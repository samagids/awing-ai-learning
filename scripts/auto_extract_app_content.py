#!/usr/bin/env python3
"""Auto-extract NON-biblical-feeling app content + vocab from the parallel
Awing-English NT corpus. Minimal manual review.

The Bible is treated here as a SOURCE OF AUTHENTIC AWING, not as
displayed religious content. We aggressively filter out:
  - Proper nouns (Jesus, Mary, Paul, Israel, Jerusalem, etc.)
  - Religion-specific vocabulary (God, sin, faith, kingdom, prayer, etc.)
  - Verses with archaic English ("thee", "thou", "verily")
  - Verses with explicit theological references (sacrifice, salvation, etc.)

What survives: ordinary sentences like "He went to the market", "The
water is good", "She has a son", "Don't be afraid". These are
authentic Awing, kid-suitable, non-religious-feeling.

Outputs three things:
  1. Vocabulary additions — auto-glossed via English co-occurrence
     (top English content word that co-occurs most with each new Awing
     word). High-confidence ones get auto-added; lower-confidence ones
     go to a review HTML.
  2. Phrases/sentences/stories — non-biblical-feeling Bible verses
     curated by length, ready to drop into the screen files.
  3. Auto-apply to source files (with --apply).

Usage:
  python3 scripts/auto_extract_app_content.py            # preview
  python3 scripts/auto_extract_app_content.py --apply    # write changes
  python3 scripts/auto_extract_app_content.py --vocab-only --apply
  python3 scripts/auto_extract_app_content.py --content-only --apply
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PARALLEL = REPO_ROOT / "corpus" / "parallel" / "nt_aligned.json"
VOCAB_DART = REPO_ROOT / "lib" / "data" / "awing_vocabulary.dart"
OUT_DIR = REPO_ROOT / "models" / "auto_extract"

# Screen files we replace content in
SENTENCES_FILE = REPO_ROOT / "lib" / "screens" / "medium" / "sentences_screen.dart"
STORIES_FILE = REPO_ROOT / "lib" / "screens" / "stories_screen.dart"
CONVO_FILE = REPO_ROOT / "lib" / "screens" / "expert" / "conversation_screen.dart"
QUIZ_FILE = REPO_ROOT / "lib" / "screens" / "expert" / "expert_quiz_screen.dart"

# ============================================================
# Filters: what makes a verse "biblical-feeling"
# ============================================================

# Awing-side proper nouns to reject. Includes common transliterations
# of biblical names found in CABTAL's Awing NT.
AWING_PROPER_NOUNS = {
    "yeso", "klisto", "klistə", "yesəkristə", "kristə",
    "mali", "mariam", "yusufu", "yosuf",
    "petelə", "petər", "petəl", "andələ", "yakubə", "yakob",
    "yopə", "matiye", "maakə", "lukasə", "jɔnə",
    "pɔlə", "petər", "tomasə", "judasə",
    "abalaam", "ablaam", "isaakə", "yakob", "musa", "moisə", "moisi",
    "elia", "isaiya", "ysaya", "danielə", "davitə",
    "mose", "moses", "abrahamə", "yacob", "yosef",
    "nazaletə", "naazəletə", "betəlɛhɛm", "betəleem",
    "yelusalemə", "judiya", "samaliya", "galilea",
    "izlael", "israelə", "kanan", "ɛjiptə", "egiptə",
    "kɔlinə", "ɛfɛsɔ", "atɛnə", "lomə", "lome",
    "famalisi", "falisi", "saduki",
    "satanə", "satən",
}

# English-side patterns that mark a verse as biblical/religious.
# We REJECT verses whose English contains any of these.
ENG_RELIGIOUS_PATTERNS = [
    # Names
    r"\b(jesus|christ|messiah|lord|holy\s+spirit|holy\s+ghost)\b",
    r"\b(moses|abraham|isaac|jacob|david|elijah|isaiah|daniel)\b",
    r"\b(mary|joseph|peter|paul|john|matthew|mark|luke|james|judas|thomas)\b",
    r"\b(israel|jerusalem|judea|samaria|galilee|nazareth|bethlehem|egypt)\b",
    r"\b(rome|corinth|ephesus|athens|babylon|sodom|gomorrah)\b",
    r"\b(pharisees?|sadducees?|scribes?|priests?|levites?)\b",
    r"\b(satan|devil|demon)\b",
    # Religious vocabulary
    r"\b(god|gods?)\b",
    r"\b(heaven|hell|kingdom\s+of\s+(?:heaven|god))\b",
    r"\bsin(?:ned|ner|s|ful|ning)?\b",
    r"\b(prayer|prayed|pray\b|praying|salvation|saved|save\b)\b",
    r"\b(sacrifice|atonement|redemption|crucifix|baptiz|baptism)\b",
    r"\b(disciples?|apostles?|prophets?)\b",
    r"\b(faith|believe|believer)\b",  # heavily religious in NT context
    r"\b(church|temple|synagogue|altar)\b",
    r"\b(angels?|archangel|cherub)\b",
    r"\b(scripture|gospel|covenant|testament)\b",
    r"\b(amen|hallelujah|hosanna)\b",
    r"\bspirit\b",
    r"\b(parable|prophesy|prophet|prophets?)\b",
    # Archaic English (rejects KJV-flavored verses regardless)
    r"\b(thee|thou|thy|thine|ye)\b",
    r"\bverily\b",
]
ENG_RELIGIOUS_RE = re.compile("|".join(ENG_RELIGIOUS_PATTERNS), re.IGNORECASE)

# Awing-side religious terms (CABTAL's NT renders these consistently)
AWING_RELIGIOUS_TERMS = {
    "ɛsɛ", "esê", "əsê",  # God
    "kristə", "klisto",
    "yeso",
}


_TONE_DIACRITICS = {"́", "̀", "̂", "̌", "̃", "̄"}


def _normalise(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if c not in _TONE_DIACRITICS)
    return unicodedata.normalize("NFC", s).lower().strip()


def _tokenise_awing(text: str) -> list[str]:
    cleaned = re.sub(r"[.,!?;:\"\(\)\[\]…—–]", " ", text)
    return [w for w in cleaned.split() if w.strip()]


def _is_non_biblical(awing: str, english: str) -> bool:
    """True iff this verse reads as ordinary Awing/English with no
    biblical names, theological vocabulary, or archaic English."""
    if ENG_RELIGIOUS_RE.search(english):
        return False
    aw_tokens = {_normalise(t) for t in _tokenise_awing(awing)}
    if aw_tokens & AWING_PROPER_NOUNS:
        return False
    if aw_tokens & AWING_RELIGIOUS_TERMS:
        return False
    return True


# ============================================================
# Vocabulary auto-glosser
# ============================================================

ENG_STOPWORDS = {
    "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
    "to", "of", "in", "on", "at", "by", "for", "with", "from", "as",
    "and", "or", "but", "not", "no", "yes", "i", "you", "he", "she",
    "it", "we", "they", "him", "her", "them", "us", "me", "my", "your",
    "his", "their", "our", "this", "that", "these", "those", "have",
    "has", "had", "do", "does", "did", "will", "would", "shall", "should",
    "may", "might", "can", "could", "must", "if", "when", "while", "all",
    "any", "some", "what", "which", "who", "whom", "where", "why", "how",
    "there", "here", "now", "then", "very", "so", "also", "just", "only",
}


def _english_content_words(s: str) -> list[str]:
    cleaned = re.sub(r"[^a-zA-Z\s]", " ", s.lower())
    return [w for w in cleaned.split()
            if w not in ENG_STOPWORDS and len(w) > 2]


def parse_existing_vocab(path: Path) -> set[str]:
    """Set of normalised Awing words already in vocab.dart."""
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8")
    pat = re.compile(
        r"AwingWord\(\s*awing:\s*(['\"])((?:\\.|(?!\1).)*)\1",
        re.DOTALL,
    )
    out: set[str] = set()
    for m in pat.finditer(text):
        awing = m.group(2).replace("\\'", "'").replace('\\"', '"')
        out.add(_normalise(awing))
    return out


def auto_gloss_vocab(parallel: list[dict], existing: set[str]
                     ) -> list[dict]:
    """For each Awing word not in vocab, find the most-co-occurring
    English content word across all verses containing it.

    Returns sorted list of {awing, gloss, freq, confidence, examples}.
    Confidence = (occurrences with top gloss) / (total occurrences).
    """
    # Build per-word stats
    awing_freq: Counter[str] = Counter()
    awing_to_eng: dict[str, Counter[str]] = defaultdict(Counter)
    awing_surface: dict[str, str] = {}
    awing_examples: dict[str, list[dict]] = defaultdict(list)

    for v in parallel:
        aw_tokens = _tokenise_awing(v["awing"])
        eng_words = set(_english_content_words(v["english"]))

        for tok in aw_tokens:
            norm = _normalise(tok)
            if not norm or len(norm) < 2:
                continue
            if any(c.isdigit() for c in norm):
                continue
            if norm in existing:
                continue
            if norm in AWING_PROPER_NOUNS:
                continue
            if norm in AWING_RELIGIOUS_TERMS:
                continue
            awing_freq[norm] += 1
            for ew in eng_words:
                awing_to_eng[norm][ew] += 1
            if norm not in awing_surface:
                awing_surface[norm] = tok
            if len(awing_examples[norm]) < 3:
                awing_examples[norm].append({
                    "ref": v["ref"],
                    "awing": v["awing"],
                    "english": v["english"],
                })

    # Compute confidence + best gloss per word
    out = []
    for norm, freq in awing_freq.most_common():
        if freq < 3:
            break  # rare tokens — skip for auto, they'd need manual review
        eng_counter = awing_to_eng[norm]
        if not eng_counter:
            continue
        top_gloss, top_count = eng_counter.most_common(1)[0]
        confidence = top_count / freq
        out.append({
            "awing": awing_surface[norm],
            "norm": norm,
            "freq": freq,
            "gloss": top_gloss,
            "confidence": confidence,
            "examples": awing_examples[norm],
        })
    return out


# ============================================================
# Content selection
# ============================================================

def select_phrases(parallel: list[dict], n: int) -> list[dict]:
    candidates = [v for v in parallel
                  if 3 <= v["awing_word_count"] <= 8
                  and _is_non_biblical(v["awing"], v["english"])]
    candidates.sort(key=lambda v: (v["awing_word_count"], v["book"], v["chapter"], v["verse"]))
    seen = set()
    out = []
    for v in candidates:
        a = v["awing"].rstrip(".,!?;:")
        if a in seen:
            continue
        seen.add(a)
        out.append({"ref": v["ref"], "awing": v["awing"], "english": v["english"]})
        if len(out) >= n:
            break
    return out


def select_sentences(parallel: list[dict], n: int) -> list[dict]:
    candidates = [v for v in parallel
                  if 6 <= v["awing_word_count"] <= 16
                  and _is_non_biblical(v["awing"], v["english"])]
    candidates.sort(key=lambda v: (v["book"], v["chapter"], v["verse"]))
    seen = set()
    out = []
    for v in candidates:
        if v["awing"] in seen:
            continue
        seen.add(v["awing"])
        out.append({"ref": v["ref"], "awing": v["awing"], "english": v["english"]})
        if len(out) >= n:
            break
    return out


def select_conversations(parallel: list[dict], n: int) -> list[dict]:
    """Find chapters with 3+ contiguous non-biblical verses, treat as Q&A."""
    by_chapter: dict[tuple[str, int], list[dict]] = defaultdict(list)
    for v in parallel:
        if _is_non_biblical(v["awing"], v["english"]):
            if 4 <= v["awing_word_count"] <= 14:
                by_chapter[(v["book"], v["chapter"])].append(v)
    out = []
    for key, verses in sorted(by_chapter.items()):
        verses.sort(key=lambda v: v["verse"])
        # Find longest contiguous run
        runs = []
        run = []
        prev = None
        for v in verses:
            if prev is not None and v["verse"] != prev + 1:
                if len(run) >= 3:
                    runs.append(run)
                run = []
            run.append(v)
            prev = v["verse"]
        if len(run) >= 3:
            runs.append(run)
        for r in runs:
            if len(r) >= 3:
                out.append({
                    "ref": f"{r[0]['book']}.{r[0]['chapter']}.{r[0]['verse']}-{r[-1]['verse']}",
                    "title": f"Conversation {len(out) + 1}",
                    "lines": [
                        {"speaker": "Person A" if i % 2 == 0 else "Person B",
                         "ref": v["ref"], "awing": v["awing"], "english": v["english"]}
                        for i, v in enumerate(r[:5])
                    ],
                })
                if len(out) >= n:
                    return out
    return out


def select_stories(parallel: list[dict], n: int) -> list[dict]:
    """Pick 3-7-verse passages with no proper nouns and no religious terms."""
    by_chapter: dict[tuple[str, int], list[dict]] = defaultdict(list)
    for v in parallel:
        if _is_non_biblical(v["awing"], v["english"]):
            if 6 <= v["awing_word_count"] <= 25:
                by_chapter[(v["book"], v["chapter"])].append(v)

    out = []
    for key, verses in sorted(by_chapter.items()):
        verses.sort(key=lambda v: v["verse"])
        run = []
        prev = None
        for v in verses:
            if prev is not None and v["verse"] != prev + 1:
                if 3 <= len(run) <= 7:
                    out.append({
                        "ref": f"{run[0]['book']}.{run[0]['chapter']}."
                               f"{run[0]['verse']}-{run[-1]['verse']}",
                        "title": f"Story {len(out) + 1}",
                        "sentences": [{"ref": v["ref"], "awing": v["awing"],
                                       "english": v["english"]} for v in run],
                    })
                run = []
            run.append(v)
            prev = v["verse"]
        if 3 <= len(run) <= 7:
            out.append({
                "ref": f"{run[0]['book']}.{run[0]['chapter']}."
                       f"{run[0]['verse']}-{run[-1]['verse']}",
                "title": f"Story {len(out) + 1}",
                "sentences": [{"ref": v["ref"], "awing": v["awing"],
                               "english": v["english"]} for v in run],
            })
        if len(out) >= n:
            break
    return out[:n]


def select_quiz_paragraphs(parallel: list[dict], vocab_norms: set[str], n: int
                           ) -> list[dict]:
    """3-verse non-biblical windows, with 3 vocab-match blanks."""
    out = []
    by_chapter: dict[tuple[str, int], list[dict]] = defaultdict(list)
    for v in parallel:
        if _is_non_biblical(v["awing"], v["english"]):
            by_chapter[(v["book"], v["chapter"])].append(v)
    seen = set()
    for key, verses in sorted(by_chapter.items()):
        verses.sort(key=lambda v: v["verse"])
        for i in range(len(verses) - 2):
            window = verses[i:i + 3]
            total = sum(v["awing_word_count"] for v in window)
            if not (15 <= total <= 50):
                continue
            wkey = "".join(v["ref"] for v in window)
            if wkey in seen:
                continue
            blanks: list[str] = []
            seen_norm = set()
            for v in window:
                for tok in _tokenise_awing(v["awing"]):
                    norm = _normalise(tok)
                    if norm in vocab_norms and norm not in seen_norm:
                        seen_norm.add(norm)
                        blanks.append(tok)
                        if len(blanks) >= 3:
                            break
                if len(blanks) >= 3:
                    break
            if len(blanks) < 3:
                continue
            seen.add(wkey)
            out.append({
                "ref": f"{window[0]['book']}.{window[0]['chapter']}."
                       f"{window[0]['verse']}-{window[-1]['verse']}",
                "verses": [{"ref": v["ref"], "awing": v["awing"],
                             "english": v["english"]} for v in window],
                "blanks": blanks,
            })
            if len(out) >= n:
                return out
    return out


# ============================================================
# Apply: write changes to source files
# ============================================================

def _dart_str(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def apply_vocab_additions(vocab_path: Path, additions: list[dict],
                          confidence_threshold: float, dry_run: bool) -> int:
    """Append high-confidence vocab to awing_vocabulary.dart's
    dictionaryEntries list. Returns count added."""
    high_conf = [a for a in additions if a["confidence"] >= confidence_threshold]
    if not high_conf:
        return 0
    if dry_run:
        return len(high_conf)
    text = vocab_path.read_text(encoding="utf-8")

    # Find dictionaryEntries list and insert before its closing ];
    marker = "List<AwingWord> dictionaryEntries = ["
    if marker not in text:
        # Try const variant
        marker = "const List<AwingWord> dictionaryEntries = ["
        if marker not in text:
            print(f"  WARNING: dictionaryEntries list not found in {vocab_path.name} — skipping vocab add")
            return 0
    start = text.find(marker)
    # Find the matching closing ];
    depth = 0
    i = start + len(marker) - 1  # at the '['
    end = -1
    for j in range(i, len(text)):
        ch = text[j]
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                end = j
                break
    if end < 0:
        print(f"  WARNING: couldn't find end of dictionaryEntries — skipping")
        return 0

    # Build the new entries text
    block = ["", "  // === Auto-extracted from Bible NT corpus (auto_extract_app_content.py) ==="]
    for a in high_conf:
        block.append(
            f"  AwingWord(awing: {_dart_str(a['awing'])}, "
            f"english: {_dart_str(a['gloss'])}, "
            f"category: 'general', difficulty: 2),"
        )
        block.append(f"    // bible:{a['examples'][0]['ref']}, conf={a['confidence']:.2f}, freq={a['freq']}")

    new_text = text[:end] + "\n".join(block) + "\n" + text[end:]
    vocab_path.write_text(new_text, encoding="utf-8")
    return len(high_conf)


# Replace _replace_list_in_file: simpler approach — replace EVERYTHING
# between two unique markers we add to the source files. We assume the
# fabricated content has been cleaned (commented out by
# cleanup_fabricated_content.py), so we just append our new content at
# a known location. To keep this simple we APPEND to the END of the
# data list and let Dart de-dupe naturally.
# This is intentionally a less clever approach than auto-replace —
# avoids breaking the screen file's parse tree.

def append_to_data_file(file_path: Path, marker: str, dart_block: str,
                        dry_run: bool) -> bool:
    """Append a Dart block immediately after the given marker (a literal
    that appears in the source). Returns True iff applied."""
    if not file_path.exists():
        print(f"  SKIP: {file_path.name} missing")
        return False
    text = file_path.read_text(encoding="utf-8")
    idx = text.find(marker)
    if idx < 0:
        print(f"  SKIP: marker {marker!r} not found in {file_path.name}")
        return False
    # Insert block on the line AFTER the marker line
    line_end = text.find("\n", idx)
    if line_end < 0:
        line_end = len(text)
    new_text = text[:line_end + 1] + dart_block + text[line_end + 1:]
    if not dry_run:
        file_path.write_text(new_text, encoding="utf-8")
    return True


# ============================================================
# Main
# ============================================================

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--apply", action="store_true",
                    help="Write changes to source files. Default: preview only.")
    ap.add_argument("--vocab-only", action="store_true",
                    help="Only do vocabulary extraction.")
    ap.add_argument("--content-only", action="store_true",
                    help="Only do content extraction.")
    ap.add_argument("--phrases", type=int, default=30)
    ap.add_argument("--sentences", type=int, default=40)
    ap.add_argument("--conversations", type=int, default=8)
    ap.add_argument("--stories", type=int, default=6)
    ap.add_argument("--quiz", type=int, default=40)
    ap.add_argument("--vocab-confidence", type=float, default=0.4,
                    help="Minimum co-occurrence confidence to auto-add a vocab "
                         "entry. 0.4 = top English gloss appears in 40%% of the "
                         "verses where this Awing word appears. Default: 0.4.")
    args = ap.parse_args()

    if not PARALLEL.exists():
        print(f"ERROR: {PARALLEL} missing. Run scripts/build_bible_parallel.py first.")
        return 1

    print(f"Loading parallel corpus...")
    parallel = json.loads(PARALLEL.read_text(encoding="utf-8"))
    print(f"  {len(parallel)} pairs\n")

    print(f"Loading existing vocabulary...")
    existing = parse_existing_vocab(VOCAB_DART)
    print(f"  {len(existing)} entries\n")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    summary: dict = {}

    # ---- Vocabulary ------------------------------------------------
    if not args.content_only:
        print("=" * 60)
        print(" Vocabulary auto-extraction")
        print("=" * 60)
        candidates = auto_gloss_vocab(parallel, existing)
        high = [c for c in candidates if c["confidence"] >= args.vocab_confidence]
        low = [c for c in candidates if c["confidence"] < args.vocab_confidence]
        print(f"  Total candidates: {len(candidates)}")
        print(f"  High-confidence (≥{args.vocab_confidence}, auto-add): {len(high)}")
        print(f"  Low-confidence (HTML review): {len(low)}")

        # Save full candidate list
        (OUT_DIR / "vocab_candidates.json").write_text(
            json.dumps(candidates, ensure_ascii=False, indent=2), encoding="utf-8")
        summary["vocab_high"] = len(high)
        summary["vocab_low"] = len(low)

        # Apply
        added = apply_vocab_additions(
            VOCAB_DART, candidates, args.vocab_confidence,
            dry_run=not args.apply)
        action = "would add" if not args.apply else "added"
        print(f"  {action} {added} entries to dictionaryEntries\n")

    # ---- Content ---------------------------------------------------
    if not args.vocab_only:
        print("=" * 60)
        print(" Non-biblical-feeling content extraction")
        print("=" * 60)

        phrases = select_phrases(parallel, args.phrases)
        sentences = select_sentences(parallel, args.sentences)
        convos = select_conversations(parallel, args.conversations)
        stories = select_stories(parallel, args.stories)
        # Re-load existing vocab including auto-added ones for quiz
        vocab_norms = parse_existing_vocab(VOCAB_DART)
        quiz = select_quiz_paragraphs(parallel, vocab_norms, args.quiz)

        print(f"  Phrases:       {len(phrases)} (target {args.phrases})")
        print(f"  Sentences:     {len(sentences)} (target {args.sentences})")
        print(f"  Conversations: {len(convos)} (target {args.conversations})")
        print(f"  Stories:       {len(stories)} (target {args.stories})")
        print(f"  Quiz paras:    {len(quiz)} (target {args.quiz})")

        # Save extraction
        (OUT_DIR / "extracted_content.json").write_text(
            json.dumps({"phrases": phrases, "sentences": sentences,
                         "conversations": convos, "stories": stories,
                         "quiz": quiz}, ensure_ascii=False, indent=2),
            encoding="utf-8")
        summary["phrases"] = len(phrases)
        summary["sentences"] = len(sentences)
        summary["conversations"] = len(convos)
        summary["stories"] = len(stories)
        summary["quiz"] = len(quiz)

        # We deliberately do NOT auto-modify the screen files in this
        # version. The screen files have UI code mixed with data,
        # making safe append/replace fragile. Instead, the JSON is
        # available and a follow-up script (apply_extracted_content.py)
        # can stitch them in once you confirm the previews look good.
        print()
        print(f"  Content saved to {(OUT_DIR / 'extracted_content.json').relative_to(REPO_ROOT)}")
        print(f"  Review there, then run apply_extracted_content.py to stitch in")

    print()
    print("Summary:", json.dumps(summary, indent=2))
    if not args.apply:
        print()
        print("Preview only — re-run with --apply to write changes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
