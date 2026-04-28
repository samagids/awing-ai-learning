#!/usr/bin/env python3
"""Generate the app's Awing audio bank using Qwen3-TTS-VoiceDesign.

Path A — no training. Uses the already-cached
Qwen3-TTS-12Hz-1.7B-VoiceDesign checkpoint + the 6 voice-design
prompts you locked in via the smoke test (voice_prompts.json).

Pipeline per clip:
  Awing text  ─►  awing_to_portuguese()  ─►  VoiceDesign synth(voice prompt)
                                              └──► WAV ─► (ffmpeg) ─► MP3

Output goes to the Play Asset Delivery install-time pack the app
already reads from:
    android/install_time_assets/src/main/assets/audio/{voice}/{category}/{key}.mp3

Voices vs. content (matches generate_audio_edge.py's level filter):
    boy, girl                 -> alphabet, vocab(diff=1), phrases, sentences
    young_man, young_woman    -> alphabet, vocab(diff<=2), phrases, sentences
    man, woman                -> alphabet, sentences, stories (no vocab)

Usage:
    python3 scripts/ml/tts/generate_awing_voicedesign.py --test
        # 5 test phrases per voice — listen first before full run

    python3 scripts/ml/tts/generate_awing_voicedesign.py
        # Generate everything for all 6 voices.

    python3 scripts/ml/tts/generate_awing_voicedesign.py --voices boy girl
        # Subset of voices.

    python3 scripts/ml/tts/generate_awing_voicedesign.py --max 50
        # Cap N clips per voice (for partial runs / iteration).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import unicodedata
from pathlib import Path
from typing import Iterator

import warnings
warnings.filterwarnings("ignore", message=".*torch_dtype.*")

REPO_ROOT = Path(__file__).resolve().parents[3]
VOICE_PROMPTS = REPO_ROOT / "scripts" / "ml" / "tts" / "voice_prompts.json"
VOCAB_DART = REPO_ROOT / "lib" / "data" / "awing_vocabulary.dart"
ALPHABET_DART = REPO_ROOT / "lib" / "data" / "awing_alphabet.dart"
TONES_DART = REPO_ROOT / "lib" / "data" / "awing_tones.dart"

# Output mirrors the PAD asset pack the Flutter app reads from at runtime.
PAD_ROOT = REPO_ROOT / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio"

MODEL_ID = "Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign"

# Level filter — which voices generate which content categories. Matches
# the per-difficulty level the app surfaces each voice in.
VOICE_LEVELS = {
    "boy":          {"level": 1, "categories": ("alphabet", "vocabulary", "phrases", "sentences")},
    "girl":         {"level": 1, "categories": ("alphabet", "vocabulary", "phrases", "sentences")},
    "young_man":    {"level": 2, "categories": ("alphabet", "vocabulary", "phrases", "sentences")},
    "young_woman":  {"level": 2, "categories": ("alphabet", "vocabulary", "phrases", "sentences")},
    "man":          {"level": 3, "categories": ("alphabet", "sentences", "stories")},
    "woman":        {"level": 3, "categories": ("alphabet", "sentences", "stories")},
}


# ============================================================
# Phonemizer
# ============================================================

# Awing-special characters → Portuguese-spelled approximations.
# Portuguese has the closest phoneme inventory match to Awing among
# Qwen3-TTS's 10 supported languages:
#   /ɛ/ in Awing -> 'é' in Portuguese (open e, e.g. "café")
#   /ɔ/ in Awing -> 'ó' in Portuguese (open o, e.g. "vovó")
#   /ə/ in Awing -> 'a' in unstressed BR Portuguese (e.g. final 'a' in "casa")
#   /ɣ/ in Awing -> intervocalic 'g' has [ɣ] allophone in casual PT speech
# We strip lexical tone diacritics; Qwen3's prosody fills in via the
# voice-design prompt's described tone/rhythm. Awing tones become
# untranscribed prosodic shape, which is the documented limitation.

# Multi-character clusters mapped to Portuguese spellings BEFORE the
# single-char substitutions, so we don't accidentally double-up:
# e.g. ŋg as a prenasalized cluster is ONE sound; without this
# special-case, ŋ→ng would produce 'ngg' (n + g + g).
_AWING_DIGRAPHS = {
    "ŋg": "ng",   # prenasalized voiced velar stop (one sound)
    "ŋk": "nk",   # prenasalized voiceless velar stop (one sound)
    "Ŋg": "Ng", "Ŋk": "Nk",
}

_AWING_TO_PT = {
    "ɛ": "é", "Ɛ": "É",
    "ɔ": "ó", "Ɔ": "Ó",
    "ə": "a", "Ə": "A",
    "ɨ": "i", "Ɨ": "I",
    "ŋ": "ng", "Ŋ": "Ng",
    "ɣ": "g",  "Ɣ": "G",
    # Curly quotes / glottal stops: replaced with hyphen so PT engine
    # inserts a brief pause rather than ignoring or vocalising the char.
    "'": "-", "’": "-", "‘": "-",
}

_TONE_DIACRITICS = {
    "́",  # combining acute  (high tone)
    "̀",  # combining grave  (low tone)
    "̂",  # combining circumflex (falling)
    "̌",  # combining caron (rising)
    "̄",  # combining macron (mid-long)
}


def awing_to_portuguese(text: str) -> str:
    """Convert Awing orthography to a Portuguese-spelled phonetic form
    that Qwen3-TTS-VoiceDesign with language='Portuguese' can read.

    Order matters:
      1. Decompose to NFD and strip lexical tone diacritics.
         (We do this BEFORE substitution so that the acute we introduce
         when mapping ɛ→é doesn't get stripped along with tone marks.)
      2. Recompose to NFC.
      3. Multi-character cluster substitutions (ŋg, ŋk) — must run
         BEFORE single-char substitutions to avoid double-g, double-k.
      4. Single-character substitutions (ɛ ɔ ə ɨ ŋ ɣ + apostrophes).
      5. Whitespace cleanup.
    """
    if not text:
        return text

    # 1+2: strip lexical tone diacritics
    decomp = unicodedata.normalize("NFD", text)
    decomp = "".join(c for c in decomp if c not in _TONE_DIACRITICS)
    s = unicodedata.normalize("NFC", decomp)

    # 3: digraph substitutions
    for src, dst in _AWING_DIGRAPHS.items():
        s = s.replace(src, dst)

    # 4: single-character substitutions
    out = []
    for ch in s:
        out.append(_AWING_TO_PT.get(ch, ch))
    s = "".join(out)

    # 5: whitespace cleanup
    s = re.sub(r"\s+", " ", s).strip()
    return s


def _smoke_test_phonemizer():
    """Quick sanity test — call this with --test-phonemizer."""
    cases = [
        ("apô", "apo"),
        ("ŋgóonɛ́", "ngoone"),     # actually after tone strip: "ngoone" — but ɛ -> é stays
        ("kɨ́'ə", "ki-a"),
        ("Móonə", "Moona"),
        ("Ghǒ ghɛnɔ́ lə əfó?", "Gho ghénó la afó?"),
        ("Lɛ̌ ndzaŋ pətǎ", "Lé ndzang pata"),
        ("ndě", "nde"),
    ]
    print("Phonemizer test:")
    for inp, expected in cases:
        got = awing_to_portuguese(inp)
        mark = "OK" if got == expected else "??"
        print(f"  [{mark}] {inp!r:24s} -> {got!r:24s}  (expected {expected!r})")
    print("Note: 'expected' values are illustrative; perfect match isn't required.")
    print("Listen to the synthesised output, not the spellings.")


# ============================================================
# Content extraction from Dart source files
# ============================================================

def _audio_key(awing: str) -> str:
    """ASCII-safe filename from Awing text. Mirrors PronunciationService
    in the Flutter app so generated files are read at runtime."""
    s = unicodedata.normalize("NFD", awing)
    s = "".join(c for c in s if c not in _TONE_DIACRITICS)
    s = unicodedata.normalize("NFC", s)
    s = (s.replace("ɛ", "e").replace("ɔ", "o").replace("ə", "e")
           .replace("ɨ", "i").replace("ŋ", "ng").replace("ɣ", "g")
           .replace("'", "").replace("’", "").replace("‘", ""))
    s = re.sub(r"[^a-zA-Z0-9_-]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s.lower() or "_"


def _read_dart(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _parse_alphabet(text: str) -> list[dict]:
    """Extract AwingLetter(...) entries with awing + english fields."""
    entries = []
    pattern = re.compile(
        r"AwingLetter\(\s*letter:\s*['\"]([^'\"]+)['\"][^)]*?"
        r"exampleWord:\s*['\"]([^'\"]+)['\"][^)]*?"
        r"exampleEnglish:\s*['\"]([^'\"]+)['\"]",
        re.DOTALL,
    )
    for m in pattern.finditer(text):
        letter, awing, eng = m.group(1), m.group(2), m.group(3)
        entries.append({"letter": letter, "awing": awing, "english": eng})
    return entries


def _parse_vocab(text: str) -> list[dict]:
    """Extract AwingWord(awing: ..., english: ..., difficulty: ..., category: ...)."""
    entries = []
    pattern = re.compile(
        r"AwingWord\(\s*awing:\s*(['\"])((?:\\.|(?!\1).)*)\1[^)]*?"
        r"english:\s*(['\"])((?:\\.|(?!\3).)*)\3"
        r"(?:[^)]*?difficulty:\s*(\d))?"
        r"(?:[^)]*?category:\s*['\"]?(\w+)['\"]?)?",
        re.DOTALL,
    )
    for m in pattern.finditer(text):
        entries.append({
            "awing": m.group(2).replace("\\'", "'").replace('\\"', '"'),
            "english": m.group(4).replace("\\'", "'").replace('\\"', '"'),
            "difficulty": int(m.group(5)) if m.group(5) else 1,
            "category": m.group(6) or "general",
        })
    return entries


def _parse_phrases(text: str) -> list[dict]:
    """Extract AwingPhrase(awing: ..., english: ...)."""
    entries = []
    pattern = re.compile(
        r"AwingPhrase\(\s*awing:\s*(['\"])((?:\\.|(?!\1).)*)\1[^)]*?"
        r"english:\s*(['\"])((?:\\.|(?!\3).)*)\3",
        re.DOTALL,
    )
    for m in pattern.finditer(text):
        entries.append({
            "awing": m.group(2).replace("\\'", "'").replace('\\"', '"'),
            "english": m.group(4).replace("\\'", "'").replace('\\"', '"'),
        })
    return entries


def _build_content_index(test_mode: bool) -> dict[str, list[dict]]:
    """Build per-category lists of {awing, english, key, ...} entries
    that need audio.
    """
    index: dict[str, list[dict]] = {
        "alphabet": [],
        "vocabulary": [],
        "phrases": [],
        "sentences": [],
        "stories": [],
    }

    if test_mode:
        # Small mixed set for quick listening — covers all the
        # linguistically tricky buckets (gh, ɛ, ɔ, prenasalized, tones).
        sample = [
            ("alphabet", {"awing": "apô", "english": "hand"}),
            ("alphabet", {"awing": "əshûə", "english": "fish"}),
            ("vocabulary", {"awing": "Móonə", "english": "baby"}),
            ("vocabulary", {"awing": "ŋgóonɛ́", "english": "snail"}),
            ("phrases", {"awing": "Ghǒ ghɛnɔ́ lə əfó?", "english": "Where are you going?"}),
        ]
        for cat, e in sample:
            e["key"] = _audio_key(e["awing"])
            e["difficulty"] = 1
            index[cat].append(e)
        return index

    # Full extraction
    alpha_text = _read_dart(ALPHABET_DART)
    for e in _parse_alphabet(alpha_text):
        e["key"] = _audio_key(e["awing"])
        e["difficulty"] = 1
        index["alphabet"].append(e)

    vocab_text = _read_dart(VOCAB_DART)
    for e in _parse_vocab(vocab_text):
        e["key"] = _audio_key(e["awing"])
        index["vocabulary"].append(e)
    # Phrases also live in the vocabulary file.
    for e in _parse_phrases(vocab_text):
        e["key"] = _audio_key(e["awing"])
        e["difficulty"] = 1
        index["phrases"].append(e)

    return index


# ============================================================
# Audio generation
# ============================================================

def _wav_to_mp3(wav_path: Path, mp3_path: Path) -> bool:
    """Convert WAV to MP3 via ffmpeg. Returns True on success."""
    try:
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error",
             "-i", str(wav_path), "-codec:a", "libmp3lame",
             "-qscale:a", "2", str(mp3_path)],
            check=True, capture_output=True,
        )
        return True
    except Exception as e:
        print(f"    ffmpeg error: {e}")
        return False


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--voices", nargs="+", default=None,
                    help="Voices to generate (default: all 6).")
    ap.add_argument("--test", action="store_true",
                    help="Generate a small mixed test set per voice for "
                         "quick listening (5 phrases). Output goes to "
                         "models/qwen3_voicedesign_test/{voice}/.")
    ap.add_argument("--test-phonemizer", action="store_true",
                    help="Just print phonemizer test cases and exit.")
    ap.add_argument("--max", type=int, default=0,
                    help="Cap clips per voice (0 = no cap).")
    ap.add_argument("--keep-wav", action="store_true",
                    help="Keep intermediate WAV files alongside MP3s.")
    args = ap.parse_args()

    if args.test_phonemizer:
        _smoke_test_phonemizer()
        return 0

    if not VOICE_PROMPTS.exists():
        print(f"ERROR: voice_prompts.json missing: {VOICE_PROMPTS}")
        return 1
    voice_cfg = json.loads(VOICE_PROMPTS.read_text(encoding="utf-8"))
    all_voices = voice_cfg["voice_order"]
    voices = args.voices or all_voices

    for v in voices:
        if v not in voice_cfg["voices"]:
            print(f"ERROR: unknown voice '{v}'. Known: {all_voices}")
            return 1

    # --- Build content index ----------------------------------------
    print("Indexing app content...")
    content = _build_content_index(test_mode=args.test)
    for cat, entries in content.items():
        print(f"  {cat}: {len(entries)} entries")
    print()

    # --- Load model -------------------------------------------------
    print(f"Loading {MODEL_ID} on GPU...")
    import torch
    if not torch.cuda.is_available():
        print("ERROR: CUDA not available.")
        return 1

    os.environ.setdefault("COQUI_TOS_AGREED", "1")
    from qwen_tts import Qwen3TTSModel
    qwen3tts = Qwen3TTSModel.from_pretrained(
        MODEL_ID,
        dtype=torch.bfloat16,
        attn_implementation="sdpa",
        device_map="cuda:0",
    )
    print(f"Model loaded. VRAM: {torch.cuda.memory_allocated() / 1e9:.1f} GB\n")

    import soundfile as sf

    # --- Generate per voice -----------------------------------------
    grand_total, grand_success = 0, 0
    for voice in voices:
        vinfo = voice_cfg["voices"][voice]
        instruct = vinfo["instruct"]
        level_info = VOICE_LEVELS[voice]
        cats = level_info["categories"]
        max_diff = level_info["level"]

        # Output dir: PAD pack for real runs, scratch dir for test mode
        if args.test:
            voice_out_root = REPO_ROOT / "models" / "qwen3_voicedesign_test" / voice
        else:
            voice_out_root = PAD_ROOT / voice
        voice_out_root.mkdir(parents=True, exist_ok=True)

        print(f"[{voice}] level={max_diff} cats={cats}")
        print(f"  Output: {voice_out_root}")
        print(f"  Voice prompt: {instruct[:80]}{'...' if len(instruct) > 80 else ''}")

        # Build the per-voice work list, applying difficulty filter
        # for the vocabulary category.
        work: list[tuple[str, dict]] = []
        for cat in cats:
            for e in content[cat]:
                if cat == "vocabulary" and e.get("difficulty", 1) > max_diff:
                    continue
                work.append((cat, e))
        if args.max and len(work) > args.max:
            work = work[: args.max]

        v_total, v_success, v_skip = 0, 0, 0
        for cat, entry in work:
            v_total += 1
            cat_dir = voice_out_root / cat
            cat_dir.mkdir(parents=True, exist_ok=True)
            mp3_path = cat_dir / f"{entry['key']}.mp3"
            wav_path = cat_dir / f"{entry['key']}.wav"

            # Skip if MP3 already exists (idempotent re-runs).
            if mp3_path.exists() and not args.test:
                v_skip += 1
                continue

            spoken = awing_to_portuguese(entry["awing"])
            if not spoken:
                continue

            try:
                wavs, sr = qwen3tts.generate_voice_design(
                    text=spoken,
                    language="Portuguese",
                    instruct=instruct,
                )
                sf.write(str(wav_path), wavs[0], sr)
                if _wav_to_mp3(wav_path, mp3_path):
                    v_success += 1
                    if not args.keep_wav:
                        wav_path.unlink(missing_ok=True)
                else:
                    print(f"    WAV->MP3 failed for {entry['key']}")
            except Exception as e:
                msg = str(e)[:100]
                print(f"    FAIL {cat}/{entry['key']}: {type(e).__name__}: {msg}")

            if v_total % 50 == 0:
                vram = torch.cuda.memory_allocated() / 1e9
                print(f"    [{voice}] {v_total} / {len(work)} "
                      f"(success {v_success}, skip {v_skip}, vram {vram:.1f} GB)")

        grand_total += v_total
        grand_success += v_success
        print(f"  [{voice}] DONE: {v_success}/{v_total} success "
              f"({v_skip} skipped, already cached)")
        print()

    print("=" * 60)
    print(f"Grand total: {grand_success}/{grand_total} clips generated")
    print(f"Output root: {PAD_ROOT if not args.test else REPO_ROOT / 'models' / 'qwen3_voicedesign_test'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
