#!/usr/bin/env python3
"""
record_audio.py  v1.0.0
Record Awing pronunciation audio clips from your microphone.

Walks through all 31 alphabet sounds + 67 vocabulary words one by one.
For each word:
  1. Shows the Awing word + English translation
  2. Press ENTER to start recording
  3. Press ENTER again to stop
  4. Saves as MP3 with the correct filename
  5. Option to replay and re-record if not happy

Usage:
  python scripts/record_audio.py                  # Record all (skips existing)
  python scripts/record_audio.py --force           # Re-record everything
  python scripts/record_audio.py --alphabet-only   # Only alphabet sounds
  python scripts/record_audio.py --vocab-only      # Only vocabulary words
  python scripts/record_audio.py --start-from 15   # Resume from clip #15
  python scripts/record_audio.py --list            # Show what's recorded

Requirements:
  pip install sounddevice soundfile pydub
  ffmpeg must be installed (for MP3 conversion)
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path

# ---------------------------------------------------------------------------
# Auto-activate venv_torch (PyTorch env for audio/TTS/training)
# ---------------------------------------------------------------------------
def _ensure_venv():
    """Activate the project venv_torch if not already active."""
    if sys.prefix != sys.base_prefix:
        return

    project_root = Path(__file__).resolve().parent.parent
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
# Imports (venv packages)
# ---------------------------------------------------------------------------
try:
    import sounddevice as sd
    import soundfile as sf
except ImportError:
    print("ERROR: sounddevice or soundfile not installed. Run:")
    print("  pip install sounddevice soundfile")
    sys.exit(1)

try:
    from pydub import AudioSegment
except ImportError:
    print("ERROR: pydub not installed. Run:")
    print("  pip install pydub")
    sys.exit(1)

import numpy as np
import threading
import time

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
ASSETS_AUDIO = PROJECT_ROOT / "assets" / "audio"
ALPHABET_DIR = ASSETS_AUDIO / "alphabet"
VOCABULARY_DIR = ASSETS_AUDIO / "vocabulary"

SAMPLE_RATE = 44100
CHANNELS = 1

# ---------------------------------------------------------------------------
# All clips to record, in order
# Format: (display_label, pronunciation_hint, english, filename, output_dir)
# ---------------------------------------------------------------------------
ALPHABET_CLIPS = [
    # Vowels
    ("a",  'Say the sound: "ah" (as in father)',     "vowel",       "a",        ALPHABET_DIR),
    ("e",  'Say the sound: "eh" (as in bed)',        "vowel",       "e",        ALPHABET_DIR),
    ("ɛ",  'Say the sound: open "eh" (as in pet)',   "vowel",       "epsilon",  ALPHABET_DIR),
    ("ə",  'Say the sound: "uh" (as in about)',      "vowel",       "schwa",    ALPHABET_DIR),
    ("i",  'Say the sound: "ee" (as in see)',        "vowel",       "i",        ALPHABET_DIR),
    ("ɨ",  'Say the sound: relaxed "ih"',            "vowel",       "barred_i", ALPHABET_DIR),
    ("o",  'Say the sound: "oh" (as in go)',         "vowel",       "o",        ALPHABET_DIR),
    ("ɔ",  'Say the sound: open "oh" (as in hot)',   "vowel",       "open_o",   ALPHABET_DIR),
    ("u",  'Say the sound: "oo" (as in food)',       "vowel",       "u",        ALPHABET_DIR),
    # Consonants
    ("b",  'Say: "ba"',  "consonant", "b",  ALPHABET_DIR),
    ("ch", 'Say: "cha"', "consonant", "ch", ALPHABET_DIR),
    ("d",  'Say: "da"',  "consonant", "d",  ALPHABET_DIR),
    ("f",  'Say: "fa"',  "consonant", "f",  ALPHABET_DIR),
    ("g",  'Say: "ga"',  "consonant", "g",  ALPHABET_DIR),
    ("gh", 'Say: "gha" (soft throat sound)', "consonant", "gh", ALPHABET_DIR),
    ("j",  'Say: "ja"',  "consonant", "j",  ALPHABET_DIR),
    ("k",  'Say: "ka"',  "consonant", "k",  ALPHABET_DIR),
    ("l",  'Say: "la"',  "consonant", "l",  ALPHABET_DIR),
    ("m",  'Say: "ma"',  "consonant", "m",  ALPHABET_DIR),
    ("n",  'Say: "na"',  "consonant", "n",  ALPHABET_DIR),
    ("ny", 'Say: "nya" (as in canyon)', "consonant", "ny", ALPHABET_DIR),
    ("ŋ",  'Say: "nga" (as in sing)',   "consonant", "eng", ALPHABET_DIR),
    ("p",  'Say: "pa"',  "consonant", "p",  ALPHABET_DIR),
    ("s",  'Say: "sa"',  "consonant", "s",  ALPHABET_DIR),
    ("sh", 'Say: "sha"', "consonant", "sh", ALPHABET_DIR),
    ("t",  'Say: "ta"',  "consonant", "t",  ALPHABET_DIR),
    ("ts", 'Say: "tsa"', "consonant", "ts", ALPHABET_DIR),
    ("w",  'Say: "wa"',  "consonant", "w",  ALPHABET_DIR),
    ("y",  'Say: "ya"',  "consonant", "y",  ALPHABET_DIR),
    ("z",  'Say: "za"',  "consonant", "z",  ALPHABET_DIR),
    ("'",  'Say: glottal stop (tiny pause)', "consonant", "glottal", ALPHABET_DIR),
]

VOCABULARY_CLIPS = [
    # Body parts
    ("apô",       "hand",        "apo",       VOCABULARY_DIR),
    ("atûə",      "head",        "atue",      VOCABULARY_DIR),
    ("alɔ́əmə",   "tongue",      "alome",     VOCABULARY_DIR),
    ("fɛlə",      "breastbone",  "fele",      VOCABULARY_DIR),
    ("nəlwîə",    "nose",        "nelwie",    VOCABULARY_DIR),
    ("ndě",       "neck",        "nde",       VOCABULARY_DIR),
    ("nkadtə",    "back",        "nkadte",    VOCABULARY_DIR),
    ("mbe'tə",    "shoulder",    "mbete",     VOCABULARY_DIR),
    ("achîə",     "blood",       "achie",     VOCABULARY_DIR),
    ("nətô",      "intestine",   "neto",      VOCABULARY_DIR),
    ("nəpe",      "liver",       "nepe",      VOCABULARY_DIR),
    # Animals and nature
    ("əshûə",     "fish",        "eshue",     VOCABULARY_DIR),
    ("koŋə",      "owl",         "konge",     VOCABULARY_DIR),
    ("anyeŋə",    "claw",        "anyenge",   VOCABULARY_DIR),
    ("nənjwínnə", "fly",         "nenjwinne", VOCABULARY_DIR),
    ("ankoomə",   "ram",         "ankoome",   VOCABULARY_DIR),
    ("ngə'ɔ́",    "termite",     "ngeo",      VOCABULARY_DIR),
    ("nóolə",     "snake",       "noole",     VOCABULARY_DIR),
    ("atîə",      "tree",        "atie",      VOCABULARY_DIR),
    ("akoobɔ́",   "forest",      "akoobo",    VOCABULARY_DIR),
    ("ngə'ə",     "stone",       "ngee",      VOCABULARY_DIR),
    ("wâakɔ́",    "sand",        "waako",     VOCABULARY_DIR),
    ("nəwûə",     "death",       "newue",     VOCABULARY_DIR),
    # Actions
    ("nô",        "drink",       "no",        VOCABULARY_DIR),
    ("lúmə",      "bite",        "lume",      VOCABULARY_DIR),
    ("mîə",       "swallow",     "mie",       VOCABULARY_DIR),
    ("pímə",      "believe",     "pime",      VOCABULARY_DIR),
    ("tsó'ə",     "heal",        "tsoe",      VOCABULARY_DIR),
    ("zó'ə",      "hear",        "zoe",       VOCABULARY_DIR),
    ("jágə",      "yawn",        "jage",      VOCABULARY_DIR),
    ("yîkə",      "harden",      "yike",      VOCABULARY_DIR),
    ("lɛdnɔ́",    "sweat",       "ledno",     VOCABULARY_DIR),
    ("pɛ́nə",     "dance",       "pene",      VOCABULARY_DIR),
    ("shîə",      "stretch",     "shie",      VOCABULARY_DIR),
    ("cha'tɔ́",   "greet",       "chato",     VOCABULARY_DIR),
    ("kwágə",     "cough",       "kwage",     VOCABULARY_DIR),
    ("lyáŋə",     "hide",        "lyange",    VOCABULARY_DIR),
    ("tɔ́gə",     "blow",        "toge",      VOCABULARY_DIR),
    ("fyáalə",    "chase",       "fyaale",    VOCABULARY_DIR),
    ("ko",        "take",        "ko",        VOCABULARY_DIR),
    ("yîə",       "come",        "yie",       VOCABULARY_DIR),
    # Things and objects
    ("ajúmə",     "thing",       "ajume",     VOCABULARY_DIR),
    ("ajwikə",    "window",      "ajwike",    VOCABULARY_DIR),
    ("afûə",      "leaf/medicine","afue",     VOCABULARY_DIR),
    ("nəse",      "grave",       "nese",      VOCABULARY_DIR),
    ("mbéenə",    "nail",        "mbeene",    VOCABULARY_DIR),
    ("ndzǒ",      "beans",       "ndzo",      VOCABULARY_DIR),
    ("nəpɔ'ɔ́",   "pumpkin",     "nepoo",     VOCABULARY_DIR),
    ("fwɔ'ə",     "chisel",      "fwoe",      VOCABULARY_DIR),
    ("shwa'a",    "razor",       "shwaa",     VOCABULARY_DIR),
    ("əkwunɔ́",   "bed",         "ekwuno",    VOCABULARY_DIR),
    ("nduə",      "hammer",      "ndue",      VOCABULARY_DIR),
    # Family and people
    ("mǎ",        "mother",      "ma",        VOCABULARY_DIR),
    ("yə",        "he/she",      "ye",        VOCABULARY_DIR),
    ("apɛ̌ɛlə",   "mad person",  "apeele",    VOCABULARY_DIR),
    ("əfəgɔ́",    "blind person","efego",     VOCABULARY_DIR),
    ("alá'ə",     "village",     "alae",      VOCABULARY_DIR),
    ("ngye",      "voice",       "ngye",      VOCABULARY_DIR),
    ("ayáŋə",     "wisdom",      "ayange",    VOCABULARY_DIR),
    # Food and daily life
    ("apeemə",    "bag",         "apeeme",    VOCABULARY_DIR),
    ("apéenə",    "flour",       "apeene",    VOCABULARY_DIR),
    ("nəgoomɔ́",  "plantain",    "negoomo",   VOCABULARY_DIR),
    ("ngwáŋə",    "salt",        "ngwange",   VOCABULARY_DIR),
    ("mândzǒ",    "groundnuts",  "mandzo",    VOCABULARY_DIR),
    ("akwe",      "response",    "akwe",      VOCABULARY_DIR),
    ("mətwé",     "saliva",      "metwe",     VOCABULARY_DIR),
    ("nəkəŋɔ́",   "pot",         "nekenge",   VOCABULARY_DIR),
]


class Recorder:
    """Simple microphone recorder using sounddevice."""

    def __init__(self):
        self.recording = False
        self.frames = []
        self._thread = None

    def start(self):
        """Start recording from microphone."""
        self.frames = []
        self.recording = True
        self._thread = threading.Thread(target=self._record_loop, daemon=True)
        self._thread.start()

    def _record_loop(self):
        """Background recording loop."""
        try:
            with sd.InputStream(samplerate=SAMPLE_RATE, channels=CHANNELS,
                                dtype='float32') as stream:
                while self.recording:
                    data, _ = stream.read(1024)
                    self.frames.append(data.copy())
        except Exception as e:
            print(f"\n  ERROR recording: {e}")
            self.recording = False

    def stop(self):
        """Stop recording and return audio data."""
        self.recording = False
        if self._thread:
            self._thread.join(timeout=2)
        if not self.frames:
            return None
        return np.concatenate(self.frames, axis=0)

    def save(self, audio_data, output_path: Path):
        """Save recorded audio as MP3."""
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Save as WAV first
        wav_path = output_path.with_suffix(".wav")
        sf.write(str(wav_path), audio_data, SAMPLE_RATE)

        # Convert to MP3
        audio = AudioSegment.from_wav(str(wav_path))
        audio.export(str(output_path), format="mp3", bitrate="128k")

        # Clean up WAV
        wav_path.unlink(missing_ok=True)

    def play(self, output_path: Path):
        """Play back a recorded clip."""
        try:
            if output_path.suffix == ".mp3":
                # Convert MP3 to numpy array for playback
                audio = AudioSegment.from_mp3(str(output_path))
                samples = np.array(audio.get_array_of_samples(), dtype=np.float32)
                samples = samples / (2**15)  # normalize int16 to float32
                sd.play(samples, audio.frame_rate)
                sd.wait()
            else:
                data, rate = sf.read(str(output_path))
                sd.play(data, rate)
                sd.wait()
        except Exception as e:
            print(f"  Could not play back: {e}")


def record_clips(clips, clip_type: str, recorder: Recorder,
                 force: bool = False, start_from: int = 0):
    """Record a set of clips interactively."""
    total = len(clips)
    recorded = 0
    skipped = 0

    print(f"\n{'='*60}")
    print(f"  Recording {total} {clip_type} clips")
    print(f"  Press ENTER to start recording, ENTER again to stop")
    print(f"  After recording: (p)lay, (r)e-record, (s)kip, ENTER to accept")
    print(f"{'='*60}\n")

    for idx, clip in enumerate(clips):
        clip_num = idx + 1

        if clip_num < start_from:
            continue

        if clip_type == "alphabet":
            letter, hint, category, filename, out_dir = clip
            display = f"  [{clip_num}/{total}]  Letter: {letter}  ({category})"
            detail = f"  {hint}"
        else:
            awing, english, filename, out_dir = clip
            display = f"  [{clip_num}/{total}]  {awing}  =  \"{english}\""
            detail = f"  Say the Awing word: {awing}"

        output_path = out_dir / f"{filename}.mp3"

        # Skip if exists and not forcing
        if output_path.exists() and not force:
            skipped += 1
            continue

        print(f"\n{'-'*50}")
        print(display)
        print(detail)

        while True:
            input("  >> Press ENTER to start recording...")

            print("  🔴 RECORDING... (press ENTER to stop)")
            recorder.start()
            input()
            audio_data = recorder.stop()

            if audio_data is None or len(audio_data) == 0:
                print("  No audio captured. Try again.")
                continue

            duration = len(audio_data) / SAMPLE_RATE
            print(f"  Recorded {duration:.1f}s")

            # Save temporarily
            recorder.save(audio_data, output_path)

            # Ask what to do
            while True:
                choice = input("  >> (p)lay / (r)e-record / (s)kip / ENTER to accept: ").strip().lower()

                if choice == 'p':
                    print("  Playing...", end=" ", flush=True)
                    recorder.play(output_path)
                    print("done.")
                elif choice == 'r':
                    print("  Re-recording...")
                    break
                elif choice == 's':
                    output_path.unlink(missing_ok=True)
                    print("  Skipped.")
                    skipped += 1
                    break
                elif choice == '':
                    print(f"  ✓ Saved: {output_path.name}")
                    recorded += 1
                    break
                else:
                    print("  Type p, r, s, or just press ENTER")

            if choice != 'r':
                break

    print(f"\n{'='*60}")
    print(f"  {clip_type.upper()} DONE: {recorded} recorded, {skipped} skipped")
    print(f"{'='*60}")
    return recorded


def list_audio():
    """Show current audio asset counts."""
    print("\n  Current audio recordings:")
    total = 0
    for name, directory, expected in [
        ("Alphabet", ALPHABET_DIR, len(ALPHABET_CLIPS)),
        ("Vocabulary", VOCABULARY_DIR, len(VOCABULARY_CLIPS))
    ]:
        if directory.exists():
            mp3s = list(directory.glob("*.mp3"))
            total += len(mp3s)
            print(f"\n  {name}: {len(mp3s)}/{expected} clips")
            for f in sorted(mp3s):
                size_kb = f.stat().st_size / 1024
                print(f"    ✓ {f.name} ({size_kb:.1f} KB)")

            # Show missing
            if name == "Alphabet":
                expected_names = {c[3] + ".mp3" for c in ALPHABET_CLIPS}
            else:
                expected_names = {c[2] + ".mp3" for c in VOCABULARY_CLIPS}
            existing_names = {f.name for f in mp3s}
            missing = expected_names - existing_names
            if missing:
                print(f"  Missing ({len(missing)}):")
                for m in sorted(missing):
                    print(f"    ✗ {m}")
        else:
            print(f"\n  {name}: (no recordings yet)")

    expected_total = len(ALPHABET_CLIPS) + len(VOCABULARY_CLIPS)
    print(f"\n  TOTAL: {total}/{expected_total} clips recorded\n")


def main():
    parser = argparse.ArgumentParser(
        description="Record Awing pronunciation audio clips from microphone"
    )
    parser.add_argument("--force", action="store_true",
                        help="Re-record even if files exist")
    parser.add_argument("--alphabet-only", action="store_true",
                        help="Only record alphabet sounds")
    parser.add_argument("--vocab-only", action="store_true",
                        help="Only record vocabulary words")
    parser.add_argument("--start-from", type=int, default=0,
                        help="Resume from clip number N")
    parser.add_argument("--list", action="store_true",
                        help="Show what's been recorded")

    args = parser.parse_args()

    if args.list:
        list_audio()
        return

    # Check microphone
    print("\n  Checking microphone...")
    try:
        devices = sd.query_devices()
        default_input = sd.query_devices(kind='input')
        print(f"  Using: {default_input['name']}")
        print(f"  Sample rate: {SAMPLE_RATE} Hz, Channels: {CHANNELS}")
    except Exception as e:
        print(f"  ERROR: No microphone found: {e}")
        print("  Make sure a microphone is connected and enabled.")
        sys.exit(1)

    recorder = Recorder()

    if not args.vocab_only:
        record_clips(ALPHABET_CLIPS, "alphabet", recorder,
                     force=args.force, start_from=args.start_from)

    if not args.alphabet_only:
        record_clips(VOCABULARY_CLIPS, "vocabulary", recorder,
                     force=args.force, start_from=args.start_from)

    # Final summary
    list_audio()

    print("  All done! Now rebuild the app:")
    print("    flutter pub get && flutter build apk --release && flutter run")
    print()


if __name__ == "__main__":
    main()
