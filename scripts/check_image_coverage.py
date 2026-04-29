#!/usr/bin/env python3
"""check_image_coverage.py — find vocabulary entries missing PNG images.

Compares awing_vocabulary.dart entries against actual files in
android/install_time_assets/src/main/assets/images/vocabulary/.

Image key format (matches lib/services/image_service.dart):
    {audio_key(awing)}__{english_slug(english)}.png

Run: python scripts/check_image_coverage.py [--list]
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
IMAGES = ROOT / "android" / "install_time_assets" / "src" / "main" / "assets" / "images" / "vocabulary"


def audio_key(awing: str) -> str:
    """Mirror Dart's audioKey(): NFD-strip diacritics, ɛ→e, ɔ→o, ə→e, ɨ→i, ŋ→ng,
    apostrophes/quotes → '', then lowercase + strip non-alnum."""
    s = awing
    # Strip combining marks
    s = "".join(c for c in unicodedata.normalize("NFD", s)
                if unicodedata.category(c) != "Mn")
    # Special vowels / consonants
    s = s.replace("ɛ", "e").replace("ɔ", "o").replace("ə", "e")
    s = s.replace("ɨ", "i").replace("ŋ", "ng").replace("ɣ", "g")
    s = s.replace("Ɛ", "e").replace("Ɔ", "o")
    # Quotes / apostrophes → drop
    for q in "'‘’“”′ʼ":
        s = s.replace(q, "")
    s = s.lower()
    s = re.sub(r"[^a-z0-9]", "", s)
    return s


def english_slug(english: str) -> str:
    """First word, lowercase, alnum only."""
    s = english.split(",")[0].split(";")[0].split("(")[0].strip()
    s = s.split()[0] if s.split() else s
    s = "".join(c for c in unicodedata.normalize("NFD", s)
                if unicodedata.category(c) != "Mn")
    s = s.lower()
    s = re.sub(r"[^a-z0-9]", "", s)
    return s


AWINGWORD_LINE = re.compile(
    r"AwingWord\(\s*awing:\s*'((?:[^'\\]|\\.)*?)'\s*,"
    r"\s*english:\s*'((?:[^'\\]|\\.)*?)'"
)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--list", action="store_true",
                   help="List every missing image key")
    args = p.parse_args()

    if not VOCAB.exists():
        print(f"ERROR: {VOCAB} not found", file=sys.stderr)
        return 1
    if not IMAGES.exists():
        print(f"ERROR: {IMAGES} not found", file=sys.stderr)
        return 1

    text = VOCAB.read_text(encoding="utf-8")
    entries = AWINGWORD_LINE.findall(text)

    expected_keys = set()
    entry_to_key = []
    for awing_raw, english_raw in entries:
        awing = awing_raw.replace(r"\'", "'")
        english = english_raw.replace(r"\'", "'")
        ak = audio_key(awing)
        es = english_slug(english)
        if not ak or not es:
            continue
        key = f"{ak}__{es}"
        expected_keys.add(key)
        entry_to_key.append((awing, english, key))

    actual_files = {f.stem for f in IMAGES.glob("*.png")}

    missing = expected_keys - actual_files
    extra = actual_files - expected_keys
    have = expected_keys & actual_files

    print(f"Vocabulary entries: {len(entries)}")
    print(f"Expected unique image keys: {len(expected_keys)}")
    print(f"Existing image files: {len(actual_files)}")
    print(f"  - covered (expected ∩ actual): {len(have)}")
    print(f"  - missing (need to generate): {len(missing)}")
    print(f"  - orphan (image without entry): {len(extra)}")

    if args.list and missing:
        print()
        print("Missing image keys (first 50):")
        # Show missing entries with their awing + english for context
        missing_with_context = [
            (a, e, k) for (a, e, k) in entry_to_key if k in missing
        ]
        for awing, english, key in missing_with_context[:50]:
            print(f"  {key}.png  ←  {awing!r} / {english[:40]!r}")
        if len(missing_with_context) > 50:
            print(f"  ... and {len(missing_with_context) - 50} more")

    return 0


if __name__ == "__main__":
    sys.exit(main())
