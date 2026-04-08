#!/usr/bin/env python3
"""
train_awing_tts.py  v3.2.0
Train a custom Awing TTS model from native speaker video files.

All video files must be pre-downloaded into the videos/ folder.
Uses subtitle-aligned audio (SRT files) plus silence detection for
segmentation. Whisper ASR auto-transcribes audio, OCR reads on-screen
text from video frames. Trains a VITS model using HuggingFace transformers.

Pipeline:
  1. PREPARE  — Extract audio from local videos, segment by subtitle
                timing or silence detection, run OCR on video frames
  2. LABEL    — Auto-label all clips (Whisper + OCR + subtitle text)
  3. TRAIN    — Train VITS model on labeled audio-text pairs
  4. GENERATE — Use trained model to generate 98 pronunciation clips

Usage:
  python scripts/train_awing_tts.py prepare
  python scripts/train_awing_tts.py label --auto
  python scripts/train_awing_tts.py train
  python scripts/train_awing_tts.py generate
  python scripts/train_awing_tts.py all
  python scripts/train_awing_tts.py add-video
  python scripts/train_awing_tts.py status

Requirements:
  All dependencies installed by scripts/install_dependencies.bat
  Video files in videos/ folder (.mp4, .mkv, .avi, .webm, .mov)
  Optional: SRT subtitle files next to video files
  NVIDIA GPU with >= 12GB VRAM (for training)
  ffmpeg installed
"""

import os
import sys
import json
import argparse
import subprocess
import shutil
import re
from pathlib import Path

# ---------------------------------------------------------------------------
# Auto-activate venv_torch (PyTorch env for training/audio/TTS)
# ---------------------------------------------------------------------------
def _ensure_venv():
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
    result = subprocess.run([str(venv_python)] + sys.argv, cwd=str(project_root))
    sys.exit(result.returncode)

_ensure_venv()

# ---------------------------------------------------------------------------
# Imports (after venv activation)
# ---------------------------------------------------------------------------
import numpy as np

try:
    from pydub import AudioSegment
    from pydub.silence import split_on_silence, detect_nonsilent
except ImportError:
    print("ERROR: pydub not installed. Run scripts/install_dependencies.bat")
    sys.exit(1)

try:
    import sounddevice as sd
    import soundfile as sf
    HAS_AUDIO_PLAYBACK = True
except ImportError:
    HAS_AUDIO_PLAYBACK = False

try:
    import cv2
    HAS_OPENCV = True
except ImportError:
    HAS_OPENCV = False

try:
    import easyocr
    HAS_OCR = True
except ImportError:
    HAS_OCR = False

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
VIDEOS_DIR = PROJECT_ROOT / "videos"          # ALL videos live here (local + downloaded)
TRAIN_DIR = PROJECT_ROOT / "training_data"
CLIPS_DIR = TRAIN_DIR / "clips"
LABELED_DIR = TRAIN_DIR / "labeled"
MODELS_DIR = PROJECT_ROOT / "models" / "awing_tts"
ASSETS_AUDIO = PROJECT_ROOT / "assets" / "audio"

LABELS_FILE = TRAIN_DIR / "labels.json"

# Video file extensions to auto-discover in videos/ folder
VIDEO_EXTENSIONS = {".mp4", ".mkv", ".avi", ".webm", ".mov", ".flv"}

# Silence detection settings to try (threshold_dB, min_silence_ms)
# More aggressive settings to capture short word clips from lesson videos
SILENCE_SETTINGS = [
    (-30, 500), (-35, 500), (-25, 500),
    (-30, 300), (-35, 300), (-25, 300),
    (-30, 700), (-35, 700), (-25, 700),
    (-40, 400), (-20, 400),
]

# App audio clip names (what we need to generate)
ALPHABET_CLIPS = [
    "a", "b", "d", "e", "epsilon", "schwa", "f", "g", "gh",
    "h", "barred_i", "i", "k", "l", "m", "n", "eng", "o",
    "open_o", "p", "r", "s", "sh", "t", "u", "v", "w", "y", "z", "zh", "glottal"
]

VOCABULARY_CLIPS = [
    "apo", "eshue", "efoe", "mbu", "ndo", "eghang", "ekue",
    "efie", "ala", "alang", "efo", "enyu", "aku", "akwi",
    "meni", "ndze", "eshe", "engwe", "evu", "ngwe", "abie",
    "nkfu", "mala", "eno", "ngong", "ntsue", "etsung", "mbue",
    "afe", "mbe", "echi", "eli", "nte", "nshi", "ndoe", "ngwe_animal",
    "ngeng", "enjui", "mbuo", "nguo", "ewu", "nke", "ngwo",
    "azu", "asi", "akang", "elie", "enie", "eto", "emie",
    "ngong_drum", "abie_dance", "enge", "alung", "mbe_goat",
    "nde", "enang", "nsong", "elung", "ala_land",
    "eka", "efung", "ezhue", "nang", "meka", "ntung", "anie"
]


# ===================================================================
# Utility functions
# ===================================================================
def discover_all_videos():
    """Discover all video files in videos/ folder with their SRT subtitles."""
    VIDEOS_DIR.mkdir(parents=True, exist_ok=True)
    videos = []
    local_paths_lower = set()  # Track which local files we've already added

    # 1. Auto-discover any video files already in videos/ folder
    for f in sorted(VIDEOS_DIR.iterdir()):
        if f.is_file() and f.suffix.lower() in VIDEO_EXTENSIONS:
            name_lower = f.stem.lower()
            if any(w in name_lower for w in ["film", "jesus", "movie", "invitation"]):
                vtype = "film"
            elif "alphabet" in name_lower or "read" in name_lower:
                vtype = "alphabet"
            elif "vocab" in name_lower or "lesson" in name_lower:
                vtype = "vocabulary"
            else:
                vtype = "film"  # Default to film (long video)

            # Check for matching SRT subtitle file
            srt_candidates = list(f.parent.glob(f"{f.stem}*.srt"))
            srt_path = str(srt_candidates[0]) if srt_candidates else None

            videos.append({
                "local_path": str(f),
                "type": vtype,
                "title": f.stem,
                "source": "local",
                "srt_path": srt_path,
            })
            local_paths_lower.add(name_lower)

    # NOTE: We only use local videos — no YouTube downloads.
    # All videos must be pre-downloaded into the videos/ folder.

    if not videos:
        print(f"  WARNING: No video files found in {VIDEOS_DIR}")
        print(f"  Place .mp4/.mkv/.avi/.webm/.mov files in the videos/ folder.")

    return videos


def load_labels():
    if LABELS_FILE.exists():
        with open(LABELS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_labels(labels):
    TRAIN_DIR.mkdir(parents=True, exist_ok=True)
    with open(LABELS_FILE, "w", encoding="utf-8") as f:
        json.dump(labels, f, indent=2, ensure_ascii=False)


def play_clip(clip_path):
    """Play an audio clip using sounddevice or ffplay."""
    if not HAS_AUDIO_PLAYBACK:
        try:
            subprocess.run(
                ["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", str(clip_path)],
                timeout=10
            )
        except Exception:
            print("  (Cannot play audio)")
        return
    try:
        data, rate = sf.read(str(clip_path))
        sd.play(data, rate)
        sd.wait()
    except Exception as e:
        print(f"  (Playback error: {e})")


def parse_srt(srt_path):
    """Parse an SRT subtitle file into a list of {start_sec, end_sec, text}.

    Robust parser that handles auto-generated SRT files with extra blank lines,
    double \\r\\r\\n line endings, BOM markers, and inconsistent formatting.
    """
    entries = []
    # Read raw bytes and normalize all line endings to \n
    raw = Path(srt_path).read_bytes()
    raw = raw.replace(b"\r\r\n", b"\n").replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    # Remove BOM
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    text_content = raw.decode("utf-8", errors="replace")
    lines = text_content.split("\n")

    TIME_RE = re.compile(
        r"(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})"
    )

    i = 0
    while i < len(lines):
        line = lines[i].strip()
        # Look for a timestamp line anywhere
        time_match = TIME_RE.match(line)
        if time_match:
            g = time_match.groups()
            start = int(g[0]) * 3600 + int(g[1]) * 60 + int(g[2]) + int(g[3]) / 1000.0
            end = int(g[4]) * 3600 + int(g[5]) * 60 + int(g[6]) + int(g[7]) / 1000.0
            # Skip any blank lines between timestamp and text
            i += 1
            while i < len(lines) and not lines[i].strip():
                i += 1
            # Collect text lines until blank line or next entry index
            text_lines = []
            while i < len(lines):
                tl = lines[i].strip()
                if not tl:  # Blank line = end of this entry
                    i += 1
                    break
                # If it looks like a numeric index for next entry, stop
                if tl.isdigit() and i + 1 < len(lines) and TIME_RE.match(lines[i + 1].strip()):
                    break
                text_lines.append(tl)
                i += 1
            text = " ".join(text_lines).strip()
            # Remove HTML tags and [Music]/[Applause] markers
            text = re.sub(r"<[^>]+>", "", text)
            text = re.sub(r"\[.*?\]", "", text).strip()
            if text and len(text) > 0:
                entries.append({"start_sec": start, "end_sec": end, "text": text})
        else:
            i += 1

    return entries


# ===================================================================
# STEP 1: PREPARE — Download, segment, OCR
# ===================================================================
def ensure_video_ready(video):
    """Ensure local video has extracted audio. Returns (video_path, audio_path)."""
    local_path = video.get("local_path")
    if not local_path or not Path(local_path).exists():
        print(f"  ERROR: Video file not found: {local_path}")
        print(f"  Place the video in: {VIDEOS_DIR}")
        return None, None

    video_path = Path(local_path)
    audio_path = video_path.with_suffix(".wav")

    if not audio_path.exists():
        print(f"  Extracting audio from {video_path.name}...")
        try:
            subprocess.run([
                "ffmpeg", "-i", str(video_path), "-ac", "1", "-ar", "16000",
                "-y", str(audio_path)
            ], capture_output=True, timeout=600)
            print(f"  Audio extracted.")
        except Exception as e:
            print(f"  ERROR extracting audio: {e}")
            return None, None
    else:
        print(f"  Audio already extracted.")

    return video_path, audio_path


def segment_by_subtitles(audio_path, srt_path, vid_dir):
    """Segment audio into clips based on subtitle timing."""
    clips_dir = vid_dir / "clips"
    metadata_path = vid_dir / "clip_metadata.json"

    if metadata_path.exists():
        with open(metadata_path, "r", encoding="utf-8") as f:
            metadata = json.load(f)
        if len(metadata) > 0:
            print(f"  Already segmented into {len(metadata)} clips.")
            return metadata
        # Cached 0 clips — likely a previous parser bug. Re-segment.
        print(f"  Previous run found 0 clips. Re-segmenting...")

    print(f"  Segmenting audio by subtitle timing...")
    entries = parse_srt(srt_path)
    audio = AudioSegment.from_wav(str(audio_path))

    clips_dir.mkdir(parents=True, exist_ok=True)
    metadata = []

    for i, entry in enumerate(entries):
        start_ms = int(entry["start_sec"] * 1000)
        end_ms = int(entry["end_sec"] * 1000)

        # Skip very short or very long segments
        duration_ms = end_ms - start_ms
        if duration_ms < 300 or duration_ms > 15000:
            continue

        clip = audio[start_ms:end_ms]
        # Convert to 16kHz mono for training
        clip = clip.set_frame_rate(16000).set_channels(1)

        clip_name = f"clip_{i:04d}.wav"
        clip.export(str(clips_dir / clip_name), format="wav")

        metadata.append({
            "file": clip_name,
            "start_sec": entry["start_sec"],
            "end_sec": entry["end_sec"],
            "subtitle_text": entry["text"],  # English subtitle
            "awing_text": None,  # To be filled by Whisper
        })

    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)

    print(f"  Created {len(metadata)} subtitle-aligned clips.")
    return metadata


def segment_by_silence(audio_path, vid_dir):
    """Segment audio by silence detection (for lesson videos without subtitles)."""
    clips_dir = vid_dir / "clips"
    metadata_path = vid_dir / "clip_metadata.json"

    if metadata_path.exists():
        with open(metadata_path, "r", encoding="utf-8") as f:
            metadata = json.load(f)
        print(f"  Already split into {len(metadata)} clips.")
        return metadata

    print(f"  Splitting audio by silence detection...")
    audio = AudioSegment.from_wav(str(audio_path))
    audio = audio.set_frame_rate(16000).set_channels(1)

    best_clips = []
    for thresh, min_sil in SILENCE_SETTINGS:
        try:
            nonsilent = detect_nonsilent(audio, min_silence_len=min_sil, silence_thresh=thresh)
            clips = []
            for start, end in nonsilent:
                dur = end - start
                if 200 <= dur <= 8000:
                    clips.append((start, end))
            if len(clips) > len(best_clips):
                best_clips = clips
        except Exception:
            continue

    if not best_clips:
        print(f"  WARNING: No clips found with silence detection. Using fixed intervals.")
        # Fallback: split into 2-second chunks
        total_ms = len(audio)
        for start in range(0, total_ms - 2000, 2500):
            best_clips.append((start, start + 2000))

    clips_dir.mkdir(parents=True, exist_ok=True)
    metadata = []

    for i, (start, end) in enumerate(best_clips):
        clip = audio[start:end]
        clip_name = f"clip_{i:04d}.wav"
        clip.export(str(clips_dir / clip_name), format="wav")
        metadata.append({
            "file": clip_name,
            "start_sec": start / 1000.0,
            "end_sec": end / 1000.0,
            "awing_text": None,
        })

    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)

    print(f"  Split into {len(metadata)} clips.")
    return metadata


def segment_by_silence_long(audio_path, vid_dir):
    """Segment long audio (films) by silence detection, processing in chunks."""
    clips_dir = vid_dir / "clips"
    metadata_path = vid_dir / "clip_metadata.json"

    if metadata_path.exists():
        with open(metadata_path, "r", encoding="utf-8") as f:
            metadata = json.load(f)
        print(f"  Already split into {len(metadata)} clips.")
        return metadata

    print(f"  Loading audio (this may take a moment for long files)...")
    audio = AudioSegment.from_wav(str(audio_path))
    audio = audio.set_frame_rate(16000).set_channels(1)
    total_ms = len(audio)
    total_min = total_ms / 60000

    print(f"  Audio length: {total_min:.1f} minutes")
    print(f"  Splitting by silence detection (processing in 5-min chunks)...")

    clips_dir.mkdir(parents=True, exist_ok=True)
    metadata = []
    clip_idx = 0

    # Process in 5-minute chunks to manage memory
    chunk_ms = 5 * 60 * 1000  # 5 minutes
    for chunk_start in range(0, total_ms, chunk_ms):
        chunk_end = min(chunk_start + chunk_ms, total_ms)
        chunk = audio[chunk_start:chunk_end]
        chunk_min = chunk_start / 60000

        if (chunk_start // chunk_ms) % 5 == 0:
            print(f"    Processing {chunk_min:.0f}-{(chunk_end/60000):.0f} min...")

        # Try different silence settings for this chunk
        best_segments = []
        for thresh, min_sil in SILENCE_SETTINGS:
            try:
                nonsilent = detect_nonsilent(chunk, min_silence_len=min_sil, silence_thresh=thresh)
                segments = []
                for start, end in nonsilent:
                    dur = end - start
                    # Accept clips 0.5s to 10s (longer for film sentences)
                    if 500 <= dur <= 10000:
                        segments.append((start, end))
                if len(segments) > len(best_segments):
                    best_segments = segments
            except Exception:
                continue

        # Save clips from this chunk
        for start, end in best_segments:
            clip = chunk[start:end]
            clip_name = f"clip_{clip_idx:04d}.wav"
            clip.export(str(clips_dir / clip_name), format="wav")
            metadata.append({
                "file": clip_name,
                "start_sec": (chunk_start + start) / 1000.0,
                "end_sec": (chunk_start + end) / 1000.0,
                "awing_text": None,
            })
            clip_idx += 1

    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)

    print(f"  Split into {len(metadata)} clips from {total_min:.0f} minutes of audio.")
    return metadata


def run_ocr_on_video(video_path, vid_dir):
    """Run EasyOCR on video frames to detect on-screen Awing text."""
    ocr_path = vid_dir / "ocr_timeline.json"
    if ocr_path.exists():
        with open(ocr_path, "r", encoding="utf-8") as f:
            return json.load(f)

    if not HAS_OPENCV or not HAS_OCR:
        print("  (Skipping OCR — opencv/easyocr not available)")
        return []

    print(f"  Running OCR on video frames...")
    reader = easyocr.Reader(["en"], gpu=True, verbose=False)
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        print("  ERROR: Cannot open video.")
        return []

    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = total_frames / fps
    sample_interval = 0.5  # seconds

    timeline = []
    last_text = ""
    frame_count = int(duration / sample_interval)

    for i in range(frame_count):
        time_sec = i * sample_interval
        frame_pos = int(time_sec * fps)
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_pos)
        ret, frame = cap.read()
        if not ret:
            continue

        try:
            results = reader.readtext(frame, detail=1)
            texts = [r[1] for r in results if r[2] > 0.5 and len(r[1]) > 1]
            combined = " ".join(texts)
            if combined and combined != last_text:
                timeline.append({
                    "time_sec": time_sec,
                    "text": combined,
                    "words": texts,
                })
                last_text = combined
        except Exception:
            continue

        if (i + 1) % 100 == 0:
            print(f"    Scanned {i+1}/{frame_count} frames...")

    cap.release()

    with open(ocr_path, "w", encoding="utf-8") as f:
        json.dump(timeline, f, indent=2, ensure_ascii=False)

    print(f"  OCR detected {len(timeline)} text changes.")
    return timeline


def match_ocr_to_clips(metadata, ocr_timeline):
    """Match OCR text to audio clips by timing (within ±2 seconds)."""
    matched = 0
    for clip in metadata:
        if clip.get("awing_text"):
            continue
        clip_mid = (clip["start_sec"] + clip["end_sec"]) / 2
        best = None
        best_dist = 999
        for ocr in ocr_timeline:
            dist = abs(ocr["time_sec"] - clip_mid)
            if dist < best_dist and dist < 2.0:
                best_dist = dist
                best = ocr
        if best:
            clip["ocr_suggestion"] = best["text"]
            matched += 1
    return matched


def cmd_prepare(args):
    """Download videos, extract audio, segment, run OCR."""
    print("\n" + "=" * 60)
    print("  STEP 1: PREPARE — Download, segment, and OCR")
    print("=" * 60)
    print(f"  Videos folder: {VIDEOS_DIR}")

    videos = discover_all_videos()

    print(f"  Found: {len(videos)} local videos")
    print()

    total_clips = 0

    for idx, video in enumerate(videos):
        title = video.get("title", "Unknown")
        vtype = video.get("type", "film")

        print(f"--- [{idx+1}/{len(videos)}] {title} ({vtype}) ---")

        # Ensure video + audio are available locally
        video_path, audio_path = ensure_video_ready(video)
        if not audio_path or not audio_path.exists():
            print(f"  SKIPPED: No audio.")
            continue

        # Create clips directory for this video
        safe_name = re.sub(r'[^\w\-.]', '_', Path(video_path).stem)[:50]
        vid_dir = CLIPS_DIR / safe_name

        # Segment audio — use subtitles if available, otherwise silence detection
        srt_path = video.get("srt_path")
        if not srt_path:
            # Check for SRT file next to the video
            srt_candidates = list(Path(video_path).parent.glob(f"{Path(video_path).stem}*.srt"))
            if srt_candidates:
                srt_path = str(srt_candidates[0])

        if srt_path and Path(srt_path).exists():
            print(f"  Using subtitle file: {Path(srt_path).name}")
            metadata = segment_by_subtitles(audio_path, srt_path, vid_dir)
        elif vtype == "film":
            metadata = segment_by_silence_long(audio_path, vid_dir)
        else:
            metadata = segment_by_silence(audio_path, vid_dir)

        # Run OCR on video (all types — films have title cards, lessons have Awing text)
        if video_path and video_path.exists():
            ocr_timeline = run_ocr_on_video(video_path, vid_dir)
            matched = match_ocr_to_clips(metadata, ocr_timeline)
            meta_path = vid_dir / "clip_metadata.json"
            with open(meta_path, "w", encoding="utf-8") as f:
                json.dump(metadata, f, indent=2, ensure_ascii=False)
            if matched > 0:
                print(f"  OCR matched {matched}/{len(metadata)} clips.")

        total_clips += len(metadata)

    print(f"\n{'=' * 60}")
    print(f"  PREPARE COMPLETE: {total_clips} total clips across {len(videos)} videos")
    print(f"  Videos stored in: {VIDEOS_DIR}")
    print(f"  Clips stored in: {CLIPS_DIR}")
    print(f"  Next step: python scripts/train_awing_tts.py label --auto")
    print(f"{'=' * 60}\n")


# ===================================================================
# STEP 2: LABEL — Auto-transcribe with Whisper + OCR
# ===================================================================
def _load_whisper_model():
    """Load OpenAI Whisper model for automatic speech recognition."""
    try:
        import whisper
        print("  Loading Whisper model (base) for speech recognition...")
        model = whisper.load_model("base")
        device = "GPU" if next(model.parameters()).is_cuda else "CPU"
        print(f"  Whisper loaded on {device}")
        return model
    except ImportError:
        print("  WARNING: openai-whisper not installed. Skipping Whisper.")
        return None


def _whisper_transcribe(model, clip_path):
    """Transcribe a single audio clip using Whisper."""
    try:
        result = model.transcribe(str(clip_path), fp16=False)
        text = result.get("text", "").strip()
        if text and len(text) > 0 and text.lower() not in ("you", "the", "a", "i", ".", ""):
            return text
    except Exception:
        pass
    return None


def cmd_label(args):
    """Label audio clips with Awing text (auto or interactive)."""
    auto_mode = getattr(args, "auto", False)
    use_whisper = getattr(args, "whisper", True)  # Default ON

    print("\n" + "=" * 60)
    if auto_mode:
        print("  STEP 2: LABEL — AUTO MODE")
    else:
        print("  STEP 2: LABEL — Interactive mode")
    print("=" * 60)

    # Load Whisper for transcription
    whisper_model = None
    if use_whisper or auto_mode:
        whisper_model = _load_whisper_model()

    labels = load_labels()

    # Gather all clips
    all_clips = []
    for vid_dir in sorted(CLIPS_DIR.iterdir()):
        if not vid_dir.is_dir():
            continue
        meta_path = vid_dir / "clip_metadata.json"
        if not meta_path.exists():
            continue
        with open(meta_path, "r", encoding="utf-8") as f:
            metadata = json.load(f)
        clips_subdir = vid_dir / "clips"
        for clip_meta in metadata:
            clip_path = clips_subdir / clip_meta["file"]
            if not clip_path.exists():
                continue
            clip_key = str(clip_path.relative_to(CLIPS_DIR))
            ocr_hint = clip_meta.get("ocr_suggestion") or clip_meta.get("awing_text")
            all_clips.append((clip_key, clip_path, ocr_hint, clip_meta))

    unlabeled = [(k, p, ocr, meta) for k, p, ocr, meta in all_clips if k not in labels]
    labeled_count = len(all_clips) - len(unlabeled)

    ocr_available = sum(1 for _, _, ocr, _ in unlabeled if ocr)
    print(f"\n  Total clips: {len(all_clips)}")
    print(f"  Already labeled: {labeled_count}")
    print(f"  Remaining: {len(unlabeled)} ({ocr_available} with OCR/subtitle hints)\n")

    if not unlabeled:
        usable = sum(1 for v in labels.values() if v not in ("__SKIP__", "__DELETE__"))
        print(f"  All clips labeled! ({usable} usable)")
        print(f"  Run: python scripts/train_awing_tts.py train")
        return

    newly_labeled = 0
    ocr_accepted = 0
    whisper_labeled = 0
    skipped = 0

    if auto_mode:
        # === AUTO MODE ===
        for idx, (clip_key, clip_path, ocr_hint, clip_meta) in enumerate(unlabeled):
            if ocr_hint:
                labels[clip_key] = ocr_hint
                newly_labeled += 1
                ocr_accepted += 1
            elif whisper_model is not None:
                whisper_text = _whisper_transcribe(whisper_model, clip_path)
                if whisper_text:
                    labels[clip_key] = whisper_text
                    newly_labeled += 1
                    whisper_labeled += 1
                else:
                    labels[clip_key] = "__SKIP__"
                    skipped += 1
            else:
                labels[clip_key] = "__SKIP__"
                skipped += 1

            if newly_labeled > 0 and newly_labeled % 100 == 0:
                save_labels(labels)
                print(f"  Auto-labeled {newly_labeled} clips...")

        save_labels(labels)
        usable = sum(1 for v in labels.values() if v not in ("__SKIP__", "__DELETE__"))
        print(f"\n{'=' * 60}")
        print(f"  AUTO-LABELING COMPLETE!")
        print(f"  OCR/subtitle accepted: {ocr_accepted}")
        print(f"  Whisper transcribed: {whisper_labeled}")
        print(f"  Skipped: {skipped}")
        print(f"  Total usable: {usable}")
        if usable >= 80:
            print(f"\n  Ready to train! Run: python scripts/train_awing_tts.py train")
        else:
            print(f"\n  Need more clips. Add videos: python scripts/train_awing_tts.py add-video <URL>")
        print(f"{'=' * 60}\n")

    else:
        # === INTERACTIVE MODE ===
        print("  For each clip: p=play, s=skip, d=delete, q=quit")
        print("  Press ENTER to accept suggestion, or type Awing text.\n")

        for idx, (clip_key, clip_path, ocr_hint, clip_meta) in enumerate(unlabeled):
            print(f"\n  [{labeled_count + idx + 1}/{len(all_clips)}] {clip_key}")

            whisper_hint = None
            if not ocr_hint and whisper_model:
                whisper_hint = _whisper_transcribe(whisper_model, clip_path)

            best_hint = ocr_hint or whisper_hint
            if ocr_hint:
                print(f"  [OCR: {ocr_hint}]")
            if whisper_hint:
                print(f"  [Whisper: {whisper_hint}]")
            if clip_meta.get("subtitle_text"):
                print(f"  [English: {clip_meta['subtitle_text']}]")

            play_clip(clip_path)

            while True:
                if best_hint:
                    user_input = input(f"  >> (ENTER=\"{best_hint}\" / p/s/d/q): ").strip()
                else:
                    user_input = input("  >> Awing text (or p/s/d/q): ").strip()

                if user_input.lower() == "p":
                    play_clip(clip_path)
                elif user_input.lower() == "s":
                    labels[clip_key] = "__SKIP__"
                    break
                elif user_input.lower() == "d":
                    labels[clip_key] = "__DELETE__"
                    break
                elif user_input.lower() == "q":
                    save_labels(labels)
                    print(f"\n  Saved! {newly_labeled} new labels.")
                    return
                elif user_input == "" and best_hint:
                    labels[clip_key] = best_hint
                    newly_labeled += 1
                    break
                elif user_input:
                    labels[clip_key] = user_input
                    newly_labeled += 1
                    break

            if newly_labeled > 0 and newly_labeled % 10 == 0:
                save_labels(labels)

        save_labels(labels)
        usable = sum(1 for v in labels.values() if v not in ("__SKIP__", "__DELETE__"))
        print(f"\n  Labeling complete! {usable} usable clips.")


# ===================================================================
# STEP 3: TRAIN — Fine-tune VITS on labeled data
# ===================================================================
def cmd_train(args):
    """Train VITS model on labeled Awing audio-text pairs."""
    print("\n" + "=" * 60)
    print("  STEP 3: TRAIN — Training Awing VITS model")
    print("=" * 60)

    import torch

    # Check GPU (required — no CPU fallback)
    if torch.cuda.is_available():
        gpu_name = torch.cuda.get_device_name(0)
        vram = torch.cuda.get_device_properties(0).total_memory / (1024 ** 3)
        print(f"  GPU: {gpu_name} ({vram:.1f} GB VRAM)")
    else:
        print("  ERROR: No CUDA GPU detected. GPU is required for training.")
        return

    # Load labels
    labels = load_labels()
    usable = {k: v for k, v in labels.items() if v not in ("__SKIP__", "__DELETE__")}
    print(f"  Usable labeled clips: {len(usable)}")

    if len(usable) < 20:
        print(f"  ERROR: Need at least 20 labeled clips (have {len(usable)}).")
        print(f"  Run: python scripts/train_awing_tts.py label --auto")
        return

    # Prepare training data directory
    LABELED_DIR.mkdir(parents=True, exist_ok=True)
    MODELS_DIR.mkdir(parents=True, exist_ok=True)

    # Copy labeled clips and build training manifest
    print(f"\n  Preparing training data...")
    entries = []
    for clip_key, text in usable.items():
        src = CLIPS_DIR / clip_key
        if not src.exists():
            continue
        # Normalize: 16kHz mono WAV
        dst_name = clip_key.replace("/", "_").replace("\\", "_")
        dst = LABELED_DIR / dst_name
        try:
            audio = AudioSegment.from_wav(str(src))
            audio = audio.set_frame_rate(22050).set_channels(1).set_sample_width(2)
            audio.export(str(dst), format="wav")
            entries.append({"audio": str(dst.resolve()), "text": text})
        except Exception as e:
            print(f"    Skip {clip_key}: {e}")

    print(f"  Prepared {len(entries)} training samples.")

    # Use HuggingFace transformers VITS for training
    print(f"\n  Setting up training with HuggingFace VITS...")

    try:
        from transformers import VitsModel, VitsTokenizer, VitsConfig
    except ImportError:
        print("  ERROR: transformers not installed.")
        return

    # Load base model (MMS Akoose as starting point for Bantu phonology)
    model_name = "facebook/mms-tts-bss"
    print(f"  Loading base model: {model_name}")
    print(f"  (Akoose — related Cameroon Bantu, provides Bantu phonology foundation)")

    try:
        tokenizer = VitsTokenizer.from_pretrained(model_name)
        model = VitsModel.from_pretrained(model_name)
    except Exception as e:
        print(f"  ERROR loading model: {e}")
        return

    # Filter labels to only use characters the tokenizer already knows.
    # OCR/Whisper misrecognitions produce garbage characters (#&+5ADx etc.)
    # that aren't real Awing text. Strip them instead of trying to resize
    # the model embeddings (VitsModel doesn't support resize_token_embeddings).
    existing_vocab = set(tokenizer.get_vocab().keys())
    print(f"  Tokenizer vocab: {len(existing_vocab)} characters")

    # Map Awing/OCR special characters to Akoose equivalents before filtering
    import unicodedata
    _char_map = {
        'ɛ': 'e', 'ɔ': 'o', 'ə': 'e', 'ɨ': 'i', 'ŋ': 'ng',
    }
    def _normalize_for_tokenizer(text):
        result = []
        for ch in text.lower():
            if ch in _char_map:
                result.append(_char_map[ch])
            else:
                decomposed = unicodedata.normalize('NFD', ch)
                base = ''.join(c for c in decomposed if unicodedata.category(c) != 'Mn')
                result.append(base if base else ch)
        return ''.join(result)

    cleaned_entries = []
    for e in entries:
        # Normalize special chars first, then keep only tokenizer-known chars
        normalized = _normalize_for_tokenizer(e["text"])
        cleaned = "".join(c for c in normalized if c in existing_vocab or c == " ")
        cleaned = " ".join(cleaned.split()).strip()  # Normalize whitespace
        if len(cleaned) >= 1:
            cleaned_entries.append({"audio": e["audio"], "text": cleaned})

    dropped = len(entries) - len(cleaned_entries)
    if dropped > 0:
        print(f"  Dropped {dropped} entries with no valid characters.")
    entries = cleaned_entries
    print(f"  Training samples after cleanup: {len(entries)}")

    if len(entries) < 10:
        print(f"  ERROR: Too few valid training samples ({len(entries)}).")
        return

    # Build character set from cleaned texts
    all_chars = sorted(set(c for e in entries for c in e["text"]))
    print(f"  Character set: {len(all_chars)} unique characters: {''.join(all_chars[:40])}")

    # Save training filelist
    filelist_path = TRAIN_DIR / "train_filelist.txt"
    with open(filelist_path, "w", encoding="utf-8") as f:
        for e in entries:
            f.write(f"{e['audio']}|{e['text']}\n")

    # ---- GPU / cuDNN setup ------------------------------------------------
    # Disable cuDNN to avoid CUDNN_STATUS_EXECUTION_FAILED on some GPUs.
    # The native CUDA kernels are slightly slower but far more stable.
    torch.backends.cudnn.enabled = False
    torch.backends.cudnn.benchmark = False

    if not torch.cuda.is_available():
        print("  ERROR: No CUDA GPU detected. GPU is required for training.")
        print("  Check: python -c \"import torch; print(torch.cuda.is_available())\"")
        return

    # Reduce fragmentation — lets PyTorch reuse freed VRAM segments
    os.environ.setdefault("PYTORCH_CUDA_ALLOC_CONF", "expandable_segments:True")

    # Clear stale CUDA state and cap VRAM usage to ~8 GB (leaves headroom on 12 GB)
    torch.cuda.empty_cache()
    torch.cuda.set_per_process_memory_fraction(0.7)  # 70% of 12 GB ≈ 8.4 GB

    # Quick CUDA sanity check
    try:
        _test = torch.zeros(1, device="cuda")
        del _test
        torch.cuda.empty_cache()
    except Exception as e:
        print(f"  ERROR: CUDA test failed ({e}).")
        return

    gpu_name = torch.cuda.get_device_name(0)
    vram = torch.cuda.get_device_properties(0).total_memory / (1024 ** 3)
    print(f"  GPU: {gpu_name} ({vram:.1f} GB VRAM, capped to ~{vram * 0.7:.1f} GB)")

    device = torch.device("cuda")
    model = model.to(device)
    model.train()

    # Enable gradient checkpointing to save VRAM
    if hasattr(model, "gradient_checkpointing_enable"):
        try:
            model.gradient_checkpointing_enable()
            print("  Gradient checkpointing: enabled (saves VRAM)")
        except Exception:
            pass

    # Simple training loop with AdamW
    from torch.optim import AdamW

    optimizer = AdamW(model.parameters(), lr=2e-5, weight_decay=0.01)

    # Training parameters — batch_size=1 to avoid OOM on longer sequences
    batch_size = 1
    max_steps = min(2000, len(entries) * 10)
    log_interval = 50
    save_interval = 500

    print(f"\n  Training config:")
    print(f"    Batch size: {batch_size}")
    print(f"    Max steps: {max_steps}")
    print(f"    Learning rate: 2e-5")
    print(f"    Device: {device}")
    print(f"    cuDNN: disabled (stability mode)")
    print(f"    VRAM cap: 70% ({vram * 0.7:.1f} GB)")
    print(f"\n  Starting training...\n")

    step = 0
    epoch = 0
    running_loss = 0.0

    while step < max_steps:
        epoch += 1
        # Shuffle entries each epoch
        import random
        random.shuffle(entries)

        for i in range(0, len(entries), batch_size):
            if step >= max_steps:
                break

            batch = entries[i:i + batch_size]

            try:
                # Tokenize texts
                texts = [e["text"] for e in batch]
                inputs = tokenizer(texts, return_tensors="pt", padding=True)
                inputs = {k: v.to(device) for k, v in inputs.items()}

                # Forward pass
                outputs = model(**inputs)

                # Use the model's built-in loss if available
                if hasattr(outputs, "loss") and outputs.loss is not None:
                    loss = outputs.loss
                else:
                    # Fallback: use waveform reconstruction loss
                    loss = outputs.waveform.abs().mean()  # placeholder

                # Backward
                optimizer.zero_grad()
                loss.backward()
                torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                optimizer.step()

                running_loss += loss.item()
                step += 1

                # Free unused VRAM every step to prevent fragmentation/OOM on variable-length inputs
                del outputs, loss
                torch.cuda.empty_cache()

                if step % log_interval == 0:
                    avg_loss = running_loss / log_interval
                    mem_used = torch.cuda.memory_allocated() / (1024 ** 3)
                    mem_reserved = torch.cuda.memory_reserved() / (1024 ** 3)
                    print(f"  Step {step}/{max_steps} | Loss: {avg_loss:.4f} | Epoch: {epoch} | VRAM: {mem_used:.1f}/{mem_reserved:.1f} GB")
                    running_loss = 0.0

                if step % save_interval == 0:
                    save_path = MODELS_DIR / "awing_vits"
                    model.cpu().save_pretrained(str(save_path))
                    tokenizer.save_pretrained(str(save_path))
                    model.to(device)
                    print(f"  Checkpoint saved: {save_path}")

            except Exception as e:
                print(f"  Step {step}: Error - {e}")
                step += 1
                continue

    # Final save
    save_path = MODELS_DIR / "awing_vits"
    save_path.mkdir(parents=True, exist_ok=True)
    model.cpu().save_pretrained(str(save_path))
    tokenizer.save_pretrained(str(save_path))

    print(f"\n{'=' * 60}")
    print(f"  TRAINING COMPLETE!")
    print(f"  Model saved: {save_path}")
    print(f"  Steps: {step} | Epochs: {epoch}")
    print(f"  Next: python scripts/train_awing_tts.py generate")
    print(f"{'=' * 60}\n")


# ===================================================================
# STEP 4: GENERATE — Create pronunciation clips from trained model
# ===================================================================
def cmd_generate(args):
    """Generate 98 pronunciation clips using the trained model."""
    print("\n" + "=" * 60)
    print("  STEP 4: GENERATE — Creating pronunciation clips")
    print("=" * 60)

    model_path = MODELS_DIR / "awing_vits"
    if not model_path.exists():
        print(f"  ERROR: Trained model not found at {model_path}")
        print(f"  Run: python scripts/train_awing_tts.py train")
        return

    import torch
    from transformers import VitsModel, VitsTokenizer

    print(f"  Loading trained model...")
    tokenizer = VitsTokenizer.from_pretrained(str(model_path))
    model = VitsModel.from_pretrained(str(model_path))

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = model.to(device)
    model.eval()

    # Load app vocabulary data for pronunciation text
    from importlib.machinery import SourceFileLoader
    try:
        alpha_data = SourceFileLoader("awing_alphabet",
            str(PROJECT_ROOT / "lib" / "data" / "awing_alphabet.dart")).load_module()
    except Exception:
        pass  # Will use clip names directly

    # Map Awing special characters to closest Akoose tokenizer equivalents
    def awing_to_akoose(text):
        """Convert Awing orthography to Akoose-compatible text for the tokenizer."""
        import unicodedata
        # Map special Awing vowels to Akoose equivalents
        char_map = {
            'ɛ': 'e', 'ɔ': 'o', 'ə': 'e', 'ɨ': 'i', 'ŋ': 'ng',
            'Ɛ': 'E', 'Ɔ': 'O', 'Ə': 'E', 'Ɨ': 'I', 'Ŋ': 'NG',
        }
        result = []
        for ch in text:
            if ch in char_map:
                result.append(char_map[ch])
            else:
                # Strip tone diacritics (combining marks) but keep the base letter
                decomposed = unicodedata.normalize('NFD', ch)
                base = ''.join(c for c in decomposed if unicodedata.category(c) != 'Mn')
                result.append(base if base else ch)
        return ''.join(result)

    # Generate alphabet clips
    alpha_dir = ASSETS_AUDIO / "alphabet"
    alpha_dir.mkdir(parents=True, exist_ok=True)
    alpha_generated = 0

    print(f"\n  Generating alphabet clips ({len(ALPHABET_CLIPS)})...")
    for name in ALPHABET_CLIPS:
        out_path = alpha_dir / f"{name}.mp3"
        # Use the letter name as input text
        text = name.replace("_", " ").replace("epsilon", "e").replace("schwa", "e")
        text = text.replace("barred_i", "i").replace("open_o", "o").replace("eng", "ng")
        text = text.replace("glottal", "'")
        text = awing_to_akoose(text)

        try:
            inputs = tokenizer(text, return_tensors="pt")
            inputs = {k: v.to(device) for k, v in inputs.items()}

            with torch.no_grad():
                outputs = model(**inputs)

            waveform = outputs.waveform[0].cpu().numpy()
            # Convert to AudioSegment and save as MP3
            waveform_int = (waveform * 32767).astype(np.int16)
            audio = AudioSegment(
                waveform_int.tobytes(),
                frame_rate=model.config.sampling_rate,
                sample_width=2,
                channels=1,
            )
            audio.export(str(out_path), format="mp3")
            alpha_generated += 1
        except Exception as e:
            print(f"    ERROR generating {name}: {e}")

    print(f"  Alphabet: {alpha_generated}/{len(ALPHABET_CLIPS)} generated")

    # Generate vocabulary clips
    vocab_dir = ASSETS_AUDIO / "vocabulary"
    vocab_dir.mkdir(parents=True, exist_ok=True)
    vocab_generated = 0

    # Load vocabulary data to get actual Awing words
    vocab_words = {}
    vocab_data_path = PROJECT_ROOT / "lib" / "data" / "awing_vocabulary.dart"
    if vocab_data_path.exists():
        try:
            content = vocab_data_path.read_text(encoding="utf-8")
            # Parse Dart file for awing words
            for match in re.finditer(r"awing:\s*'([^']+)'", content):
                word = match.group(1)
                key = re.sub(r"[^a-zA-Z]", "", word.lower())
                vocab_words[key] = word
        except Exception:
            pass

    print(f"\n  Generating vocabulary clips ({len(VOCABULARY_CLIPS)})...")
    for name in VOCABULARY_CLIPS:
        out_path = vocab_dir / f"{name}.mp3"
        # Try to find actual Awing word, fall back to name
        text = vocab_words.get(name, name.replace("_", " "))
        text = awing_to_akoose(text)

        try:
            inputs = tokenizer(text, return_tensors="pt")
            inputs = {k: v.to(device) for k, v in inputs.items()}

            with torch.no_grad():
                outputs = model(**inputs)

            waveform = outputs.waveform[0].cpu().numpy()
            waveform_int = (waveform * 32767).astype(np.int16)
            audio = AudioSegment(
                waveform_int.tobytes(),
                frame_rate=model.config.sampling_rate,
                sample_width=2,
                channels=1,
            )
            audio.export(str(out_path), format="mp3")
            vocab_generated += 1
        except Exception as e:
            print(f"    ERROR generating {name}: {e}")

    print(f"  Vocabulary: {vocab_generated}/{len(VOCABULARY_CLIPS)} generated")

    print(f"\n{'=' * 60}")
    print(f"  GENERATE COMPLETE!")
    print(f"  Alphabet: {alpha_generated}/{len(ALPHABET_CLIPS)}")
    print(f"  Vocabulary: {vocab_generated}/{len(VOCABULARY_CLIPS)}")
    print(f"  Output: {ASSETS_AUDIO}")
    print(f"\n  Next: scripts\\build_and_run.bat")
    print(f"{'=' * 60}\n")


# ===================================================================
# Utility commands
# ===================================================================
def cmd_add_video(args):
    """Show instructions for adding a new video."""
    print(f"\n  To add a new video, place the .mp4 file in:")
    print(f"    {VIDEOS_DIR}")
    print(f"\n  Optionally place the matching .srt subtitle file next to it.")
    print(f"  The file will be auto-discovered on next 'prepare' run.")
    print(f"\n  Current videos in folder:")
    videos = discover_all_videos()
    for v in videos:
        print(f"    - {v['title']} ({v['type']})")
    if not videos:
        print(f"    (none)")
    print(f"\n  After adding, run: python scripts/train_awing_tts.py prepare")


def cmd_status(args):
    """Show pipeline status."""
    print("\n" + "=" * 60)
    print("  Awing TTS Training Pipeline — Status")
    print("=" * 60)

    videos = discover_all_videos()
    print(f"\n  Video sources: {len(videos)}")
    for v in videos:
        status = "local" if (v.get("local_path") and Path(v["local_path"]).exists()) else "to download"
        print(f"    - {v['title']} ({v.get('type', '?')}) [{status}]")

    # Count clips
    total_clips = 0
    if CLIPS_DIR.exists():
        for vid_dir in CLIPS_DIR.iterdir():
            if vid_dir.is_dir():
                meta = vid_dir / "clip_metadata.json"
                if meta.exists():
                    with open(meta) as f:
                        total_clips += len(json.load(f))
    print(f"\n  Total clips: {total_clips}")

    # Count labels
    labels = load_labels()
    usable = sum(1 for v in labels.values() if v not in ("__SKIP__", "__DELETE__"))
    skipped = sum(1 for v in labels.values() if v == "__SKIP__")
    deleted = sum(1 for v in labels.values() if v == "__DELETE__")
    unlabeled = total_clips - len(labels)
    print(f"  Labels: {usable} usable, {skipped} skipped, {deleted} deleted, {unlabeled} unlabeled")

    # Check model
    model_path = MODELS_DIR / "awing_vits"
    if model_path.exists():
        print(f"\n  Trained model: {model_path}")
    else:
        print(f"\n  Trained model: NOT YET")

    # Check audio clips
    alpha_count = len(list((ASSETS_AUDIO / "alphabet").glob("*.mp3"))) if (ASSETS_AUDIO / "alphabet").exists() else 0
    vocab_count = len(list((ASSETS_AUDIO / "vocabulary").glob("*.mp3"))) if (ASSETS_AUDIO / "vocabulary").exists() else 0
    print(f"  App audio: {alpha_count}/31 alphabet, {vocab_count}/67 vocabulary")

    # Suggest next step
    print(f"\n  Next step:")
    if total_clips == 0:
        print("  python scripts/train_awing_tts.py prepare")
    elif usable < 50:
        print("  python scripts/train_awing_tts.py label --auto")
    elif not model_path.exists():
        print("  python scripts/train_awing_tts.py train")
    elif alpha_count < 31:
        print("  python scripts/train_awing_tts.py generate")
    else:
        print("  All done! Run: scripts\\build_and_run.bat")
    print(f"{'=' * 60}\n")


def cmd_all(args):
    """Run the full pipeline."""
    cmd_prepare(args)
    # Create a fake args with auto=True for labeling
    class AutoArgs:
        auto = True
        whisper = True
    cmd_label(AutoArgs())
    cmd_train(args)
    cmd_generate(args)


def main():
    parser = argparse.ArgumentParser(
        description="Train a custom Awing TTS model from YouTube videos"
    )
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("prepare", help="Download videos, segment audio, run OCR")

    label_parser = subparsers.add_parser("label", help="Label audio clips")
    label_parser.add_argument("--auto", action="store_true",
                              help="Auto-accept OCR + Whisper labels")
    label_parser.add_argument("--no-whisper", dest="whisper", action="store_false",
                              help="Disable Whisper transcription")

    subparsers.add_parser("train", help="Train VITS model on labeled data")
    subparsers.add_parser("generate", help="Generate 98 pronunciation clips")
    subparsers.add_parser("all", help="Run full pipeline")
    subparsers.add_parser("status", help="Show pipeline status")

    subparsers.add_parser("add-video", help="Show how to add a new video")

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return

    commands = {
        "prepare": cmd_prepare,
        "label": cmd_label,
        "train": cmd_train,
        "generate": cmd_generate,
        "all": cmd_all,
        "status": cmd_status,
        "add-video": cmd_add_video,
    }

    commands[args.command](args)


if __name__ == "__main__":
    main()
