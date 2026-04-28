#!/usr/bin/env python3
"""
record_audio.py  v2.0.0
Record clean Awing pronunciation audio for VITS fine-tuning.

Replaces the old YouTube-segmentation + auto-labeling pipeline.
Dr. Sama records ~200 words directly into the microphone.
The filename IS the label, eliminating all OCR/segmentation problems.

Workflow:
  1. Compute a balanced ~200-word shortlist that covers:
     - All 9 Awing vowels × 5 tones (45 cells)
     - All 22 consonants (incl. digraphs ch, gh, ny, sh, ts) + glottal stop
     - Common consonant clusters (prenasalized mb/nd/ng, labialized kw/tw,
       palatalized ky/py, etc.)
     - Syllable lengths 1–4+
  2. Walk through each word with record / play / retake / skip / quit controls
  3. Save as WAV (44.1 kHz mono) into training_data/recordings/{key}.wav
  4. Persist progress so Ctrl+C is safe — re-running resumes where you left off
  5. Write training_data/recordings/manifest.json + metadata.csv (LJSpeech)
     so the dataset can be fed straight into HuggingFace fine-tuning.

Usage:
  python scripts/record_audio.py                  # Record (skips already-done)
  python scripts/record_audio.py --dry-run         # Print shortlist + coverage,
                                                   # do not touch the microphone
  python scripts/record_audio.py --target-count 250  # Pick a longer shortlist
  python scripts/record_audio.py --regenerate-shortlist  # Recompute from scratch
  python scripts/record_audio.py --start-from 50   # Jump to position 50
  python scripts/record_audio.py --list            # Show what's recorded so far

Requirements:
  pip install sounddevice soundfile  (already in scripts/requirements.txt)
  A working microphone (the script checks at startup)
"""

import os
import sys
import json
import argparse
import subprocess
import unicodedata
import re
from pathlib import Path
from datetime import datetime, timezone

# ---------------------------------------------------------------------------
# Auto-activate venv
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
# Constants and data parsing
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
ALPHABET_DART = PROJECT_ROOT / "lib" / "data" / "awing_alphabet.dart"
VOCABULARY_DART = PROJECT_ROOT / "lib" / "data" / "awing_vocabulary.dart"

OUTPUT_DIR = PROJECT_ROOT / "training_data" / "recordings"
SHORTLIST_PATH = OUTPUT_DIR / "shortlist.json"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
METADATA_CSV = OUTPUT_DIR / "metadata.csv"
SKIPPED_PATH = OUTPUT_DIR / "skipped.json"  # Session 54: words to never re-pick

SAMPLE_RATE = 44100
CHANNELS = 1

# Awing phonetic inventory
DIGRAPHS = ["ch", "gh", "ny", "sh", "ts"]
SINGLE_CONS = list("bdfgjklmnpstwyz") + ["ŋ", "'"]
ALL_CONS = DIGRAPHS + SINGLE_CONS  # 22 total + glottal stop = 23 buckets
ALL_VOWELS = list("aeiouɛəɨɔ")  # 9 vowels
TONE_MARKS = {
    "\u0301": "H",  # acute → High
    "\u0300": "L",  # grave → Low
    "\u0302": "F",  # circumflex → Falling
    "\u030C": "R",  # caron → Rising
}
TONES = ["H", "M", "L", "F", "R"]


def _audio_key(awing_text: str) -> str:
    """Convert an Awing word to a safe ASCII filename key.

    Mirrors the convention used by lib/services/pronunciation_service.dart and
    the rest of the audio pipeline so generated WAVs round-trip cleanly.
    """
    nfd = unicodedata.normalize("NFD", awing_text)
    nfd = "".join(c for c in nfd if not unicodedata.combining(c))  # strip tones
    out = []
    for ch in nfd.lower():
        if ch == "ɛ":
            out.append("e")
        elif ch == "ɔ":
            out.append("o")
        elif ch == "ə":
            out.append("e")
        elif ch == "ɨ":
            out.append("i")
        elif ch == "ŋ":
            out.append("ng")
        elif ch in "abcdefghijklmnopqrstuvwxyz0123456789":
            out.append(ch)
        # everything else (apostrophe, punctuation) silently dropped
    return "".join(out) or "unk"


def parse_alphabet():
    """Return list of {letter, example_word, example_english} from awing_alphabet.dart."""
    src = ALPHABET_DART.read_text(encoding="utf-8")
    pat = re.compile(
        r"AwingLetter\("
        r"[^)]*?letter\s*:\s*(['\"])(?P<letter>.+?)\1"
        r"[^)]*?exampleWord\s*:\s*(['\"])(?P<example>.+?)\3"
        r"[^)]*?exampleEnglish\s*:\s*(['\"])(?P<eng>.+?)\5",
        re.DOTALL,
    )
    out = []
    for m in pat.finditer(src):
        out.append({
            "letter": m.group("letter"),
            "awing": m.group("example"),
            "english": m.group("eng"),
            "source": "alphabet",
        })
    return out


def _unescape_dart_str(s: str) -> str:
    """Convert Dart string literal escapes (\\', \\\", \\\\, \\n, \\t) back to plain chars."""
    out = []
    i = 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s):
            nxt = s[i + 1]
            if nxt in ("'", '"', "\\"):
                out.append(nxt)
            elif nxt == "n":
                out.append("\n")
            elif nxt == "t":
                out.append("\t")
            else:
                out.append(nxt)  # drop backslash, keep next char
            i += 2
        else:
            out.append(s[i])
            i += 1
    return "".join(out)


def parse_vocabulary():
    """Return list of vocabulary dicts from awing_vocabulary.dart.

    Skips multi-word phrases (anything with whitespace in `awing`) — those
    are idiomatic dictionary entries, not single-word recording targets for
    VITS fine-tuning.
    """
    src = VOCABULARY_DART.read_text(encoding="utf-8")
    body_pat = re.compile(
        r"AwingWord\((?P<body>[^()]*?(?:\([^()]*\)[^()]*?)*)\)",
        re.DOTALL,
    )
    field_pat = re.compile(
        r"(\w+)\s*:\s*(?:(['\"])((?:\\.|(?!\2).)*?)\2|(\d+))"
    )
    out = []
    for m in body_pat.finditer(src):
        fields = {}
        for fm in field_pat.finditer(m.group("body")):
            k = fm.group(1)
            if fm.group(2):  # quoted string
                fields[k] = _unescape_dart_str(fm.group(3))
            else:  # int
                fields[k] = int(fm.group(4))
        if "awing" not in fields or "english" not in fields:
            continue
        awing = fields["awing"].strip()
        # Reject multi-word phrases (VITS training is per-word).
        if not awing or any(ch.isspace() for ch in awing):
            continue
        # Reject stray backslashes that slipped past escape handling.
        if "\\" in awing:
            continue
        fields["awing"] = awing
        out.append(fields)
    return out


# ---------------------------------------------------------------------------
# Phoneme feature extraction
# ---------------------------------------------------------------------------
def extract_features(word: str):
    """Return dict of features used to score coverage:
        vowel_tones: set of (vowel, tone) tuples
        consonants:  set of consonant tokens (digraphs counted as one)
        clusters:    set of two-token consonant-cluster strings
        nsyl:        syllable count (= number of vowels in the word)
    """
    nfd = unicodedata.normalize("NFD", word)

    # First pass: walk to identify vowels with their attached tone marks.
    vowel_tones = set()
    i = 0
    while i < len(nfd):
        ch = nfd[i]
        if ch in ALL_VOWELS:
            tone = "M"  # default mid / unmarked
            j = i + 1
            while j < len(nfd) and unicodedata.combining(nfd[j]):
                if nfd[j] in TONE_MARKS:
                    tone = TONE_MARKS[nfd[j]]
                j += 1
            vowel_tones.add((ch, tone))
            i = j
        else:
            i += 1

    # Strip combining marks for consonant detection
    plain = "".join(c for c in nfd if not unicodedata.combining(c)).lower()

    # Detect consonants (digraphs first)
    consonants = set()
    clusters = set()
    i = 0
    n = len(plain)
    while i < n:
        # Try digraph match
        if i + 1 < n and plain[i:i+2] in DIGRAPHS:
            consonants.add(plain[i:i+2])
            i += 2
            continue

        ch = plain[i]
        if ch in SINGLE_CONS:
            consonants.add(ch)
            # Check for cluster with the next char
            if i + 1 < n:
                nxt = plain[i+1]
                # Prenasalized: nasal + consonant
                if ch in "mnŋ" and nxt in "bdgpktfzjs":
                    clusters.add(ch + nxt)
                # Labialized: C + w
                elif nxt == "w" and ch in "kgtbpmnlsfd":
                    clusters.add(ch + "w")
                # Palatalized: C + y
                elif nxt == "y" and ch in "kgtbpmnlsfd":
                    clusters.add(ch + "y")
        i += 1

    nsyl = len([1 for c in plain if c in ALL_VOWELS])
    return {
        "vowel_tones": vowel_tones,
        "consonants": consonants,
        "clusters": clusters,
        "nsyl": nsyl,
    }


# ---------------------------------------------------------------------------
# Balanced shortlist selection
# ---------------------------------------------------------------------------
def _load_excluded_keys() -> set:
    """Load skipped-word keys from skipped.json so they never reappear."""
    if not SKIPPED_PATH.exists():
        return set()
    try:
        data = json.loads(SKIPPED_PATH.read_text(encoding="utf-8"))
        return {w["key"] for w in data.get("skipped", []) if "key" in w}
    except (json.JSONDecodeError, KeyError, TypeError):
        return set()


def build_shortlist(target_count: int = 200,
                    excluded_keys: set = None,
                    pinned_keys: set = None) -> list:
    """Pick a balanced shortlist for VITS coverage.

    Strategy:
      1. Seed with the 31 alphabet exampleWords (already designed for coverage)
      2. Greedy-add from the beginner vocabulary pool by marginal coverage gain.
      3. If we hit target before phoneme buckets are full, top up with the
         shortest remaining beginner words.

    Coverage buckets (53 + 23 + ~25 + 4 ≈ 105 total cells to fill):
      - vowel_tones (max 45: 9 vowels × 5 tones; many cells empty in real data)
      - consonants  (23: digraphs + singles + glottal stop)
      - clusters    (open-ended; weighted lower)
      - syllable_lengths (1..4+, 4 cells)

    Session 54 additions:
      excluded_keys: never include these (e.g. words user couldn't pronounce
                     or that have unverified dictionary meanings).
      pinned_keys:   keep these in the shortlist even if their coverage gain
                     is zero (e.g. words already recorded — preserves training
                     data continuity across regeneration runs).
    """
    excluded_keys = excluded_keys or set()
    pinned_keys = pinned_keys or set()

    alphabet = parse_alphabet()
    vocabulary = parse_vocabulary()

    # Beginner pool: difficulty=1 OR difficulty unset (defaults to 1)
    beginner = [w for w in vocabulary if w.get("difficulty", 1) == 1]

    # ----- Seed: alphabet example words (skip excluded) -----
    selected = []
    selected_keys = set()
    for entry in alphabet:
        key = _audio_key(entry["awing"])
        if key in selected_keys or not key or key in excluded_keys:
            continue
        feats = extract_features(entry["awing"])
        selected.append({
            "key": key,
            "awing": entry["awing"],
            "english": entry["english"],
            "source": "alphabet",
            "letter": entry["letter"],
            "features": feats,
        })
        selected_keys.add(key)

    # ----- Coverage state -----
    cov_vt = set()
    cov_cons = set()
    cov_clust = set()
    cov_nsyl = {}
    for s in selected:
        cov_vt |= s["features"]["vowel_tones"]
        cov_cons |= s["features"]["consonants"]
        cov_clust |= s["features"]["clusters"]
        cov_nsyl[s["features"]["nsyl"]] = cov_nsyl.get(s["features"]["nsyl"], 0) + 1

    seen_keys = set(selected_keys)

    # ----- Pinned-first pass: pull already-recorded vocab into selection -----
    # Pinned = keys for clips the user has already recorded. We add them BEFORE
    # building the greedy pool so (a) those WAVs stay valid across regenerations
    # and (b) the coverage state reflects them, so greedy doesn't waste slots
    # re-covering phonemes the recordings already supply.
    # We scan ALL vocabulary (not just beginner) because the prior shortlist
    # could have drawn pinned keys from the gap-fill pass (medium/expert).
    if pinned_keys:
        for w in vocabulary:
            key = _audio_key(w["awing"])
            if not key or key in seen_keys or key not in pinned_keys:
                continue
            feats = extract_features(w["awing"])
            if feats["nsyl"] == 0:
                continue
            seen_keys.add(key)
            # Tag source so the persisted shortlist remembers where pinned came from
            src = "vocabulary" if w.get("difficulty", 1) == 1 else "vocabulary_gap"
            entry = {
                "key": key,
                "awing": w["awing"],
                "english": w["english"],
                "category": w.get("category", ""),
                "source": src,
                "features": feats,
            }
            if src == "vocabulary_gap":
                entry["difficulty"] = w.get("difficulty", 1)
            selected.append(entry)
            cov_vt |= feats["vowel_tones"]
            cov_cons |= feats["consonants"]
            cov_clust |= feats["clusters"]
            cov_nsyl[feats["nsyl"]] = cov_nsyl.get(feats["nsyl"], 0) + 1

    # ----- Build candidate pool from beginner vocabulary (skip excluded + pinned) -----
    candidates = []
    for w in beginner:
        key = _audio_key(w["awing"])
        if not key or key in seen_keys or key in excluded_keys:
            continue
        seen_keys.add(key)
        feats = extract_features(w["awing"])
        # Skip words with no vowels (data error / abbreviations)
        if feats["nsyl"] == 0:
            continue
        candidates.append({
            "key": key,
            "awing": w["awing"],
            "english": w["english"],
            "category": w.get("category", ""),
            "source": "vocabulary",
            "features": feats,
        })

    # ----- Greedy selection by marginal coverage gain -----
    def gain(c):
        f = c["features"]
        # Strong weight for new vowel-tone combos and new consonants
        g = 3 * len(f["vowel_tones"] - cov_vt)
        g += 3 * len(f["consonants"] - cov_cons)
        # Lighter weight for clusters (many are rare)
        g += 1 * len(f["clusters"] - cov_clust)
        # Reward syllable length diversity (2 syll → most common, prefer 1, 3, 4+)
        nsyl = f["nsyl"]
        if cov_nsyl.get(nsyl, 0) < 8:
            g += 1
        return g

    while len(selected) < target_count and candidates:
        # Pick the candidate with highest gain; tie-break by shorter awing word
        best = max(candidates, key=lambda c: (gain(c), -len(c["awing"])))
        if gain(best) == 0:
            # No more useful coverage from beginner pool — try gap-fill next.
            break
        selected.append(best)
        candidates.remove(best)
        f = best["features"]
        cov_vt |= f["vowel_tones"]
        cov_cons |= f["consonants"]
        cov_clust |= f["clusters"]
        cov_nsyl[f["nsyl"]] = cov_nsyl.get(f["nsyl"], 0) + 1

    # ----- Gap-fill pass: pull from ALL difficulty levels for rare phonemes -----
    # Beginner vocabulary can't cover every vowel-tone × consonant combo because
    # some are genuinely rare in Awing. Scan medium + expert vocabulary for words
    # that close remaining gaps on vowel_tones and consonants (clusters are too
    # plentiful to justify this).
    if len(selected) < target_count:
        advanced = [w for w in vocabulary if w.get("difficulty", 1) > 1]
        gap_candidates = []
        for w in advanced:
            key = _audio_key(w["awing"])
            if not key or key in seen_keys or key in excluded_keys:
                continue
            seen_keys.add(key)
            feats = extract_features(w["awing"])
            if feats["nsyl"] == 0:
                continue
            # Only consider if it fills a rare gap
            new_vt = feats["vowel_tones"] - cov_vt
            new_cons = feats["consonants"] - cov_cons
            if not new_vt and not new_cons:
                continue
            gap_candidates.append({
                "key": key,
                "awing": w["awing"],
                "english": w["english"],
                "category": w.get("category", ""),
                "source": "vocabulary_gap",
                "difficulty": w.get("difficulty", 1),
                "features": feats,
                "new_cells": len(new_vt) + len(new_cons),
            })
        # Pick the ones that contribute the most new cells per word,
        # preferring difficulty=2 over difficulty=3 and shorter words.
        gap_candidates.sort(
            key=lambda c: (-c["new_cells"], c["difficulty"], len(c["awing"]))
        )
        for c in gap_candidates:
            if len(selected) >= target_count:
                break
            f = c["features"]
            new_vt = f["vowel_tones"] - cov_vt
            new_cons = f["consonants"] - cov_cons
            if not new_vt and not new_cons:
                continue  # cell already filled by an earlier gap pick
            selected.append(c)
            cov_vt |= f["vowel_tones"]
            cov_cons |= f["consonants"]
            cov_clust |= f["clusters"]
            cov_nsyl[f["nsyl"]] = cov_nsyl.get(f["nsyl"], 0) + 1

    # Top up with shortest remaining beginner words (without coverage gain)
    if len(selected) < target_count and candidates:
        candidates.sort(key=lambda c: (len(c["awing"]), c["english"]))
        for c in candidates:
            if len(selected) >= target_count:
                break
            selected.append(c)

    # Final coverage report fields
    return selected, {
        "vowel_tones": sorted(cov_vt),
        "consonants": sorted(cov_cons),
        "clusters": sorted(cov_clust),
        "syllable_histogram": dict(sorted(cov_nsyl.items())),
    }


def print_coverage(shortlist, coverage):
    print()
    print("=" * 64)
    print(f"  SHORTLIST COVERAGE — {len(shortlist)} words")
    print("=" * 64)

    # Vowel × Tone matrix
    print("\n  Vowel × Tone coverage:")
    print("       " + "  ".join(t.rjust(2) for t in TONES))
    cov = set(tuple(vt) for vt in coverage["vowel_tones"])
    for v in ALL_VOWELS:
        row = [v.rjust(3)]
        for t in TONES:
            row.append(" ✓" if (v, t) in cov else " ·")
        print("    " + "  ".join(row))
    cov_count = len([1 for v in ALL_VOWELS for t in TONES if (v, t) in cov])
    print(f"    (filled {cov_count}/45 cells — empty cells are tones that")
    print(f"     don't occur anywhere in the source vocabulary)")

    # Consonants
    print("\n  Consonants covered ({}/{}):".format(
        len(coverage["consonants"]), len(ALL_CONS)))
    have = set(coverage["consonants"])
    print("    " + " ".join(c if c in have else f"({c})" for c in ALL_CONS))
    missing = [c for c in ALL_CONS if c not in have]
    if missing:
        print(f"    Missing: {' '.join(missing)} (parens above)")

    # Clusters
    print(f"\n  Consonant clusters covered ({len(coverage['clusters'])}):")
    print("    " + " ".join(coverage["clusters"]) if coverage["clusters"] else
          "    (none)")

    # Syllable histogram
    print("\n  Syllable count histogram:")
    for nsyl, count in coverage["syllable_histogram"].items():
        bar = "█" * min(count, 50)
        print(f"    {nsyl} syll: {count:3d}  {bar}")

    # Source breakdown
    src_counts = {}
    for s in shortlist:
        src_counts[s["source"]] = src_counts.get(s["source"], 0) + 1
    print(f"\n  Sources: {src_counts}")
    print("=" * 64)


# ---------------------------------------------------------------------------
# Microphone recorder
# ---------------------------------------------------------------------------
def _import_audio_libs():
    """Imported lazily so --dry-run works without sounddevice installed."""
    try:
        import sounddevice as sd
        import soundfile as sf
        import numpy as np
        return sd, sf, np
    except ImportError as e:
        print(f"\nERROR: missing audio library: {e}")
        print("Run:  pip install sounddevice soundfile numpy")
        sys.exit(1)


class Recorder:
    def __init__(self):
        self.sd, self.sf, self.np = _import_audio_libs()
        import threading
        self._threading = threading
        self.recording = False
        self.frames = []
        self._thread = None

    def start(self):
        self.frames = []
        self.recording = True
        self._thread = self._threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def _loop(self):
        try:
            with self.sd.InputStream(samplerate=SAMPLE_RATE, channels=CHANNELS,
                                     dtype="float32") as stream:
                while self.recording:
                    data, _ = stream.read(1024)
                    self.frames.append(data.copy())
        except Exception as e:
            print(f"\n  ERROR recording: {e}")
            self.recording = False

    def stop(self):
        self.recording = False
        if self._thread:
            self._thread.join(timeout=2)
        if not self.frames:
            return None
        return self.np.concatenate(self.frames, axis=0)

    def save_wav(self, audio_data, output_path: Path):
        output_path.parent.mkdir(parents=True, exist_ok=True)
        self.sf.write(str(output_path), audio_data, SAMPLE_RATE)

    def play(self, path: Path):
        try:
            data, rate = self.sf.read(str(path))
            self.sd.play(data, rate)
            self.sd.wait()
        except Exception as e:
            print(f"  Could not play back: {e}")


# ---------------------------------------------------------------------------
# Manifest persistence
# ---------------------------------------------------------------------------
def load_manifest():
    if not MANIFEST_PATH.exists():
        return []
    try:
        return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except Exception:
        return []


def save_manifest(entries):
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(entries, indent=2, ensure_ascii=False),
                             encoding="utf-8")


def write_metadata_csv(entries):
    """LJSpeech-compatible metadata.csv: key|awing|english"""
    METADATA_CSV.parent.mkdir(parents=True, exist_ok=True)
    with METADATA_CSV.open("w", encoding="utf-8") as f:
        for e in entries:
            f.write(f"{e['key']}|{e['awing']}|{e['english']}\n")


def load_or_build_shortlist(target_count: int, regenerate: bool,
                            respect_skip_list: bool = True):
    if SHORTLIST_PATH.exists() and not regenerate:
        try:
            data = json.loads(SHORTLIST_PATH.read_text(encoding="utf-8"))
            print(f"  Loaded existing shortlist: {len(data['shortlist'])} words "
                  f"({SHORTLIST_PATH.relative_to(PROJECT_ROOT)})")
            return data["shortlist"], data["coverage"]
        except Exception as e:
            print(f"  Could not load shortlist ({e}), rebuilding...")

    # Session 54: when regenerating, preserve continuity with prior recordings:
    #   excluded_keys  = words user couldn't pronounce / not in dictionary
    #   pinned_keys    = words user has already recorded (keep them in)
    excluded_keys = _load_excluded_keys() if respect_skip_list else set()
    pinned_keys = set()
    if regenerate:
        # Pin every key already on disk as a .wav (filesystem is the source of
        # truth for "what's recorded" — manifest.json may lag behind).
        for wav in OUTPUT_DIR.glob("*.wav"):
            pinned_keys.add(wav.stem)
        if pinned_keys:
            print(f"  Pinning {len(pinned_keys)} already-recorded words "
                  f"(found .wav files in {OUTPUT_DIR.relative_to(PROJECT_ROOT)})")
        if excluded_keys:
            print(f"  Excluding {len(excluded_keys)} previously-skipped words "
                  f"(from {SKIPPED_PATH.relative_to(PROJECT_ROOT)})")
        # Backup the old shortlist before overwriting so it can be diffed/restored
        if SHORTLIST_PATH.exists():
            from datetime import datetime
            stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup = SHORTLIST_PATH.with_suffix(f".json.bak.{stamp}")
            backup.write_bytes(SHORTLIST_PATH.read_bytes())
            print(f"  Backed up old shortlist → {backup.relative_to(PROJECT_ROOT)}")

    print(f"  Building balanced shortlist (target {target_count} words)...")
    shortlist, coverage = build_shortlist(target_count,
                                          excluded_keys=excluded_keys,
                                          pinned_keys=pinned_keys)
    # Strip non-serializable fields and persist
    persist = []
    for s in shortlist:
        entry = {
            "key": s["key"],
            "awing": s["awing"],
            "english": s["english"],
            "source": s["source"],
        }
        if "letter" in s:
            entry["letter"] = s["letter"]
        if s["source"].startswith("vocabulary"):
            entry["category"] = s.get("category", "")
            entry["difficulty"] = s.get("difficulty", 1)
        persist.append(entry)
    persist_cov = {
        "vowel_tones": [list(vt) for vt in coverage["vowel_tones"]],
        "consonants": coverage["consonants"],
        "clusters": coverage["clusters"],
        "syllable_histogram": coverage["syllable_histogram"],
    }
    SHORTLIST_PATH.parent.mkdir(parents=True, exist_ok=True)
    SHORTLIST_PATH.write_text(
        json.dumps({"shortlist": persist, "coverage": persist_cov},
                   indent=2, ensure_ascii=False),
        encoding="utf-8")
    print(f"  Saved shortlist → {SHORTLIST_PATH.relative_to(PROJECT_ROOT)}")
    return persist, persist_cov


# ---------------------------------------------------------------------------
# Recording loop
# ---------------------------------------------------------------------------
def record_session(shortlist, recorder, start_from: int = 0):
    """Walk through the shortlist and record one word at a time."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Build manifest of existing recordings
    manifest = load_manifest()
    have_keys = {e["key"] for e in manifest}

    total = len(shortlist)
    done = sum(1 for s in shortlist if s["key"] in have_keys)
    print(f"\n  {done}/{total} already recorded ({total - done} remaining)")

    if done == total:
        print("  ✓ All words recorded! Run with --regenerate-shortlist to start over.")
        return

    print("\n" + "=" * 64)
    print("  RECORDING CONTROLS")
    print("    ENTER          start recording")
    print("    ENTER          stop recording")
    print("    p              play back the take")
    print("    r              re-record this word")
    print("    s              skip this word (no save)")
    print("    q              save progress and quit")
    print("    ENTER          accept and move to next word")
    print("=" * 64)

    for idx, entry in enumerate(shortlist):
        if idx + 1 < start_from:
            continue
        if entry["key"] in have_keys:
            continue

        out_path = OUTPUT_DIR / f"{entry['key']}.wav"
        print()
        print("-" * 64)
        print(f"  [{idx+1}/{total}]   {entry['awing']}")
        print(f"  English: {entry['english']}")
        if entry["source"] == "alphabet":
            print(f"  (alphabet example for letter '{entry.get('letter', '?')}')")
        elif entry.get("category"):
            print(f"  (category: {entry['category']})")
        print(f"  → will save to: training_data/recordings/{entry['key']}.wav")

        # Record / retake loop
        accepted = False
        while not accepted:
            try:
                cmd = input("  >> ENTER to record (q to quit, s to skip): ").strip().lower()
            except (EOFError, KeyboardInterrupt):
                print("\n  Interrupted — saving progress.")
                save_manifest(manifest)
                write_metadata_csv(manifest)
                return

            if cmd == "q":
                print("  Saving progress and exiting.")
                save_manifest(manifest)
                write_metadata_csv(manifest)
                return
            if cmd == "s":
                print("  Skipped.")
                accepted = True
                break

            print("  🔴 RECORDING...  (press ENTER to stop)")
            recorder.start()
            try:
                input()
            except (EOFError, KeyboardInterrupt):
                recorder.stop()
                print("\n  Interrupted — saving progress.")
                save_manifest(manifest)
                write_metadata_csv(manifest)
                return
            audio = recorder.stop()

            if audio is None or len(audio) == 0:
                print("  No audio captured. Try again.")
                continue
            duration = len(audio) / SAMPLE_RATE
            print(f"  Recorded {duration:.2f}s")

            recorder.save_wav(audio, out_path)

            # Post-recording menu
            while True:
                try:
                    choice = input("  >> (p)lay / (r)e-record / (s)kip / (q)uit / "
                                   "ENTER to accept: ").strip().lower()
                except (EOFError, KeyboardInterrupt):
                    print("\n  Interrupted — saving progress.")
                    save_manifest(manifest)
                    write_metadata_csv(manifest)
                    return

                if choice == "p":
                    print("  Playing...", end=" ", flush=True)
                    recorder.play(out_path)
                    print("done.")
                elif choice == "r":
                    print("  Re-recording...")
                    break  # re-enter outer loop
                elif choice == "s":
                    out_path.unlink(missing_ok=True)
                    print("  Skipped (file deleted).")
                    accepted = True
                    break
                elif choice == "q":
                    # Keep this take, then exit
                    manifest.append({
                        "key": entry["key"],
                        "awing": entry["awing"],
                        "english": entry["english"],
                        "wav_path": f"training_data/recordings/{entry['key']}.wav",
                        "duration_s": round(duration, 3),
                        "source": entry["source"],
                        "recorded_at": datetime.now(timezone.utc).isoformat(),
                    })
                    save_manifest(manifest)
                    write_metadata_csv(manifest)
                    print("  Saved this take and exiting.")
                    return
                elif choice == "":
                    manifest.append({
                        "key": entry["key"],
                        "awing": entry["awing"],
                        "english": entry["english"],
                        "wav_path": f"training_data/recordings/{entry['key']}.wav",
                        "duration_s": round(duration, 3),
                        "source": entry["source"],
                        "recorded_at": datetime.now(timezone.utc).isoformat(),
                    })
                    save_manifest(manifest)  # checkpoint after every accept
                    write_metadata_csv(manifest)
                    have_keys.add(entry["key"])
                    print(f"  ✓ Saved {entry['key']}.wav   "
                          f"(progress: {len(have_keys)}/{total})")
                    accepted = True
                    break
                else:
                    print("  Type p, r, s, q, or just press ENTER")

    print("\n" + "=" * 64)
    print(f"  ALL DONE — {len(have_keys)} clips in training_data/recordings/")
    print(f"  Manifest:    {MANIFEST_PATH.relative_to(PROJECT_ROOT)}")
    print(f"  CSV (HF):    {METADATA_CSV.relative_to(PROJECT_ROOT)}")
    print("=" * 64)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def cmd_list(shortlist):
    manifest = load_manifest()
    have_keys = {e["key"] for e in manifest}
    print()
    print(f"  Recordings:  {len(have_keys)}/{len(shortlist)}  "
          f"({OUTPUT_DIR.relative_to(PROJECT_ROOT)})")
    print()
    for idx, s in enumerate(shortlist):
        mark = "✓" if s["key"] in have_keys else "·"
        flag = f"[{s['source'][0]}]"
        print(f"  {mark} {idx+1:3d}.  {flag}  {s['awing']:20s}  =  {s['english']}")
    print()


def main():
    parser = argparse.ArgumentParser(
        description="Record clean Awing audio for VITS fine-tuning."
    )
    parser.add_argument("--target-count", type=int, default=200,
                        help="How many words to include in the shortlist (default 200)")
    parser.add_argument("--regenerate-shortlist", action="store_true",
                        help="Recompute the shortlist even if one exists")
    parser.add_argument("--start-from", type=int, default=0,
                        help="Resume at position N (1-indexed). Already-recorded "
                             "words are skipped automatically.")
    parser.add_argument("--list", action="store_true",
                        help="Show the shortlist and which words are recorded")
    parser.add_argument("--dry-run", action="store_true",
                        help="Compute shortlist + print coverage stats. Do not "
                             "touch the microphone.")
    parser.add_argument("--no-skip-list", action="store_true",
                        help="Ignore training_data/recordings/skipped.json when "
                             "regenerating. Default behaviour respects it so "
                             "previously-skipped words don't reappear.")
    args = parser.parse_args()

    print("\n  Awing audio recorder for VITS fine-tuning")
    print(f"  Project root: {PROJECT_ROOT}")
    print(f"  Output:       {OUTPUT_DIR.relative_to(PROJECT_ROOT)}/")

    shortlist, coverage = load_or_build_shortlist(
        args.target_count,
        args.regenerate_shortlist,
        respect_skip_list=not args.no_skip_list)
    print_coverage(shortlist, coverage)

    if args.list:
        cmd_list(shortlist)
        return

    if args.dry_run:
        print("\n  --dry-run: shortlist saved. Skipping microphone setup.")
        print("  Re-run without --dry-run to start recording.")
        return

    # Microphone check
    print("\n  Initializing audio device...")
    sd, _, _ = _import_audio_libs()
    try:
        default_input = sd.query_devices(kind="input")
        print(f"  Microphone:   {default_input['name']}")
        print(f"  Sample rate:  {SAMPLE_RATE} Hz, channels: {CHANNELS}")
    except Exception as e:
        print(f"\n  ERROR: no microphone found: {e}")
        print("  Make sure a microphone is connected and selected as default.")
        sys.exit(1)

    recorder = Recorder()
    try:
        record_session(shortlist, recorder, start_from=args.start_from)
    except KeyboardInterrupt:
        print("\n  Interrupted. Progress saved in manifest.")


if __name__ == "__main__":
    main()
