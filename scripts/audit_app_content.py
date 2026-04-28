#!/usr/bin/env python3
"""Audit every Awing/English pair across the app's content files.

What it does
------------
1. Extract every (awing, english) pair from:
     lib/data/awing_vocabulary.dart           (AwingPhrase entries)
     lib/screens/medium/sentences_screen.dart (sentence templates)
     lib/screens/stories_screen.dart          (StorySentence + StoryVocabulary)
     lib/screens/expert/conversation_screen.dart (dialog turns)
     lib/screens/expert/expert_quiz_screen.dart  (paragraph fill-in-blank)
2. Build a "corrected meaning" dictionary from awing_vocabulary.dart's
   AwingWord entries — these have been audited against the 2007
   dictionary (Sessions 22, 49-52).
3. For each Awing/English pair found above, tokenise the Awing, look
   up each token in the corrected dictionary, and flag entries where
   no token in the sentence carries any meaning that overlaps with
   the English claim.
4. Also search for the FULL Awing phrase as a substring in the Bible
   corpus (corpus/raw/bible/azocab/.../verses.json) — matching there
   is the strongest signal of semantic correctness because the
   corpus is from CABTAL's authoritative translation.
5. Categorise each pair: VERIFIED-BIBLE (matched in corpus),
   VERIFIED-DICT (vocab supports the claimed meaning),
   MISMATCH (vocabulary disagrees with English claim, like the koŋə
   "owl"/"crawl" confusion), or UNKNOWN (couldn't decide).
6. Emit JSON manifest + readable HTML at models/content_audit/.

Usage
-----
    source ~/awing_venv/bin/activate
    python3 scripts/audit_app_content.py

After running, open models/content_audit/index.html in a browser and
review the MISMATCH section. Those are the entries that need to be
fixed or replaced (likely with Bible-derived equivalents).
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
VOCAB_DART = REPO_ROOT / "lib" / "data" / "awing_vocabulary.dart"
SCREENS = [
    REPO_ROOT / "lib" / "screens" / "medium" / "sentences_screen.dart",
    REPO_ROOT / "lib" / "screens" / "stories_screen.dart",
    REPO_ROOT / "lib" / "screens" / "expert" / "conversation_screen.dart",
    REPO_ROOT / "lib" / "screens" / "expert" / "expert_quiz_screen.dart",
]
CORPUS_DIR = REPO_ROOT / "corpus" / "raw" / "bible" / "azocab"
OUT_DIR = REPO_ROOT / "models" / "content_audit"


# ============================================================
# Tokenisation + normalisation
# ============================================================

_TONE_DIACRITICS = {"́", "̀", "̂", "̌", "̃", "̄"}


def _normalise_awing(s: str) -> str:
    """Lowercase, strip tone diacritics. For dictionary lookups + matching."""
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if c not in _TONE_DIACRITICS)
    s = unicodedata.normalize("NFC", s)
    return s.lower().strip()


def _tokenise_awing(text: str) -> list[str]:
    """Split Awing text into words. Punctuation goes away."""
    # Glottal stop ' is part of words, keep it. Other punctuation: drop.
    cleaned = re.sub(r"[.,!?;:\"\(\)\[\]\{\}…—–]", " ", text)
    return [w for w in cleaned.split() if w.strip()]


_STOPWORDS = {
    "the", "a", "an", "is", "are", "to", "of", "in", "on", "at",
    "and", "or", "but", "i", "you", "he", "she", "it", "we", "they",
    "his", "her", "its", "our", "their", "my", "this", "that",
    "be", "been", "was", "were", "have", "has", "had", "do", "does",
    "did", "will", "would", "shall", "should", "may", "might",
    "for", "with", "from", "by", "as", "not",
}


def _english_content_words(s: str) -> set[str]:
    """English content words minus stopwords. For overlap checks."""
    cleaned = re.sub(r"[^a-zA-Z\s]", " ", s.lower())
    return {w for w in cleaned.split() if w and w not in _STOPWORDS and len(w) > 2}


# ============================================================
# Source extraction
# ============================================================

def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8") if p.exists() else ""


def parse_vocab_words(text: str) -> dict[str, set[str]]:
    """awing word (normalised) -> set of English content words from its gloss."""
    out: dict[str, set[str]] = defaultdict(set)
    pattern = re.compile(
        r"AwingWord\(\s*awing:\s*(['\"])((?:\\.|(?!\1).)*)\1[^)]*?"
        r"english:\s*(['\"])((?:\\.|(?!\3).)*)\3",
        re.DOTALL,
    )
    for m in pattern.finditer(text):
        awing = m.group(2).replace("\\'", "'").replace('\\"', '"')
        english = m.group(4).replace("\\'", "'").replace('\\"', '"')
        out[_normalise_awing(awing)] |= _english_content_words(english)
    return out


def extract_pairs(path: Path) -> list[dict]:
    """Generic Awing+English pair extractor. Catches three patterns:
       1. Named-parameter:         awing: '...'  english: '...'
       2. Map-literal (string key): 'awing': '...'  'english': '...'
       3. AwingText paragraph:      awingText: '...' english: '...'  OR
                                    awingText: r'''...'''  english: r'''...'''
    """
    pairs = []
    if not path.exists():
        return pairs
    text = path.read_text(encoding="utf-8")

    # Catches: awing:/'awing':/awingText: paired with english:/'english':/englishText:
    pat = re.compile(
        r"(?:'?awing(?:Text)?'?):\s*(['\"]r?)((?:\\.|(?!\1).)*?)\1"
        r"[\s\S]{0,400}?"
        r"(?:'?english(?:Text)?'?):\s*(['\"]r?)((?:\\.|(?!\3).)*?)\3",
        re.MULTILINE,
    )
    seen = set()
    for m in pat.finditer(text):
        line = text.count("\n", 0, m.start()) + 1
        awing = m.group(2).replace("\\'", "'").replace('\\"', '"')
        english = m.group(4).replace("\\'", "'").replace('\\"', '"')
        # De-dupe: same file/line/awing combo can match twice if the
        # surrounding regex overlaps (rare but possible).
        key = (path.name, line, awing)
        if key in seen:
            continue
        seen.add(key)
        pairs.append({
            "file": str(path.relative_to(REPO_ROOT)),
            "line": line,
            "awing": awing,
            "english": english,
        })
    return pairs


def load_bible_verses() -> list[tuple[str, str]]:
    """Returns list of (ref, awing_text) for every NT verse on disk."""
    out = []
    if not CORPUS_DIR.exists():
        return out
    for vj in sorted(CORPUS_DIR.rglob("*.verses.json")):
        try:
            data = json.loads(vj.read_text(encoding="utf-8"))
        except Exception:
            continue
        for entry in data:
            ref = entry.get("ref") or entry.get("verse_id") or vj.stem
            text = (entry.get("text") or "").strip()
            if text:
                out.append((ref, text))
    return out


# ============================================================
# Verdict
# ============================================================

def verdict(pair: dict, vocab: dict[str, set[str]],
            bible: list[tuple[str, str]]) -> dict:
    """Compute a verdict for one pair. Returns the same dict with extras."""
    pair = dict(pair)  # don't mutate caller
    awing = pair["awing"]
    english_words = _english_content_words(pair["english"])

    # Bible substring match (strongest signal)
    bible_match = None
    awing_norm_for_search = awing.strip().rstrip(".,!?:;").lower()
    if len(awing_norm_for_search) >= 8:
        for ref, vt in bible:
            if awing_norm_for_search in vt.lower():
                bible_match = ref
                break

    # Per-token vocabulary check
    tokens = _tokenise_awing(awing)
    vocab_meanings: list[set[str]] = []
    matched_tokens: list[str] = []
    unmatched_tokens: list[str] = []
    for tok in tokens:
        norm = _normalise_awing(tok)
        if norm in vocab:
            matched_tokens.append(tok)
            vocab_meanings.append(vocab[norm])
        else:
            unmatched_tokens.append(tok)

    union_meanings: set[str] = set().union(*vocab_meanings) if vocab_meanings else set()
    overlap = english_words & union_meanings

    pair["bible_match"] = bible_match
    pair["matched_tokens"] = matched_tokens
    pair["unmatched_tokens"] = unmatched_tokens
    pair["english_words"] = sorted(english_words)
    pair["vocab_says"] = sorted(union_meanings)
    pair["overlap"] = sorted(overlap)

    if bible_match:
        pair["verdict"] = "VERIFIED-BIBLE"
    elif vocab_meanings and english_words and not overlap:
        pair["verdict"] = "MISMATCH"
    elif vocab_meanings and overlap:
        pair["verdict"] = "VERIFIED-DICT"
    else:
        pair["verdict"] = "UNKNOWN"

    return pair


# ============================================================
# Output
# ============================================================

def _row_html(p: dict) -> str:
    color = {
        "VERIFIED-BIBLE": "#dcfce7",
        "VERIFIED-DICT":  "#fef9c3",
        "MISMATCH":       "#fecaca",
        "UNKNOWN":        "#e0e7ff",
    }.get(p["verdict"], "#fff")
    bm = p.get("bible_match") or ""
    overlap = ", ".join(p["overlap"]) or "—"
    vocab_says = ", ".join(p["vocab_says"][:6]) + ("…" if len(p["vocab_says"]) > 6 else "")
    return f"""<tr style="background:{color}">
  <td>{p['verdict']}</td>
  <td><code>{p['file']}:{p['line']}</code></td>
  <td><code>{_html_safe(p['awing'])}</code></td>
  <td>{_html_safe(p['english'])}</td>
  <td>{_html_safe(vocab_says)}</td>
  <td>{_html_safe(overlap)}</td>
  <td>{_html_safe(bm)}</td>
</tr>"""


def _html_safe(s: str) -> str:
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Reading vocabulary from {VOCAB_DART.relative_to(REPO_ROOT)}...")
    vocab = parse_vocab_words(_read(VOCAB_DART))
    print(f"  Indexed {len(vocab)} unique Awing words (post-correction meanings)\n")

    print(f"Loading Bible corpus from {CORPUS_DIR.relative_to(REPO_ROOT)}...")
    bible = load_bible_verses()
    print(f"  Loaded {len(bible)} verses\n")

    pairs: list[dict] = []
    pairs += extract_pairs(VOCAB_DART)  # AwingPhrase entries
    for s in SCREENS:
        pairs += extract_pairs(s)
    print(f"Extracted {len(pairs)} (awing, english) pairs\n")

    print("Verdicting...")
    verdicted = [verdict(p, vocab, bible) for p in pairs]

    counts: dict[str, int] = defaultdict(int)
    for p in verdicted:
        counts[p["verdict"]] += 1

    print()
    print("=" * 60)
    for k in ("VERIFIED-BIBLE", "VERIFIED-DICT", "UNKNOWN", "MISMATCH"):
        n = counts.get(k, 0)
        bar = "█" * int(40 * n / max(1, len(verdicted)))
        print(f"  {k:16s} {n:4d}  {bar}")
    print("=" * 60)

    by_file: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for p in verdicted:
        by_file[p["file"]][p["verdict"]] += 1
    print("\nPer-file breakdown:")
    for f in sorted(by_file):
        row = by_file[f]
        total = sum(row.values())
        mismatched = row.get("MISMATCH", 0)
        bible = row.get("VERIFIED-BIBLE", 0)
        dict_ok = row.get("VERIFIED-DICT", 0)
        print(f"  {f:50s}  total={total:4d}  bible={bible:3d}  "
              f"dict={dict_ok:3d}  mismatch={mismatched:3d}")

    # JSON dump
    json_path = OUT_DIR / "audit.json"
    json_path.write_text(json.dumps({
        "summary": dict(counts),
        "by_file": {f: dict(d) for f, d in by_file.items()},
        "pairs": verdicted,
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nJSON: {json_path.relative_to(REPO_ROOT)}")

    # HTML report
    sorted_pairs = sorted(verdicted, key=lambda p: (
        ["MISMATCH", "UNKNOWN", "VERIFIED-DICT", "VERIFIED-BIBLE"].index(p["verdict"]),
        p["file"], p["line"],
    ))
    rows = "\n".join(_row_html(p) for p in sorted_pairs)
    summary_html = "\n".join(
        f"<li><strong>{k}:</strong> {counts.get(k, 0)}</li>"
        for k in ["MISMATCH", "UNKNOWN", "VERIFIED-DICT", "VERIFIED-BIBLE"]
    )
    html = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>App content audit</title>
<style>
  body {{ font: 14px/1.4 system-ui, sans-serif; margin: 1.5em; max-width: 1400px; }}
  h1 {{ margin-bottom: 0.3em; }}
  table {{ border-collapse: collapse; width: 100%; margin-top: 1em; }}
  th, td {{ padding: 5px 8px; border-bottom: 1px solid #ddd; vertical-align: top;
            font-size: 13px; }}
  th {{ background: #fafafa; text-align: left; position: sticky; top: 0; }}
  code {{ font-size: 12px; }}
  .legend li {{ margin: 0.3em 0; }}
  .verified-bible {{ color: #15803d; }}
  .mismatch {{ color: #b91c1c; }}
</style></head><body>
<h1>App content audit</h1>
<p>Awing/English pairs from app content files, cross-checked against the
corrected vocabulary dictionary and the Awing NT corpus.</p>
<ul class="legend">{summary_html}</ul>
<p><strong>Read order:</strong> MISMATCH first (these are the broken
ones), then UNKNOWN (no signal either way — likely fabricated).
VERIFIED-DICT means each word's individual meaning supports the claim
(but doesn't validate grammar). VERIFIED-BIBLE means the exact phrase
appears in the corpus, the strongest signal.</p>
<table>
  <thead><tr>
    <th>Verdict</th><th>File:line</th><th>Awing</th><th>English claim</th>
    <th>Vocab says</th><th>Overlap</th><th>Bible match</th>
  </tr></thead>
  <tbody>
{rows}
  </tbody>
</table>
</body></html>"""
    html_path = OUT_DIR / "index.html"
    html_path.write_text(html, encoding="utf-8")
    print(f"HTML: {html_path.relative_to(REPO_ROOT)}")
    print()
    print("Open in Chrome on Windows:")
    win = str(html_path).replace("/mnt/c/", "C:\\").replace("/", "\\")
    print(f"  {win}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
