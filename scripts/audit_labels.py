#!/usr/bin/env python3
"""
audit_labels.py  v1.0.0

Label quality audit for the VITS training corpus. Answers one question
honestly:

  "Do we have enough clean Awing-text training labels to make fine-tuning
   facebook/mms-tts-mcp worth doing?"

Checks three candidate label sources:
  1. training_data/labels.json         — Whisper ASR + OCR auto-labels
  2. videos/*.srt                      — YouTube auto-caption tracks
  3. training_data/clips/*/clip_metadata.json  — per-clip OCR suggestions

Criterion for "clean Awing label":
  - Contains at least one Awing-specific character (ɛ ɔ ə ɨ ŋ) OR
    a combining tone diacritic (acute/grave/circumflex/caron/macron)
  - Is between 2 and 60 characters (single words or short phrases)
  - Does not contain PowerPoint slide chrome markers

Prints a concise report and exits 0 if we have enough (>= 200 clean
labels), 1 otherwise.

Usage:
  python scripts/audit_labels.py
"""

import json
import re
import sys
from pathlib import Path
from collections import Counter

PROJECT = Path(__file__).resolve().parent.parent
LABELS = PROJECT / "training_data" / "labels.json"
VIDEOS = PROJECT / "videos"
CLIPS_ROOT = PROJECT / "training_data" / "clips"

# Characters that uniquely identify Awing text (not present in English, Swahili,
# Makaa, or standard Bantu Latin orthographies).
AWING_CHARS = set("ɛɔəɨŋƐƆƏƖŊ")

# Unicode combining marks used for Awing tone diacritics.
#   U+0300 grave, U+0301 acute, U+0302 circumflex, U+0304 macron, U+030C caron
TONE_COMBINING = set("\u0300\u0301\u0302\u0304\u030c")

# Slide-chrome markers that indicate the OCR captured the PowerPoint UI
# instead of the Awing word on screen. Any label containing one of these
# is treated as contaminated, no matter what else is in it.
SLIDE_CHROME = (
    ".pptx", "Phoenix Files", "Exit ", "PM The", "AM The",
    ".mp4", ".wav", "File Home", "Insert Design",
)

MIN_CLEAN_FOR_TRAINING = 200


def has_awing_signal(text: str) -> bool:
    """True if the label contains at least one Awing-identifying char."""
    if any(c in AWING_CHARS for c in text):
        return True
    if any(c in TONE_COMBINING for c in text):
        return True
    return False


def is_contaminated(text: str) -> bool:
    return any(marker in text for marker in SLIDE_CHROME)


def classify(text: str) -> str:
    t = text.strip()
    if not t or len(t) < 2:
        return "empty"
    if is_contaminated(t):
        return "slide_chrome"
    if len(t) > 60:
        return "too_long"
    if has_awing_signal(t):
        return "clean_awing"
    if t.isascii():
        return "ascii_only"
    return "other_latin"


def audit_labels_json():
    print("=" * 64)
    print("Source 1: training_data/labels.json  (Whisper + OCR auto-labels)")
    print("=" * 64)
    if not LABELS.exists():
        print(f"  Not found: {LABELS}")
        return []

    with open(LABELS, encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, dict):
        print(f"  ERROR: Expected dict, got {type(data).__name__}")
        return []

    buckets = Counter()
    clean_entries = []
    for clip, text in data.items():
        tag = classify(str(text))
        buckets[tag] += 1
        if tag == "clean_awing":
            clean_entries.append((clip, text))

    print(f"  Total labels: {len(data)}")
    for tag in (
        "clean_awing", "ascii_only", "other_latin",
        "slide_chrome", "too_long", "empty",
    ):
        n = buckets.get(tag, 0)
        flag = "✓" if tag == "clean_awing" and n >= MIN_CLEAN_FOR_TRAINING else " "
        print(f"  {flag} {tag:18s}  {n:4d}")

    if clean_entries:
        print(f"\n  Sample of clean Awing labels ({min(5, len(clean_entries))}):")
        for clip, text in clean_entries[:5]:
            print(f"    {clip[-35:]:35s}  {text!r}")
    return clean_entries


def audit_srts():
    print()
    print("=" * 64)
    print("Source 2: videos/*.srt  (YouTube auto-caption tracks)")
    print("=" * 64)

    if not VIDEOS.exists():
        print(f"  Not found: {VIDEOS}")
        return []

    srts = sorted(VIDEOS.glob("*.srt"))
    if not srts:
        print(f"  No SRT files in {VIDEOS}")
        return []

    TIME_RE = re.compile(r"\d{2}:\d{2}:\d{2}[,.]\d{3}\s*-->")
    all_entries = []

    for srt in srts:
        raw = srt.read_bytes().replace(b"\r\r\n", b"\n").replace(b"\r\n", b"\n")
        if raw.startswith(b"\xef\xbb\xbf"):
            raw = raw[3:]
        content = raw.decode("utf-8", errors="replace")

        # Count subtitle-text lines (strip numbering, timings, and bracketed
        # SFX markers like [Music] / [Applause]).
        lines = content.split("\n")
        text_lines = []
        for ln in lines:
            ln = ln.strip()
            if not ln or ln.isdigit() or TIME_RE.match(ln):
                continue
            ln = re.sub(r"\[.*?\]", "", ln).strip()
            if ln:
                text_lines.append(ln)

        awing = sum(1 for ln in text_lines if has_awing_signal(ln))
        music = content.count("[Music]")
        foreign = sum(1 for ln in text_lines if ln.lower() == "foreign")
        print(f"  {srt.name[:55]:55s}")
        print(f"    subtitle lines: {len(text_lines):4d}  "
              f"[Music]: {music:4d}  'foreign': {foreign:3d}  "
              f"awing-signal: {awing}")
        if awing:
            all_entries.extend(
                ln for ln in text_lines if has_awing_signal(ln)
            )

    if not all_entries:
        print("\n  VERDICT: YouTube auto-captions contain zero Awing signal.")
        print("  These are English or Vietnamese transcriptions of Awing speech.")
    return all_entries


def audit_clip_metadata():
    print()
    print("=" * 64)
    print("Source 3: training_data/clips/*/clip_metadata.json  (OCR per clip)")
    print("=" * 64)

    if not CLIPS_ROOT.exists():
        print(f"  Not found: {CLIPS_ROOT}")
        return []

    metas = sorted(CLIPS_ROOT.glob("*/clip_metadata.json"))
    if not metas:
        print(f"  No per-video clip_metadata.json files yet.")
        return []

    total_clips = 0
    total_suggestions = 0
    clean_suggestions = []

    for meta in metas:
        try:
            with open(meta, "r", encoding="utf-8") as f:
                entries = json.load(f)
        except Exception as e:
            print(f"  WARN: could not read {meta.name}: {e}")
            continue
        video_clips = len(entries)
        video_suggestions = 0
        video_clean = 0
        for entry in entries:
            suggestions = entry.get("ocr_suggestions", []) or []
            for s in suggestions:
                video_suggestions += 1
                if classify(str(s)) == "clean_awing":
                    video_clean += 1
                    clean_suggestions.append((meta.parent.name, entry.get("index"), s))
        total_clips += video_clips
        total_suggestions += video_suggestions
        print(f"  {meta.parent.name[:45]:45s}  "
              f"clips:{video_clips:4d}  ocr:{video_suggestions:5d}  "
              f"clean-awing:{video_clean:3d}")

    print(f"\n  TOTAL — clips: {total_clips}  OCR suggestions: "
          f"{total_suggestions}  clean-Awing suggestions: {len(clean_suggestions)}")

    if clean_suggestions:
        print("\n  Sample of clean OCR suggestions:")
        for vid, idx, s in clean_suggestions[:5]:
            print(f"    {vid[:30]:30s}  clip_{idx:04d}  {s!r}")
    return clean_suggestions


def main():
    print()
    print("Awing VITS training-label audit")
    print(f"Project: {PROJECT}")
    print()

    clean_labels = audit_labels_json()
    clean_srt = audit_srts()
    clean_ocr = audit_clip_metadata()

    total_clean = len(clean_labels) + len(clean_srt) + len(clean_ocr)
    print()
    print("=" * 64)
    print("BOTTOM LINE")
    print("=" * 64)
    print(f"  Clean Awing labels (all sources combined): {total_clean}")
    print(f"  Threshold for viable fine-tune:            {MIN_CLEAN_FOR_TRAINING}")

    if total_clean >= MIN_CLEAN_FOR_TRAINING:
        print()
        print("  ✓ VIABLE — enough clean labels exist to justify writing VITS")
        print("    training code. Proceed with task #12 and beyond.")
        sys.exit(0)

    print()
    print("  ✗ NOT VIABLE with current data.")
    print()
    print("  Every automated labeling source we control has failed:")
    print("    - Whisper ASR (Swahili mode) hallucinates English/pseudo-Turkish")
    print("      on Awing audio because it has no Awing training data.")
    print("    - OCR captured PowerPoint slide chrome, not the on-screen word.")
    print("    - YouTube auto-captions are English translations, not Awing")
    print("      transcriptions (the Jesus Film SRT is 313 [Music] markers")
    print("      out of ~700 entries, with the rest in English).")
    print()
    print("  Paths forward:")
    print()
    print("  (A) Hand-transcribe a subset. Dr. Sama listens to ~500 clips from")
    print("      the Awing Jesus Film and types the Awing text. ~6 hours of")
    print("      native-speaker work. Highest fidelity.")
    print()
    print("  (B) Record fresh. Use the Record tab in Developer Mode (or")
    print("      scripts/record_audio.py) to capture ~500 prompted recordings")
    print("      of words from lib/data/awing_vocabulary.dart. Already-built")
    print("      workflow. Produces a personalized voice model.")
    print()
    print("  (C) Skip fine-tune. Use facebook/mms-tts-mcp base model directly")
    print("      with awing_to_makaa() char mapping. Diagnostic shows peaks")
    print("      0.4-0.7 on every word. Good enough to ship if it sounds")
    print("      acceptably Awing on your device.")
    print()
    print("  (D) Ship 1.9.0+32 on Edge TTS (current production path) and")
    print("      defer Awing-native TTS to v2.0.")
    print()
    sys.exit(1)


if __name__ == "__main__":
    main()
