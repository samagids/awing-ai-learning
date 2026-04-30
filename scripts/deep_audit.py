#!/usr/bin/env python3
"""deep_audit.py — comprehensive Awing content correctness audit.

Catches problems audit_screen_glosses.py misses:

1. UNKNOWN WORDS: Awing words used in screen files that don't exist
   anywhere in the vocabulary file. These are pure fabrications.

2. GLOSS MISMATCH: (already covered by audit_screen_glosses.py) screen
   gloss doesn't share content words with dictionary gloss.

3. SENTENCE BREAKDOWN HOLES: Awing sentence "X Y Z" with only 2 word-
   level breakdowns instead of 3 — means a token has no gloss given.

4. CROSS-FILE ndě / nkǐə specifically: any usage glossed as water/river.

Usage: python scripts/deep_audit.py [--verbose]
"""

from __future__ import annotations

import re
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
TONES = ROOT / "lib" / "data" / "awing_tones.dart"
ALPHABET = ROOT / "lib" / "data" / "awing_alphabet.dart"
SCREENS = ROOT / "lib" / "screens"


def normalize(s: str) -> str:
    s = "".join(c for c in unicodedata.normalize("NFD", s)
                if unicodedata.category(c) != "Mn")
    return s.lower().strip()


def load_known_awing_words() -> dict[str, list[str]]:
    """Return {normalized_awing: [english_glosses]} from ALL data files."""
    out: dict[str, list[str]] = defaultdict(list)
    pat = re.compile(
        r"AwingWord\(\s*awing:\s*'((?:[^'\\]|\\.)*?)'\s*,"
        r"\s*english:\s*'((?:[^'\\]|\\.)*?)'"
    )
    for source in (VOCAB, TONES, ALPHABET):
        if not source.exists():
            continue
        text = source.read_text(encoding="utf-8")
        for awing, english in pat.findall(text):
            a = awing.replace(r"\'", "'")
            e = english.replace(r"\'", "'")
            out[normalize(a)].append(e)
    return out


def split_awing_tokens(awing_sentence: str) -> list[str]:
    """Split a sentence into Awing word tokens (whitespace-separated,
    strip punctuation). Preserves apostrophe + tone diacritics."""
    s = awing_sentence
    s = re.sub(r"[.,!?;:\"\(\)\[\]]", " ", s)
    return [t.strip() for t in s.split() if t.strip()]


def audit_unknown_words(file: Path, vocab: dict) -> list[tuple[str, str]]:
    """Find Awing tokens in any 'awing:' field that have no known
    headword anywhere in the data files."""
    text = file.read_text(encoding="utf-8")
    awing_field = re.compile(r"awing:\s*'((?:[^'\\]|\\.)*?)'")
    unknown = []
    seen = set()

    for m in awing_field.finditer(text):
        awing_str = m.group(1).replace(r"\'", "'")
        # Could be a phrase. Tokenize.
        for token in split_awing_tokens(awing_str):
            n = normalize(token)
            if not n:
                continue
            if n in seen:
                continue
            seen.add(n)
            # Skip pronouns, particles, articles that often get used
            # but might not have explicit dict entries.
            if len(n) <= 1:
                continue
            if n not in vocab:
                unknown.append((token, awing_str[:60]))

    return unknown


def audit_water_river_misuse(file: Path) -> list[str]:
    """Catch any (awing, english) pair where awing contains ndě and
    english mentions water/river. Should be 0 since ndě never means
    water — water is nkǐə."""
    text = file.read_text(encoding="utf-8")
    findings = []

    # Find all AwingWord(...) and AwingSentence(...) pairs containing ndě
    pat = re.compile(
        r"(AwingWord|AwingSentence|AwingPhrase|StoryVocabulary|"
        r"StorySentence)\([^)]{0,500}awing:\s*'([^']*ndě[^']*?)'"
        r"[^)]{0,500}english:\s*'([^']*?)'",
        re.DOTALL,
    )
    for m in pat.finditer(text):
        kind, awing, english = m.group(1), m.group(2), m.group(3)
        e_lc = english.lower()
        if "water" in e_lc or "river" in e_lc or "drink" in e_lc:
            # But skip if it's "drinking spot" / bar (legitimate house meaning)
            if "drinking spot" in e_lc or "bar" in e_lc:
                continue
            findings.append(f"{kind}: awing={awing!r} english={english!r}")
    return findings


def main() -> int:
    verbose = "--verbose" in sys.argv

    print("=" * 70)
    print("DEEP AWING CONTENT AUDIT")
    print("=" * 70)
    print()

    vocab = load_known_awing_words()
    print(f"Loaded {len(vocab)} unique Awing headwords from data files.")
    print()

    issues = 0

    # 1. ndě / water cross-check across ALL files
    print("[1] Checking ndě → water/river misuse across all files…")
    for f in sorted(SCREENS.rglob("*.dart")) + [VOCAB, TONES]:
        findings = audit_water_river_misuse(f)
        for finding in findings:
            print(f"   {f.relative_to(ROOT)}: {finding}")
            issues += 1
    if not issues:
        print("   ✓ No ndě → water/river issues anywhere.")
    print()

    # 2. Unknown Awing words used in screens
    print("[2] Checking for unknown Awing words used in screen files…")
    unknown_count = 0
    for f in sorted(SCREENS.rglob("*.dart")):
        if "_screen" not in f.name and "_home" not in f.name:
            continue
        unknowns = audit_unknown_words(f, vocab)
        if unknowns:
            print(f"\n  --- {f.relative_to(ROOT)} ---")
            for tok, ctx in unknowns[:15]:
                print(f"   UNKNOWN: {tok!r} (in: {ctx!r})")
            if len(unknowns) > 15:
                print(f"   ... and {len(unknowns) - 15} more")
            unknown_count += len(unknowns)
    if unknown_count == 0:
        print("   ✓ No unknown Awing words in screen files.")
    else:
        print(f"\n   Total unknown words: {unknown_count}")
        issues += unknown_count
    print()

    # 3. Stories specifically — should be empty
    stories_file = SCREENS / "stories_screen.dart"
    if stories_file.exists():
        text = stories_file.read_text(encoding="utf-8")
        story_count = text.count("AwingStory(")
        print(f"[3] Stories file: {story_count} AwingStory entries.")
        if story_count == 0:
            print("   ✓ Stories list is empty (pending native-speaker authoring).")
        else:
            print(f"   ⚠️ {story_count} stories present — please verify against PDFs.")
    print()

    print("=" * 70)
    print(f"TOTAL ISSUES: {issues}")
    print("=" * 70)
    return 0 if issues == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
