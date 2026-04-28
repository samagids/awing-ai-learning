#!/usr/bin/env python3
"""Forced-align Awing Bible chapter audio to verse-level training clips.

Output is LJSpeech-format (wav/ + metadata.csv), the de-facto standard
input for almost every TTS / ASR training framework — Coqui XTTS,
Coqui VITS, ESPnet, NeMo, Whisper fine-tune, MMS-ASR fine-tune. The
output of THIS script is the foundation that downstream task-specific
trainers consume; it is not tied to any one architecture.

Input:
  corpus/raw/bible/azocab/{BOOK}/{NNN}.mp3         chapter audio (dramatized)
  corpus/raw/bible/azocab/{BOOK}/{NNN}.verses.json ordered verse records
  corpus/raw/bible/azocab/_split.json              {book: "train"|"eval"}

Output:
  corpus/aligned/piper/
    train/
      wav/{BOOK}_{chap:03d}_{verse:03d}.wav   22050Hz mono PCM16
      metadata.csv                            LJSpeech: "id|text" per line
    eval/
      wav/...
      metadata.csv
    _state.json                               per-chapter status for resume
    _stats.json                               alignment quality stats

Method:
  1. Load chapter mp3, resample to 16kHz for alignment model.
  2. Normalize each verse's Awing text to MMS_FA's tokenizer charset
     (strip tone diacritics, map ɛ→e, ɔ→o, ə→e, ɨ→i, ŋ→ng, etc.).
  3. Concatenate normalized verses into one transcript, tracking which
     word index belongs to which verse.
  4. Run torchaudio.pipelines.MMS_FA forced alignment (CTC-based, trained
     on 23k hours across 1100+ languages).
  5. For each verse, derive a (start_s, end_s) window from the first and
     last word timings in that verse, add a small pad, extract the audio
     segment at 22050Hz mono PCM16, save.
  6. metadata.csv gets the ORIGINAL Awing verse text — the Piper model
     learns to map Awing characters to audio, not our simplified form.

Usage:
  python scripts/ml/forced_align.py status
  python scripts/ml/forced_align.py prep --book MAT --chapters 1   # smoke test
  python scripts/ml/forced_align.py prep --book MAT                # one book
  python scripts/ml/forced_align.py prep                           # full NT
  python scripts/ml/forced_align.py stats                          # alignment quality

GPU is strongly recommended. On CPU this script runs ~20-30x real time,
which is hours for one chapter. On a modest GPU (~6GB VRAM) it's faster
than real time, so the full 260-chapter run is roughly an hour.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import time
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# Tell PyTorch's CUDA allocator to use expandable memory segments. With
# fixed-size segments, fragmentation from variable-length chapter audio
# (20 sec to 20 min per chapter) causes OOMs even when plenty of VRAM
# is nominally free. This is PyTorch's documented remedy; it's harmless
# on CPU-only runs. Must be set BEFORE torch is imported.
# Use HARD set (not setdefault): any pre-existing value was likely from
# a previous shell session where we hadn't configured this yet.
os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"

# Heavy imports (torch, torchaudio) are deferred to inside functions that
# need them so `status` and `stats` subcommands can run without a GPU env.


# ------------------------------------------------------------------ paths

def _repo_root() -> Path:
    p = Path(__file__).resolve().parent
    for _ in range(6):
        if (p / "lib").is_dir() and (p / "scripts").is_dir():
            return p
        p = p.parent
    return Path.cwd()


ROOT = _repo_root()
BIBLE_RAW = ROOT / "corpus" / "raw" / "bible" / "azocab"
OUT_ROOT = ROOT / "corpus" / "aligned" / "piper"
TRAIN_DIR = OUT_ROOT / "train"
EVAL_DIR = OUT_ROOT / "eval"
STATE_PATH = OUT_ROOT / "_state.json"
STATS_PATH = OUT_ROOT / "_stats.json"
SPLIT_PATH = BIBLE_RAW / "_split.json"


# ------------------------------------------------------------------ config

# Target output sample rate (Piper trains at 22050Hz by default).
TARGET_SR = 22050

# MMS_FA operates on 16kHz mono. We resample once for alignment.
ALIGN_SR = 16000

# Audio padding around each verse's aligned start/end, in seconds.
# MMS's word timings land on word onsets/offsets; a little slack keeps
# leading/trailing silence natural and hedges against small mis-alignment.
PAD_START_S = 0.12
PAD_END_S = 0.25

# Reject extracted clips outside this range. Too-short clips are likely
# alignment failures; too-long ones likely merged two verses. Both hurt
# training more than they help.
MIN_CLIP_S = 0.8
MAX_CLIP_S = 20.0


# ------------------------------------------------------------------ text norm

# MMS_FA's tokenizer expects a limited ASCII charset: a-z + space +
# regular apostrophe. Anything else KeyErrors it. We normalize Awing
# text to that space so alignment works; the ORIGINAL Awing text goes
# into metadata.csv so the Piper fine-tune learns the real characters
# from examples.
_AWING_TO_ASCII = {
    # Special Awing vowels → closest Latin approximation
    "ɛ": "e", "ɔ": "o", "ə": "e", "ɨ": "i",
    # Velar nasal ŋ → "ng"
    "ŋ": "ng",
}

# All the apostrophe-like characters we've seen in real Awing text.
# These get collapsed to the single ASCII apostrophe that MMS_FA
# actually tolerates.
_APOS_VARIANTS = (
    "\u2019",   # ’   right single quote (curly)
    "\u2018",   # ‘   left single quote
    "\u02bc",   # ʼ   modifier letter apostrophe  <-- glottal stop in azocab
    "\u02be",   # ʾ   modifier letter right half ring
    "\u02bf",   # ʿ   modifier letter left half ring
    "\u2032",   # ′   prime
    "`",        # grave accent sometimes used as quote
)


def normalize_for_alignment(text: str) -> str:
    """Produce an MMS_FA-tokenizable lowercase string.

    Pipeline:
      1. lowercase
      2. apply Awing→ASCII char map (ɛɔəɨŋ)
      3. NFD decompose, drop combining marks (tone diacritics)
      4. unify all apostrophe variants to ASCII '
      5. drop *anything* not in [a-z' ] as a safety net so the
         tokenizer never sees an unknown codepoint
    """
    s = text.lower()
    for src, dst in _AWING_TO_ASCII.items():
        s = s.replace(src, dst)
    # Unicode NFD: split pre-composed glyphs (á, ě, ô...) into base + combining
    s = unicodedata.normalize("NFD", s)
    # Drop all combining marks (tone diacritics, etc.)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    # Unify apostrophe variants
    for apos in _APOS_VARIANTS:
        s = s.replace(apos, "'")
    # Hard filter: keep ONLY what MMS_FA's tokenizer accepts.
    # Everything else becomes a space.
    s = re.sub(r"[^a-z' ]+", " ", s)
    # Collapse repeated whitespace
    s = re.sub(r"\s+", " ", s).strip()
    return s


# ------------------------------------------------------------------ state

@dataclass
class AlignStats:
    verse_count: int = 0
    clips_saved: int = 0
    clips_rejected_short: int = 0
    clips_rejected_long: int = 0
    clips_rejected_align_fail: int = 0
    chapter_duration_s: float = 0.0
    total_clip_duration_s: float = 0.0
    alignment_score_sum: float = 0.0


@dataclass
class State:
    # {BOOK: {chap_str: "done"|"error"|"missing"}}
    chapters: dict[str, dict[str, str]] = field(default_factory=dict)
    # {BOOK/NNN: AlignStats-as-dict}
    stats: dict[str, dict[str, Any]] = field(default_factory=dict)

    def status(self, book: str, chap: int) -> str:
        return self.chapters.get(book, {}).get(str(chap), "pending")

    def set_status(self, book: str, chap: int, status: str) -> None:
        self.chapters.setdefault(book, {})[str(chap)] = status

    def set_stats(self, book: str, chap: int, s: AlignStats) -> None:
        self.stats[f"{book}/{chap:03d}"] = s.__dict__.copy()

    def save(self) -> None:
        STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
        STATE_PATH.write_text(
            json.dumps({"chapters": self.chapters}, indent=2, sort_keys=True),
            encoding="utf-8",
        )
        STATS_PATH.write_text(
            json.dumps(self.stats, indent=2, sort_keys=True),
            encoding="utf-8",
        )

    @classmethod
    def load(cls) -> "State":
        st = cls()
        if STATE_PATH.exists():
            try:
                d = json.loads(STATE_PATH.read_text(encoding="utf-8"))
                st.chapters = d.get("chapters", {})
            except (OSError, json.JSONDecodeError):
                pass
        if STATS_PATH.exists():
            try:
                st.stats = json.loads(STATS_PATH.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                pass
        return st


def load_split() -> dict[str, str]:
    """Load the train/eval book assignment produced by youversion.py."""
    if not SPLIT_PATH.exists():
        raise FileNotFoundError(
            f"Missing {SPLIT_PATH}. Run `python scripts/ingest/youversion.py plan` "
            f"to create it, or re-run the NT fetch."
        )
    return json.loads(SPLIT_PATH.read_text(encoding="utf-8"))


# ------------------------------------------------------------------ alignment

def _lazy_import_torch():
    """Import torch/torchaudio lazily so status/stats work without them.

    We use `soundfile` for audio I/O (MP3 in, WAV out) because:
    - torch 2.11's torchaudio.load now requires torchcodec + an ffmpeg
      "full-shared" build, which is fragile to set up on Windows.
    - soundfile has pre-built Windows wheels with libsndfile 1.2+
      that handles MP3 decoding natively.
    torchaudio's resample + MMS_FA pipeline tensor ops still work fine.
    """
    import torch
    import torchaudio
    from torchaudio.pipelines import MMS_FA as BUNDLE
    try:
        import soundfile  # noqa: F401
    except ImportError:
        raise SystemExit(
            "\nERROR: 'soundfile' is required for audio I/O but not installed.\n"
            "Fix:   pip install soundfile\n"
            "(This avoids the torchcodec + ffmpeg DLL setup that torchaudio.load\n"
            " now requires in torch 2.11+.)"
        )
    return torch, torchaudio, BUNDLE


def _load_audio(path: Path, target_sr: int, torch_mod, torchaudio_mod):
    """Load an MP3/WAV via soundfile, resample to target_sr via torchaudio.

    Returns a (1, n_samples) float32 tensor + the target sample rate.
    """
    import soundfile as sf
    data, sr = sf.read(str(path), dtype="float32", always_2d=False)
    if data.ndim > 1:
        data = data.mean(axis=1)  # downmix to mono
    tensor = torch_mod.from_numpy(data).unsqueeze(0)
    if sr != target_sr:
        tensor = torchaudio_mod.functional.resample(tensor, sr, target_sr)
    return tensor, target_sr


def _save_wav(path: Path, tensor, sample_rate: int, bits_per_sample: int = 16) -> None:
    """Save a (1, n) or (n,) float tensor as PCM WAV via soundfile.

    Avoids torchaudio.save's dependency on torchcodec/ffmpeg.
    """
    import soundfile as sf
    arr = tensor.squeeze(0).detach().cpu().numpy() if hasattr(tensor, "squeeze") else tensor
    if arr.ndim > 1:
        arr = arr.squeeze()
    subtype = {
        16: "PCM_16",
        24: "PCM_24",
        32: "PCM_32",
    }.get(bits_per_sample, "PCM_16")
    sf.write(str(path), arr, sample_rate, subtype=subtype)


def align_chapter(
    audio_path: Path,
    verses: list[dict[str, Any]],
    device: str,
    bundle,
    torch_mod,
    torchaudio_mod,
) -> tuple[list[dict[str, Any]], AlignStats]:
    """Forced-align one chapter and return per-verse time windows.

    Returns (list of {usfm, verse, text_awing, start_s, end_s, align_score},
             AlignStats).
    """
    stats = AlignStats(verse_count=len(verses))

    # Load + resample to the alignment model's rate. Use soundfile to
    # avoid torchaudio.load's torchcodec+ffmpeg dependency chain.
    waveform, _ = _load_audio(audio_path, ALIGN_SR, torch_mod, torchaudio_mod)
    stats.chapter_duration_s = waveform.shape[1] / ALIGN_SR
    waveform = waveform.to(device)

    # Build transcript: list of normalized words, and a parallel array
    # mapping each word index to its source verse index.
    model = bundle.get_model().to(device).eval()
    tokenizer = bundle.get_tokenizer()
    aligner = bundle.get_aligner()

    words: list[str] = []
    word_to_verse: list[int] = []
    for vi, v in enumerate(verses):
        norm = normalize_for_alignment(v.get("text", ""))
        if not norm:
            continue
        for w in norm.split():
            words.append(w)
            word_to_verse.append(vi)

    if not words:
        stats.clips_rejected_align_fail = len(verses)
        return [], stats

    # Emissions + alignment
    with torch_mod.inference_mode():
        emissions, _ = model(waveform)
    try:
        token_spans = aligner(emissions[0], tokenizer(words))
    except Exception as e:
        # Rare: the model errors on some pathological input. Mark whole
        # chapter as align-fail and let the caller decide what to do.
        print(f"    alignment error: {e}")
        stats.clips_rejected_align_fail = len(verses)
        return [], stats

    # Each entry in token_spans corresponds to one word in `words`; each
    # span has .start and .end in model frames. Convert to seconds.
    ratio = waveform.shape[1] / emissions.shape[1] / ALIGN_SR
    word_times: list[tuple[float, float, float]] = []  # (start_s, end_s, score)
    for spans in token_spans:
        if not spans:
            word_times.append((0.0, 0.0, 0.0))
            continue
        start_frame = spans[0].start
        end_frame = spans[-1].end
        # Average confidence across the spans that make up this word
        score = sum(s.score for s in spans) / max(1, len(spans))
        word_times.append((start_frame * ratio, end_frame * ratio, score))

    # We've extracted all the timing info we need from the GPU tensors;
    # drop them now so the next chapter starts with a clean VRAM slate.
    # Keeping these references alive through extract_clips was one of
    # the suspected accumulation paths in the Blackwell crash.
    del emissions, waveform, token_spans
    if device == "cuda":
        torch_mod.cuda.empty_cache()

    # Aggregate back to verse-level windows.
    windows: list[dict[str, Any]] = []
    for vi, v in enumerate(verses):
        idxs = [i for i, vv in enumerate(word_to_verse) if vv == vi]
        if not idxs:
            continue
        starts = [word_times[i][0] for i in idxs]
        ends = [word_times[i][1] for i in idxs]
        scores = [word_times[i][2] for i in idxs]
        s_s = max(0.0, min(starts) - PAD_START_S)
        e_s = min(stats.chapter_duration_s, max(ends) + PAD_END_S)
        score = sum(scores) / max(1, len(scores))
        windows.append({
            "usfm": v["usfm"],
            "verse": v["verse"],
            "text_awing": v["text"],
            "start_s": s_s,
            "end_s": e_s,
            "align_score": score,
        })
        stats.alignment_score_sum += score

    return windows, stats


def extract_clips(
    audio_path: Path,
    windows: list[dict[str, Any]],
    out_wav_dir: Path,
    book: str,
    chap: int,
    stats: AlignStats,
    torch_mod,
    torchaudio_mod,
) -> list[tuple[str, str]]:
    """Slice chapter audio at each verse window, write 22050Hz mono PCM16.

    Returns list of (clip_id, awing_text) for metadata.csv.
    """
    # Reload source at target SR so our outputs are native-rate.
    waveform, _ = _load_audio(audio_path, TARGET_SR, torch_mod, torchaudio_mod)

    out_wav_dir.mkdir(parents=True, exist_ok=True)
    rows: list[tuple[str, str]] = []
    for w in windows:
        dur = w["end_s"] - w["start_s"]
        if dur < MIN_CLIP_S:
            stats.clips_rejected_short += 1
            continue
        if dur > MAX_CLIP_S:
            stats.clips_rejected_long += 1
            continue
        start_i = int(w["start_s"] * TARGET_SR)
        end_i = int(w["end_s"] * TARGET_SR)
        clip = waveform[:, start_i:end_i]
        if clip.shape[1] < int(MIN_CLIP_S * TARGET_SR):
            stats.clips_rejected_short += 1
            continue
        clip_id = f"{book}_{chap:03d}_{w['verse']:03d}"
        out_path = out_wav_dir / f"{clip_id}.wav"
        # Save as int16 PCM, which is what Piper's preprocessor expects.
        # Use soundfile to avoid torchaudio.save's codec dependency.
        _save_wav(out_path, clip, TARGET_SR, bits_per_sample=16)
        rows.append((clip_id, w["text_awing"]))
        stats.clips_saved += 1
        stats.total_clip_duration_s += clip.shape[1] / TARGET_SR
    return rows


def append_metadata(metadata_path: Path, rows: list[tuple[str, str]]) -> None:
    """Append rows to metadata.csv in LJSpeech format (id|text, pipe-separated)."""
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    # Open in append-text mode. LJSpeech uses '|' as delimiter.
    with open(metadata_path, "a", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, delimiter="|", quoting=csv.QUOTE_MINIMAL,
                            quotechar='"', lineterminator="\n")
        for clip_id, text in rows:
            # Collapse internal newlines and tabs to a single space so
            # each row is one line.
            clean = re.sub(r"\s+", " ", text).strip()
            writer.writerow([clip_id, clean])


# ------------------------------------------------------------------ commands

def cmd_status(_args: argparse.Namespace) -> int:
    st = State.load()
    if not BIBLE_RAW.exists():
        print("No scraped Bible data yet; run scripts/ingest/youversion.py fetch first.")
        return 0
    done = error = missing = 0
    total = 0
    books_present = 0
    for book_dir in sorted(p for p in BIBLE_RAW.iterdir() if p.is_dir()):
        book = book_dir.name
        mp3_count = len(list(book_dir.glob("*.mp3")))
        if not mp3_count:
            continue
        books_present += 1
        for mp3 in sorted(book_dir.glob("*.mp3")):
            try:
                chap = int(mp3.stem)
            except ValueError:
                continue
            total += 1
            s = st.status(book, chap)
            if s == "done":
                done += 1
            elif s == "error":
                error += 1
            elif s == "missing":
                missing += 1
    pending = total - done - error - missing
    print(f"Scraped chapters:     {total}  (across {books_present} books)")
    print(f"Aligned + extracted:  {done}  ({100*done/max(1,total):.1f}%)")
    print(f"Errors:               {error}")
    print(f"Missing (no verses):  {missing}")
    print(f"Pending:              {pending}")
    if OUT_ROOT.exists():
        for split in ("train", "eval"):
            mdp = OUT_ROOT / split / "metadata.csv"
            if mdp.exists():
                n = sum(1 for _ in mdp.open(encoding="utf-8"))
                wav_n = len(list((OUT_ROOT / split / "wav").glob("*.wav"))) \
                    if (OUT_ROOT / split / "wav").exists() else 0
                print(f"  {split:5s}: {n} metadata rows, {wav_n} wav files")
    return 0


def cmd_stats(_args: argparse.Namespace) -> int:
    st = State.load()
    if not st.stats:
        print("No stats recorded yet; run `prep` first.")
        return 0
    # Aggregate
    totals = AlignStats()
    low_score_chapters = []
    for key, s in st.stats.items():
        totals.verse_count += s.get("verse_count", 0)
        totals.clips_saved += s.get("clips_saved", 0)
        totals.clips_rejected_short += s.get("clips_rejected_short", 0)
        totals.clips_rejected_long += s.get("clips_rejected_long", 0)
        totals.clips_rejected_align_fail += s.get("clips_rejected_align_fail", 0)
        totals.chapter_duration_s += s.get("chapter_duration_s", 0)
        totals.total_clip_duration_s += s.get("total_clip_duration_s", 0)
        totals.alignment_score_sum += s.get("alignment_score_sum", 0)
        vc = s.get("verse_count", 0)
        if vc:
            avg = s.get("alignment_score_sum", 0) / vc
            if avg < 0.5:
                low_score_chapters.append((key, avg))
    avg_score = (totals.alignment_score_sum /
                 max(1, totals.verse_count))
    print(f"Chapters processed:      {len(st.stats)}")
    print(f"Verses in:               {totals.verse_count}")
    print(f"Clips saved:             {totals.clips_saved}  "
          f"({100 * totals.clips_saved / max(1,totals.verse_count):.1f}%)")
    print(f"Rejected (too short):    {totals.clips_rejected_short}")
    print(f"Rejected (too long):     {totals.clips_rejected_long}")
    print(f"Rejected (align fail):   {totals.clips_rejected_align_fail}")
    print(f"Source audio hours:      {totals.chapter_duration_s/3600:.2f}")
    print(f"Extracted clip hours:    {totals.total_clip_duration_s/3600:.2f}  "
          f"({100 * totals.total_clip_duration_s / max(1,totals.chapter_duration_s):.1f}% of source)")
    print(f"Mean alignment score:    {avg_score:.3f}  (1.0 = perfect)")
    if low_score_chapters:
        print()
        print("Chapters with mean score < 0.5 (likely alignment issues):")
        for k, s in sorted(low_score_chapters, key=lambda x: x[1]):
            print(f"  {k}  score={s:.3f}")
    return 0


def cmd_prep(args: argparse.Namespace) -> int:
    if not BIBLE_RAW.exists():
        print(f"Missing {BIBLE_RAW}. Nothing to align.")
        return 1

    split = load_split()
    state = State.load()

    # Lazy import: only the prep command needs torch.
    print("Loading torch + MMS_FA bundle...")
    torch_mod, torchaudio_mod, BUNDLE = _lazy_import_torch()

    # Defensive settings — Blackwell + cu128 + PyTorch 2.11 is a fresh
    # stack and sustained GPU inference has been reported to trigger
    # driver resets / full PC crashes. These mitigations are what
    # Session 15/16 found stable for TTS training on the same GPU.
    device = "cuda" if torch_mod.cuda.is_available() else "cpu"
    print(f"Device: {device}")
    if device == "cuda":
        # Cap VRAM so the OS/display has headroom, but keep enough room
        # for long chapters (~3 GB emissions tensor). 85% of 12 GB is
        # ~10.1 GB — model uses ~1.2 GB, leaving ~9 GB for tensors.
        # With expandable_segments (set as env var at module load),
        # fragmentation no longer eats into that headroom.
        try:
            torch_mod.cuda.set_per_process_memory_fraction(0.85, 0)
            print("  VRAM cap: 85% of device")
        except Exception as e:
            print(f"  WARNING: could not set VRAM fraction: {e}")
        # cuDNN caching under long-running inference was implicated in
        # Session 15/16 training crashes on the same GPU class.
        torch_mod.backends.cudnn.benchmark = False
        print("  cuDNN benchmark: disabled (stability over throughput)")
        # Confirm the alloc conf env var took effect.
        alloc_conf = os.environ.get("PYTORCH_CUDA_ALLOC_CONF", "(unset)")
        print(f"  PYTORCH_CUDA_ALLOC_CONF: {alloc_conf}")
    if device == "cpu":
        print("WARNING: running on CPU — expect many hours. GPU strongly recommended.")

    # The bundle downloads model weights on first use. ~1.2GB.
    bundle = BUNDLE
    # Touch these so the first chapter isn't paying the download cost.
    _ = bundle.get_model()
    _ = bundle.get_tokenizer()
    _ = bundle.get_aligner()

    # Determine which chapters to do.
    target_books: list[str] = []
    if args.book:
        target_books = [args.book]
    else:
        target_books = sorted(p.name for p in BIBLE_RAW.iterdir()
                              if p.is_dir() and any(p.glob("*.mp3")))

    for book in target_books:
        book_dir = BIBLE_RAW / book
        if not book_dir.is_dir():
            continue
        split_name = split.get(book, "train")  # safe default
        out_dir = TRAIN_DIR if split_name == "train" else EVAL_DIR
        wav_dir = out_dir / "wav"
        metadata_path = out_dir / "metadata.csv"

        chaps = sorted(int(p.stem) for p in book_dir.glob("*.mp3"))
        if args.chapters:
            wanted = {int(c) for c in args.chapters.split(",")}
            chaps = [c for c in chaps if c in wanted]

        print(f"\n== {book} ({split_name}) — {len(chaps)} chapter(s) ==")
        for chap in chaps:
            if state.status(book, chap) == "done" and not args.force:
                print(f"  [{book} {chap:3d}] already done — skipping")
                continue
            mp3 = book_dir / f"{chap:03d}.mp3"
            vjson = book_dir / f"{chap:03d}.verses.json"
            if not mp3.exists() or not vjson.exists():
                print(f"  [{book} {chap:3d}] missing files — skipping")
                state.set_status(book, chap, "missing")
                state.save()
                continue

            try:
                verses = json.loads(vjson.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                print(f"  [{book} {chap:3d}] corrupt verses.json — skipping")
                state.set_status(book, chap, "error")
                state.save()
                continue

            print(f"  [{book} {chap:3d}] aligning {len(verses)} verses...")
            t0 = time.time()
            try:
                windows, stats = align_chapter(
                    mp3, verses, device, bundle, torch_mod, torchaudio_mod,
                )
            except torch_mod.cuda.OutOfMemoryError as e:
                # GPU ran out of VRAM. Fall back to CPU for JUST this
                # chapter — slower (~30-60s instead of ~6s) but always
                # fits. Model moves back to GPU afterward.
                print(f"    GPU OOM; retrying on CPU (slower). "
                      f"{str(e).splitlines()[0][:80]}")
                torch_mod.cuda.empty_cache()
                torch_mod.cuda.synchronize()
                try:
                    model = bundle.get_model()
                    model.to("cpu")
                    windows, stats = align_chapter(
                        mp3, verses, "cpu", bundle, torch_mod, torchaudio_mod,
                    )
                except Exception as e2:
                    print(f"    CPU fallback also failed: {e2}")
                    state.set_status(book, chap, "error")
                    state.save()
                    # Restore model to GPU before next chapter
                    try:
                        bundle.get_model().to(device)
                    except Exception:
                        pass
                    continue
                finally:
                    # Always try to return model to GPU for subsequent chapters
                    try:
                        bundle.get_model().to(device)
                        torch_mod.cuda.empty_cache()
                    except Exception:
                        pass
            except Exception as e:
                print(f"    ERROR: {e}")
                state.set_status(book, chap, "error")
                state.save()
                continue

            rows = extract_clips(
                mp3, windows, wav_dir, book, chap, stats,
                torch_mod, torchaudio_mod,
            )
            append_metadata(metadata_path, rows)

            dt = time.time() - t0
            avg_score = (stats.alignment_score_sum /
                         max(1, stats.verse_count))
            print(f"    saved {stats.clips_saved}/{stats.verse_count}  "
                  f"rejected(short={stats.clips_rejected_short}, "
                  f"long={stats.clips_rejected_long})  "
                  f"score={avg_score:.3f}  elapsed={dt:.1f}s")

            state.set_stats(book, chap, stats)
            # "done" only means we got clips out. A chapter with zero
            # extracted clips is a failure that should re-run on retry.
            final_status = "done" if stats.clips_saved > 0 else "error"
            state.set_status(book, chap, final_status)
            state.save()

            # Aggressive per-chapter cleanup. Suspected fix for the
            # driver-reset crash on Blackwell under long runs.
            try:
                del windows, rows
            except NameError:
                pass
            import gc
            gc.collect()
            if device == "cuda":
                torch_mod.cuda.empty_cache()
                torch_mod.cuda.synchronize()

    print("\n-- done --")
    cmd_status(argparse.Namespace())
    return 0


# ------------------------------------------------------------------ main

def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    sub.add_parser("status", help="Show how many chapters are aligned")
    sub.add_parser("stats", help="Alignment quality + clip stats")

    p = sub.add_parser("prep", help="Align + extract verse clips (GPU recommended)")
    p.add_argument("--book", help="Limit to one book (e.g. MAT)")
    p.add_argument("--chapters", help="Comma-separated chapters within a book")
    p.add_argument("--force", action="store_true",
                   help="Re-align chapters already marked done")

    args = ap.parse_args(argv)
    {
        "status": cmd_status,
        "stats": cmd_stats,
        "prep": cmd_prep,
    }[args.cmd](args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
