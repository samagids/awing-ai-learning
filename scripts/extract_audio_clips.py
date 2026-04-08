"""
Awing Audio Clip Extractor — Fully Automated
================================================
Extracts real native-speaker pronunciation clips directly from
Awing YouTube lesson videos. No manual labeling required.

Strategy:
  - Uses the shortest alphabet video (part 1) where the speaker says each
    letter once in order → maps clips 1:1 to alphabet letters
  - For vocabulary, takes clips from vocabulary lesson videos and maps
    them sequentially to the vocabulary word list
  - Picks the best clip per word: filters out clips that are too short
    (noise) or too long (phrases), keeps clean single-word pronunciations
  - Falls back to longer alphabet videos if the first doesn't have enough clips

Requirements:
  pip install yt-dlp pydub
  Also requires ffmpeg: winget install ffmpeg

Usage:
  python scripts/extract_audio_clips.py           # Full auto: download, split, label, copy
  python scripts/extract_audio_clips.py --list    # Show what's in assets/audio/
  python scripts/extract_audio_clips.py --clean   # Delete temp files and re-extract
"""

import os
import sys
import subprocess
import argparse

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
VIDEOS_DIR = os.path.join(PROJECT_ROOT, "videos")

# ============================================================
# YouTube Sources
# ============================================================
# Alphabet videos: speaker says each letter in sequence (a, b, ch, d, e, ...)
# Vocabulary videos: speaker says words with English translations
YOUTUBE_SOURCES = [
    # --- Alphabet videos (index 0-3) ---
    # local_file: WAV already downloaded in videos/ folder (preferred)
    {
        "url": "https://www.youtube.com/watch?v=aaCB8zm7uAk",
        "local_file": "Awing alphabet - part 1.wav",
        "title": "Awing alphabet part 1 (short)",
        "type": "alphabet",
        "skip_start": 5,
        "skip_end": 3,
    },
    {
        "url": "https://www.youtube.com/watch?v=MpPIPdebQE0",
        "local_file": "Awing alphabet - part 2a.wav",
        "title": "Awing alphabet part 2a",
        "type": "alphabet",
        "skip_start": 3,
        "skip_end": 3,
    },
    {
        "local_file": "Awing alphabet - part 2b.wav",
        "title": "Awing alphabet part 2b",
        "type": "alphabet",
        "skip_start": 3,
        "skip_end": 3,
    },
    {
        "url": "https://www.youtube.com/watch?v=GaG14f8bnMI",
        "local_file": "Lesson One- Awing Alphabet.wav",
        "title": "Lesson One: Awing Alphabet (long)",
        "type": "alphabet",
        "skip_start": 10,
        "skip_end": 5,
    },
    {
        "local_file": "How to Read the Awing Alphabet.wav",
        "title": "How to Read the Awing Alphabet",
        "type": "alphabet",
        "skip_start": 5,
        "skip_end": 3,
    },
    # --- Vocabulary videos (index 5+) ---
    {
        "url": "https://www.youtube.com/watch?v=Q6dKSBlGzlc",
        "title": "Awing language lesson 2",
        "type": "vocabulary",
        "skip_start": 5,
        "skip_end": 3,
    },
    {
        "url": "https://www.youtube.com/watch?v=uNxgDelrW4U",
        "title": "Awing language lesson 3",
        "type": "vocabulary",
        "skip_start": 5,
        "skip_end": 3,
    },
    {
        "url": "https://www.youtube.com/watch?v=aOSqhGNQuC8",
        "title": "Awing language lesson 4",
        "type": "vocabulary",
        "skip_start": 5,
        "skip_end": 3,
    },
    {
        "url": "https://www.youtube.com/watch?v=sbvBQxb80Z8",
        "title": "Awing language lesson 5",
        "type": "vocabulary",
        "skip_start": 5,
        "skip_end": 3,
    },
    {
        "url": "https://www.youtube.com/watch?v=3AF3iQg-RhI",
        "title": "Awing language lesson 6",
        "type": "vocabulary",
        "skip_start": 5,
        "skip_end": 3,
    },
    {
        "url": "https://www.youtube.com/watch?v=Bq_MSpiijh4",
        "title": "Awing language lesson 7",
        "type": "vocabulary",
        "skip_start": 5,
        "skip_end": 3,
    },
    {
        "local_file": "You Can Read and Write Awing.wav",
        "title": "You Can Read and Write Awing",
        "type": "vocabulary",
        "skip_start": 5,
        "skip_end": 3,
    },
]

# ============================================================
# Expected filenames in order — must match pronunciation_service.dart
# ============================================================
ALPHABET_NAMES = [
    "a", "b", "ch", "d", "e", "epsilon", "schwa", "f", "g", "gh",
    "i", "barred_i", "j", "k", "l", "m", "n", "ny", "eng", "o",
    "open_o", "p", "s", "sh", "t", "ts", "u", "w", "y", "z", "glottal",
]

VOCABULARY_NAMES = [
    "apo", "atue", "aloeme", "fele", "nelwie", "nde", "nkadte", "mbete",
    "achie", "neto", "nepe",
    "eshue", "konge", "anyenge", "nenjwinne", "ankoome", "ngeo", "noole",
    "atie", "akoobo", "ngee", "waako", "newue",
    "no", "lume", "mie", "pime", "tsoe", "zoe", "jage", "yike",
    "ledno", "pene", "shie", "chato", "kwage", "lyange", "toge",
    "fyaale", "ko", "yie",
    "ajume", "ajwike", "afue", "nese", "mbeene", "ndzo", "nepoo",
    "fwoe", "shwaa", "ekwuno", "ndue",
    "ma", "ye", "apeele", "efego", "alae", "ngye", "ayange",
    "apeeme", "apeene", "negoomo", "ngwange", "mandzo", "akwe", "metwe",
    "nekengo",
]


def check_dependencies():
    """Verify required packages."""
    missing = []
    warnings = []

    # yt-dlp only needed if we don't have local files
    has_local = os.path.exists(VIDEOS_DIR) and any(
        f.endswith(('.wav', '.mp4')) for f in os.listdir(VIDEOS_DIR)
    ) if os.path.exists(VIDEOS_DIR) else False

    try:
        import yt_dlp
    except ImportError:
        if has_local:
            warnings.append("yt-dlp not installed (OK — using local video files)")
        else:
            missing.append("yt-dlp (pip install yt-dlp)")

    try:
        from pydub import AudioSegment
    except ImportError:
        missing.append("pydub (pip install pydub)")

    try:
        subprocess.run(["ffmpeg", "-version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        missing.append("ffmpeg (winget install ffmpeg)")

    if missing:
        print("  ERROR: Missing dependencies:")
        for dep in missing:
            print(f"    - {dep}")
        print("\n  Run: .\\scripts\\install_dependencies.bat")
        sys.exit(1)

    for w in warnings:
        print(f"  Note: {w}")

    if has_local:
        local_files = [f for f in os.listdir(VIDEOS_DIR) if f.endswith(('.wav', '.mp4'))]
        print(f"  Found {len(local_files)} local video/audio files in videos/")
    print("  All required dependencies found.")


def download_audio(source, index):
    """Get audio for a source — check local videos/ folder first, then download."""

    # 1. Check for local file in videos/ folder (already downloaded)
    local_file = source.get('local_file')
    if local_file:
        local_path = os.path.join(VIDEOS_DIR, local_file)
        if os.path.exists(local_path):
            print(f"    Local: {local_file}")
            return local_path

        # Also check MP4 version (pydub can read it via ffmpeg)
        mp4_file = local_file.replace('.wav', '.mp4')
        mp4_path = os.path.join(VIDEOS_DIR, mp4_file)
        if os.path.exists(mp4_path):
            print(f"    Local: {mp4_file}")
            return mp4_path

    # 2. Check temp cache
    output_base = os.path.join(TEMP_DIR, f"video_{index}")
    wav_path = output_base + ".wav"
    if os.path.exists(wav_path):
        print(f"    Cached: {os.path.basename(wav_path)}")
        return wav_path

    # 3. Download from YouTube
    url = source.get('url')
    if not url:
        print(f"    SKIPPED: No URL and no local file for '{source['title']}'")
        return None

    try:
        import yt_dlp
    except ImportError:
        print(f"    SKIPPED: yt-dlp not installed (pip install yt-dlp)")
        return None

    print(f"    Downloading: {source['title']}...")
    ydl_opts = {
        'format': 'bestaudio/best',
        'outtmpl': output_base,
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'wav',
            'preferredquality': '0',
        }],
        'quiet': True,
        'no_warnings': True,
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
    except Exception as e:
        print(f"    FAILED: {e}")
        return None

    for ext in ['.wav', '.m4a', '.webm', '.mp3']:
        p = output_base + ext
        if os.path.exists(p):
            return p
    return None


def split_audio(audio_path, source, min_silence_ms=700, silence_thresh_db=-30,
                min_clip_ms=300, max_clip_ms=6000):
    """Split audio into chunks using silence detection."""
    from pydub import AudioSegment
    from pydub.silence import split_on_silence

    audio = AudioSegment.from_file(audio_path)

    # Trim intro/outro
    start = source.get('skip_start', 0) * 1000
    end = source.get('skip_end', 0) * 1000
    if end > 0:
        audio = audio[start:-end]
    else:
        audio = audio[start:]

    print(f"    Duration: {len(audio)/1000:.1f}s | Splitting (thresh={silence_thresh_db}dB, gap={min_silence_ms}ms)...")

    chunks = split_on_silence(
        audio,
        min_silence_len=min_silence_ms,
        silence_thresh=silence_thresh_db,
        keep_silence=100,
    )

    # Filter by duration — keep only clean single-word clips
    good = []
    for chunk in chunks:
        dur = len(chunk)
        if min_clip_ms <= dur <= max_clip_ms:
            good.append(chunk)
        elif dur > max_clip_ms:
            # Try splitting long segments more aggressively
            sub = split_on_silence(chunk, min_silence_len=250,
                                   silence_thresh=silence_thresh_db + 5,
                                   keep_silence=80)
            for sc in sub:
                if min_clip_ms <= len(sc) <= max_clip_ms:
                    good.append(sc)

    print(f"    Found {len(good)} usable clips (from {len(chunks)} segments)")
    return good


def normalize_and_export(chunk, filepath):
    """Normalize volume, convert to mono, export as MP3."""
    chunk = chunk.set_channels(1).set_frame_rate(22050)
    # Normalize to -20 dBFS
    change = -20.0 - chunk.dBFS
    chunk = chunk.apply_gain(change)
    chunk.export(filepath, format="mp3", bitrate="128k")


def extract_alphabet(sources):
    """
    Extract alphabet clips from alphabet videos.

    Strategy: Try each alphabet video until we find one where the number of
    clips roughly matches 31 (the alphabet size). The speaker says each letter
    in order, so clip N = letter N.

    If no video gives exactly 31 clips, use the closest match and try
    different silence settings.
    """
    os.makedirs(ALPHABET_DIR, exist_ok=True)
    target = len(ALPHABET_NAMES)  # 31
    best_chunks = None
    best_diff = 999
    best_source_title = ""

    # Silence settings to try — from strict to lenient
    settings = [
        (800, -28),  # Very strict: long gaps, louder threshold
        (700, -30),  # Default
        (600, -32),  # Medium
        (500, -35),  # Lenient
        (900, -25),  # Extra strict
        (1000, -22), # Ultra strict for dense videos
    ]

    for idx, source in sources:
        audio_path = download_audio(source, idx)
        if not audio_path:
            continue

        for min_sil, thresh in settings:
            chunks = split_audio(audio_path, source,
                                min_silence_ms=min_sil,
                                silence_thresh_db=thresh)
            diff = abs(len(chunks) - target)
            if diff < best_diff:
                best_diff = diff
                best_chunks = chunks
                best_source_title = source['title']
                best_settings = (min_sil, thresh)

            # Perfect match — stop searching
            if len(chunks) == target:
                break

        if best_diff == 0:
            break

    if not best_chunks:
        print("  ERROR: Could not extract alphabet clips from any video.")
        return 0

    print(f"\n  Best match: '{best_source_title}' → {len(best_chunks)} clips "
          f"(target: {target}, settings: gap={best_settings[0]}ms, thresh={best_settings[1]}dB)")

    # Map clips to alphabet names
    count = 0
    for i, name in enumerate(ALPHABET_NAMES):
        if i < len(best_chunks):
            dest = os.path.join(ALPHABET_DIR, f"{name}.mp3")
            normalize_and_export(best_chunks[i], dest)
            dur = len(best_chunks[i])
            print(f"    [{i+1:2d}/{target}] {name}.mp3  ({dur}ms)")
            count += 1
        else:
            print(f"    [{i+1:2d}/{target}] {name}.mp3  — MISSING (not enough clips)")

    return count


def extract_vocabulary(sources):
    """
    Extract vocabulary clips from vocabulary lesson videos.

    Strategy: Pool all clips from all vocabulary videos into one big list,
    then assign them sequentially to vocabulary words. Each video contributes
    clips for the next batch of words in the list.
    """
    os.makedirs(VOCABULARY_DIR, exist_ok=True)
    target = len(VOCABULARY_NAMES)  # 67

    all_chunks = []
    for idx, source in sources:
        audio_path = download_audio(source, idx)
        if not audio_path:
            continue

        # Try default settings first
        chunks = split_audio(audio_path, source,
                           min_silence_ms=700, silence_thresh_db=-30)
        if chunks:
            all_chunks.extend(chunks)
            print(f"    Added {len(chunks)} clips from '{source['title']}'")

    if not all_chunks:
        print("  ERROR: Could not extract vocabulary clips from any video.")
        return 0

    print(f"\n  Total vocabulary clips available: {len(all_chunks)} (need {target})")

    # Assign clips to vocabulary names
    # If we have more clips than words, pick evenly spaced ones
    count = 0
    if len(all_chunks) >= target:
        # Pick best clips — evenly distributed across the pool
        step = len(all_chunks) / target
        for i, name in enumerate(VOCABULARY_NAMES):
            clip_idx = min(int(i * step), len(all_chunks) - 1)
            dest = os.path.join(VOCABULARY_DIR, f"{name}.mp3")
            normalize_and_export(all_chunks[clip_idx], dest)
            dur = len(all_chunks[clip_idx])
            print(f"    [{i+1:2d}/{target}] {name}.mp3  ({dur}ms)")
            count += 1
    else:
        # Not enough clips — assign what we have
        for i, name in enumerate(VOCABULARY_NAMES):
            if i < len(all_chunks):
                dest = os.path.join(VOCABULARY_DIR, f"{name}.mp3")
                normalize_and_export(all_chunks[i], dest)
                dur = len(all_chunks[i])
                print(f"    [{i+1:2d}/{target}] {name}.mp3  ({dur}ms)")
                count += 1
            else:
                print(f"    [{i+1:2d}/{target}] {name}.mp3  — MISSING")

    return count


def list_assets():
    """Show what's currently in assets/audio/."""
    print("\n  === Audio Assets ===")
    for dir_path, label in [(ALPHABET_DIR, "Alphabet"), (VOCABULARY_DIR, "Vocabulary")]:
        if os.path.exists(dir_path):
            mp3s = sorted([f for f in os.listdir(dir_path) if f.endswith('.mp3')])
            print(f"\n  {label}: {len(mp3s)} clips")
            for f in mp3s:
                size = os.path.getsize(os.path.join(dir_path, f))
                print(f"    {f:25s} ({size/1024:.1f} KB)")
        else:
            print(f"\n  {label}: (no clips yet)")


def clean_temp():
    """Delete temp files to force re-download and re-extraction."""
    import shutil
    if os.path.exists(TEMP_DIR):
        shutil.rmtree(TEMP_DIR)
        print(f"  Deleted: {TEMP_DIR}")
    print("  Run the script again to re-extract from YouTube.")


def main():
    parser = argparse.ArgumentParser(
        description="Extract Awing pronunciation clips from YouTube — fully automated")
    parser.add_argument("--list", "-l", action="store_true",
                       help="List current audio assets")
    parser.add_argument("--clean", action="store_true",
                       help="Delete temp files and start fresh")
    parser.add_argument("--alphabet-only", action="store_true",
                       help="Only extract alphabet clips")
    parser.add_argument("--vocab-only", action="store_true",
                       help="Only extract vocabulary clips")
    args = parser.parse_args()

    print("=" * 60)
    print("  Awing Audio Clip Extractor (Fully Automated)")
    print("  Extracts real pronunciation from native speaker videos")
    print("=" * 60)

    if args.list:
        list_assets()
        return

    if args.clean:
        clean_temp()
        return

    print("\nStep 1: Checking dependencies...")
    check_dependencies()
    os.makedirs(TEMP_DIR, exist_ok=True)

    alphabet_sources = [(i, s) for i, s in enumerate(YOUTUBE_SOURCES) if s['type'] == 'alphabet']
    vocab_sources = [(i, s) for i, s in enumerate(YOUTUBE_SOURCES) if s['type'] == 'vocabulary']

    alphabet_count = 0
    vocab_count = 0

    # Default: alphabet only (letters are spoken in order so mapping is reliable).
    # Vocabulary extraction is disabled by default because the videos don't speak
    # words in the same order as our vocabulary list — clips get mismatched.
    # Use --vocab-only to force vocabulary extraction (requires manual verification).

    if args.vocab_only:
        print(f"\nStep 2: Extracting vocabulary clips ({len(VOCABULARY_NAMES)} words)...")
        print("  WARNING: Vocabulary clips may not match words! Verify manually.")
        vocab_count = extract_vocabulary(vocab_sources)
    else:
        print(f"\nStep 2: Extracting alphabet clips ({len(ALPHABET_NAMES)} letters)...")
        alphabet_count = extract_alphabet(alphabet_sources)
        print(f"\n  Note: Vocabulary uses Edge TTS voices (not video extraction)")
        print(f"        because video word order doesn't match our vocabulary list.")

    total = alphabet_count + vocab_count
    print()
    print("=" * 60)
    print(f"  DONE: {total} audio clips extracted")
    print(f"    Alphabet:   {alphabet_count}/{len(ALPHABET_NAMES)}")
    if vocab_count > 0:
        print(f"    Vocabulary: {vocab_count}/{len(VOCABULARY_NAMES)}")
    else:
        print(f"    Vocabulary: uses Edge TTS character voices")
    print(f"    Saved to:   assets/audio/")
    print("=" * 60)
    print()
    if total > 0:
        print("  Next: rebuild the app to include the audio clips:")
        print("    flutter pub get && flutter build apk --release")


if __name__ == "__main__":
    main()
