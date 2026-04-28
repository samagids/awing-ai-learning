#!/usr/bin/env python3
"""Curate Bible-derived replacements for fabricated app content.

Reads:
  corpus/parallel/nt_aligned.json    (built by build_bible_parallel.py)
  lib/data/awing_vocabulary.dart     (corrected vocab, used to find blank words)

Writes (under models/bible_curated/):
  phrases.dart           — replacement for AwingPhrase entries in awing_vocabulary.dart
  sentences.dart         — replacement for SentenceTemplate list in sentences_screen.dart
  conversations.dart     — replacement for _conversations list in conversation_screen.dart
  stories.dart           — replacement for stories list in stories_screen.dart
  quiz_paragraphs.dart   — replacement for paragraphs in expert_quiz_screen.dart
  curation.json          — the underlying selections + verse refs (for audit)
  index.html             — browsable preview

You then paste each Dart block into the corresponding screen file,
replacing the fabricated section. Each block is self-contained: just
the data list, no surrounding boilerplate.

The curator is deterministic — same input always produces the same
output. Re-runs are stable for git diff review.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parents[1]
PARALLEL = REPO_ROOT / "corpus" / "parallel" / "nt_aligned.json"
VOCAB_DART = REPO_ROOT / "lib" / "data" / "awing_vocabulary.dart"
OUT_DIR = REPO_ROOT / "models" / "bible_curated"

# Target counts per section. Tunable via CLI.
DEFAULTS = {
    "phrases": 30,
    "sentences": 40,
    "conversations": 8,    # number of multi-line dialogues
    "stories": 8,          # number of multi-verse stories
    "quiz_paragraphs": 40,
}

# Length bands (Awing word count). Tuned against the distribution from
# build_bible_parallel.py: 73 short, 1,621 medium, 6,177 long.
PHRASE_LEN_RANGE = (3, 9)
SENTENCE_LEN_RANGE = (8, 18)
CONVO_LINE_LEN_RANGE = (5, 15)
STORY_VERSE_LEN_RANGE = (8, 30)

# Famous Bible passages suitable for kids — selected by reference.
# Each story is a (book, chapter, verse_start, verse_end, title) tuple.
STORY_REFS = [
    ("LUK", 2, 1, 7,   "The Birth of Jesus"),
    ("LUK", 2, 41, 50, "The Boy Jesus in the Temple"),
    ("MAT", 4, 18, 22, "Jesus Calls the First Disciples"),
    ("MAT", 14, 13, 21,"Jesus Feeds Five Thousand"),
    ("MAT", 14, 22, 31,"Jesus Walks on Water"),
    ("LUK", 15, 4, 7,  "The Lost Sheep"),
    ("LUK", 15, 8, 10, "The Lost Coin"),
    ("LUK", 19, 1, 10, "Zacchaeus"),
]

# Conversation passages — Q&A-shaped Bible exchanges suitable as dialogue.
# Each tuple: (book, chapter, verse_start, verse_end, title).
CONVO_REFS = [
    ("LUK", 1, 28, 38,  "Mary and the Angel"),
    ("MAT", 16, 13, 17, "Who Do You Say I Am?"),
    ("MAT", 19, 16, 22, "The Rich Young Man"),
    ("LUK", 10, 25, 28, "The Greatest Commandment"),
    ("JHN", 4, 7, 15,   "Jesus and the Woman at the Well"),
    ("LUK", 11, 1, 4,   "Teach Us to Pray"),
    ("LUK", 23, 39, 43, "The Thief on the Cross"),
    ("JHN", 21, 15, 17, "Do You Love Me?"),
]


# ============================================================
# Vocabulary lookup
# ============================================================

_TONE_MARKS = {"́", "̀", "̂", "̌", "̃", "̄"}


def _normalise(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if c not in _TONE_MARKS)
    return unicodedata.normalize("NFC", s).lower().strip()


def _tokenise(text: str) -> list[str]:
    return [w for w in re.sub(r"[.,!?;:\"\(\)\[\]…—–]", " ", text).split() if w]


def parse_vocab(path: Path) -> dict[str, str]:
    """awing_norm -> first English gloss. Used to find blankable words."""
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    pat = re.compile(
        r"AwingWord\(\s*awing:\s*(['\"])((?:\\.|(?!\1).)*)\1[^)]*?"
        r"english:\s*(['\"])((?:\\.|(?!\3).)*)\3",
        re.DOTALL,
    )
    out: dict[str, str] = {}
    for m in pat.finditer(text):
        awing = m.group(2).replace("\\'", "'").replace('\\"', '"')
        english = m.group(4).replace("\\'", "'").replace('\\"', '"')
        norm = _normalise(awing)
        if norm and norm not in out:
            out[norm] = english.split(",")[0].strip()
    return out


# ============================================================
# Selection helpers
# ============================================================

def _english_is_clean(text: str) -> bool:
    """Reject verses with archaic language, footnote markers, or weird
    artifacts that would confuse kids."""
    bad = ["thee ", " thee ", "thou ", "thy ", "thine ", "yea, ", "verily,",
           "[", "]", "{", "}", "*", "(See "]
    low = " " + text.lower() + " "
    return not any(b in low for b in bad)


def _awing_is_clean(text: str) -> bool:
    """Reject Awing strings with Bible-specific markup or weirdness."""
    return "[" not in text and "]" not in text


def _has_vocab_match(awing: str, vocab: dict[str, str]) -> str | None:
    """Return the first Awing token (with original casing) that has a
    vocabulary entry, or None."""
    for tok in _tokenise(awing):
        if _normalise(tok) in vocab:
            return tok
    return None


def _verses_in_range(parallel: list[dict], length_range: tuple[int, int]) -> list[dict]:
    lo, hi = length_range
    return [p for p in parallel
            if lo <= p["awing_word_count"] <= hi
            and _english_is_clean(p["english"])
            and _awing_is_clean(p["awing"])]


def _verses_for_passage(parallel: list[dict], book: str, ch: int,
                        v_start: int, v_end: int) -> list[dict]:
    """Pick a contiguous span of verses by ref."""
    target = []
    for v in parallel:
        if (v["book"] == book and v["chapter"] == ch
                and v_start <= v["verse"] <= v_end):
            target.append(v)
    target.sort(key=lambda v: v["verse"])
    return target


# ============================================================
# Curators (one per section)
# ============================================================

def curate_phrases(parallel: list[dict], vocab: dict[str, str], n: int) -> list[dict]:
    candidates = _verses_in_range(parallel, PHRASE_LEN_RANGE)
    # Deterministic ordering: by book canonical, then chapter, then verse,
    # then awing length ascending — short first.
    candidates.sort(key=lambda p: (p["book"], p["chapter"], p["verse"],
                                    p["awing_word_count"]))
    out = []
    seen_awing = set()
    for v in candidates:
        if len(out) >= n:
            break
        a = v["awing"].rstrip(".,!?;:")
        if a in seen_awing:
            continue
        seen_awing.add(a)
        out.append({
            "ref": v["ref"],
            "awing": v["awing"],
            "english": v["english"],
        })
    return out


def curate_sentences(parallel: list[dict], vocab: dict[str, str], n: int) -> list[dict]:
    """Sentence templates have a fill-in-the-blank word. We pick verses
    where at least one Awing token has a vocabulary entry — that token
    becomes the blank, its English gloss becomes the hint."""
    candidates = _verses_in_range(parallel, SENTENCE_LEN_RANGE)
    candidates.sort(key=lambda p: (p["book"], p["chapter"], p["verse"]))
    out = []
    seen = set()
    for v in candidates:
        if len(out) >= n:
            break
        if v["awing"] in seen:
            continue
        blank = _has_vocab_match(v["awing"], vocab)
        if not blank:
            continue
        # Keep blank words that have a clean ASCII gloss (no commas, parens)
        gloss = vocab[_normalise(blank)]
        if not re.match(r"^[a-zA-Z][a-zA-Z\s'-]*$", gloss) or len(gloss) > 20:
            continue
        seen.add(v["awing"])
        out.append({
            "ref": v["ref"],
            "awing": v["awing"],
            "english": v["english"],
            "blankWord": blank,
            "blankGloss": gloss,
        })
    return out


def curate_conversations(parallel: list[dict], vocab: dict[str, str], n: int) -> list[dict]:
    """Pick the predefined famous Q&A passages by reference."""
    out = []
    for ref in CONVO_REFS[:n]:
        book, ch, v_start, v_end, title = ref
        verses = _verses_for_passage(parallel, book, ch, v_start, v_end)
        if not verses:
            continue
        # Filter ones that fit the per-line length band so the dialogue
        # is readable for kids.
        usable = [v for v in verses
                  if CONVO_LINE_LEN_RANGE[0] <= v["awing_word_count"] <= CONVO_LINE_LEN_RANGE[1]
                  and _english_is_clean(v["english"])]
        # Allow up to ~5 lines per dialogue.
        if len(usable) < 2:
            continue
        out.append({
            "title": title,
            "ref": f"{book}.{ch}.{v_start}-{v_end}",
            "lines": [
                # Speaker labels alternate Person A / Person B by verse parity
                {"speaker": "Person A" if i % 2 == 0 else "Person B",
                 "ref": v["ref"], "awing": v["awing"], "english": v["english"]}
                for i, v in enumerate(usable[:5])
            ],
        })
    return out


def curate_stories(parallel: list[dict], vocab: dict[str, str], n: int) -> list[dict]:
    """Pick predefined famous-story passages by reference."""
    out = []
    for ref in STORY_REFS[:n]:
        book, ch, v_start, v_end, title = ref
        verses = _verses_for_passage(parallel, book, ch, v_start, v_end)
        if not verses:
            continue
        usable = [v for v in verses
                  if STORY_VERSE_LEN_RANGE[0] <= v["awing_word_count"] <= STORY_VERSE_LEN_RANGE[1]
                  and _english_is_clean(v["english"])]
        if not usable:
            usable = verses[:6]  # accept anyway, story without filter
        # Build vocabulary list from words appearing in the story
        vocab_used = []
        seen_words = set()
        for v in usable:
            for tok in _tokenise(v["awing"]):
                norm = _normalise(tok)
                if norm in vocab and norm not in seen_words:
                    seen_words.add(norm)
                    vocab_used.append({"awing": tok, "english": vocab[norm]})
                    if len(vocab_used) >= 8:
                        break
            if len(vocab_used) >= 8:
                break
        out.append({
            "title": title,
            "ref": f"{book}.{ch}.{v_start}-{v_end}",
            "sentences": [{"ref": v["ref"], "awing": v["awing"],
                            "english": v["english"]}
                          for v in usable],
            "vocabulary": vocab_used,
        })
    return out


def curate_quiz_paragraphs(parallel: list[dict], vocab: dict[str, str],
                            n: int) -> list[dict]:
    """Each quiz paragraph: 2-4 verses fitting in 30-50 Awing words total,
    with 3 vocabulary-match blanks chosen from the verses' tokens."""
    # Prefer 2-3 contiguous verses from the same chapter that together fit.
    out = []
    used = set()
    # Walk sequentially through parallel, gathering 3-verse windows.
    by_chapter: dict[tuple[str, int], list[dict]] = {}
    for v in parallel:
        if not _english_is_clean(v["english"]) or not _awing_is_clean(v["awing"]):
            continue
        by_chapter.setdefault((v["book"], v["chapter"]), []).append(v)

    for key in sorted(by_chapter.keys()):
        verses = sorted(by_chapter[key], key=lambda v: v["verse"])
        for i in range(len(verses) - 1):
            window = verses[i:i + 3]
            total_words = sum(v["awing_word_count"] for v in window)
            if not (20 <= total_words <= 60):
                continue
            wkey = "".join(v["ref"] for v in window)
            if wkey in used:
                continue
            # Find 3 distinct vocab-match blanks in this window
            blanks: list[str] = []
            seen_blanks = set()
            for v in window:
                for tok in _tokenise(v["awing"]):
                    norm = _normalise(tok)
                    if norm in vocab and norm not in seen_blanks:
                        gloss = vocab[norm]
                        if (re.match(r"^[a-zA-Z][a-zA-Z\s'-]*$", gloss)
                                and len(gloss) <= 20):
                            seen_blanks.add(norm)
                            blanks.append(tok)
                            if len(blanks) >= 3:
                                break
                if len(blanks) >= 3:
                    break
            if len(blanks) < 3:
                continue
            used.add(wkey)
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
# Dart code emitters
# ============================================================

def _dart_str(s: str) -> str:
    """Single-quoted Dart string literal; escapes apostrophes."""
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def emit_phrases_dart(phrases: list[dict]) -> str:
    lines = [
        "// Auto-curated from corpus/parallel/nt_aligned.json by",
        "// scripts/curate_bible_app_content.py. To regenerate:",
        "//   python3 scripts/curate_bible_app_content.py",
        "// Each entry is sourced from the WEB English NT and the CABTAL Awing NT.",
        "",
        "final List<AwingPhrase> awingPhrases = [",
    ]
    for p in phrases:
        lines.append(f"  // {p['ref']}")
        lines.append(f"  AwingPhrase(")
        lines.append(f"    awing: {_dart_str(p['awing'])},")
        lines.append(f"    english: {_dart_str(p['english'])},")
        lines.append(f"  ),")
    lines.append("];")
    return "\n".join(lines)


def emit_sentences_dart(sentences: list[dict]) -> str:
    lines = [
        "// Auto-curated from Bible NT — sentence templates for fill-in-the-blank.",
        "",
        "final List<_SentenceTemplate> _sentenceTemplates = [",
    ]
    for s in sentences:
        lines.append(f"  // {s['ref']}")
        lines.append(f"  _SentenceTemplate(")
        lines.append(f"    awing: {_dart_str(s['awing'])},")
        lines.append(f"    english: {_dart_str(s['english'])},")
        lines.append(f"    blankWord: {_dart_str(s['blankWord'])},")
        lines.append(f"    hint: {_dart_str(s['blankGloss'])},")
        lines.append(f"  ),")
    lines.append("];")
    return "\n".join(lines)


def emit_conversations_dart(convos: list[dict]) -> str:
    lines = [
        "// Auto-curated dialogues from Bible NT.",
        "",
        "final List<Map<String, dynamic>> _conversations = [",
    ]
    for c in convos:
        lines.append(f"  // {c['ref']} — {c['title']}")
        lines.append("  {")
        lines.append(f"    'title': {_dart_str(c['title'])},")
        lines.append("    'lines': <Map<String, String>>[")
        for ln in c["lines"]:
            lines.append("      {")
            lines.append(f"        'speaker': {_dart_str(ln['speaker'])},")
            lines.append(f"        'awing': {_dart_str(ln['awing'])},")
            lines.append(f"        'english': {_dart_str(ln['english'])},")
            lines.append("      },")
        lines.append("    ],")
        lines.append("  },")
    lines.append("];")
    return "\n".join(lines)


def emit_stories_dart(stories: list[dict]) -> str:
    lines = [
        "// Auto-curated stories from Bible NT.",
        "",
        "final List<AwingStory> _stories = [",
    ]
    for st in stories:
        lines.append(f"  // {st['ref']}")
        lines.append("  AwingStory(")
        lines.append(f"    title: {_dart_str(st['title'])},")
        lines.append("    sentences: [")
        for s in st["sentences"]:
            lines.append("      StorySentence(")
            lines.append(f"        awing: {_dart_str(s['awing'])},")
            lines.append(f"        english: {_dart_str(s['english'])},")
            lines.append("      ),")
        lines.append("    ],")
        lines.append("    vocabulary: [")
        for v in st["vocabulary"]:
            lines.append("      StoryVocabulary(")
            lines.append(f"        awing: {_dart_str(v['awing'])},")
            lines.append(f"        english: {_dart_str(v['english'])},")
            lines.append("      ),")
        lines.append("    ],")
        lines.append("  ),")
    lines.append("];")
    return "\n".join(lines)


def emit_quiz_paragraphs_dart(paras: list[dict]) -> str:
    lines = [
        "// Auto-curated paragraph fill-in-the-blank quizzes from Bible NT.",
        "// Each paragraph has 3 blanks marked {0}, {1}, {2}.",
        "",
        "final List<_QuizParagraph> _quizParagraphs = [",
    ]
    for p in paras:
        # Build a single Awing-text string with verses concatenated by spaces,
        # replacing each chosen blank's first occurrence with {N}.
        awing_full = " ".join(v["awing"] for v in p["verses"])
        english_full = " ".join(v["english"] for v in p["verses"])
        marked = awing_full
        for i, blank in enumerate(p["blanks"]):
            # Replace the FIRST whole-word occurrence of this blank.
            pat = re.compile(r"\b" + re.escape(blank) + r"\b", re.UNICODE)
            marked = pat.sub("{" + str(i) + "}", marked, count=1)
        lines.append(f"  // {p['ref']}")
        lines.append("  _QuizParagraph(")
        lines.append(f"    awingText: {_dart_str(marked)},")
        lines.append(f"    englishText: {_dart_str(english_full)},")
        lines.append("    blanks: [")
        for blank in p["blanks"]:
            lines.append(f"      {_dart_str(blank)},")
        lines.append("    ],")
        lines.append("  ),")
    lines.append("];")
    return "\n".join(lines)


# ============================================================
# Main
# ============================================================

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--phrases", type=int, default=DEFAULTS["phrases"])
    ap.add_argument("--sentences", type=int, default=DEFAULTS["sentences"])
    ap.add_argument("--conversations", type=int, default=DEFAULTS["conversations"])
    ap.add_argument("--stories", type=int, default=DEFAULTS["stories"])
    ap.add_argument("--quiz-paragraphs", dest="quiz_paragraphs",
                    type=int, default=DEFAULTS["quiz_paragraphs"])
    args = ap.parse_args()

    if not PARALLEL.exists():
        print(f"ERROR: {PARALLEL} missing. Run scripts/build_bible_parallel.py first.")
        return 1

    print(f"Loading parallel verses from {PARALLEL.relative_to(REPO_ROOT)}...")
    parallel = json.loads(PARALLEL.read_text(encoding="utf-8"))
    print(f"  {len(parallel)} pairs across {len({p['book'] for p in parallel})} books")

    print(f"Loading vocabulary from {VOCAB_DART.relative_to(REPO_ROOT)}...")
    vocab = parse_vocab(VOCAB_DART)
    print(f"  {len(vocab)} unique Awing words with English glosses\n")

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Curating {args.phrases} phrases (band {PHRASE_LEN_RANGE})...")
    phrases = curate_phrases(parallel, vocab, args.phrases)
    print(f"  Picked {len(phrases)}\n")

    print(f"Curating {args.sentences} sentences (band {SENTENCE_LEN_RANGE})...")
    sentences = curate_sentences(parallel, vocab, args.sentences)
    print(f"  Picked {len(sentences)}\n")

    print(f"Curating {args.conversations} conversations (from canonical Q&A passages)...")
    conversations = curate_conversations(parallel, vocab, args.conversations)
    print(f"  Picked {len(conversations)}\n")

    print(f"Curating {args.stories} stories (from canonical kid-suitable passages)...")
    stories = curate_stories(parallel, vocab, args.stories)
    print(f"  Picked {len(stories)}\n")

    print(f"Curating {args.quiz_paragraphs} quiz paragraphs (3-verse windows)...")
    quiz = curate_quiz_paragraphs(parallel, vocab, args.quiz_paragraphs)
    print(f"  Picked {len(quiz)}\n")

    # Emit Dart files
    (OUT_DIR / "phrases.dart").write_text(emit_phrases_dart(phrases),
                                            encoding="utf-8")
    (OUT_DIR / "sentences.dart").write_text(emit_sentences_dart(sentences),
                                              encoding="utf-8")
    (OUT_DIR / "conversations.dart").write_text(emit_conversations_dart(conversations),
                                                  encoding="utf-8")
    (OUT_DIR / "stories.dart").write_text(emit_stories_dart(stories),
                                             encoding="utf-8")
    (OUT_DIR / "quiz_paragraphs.dart").write_text(emit_quiz_paragraphs_dart(quiz),
                                                    encoding="utf-8")

    # Audit JSON
    (OUT_DIR / "curation.json").write_text(json.dumps({
        "phrases": phrases,
        "sentences": sentences,
        "conversations": conversations,
        "stories": stories,
        "quiz_paragraphs": quiz,
    }, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Output: {OUT_DIR.relative_to(REPO_ROOT)}/")
    print(f"  phrases.dart           {len(phrases)} entries")
    print(f"  sentences.dart         {len(sentences)} entries")
    print(f"  conversations.dart     {len(conversations)} dialogues")
    print(f"  stories.dart           {len(stories)} stories")
    print(f"  quiz_paragraphs.dart   {len(quiz)} paragraphs")
    print(f"  curation.json          full audit data")
    return 0


if __name__ == "__main__":
    sys.exit(main())
