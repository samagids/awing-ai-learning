#!/usr/bin/env python3
"""
record_test_words.py  v1.0.0  (Session 53)

Records the 20 held-out bake-off test words into a SEPARATE directory:
   training_data/test_recordings/

These words must NEVER be added to the VITS training set, otherwise the
A/B/C bake-off becomes invalid (you can't measure generalization on data
the model trained on). The shortlist lives at:
   training_data/test_recordings/shortlist.json

Reuses the Recorder class and record_session loop from record_audio.py
by monkey-patching its module-level OUTPUT_DIR / MANIFEST_PATH constants.

Usage:
    python scripts/record_test_words.py            # Record (resumes)
    python scripts/record_test_words.py --list     # Show what's recorded
    python scripts/record_test_words.py --start-from 5
"""

import os
import sys
import json
import argparse
import subprocess
from pathlib import Path


# ---------------------------------------------------------------------------
# Auto-activate venv (same pattern as the rest of scripts/)
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
# Re-route record_audio to our test directory BEFORE importing its functions
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
TEST_DIR = PROJECT_ROOT / "training_data" / "test_recordings"
TEST_DIR.mkdir(parents=True, exist_ok=True)

import record_audio  # noqa: E402  (must come AFTER venv re-activation)

# Override module-level paths so record_session writes to test_recordings/
record_audio.OUTPUT_DIR = TEST_DIR
record_audio.MANIFEST_PATH = TEST_DIR / "manifest.json"
record_audio.METADATA_CSV = TEST_DIR / "metadata.csv"
record_audio.SHORTLIST_PATH = TEST_DIR / "shortlist.json"


# ---------------------------------------------------------------------------
# Patched record_session that writes 'training_data/test_recordings/...' paths
# in the manifest (otherwise it hardcodes 'training_data/recordings/...')
# ---------------------------------------------------------------------------
_orig_record_session = record_audio.record_session

def _patched_record_session(shortlist, recorder, start_from: int = 0):
    """Wrap record_session so the saved wav_path field points to test_recordings."""
    # Inject a small post-write hook by patching save_manifest to rewrite paths.
    orig_save = record_audio.save_manifest

    def _save_with_correct_paths(entries):
        for e in entries:
            # Rewrite any old training_data/recordings/ paths to test_recordings/
            if e.get("wav_path", "").startswith("training_data/recordings/"):
                e["wav_path"] = e["wav_path"].replace(
                    "training_data/recordings/",
                    "training_data/test_recordings/", 1)
        orig_save(entries)

    record_audio.save_manifest = _save_with_correct_paths
    try:
        _orig_record_session(shortlist, recorder, start_from)
    finally:
        record_audio.save_manifest = orig_save


record_audio.record_session = _patched_record_session


# ---------------------------------------------------------------------------
# Load the curated 20-word test shortlist (Session 53)
# ---------------------------------------------------------------------------
def load_test_shortlist():
    path = TEST_DIR / "shortlist.json"
    if not path.exists():
        print(f"ERROR: missing test shortlist at {path}")
        print("It should have been created at the start of Session 53.")
        sys.exit(1)
    data = json.loads(path.read_text(encoding="utf-8"))
    return data["shortlist"]


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Record the 20 held-out bake-off test words.")
    parser.add_argument("--list", action="store_true",
                        help="Show progress and exit")
    parser.add_argument("--start-from", type=int, default=0,
                        help="Skip the first N words (1-indexed position)")
    args = parser.parse_args()

    shortlist = load_test_shortlist()

    print("=" * 64)
    print("  AWING VITS BAKE-OFF — Ground-truth recording")
    print("=" * 64)
    print(f"  Output dir: {TEST_DIR.relative_to(PROJECT_ROOT)}")
    print(f"  Test words: {len(shortlist)}")
    print(f"  Purpose:    held-out evaluation of A/B/C voice variants")
    print()

    if args.list:
        manifest = record_audio.load_manifest()
        have = {e["key"] for e in manifest}
        for i, s in enumerate(shortlist, 1):
            mark = "✓" if s["key"] in have else " "
            print(f"  [{mark}] {i:2d}. {s['awing']:12s} ({s['english']})")
        print(f"\n  Recorded: {len(have)}/{len(shortlist)}")
        return

    recorder = record_audio.Recorder()
    record_audio.record_session(shortlist, recorder, start_from=args.start_from)


if __name__ == "__main__":
    main()
