#!/usr/bin/env python3
"""
generate_audio_mms.py  v1.0.0
Generate Awing pronunciation audio using Meta MMS (Massively Multilingual Speech) TTS.

Awing (ISO 639-3: azo) is NOT in MMS's 1,107 supported languages.
Strategy: Use a closely related Cameroon Bantu language as the TTS engine.
Bantu languages share phonological features (vowel systems, prenasalized consonants,
tone patterns), so a related language's model will produce much better pronunciation
than English TTS.

Candidate languages (in MMS):
  - bss (Akoose) — Southern Bantoid, Cameroon
  - mcu (Mambila, Cameroon) — Mambiloid, Cameroon
  - mcp (Makaa) — Southern Bantoid, Cameroon

The script:
  1. Downloads MMS TTS models for candidate languages
  2. Generates audio for all 31 alphabet sounds + 67 vocabulary words
  3. Saves MP3 files to assets/audio/alphabet/ and assets/audio/vocabulary/
  4. Optionally tests all candidates and picks the best sounding one

Usage:
  python scripts/generate_audio_mms.py                # Generate with best language
  python scripts/generate_audio_mms.py --language bss  # Force specific language
  python scripts/generate_audio_mms.py --test          # Test all candidate languages
  python scripts/generate_audio_mms.py --list          # Show current audio assets
  python scripts/generate_audio_mms.py --clean         # Delete generated audio

Requirements:
  pip install ttsmms pydub
  ffmpeg must be installed (for MP3 conversion)

License note: MMS TTS models use CC-BY-NC license (non-commercial use).
"""

import os
import sys
import argparse
import shutil
import subprocess
import json
from pathlib import Path

# ---------------------------------------------------------------------------
# Auto-activate venv_torch (PyTorch env for audio/TTS/training)
# ---------------------------------------------------------------------------
def _ensure_venv():
    """Activate the project venv_torch if not already active."""
    if sys.prefix != sys.base_prefix:
        return  # Already in a venv

    project_root = Path(__file__).resolve().parent.parent
    # Prefer venv_torch, fall back to old single-venv name
    for venv_name in ("venv_torch", "venv"):
        if sys.platform == "win32":
            venv_python = project_root / venv_name / "Scripts" / "python.exe"
        else:
            venv_python = project_root / venv_name / "bin" / "python"
        if venv_python.exists():
            break
    else:
        print("WARNING: venv_torch not found. Run install_dependencies.bat first.")
        return

    # Avoid infinite loop: if we ARE the venv python, don't re-exec
    if os.path.abspath(sys.executable) == os.path.abspath(str(venv_python)):
        return

    print(f"Auto-activating venv: {venv_python}")
    result = subprocess.run(
        [str(venv_python)] + sys.argv,
        cwd=str(project_root)
    )
    sys.exit(result.returncode)

_ensure_venv()

# ---------------------------------------------------------------------------
# Now safe to import packages that live inside the venv
# ---------------------------------------------------------------------------
try:
    from ttsmms import TTS, download
except ImportError:
    print("ERROR: ttsmms not installed. Run:")
    print("  pip install ttsmms")
    sys.exit(1)

try:
    from pydub import AudioSegment
except ImportError:
    print("ERROR: pydub not installed. Run:")
    print("  pip install pydub")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
ASSETS_AUDIO = PROJECT_ROOT / "assets" / "audio"
ALPHABET_DIR = ASSETS_AUDIO / "alphabet"
VOCABULARY_DIR = ASSETS_AUDIO / "vocabulary"
MODELS_DIR = PROJECT_ROOT / "models" / "mms_tts"

# MMS candidate languages — related Cameroon Bantu languages
CANDIDATE_LANGUAGES = {
    "bss": "Akoose (Southern Bantoid, Cameroon)",
    "mcu": "Mambila (Mambiloid, Cameroon)",
    "mcp": "Makaa (Southern Bantoid, Cameroon)",
}

# Default language (best results in testing)
DEFAULT_LANGUAGE = "bss"

# ---------------------------------------------------------------------------
# Awing alphabet — 9 vowels + 22 consonants
# Maps: letter -> (phonetic_text_for_tts, output_filename)
# We use phonetic spellings that Bantu TTS models can handle
# ---------------------------------------------------------------------------
ALPHABET_SOUNDS = {
    # Vowels
    "a":  ("a", "a"),
    "e":  ("e", "e"),
    "ɛ":  ("e", "epsilon"),       # open e
    "ə":  ("e", "schwa"),         # schwa
    "i":  ("i", "i"),
    "ɨ":  ("i", "barred_i"),      # close central unrounded
    "o":  ("o", "o"),
    "ɔ":  ("o", "open_o"),        # open o
    "u":  ("u", "u"),
    # Consonants
    "b":  ("ba", "b"),
    "ch": ("cha", "ch"),
    "d":  ("da", "d"),
    "f":  ("fa", "f"),
    "g":  ("ga", "g"),
    "gh": ("ga", "gh"),           # voiced velar fricative
    "j":  ("ja", "j"),
    "k":  ("ka", "k"),
    "l":  ("la", "l"),
    "m":  ("ma", "m"),
    "n":  ("na", "n"),
    "ny": ("nya", "ny"),
    "ŋ":  ("nga", "eng"),         # velar nasal
    "p":  ("pa", "p"),
    "s":  ("sa", "s"),
    "sh": ("sha", "sh"),
    "t":  ("ta", "t"),
    "ts": ("tsa", "ts"),
    "w":  ("wa", "w"),
    "y":  ("ya", "y"),
    "z":  ("za", "z"),
    "'":  ("a", "glottal"),       # glottal stop
}

# ---------------------------------------------------------------------------
# Awing vocabulary — 67 words
# Maps: awing_word -> (tts_input_text, output_filename)
# The tts_input uses simplified phonetic text that Bantu models can handle
# ---------------------------------------------------------------------------
VOCABULARY_WORDS = {
    # Body parts
    "apô":       ("apo", "apo"),
    "atûə":      ("atue", "atue"),
    "alɔ́əmə":   ("alome", "alome"),
    "fɛlə":      ("fele", "fele"),
    "nəlwîə":    ("nelwie", "nelwie"),
    "ndě":       ("nde", "nde"),
    "nkadtə":    ("nkadte", "nkadte"),
    "mbe'tə":    ("mbete", "mbete"),
    "achîə":     ("achie", "achie"),
    "nətô":      ("neto", "neto"),
    "nəpe":      ("nepe", "nepe"),
    # Animals and nature
    "əshûə":     ("eshue", "eshue"),
    "koŋə":      ("konge", "konge"),
    "anyeŋə":    ("anyenge", "anyenge"),
    "nənjwínnə": ("nenjwinne", "nenjwinne"),
    "ankoomə":   ("ankoome", "ankoome"),
    "ngə'ɔ́":    ("ngeo", "ngeo"),
    "nóolə":     ("noole", "noole"),
    "atîə":      ("atie", "atie"),
    "akoobɔ́":   ("akoobo", "akoobo"),
    "ngə'ə":     ("ngee", "ngee"),
    "wâakɔ́":    ("waako", "waako"),
    "nəwûə":     ("newue", "newue"),
    # Actions
    "nô":        ("no", "no"),
    "lúmə":      ("lume", "lume"),
    "mîə":       ("mie", "mie"),
    "pímə":      ("pime", "pime"),
    "tsó'ə":     ("tsoe", "tsoe"),
    "zó'ə":      ("zoe", "zoe"),
    "jágə":      ("jage", "jage"),
    "yîkə":      ("yike", "yike"),
    "lɛdnɔ́":    ("ledno", "ledno"),
    "pɛ́nə":     ("pene", "pene"),
    "shîə":      ("shie", "shie"),
    "cha'tɔ́":   ("chato", "chato"),
    "kwágə":     ("kwage", "kwage"),
    "lyáŋə":     ("lyange", "lyange"),
    "tɔ́gə":     ("toge", "toge"),
    "fyáalə":    ("fyaale", "fyaale"),
    "ko":        ("ko", "ko"),
    "yîə":       ("yie", "yie"),
    # Things and objects
    "ajúmə":     ("ajume", "ajume"),
    "ajwikə":    ("ajwike", "ajwike"),
    "afûə":      ("afue", "afue"),
    "nəse":      ("nese", "nese"),
    "mbéenə":    ("mbeene", "mbeene"),
    "ndzǒ":      ("ndzo", "ndzo"),
    "nəpɔ'ɔ́":   ("nepoo", "nepoo"),
    "fwɔ'ə":     ("fwoe", "fwoe"),
    "shwa'a":    ("shwaa", "shwaa"),
    "əkwunɔ́":   ("ekwuno", "ekwuno"),
    "nduə":      ("ndue", "ndue"),
    # Family and people
    "mǎ":        ("ma", "ma"),
    "yə":        ("ye", "ye"),
    "apɛ̌ɛlə":   ("apeele", "apeele"),
    "əfəgɔ́":    ("efego", "efego"),
    "alá'ə":     ("alae", "alae"),
    "ngye":      ("ngye", "ngye"),
    "ayáŋə":     ("ayange", "ayange"),
    # Food and daily life
    "apeemə":    ("apeeme", "apeeme"),
    "apéenə":    ("apeene", "apeene"),
    "nəgoomɔ́":  ("negoomo", "negoomo"),
    "ngwáŋə":    ("ngwange", "ngwange"),
    "mândzǒ":    ("mandzo", "mandzo"),
    "akwe":      ("akwe", "akwe"),
    "mətwé":     ("metwe", "metwe"),
    "nəkəŋɔ́":   ("nekenge", "nekenge"),
}


def download_model(lang_code: str) -> Path:
    """Download MMS TTS model for a language, returns model directory path.

    ttsmms extracts into a nested subdirectory: models/mms_tts/bss/bss/
    The actual model files (config.json, G_100000.pth, vocab.txt) are in the inner dir.
    We return the path that contains config.json.
    """
    model_dir = MODELS_DIR / lang_code

    # Check if already downloaded — look in both possible locations
    inner_dir = model_dir / lang_code
    for candidate in [model_dir, inner_dir]:
        if candidate.exists() and (candidate / "config.json").exists():
            print(f"  Model for {lang_code} already downloaded at {candidate}")
            return candidate

    print(f"  Downloading MMS TTS model for {lang_code}...")
    model_dir.mkdir(parents=True, exist_ok=True)

    # ttsmms download function
    try:
        download(lang_code, str(model_dir))
    except Exception as e:
        print(f"  ERROR downloading {lang_code}: {e}")
        # Try manual download as fallback
        url = f"https://dl.fbaipublicfiles.com/mms/tts/{lang_code}.tar.gz"
        tar_path = model_dir / f"{lang_code}.tar.gz"
        print(f"  Trying manual download from {url}...")
        try:
            import urllib.request
            urllib.request.urlretrieve(url, str(tar_path))
            import tarfile
            with tarfile.open(str(tar_path), "r:gz") as tar:
                tar.extractall(str(model_dir))
            tar_path.unlink()
        except Exception as e2:
            print(f"  ERROR: Manual download also failed: {e2}")
            return None

    # Find config.json — ttsmms extracts to nested dir (e.g., bss/bss/)
    for candidate in [model_dir, inner_dir]:
        if (candidate / "config.json").exists():
            print(f"  Model files found at: {candidate}")
            return candidate

    # Last resort: search recursively for config.json
    for config_file in model_dir.rglob("config.json"):
        print(f"  Model files found at: {config_file.parent}")
        return config_file.parent

    print(f"  ERROR: config.json not found after download in {model_dir}")
    return None


def generate_audio(tts, text: str, output_path: Path):
    """Generate audio for a text string and save as MP3."""
    try:
        # ttsmms generates WAV
        wav_path = output_path.with_suffix(".wav")
        result = tts.synthesis(text)

        # Save WAV first
        import numpy as np
        import wave

        # result is a dict with 'x' (audio array) and 'sampling_rate'
        audio_data = result["x"]
        sample_rate = result["sampling_rate"]

        # Normalize audio
        if hasattr(audio_data, 'numpy'):
            audio_data = audio_data.numpy()

        import numpy as np
        audio_data = np.array(audio_data, dtype=np.float32)
        if audio_data.max() > 0:
            audio_data = audio_data / max(abs(audio_data.max()), abs(audio_data.min()))
        audio_int16 = (audio_data * 32767).astype(np.int16)

        with wave.open(str(wav_path), 'w') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(sample_rate)
            wf.writeframes(audio_int16.tobytes())

        # Convert to MP3 using pydub (requires ffmpeg)
        audio = AudioSegment.from_wav(str(wav_path))
        audio.export(str(output_path), format="mp3", bitrate="128k")

        # Clean up WAV
        wav_path.unlink(missing_ok=True)

        return True
    except Exception as e:
        print(f"    ERROR generating audio: {e}")
        return False


def generate_all(lang_code: str, force: bool = False):
    """Generate all alphabet + vocabulary audio files."""
    print(f"\n{'='*60}")
    print(f"  Generating Awing audio using MMS TTS ({lang_code})")
    print(f"  Language: {CANDIDATE_LANGUAGES.get(lang_code, 'Unknown')}")
    print(f"{'='*60}\n")

    # Download model
    model_dir = download_model(lang_code)
    if model_dir is None:
        print("ERROR: Could not download model. Aborting.")
        return False

    # Initialize TTS
    print("  Loading TTS model...")
    try:
        tts = TTS(str(model_dir))
    except Exception as e:
        print(f"  ERROR loading model: {e}")
        return False
    print("  Model loaded successfully.\n")

    # Create output directories
    ALPHABET_DIR.mkdir(parents=True, exist_ok=True)
    VOCABULARY_DIR.mkdir(parents=True, exist_ok=True)

    # Generate alphabet sounds
    print(f"  Generating {len(ALPHABET_SOUNDS)} alphabet sounds...")
    alphabet_count = 0
    for letter, (tts_text, filename) in ALPHABET_SOUNDS.items():
        output_path = ALPHABET_DIR / f"{filename}.mp3"
        if output_path.exists() and not force:
            print(f"    [{letter}] → {filename}.mp3 (exists, skipping)")
            alphabet_count += 1
            continue

        print(f"    [{letter}] → {filename}.mp3 ... ", end="", flush=True)
        if generate_audio(tts, tts_text, output_path):
            print("OK")
            alphabet_count += 1
        else:
            print("FAILED")

    print(f"\n  Alphabet: {alphabet_count}/{len(ALPHABET_SOUNDS)} clips generated.\n")

    # Generate vocabulary words
    print(f"  Generating {len(VOCABULARY_WORDS)} vocabulary words...")
    vocab_count = 0
    for awing_word, (tts_text, filename) in VOCABULARY_WORDS.items():
        output_path = VOCABULARY_DIR / f"{filename}.mp3"
        if output_path.exists() and not force:
            print(f"    [{awing_word}] → {filename}.mp3 (exists, skipping)")
            vocab_count += 1
            continue

        print(f"    [{awing_word}] → {filename}.mp3 ... ", end="", flush=True)
        if generate_audio(tts, tts_text, output_path):
            print("OK")
            vocab_count += 1
        else:
            print("FAILED")

    print(f"\n  Vocabulary: {vocab_count}/{len(VOCABULARY_WORDS)} clips generated.\n")

    total = alphabet_count + vocab_count
    expected = len(ALPHABET_SOUNDS) + len(VOCABULARY_WORDS)
    print(f"  {'='*60}")
    print(f"  TOTAL: {total}/{expected} audio clips generated")
    print(f"  Alphabet clips in:   {ALPHABET_DIR}")
    print(f"  Vocabulary clips in: {VOCABULARY_DIR}")
    print(f"  {'='*60}")

    return total == expected


def test_candidates():
    """Test all candidate languages — generate a few sample words for comparison."""
    print("\n" + "="*60)
    print("  Testing MMS TTS candidate languages")
    print("="*60)

    test_words = [
        ("apo", "apô (hand)"),
        ("eshue", "əshûə (fish)"),
        ("mbete", "mbe'tə (shoulder)"),
        ("ndzo", "ndzǒ (beans)"),
        ("ngee", "ngə'ə (stone)"),
    ]

    test_dir = PROJECT_ROOT / "temp" / "mms_test"
    test_dir.mkdir(parents=True, exist_ok=True)

    for lang_code, lang_name in CANDIDATE_LANGUAGES.items():
        print(f"\n--- {lang_code}: {lang_name} ---")

        model_dir = download_model(lang_code)
        if model_dir is None:
            print(f"  SKIPPED (download failed)")
            continue

        try:
            tts = TTS(str(model_dir))
        except Exception as e:
            print(f"  SKIPPED (load failed: {e})")
            continue

        lang_dir = test_dir / lang_code
        lang_dir.mkdir(parents=True, exist_ok=True)

        for tts_text, label in test_words:
            output_path = lang_dir / f"{tts_text}.mp3"
            print(f"  [{label}] → ", end="", flush=True)
            if generate_audio(tts, tts_text, output_path):
                print(f"OK → {output_path}")
            else:
                print("FAILED")

    print(f"\n  Test files saved in: {test_dir}")
    print(f"  Compare the audio quality and pick the best language.")
    print(f"  Then run: python scripts/generate_audio_mms.py --language <code>\n")


def list_audio():
    """Show current audio asset counts."""
    print("\n  Current audio assets:")
    for name, directory in [("Alphabet", ALPHABET_DIR), ("Vocabulary", VOCABULARY_DIR)]:
        if directory.exists():
            mp3s = list(directory.glob("*.mp3"))
            print(f"    {name}: {len(mp3s)} clips in {directory}")
            for f in sorted(mp3s):
                size_kb = f.stat().st_size / 1024
                print(f"      {f.name} ({size_kb:.1f} KB)")
        else:
            print(f"    {name}: (directory does not exist)")
    print()


def clean_audio():
    """Delete all generated audio files."""
    for directory in [ALPHABET_DIR, VOCABULARY_DIR]:
        if directory.exists():
            mp3s = list(directory.glob("*.mp3"))
            for f in mp3s:
                f.unlink()
            print(f"  Deleted {len(mp3s)} files from {directory}")

    # Also clean model cache
    if MODELS_DIR.exists():
        shutil.rmtree(str(MODELS_DIR))
        print(f"  Deleted model cache: {MODELS_DIR}")

    print("  Done.")


def main():
    parser = argparse.ArgumentParser(
        description="Generate Awing pronunciation audio using Meta MMS TTS"
    )
    parser.add_argument(
        "--language", "-l",
        default=DEFAULT_LANGUAGE,
        choices=list(CANDIDATE_LANGUAGES.keys()),
        help=f"MMS language code to use (default: {DEFAULT_LANGUAGE})"
    )
    parser.add_argument(
        "--test", action="store_true",
        help="Test all candidate languages with sample words"
    )
    parser.add_argument(
        "--list", action="store_true",
        help="Show current audio assets"
    )
    parser.add_argument(
        "--clean", action="store_true",
        help="Delete all generated audio files"
    )
    parser.add_argument(
        "--force", action="store_true",
        help="Regenerate even if files already exist"
    )

    args = parser.parse_args()

    if args.list:
        list_audio()
        return

    if args.clean:
        clean_audio()
        return

    if args.test:
        test_candidates()
        return

    generate_all(args.language, force=args.force)


if __name__ == "__main__":
    main()
