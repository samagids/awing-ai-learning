#!/usr/bin/env python3
"""
record_xtts_reference.py  v1.0.0

Capture ONE continuous 30-second recording of natural Awing speech and
save it as the XTTS v2 speaker reference at:

    models/awing_xtts_speaker_ref.wav

Why this exists:
  The previous speaker reference was auto-built by `xtts_bakeoff.py setup`
  from 3-5 of Dr. Sama's longest single-word recordings concatenated with
  200ms silences. XTTS v2 was trained on continuous natural speech and
  cannot extract a stable timbre vector from that disjoint shape — it
  falls back toward its English-weighted trained mean voice, which is why
  the synthesized test words came out English-phonetic instead of
  Awing-phonetic.

  One unbroken 20-30 second take of natural Awing (a story paragraph,
  an anecdote, free-form narration — anything continuous) gives XTTS the
  shape of reference it expects. Tone, rhythm, and timbre all come
  through intact.

What to say during the 30 seconds:
  Anything in Awing — a story, a prayer, a greeting to a friend, reading
  aloud from the orthography PDF, describing your day. Speak naturally
  at a normal pace. Avoid long pauses. If you stumble, keep going — it's
  fine, XTTS just needs ~20+ seconds of continuous voice.

After this script finishes:
  python scripts\\xtts_bakeoff.py synthesize --force

  This will re-render the 20 test words using the new reference.
  Then open training_data\\test_recordings\\bakeoff.html to rate.

Usage:
  python scripts\\record_xtts_reference.py               # Standard 30s take
  python scripts\\record_xtts_reference.py --seconds 25  # Custom length (>=15)
  python scripts\\record_xtts_reference.py --device 2    # Pick a specific mic
  python scripts\\record_xtts_reference.py --list-devices
"""

import os
import sys
import argparse
import subprocess
import time
from pathlib import Path


# ---------------------------------------------------------------------------
# Auto-activate main venv (sounddevice + soundfile live there; XTTS lives
# in venv_coqui but this script does NOT touch XTTS — it just records).
# ---------------------------------------------------------------------------
def _ensure_venv():
    if sys.prefix != sys.base_prefix:
        return
    project_root = Path(__file__).resolve().parent.parent
    if sys.platform == "win32":
        venv_python = project_root / "venv" / "Scripts" / "python.exe"
    else:
        venv_python = project_root / "venv" / "bin" / "python"
    if not venv_python.exists():
        print("WARNING: venv not found. Run install_dependencies.bat first.")
        return
    if os.path.abspath(sys.executable) == os.path.abspath(str(venv_python)):
        return
    print(f"Auto-activating venv: {venv_python}")
    result = subprocess.run([str(venv_python)] + sys.argv, cwd=str(project_root))
    sys.exit(result.returncode)


_ensure_venv()


# ---------------------------------------------------------------------------
# Imports that require the venv
# ---------------------------------------------------------------------------
try:
    import sounddevice as sd
    import soundfile as sf
    import numpy as np
except ImportError as e:
    print(f"\nERROR: Missing required package ({e}).")
    print("Run: venv\\Scripts\\pip install sounddevice soundfile numpy")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
MODELS_DIR = PROJECT_ROOT / "models"
OUTPUT_PATH = MODELS_DIR / "awing_xtts_speaker_ref.wav"
BACKUP_DIR = MODELS_DIR / "_xtts_reference_history"

SAMPLE_RATE = 22050   # XTTS v2 expects 22050 Hz
CHANNELS = 1          # Mono
DTYPE = "int16"       # PCM16

DEFAULT_SECONDS = 30
MIN_SECONDS = 15      # Below 15s, XTTS cloning becomes unreliable
MAX_SECONDS = 60      # Above 60s, XTTS ignores the tail anyway


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def list_devices() -> None:
    """Print all input devices with their IDs."""
    print("\nAvailable input devices:")
    print("=" * 70)
    devs = sd.query_devices()
    default_in = sd.default.device[0] if isinstance(sd.default.device, (list, tuple)) else sd.default.device
    for i, d in enumerate(devs):
        if d.get("max_input_channels", 0) > 0:
            marker = " (default)" if i == default_in else ""
            name = d.get("name", "?")
            chans = d.get("max_input_channels", 0)
            sr = int(d.get("default_samplerate", 0))
            print(f"  [{i}] {name}{marker}")
            print(f"      channels={chans}  default_samplerate={sr}")
    print("=" * 70)
    print("\nUse --device <id> to pick a specific mic.")


def backup_existing() -> None:
    """Save the current reference under _xtts_reference_history/ before
    overwriting, so we never destroy a working reference."""
    if not OUTPUT_PATH.exists():
        return
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    stamp = time.strftime("%Y%m%d_%H%M%S")
    dest = BACKUP_DIR / f"awing_xtts_speaker_ref_{stamp}.wav"
    try:
        import shutil
        shutil.copy2(OUTPUT_PATH, dest)
        print(f"  Backed up previous reference to: {dest.relative_to(PROJECT_ROOT)}")
    except Exception as e:
        print(f"  WARNING: could not back up previous reference: {e}")


def countdown(seconds: int = 3) -> None:
    """Print a countdown before recording starts."""
    for n in range(seconds, 0, -1):
        print(f"  Starting in {n}...", flush=True)
        time.sleep(1.0)
    print("\n  >>> SPEAK NOW <<<\n", flush=True)


def record_reference(seconds: int, device: int | None) -> np.ndarray:
    """Record a single continuous clip and return the int16 samples."""
    total_frames = int(seconds * SAMPLE_RATE)
    # Preallocate the buffer so we don't rely on streaming callbacks.
    buf = np.zeros((total_frames, CHANNELS), dtype=np.int16)

    stream_kwargs = dict(
        samplerate=SAMPLE_RATE,
        channels=CHANNELS,
        dtype=DTYPE,
    )
    if device is not None:
        stream_kwargs["device"] = device

    # sd.rec is blocking when combined with sd.wait — perfect for this.
    recording = sd.rec(frames=total_frames, **stream_kwargs)

    # Progress bar during the take (text-mode, updates once per second).
    for elapsed in range(1, seconds + 1):
        remaining = seconds - elapsed
        bar_width = 40
        filled = int(bar_width * elapsed / seconds)
        bar = "#" * filled + "-" * (bar_width - filled)
        print(f"\r  [{bar}] {elapsed:2d}/{seconds}s  (remaining: {remaining:2d}s)", end="", flush=True)
        time.sleep(1.0)
    print()

    sd.wait()
    buf[:] = recording
    return buf


def summarize_take(samples: np.ndarray) -> None:
    """Print basic sanity checks so the user knows the take is usable."""
    if samples.size == 0:
        print("  WARNING: recorded buffer is empty — is the mic muted?")
        return
    # Peak level (int16 fullscale = 32767)
    peak = int(np.max(np.abs(samples)))
    peak_db = 20 * np.log10(peak / 32767.0) if peak > 0 else -120.0
    # Rough silence ratio: frames below 1% of fullscale
    silence_thresh = int(0.01 * 32767)
    silent_frames = int(np.sum(np.max(np.abs(samples), axis=1) < silence_thresh))
    silent_pct = 100.0 * silent_frames / len(samples)
    duration = len(samples) / SAMPLE_RATE

    print("  Take summary:")
    print(f"    duration      : {duration:.2f} s")
    print(f"    peak level    : {peak_db:+.1f} dBFS  (should be between -12 and -1)")
    print(f"    silent frames : {silent_pct:.1f}%        (ideally < 15%)")

    warnings = []
    if peak_db < -18:
        warnings.append("- recording is too quiet; speak closer or raise mic gain")
    if peak_db > -0.5:
        warnings.append("- recording is clipping; move back or lower mic gain")
    if silent_pct > 30:
        warnings.append("- long silences detected; try to talk continuously next take")
    if duration < MIN_SECONDS:
        warnings.append(f"- take is shorter than {MIN_SECONDS}s; XTTS needs more context")

    if warnings:
        print("\n  Suggestions for a better take:")
        for w in warnings:
            print(f"    {w}")
    else:
        print("\n  Take looks good.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> int:
    parser = argparse.ArgumentParser(
        description="Record a continuous speaker reference for XTTS v2.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--seconds",
        type=int,
        default=DEFAULT_SECONDS,
        help=f"Length of the take (default: {DEFAULT_SECONDS}; min: {MIN_SECONDS}; max: {MAX_SECONDS})",
    )
    parser.add_argument(
        "--device",
        type=int,
        default=None,
        help="Input device ID (see --list-devices). Defaults to system default.",
    )
    parser.add_argument(
        "--list-devices",
        action="store_true",
        help="List available input devices and exit.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=OUTPUT_PATH,
        help=f"Output WAV path (default: {OUTPUT_PATH.relative_to(PROJECT_ROOT)})",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Don't back up the existing reference before overwriting.",
    )
    args = parser.parse_args()

    if args.list_devices:
        list_devices()
        return 0

    seconds = max(MIN_SECONDS, min(MAX_SECONDS, args.seconds))
    if seconds != args.seconds:
        print(f"Clamped --seconds to {seconds} (range {MIN_SECONDS}-{MAX_SECONDS}).")

    out_path: Path = args.output
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # ---- Banner + instructions ------------------------------------------------
    print("=" * 70)
    print("  XTTS v2 — Speaker Reference Recorder")
    print("=" * 70)
    print(f"  Output    : {out_path.relative_to(PROJECT_ROOT)}")
    print(f"  Duration  : {seconds} seconds (one continuous take)")
    print(f"  Format    : {SAMPLE_RATE} Hz mono PCM16 (XTTS v2 reference spec)")

    # Show which device will be used
    try:
        default_in = sd.default.device[0] if isinstance(sd.default.device, (list, tuple)) else sd.default.device
        dev_id = args.device if args.device is not None else default_in
        dev_info = sd.query_devices(dev_id)
        print(f"  Mic       : [{dev_id}] {dev_info.get('name', '?')}")
    except Exception as e:
        print(f"  Mic       : (unable to query device: {e})")

    if out_path.exists() and not args.no_backup:
        print(f"\n  Existing reference will be backed up (use --no-backup to skip).")

    print()
    print("  What to say:")
    print("    Anything in Awing — a story, a prayer, reading from the")
    print("    orthography PDF, describing your day. Speak naturally at")
    print("    a normal pace. Avoid long pauses. If you stumble, keep going.")
    print()
    print("  Ready? Press ENTER to start the countdown, or Ctrl+C to cancel.")
    try:
        input()
    except KeyboardInterrupt:
        print("\n  Cancelled.")
        return 130

    # ---- Countdown + record ---------------------------------------------------
    countdown(3)
    try:
        samples = record_reference(seconds, args.device)
    except KeyboardInterrupt:
        print("\n  Cancelled during recording; nothing was saved.")
        return 130
    except Exception as e:
        print(f"\n  ERROR during recording: {e}")
        return 1

    print("  Stopped recording.\n")

    # ---- Summary + save -------------------------------------------------------
    summarize_take(samples)

    if not args.no_backup:
        backup_existing()

    try:
        # soundfile expects float or int; we already have int16 so pass through.
        # Squeeze out the channel dim for mono since sf prefers 1-D.
        mono = samples[:, 0] if samples.ndim == 2 else samples
        sf.write(str(out_path), mono, SAMPLE_RATE, subtype="PCM_16")
    except Exception as e:
        print(f"\n  ERROR writing WAV: {e}")
        return 1

    size_mb = out_path.stat().st_size / (1024 * 1024)
    print(f"\n  Saved: {out_path.relative_to(PROJECT_ROOT)}  ({size_mb:.2f} MB)")

    # ---- Next steps -----------------------------------------------------------
    print()
    print("=" * 70)
    print("  NEXT STEP")
    print("=" * 70)
    print("  Re-render the 20 test words with the new reference:")
    print()
    print("    python scripts\\xtts_bakeoff.py synthesize --force")
    print()
    print("  Then refresh the bake-off page and rate:")
    print()
    print("    python scripts\\bakeoff.py html")
    print("    start training_data\\test_recordings\\bakeoff.html")
    print()
    print("  If this take doesn't sound natural enough, just re-run:")
    print("    python scripts\\record_xtts_reference.py")
    print("  (the previous reference is preserved in models\\_xtts_reference_history\\)")
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
