#!/usr/bin/env python3
"""
xtts_bakeoff.py  v1.0.0  (Session 55)

Variant D for the Awing voice-synthesis bake-off — Coqui XTTS v2 with a
speaker reference built from Dr. Sama's 197 hand recordings.

Why XTTS rather than another from-scratch VITS:

  Session 54's Coqui VITS fine-tune on 197 clips (5.56 min total audio)
  fell well below VITS's 1-10 hour training floor.  Mode collapse —
  every variant rendered the same "average vowel mush", indistinguishable
  per word.  Variants A/B/C in bakeoff.py all share that one collapsed
  checkpoint, so they all suffer the same problem.

  XTTS v2 inverts the data-shape problem.  It is a *pretrained
  multilingual* model designed for low-resource speaker cloning — its
  documented floor is ~6 seconds of speaker-reference audio.  We have
  333 seconds (5.56 min) of Dr. Sama's voice in a wide variety of
  Awing words; that is well above the cloning floor.  Phonetics come
  from the pretrained model + an Awing-tailored phonemizer; speaker
  timbre & prosody come from the reference.

  None of XTTS's 17 supported languages are Bantu, but Portuguese has
  unusually broad phonemic coverage of the Awing vowel inventory:
    • /ɛ/ via é, /ɔ/ via ó (open-mid vowels with explicit diacritics)
    • Brazilian unstressed /a/ ≈ /ɐ/ ≈ Awing /ə/
    • Intervocalic /g/ has a /ɣ/ allophone in casual speech
    • Syllable-timed rhythm matches Bantu rhythm better than English
  So our default phonemizer targets Portuguese.  --language can
  override (it = Italian, es = Spanish, etc) for A/B comparison.

Workflow:

  1. Build speaker reference (concatenate 3-5 longest manifest clips):
        python scripts\\xtts_bakeoff.py setup

  2. Synthesize all 20 test words through XTTS v2:
        python scripts\\xtts_bakeoff.py synthesize

  3. Wire into bakeoff.html:
        python scripts\\bakeoff.py html
        # (bakeoff.py auto-detects xtts_bakeoff/_xtts_raw/{key}.wav and
        #  populates the variant_xtts column for all 6 voice rows)

  4. status / clean utility:
        python scripts\\xtts_bakeoff.py status
        python scripts\\xtts_bakeoff.py clean

Reuses venv_coqui (the same venv that runs scripts\\train_coqui_vits.py).
The coqui-tts package ships XTTS v2 inside the same `TTS` import root,
so no separate venv is needed.

All paths are relative to the project root.
"""

import os
import sys
import json
import shutil
import argparse
import subprocess
import unicodedata
from pathlib import Path


# ---------------------------------------------------------------------------
# Auto-activate venv_coqui (the same venv that runs train_coqui_vits.py).
# XTTS v2 ships inside the coqui-tts package, so no separate venv is needed.
# ---------------------------------------------------------------------------
_VENV_NAME = "venv_coqui"
_REPO_ROOT = Path(__file__).resolve().parent.parent
if sys.platform == "win32":
    _VENV_PY = _REPO_ROOT / _VENV_NAME / "Scripts" / "python.exe"
else:
    _VENV_PY = _REPO_ROOT / _VENV_NAME / "bin" / "python"


def _in_venv_coqui() -> bool:
    try:
        return os.path.abspath(sys.executable) == os.path.abspath(str(_VENV_PY))
    except Exception:
        return False


if not _in_venv_coqui():
    if _VENV_PY.exists():
        print(f"Auto-activating {_VENV_NAME}: {_VENV_PY}")
        result = subprocess.run([str(_VENV_PY), __file__] + sys.argv[1:],
                                cwd=str(_REPO_ROOT))
        sys.exit(result.returncode)
    else:
        print(f"WARNING: {_VENV_NAME} not found at {_VENV_PY}.")
        print(f"  Create it with the recipe in scripts\\requirements_coqui.txt:")
        print(f"    python -m venv {_VENV_NAME}")
        print(f"    {_VENV_NAME}\\Scripts\\pip install -r scripts\\requirements_coqui.txt")
        print(f"  Then re-run this script.")
        # Keep going — useful for `--help` and `status` on a fresh checkout.


# ---------------------------------------------------------------------------
# Paths — mirror the layout used by bakeoff.py
# ---------------------------------------------------------------------------
PROJECT_ROOT = _REPO_ROOT
RECORDINGS_DIR = PROJECT_ROOT / "training_data" / "recordings"
RECORDINGS_MANIFEST = RECORDINGS_DIR / "manifest.json"

TEST_DIR = PROJECT_ROOT / "training_data" / "test_recordings"
SHORTLIST_PATH = TEST_DIR / "shortlist.json"
BAKEOFF_DIR = TEST_DIR / "bakeoff"
XTTS_RAW_DIR = BAKEOFF_DIR / "_xtts_raw"

MODELS_DIR = PROJECT_ROOT / "models"
SPEAKER_REF = MODELS_DIR / "awing_xtts_speaker_ref.wav"

XTTS_MODEL = "tts_models/multilingual/multi-dataset/xtts_v2"

# XTTS v2 supported languages (as of Coqui-TTS 0.27.x):
XTTS_LANGUAGES = {
    "en", "es", "fr", "de", "it", "pt", "pl", "tr", "ru", "nl",
    "cs", "ar", "zh-cn", "hu", "ko", "ja", "hi",
}
DEFAULT_LANGUAGE = "pt"  # see top-of-file rationale

# ≥6 seconds is XTTS's documented speaker-reference floor.  We aim for
# 12-20 seconds of clean speech so the cloning has plenty of timbre data.
SPEAKER_REF_TARGET_S = 18.0
SPEAKER_REF_MIN_S = 6.0
SPEAKER_REF_GAP_MS = 200  # silence between concatenated clips

# Make sure all output dirs exist (idempotent).
for d in (BAKEOFF_DIR, XTTS_RAW_DIR, MODELS_DIR):
    d.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _load_shortlist():
    if not SHORTLIST_PATH.exists():
        print(f"ERROR: shortlist missing at {SHORTLIST_PATH}")
        sys.exit(1)
    return json.loads(SHORTLIST_PATH.read_text(encoding="utf-8"))["shortlist"]


def _load_recordings_manifest():
    if not RECORDINGS_MANIFEST.exists():
        print(f"ERROR: training manifest missing at {RECORDINGS_MANIFEST}")
        print(f"  Record the 197-word training set with record_audio.py first.")
        sys.exit(1)
    return json.loads(RECORDINGS_MANIFEST.read_text(encoding="utf-8"))


def awing_to_xtts(text: str, language: str = DEFAULT_LANGUAGE) -> str:
    """
    Convert Awing orthography into a string the XTTS-v2 phonemizer for the
    chosen pretrained language can do something useful with.

    Strategy:
      1. NFD-decompose so we can strip combining tone marks (XTTS doesn't
         model lexical tones — speaker reference handles prosody).
      2. Drop the combining marks.
      3. NFC-recompose to get clean base characters.
      4. Map Awing-only graphemes to the closest target-language graphemes.

    For Portuguese (default) the open-mid vowels é/ó carry /ɛ/ and /ɔ/
    naturally, and Brazilian unstressed 'a' approximates /ə/.  For Italian
    the open-mid è/ò serve the same role.  Other languages fall back to
    plain a/e/o.
    """
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    text = unicodedata.normalize("NFC", text)

    if language == "pt":
        replacements = {
            "ɛ": "é", "Ɛ": "É",
            "ɔ": "ó", "Ɔ": "Ó",
            "ə": "a", "Ə": "A",   # Brazilian unstressed /a/ ≈ schwa
            "ɨ": "i", "Ɨ": "I",
            "ŋ": "ng", "Ŋ": "Ng",
            "ɣ": "g",
            # Glottal stop — Portuguese has no native one; a hyphen
            # forces espeak-ng to insert a syllable break instead of
            # eliding the consonants.
            "'": "-", "\u2019": "-", "\u2018": "-",
        }
    elif language == "it":
        replacements = {
            "ɛ": "è", "Ɛ": "È",
            "ɔ": "ò", "Ɔ": "Ò",
            "ə": "e", "Ə": "E",
            "ɨ": "i", "Ɨ": "I",
            "ŋ": "n", "Ŋ": "N",
            "ɣ": "gh",  # Italian 'gh' = /g/ — closest fricative neighbour
            "'": "-", "\u2019": "-", "\u2018": "-",
        }
    else:
        # Generic fallback for en/es/fr/de/etc. — drop everything Awing-only
        # to its nearest base-Latin neighbour.
        replacements = {
            "ɛ": "e", "Ɛ": "E",
            "ɔ": "o", "Ɔ": "O",
            "ə": "e", "Ə": "E",
            "ɨ": "i", "Ɨ": "I",
            "ŋ": "ng", "Ŋ": "Ng",
            "ɣ": "g",
            "'": "-", "\u2019": "-", "\u2018": "-",
        }

    for src, dst in replacements.items():
        text = text.replace(src, dst)
    return text


# ---------------------------------------------------------------------------
# setup — build the XTTS speaker reference WAV
# ---------------------------------------------------------------------------
def cmd_setup(args):
    print("\n" + "=" * 64)
    print("  XTTS VARIANT — STEP 1: Build speaker reference")
    print("=" * 64)

    if SPEAKER_REF.exists() and not args.force:
        print(f"  Speaker reference already exists: {SPEAKER_REF}")
        print(f"  Pass --force to rebuild.")
        return

    try:
        from pydub import AudioSegment
    except ImportError:
        print("  ERROR: pydub not installed in venv_coqui.")
        print(f"    {_VENV_NAME}\\Scripts\\pip install pydub")
        sys.exit(1)

    manifest = _load_recordings_manifest()
    shortlist = _load_shortlist()
    test_keys = {s["key"] for s in shortlist}

    # Disjoint check — never use a held-out test word as part of the
    # speaker reference.  Even though the speaker reference is just timbre,
    # not text, leaking the target wave through the cloner makes XTTS
    # over-confident on those exact words and pollutes the bake-off.
    candidates = [m for m in manifest if m["key"] not in test_keys]
    dropped = len(manifest) - len(candidates)
    if dropped:
        print(f"  Dropped {dropped} clips that overlap with the 20 test words.")
    print(f"  Pool: {len(candidates)} eligible training clips.")

    # Sort longest-first so we can hit the target duration with the fewest
    # concatenations (fewer joins = fewer audible discontinuities).
    candidates.sort(key=lambda m: m.get("duration_s", 0.0), reverse=True)

    chosen = []
    total_s = 0.0
    for m in candidates:
        if total_s >= SPEAKER_REF_TARGET_S:
            break
        wav_path = PROJECT_ROOT / m["wav_path"]
        if not wav_path.exists():
            continue
        chosen.append((m, wav_path))
        total_s += float(m.get("duration_s", 0.0))

    if total_s < SPEAKER_REF_MIN_S:
        print(f"  ERROR: only {total_s:.1f}s of clean reference audio "
              f"available (XTTS needs ≥{SPEAKER_REF_MIN_S}s).")
        sys.exit(1)

    print(f"  Selected {len(chosen)} clips totalling {total_s:.1f}s "
          f"(target {SPEAKER_REF_TARGET_S:.0f}s).")

    # Build the reference: PCM16 mono 22050 Hz, brief silence between clips.
    silence = AudioSegment.silent(duration=SPEAKER_REF_GAP_MS, frame_rate=22050)
    combined = AudioSegment.silent(duration=0, frame_rate=22050)
    for i, (m, wav_path) in enumerate(chosen):
        try:
            seg = AudioSegment.from_wav(str(wav_path))
        except Exception as e:
            print(f"    skip {m['key']}: {e}")
            continue
        seg = seg.set_frame_rate(22050).set_channels(1).set_sample_width(2)
        if i > 0:
            combined += silence
        combined += seg

    SPEAKER_REF.parent.mkdir(parents=True, exist_ok=True)
    combined.export(str(SPEAKER_REF), format="wav")
    actual_s = len(combined) / 1000.0
    print(f"  ✓ Wrote speaker reference: {SPEAKER_REF.relative_to(PROJECT_ROOT)}")
    print(f"    Duration: {actual_s:.1f}s  |  22050 Hz mono PCM16")
    print(f"\n  Next: python scripts\\xtts_bakeoff.py synthesize")


# ---------------------------------------------------------------------------
# synthesize — run all 20 test words through XTTS v2
# ---------------------------------------------------------------------------
def cmd_synthesize(args):
    print("\n" + "=" * 64)
    print("  XTTS VARIANT — STEP 2: Synthesize 20 test words")
    print("=" * 64)

    if not SPEAKER_REF.exists():
        print(f"  ERROR: speaker reference not found at {SPEAKER_REF}")
        print(f"  Run: python scripts\\xtts_bakeoff.py setup")
        sys.exit(1)

    language = args.language
    if language not in XTTS_LANGUAGES:
        print(f"  ERROR: language '{language}' not supported by XTTS v2.")
        print(f"  Pick one of: {', '.join(sorted(XTTS_LANGUAGES))}")
        sys.exit(1)

    try:
        import torch
        from TTS.api import TTS
    except ImportError as e:
        print(f"  ERROR: missing dependency in {_VENV_NAME}: {e}")
        print(f"    {_VENV_NAME}\\Scripts\\pip install -r scripts\\requirements_coqui.txt")
        sys.exit(1)

    use_cuda = torch.cuda.is_available()
    if use_cuda:
        gpu_name = torch.cuda.get_device_name(0)
        vram = torch.cuda.get_device_properties(0).total_memory / (1024 ** 3)
        print(f"  GPU: {gpu_name} ({vram:.1f} GB VRAM)")
    else:
        print(f"  No CUDA — XTTS will run on CPU (~30 sec/word).")

    # Coqui requires this env var on first download to silence its EULA prompt.
    os.environ.setdefault("COQUI_TOS_AGREED", "1")
    print(f"\n  Loading {XTTS_MODEL}")
    print(f"  (~2 GB download to ~/.cache/coqui/ on first run; please wait)")
    try:
        tts = TTS(model_name=XTTS_MODEL, progress_bar=False, gpu=use_cuda)
    except Exception as e:
        print(f"  ERROR loading XTTS: {e}")
        sys.exit(1)

    shortlist = _load_shortlist()
    n = len(shortlist)
    print(f"\n  Synthesizing {n} test words")
    print(f"    language:  {language}")
    print(f"    speaker:   {SPEAKER_REF.relative_to(PROJECT_ROOT)}")
    print(f"    output:    {XTTS_RAW_DIR.relative_to(PROJECT_ROOT)}/<key>.wav")
    print()

    XTTS_RAW_DIR.mkdir(parents=True, exist_ok=True)
    overrides = {}
    fail_count = 0

    for i, entry in enumerate(shortlist, 1):
        key = entry["key"]
        awing = entry["awing"]
        out_path = XTTS_RAW_DIR / f"{key}.wav"
        if out_path.exists() and not args.force:
            print(f"  [{i:2d}/{n}] {key:10s} (cached) → {out_path.name}")
            overrides[key] = awing_to_xtts(awing, language)
            continue
        phonemized = awing_to_xtts(awing, language)
        overrides[key] = phonemized
        print(f"  [{i:2d}/{n}] {key:10s}  awing='{awing}' → text='{phonemized}'",
              flush=True)
        try:
            tts.tts_to_file(
                text=phonemized,
                file_path=str(out_path),
                speaker_wav=str(SPEAKER_REF),
                language=language,
            )
        except Exception as e:
            print(f"             ✗ FAILED: {e}")
            fail_count += 1
            continue

    # Persist the phonemized text per word so the rater (and future Claude
    # sessions) can see what XTTS was actually fed.
    overrides_path = XTTS_RAW_DIR / "phonemizer_output.json"
    overrides_path.write_text(
        json.dumps({"language": language, "overrides": overrides},
                   ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    success = n - fail_count
    print(f"\n  ✓ {success}/{n} words synthesized "
          f"({fail_count} failed)")
    print(f"  Phonemizer output saved to "
          f"{overrides_path.relative_to(PROJECT_ROOT)}")
    print(f"\n  Next: python scripts\\bakeoff.py html")


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------
def cmd_status(args):
    print("\n" + "=" * 64)
    print("  XTTS VARIANT — STATUS")
    print("=" * 64)

    print(f"  venv_coqui:           "
          f"{'yes' if _VENV_PY.exists() else 'NOT YET — see top of script'}")
    print(f"  Speaker reference:    "
          f"{'yes' if SPEAKER_REF.exists() else 'NOT YET — run `setup`'}")
    if SPEAKER_REF.exists():
        sz = SPEAKER_REF.stat().st_size / (1024 * 1024)
        print(f"      file:             {SPEAKER_REF.relative_to(PROJECT_ROOT)} "
              f"({sz:.2f} MB)")

    if SHORTLIST_PATH.exists():
        shortlist = _load_shortlist()
        n = len(shortlist)
        synth = sum(1 for s in shortlist
                    if (XTTS_RAW_DIR / f"{s['key']}.wav").exists())
        print(f"  Synthesized words:    {synth}/{n}")
    else:
        print(f"  Shortlist missing at {SHORTLIST_PATH}")

    overrides_path = XTTS_RAW_DIR / "phonemizer_output.json"
    if overrides_path.exists():
        data = json.loads(overrides_path.read_text(encoding="utf-8"))
        print(f"  Last phonemizer lang: {data.get('language', '?')}")

    print()
    if not SPEAKER_REF.exists():
        print("  Next: python scripts\\xtts_bakeoff.py setup")
    elif not (XTTS_RAW_DIR / f"{_load_shortlist()[0]['key']}.wav").exists():
        print("  Next: python scripts\\xtts_bakeoff.py synthesize")
    else:
        print("  Next: python scripts\\bakeoff.py html")


# ---------------------------------------------------------------------------
# clean
# ---------------------------------------------------------------------------
def cmd_clean(args):
    print("\n" + "=" * 64)
    print("  XTTS VARIANT — CLEAN")
    print("=" * 64)
    targets = [XTTS_RAW_DIR]
    if args.deep:
        targets.append(SPEAKER_REF)
    for t in targets:
        if t.exists():
            if t.is_dir():
                shutil.rmtree(t)
                print(f"  removed dir:  {t.relative_to(PROJECT_ROOT)}")
            else:
                t.unlink()
                print(f"  removed file: {t.relative_to(PROJECT_ROOT)}")
        else:
            print(f"  (not present) {t.relative_to(PROJECT_ROOT)}")
    XTTS_RAW_DIR.mkdir(parents=True, exist_ok=True)
    print()
    if args.deep:
        print("  Next: python scripts\\xtts_bakeoff.py setup")
    else:
        print("  Speaker reference kept. Re-run with --deep to delete it too.")


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Variant D for the Awing voice-synthesis bake-off — XTTS v2.")
    sub = parser.add_subparsers(dest="command")

    s = sub.add_parser("setup",
                       help="Build the XTTS speaker reference from manifest clips")
    s.add_argument("--force", action="store_true",
                   help="Rebuild the reference even if it already exists")

    syn = sub.add_parser("synthesize",
                         help="Synthesize the 20 test words via XTTS v2")
    syn.add_argument("--language", default=DEFAULT_LANGUAGE,
                     help=f"XTTS target language (default: {DEFAULT_LANGUAGE}). "
                          f"One of: {', '.join(sorted(XTTS_LANGUAGES))}")
    syn.add_argument("--force", action="store_true",
                     help="Re-synthesize even if a wav already exists for a key")

    sub.add_parser("status", help="Show progress on the XTTS variant pipeline")
    c = sub.add_parser("clean", help="Delete generated XTTS audio")
    c.add_argument("--deep", action="store_true",
                   help="Also delete the speaker reference WAV")

    args = parser.parse_args()
    if args.command is None:
        parser.print_help()
        return

    commands = {
        "setup": cmd_setup,
        "synthesize": cmd_synthesize,
        "status": cmd_status,
        "clean": cmd_clean,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()
