#!/usr/bin/env python3
"""
A/B Spot-Check — Whisper-derived overrides vs default awing_to_speakable()

A small, gated validation step BEFORE committing to the full 197-recording
override pipeline. Picks ~15 diverse words from the local training
recordings, transcribes each with Whisper(language='sw'), then generates
TWO Edge TTS clips per word per voice:

  A = default     awing_to_speakable(awing) → Edge TTS
  B = Whisper-derived override            → Edge TTS

Emits an HTML rating page so Dr. Sama can A/B compare each pair against
the ground-truth recording. The aggregate panel reports avg stars per
side and an "override wins" ratio. If overrides reliably beat the default
on this small sample, we proceed to the full pipeline. If not, the
default mapping wins for those words and we focus on rule improvements.

The 6 Edge TTS voices remain THE official voices of the app. This script
never replaces them with human recordings — the recordings are reference
material that shapes the SPELLINGS fed into the same 6 frozen voices.

Usage:
    python scripts/ab_spot_check.py setup            # Pick samples, run Whisper, generate A & B
    python scripts/ab_spot_check.py setup --samples 20 --voices young_woman,boy,girl
    python scripts/ab_spot_check.py setup --all-voices    # All 6 voices
    python scripts/ab_spot_check.py setup --force         # Re-run Whisper + regenerate
    python scripts/ab_spot_check.py html             # Re-emit spotcheck.html only
    python scripts/ab_spot_check.py status           # Show file counts
    python scripts/ab_spot_check.py clean            # Remove generated A/B clips
    python scripts/ab_spot_check.py clean --deep     # Also remove ground-truth + manifest

Then open: training_data/ab_spot_check/spotcheck.html

Requires: edge-tts (pip install edge-tts)
          openai-whisper (pip install openai-whisper) — script is fail-loud
                                                        if missing
"""

import os
import sys
import json
import shutil
import argparse
import asyncio
import unicodedata
import re
import subprocess
from pathlib import Path
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Auto-activate venv (same pattern as record_audio.py)
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
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
RECORDINGS_DIR = PROJECT_ROOT / "training_data" / "recordings"
RECORDINGS_MANIFEST = RECORDINGS_DIR / "manifest.json"

SPOT_CHECK_DIR = PROJECT_ROOT / "training_data" / "ab_spot_check"
GROUND_TRUTH_DIR = SPOT_CHECK_DIR / "_ground_truth"
DEFAULT_DIR = SPOT_CHECK_DIR / "_default"      # A
OVERRIDE_DIR = SPOT_CHECK_DIR / "_override"    # B
SAMPLES_MANIFEST = SPOT_CHECK_DIR / "manifest.json"
HTML_OUT = SPOT_CHECK_DIR / "spotcheck.html"

TEMP_DIR = SCRIPT_DIR / "_ab_spot_temp"


# ---------------------------------------------------------------------------
# Import production helpers from generate_audio_edge so spot-check uses
# IDENTICAL defaults to what the build pipeline ships.
# ---------------------------------------------------------------------------
sys.path.insert(0, str(SCRIPT_DIR))
try:
    from generate_audio_edge import (
        VOICE_CHARACTERS,
        awing_to_speakable,
    )
except ImportError as e:
    print(f"ERROR: could not import from generate_audio_edge.py: {e}")
    print("Run from the project root after installing edge-tts.")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Linguistic bucket detection
# ---------------------------------------------------------------------------

# Combining diacritics → tone names
_TONE_MARK_NAMES = {
    "\u0301": "high",     # acute (á)
    "\u0300": "low",      # grave (à)
    "\u0302": "falling",  # circumflex (â)
    "\u030C": "rising",   # caron (ǎ)
}

# Awing vowels (base)
_AWING_VOWELS = set("aeiouɛɔəɨ")

# Prenasalized cluster prefixes (consonant after a nasal)
_PRENASAL_PREFIXES = ("mb", "nd", "nj", "nk", "ng", "nt", "nz", "ns",
                      "ŋg", "ŋk")

# Diphthongs (vowel + ə sequences)
_DIPHTHONGS = ("iə", "ɨə", "uə")


def _strip_diacritics(text):
    """Remove combining marks but keep base characters intact."""
    nfd = unicodedata.normalize("NFD", text)
    return "".join(c for c in nfd if not unicodedata.category(c).startswith("M"))


def _detect_tones(text):
    """Return set of tone names present in the word ('high', 'low', etc).
    'mid' is added if any vowel has no diacritic mark.
    """
    tones = set()
    nfd = unicodedata.normalize("NFD", text.lower())
    has_unmarked_vowel = False
    i = 0
    while i < len(nfd):
        c = nfd[i]
        if c in _AWING_VOWELS:
            # Look ahead for combining marks attached to this vowel
            marked = False
            j = i + 1
            while j < len(nfd) and unicodedata.category(nfd[j]).startswith("M"):
                if nfd[j] in _TONE_MARK_NAMES:
                    tones.add(_TONE_MARK_NAMES[nfd[j]])
                    marked = True
                j += 1
            if not marked:
                has_unmarked_vowel = True
            i = j
        else:
            i += 1
    if has_unmarked_vowel:
        tones.add("mid")
    return tones


def _count_syllables(text):
    """Rough syllable count: count vowel groups in the base form.
    Treats long vowels (aa, oo) and diphthongs (iə) as single syllables.
    """
    base = _strip_diacritics(text.lower())
    base = base.replace("'", "").replace("\u2019", "")
    count = 0
    in_vowel = False
    for c in base:
        if c in _AWING_VOWELS:
            if not in_vowel:
                count += 1
                in_vowel = True
        else:
            in_vowel = False
    return count


def _bucket_word(awing_text):
    """Return list of bucket tags this word falls into."""
    base = awing_text.lower()
    base_no_dia = _strip_diacritics(base)
    buckets = []

    # /ɣ/ fricative
    if "gh" in base_no_dia or "ɣ" in base_no_dia:
        buckets.append("gh")

    # Special vowels
    for v in "ɛɔəɨ":
        if v in base_no_dia:
            buckets.append(f"vowel_{v}")
            break  # one is enough to mark this bucket

    # Tones
    for t in _detect_tones(awing_text):
        buckets.append(f"tone_{t}")

    # Prenasalized clusters
    for prefix in _PRENASAL_PREFIXES:
        if prefix in base_no_dia:
            buckets.append("prenasal")
            break

    # Glottal stops
    if "'" in base or "\u2019" in base:
        buckets.append("glottal")

    # Long vowels (doubled)
    for v in "aeiouɛɔəɨ":
        if v + v in base_no_dia:
            buckets.append("long_vowel")
            break

    # Diphthongs
    for d in _DIPHTHONGS:
        if d in base_no_dia:
            buckets.append("diphthong")
            break

    # Polysyllabic
    if _count_syllables(awing_text) >= 3:
        buckets.append("polysyllabic")

    return buckets


# ---------------------------------------------------------------------------
# Sample curation
# ---------------------------------------------------------------------------

# Target buckets we want represented in the spot-check sample
TARGET_BUCKETS = [
    "gh",
    "vowel_ɛ", "vowel_ɔ", "vowel_ə", "vowel_ɨ",
    "tone_high", "tone_low", "tone_falling", "tone_rising", "tone_mid",
    "prenasal",
    "glottal",
    "long_vowel",
    "diphthong",
    "polysyllabic",
]


def _curate_samples(manifest_entries, target_count):
    """Greedy diverse sample selection covering all target buckets.

    Priority:
    1. Seed: pick one entry per target bucket (first hit).
    2. Fill: if we still have room, add entries that introduce the most
       new buckets (diminishing returns until target_count reached).

    Returns: list of (entry, buckets) tuples.
    """
    # Index entries by bucket
    bucket_pool = {b: [] for b in TARGET_BUCKETS}
    entry_buckets = {}
    for entry in manifest_entries:
        bks = _bucket_word(entry["awing"])
        entry_buckets[entry["key"]] = bks
        for b in bks:
            if b in bucket_pool:
                bucket_pool[b].append(entry)

    selected = []
    selected_keys = set()

    # Pass 1: seed one entry per bucket (skip empties)
    for bucket in TARGET_BUCKETS:
        for entry in bucket_pool[bucket]:
            if entry["key"] not in selected_keys:
                selected.append(entry)
                selected_keys.add(entry["key"])
                break
        if len(selected) >= target_count:
            break

    # Pass 2: greedy fill — pick entries that hit unrepresented buckets
    if len(selected) < target_count:
        # Bucket count among already-selected
        covered = {b: 0 for b in TARGET_BUCKETS}
        for e in selected:
            for b in entry_buckets[e["key"]]:
                if b in covered:
                    covered[b] += 1

        remaining = [e for e in manifest_entries if e["key"] not in selected_keys]
        while len(selected) < target_count and remaining:
            # Score each remaining entry by how many UNDER-COVERED buckets it adds
            best, best_score = None, -1
            for e in remaining:
                score = sum(
                    1 for b in entry_buckets[e["key"]]
                    if b in covered and covered[b] == 0
                )
                # Tiebreak: shorter words first (cleaner Whisper transcription)
                if score > best_score or (
                    score == best_score and best is not None
                    and len(e["awing"]) < len(best["awing"])
                ):
                    best, best_score = e, score
            if best is None or best_score < 0:
                break
            selected.append(best)
            selected_keys.add(best["key"])
            remaining.remove(best)
            for b in entry_buckets[best["key"]]:
                if b in covered:
                    covered[b] += 1
            if best_score == 0:
                # No remaining entry can add a new bucket; stop early
                break

    # Final: pad with any remaining entries up to target_count
    if len(selected) < target_count:
        for e in manifest_entries:
            if e["key"] not in selected_keys:
                selected.append(e)
                selected_keys.add(e["key"])
                if len(selected) >= target_count:
                    break

    return [(e, entry_buckets[e["key"]]) for e in selected[:target_count]]


# ---------------------------------------------------------------------------
# Whisper transcription (fail-loud if missing)
# ---------------------------------------------------------------------------

_WHISPER_MODEL_CACHE = {}


def _sanitize_override(text):
    """Normalize a Whisper transcription so Edge TTS Swahili can pronounce it.

    Whisper sometimes leaks Awing-specific characters (ɛ, ɔ, ə, ɨ, ŋ, ɣ, tone
    diacritics) into its output even when language='sw'. Edge TTS Swahili has
    no idea what those are and spells them out letter-by-letter ("ə" → "uh-uh"
    or just silent), which is exactly what defeated the first attempt.

    This re-uses production's awing_to_speakable() character map as a final
    pass over Whisper's output. Whisper still gets to choose the word SHAPE
    (where consonants land, vowel quality, syllable count). We only strip
    what Swahili can't pronounce.
    """
    if not text:
        return text
    # awing_to_speakable handles: gh→g, ɛ→e, ɔ→o, ə→e, ɨ→i, ŋ→ng, ɣ→g,
    # apostrophes stripped, tone diacritics stripped (NFD), etc.
    cleaned = awing_to_speakable(text)
    # Also strip any leftover punctuation Whisper sometimes adds (.,!?")
    cleaned = re.sub(r"[.,!?\"\u201c\u201d\u2018\u2019]", "", cleaned).strip()
    # Collapse runs of whitespace
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned or None


def _bigrams(s):
    """Return a set of 2-character substrings from s (lowercased, no spaces)."""
    if not s:
        return set()
    s = re.sub(r"\s+", "", s.lower())
    if len(s) < 2:
        return {s} if s else set()
    return {s[i:i + 2] for i in range(len(s) - 1)}


def _similarity(a, b):
    """Bigram Jaccard similarity in [0,1]. Symmetric, order-insensitive.

    Examples:
      'eshue' vs 'ajida'  -> 0.00 (clear hallucination — 0 shared bigrams)
      'eshue' vs 'eshwe'  -> 0.33 (close acoustic miss — acceptable)
      'ngoone' vs 'ngoone' -> 1.00 (perfect)
      'pene' vs 'penne'   -> 0.50 (consonant doubling — acceptable)
    """
    bg_a, bg_b = _bigrams(a), _bigrams(b)
    if not bg_a or not bg_b:
        return 0.0
    return len(bg_a & bg_b) / len(bg_a | bg_b)


# Reject Whisper output as a hallucination when:
#   bigram-Jaccard(sanitized_whisper, default_speakable) < this threshold
#   AND the first letter doesn't match.
# Tuned so 'eshue' vs 'ajida' (Jaccard=0.0, first-letter mismatch) is rejected
# but 'eshue' vs 'eshwe' (Jaccard=0.33) and other near-misses pass through.
_HALLUCINATION_SIMILARITY_FLOOR = 0.20


def _is_hallucination(sanitized_whisper, default_speakable, awing):
    """Heuristic: does the Whisper output look unrelated to the Awing word?

    Returns (is_hallucination: bool, reason: str|None, similarity: float).

    We compare the sanitized Whisper output against the production
    awing_to_speakable() default. Both should land in roughly the same
    Swahili-letter space if Whisper actually heard the audio. If they
    share neither bigrams nor a first letter, Whisper invented something.
    """
    if not sanitized_whisper:
        return True, "empty after sanitization", 0.0

    sim = _similarity(sanitized_whisper, default_speakable)
    s_first = sanitized_whisper.lower().lstrip()[:1]
    d_first = default_speakable.lower().lstrip()[:1]
    first_match = bool(s_first and d_first and s_first == d_first)

    # Length sanity — Whisper sometimes returns long sentences from background
    # noise or its language-model prior. If output is >3x the default, suspect.
    len_ratio = (len(sanitized_whisper.replace(" ", "")) /
                 max(1, len(default_speakable.replace(" ", ""))))
    if len_ratio > 3.0:
        return (True,
                f"output {len_ratio:.1f}x longer than expected "
                f"(LM rambled?)",
                sim)

    if sim < _HALLUCINATION_SIMILARITY_FLOOR and not first_match:
        return (True,
                f"bigram overlap {sim:.2f} < {_HALLUCINATION_SIMILARITY_FLOOR} "
                f"AND first letter mismatch ({s_first!r} vs {d_first!r})",
                sim)

    return False, None, sim


def _whisper_transcribe(wav_path, awing=None, model_name="small"):
    """Transcribe a recording with OpenAI Whisper (Swahili-biased) + sanity check.

    Returns (raw_text, sanitized_text) or (None, None). Loud warning on fail
    or on hallucination-rejection.

    NOTE: We deliberately DO NOT pass `initial_prompt=awing`. Priming
    Whisper with the Awing word causes it to copy back the Awing characters
    (ɛ, ə, ŋ, etc.) verbatim, which then breaks Edge TTS Swahili. Letting
    Whisper run unbiased forces it to invent its own Swahili-letter
    approximation, which is exactly the input Edge TTS is trained on.

    Hallucination guard: if Whisper's output shares neither bigrams nor a
    first letter with the default awing_to_speakable() rendering AND the
    `awing` arg is provided, we reject the override (return raw, None) so
    the caller falls back to the default mapping. This catches the
    Whisper-Swahili LM-prior failure mode where Whisper invents a
    plausible Swahili word ("Ajida") for an unfamiliar Awing input
    ("əshûə").
    """
    try:
        import whisper
    except ImportError:
        print()
        print("=" * 64)
        print("!! OpenAI Whisper is NOT installed.")
        print("!! Spot-check needs Whisper to derive override strings.")
        print("!!")
        print("!! Fix:")
        print("!!     venv\\Scripts\\pip install openai-whisper")
        print("!! Then rerun: python scripts\\ab_spot_check.py setup")
        print("=" * 64)
        return None, None

    if model_name not in _WHISPER_MODEL_CACHE:
        print(f"  Loading Whisper model '{model_name}' (one-time)...")
        _WHISPER_MODEL_CACHE[model_name] = whisper.load_model(model_name)
    model = _WHISPER_MODEL_CACHE[model_name]

    try:
        result = model.transcribe(
            str(wav_path),
            language="sw",
            task="transcribe",
            # NO initial_prompt — see docstring
            fp16=False,
        )
        raw = (result.get("text") or "").strip()
        if not raw:
            return None, None
        sanitized = _sanitize_override(raw)

        # Hallucination guard — only runs if caller passes the Awing word
        # so we know what the audio is supposed to be.
        if awing and sanitized:
            default = awing_to_speakable(awing)
            is_hallu, reason, sim = _is_hallucination(sanitized, default, awing)
            if is_hallu:
                print(f"    ! HALLUCINATION REJECTED: {reason}")
                print(f"      whisper said: '{sanitized}'   "
                      f"default says: '{default}'   sim={sim:.2f}")
                print(f"      → falling back to default mapping for this word")
                return raw, None

        return raw, sanitized
    except Exception as e:
        print(f"    ! Whisper failed for {wav_path.name}: {e}")
        return None, None


# ---------------------------------------------------------------------------
# Edge TTS clip generation
# ---------------------------------------------------------------------------

async def _edge_tts_to_mp3(text, voice_name, rate, pitch, output_path):
    """Generate one Edge TTS clip. Returns True on success."""
    import edge_tts
    try:
        TEMP_DIR.mkdir(parents=True, exist_ok=True)
        temp_mp3 = TEMP_DIR / f"_temp_{os.getpid()}.mp3"
        communicate = edge_tts.Communicate(text, voice_name, rate=rate, pitch=pitch)
        await communicate.save(str(temp_mp3))
        if temp_mp3.exists() and temp_mp3.stat().st_size > 500:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(temp_mp3, output_path)
            try:
                temp_mp3.unlink()
            except Exception:
                pass
            return True
    except Exception as e:
        print(f"    ! Edge TTS failed ({voice_name}, '{text}'): {e}")
    return False


async def _generate_pair(awing, override, voices, key):
    """For each voice generate A (default) and B (override) clips."""
    a_results = {}
    b_results = {}
    default_text = awing_to_speakable(awing)
    for voice_id in voices:
        cfg = VOICE_CHARACTERS[voice_id]
        voice_name = cfg["voice"]
        rate = cfg["rate"]
        pitch = cfg["pitch"]

        a_path = DEFAULT_DIR / voice_id / f"{key}.mp3"
        b_path = OVERRIDE_DIR / voice_id / f"{key}.mp3"

        a_ok = await _edge_tts_to_mp3(default_text, voice_name, rate, pitch, a_path)
        a_results[voice_id] = a_ok

        if override:
            b_ok = await _edge_tts_to_mp3(override, voice_name, rate, pitch, b_path)
            b_results[voice_id] = b_ok
        else:
            b_results[voice_id] = False

    return a_results, b_results, default_text


# ---------------------------------------------------------------------------
# Subcommand: setup
# ---------------------------------------------------------------------------

def cmd_setup(args):
    """Curate samples, transcribe with Whisper, generate A & B clips."""

    if not RECORDINGS_MANIFEST.exists():
        print(f"ERROR: {RECORDINGS_MANIFEST} not found.")
        print("Run record_audio.py first to capture training references.")
        return False

    with open(RECORDINGS_MANIFEST, "r", encoding="utf-8") as f:
        all_entries = json.load(f)
    print(f"Loaded {len(all_entries)} training recordings from manifest.")

    # Validate voice list
    voices = args.voices.split(",") if args.voices else ["young_woman", "boy"]
    if args.all_voices:
        voices = list(VOICE_CHARACTERS.keys())
    voices = [v.strip() for v in voices if v.strip()]
    bad = [v for v in voices if v not in VOICE_CHARACTERS]
    if bad:
        print(f"ERROR: unknown voice(s): {bad}")
        print(f"Valid: {list(VOICE_CHARACTERS.keys())}")
        return False
    print(f"Voices: {', '.join(voices)}")

    # Curate diverse sample
    samples = _curate_samples(all_entries, args.samples)
    print(f"\nCurated {len(samples)} diverse samples covering buckets:")
    bucket_counts = {}
    for _, bks in samples:
        for b in bks:
            if b in TARGET_BUCKETS:
                bucket_counts[b] = bucket_counts.get(b, 0) + 1
    for b in TARGET_BUCKETS:
        print(f"  {b:18s} {bucket_counts.get(b, 0):2d}")
    uncovered = [b for b in TARGET_BUCKETS if b not in bucket_counts]
    if uncovered:
        print(f"  ! Uncovered: {uncovered}")

    # Make output dirs
    for d in (GROUND_TRUTH_DIR, DEFAULT_DIR, OVERRIDE_DIR, TEMP_DIR):
        d.mkdir(parents=True, exist_ok=True)
    for v in voices:
        (DEFAULT_DIR / v).mkdir(parents=True, exist_ok=True)
        (OVERRIDE_DIR / v).mkdir(parents=True, exist_ok=True)

    # Process each sample
    sample_records = []
    print()
    for i, (entry, buckets) in enumerate(samples, 1):
        key = entry["key"]
        awing = entry["awing"]
        english = entry.get("english", "")
        wav_src = PROJECT_ROOT / entry["wav_path"]

        print(f"[{i}/{len(samples)}] {key}  ({awing}, '{english}')")
        print(f"    buckets: {[b for b in buckets if b in TARGET_BUCKETS]}")

        # Copy ground truth
        gt_dst = GROUND_TRUTH_DIR / f"{key}.wav"
        if not gt_dst.exists() or args.force:
            if wav_src.exists():
                shutil.copy2(wav_src, gt_dst)
            else:
                print(f"    ! Source WAV missing: {wav_src}")
                continue

        # Whisper transcription
        override = None
        whisper_raw = None
        if args.force or not any(
            (OVERRIDE_DIR / v / f"{key}.mp3").exists() for v in voices
        ):
            print(f"    → Whisper(language='sw', model='{args.whisper_model}', no prompt)...")
            whisper_raw, override = _whisper_transcribe(
                gt_dst, awing=awing, model_name=args.whisper_model)
            if whisper_raw:
                print(f"    Whisper raw:    '{whisper_raw}'")
            if override and override != whisper_raw:
                print(f"    Override (Swahili-safe): '{override}'")
            elif override:
                print(f"    Override:       '{override}'")
            else:
                print(f"    ! Whisper produced no override (will skip B clips)")
        else:
            # Re-load from existing manifest if available
            if SAMPLES_MANIFEST.exists():
                with open(SAMPLES_MANIFEST, "r", encoding="utf-8") as f:
                    prev = json.load(f)
                for r in prev.get("samples", []):
                    if r["key"] == key:
                        override = r.get("override")
                        whisper_raw = r.get("whisper_raw")
                        break

        # Generate A & B for each voice
        default_text = awing_to_speakable(awing)
        print(f"    A (default mapping): '{default_text}'")
        if override:
            print(f"    B (override):        '{override}'")

        if args.force or not all(
            (DEFAULT_DIR / v / f"{key}.mp3").exists() for v in voices
        ) or (override and not all(
            (OVERRIDE_DIR / v / f"{key}.mp3").exists() for v in voices
        )):
            a_results, b_results, _ = asyncio.run(
                _generate_pair(awing, override, voices, key)
            )
            for v in voices:
                a = "✓" if a_results.get(v) else "✗"
                b = "✓" if b_results.get(v) else "—"
                print(f"      {v:14s} A={a}  B={b}")
        else:
            print(f"    (skipped — clips already exist; use --force to regenerate)")

        sample_records.append({
            "key": key,
            "awing": awing,
            "english": english,
            "buckets": [b for b in buckets if b in TARGET_BUCKETS],
            "default_speakable": default_text,
            "whisper_raw": whisper_raw,
            "override": override,
            "ground_truth_wav": str(gt_dst.relative_to(SPOT_CHECK_DIR)).replace(
                os.sep, "/"),
            "wav_duration_s": entry.get("duration_s"),
        })

    # Save manifest
    manifest = {
        "version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "voices": voices,
        "whisper_model": args.whisper_model,
        "samples": sample_records,
    }
    SAMPLES_MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False),
                                encoding="utf-8")
    print(f"\nManifest written: {SAMPLES_MANIFEST}")

    # Emit HTML
    cmd_html(args)
    return True


# ---------------------------------------------------------------------------
# Subcommand: html
# ---------------------------------------------------------------------------

HTML_TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>A/B Spot-Check — Whisper-Override vs Default</title>
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    max-width: 1400px;
    margin: 0 auto;
    padding: 24px;
    background: #f7f8fa;
    color: #1a1a1a;
  }
  h1 { margin: 0 0 8px 0; font-size: 28px; }
  .subtitle { color: #555; margin-bottom: 8px; font-size: 14px; }
  .hint {
    background: #fff7ed;
    border-left: 4px solid #f97316;
    padding: 12px 16px;
    margin: 16px 0;
    border-radius: 4px;
    font-size: 14px;
  }
  .sample {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 16px 20px;
    margin: 16px 0;
    box-shadow: 0 1px 2px rgba(0,0,0,0.04);
  }
  .sample-header {
    display: flex;
    align-items: baseline;
    gap: 16px;
    margin-bottom: 8px;
  }
  .awing { font-size: 24px; font-weight: 600; color: #0f172a; }
  .english { color: #64748b; font-size: 16px; }
  .key {
    font-family: monospace;
    color: #94a3b8;
    font-size: 12px;
    margin-left: auto;
  }
  .buckets {
    margin: 4px 0 12px 0;
    font-size: 12px;
    color: #6b7280;
  }
  .bucket-tag {
    display: inline-block;
    background: #f1f5f9;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 2px 8px;
    margin-right: 4px;
  }
  .ground-truth {
    background: #ecfdf5;
    border: 1px solid #d1fae5;
    border-radius: 6px;
    padding: 8px 12px;
    margin-bottom: 12px;
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .ground-truth-label {
    font-weight: 600;
    color: #047857;
    font-size: 13px;
    min-width: 110px;
  }
  .voice-row {
    display: grid;
    grid-template-columns: 110px 1fr 1fr 140px;
    gap: 12px;
    align-items: center;
    padding: 8px 0;
    border-top: 1px solid #f1f5f9;
  }
  .voice-name {
    font-weight: 600;
    font-size: 13px;
    color: #334155;
  }
  .clip-cell {
    display: flex;
    flex-direction: column;
    gap: 4px;
    background: #fafafa;
    padding: 8px;
    border-radius: 4px;
  }
  .clip-label {
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: #64748b;
  }
  .clip-text {
    font-family: monospace;
    font-size: 11px;
    color: #475569;
  }
  audio { width: 100%; height: 32px; }
  .stars {
    display: flex;
    gap: 2px;
  }
  .star {
    cursor: pointer;
    font-size: 16px;
    color: #d1d5db;
    transition: color 0.1s;
    user-select: none;
  }
  .star.active { color: #f59e0b; }
  .star:hover { color: #fbbf24; }
  .pref {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }
  .pref-label {
    font-size: 11px;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  .pref-buttons {
    display: flex;
    gap: 4px;
  }
  .pref-btn {
    flex: 1;
    padding: 6px 4px;
    border: 1px solid #d1d5db;
    background: white;
    border-radius: 4px;
    cursor: pointer;
    font-size: 11px;
    transition: all 0.1s;
  }
  .pref-btn:hover { background: #f3f4f6; }
  .pref-btn.selected.a { background: #dbeafe; border-color: #3b82f6; color: #1e40af; }
  .pref-btn.selected.tie { background: #f3f4f6; border-color: #6b7280; color: #374151; }
  .pref-btn.selected.b { background: #fed7aa; border-color: #ea580c; color: #9a3412; }
  .summary {
    position: sticky;
    top: 16px;
    background: white;
    border: 2px solid #1e293b;
    border-radius: 8px;
    padding: 16px;
    margin-bottom: 24px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }
  .summary h2 { margin: 0 0 12px 0; font-size: 18px; }
  .summary-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }
  .summary-cell {
    padding: 12px;
    background: #f8fafc;
    border-radius: 6px;
    text-align: center;
  }
  .summary-cell .label {
    font-size: 11px;
    color: #64748b;
    text-transform: uppercase;
  }
  .summary-cell .value {
    font-size: 24px;
    font-weight: 700;
    margin-top: 4px;
  }
  .a-color { color: #1e40af; }
  .b-color { color: #ea580c; }
  .tie-color { color: #6b7280; }
  .reset-btn {
    padding: 8px 16px;
    background: #ef4444;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 13px;
    margin-top: 12px;
  }
  .reset-btn:hover { background: #dc2626; }
  .verdict {
    margin-top: 12px;
    padding: 12px;
    border-radius: 6px;
    font-size: 14px;
    text-align: center;
    font-weight: 600;
  }
  .verdict.b-wins { background: #fed7aa; color: #9a3412; }
  .verdict.a-wins { background: #dbeafe; color: #1e40af; }
  .verdict.unclear { background: #f3f4f6; color: #374151; }
</style>
</head>
<body>

<h1>A/B Spot-Check — Whisper Override vs Default Mapping</h1>
<div class="subtitle">
  Generated: __GENERATED_AT__ · Voices: __VOICES__ · Whisper model: __WHISPER_MODEL__
</div>

<div class="hint">
  <b>Goal:</b> Decide whether Whisper-derived override strings reliably beat
  the default <code>awing_to_speakable()</code> mapping for the 6 Edge TTS
  voices. Listen to the green ground-truth recording first, then rate A
  and B on a 5-star scale, then vote which sounds closer to the reference.
  Your ratings persist in browser localStorage.
</div>

<div class="summary" id="summary">
  <h2>Aggregate</h2>
  <div class="summary-grid">
    <div class="summary-cell">
      <div class="label">Avg ★ — A (default)</div>
      <div class="value a-color" id="avg-a">—</div>
    </div>
    <div class="summary-cell">
      <div class="label">Avg ★ — B (override)</div>
      <div class="value b-color" id="avg-b">—</div>
    </div>
    <div class="summary-cell">
      <div class="label">Override-wins ratio</div>
      <div class="value b-color" id="ratio">—</div>
    </div>
  </div>
  <div class="summary-grid" style="margin-top:8px">
    <div class="summary-cell">
      <div class="label">A wins</div>
      <div class="value a-color" id="a-wins">0</div>
    </div>
    <div class="summary-cell">
      <div class="label">Tie</div>
      <div class="value tie-color" id="tie-count">0</div>
    </div>
    <div class="summary-cell">
      <div class="label">B wins</div>
      <div class="value b-color" id="b-wins">0</div>
    </div>
  </div>
  <div class="verdict" id="verdict">Rate at least 3 samples to see a verdict.</div>
  <button class="reset-btn" onclick="resetAll()">Reset all ratings</button>
</div>

<div id="samples">__SAMPLE_BLOCKS__</div>

<script>
const STORAGE_KEY = "awing_ab_spot_check_v1";
const SAMPLES = __SAMPLES_JSON__;
const VOICES = __VOICES_JSON__;

function loadState() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}");
  } catch {
    return {};
  }
}

function saveState(state) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function setStars(key, voice, side, n) {
  const state = loadState();
  state[key] = state[key] || {};
  state[key][voice] = state[key][voice] || {};
  state[key][voice][side] = n;
  saveState(state);
  renderStars(key, voice, side, n);
  updateSummary();
}

function setPref(key, voice, choice) {
  const state = loadState();
  state[key] = state[key] || {};
  state[key][voice] = state[key][voice] || {};
  state[key][voice].pref = choice;
  saveState(state);
  renderPref(key, voice, choice);
  updateSummary();
}

function renderStars(key, voice, side, n) {
  const container = document.querySelector(
    `[data-key="${key}"][data-voice="${voice}"][data-side="${side}"]`);
  if (!container) return;
  container.querySelectorAll(".star").forEach((s, i) => {
    s.classList.toggle("active", i < n);
  });
}

function renderPref(key, voice, choice) {
  const buttons = document.querySelectorAll(
    `.pref-btn[data-key="${key}"][data-voice="${voice}"]`);
  buttons.forEach(btn => {
    btn.classList.toggle("selected",
      btn.dataset.choice === choice);
    btn.classList.remove("a", "tie", "b");
    if (btn.dataset.choice === choice) {
      btn.classList.add(choice);
    }
  });
}

function updateSummary() {
  const state = loadState();
  let aSum = 0, aCount = 0, bSum = 0, bCount = 0;
  let aWins = 0, ties = 0, bWins = 0;
  for (const key in state) {
    for (const voice in state[key]) {
      const r = state[key][voice];
      if (typeof r.a === "number") { aSum += r.a; aCount++; }
      if (typeof r.b === "number") { bSum += r.b; bCount++; }
      if (r.pref === "a") aWins++;
      else if (r.pref === "tie") ties++;
      else if (r.pref === "b") bWins++;
    }
  }
  const avgA = aCount ? (aSum / aCount).toFixed(2) : "—";
  const avgB = bCount ? (bSum / bCount).toFixed(2) : "—";
  document.getElementById("avg-a").textContent = avgA;
  document.getElementById("avg-b").textContent = avgB;
  document.getElementById("a-wins").textContent = aWins;
  document.getElementById("tie-count").textContent = ties;
  document.getElementById("b-wins").textContent = bWins;
  const totalVotes = aWins + ties + bWins;
  const ratio = totalVotes
    ? ((bWins / totalVotes) * 100).toFixed(0) + "%"
    : "—";
  document.getElementById("ratio").textContent = ratio;
  const verdict = document.getElementById("verdict");
  verdict.classList.remove("b-wins", "a-wins", "unclear");
  if (totalVotes < 3) {
    verdict.textContent = "Rate at least 3 samples to see a verdict.";
    verdict.classList.add("unclear");
  } else if (bWins > aWins * 1.5 && bWins >= totalVotes * 0.5) {
    verdict.textContent =
      `Override path WINS (${bWins}/${totalVotes}). Proceed to full pipeline.`;
    verdict.classList.add("b-wins");
  } else if (aWins > bWins * 1.5) {
    verdict.textContent =
      `Default mapping wins (${aWins}/${totalVotes}). DO NOT migrate; investigate why.`;
    verdict.classList.add("a-wins");
  } else {
    verdict.textContent =
      `Mixed results (A=${aWins}, tie=${ties}, B=${bWins}). Override path is not a clear win.`;
    verdict.classList.add("unclear");
  }
}

function resetAll() {
  if (!confirm("Clear ALL ratings? This cannot be undone.")) return;
  localStorage.removeItem(STORAGE_KEY);
  document.querySelectorAll(".star.active").forEach(s =>
    s.classList.remove("active"));
  document.querySelectorAll(".pref-btn.selected").forEach(b => {
    b.classList.remove("selected", "a", "tie", "b");
  });
  updateSummary();
}

// Restore state on load
document.addEventListener("DOMContentLoaded", () => {
  const state = loadState();
  for (const key in state) {
    for (const voice in state[key]) {
      const r = state[key][voice];
      if (typeof r.a === "number") renderStars(key, voice, "a", r.a);
      if (typeof r.b === "number") renderStars(key, voice, "b", r.b);
      if (r.pref) renderPref(key, voice, r.pref);
    }
  }
  updateSummary();
});
</script>

</body>
</html>
"""


def _build_sample_block(sample, voices):
    """Build the HTML block for one sample."""
    key = sample["key"]
    awing = sample["awing"]
    english = sample.get("english", "")
    buckets = sample.get("buckets", [])
    default_text = sample.get("default_speakable", "")
    override = sample.get("override") or ""
    gt_path = sample.get("ground_truth_wav", "")

    bucket_tags = "".join(
        f'<span class="bucket-tag">{b}</span>' for b in buckets
    )

    voice_rows = []
    for v in voices:
        cfg = VOICE_CHARACTERS[v]
        a_path = f"_default/{v}/{key}.mp3"
        b_path = f"_override/{v}/{key}.mp3"
        b_disabled = "disabled" if not override else ""
        b_label_text = override if override else "(no override available)"

        stars_a = "".join(
            f'<span class="star" onclick="setStars(\'{key}\', \'{v}\', \'a\', {i+1})">★</span>'
            for i in range(5)
        )
        stars_b = "".join(
            f'<span class="star" onclick="setStars(\'{key}\', \'{v}\', \'b\', {i+1})">★</span>'
            for i in range(5)
        )

        voice_rows.append(f'''
      <div class="voice-row">
        <div class="voice-name">{cfg["description"]}<br><small>{v}</small></div>
        <div class="clip-cell">
          <div class="clip-label">A · default mapping</div>
          <audio controls preload="none" src="{a_path}"></audio>
          <div class="clip-text">"{default_text}"</div>
          <div class="stars" data-key="{key}" data-voice="{v}" data-side="a">{stars_a}</div>
        </div>
        <div class="clip-cell">
          <div class="clip-label">B · Whisper override</div>
          <audio controls preload="none" src="{b_path}"></audio>
          <div class="clip-text">"{b_label_text}"</div>
          <div class="stars" data-key="{key}" data-voice="{v}" data-side="b">{stars_b}</div>
        </div>
        <div class="pref">
          <div class="pref-label">Which is closer to the recording?</div>
          <div class="pref-buttons">
            <button class="pref-btn" data-key="{key}" data-voice="{v}" data-choice="a"
              onclick="setPref('{key}', '{v}', 'a')">A</button>
            <button class="pref-btn" data-key="{key}" data-voice="{v}" data-choice="tie"
              onclick="setPref('{key}', '{v}', 'tie')">Tie</button>
            <button class="pref-btn" data-key="{key}" data-voice="{v}" data-choice="b"
              onclick="setPref('{key}', '{v}', 'b')" {b_disabled}>B</button>
          </div>
        </div>
      </div>''')

    return f'''
  <div class="sample">
    <div class="sample-header">
      <span class="awing">{awing}</span>
      <span class="english">{english}</span>
      <span class="key">{key}</span>
    </div>
    <div class="buckets">{bucket_tags}</div>
    <div class="ground-truth">
      <span class="ground-truth-label">Ground truth ↓</span>
      <audio controls preload="none" src="{gt_path}" style="flex:1"></audio>
    </div>
{"".join(voice_rows)}
  </div>'''


def cmd_html(args):
    """Re-emit the HTML rating page from manifest.json."""
    if not SAMPLES_MANIFEST.exists():
        print(f"ERROR: {SAMPLES_MANIFEST} not found. Run 'setup' first.")
        return False

    with open(SAMPLES_MANIFEST, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    voices = manifest.get("voices", ["young_woman", "boy"])
    samples = manifest.get("samples", [])

    sample_blocks = "\n".join(_build_sample_block(s, voices) for s in samples)

    html = HTML_TEMPLATE.replace("__GENERATED_AT__", manifest.get("generated_at", ""))
    html = html.replace("__VOICES__", ", ".join(voices))
    html = html.replace("__WHISPER_MODEL__", manifest.get("whisper_model", "small"))
    html = html.replace("__SAMPLE_BLOCKS__", sample_blocks)
    html = html.replace("__SAMPLES_JSON__", json.dumps(samples, ensure_ascii=False))
    html = html.replace("__VOICES_JSON__", json.dumps(voices))

    HTML_OUT.write_text(html, encoding="utf-8")
    print(f"\nRating page emitted: {HTML_OUT}")
    print(f"\nOpen in browser:")
    if sys.platform == "win32":
        print(f"   start {HTML_OUT}")
    elif sys.platform == "darwin":
        print(f"   open {HTML_OUT}")
    else:
        print(f"   xdg-open {HTML_OUT}")
    return True


# ---------------------------------------------------------------------------
# Subcommand: status
# ---------------------------------------------------------------------------

def cmd_status(args):
    """Print file counts at each stage."""
    print(f"Spot-check directory: {SPOT_CHECK_DIR}")
    print()
    if not SPOT_CHECK_DIR.exists():
        print("  (not initialized — run 'setup')")
        return True

    gt = list(GROUND_TRUTH_DIR.glob("*.wav")) if GROUND_TRUTH_DIR.exists() else []
    print(f"  Ground-truth WAVs:  {len(gt)}")

    if SAMPLES_MANIFEST.exists():
        with open(SAMPLES_MANIFEST, "r", encoding="utf-8") as f:
            manifest = json.load(f)
        voices = manifest.get("voices", [])
        n_samples = len(manifest.get("samples", []))
        n_with_override = sum(1 for s in manifest["samples"] if s.get("override"))
        print(f"  Samples in manifest:{n_samples}  (with override: {n_with_override})")
        print(f"  Voices:             {', '.join(voices)}")
        print(f"  Whisper model:      {manifest.get('whisper_model', 'unknown')}")
        for v in voices:
            a = list((DEFAULT_DIR / v).glob("*.mp3")) if (DEFAULT_DIR / v).exists() else []
            b = list((OVERRIDE_DIR / v).glob("*.mp3")) if (OVERRIDE_DIR / v).exists() else []
            print(f"    {v:14s} A (default): {len(a):2d}  B (override): {len(b):2d}")
    else:
        print("  (no manifest yet — run 'setup')")

    if HTML_OUT.exists():
        print(f"  HTML page:          {HTML_OUT}")
    else:
        print(f"  HTML page:          (not generated — run 'setup' or 'html')")
    return True


# ---------------------------------------------------------------------------
# Subcommand: clean
# ---------------------------------------------------------------------------

def cmd_clean(args):
    """Remove generated A/B clips. With --deep, also remove ground-truth + manifest."""
    removed = 0
    if DEFAULT_DIR.exists():
        shutil.rmtree(DEFAULT_DIR); removed += 1; print(f"  Removed {DEFAULT_DIR}")
    if OVERRIDE_DIR.exists():
        shutil.rmtree(OVERRIDE_DIR); removed += 1; print(f"  Removed {OVERRIDE_DIR}")
    if HTML_OUT.exists():
        HTML_OUT.unlink(); removed += 1; print(f"  Removed {HTML_OUT}")
    if args.deep:
        if GROUND_TRUTH_DIR.exists():
            shutil.rmtree(GROUND_TRUTH_DIR); removed += 1
            print(f"  Removed {GROUND_TRUTH_DIR}")
        if SAMPLES_MANIFEST.exists():
            SAMPLES_MANIFEST.unlink(); removed += 1
            print(f"  Removed {SAMPLES_MANIFEST}")
        if SPOT_CHECK_DIR.exists() and not any(SPOT_CHECK_DIR.iterdir()):
            SPOT_CHECK_DIR.rmdir()
            print(f"  Removed empty {SPOT_CHECK_DIR}")
    if TEMP_DIR.exists():
        shutil.rmtree(TEMP_DIR); removed += 1; print(f"  Removed {TEMP_DIR}")
    if removed == 0:
        print("  (nothing to clean)")
    return True


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    p = argparse.ArgumentParser(
        description="A/B spot-check: Whisper-override vs default mapping for Edge TTS",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = p.add_subparsers(dest="command", required=True)

    setup = sub.add_parser("setup",
        help="Curate samples, transcribe with Whisper, generate A & B clips, emit HTML")
    setup.add_argument("--samples", type=int, default=15,
        help="Number of words to sample (default: 15)")
    setup.add_argument("--voices", default=None,
        help="Comma-separated voice IDs (default: young_woman,boy). "
             f"Valid: {','.join(VOICE_CHARACTERS.keys())}")
    setup.add_argument("--all-voices", action="store_true",
        help="Use all 6 voices (overrides --voices)")
    setup.add_argument("--whisper-model", default="small",
        help="Whisper model size: tiny, base, small (default), medium, large")
    setup.add_argument("--force", action="store_true",
        help="Re-run Whisper and regenerate all clips")

    html = sub.add_parser("html",
        help="Re-emit spotcheck.html from existing manifest.json")

    status = sub.add_parser("status",
        help="Show file counts at each stage")

    clean = sub.add_parser("clean",
        help="Remove generated A/B clips")
    clean.add_argument("--deep", action="store_true",
        help="Also remove ground-truth + manifest")

    args = p.parse_args()
    handlers = {
        "setup": cmd_setup,
        "html": cmd_html,
        "status": cmd_status,
        "clean": cmd_clean,
    }
    ok = handlers[args.command](args)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
