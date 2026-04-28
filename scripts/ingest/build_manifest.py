#!/usr/bin/env python3
"""Build corpus/manifest.jsonl — the canonical index of all raw Awing data.

Walks a configured set of scan roots (corpus/raw/ by default, plus any
registered legacy paths like videos/ and training_data/recordings/ that
we haven't moved yet), probes each file for size + duration + siblings,
merges any per-file provenance JSON next to it, and writes one JSONL
record per data file.

The manifest is the bridge between "there are files on disk somewhere"
and "downstream pipelines know exactly what exists and where." Every
tool that processes raw data should read corpus/manifest.jsonl rather
than scanning the filesystem itself — that way sources can live
anywhere and move later without breaking tools.

Usage:
  python scripts/ingest/build_manifest.py               # full rebuild
  python scripts/ingest/build_manifest.py --refresh     # only probe new/changed files
  python scripts/ingest/build_manifest.py --dry-run     # print plan, write nothing
  python scripts/ingest/build_manifest.py --stats       # after building, print totals

Design notes:
  - `id` is a sha256 of the relative path. Stable across reruns, independent
    of file content (so re-encoding audio doesn't invalidate the id).
  - `content_hash` is sha256 of the FIRST 1 MiB of the file. Cheap on large
    videos, sufficient for dedup across copies, and we recompute it only
    when size+mtime changed.
  - `duration_seconds` comes from ffprobe. If ffprobe is absent, we record
    None and warn once.
  - Raw files are NEVER modified. This tool is read-only on the data dirs;
    it only writes corpus/manifest.jsonl.
  - Sibling detection: for a video/audio file, we look in the same
    directory for files with the same stem and recognized transcript /
    companion extensions (.srt, .vtt, .wav counterpart for .mp4, etc.).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass, asdict, field
from pathlib import Path
from typing import Any, Iterable


# ------------------------------------------------------------------ config

# Every path here is relative to the repo root (the directory containing
# lib/, scripts/, corpus/, etc.). Order matters only for presentation —
# the manifest is a flat list.
SCAN_ROOTS: list[tuple[str, str]] = [
    # (path, source_type)
    ("corpus/raw/bible",   "bible"),
    ("corpus/raw/grn",     "grn"),
    ("corpus/raw/studio",  "studio"),
    ("corpus/raw/books",   "books"),
    ("corpus/raw/youtube", "youtube"),
    # Legacy locations — data that pre-dates the corpus/ layout. We index
    # it in place rather than move and break existing scripts. Once the
    # legacy consumers retire we can migrate these into corpus/raw/.
    ("videos",                     "youtube_legacy"),
    ("training_data/recordings",   "studio_legacy"),
]

MANIFEST_PATH = "corpus/manifest.jsonl"
STATS_PATH = "corpus/manifest_stats.json"

# File types we care about. Anything else in the scan tree is ignored
# (README.md, .gitkeep, .DS_Store, etc.).
AUDIO_EXTS = {".mp3", ".wav", ".m4a", ".ogg", ".flac", ".opus"}
VIDEO_EXTS = {".mp4", ".mkv", ".webm", ".mov", ".avi"}
TEXT_EXTS  = {".srt", ".vtt", ".txt", ".usfm", ".sfm"}
DOC_EXTS   = {".pdf", ".epub", ".docx"}
DATA_EXTS  = {".json", ".jsonl", ".csv"}

# Files that pair with a parent data file (same stem, different ext).
SIDECAR_TEXT_EXTS = {".srt", ".vtt"}   # subtitles
SIDECAR_DATA_EXTS = {".json"}          # provenance records

# What to skip entirely during the walk.
IGNORE_NAMES = {"README.md", ".gitkeep", ".gitignore", ".DS_Store"}


# ------------------------------------------------------------------ data

@dataclass
class ManifestEntry:
    """One row of corpus/manifest.jsonl."""
    id: str
    path: str                    # relative to repo root, POSIX-style
    source_type: str             # grn | youtube | studio | bible | ...
    format: str                  # mime-ish: audio/mp3, video/mp4, text/srt
    size_bytes: int
    mtime: float
    content_hash: str | None     # sha256 of first 1 MiB; None if unreadable
    duration_seconds: float | None   # audio/video only
    title: str                   # derived from filename or provenance
    stem: str                    # for sibling correlation
    siblings: dict[str, str]     # {"srt": "path", "wav": "path", ...}
    provenance: dict[str, Any]   # merged from *.json sidecar, possibly empty
    discovered_at: float         # epoch seconds


# ------------------------------------------------------------------ helpers

def _repo_root() -> Path:
    """Walk up from this file to find the repo root.

    Repo root has both `lib/` and `scripts/` siblings. This keeps the tool
    runnable from any working directory.
    """
    p = Path(__file__).resolve().parent
    for _ in range(6):
        if (p / "lib").is_dir() and (p / "scripts").is_dir():
            return p
        p = p.parent
    # Fallback: cwd
    return Path.cwd()


_FFPROBE_OK: bool | None = None


def _have_ffprobe() -> bool:
    global _FFPROBE_OK
    if _FFPROBE_OK is None:
        try:
            r = subprocess.run(
                ["ffprobe", "-version"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                timeout=5,
            )
            _FFPROBE_OK = (r.returncode == 0)
        except (FileNotFoundError, subprocess.TimeoutExpired):
            _FFPROBE_OK = False
    return _FFPROBE_OK


def probe_duration(path: Path) -> float | None:
    """Return media duration in seconds via ffprobe, or None if unavailable."""
    if not _have_ffprobe():
        return None
    try:
        r = subprocess.run(
            [
                "ffprobe", "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1",
                str(path),
            ],
            capture_output=True, text=True, timeout=30,
        )
        s = (r.stdout or "").strip()
        if not s:
            return None
        try:
            return float(s)
        except ValueError:
            return None
    except subprocess.TimeoutExpired:
        return None


def first_mib_sha256(path: Path) -> str | None:
    """sha256 of the first 1 MiB of the file. Cheap, sufficient for dedup."""
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            chunk = f.read(1024 * 1024)
            h.update(chunk)
        return h.hexdigest()
    except OSError:
        return None


def path_id(rel_path: str) -> str:
    """Stable 16-hex-char ID from the relative path. Filename changes = new id."""
    return hashlib.sha256(rel_path.encode("utf-8")).hexdigest()[:16]


def classify(path: Path) -> tuple[str, str] | None:
    """Return (category, format) for supported file types, else None.

    category is one of: audio / video / text / doc / data
    format is a mime-ish string like 'audio/mp3', 'video/mp4', 'text/srt'.
    """
    ext = path.suffix.lower()
    if ext in AUDIO_EXTS:
        return "audio", f"audio/{ext.lstrip('.')}"
    if ext in VIDEO_EXTS:
        return "video", f"video/{ext.lstrip('.')}"
    if ext in TEXT_EXTS:
        return "text", f"text/{ext.lstrip('.')}"
    if ext in DOC_EXTS:
        return "doc", f"application/{ext.lstrip('.')}"
    if ext in DATA_EXTS:
        return "data", f"application/{ext.lstrip('.')}"
    return None


def load_provenance_sidecar(path: Path) -> dict[str, Any]:
    """If `path.json` exists next to `path`, load it. Else {}."""
    sidecar = path.with_suffix(path.suffix + ".json")
    if sidecar.exists():
        try:
            return json.loads(sidecar.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {}
    # Also try the "same stem, .json" variant (stem.mp3 → stem.json)
    sidecar2 = path.with_suffix(".json")
    if sidecar2.exists() and sidecar2 != path:
        try:
            return json.loads(sidecar2.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {}
    return {}


def find_siblings(path: Path, category: str) -> dict[str, str]:
    """For a primary data file, find related files in the same directory.

    For a video.mp4, look for video.wav (audio extract), video.srt,
    video_en.srt, video_vi.srt, etc. For an audio.mp3, look for audio.srt
    or audio.vtt.
    """
    if category not in {"audio", "video"}:
        return {}

    siblings: dict[str, str] = {}
    stem = path.stem
    parent = path.parent

    for f in parent.iterdir():
        if not f.is_file():
            continue
        if f == path:
            continue
        if f.stem == stem or f.stem.startswith(stem + "_") or \
                (stem.endswith(")") and f.stem == stem.rsplit(" (", 1)[0]):
            ext = f.suffix.lower()
            if ext in SIDECAR_TEXT_EXTS:
                # Distinguish language-tagged subtitles by suffix
                tag = ext.lstrip(".")
                if "_en" in f.stem:
                    siblings[f"{tag}_en"] = f.name
                elif "_vi" in f.stem:
                    siblings[f"{tag}_vi"] = f.name
                else:
                    siblings[tag] = f.name
            elif ext in AUDIO_EXTS and category == "video":
                siblings["audio"] = f.name
    return siblings


def title_from_filename(path: Path, provenance: dict) -> str:
    """Use provenance.title if set, else a cleaned-up filename."""
    t = provenance.get("title")
    if t:
        return t
    # Filename minus extension, with underscores to spaces
    return path.stem.replace("_", " ").strip()


# ------------------------------------------------------------------ scan

def iter_scan_files(root: Path, source_type: str) -> Iterable[tuple[Path, str]]:
    """Yield (file_path, resolved_source_type) for every file under root."""
    if not root.is_dir():
        return
    for dirpath, dirnames, filenames in os.walk(root):
        # Skip hidden directories
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for name in filenames:
            if name in IGNORE_NAMES:
                continue
            if name.startswith("."):
                continue
            yield Path(dirpath) / name, source_type


def build_entry(
    path: Path,
    source_type: str,
    repo_root: Path,
    cache: dict[str, ManifestEntry],
    refresh: bool,
) -> ManifestEntry | None:
    """Produce one manifest entry. Returns None for unsupported file types."""
    cat_fmt = classify(path)
    if cat_fmt is None:
        return None
    category, fmt = cat_fmt

    try:
        stat = path.stat()
    except OSError:
        return None

    rel = path.relative_to(repo_root).as_posix()
    pid = path_id(rel)
    provenance = load_provenance_sidecar(path)

    # Sidecar provenance files themselves should not appear as separate
    # entries — they're attached to their parent data file. Filter by the
    # same-stem rule: if `{stem}.{ext}.json` exists and current file is
    # that JSON, skip it.
    if path.suffix.lower() == ".json":
        parent_candidates = [
            path.with_suffix(""),                      # foo.mp3.json -> foo.mp3
            path.parent / (path.stem + ".mp3"),
            path.parent / (path.stem + ".wav"),
            path.parent / (path.stem + ".mp4"),
        ]
        if any(p.exists() and p != path for p in parent_candidates):
            return None

    # Incremental update: reuse cached entry if size + mtime unchanged
    if refresh and pid in cache:
        prev = cache[pid]
        if prev.size_bytes == stat.st_size and abs(prev.mtime - stat.st_mtime) < 0.01:
            # Rebuild just siblings + provenance in case those moved
            prev.siblings = find_siblings(path, category)
            prev.provenance = provenance or prev.provenance
            prev.title = title_from_filename(path, provenance or prev.provenance)
            return prev

    siblings = find_siblings(path, category)
    duration = probe_duration(path) if category in {"audio", "video"} else None
    content_hash = first_mib_sha256(path) if category in {"audio", "video", "doc"} else None

    return ManifestEntry(
        id=pid,
        path=rel,
        source_type=source_type,
        format=fmt,
        size_bytes=stat.st_size,
        mtime=stat.st_mtime,
        content_hash=content_hash,
        duration_seconds=duration,
        title=title_from_filename(path, provenance),
        stem=path.stem,
        siblings=siblings,
        provenance=provenance,
        discovered_at=time.time(),
    )


def load_existing(manifest_path: Path) -> dict[str, ManifestEntry]:
    cache: dict[str, ManifestEntry] = {}
    if not manifest_path.exists():
        return cache
    for line in manifest_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
            cache[d["id"]] = ManifestEntry(**d)
        except (json.JSONDecodeError, TypeError, KeyError):
            continue
    return cache


def write_manifest(manifest_path: Path, entries: list[ManifestEntry]) -> None:
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    # Sort for deterministic output
    entries.sort(key=lambda e: (e.source_type, e.path))
    with open(manifest_path, "w", encoding="utf-8") as f:
        for e in entries:
            f.write(json.dumps(asdict(e), ensure_ascii=False) + "\n")


# ------------------------------------------------------------------ stats

def compute_stats(entries: list[ManifestEntry]) -> dict[str, Any]:
    """Summary statistics — what we have, grouped by source."""
    by_source: dict[str, dict[str, Any]] = {}
    total_audio_hours = 0.0
    total_video_hours = 0.0

    for e in entries:
        s = by_source.setdefault(e.source_type, {
            "count": 0, "size_bytes": 0, "audio_seconds": 0.0,
            "video_seconds": 0.0, "text_files": 0, "doc_files": 0,
        })
        s["count"] += 1
        s["size_bytes"] += e.size_bytes
        cat = e.format.split("/", 1)[0]
        if cat == "audio" and e.duration_seconds:
            s["audio_seconds"] += e.duration_seconds
            total_audio_hours += e.duration_seconds / 3600
        elif cat == "video" and e.duration_seconds:
            s["video_seconds"] += e.duration_seconds
            total_video_hours += e.duration_seconds / 3600
        elif cat == "text":
            s["text_files"] += 1
        elif cat == "application":
            s["doc_files"] += 1

    # Round durations
    for s in by_source.values():
        s["audio_hours"] = round(s["audio_seconds"] / 3600, 3)
        s["video_hours"] = round(s["video_seconds"] / 3600, 3)
        s["size_mb"] = round(s["size_bytes"] / (1024 * 1024), 1)

    return {
        "total_files": len(entries),
        "total_audio_hours": round(total_audio_hours, 3),
        "total_video_hours": round(total_video_hours, 3),
        "by_source": by_source,
        "built_at": time.time(),
    }


def print_stats(stats: dict[str, Any]) -> None:
    print()
    print(f"Total files:        {stats['total_files']}")
    print(f"Total audio hours:  {stats['total_audio_hours']:.2f}")
    print(f"Total video hours:  {stats['total_video_hours']:.2f}")
    print()
    print(f"{'source':<20}  {'files':>5}  {'size MB':>9}  {'audio h':>7}  {'video h':>7}  {'text':>4}  {'docs':>4}")
    print("-" * 70)
    for src, s in sorted(stats["by_source"].items()):
        print(
            f"{src:<20}  {s['count']:>5}  {s['size_mb']:>9.1f}  "
            f"{s['audio_hours']:>7.2f}  {s['video_hours']:>7.2f}  "
            f"{s['text_files']:>4}  {s['doc_files']:>4}"
        )
    print()


# ------------------------------------------------------------------ main

def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--refresh", action="store_true",
                    help="Reuse cached entries whose size+mtime unchanged (fast).")
    ap.add_argument("--dry-run", action="store_true",
                    help="Scan and report but do not write manifest.")
    ap.add_argument("--stats", action="store_true",
                    help="Print summary statistics after writing.")
    ap.add_argument("--verbose", "-v", action="store_true")
    args = ap.parse_args(argv)

    repo_root = _repo_root()
    manifest_path = repo_root / MANIFEST_PATH
    stats_path = repo_root / STATS_PATH

    if args.verbose:
        print(f"Repo root: {repo_root}")
        print(f"Manifest:  {manifest_path}")
        print(f"ffprobe:   {'available' if _have_ffprobe() else 'MISSING — durations will be None'}")
        print()

    cache = load_existing(manifest_path) if args.refresh else {}
    if args.verbose and cache:
        print(f"Loaded {len(cache)} cached entries (refresh mode).")

    entries: list[ManifestEntry] = []
    probed = skipped = reused = 0

    for rel_root, source_type in SCAN_ROOTS:
        root = repo_root / rel_root
        if not root.is_dir():
            if args.verbose:
                print(f"  skip (missing): {rel_root}")
            continue
        if args.verbose:
            print(f"  scan: {rel_root}  [{source_type}]")
        for path, src in iter_scan_files(root, source_type):
            entry = build_entry(path, src, repo_root, cache, refresh=args.refresh)
            if entry is None:
                skipped += 1
                continue
            if args.refresh and entry.id in cache and cache[entry.id].mtime == entry.mtime \
                    and cache[entry.id].size_bytes == entry.size_bytes:
                reused += 1
            else:
                probed += 1
            entries.append(entry)

    print(f"Manifest: {len(entries)} files  "
          f"(probed={probed}, reused={reused}, skipped={skipped})")

    if args.dry_run:
        print("(dry run — manifest NOT written)")
    else:
        write_manifest(manifest_path, entries)
        print(f"Wrote {manifest_path}")

    stats = compute_stats(entries)
    if not args.dry_run:
        stats_path.write_text(json.dumps(stats, indent=2), encoding="utf-8")

    if args.stats or args.verbose:
        print_stats(stats)

    return 0


if __name__ == "__main__":
    sys.exit(main())
