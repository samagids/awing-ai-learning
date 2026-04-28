#!/usr/bin/env python3
"""Place Dr. Sama's recorded Awing WAVs into the PAD asset pack as the
'native' voice tier — the app's highest-priority audio source.

Reads:  training_data/recordings/manifest.json
Writes: android/install_time_assets/src/main/assets/audio/native/<category>/<key>.mp3

The Flutter app's PronunciationService searches `assets/audio/native/...`
first, then falls back to the per-character Edge TTS Swahili voices for
words without a recording. So every character (boy, girl, young_man,
young_woman, man, woman) plays the authentic recording for the 197
words covered, and the synthesised approximation only for the rest.

Usage:
    python3 scripts/apply_recordings_as_audio.py
        # Convert all WAVs to MP3 and write under audio/native/

    python3 scripts/apply_recordings_as_audio.py --dry-run
        # List what would be written without touching disk

    python3 scripts/apply_recordings_as_audio.py --force
        # Overwrite existing native MP3s even if newer than source WAV
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import unicodedata
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
RECORDINGS_DIR = REPO_ROOT / "training_data" / "recordings"
MANIFEST = RECORDINGS_DIR / "manifest.json"
NATIVE_OUT = REPO_ROOT / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio" / "native"

# Map manifest "source" field -> the audio/native/<category>/ subdir
# the app's PronunciationService searches under. The app currently
# tries categories ['vocabulary', 'alphabet', 'dictionary', 'sentences']
# in order, so any unknown source falls through to vocabulary.
_SOURCE_TO_CATEGORY = {
    "alphabet": "alphabet",
    "vocabulary": "vocabulary",
    "dictionary": "dictionary",
    "sentences": "sentences",
    "phrases": "vocabulary",  # phrases live under vocabulary in the lookup
    "stories": "stories",
}

# Tone diacritics + Awing-special chars stripped to build ASCII filenames.
# MUST match the Dart-side _audioKey function in pronunciation_service.dart
# so file lookup succeeds. (Verified: the Dart side does the same NFD
# strip + replacement table.)
_TONE_DIACRITICS = {"́", "̀", "̂", "̌", "̃", "̄"}
_REPLACEMENTS = {
    "ɛ": "e", "Ɛ": "E",
    "ɔ": "o", "Ɔ": "O",
    "ə": "e", "Ə": "E",
    "ɨ": "i", "Ɨ": "I",
    "ŋ": "ng", "Ŋ": "Ng",
    "ɣ": "g", "Ɣ": "G",
    "ʼ": "", "’": "", "‘": "", "'": "",
}


def audio_key(awing: str) -> str:
    """ASCII-safe filename derived from Awing text. Mirrors
    pronunciation_service.dart's _audioKey."""
    decomp = unicodedata.normalize("NFD", awing)
    decomp = "".join(c for c in decomp if c not in _TONE_DIACRITICS)
    s = unicodedata.normalize("NFC", decomp)
    for src, dst in _REPLACEMENTS.items():
        s = s.replace(src, dst)
    s = re.sub(r"[^a-zA-Z0-9_-]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s.lower() or "_"


def convert_wav_to_mp3(wav_path: Path, mp3_path: Path) -> bool:
    """ffmpeg WAV -> MP3 at 64 kbps mono — matches the rest of the bank."""
    mp3_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        result = subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error",
             "-i", str(wav_path),
             "-codec:a", "libmp3lame",
             "-b:a", "64k",
             "-ar", "22050",
             "-ac", "1",  # mono
             str(mp3_path)],
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            print(f"    ffmpeg error: {result.stderr.decode('utf-8', errors='replace')[:200]}")
            return False
        return mp3_path.exists() and mp3_path.stat().st_size > 500
    except FileNotFoundError:
        print("ERROR: ffmpeg not on PATH. Install ffmpeg or run from the venv with ffmpeg available.")
        return False


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dry-run", action="store_true",
                    help="List what would be written without touching disk.")
    ap.add_argument("--force", action="store_true",
                    help="Overwrite existing MP3s even if newer than the WAV.")
    ap.add_argument("--source-filter", default=None,
                    help="Only process recordings with manifest.source == this "
                         "value (e.g. 'alphabet').")
    args = ap.parse_args()

    if not MANIFEST.exists():
        print(f"ERROR: {MANIFEST} not found.")
        return 1

    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))
    print(f"Manifest: {len(entries)} recordings\n")

    by_category: dict[str, int] = {}
    written, skipped, failed = 0, 0, 0

    for entry in entries:
        awing = (entry.get("awing") or "").strip()
        wav_rel = entry.get("wav_path", "")
        source = entry.get("source", "vocabulary")
        if not awing or not wav_rel:
            continue

        wav_path = REPO_ROOT / wav_rel
        if not wav_path.exists():
            print(f"  MISSING WAV: {wav_rel} (skipping)")
            failed += 1
            continue

        if args.source_filter and source != args.source_filter:
            continue

        category = _SOURCE_TO_CATEGORY.get(source, "vocabulary")
        key = audio_key(awing)
        mp3_path = NATIVE_OUT / category / f"{key}.mp3"

        if mp3_path.exists() and not args.force:
            wav_mtime = wav_path.stat().st_mtime
            mp3_mtime = mp3_path.stat().st_mtime
            if mp3_mtime >= wav_mtime:
                skipped += 1
                continue

        rel_out = mp3_path.relative_to(REPO_ROOT)
        print(f"  {awing!r:24s} ({source:11s}) -> {rel_out}")
        by_category[category] = by_category.get(category, 0) + 1

        if args.dry_run:
            written += 1
            continue

        if convert_wav_to_mp3(wav_path, mp3_path):
            written += 1
        else:
            failed += 1

    print()
    print(f"{'(DRY RUN) ' if args.dry_run else ''}"
          f"Written: {written}  Skipped (cached): {skipped}  Failed: {failed}")
    print(f"By category: {by_category}")
    print()
    print(f"Output root: {NATIVE_OUT.relative_to(REPO_ROOT)}")
    print()
    if not args.dry_run and written > 0:
        print("Next:")
        print("  flutter build appbundle --release")
        print("  # then bundletool install-apks (PAD pack includes new native/ tree)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
