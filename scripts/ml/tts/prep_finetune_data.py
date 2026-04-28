#!/usr/bin/env python3
"""Build per-voice JSONLs for Qwen3-TTS Awing fine-tuning.

What this script produces
-------------------------
For each of the 6 locked-in voices (boy, girl, young_man, young_woman,
man, woman) — one raw_train.jsonl + raw_eval.jsonl pair containing:

  {"audio": "<absolute path to training clip wav>",
   "text":  "<Awing transcript>",
   "ref_audio": "<absolute path to that voice's reference WAV>"}

Each row uses the SAME ref_audio for that voice (per the official Qwen3
fine-tuning recipe — keeps the target voice consistent during training).

Training data sources
---------------------
1. Awing Bible NT — 7,410 train + 364 eval verse-level clips at
   corpus/aligned/piper/{train,eval}/, MMS-aligned in Session 56.
2. Dr. Sama's word recordings — 197 single-word clips at
   training_data/recordings/manifest.json. Different speaker than
   the Bible narrator, but same Awing language — adds phonetic
   variety so the model doesn't overfit to one voice's phonetics.

The ref_audio (the locked voice WAV) tells the model which voice to
output. The training audio teaches it Awing acoustics. Different speakers
in the training audio is fine and sometimes helps generalization.

Output layout
-------------
  corpus/finetune/<voice>/raw_train.jsonl
  corpus/finetune/<voice>/raw_eval.jsonl

After this runs, encode each JSONL via the official prepare_data.py:
  python ~/Qwen3-TTS/finetuning/prepare_data.py \\
      --input_jsonl corpus/finetune/boy/raw_train.jsonl \\
      --output_jsonl corpus/finetune/boy/train_with_codes.jsonl

Then train via sft_12hz.py.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path
from typing import Iterator

REPO_ROOT = Path(__file__).resolve().parents[3]
VOICE_PROMPTS = REPO_ROOT / "scripts" / "ml" / "tts" / "voice_prompts.json"
ALIGNED_DIR = REPO_ROOT / "corpus" / "aligned" / "piper"
RECORDINGS_MANIFEST = REPO_ROOT / "training_data" / "recordings" / "manifest.json"
OUT_BASE = REPO_ROOT / "corpus" / "finetune"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument(
        "--voices", nargs="+",
        help="Subset of voices to prep (default: all 6). E.g. --voices boy girl",
    )
    ap.add_argument(
        "--include-recordings", action="store_true", default=True,
        help="Include Dr. Sama's 197 word recordings in train set (default: yes).",
    )
    ap.add_argument(
        "--no-include-recordings", action="store_false",
        dest="include_recordings",
        help="EXCLUDE Dr. Sama's recordings (Bible-only training).",
    )
    ap.add_argument(
        "--max-train-clips", type=int, default=0,
        help="Cap train clips at N (for quick validators). 0 = no cap.",
    )
    args = ap.parse_args()

    if not VOICE_PROMPTS.exists():
        print(f"ERROR: voice_prompts.json missing: {VOICE_PROMPTS}")
        return 1
    voice_config = json.loads(VOICE_PROMPTS.read_text(encoding="utf-8"))
    all_voices = voice_config["voice_order"]
    voices = args.voices or all_voices

    for v in voices:
        if v not in voice_config["voices"]:
            print(f"ERROR: unknown voice '{v}'. Known: {all_voices}")
            return 1

    # --- Load training data sources -----------------------------------
    print("Loading Bible train + eval clips...")
    train_clips = list(_load_lj_clips(ALIGNED_DIR / "train"))
    eval_clips = list(_load_lj_clips(ALIGNED_DIR / "eval"))
    print(f"  Bible train clips: {len(train_clips)}")
    print(f"  Bible eval clips:  {len(eval_clips)}")

    if args.include_recordings:
        recordings = list(_load_recordings(RECORDINGS_MANIFEST))
        print(f"  Word recordings:   {len(recordings)} (Dr. Sama)")
        train_clips += recordings
    else:
        print("  Word recordings:   skipped (--no-include-recordings)")

    if args.max_train_clips and args.max_train_clips < len(train_clips):
        print(f"  Capping train clips at {args.max_train_clips} "
              f"(was {len(train_clips)})")
        train_clips = train_clips[:args.max_train_clips]

    # Sanity check — every clip must have a real WAV on disk and
    # non-empty text. Missing files break encoding silently.
    train_clips = list(_validate_clips(train_clips, label="train"))
    eval_clips = list(_validate_clips(eval_clips, label="eval"))
    print(f"  After validation: {len(train_clips)} train, {len(eval_clips)} eval")

    if not train_clips:
        print("ERROR: zero valid train clips after validation.")
        return 1

    # --- Emit per-voice JSONLs ----------------------------------------
    print(f"\nWriting JSONLs for {len(voices)} voice(s)...")
    for voice in voices:
        cfg = voice_config["voices"][voice]
        ref_wav = (REPO_ROOT / cfg["ref_wav"]).resolve()
        if not ref_wav.exists():
            print(f"  ERROR: {voice} ref_wav missing: {ref_wav}")
            print(f"         Re-run smoke_test_qwen3.py first.")
            return 1
        out_dir = OUT_BASE / voice
        out_dir.mkdir(parents=True, exist_ok=True)

        train_path = out_dir / "raw_train.jsonl"
        eval_path = out_dir / "raw_eval.jsonl"

        _write_jsonl(train_path, train_clips, ref_wav)
        _write_jsonl(eval_path, eval_clips, ref_wav)

        print(f"  {voice:14s}  ref={ref_wav.name}  "
              f"train={len(train_clips)}  eval={len(eval_clips)}")
        print(f"    {train_path.relative_to(REPO_ROOT)}")
        print(f"    {eval_path.relative_to(REPO_ROOT)}")

    print(f"\n{len(voices)} voice JSONL pair(s) written under "
          f"{OUT_BASE.relative_to(REPO_ROOT)}/")
    print()
    print("Next: encode each voice's train JSONL via prepare_data.py.")
    print("  bash scripts/ml/tts/train_voice.sh <voice>  (handles encode + train)")
    return 0


def _load_lj_clips(split_dir: Path) -> Iterator[dict]:
    """LJSpeech-format split: metadata.csv with 'id|text' lines + wav/<id>.wav."""
    metadata_csv = split_dir / "metadata.csv"
    wav_dir = split_dir / "wav"
    if not metadata_csv.exists() or not wav_dir.exists():
        return
    with open(metadata_csv, encoding="utf-8") as f:
        reader = csv.reader(f, delimiter="|")
        for row in reader:
            if len(row) < 2:
                continue
            clip_id, text = row[0], row[1]
            wav_path = wav_dir / f"{clip_id}.wav"
            yield {
                "audio": str(wav_path.resolve()),
                "text": text.strip(),
                "source": f"bible:{split_dir.name}",
                "id": clip_id,
            }


def _load_recordings(manifest_path: Path) -> Iterator[dict]:
    """Dr. Sama's 197 word recordings — manifest.json."""
    if not manifest_path.exists():
        return
    entries = json.loads(manifest_path.read_text(encoding="utf-8"))
    for e in entries:
        wav_rel = e.get("wav_path", "")
        wav_path = REPO_ROOT / wav_rel
        text = (e.get("awing") or "").strip()
        if not wav_path.exists() or not text:
            continue
        yield {
            "audio": str(wav_path.resolve()),
            "text": text,
            "source": "recordings",
            "id": e.get("key", wav_path.stem),
        }


def _validate_clips(clips: list, label: str) -> Iterator[dict]:
    """Drop clips with missing files, empty text, or unreadable wavs."""
    dropped_missing = 0
    dropped_empty = 0
    for c in clips:
        if not c.get("text", "").strip():
            dropped_empty += 1
            continue
        if not Path(c["audio"]).exists():
            dropped_missing += 1
            continue
        yield c
    if dropped_missing or dropped_empty:
        print(f"  [{label}] dropped {dropped_missing} missing wav, "
              f"{dropped_empty} empty text")


def _write_jsonl(path: Path, clips: list, ref_wav: Path) -> None:
    """Write JSONL with the official Qwen3 fine-tune format."""
    with open(path, "w", encoding="utf-8") as f:
        for c in clips:
            row = {
                "audio": c["audio"],
                "text": c["text"],
                "ref_audio": str(ref_wav),
                # Optional fields (ignored by prepare_data.py / sft_12hz.py
                # but useful for audit / future filtering):
                "source": c.get("source", "?"),
                "id": c.get("id", ""),
            }
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    sys.exit(main())
