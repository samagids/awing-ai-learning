"""
Awing Voice Cloning Audio Generator
=====================================
Clones a native Awing speaker's voice from YouTube videos, then generates
pronunciation audio for every word in the app using that cloned voice.

Pipeline:
  1. Downloads audio from Awing YouTube lessons
  2. Extracts a clean speaker sample (6-30 seconds)
  3. Loads Coqui XTTS v2 voice cloning model
  4. Generates all 98 audio clips in the cloned voice
  5. Saves to assets/audio/ for the Flutter app

Requirements (install in order):
  pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121
  pip install coqui-tts
  pip install yt-dlp
  pip install pydub

  Also requires ffmpeg: https://ffmpeg.org/download.html
  (or: winget install ffmpeg)

Usage:
  python scripts/generate_audio_clone.py

First run downloads the XTTS v2 model (~1.8GB). Subsequent runs use the cache.
"""

import os
import sys
import subprocess
import re

# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

# Auto-activate venv_torch (PyTorch env for audio/TTS/training)
for _venv_name in ("venv_torch", "venv"):
    VENV_DIR = os.path.join(PROJECT_ROOT, _venv_name)
    if os.path.exists(VENV_DIR):
        break
if os.path.exists(VENV_DIR) and sys.prefix == sys.base_prefix:
    if sys.platform == "win32":
        venv_python = os.path.join(VENV_DIR, "Scripts", "python.exe")
    else:
        venv_python = os.path.join(VENV_DIR, "bin", "python")
    if os.path.exists(venv_python) and os.path.abspath(venv_python) != os.path.abspath(sys.executable):
        print("  Auto-activating virtual environment...")
        result = subprocess.run([venv_python] + sys.argv)
        sys.exit(result.returncode)
ALPHABET_DIR = os.path.join(PROJECT_ROOT, "assets", "audio", "alphabet")
VOCABULARY_DIR = os.path.join(PROJECT_ROOT, "assets", "audio", "vocabulary")
TEMP_DIR = os.path.join(PROJECT_ROOT, "scripts", "_audio_temp")

# YouTube videos with best pronunciation content (alphabet lessons)
YOUTUBE_URLS = [
    "https://www.youtube.com/watch?v=GaG14f8bnMI",   # Lesson One: Awing Alphabet (long)
    "https://www.youtube.com/watch?v=aaCB8zm7uAk",   # Awing alphabet part 1
    "https://www.youtube.com/watch?v=MpPIPdebQE0",   # Awing alphabet part 2
    # NOTE: Voice cloning is deprecated — use extract_audio_clips.py instead
]

# Speaker sample: which video to use and time range (start_sec, end_sec)
# We take a clean segment from the first video where the speaker is talking clearly
SPEAKER_SAMPLE_VIDEO_INDEX = 0   # First video
SPEAKER_SAMPLE_START = 30        # Start at 30 seconds (past intro)
SPEAKER_SAMPLE_DURATION = 20     # 20 seconds of clear speech

# XTTS language code (English is used since Awing isn't directly supported,
# but the voice characteristics are cloned from the native speaker)
XTTS_LANGUAGE = "en"

# ============================================================
# WORD DATA - IPA phonetic text for XTTS to speak
# XTTS works better with phonetic English spellings than raw IPA symbols,
# so we provide carefully crafted pronunciations that guide the cloned
# voice to produce the closest possible Awing sounds.
# ============================================================

ALPHABET_CLIPS = [
    # (filename, display, phonetic_text_for_tts)
    ("a",        "a",   "aah"),
    ("e",        "e",   "eh"),
    ("epsilon",  "ɛ",   "air"),
    ("schwa",    "ə",   "uh"),
    ("i",        "i",   "ee"),
    ("barred_i", "ɨ",   "ih"),
    ("o",        "o",   "oh"),
    ("open_o",   "ɔ",   "aw"),
    ("u",        "u",   "oo"),
    ("b",   "b",   "buh"),
    ("ch",  "ch",  "chuh"),
    ("d",   "d",   "duh"),
    ("f",   "f",   "fuh"),
    ("g",   "g",   "guh"),
    ("gh",  "gh",  "ruh"),
    ("j",   "j",   "juh"),
    ("k",   "k",   "kuh"),
    ("l",   "l",   "luh"),
    ("m",   "m",   "muh"),
    ("n",   "n",   "nuh"),
    ("ny",  "ny",  "nyuh"),
    ("eng", "ŋ",   "nguh"),
    ("p",   "p",   "puh"),
    ("s",   "s",   "suh"),
    ("sh",  "sh",  "shuh"),
    ("t",   "t",   "tuh"),
    ("ts",  "ts",  "tsuh"),
    ("w",   "w",   "wuh"),
    ("y",   "y",   "yuh"),
    ("z",   "z",   "zuh"),
    ("glottal", "'", "uh oh"),
]

VOCABULARY_CLIPS = [
    # (filename, awing_display, english, phonetic_for_tts)
    # Body parts
    ("apo",       "apô",       "hand",        "ah poh"),
    ("atue",      "atûə",      "head",        "ah too uh"),
    ("aloeme",    "alɔ́əmə",    "tongue",      "ah law uh muh"),
    ("fele",      "fɛlə",      "breastbone",  "fair luh"),
    ("nelwie",    "nəlwîə",    "nose",        "nuh lwee uh"),
    ("nde",       "ndě",       "neck",        "n day"),
    ("nkadte",    "nkadtə",    "back",        "n kahd tuh"),
    ("mbete",     "mbe'tə",    "shoulder",    "m beh tuh"),
    ("achie",     "achîə",     "blood",       "ah chee uh"),
    ("neto",      "nətô",      "intestine",   "nuh toh"),
    ("nepe",      "nəpe",      "liver",       "nuh peh"),
    # Animals & Nature
    ("eshue",     "əshûə",     "fish",        "uh shoo uh"),
    ("konge",     "koŋə",      "owl",         "kong uh"),
    ("anyenge",   "anyeŋə",    "claw",        "ah nyeng uh"),
    ("nenjwinne", "nənjwínnə", "fly",         "nuh njween nuh"),
    ("ankoome",   "ankoomə",   "ram",         "ahn koh muh"),
    ("ngeo",      "ngə'ɔ́",     "termite",     "ng uh aw"),
    ("noole",     "nóolə",     "snake",       "noh luh"),
    ("atie",      "atîə",      "tree",        "ah tee uh"),
    ("akoobo",    "akoobɔ́",    "forest",      "ah koh baw"),
    ("ngee",      "ngə'ə",     "stone",       "ng uh uh"),
    ("waako",     "wâakɔ́",     "sand",        "wah kaw"),
    ("newue",     "nəwûə",     "death",       "nuh woo uh"),
    # Actions
    ("no",        "nô",        "drink",       "noh"),
    ("lume",      "lúmə",      "bite",        "loo muh"),
    ("mie",       "mîə",       "swallow",     "mee uh"),
    ("pime",      "pímə",      "believe",     "pee muh"),
    ("tsoe",      "tsó'ə",     "heal",        "tsoh uh"),
    ("zoe",       "zó'ə",      "hear",        "zoh uh"),
    ("jage",      "jágə",      "yawn",        "jah guh"),
    ("yike",      "yîkə",      "harden",      "yee kuh"),
    ("ledno",     "lɛdnɔ́",     "sweat",       "led naw"),
    ("pene",      "pɛ́nə",      "dance",       "pen uh"),
    ("shie",      "shîə",      "stretch",     "shee uh"),
    ("chato",     "cha'tɔ́",    "greet",       "chah taw"),
    ("kwage",     "kwágə",     "cough",       "kwah guh"),
    ("lyange",    "lyáŋə",     "hide",        "lyahng uh"),
    ("toge",      "tɔ́gə",      "blow",        "taw guh"),
    ("fyaale",    "fyáalə",    "chase",       "fyah luh"),
    ("ko",        "ko",        "take",        "koh"),
    ("yie",       "yîə",       "come",        "yee uh"),
    # Things & Objects
    ("ajume",     "ajúmə",     "thing",       "ah joo muh"),
    ("ajwike",    "ajwikə",    "window",      "ah jwee kuh"),
    ("afue",      "afûə",      "leaf",        "ah foo uh"),
    ("nese",      "nəse",      "grave",       "nuh seh"),
    ("mbeene",    "mbéenə",    "nail",        "m beh nuh"),
    ("ndzo",      "ndzǒ",      "beans",       "n joh"),
    ("nepoo",     "nəpɔ'ɔ́",    "pumpkin",     "nuh paw aw"),
    ("fwoe",      "fwɔ'ə",     "chisel",      "fwaw uh"),
    ("shwaa",     "shwa'a",    "razor",       "shwah ah"),
    ("ekwuno",    "əkwunɔ́",    "bed",         "uh kwoo naw"),
    ("ndue",      "nduə",      "hammer",      "n doo uh"),
    # Family & People
    ("ma",        "mǎ",        "mother",      "mah"),
    ("ye",        "yə",        "he/she",      "yuh"),
    ("apeele",    "apɛ̌ɛlə",    "mad person",  "ah pair luh"),
    ("efego",     "əfəgɔ́",     "blind person","uh fuh gaw"),
    ("alae",      "alá'ə",     "village",     "ah lah uh"),
    ("ngye",      "ngye",      "voice",       "ng yeh"),
    ("ayange",    "ayáŋə",     "wisdom",      "ah yahng uh"),
    # Food & Daily Life
    ("apeeme",    "apeemə",    "bag",         "ah peh muh"),
    ("apeene",    "apéenə",    "flour",       "ah peh nuh"),
    ("negoomo",   "nəgoomɔ́",   "plantain",    "nuh goh maw"),
    ("ngwange",   "ngwáŋə",    "salt",        "ngwahng uh"),
    ("mandzo",    "mândzǒ",    "groundnuts",  "mahn joh"),
    ("akwe",      "akwe",      "response",    "ah kweh"),
    ("metwe",     "mətwé",     "saliva",      "muh tweh"),
    ("nekengo",   "nəkəŋɔ́",    "pot",         "nuh kuhng aw"),
]


def check_dependencies():
    """Verify all required packages are installed."""
    missing = []

    try:
        import torch
    except ImportError:
        missing.append("torch (pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121)")

    try:
        from TTS.api import TTS
    except ImportError:
        missing.append("coqui-tts (pip install coqui-tts)")

    try:
        import yt_dlp
    except ImportError:
        missing.append("yt-dlp (pip install yt-dlp)")

    try:
        from pydub import AudioSegment
    except ImportError:
        missing.append("pydub (pip install pydub)")

    # Check ffmpeg
    try:
        subprocess.run(["ffmpeg", "-version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        missing.append("ffmpeg (winget install ffmpeg, or https://ffmpeg.org/download.html)")

    if missing:
        print("ERROR: Missing dependencies:")
        for dep in missing:
            print(f"  - {dep}")
        print("\nInstall them and try again.")
        sys.exit(1)

    print("All dependencies found!")


def download_youtube_audio(url: str, output_path: str) -> str:
    """Download audio from a YouTube video."""
    import yt_dlp

    ydl_opts = {
        'format': 'bestaudio/best',
        'outtmpl': output_path,
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'wav',
            'preferredquality': '0',
        }],
        'quiet': True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])

    # yt-dlp adds the extension
    wav_path = output_path + ".wav"
    if os.path.exists(wav_path):
        return wav_path

    # Sometimes it keeps original extension
    for ext in ['.wav', '.m4a', '.webm', '.mp3']:
        p = output_path + ext
        if os.path.exists(p):
            return p

    raise FileNotFoundError(f"Downloaded audio not found at {output_path}.*")


def extract_speaker_sample(audio_path: str, output_path: str,
                           start_sec: int, duration_sec: int) -> str:
    """Extract a clean segment from the audio for voice cloning."""
    from pydub import AudioSegment

    audio = AudioSegment.from_file(audio_path)
    sample = audio[start_sec * 1000 : (start_sec + duration_sec) * 1000]

    # Normalize volume
    sample = sample.set_frame_rate(22050).set_channels(1)
    change_in_dBFS = -20.0 - sample.dBFS
    sample = sample.apply_gain(change_in_dBFS)

    sample.export(output_path, format="wav")
    print(f"  Speaker sample: {duration_sec}s extracted to {output_path}")
    return output_path


def generate_clips_with_xtts(speaker_wav: str):
    """Generate all audio clips using XTTS voice cloning."""
    import torch
    from TTS.api import TTS

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"\n  Using device: {device}")
    if device == "cpu":
        print("  WARNING: CPU mode is slow (~5-10s per clip). GPU recommended.")
        print("  Total estimated time: ~10-15 minutes on CPU")
    else:
        print("  GPU detected! Estimated time: ~2-3 minutes")

    print("\n  Loading XTTS v2 model (first run downloads ~1.8GB)...")
    tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(device)

    # Cache the speaker embedding
    print("  Caching speaker voice from sample...")

    # --- Generate alphabet clips ---
    print(f"\n  Generating {len(ALPHABET_CLIPS)} alphabet clips...")
    success = 0
    for filename, display, phonetic in ALPHABET_CLIPS:
        output_path = os.path.join(ALPHABET_DIR, f"{filename}.mp3")
        try:
            tts.tts_to_file(
                text=phonetic,
                speaker_wav=speaker_wav,
                language=XTTS_LANGUAGE,
                file_path=output_path,
            )
            size = os.path.getsize(output_path)
            if size > 100:
                success += 1
                print(f"    ✓ {filename}.mp3  ({display})")
            else:
                print(f"    ✗ {filename}.mp3  ({display}) — file too small")
        except Exception as e:
            print(f"    ✗ {filename}.mp3  ({display}) — {e}")

    print(f"\n  Alphabet: {success}/{len(ALPHABET_CLIPS)} clips")

    # --- Generate vocabulary clips ---
    print(f"\n  Generating {len(VOCABULARY_CLIPS)} vocabulary clips...")
    vocab_success = 0
    for filename, awing, english, phonetic in VOCABULARY_CLIPS:
        output_path = os.path.join(VOCABULARY_DIR, f"{filename}.mp3")
        try:
            tts.tts_to_file(
                text=phonetic,
                speaker_wav=speaker_wav,
                language=XTTS_LANGUAGE,
                file_path=output_path,
            )
            size = os.path.getsize(output_path)
            if size > 100:
                vocab_success += 1
                print(f"    ✓ {filename}.mp3  ({awing} = {english})")
            else:
                print(f"    ✗ {filename}.mp3  ({awing} = {english}) — file too small")
        except Exception as e:
            print(f"    ✗ {filename}.mp3  ({awing} = {english}) — {e}")

    print(f"\n  Vocabulary: {vocab_success}/{len(VOCABULARY_CLIPS)} clips")
    return success + vocab_success


def main():
    print("=" * 60)
    print("  Awing Voice Cloning Audio Generator")
    print("  Using Coqui XTTS v2 + YouTube speaker samples")
    print("=" * 60)

    # Check dependencies
    print("\nStep 1: Checking dependencies...")
    check_dependencies()

    # Create directories
    os.makedirs(ALPHABET_DIR, exist_ok=True)
    os.makedirs(VOCABULARY_DIR, exist_ok=True)
    os.makedirs(TEMP_DIR, exist_ok=True)

    # Download YouTube audio
    print("\nStep 2: Downloading YouTube audio for voice sample...")
    video_url = YOUTUBE_URLS[SPEAKER_SAMPLE_VIDEO_INDEX]
    audio_path = os.path.join(TEMP_DIR, "source_audio")

    if not any(os.path.exists(audio_path + ext) for ext in ['.wav', '.m4a', '.webm', '.mp3']):
        downloaded_path = download_youtube_audio(video_url, audio_path)
        print(f"  Downloaded: {downloaded_path}")
    else:
        # Find existing file
        for ext in ['.wav', '.m4a', '.webm', '.mp3']:
            if os.path.exists(audio_path + ext):
                downloaded_path = audio_path + ext
                break
        print(f"  Using cached: {downloaded_path}")

    # Extract speaker sample
    print("\nStep 3: Extracting speaker sample...")
    speaker_wav = os.path.join(TEMP_DIR, "speaker_sample.wav")
    if not os.path.exists(speaker_wav):
        extract_speaker_sample(
            downloaded_path, speaker_wav,
            SPEAKER_SAMPLE_START, SPEAKER_SAMPLE_DURATION
        )
    else:
        print(f"  Using cached: {speaker_wav}")

    # Generate clips
    print("\nStep 4: Generating audio clips with cloned voice...")
    total = generate_clips_with_xtts(speaker_wav)

    total_expected = len(ALPHABET_CLIPS) + len(VOCABULARY_CLIPS)
    print()
    print("=" * 60)
    print(f"  DONE: {total}/{total_expected} audio clips generated")
    print(f"  Alphabet:   {ALPHABET_DIR}")
    print(f"  Vocabulary: {VOCABULARY_DIR}")
    print("=" * 60)
    print()
    print("Next steps:")
    print("  1. Listen to a few clips to check quality")
    print("  2. flutter pub get")
    print("  3. flutter build apk --release")
    print("  4. The app will automatically use these audio files!")
    print()
    print("Tip: If quality isn't great, try adjusting SPEAKER_SAMPLE_START")
    print("     in the script to find a clearer segment of the video.")


if __name__ == "__main__":
    main()
