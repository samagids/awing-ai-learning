#!/usr/bin/env python3
"""audit_screen_glosses.py — find Awing-English mismatches in screen files.

The screen files (stories_screen.dart, conversation_screen.dart, etc.)
have hardcoded Awing-English pairs that drifted from the dictionary
ground truth in awing_vocabulary.dart. User caught real examples:

    wâakɔ́ glossed as 'water'     → dict says wáako = sand
    ndě interpreted as 'river'   → dict says ndě = neck/water/house

This script:
1. Parses awing_vocabulary.dart for the authoritative gloss of each
   Awing word.
2. Walks lib/screens/ for every (awing, english) pair (StoryVocabulary,
   _ConversationLine, _SentenceTemplate, etc.).
3. Reports each pair where the dict's gloss for that Awing word doesn't
   share any content word with the screen file's gloss.

Output: one line per mismatch, grouped by source file. Reports total
counts at the end.

Run: python scripts/audit_screen_glosses.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from collections import defaultdict
import unicodedata

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
SCREENS = ROOT / "lib" / "screens"


STOPWORDS = {
    "the", "a", "an", "to", "of", "in", "at", "on", "and", "or", "but",
    "is", "was", "are", "were", "be", "been", "being", "have", "has",
    "had", "do", "does", "did", "for", "by", "with", "from", "into",
    "onto", "upon", "this", "that", "these", "those", "it", "its",
    "as", "if", "so", "her", "his", "their", "they", "them", "she",
    "he", "we", "us", "you", "your", "my", "our", "i", "me", "out",
    "up", "down", "off", "over", "under", "again", "go", "going",
    "went", "gone", "come", "came", "coming",
}


def normalize_awing(s: str) -> str:
    """Strip combining diacritics + lowercase. Used for fuzzy matching when
    a word's exact diacritic pattern varies between vocab and screen."""
    s = "".join(c for c in unicodedata.normalize("NFD", s)
                if unicodedata.category(c) != "Mn")
    return s.lower().strip()


def tokenize_gloss(gloss: str) -> set[str]:
    """Lowercase, strip punctuation, drop stopwords, return a set of
    content words."""
    g = gloss.lower()
    g = re.sub(r"[^a-zəɛɔɨŋ\s']", " ", g)
    tokens = {t for t in g.split() if t and t not in STOPWORDS and len(t) > 1}
    return tokens


def load_vocab() -> dict[str, list[str]]:
    """Return {normalized_awing: [english_glosses]} from awing_vocabulary.dart."""
    if not VOCAB.exists():
        print(f"ERROR: {VOCAB} not found", file=sys.stderr)
        sys.exit(1)

    text = VOCAB.read_text(encoding="utf-8")
    pat = re.compile(
        r"AwingWord\(\s*awing:\s*'((?:[^'\\]|\\.)*?)'\s*,"
        r"\s*english:\s*'((?:[^'\\]|\\.)*?)'"
    )
    out: dict[str, list[str]] = defaultdict(list)
    for awing, english in pat.findall(text):
        a = awing.replace(r"\'", "'")
        e = english.replace(r"\'", "'")
        out[normalize_awing(a)].append(e)
        # Also index by normalized + diacritic-stripped lowercase only of the awing
    return out


# Patterns we look for in screen files. We match (awing, english) pairs
# in any constructor call where both fields appear in the same call.
SCREEN_PATTERNS = [
    re.compile(
        r"(?:StoryVocabulary|StorySentence|_ConversationLine|"
        r"_SentenceTemplate|_QuizParagraph|AwingPhrase|AwingSentence|"
        r"AwingWord)\([^)]*?awing:\s*'((?:[^'\\]|\\.)*?)'"
        r"[^)]*?english:\s*'((?:[^'\\]|\\.)*?)'",
        re.DOTALL,
    ),
]


def audit_file(path: Path, vocab: dict[str, list[str]]) -> list[tuple[str, str, list[str]]]:
    """Return list of (awing, screen_english, dict_glosses) tuples for
    each entry where the screen's gloss has no shared content words with
    any of the dict's glosses for that Awing word."""
    text = path.read_text(encoding="utf-8")
    results = []

    seen = set()
    for pat in SCREEN_PATTERNS:
        for m in pat.finditer(text):
            awing_raw = m.group(1).replace(r"\'", "'")
            english_raw = m.group(2).replace(r"\'", "'")
            key = (awing_raw, english_raw)
            if key in seen:
                continue
            seen.add(key)

            norm = normalize_awing(awing_raw)
            # Awing grammatical particles legitimately have multiple
            # correct uses (a = pronoun OR subject marker, tə = pronoun
            # OR progressive aspect, lə = "but" OR locative). Don't
            # flag them — both senses are correct.
            if norm in {"a", "ə", "kə", "tə", "lə", "nə", "ma", "po",
                        "pə", "yə", "yi", "ne", "li"}:
                continue
            dict_glosses = vocab.get(norm, [])
            if not dict_glosses:
                # Word not in vocab — can't audit.
                continue

            screen_tokens = tokenize_gloss(english_raw)
            if not screen_tokens:
                continue

            # Check overlap with ANY dict gloss
            matched = False
            for dg in dict_glosses:
                dict_tokens = tokenize_gloss(dg)
                if screen_tokens & dict_tokens:
                    matched = True
                    break

            if not matched:
                results.append((awing_raw, english_raw, dict_glosses))

    return results


def main() -> int:
    vocab = load_vocab()
    print(f"Loaded {len(vocab)} unique Awing headwords from vocab.")
    print()

    total = 0
    files = sorted(SCREENS.rglob("*.dart"))
    for f in files:
        if "_screen" not in f.name and "_home" not in f.name:
            continue
        mismatches = audit_file(f, vocab)
        if not mismatches:
            continue

        rel = f.relative_to(ROOT)
        print(f"=== {rel} — {len(mismatches)} mismatches ===")
        for awing, screen_eng, dict_glosses in mismatches:
            dg_short = "; ".join(d[:60] for d in dict_glosses[:3])
            print(f"  {awing!r}")
            print(f"     screen says: {screen_eng[:80]!r}")
            print(f"     dict says:   {dg_short!r}")
        print()
        total += len(mismatches)

    print(f"Total mismatches: {total}")
    return 0 if total == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
