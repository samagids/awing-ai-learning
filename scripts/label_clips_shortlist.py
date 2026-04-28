#!/usr/bin/env python3
"""
label_clips_shortlist.py  v1.0.0

Interactive shortlist labeler for Awing training clips.

For each audio clip, the script:
  1. Parses the slide-OCR dump (e.g. "ndona (duck) ako'a (chair pile)
     nko' (bucket) poola (breast wear)") into word/gloss candidates.
  2. Fuzzy-matches each OCR word against the 3,195-word vocabulary in
     lib/data/awing_vocabulary.dart to surface the canonical orthography
     (ɛ, ɔ, ə, ɨ, ŋ, tone diacritics) when available.
  3. Pads with duration-filtered vocabulary entries for backup.
  4. Plays the clip and shows a numbered shortlist — native speaker
     picks the one they hear. Also supports typing a word not on the
     list, deleting a garbage clip, skipping, and save-and-quit.

Output: training_data/labels_curated.json
  { "video\\clips\\clip_0000.wav": {"awing": "ndɔ́nə", "english": "duck",
    "source": "shortlist|ocr|manual", "duration": 0.52}, ... }

This file is the source of truth for VITS fine-tuning — the old
training_data/labels.json contains OCR slide chrome + Whisper
hallucinations and should be ignored.

Usage:
  python scripts/label_clips_shortlist.py                # all short clips
  python scripts/label_clips_shortlist.py --video part_2b # match video name
  python scripts/label_clips_shortlist.py --max-dur 2.5   # length cap (sec)
  python scripts/label_clips_shortlist.py --min-dur 0.3   # length floor (sec)
  python scripts/label_clips_shortlist.py --stats         # progress only
  python scripts/label_clips_shortlist.py --export FILE   # write HF dataset
"""

import argparse
import json
import os
import re
import subprocess
import sys
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path


# ---------------------------------------------------------------------------
# venv auto-activation (same pattern as every other script in this project)
# ---------------------------------------------------------------------------

def _ensure_venv():
    """Re-exec under venv/Scripts/python.exe if not already inside it."""
    if sys.prefix != sys.base_prefix:
        return
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    candidates = [
        os.path.join(project_root, "venv", "Scripts", "python.exe"),
        os.path.join(project_root, "venv", "bin", "python3"),
        os.path.join(project_root, "venv", "bin", "python"),
    ]
    for venv_python in candidates:
        if not os.path.exists(venv_python):
            continue
        if os.path.abspath(venv_python) == os.path.abspath(sys.executable):
            return
        result = subprocess.run([venv_python, __file__] + sys.argv[1:])
        sys.exit(result.returncode)


_ensure_venv()


# sounddevice/soundfile are optional — fall back to a system player
try:
    import sounddevice as sd
    import soundfile as sf
    _HAS_SD = True
except Exception:
    _HAS_SD = False


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

PROJECT = Path(__file__).resolve().parent.parent
CLIPS_ROOT = PROJECT / "training_data" / "clips"
LABELS_FILE = PROJECT / "training_data" / "labels.json"
CURATED_FILE = PROJECT / "training_data" / "labels_curated.json"
VOCAB_DART = PROJECT / "lib" / "data" / "awing_vocabulary.dart"
ALPHABET_DART = PROJECT / "lib" / "data" / "awing_alphabet.dart"


# Videos by content type — used to route candidate generation. Anything not
# listed here defaults to "vocab" (slide-pair / fuzzy-vocab matching).
VIDEO_KIND = {
    # Letter-by-letter alphabet drills. OCR shows the letter glyph itself.
    "How_to_Read_the_Awing_Alphabet": "letter",
    "Awing_alphabet_-_part_1":        "letter",
    # Multi-word slide drills with `word (english)` OCR pairs.
    "Awing_alphabet_-_part_2a":       "vocab",
    "Awing_alphabet_-_part_2b":       "vocab",
    "Lesson_One-_Awing_Alphabet":     "vocab",
    "You_Can_Read_and_Write_Awing":   "vocab",
    # Narration videos — multi-word utterances, English subtitles, no per-clip
    # OCR. Single-word labeling is not meaningful for these clips.
    "Awing_Jesus_Film__Readandwriteawing":            "narration",
    "Invitation_to_Know_Jesus_Personally_Awing_People": "narration",
}


def video_kind(video_name: str) -> str:
    return VIDEO_KIND.get(video_name, "vocab")


# ---------------------------------------------------------------------------
# Awing → ASCII normalization for fuzzy matching
# ---------------------------------------------------------------------------

# Same mapping the app uses for TTS phoneticization.
_SPECIAL_VOWELS = {
    "ɛ": "e", "Ɛ": "E",
    "ɔ": "o", "Ɔ": "O",
    "ə": "e", "Ə": "E",
    "ɨ": "i", "Ɨ": "I",
}
_TONE_COMBINING = set("\u0300\u0301\u0302\u0304\u030c")
_APOS_RE = re.compile(r"[\u2018\u2019\u02bc\u02bb']")


def awing_to_ascii(text: str) -> str:
    """Lowercase ASCII form for SequenceMatcher-style phonetic ranking."""
    if not text:
        return ""
    for src, dst in _SPECIAL_VOWELS.items():
        text = text.replace(src, dst)
    decomposed = unicodedata.normalize("NFD", text)
    stripped = "".join(c for c in decomposed if c not in _TONE_COMBINING)
    stripped = stripped.replace("ŋ", "ng").replace("Ŋ", "Ng")
    stripped = _APOS_RE.sub("", stripped)
    return stripped.lower().strip()


def estimate_syllables(awing_text: str) -> int:
    """Count vowel groups (crude syllable estimate)."""
    ascii_form = awing_to_ascii(awing_text)
    vowels = set("aeiou")
    count = 0
    in_vowel = False
    for c in ascii_form:
        if c in vowels:
            if not in_vowel:
                count += 1
                in_vowel = True
        else:
            in_vowel = False
    return max(1, count)


# Awing isolated-word tempo. Tuned to allow slack for slow classroom speech.
_SYL_DUR_MIN = 0.12
_SYL_DUR_MAX = 0.45


def duration_syllable_range(dur_sec: float) -> tuple[int, int]:
    lo = max(1, int(dur_sec / _SYL_DUR_MAX))
    hi = max(1, int(dur_sec / _SYL_DUR_MIN) + 1)
    return lo, hi


# ---------------------------------------------------------------------------
# Vocabulary loader (parse Dart file for AwingWord literals)
# ---------------------------------------------------------------------------

# Handles both quote styles (awing: '...' or awing: "...")
_AWINGWORD_RE = re.compile(
    r"AwingWord\(\s*"
    r"awing\s*:\s*(['\"])(?P<awing>.+?)\1\s*,\s*"
    r"english\s*:\s*(['\"])(?P<english>.+?)\3",
    re.DOTALL,
)


def load_vocabulary() -> list[dict]:
    if not VOCAB_DART.exists():
        raise RuntimeError(f"Vocabulary file not found: {VOCAB_DART}")
    src = VOCAB_DART.read_text(encoding="utf-8")
    seen = set()
    entries = []
    for m in _AWINGWORD_RE.finditer(src):
        awing = m.group("awing").replace("\\'", "'").strip()
        english = m.group("english").replace("\\'", "'").strip()
        if not awing or not english:
            continue
        key = (awing.lower(), english.lower())
        if key in seen:
            continue
        seen.add(key)
        entries.append({
            "awing": awing,
            "english": english,
            "ascii": awing_to_ascii(awing),
            "syllables": estimate_syllables(awing),
        })
    return entries


# Loose AwingLetter parser — picks up letter, phoneme, exampleWord, English.
# Uses `.+?` inside the captured content with a backreference terminator so
# we correctly parse `exampleWord: "cha'tɔ́"` (single quote inside double-
# quoted string) and vice versa.
_AWINGLETTER_RE = re.compile(
    r"AwingLetter\("
    r"[^)]*?letter\s*:\s*(['\"])(?P<letter>.+?)\1"
    r"[^)]*?phoneme\s*:\s*(['\"])(?P<phoneme>.+?)\3"
    r"[^)]*?exampleWord\s*:\s*(['\"])(?P<example>.+?)\5"
    r"[^)]*?exampleEnglish\s*:\s*(['\"])(?P<exampleEng>.+?)\7",
    re.DOTALL,
)


def load_alphabet() -> list[dict]:
    """Return [{letter, phoneme, example, example_english, ascii}] for letter
    drill videos (How_to_Read, alphabet part 1)."""
    if not ALPHABET_DART.exists():
        return []
    src = ALPHABET_DART.read_text(encoding="utf-8")
    out = []
    seen = set()
    for m in _AWINGLETTER_RE.finditer(src):
        letter = m.group("letter").strip()
        if letter.lower() in seen:
            continue
        seen.add(letter.lower())
        out.append({
            "letter":       letter,
            "phoneme":      m.group("phoneme").strip(),
            "example":      m.group("example").replace("\\'", "'").strip(),
            "example_eng":  m.group("exampleEng").replace("\\'", "'").strip(),
            "ascii":        awing_to_ascii(letter),
        })
    return out


# ---------------------------------------------------------------------------
# OCR slide dump parsing
# ---------------------------------------------------------------------------

# Matches `word (english gloss)` — word must be letters/apostrophes only,
# and the gloss must look like English (spaces + letters, no pptx chrome).
_SLIDE_PAIR_RE = re.compile(
    r"\b([a-zA-Z'][a-zA-Z']{1,25})\s*"
    r"\(([a-zA-Z][^)]{1,80})\)"
)

# Slide chrome tokens we never want to appear as candidates.
_CHROME_TOKENS = {
    "pm", "am", "the", "exit", "phoenix", "files", "alphabet",
    "pptx", "mp4", "wav", "file", "home", "insert", "design",
    "animations", "slide", "show", "view", "help", "image",
}


def parse_slide_dump(dump: str | None) -> list[tuple[str, str]]:
    """Return [(awing_ascii, english_gloss)] pairs from an OCR slide dump."""
    if not dump:
        return []
    pairs = []
    seen = set()
    for m in _SLIDE_PAIR_RE.finditer(dump):
        word = m.group(1).strip()
        gloss = m.group(2).strip()
        if word.lower() in _CHROME_TOKENS:
            continue
        # gloss must contain at least one English-looking word
        if not re.search(r"[a-zA-Z]{2,}", gloss):
            continue
        key = (word.lower(), gloss.lower())
        if key in seen:
            continue
        seen.add(key)
        pairs.append((word, gloss))
    return pairs


# ---------------------------------------------------------------------------
# Candidate ranking
# ---------------------------------------------------------------------------

def score(a: str, b: str) -> float:
    if not a or not b:
        return 0.0
    return SequenceMatcher(None, a, b).ratio()


def build_letter_candidates(
    ocr_dump: str,
    alphabet: list[dict],
) -> list[dict]:
    """For How_to_Read / alphabet-part-1 style clips.

    OCR is typically just the letter glyph shown on screen (e.g. 'ch',
    'e', 'gh'). We surface both the letter as a label (when the clip
    says the letter name) AND the example word, because these drills
    often play both.
    """
    hint = (ocr_dump or "").lower().strip()
    # Strip the few noise chars we see ('&', digits, stray spaces)
    hint = re.sub(r"[^a-zŋɛɔəɨ'\s]", " ", hint).strip()
    hint_tokens = [t for t in hint.split() if len(t) <= 4]

    out = []
    seen = set()
    # 1. Exact-ish hint match first
    for tok in hint_tokens:
        for a in alphabet:
            if a["ascii"] == tok or a["letter"].lower() == tok:
                if a["letter"].lower() in seen:
                    continue
                seen.add(a["letter"].lower())
                out.append({
                    "awing":   a["letter"],
                    "english": f"letter /{a['phoneme']}/",
                    "note":    "letter (from OCR glyph)",
                    "source":  "letter",
                })
                out.append({
                    "awing":   a["example"],
                    "english": a["example_eng"],
                    "note":    f"example for /{a['phoneme']}/",
                    "source":  "letter-example",
                })
    # 2. Padding — show all letters as a fallback menu so the user
    #    can override when OCR is garbled.
    for a in alphabet:
        if len(out) >= 14:
            break
        if a["letter"].lower() in seen:
            continue
        seen.add(a["letter"].lower())
        out.append({
            "awing":   a["letter"],
            "english": f"letter /{a['phoneme']}/  (example: {a['example']})",
            "note":    "letter",
            "source":  "letter",
        })
    return out


def build_candidates(
    dur: float,
    slide_pairs: list[tuple[str, str]],
    vocab: list[dict],
    top_n: int = 10,
) -> list[dict]:
    """Ranked candidate list for one VOCAB-kind clip.

    Priority:
      1. Each OCR slide pair, upgraded to canonical orthography via
         closest vocab match (so `ndona (duck)` → `ndɔnə (duck)` when
         the real form exists in awing_vocabulary.dart).
      2. Duration-filtered vocab entries (fuzzy-ranked against the
         concatenated slide-word ASCII string, when there is one).
    """
    slide_candidates = []
    slide_ascii_terms = []
    for ocr_word, ocr_gloss in slide_pairs:
        ocr_ascii = awing_to_ascii(ocr_word)
        slide_ascii_terms.append(ocr_ascii)
        # Best vocab match for canonical orthography.
        best = None
        best_score = 0.0
        for w in vocab:
            s = score(ocr_ascii, w["ascii"])
            if s > best_score:
                best_score = s
                best = w
        if best and best_score >= 0.75:
            slide_candidates.append({
                "awing": best["awing"],
                "english": best["english"],
                "note": f"slide + vocab ({int(best_score * 100)}%)",
                "source": "slide+vocab",
            })
        else:
            slide_candidates.append({
                "awing": ocr_word,
                "english": ocr_gloss,
                "note": "slide OCR only",
                "source": "slide",
            })

    # De-dupe slide candidates by canonical awing form
    out = []
    seen = set()
    for c in slide_candidates:
        k = c["awing"].lower()
        if k in seen:
            continue
        seen.add(k)
        out.append(c)

    if len(out) >= top_n:
        return out[:top_n]

    # Pad with duration-filtered vocab
    lo, hi = duration_syllable_range(dur)
    lo_soft, hi_soft = max(1, lo - 1), hi + 1
    hint_ascii = " ".join(slide_ascii_terms)
    scored = []
    for w in vocab:
        if not (lo_soft <= w["syllables"] <= hi_soft):
            continue
        if w["awing"].lower() in seen:
            continue
        s = score(hint_ascii, w["ascii"]) if hint_ascii else 0.0
        syl_bonus = 0.1 if lo <= w["syllables"] <= hi else 0.0
        scored.append((s + syl_bonus, w))
    scored.sort(key=lambda x: -x[0])
    for _, w in scored[:top_n - len(out)]:
        out.append({
            "awing": w["awing"],
            "english": w["english"],
            "note": f"vocab / ~{w['syllables']} syl",
            "source": "vocab",
        })
        seen.add(w["awing"].lower())

    return out


# ---------------------------------------------------------------------------
# Clip iteration
# ---------------------------------------------------------------------------

def load_metadata_map() -> dict[str, dict]:
    """Merge all clip_metadata.json files into one dict keyed by clip path.

    Keys use the same `video\\clips\\clip_XXXX.wav` (backslash) style as
    training_data/labels.json, so we can look up Whisper dumps too.
    """
    out = {}
    if not CLIPS_ROOT.exists():
        return out
    for meta in CLIPS_ROOT.glob("*/clip_metadata.json"):
        try:
            entries = json.load(open(meta, encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        video = meta.parent.name
        for entry in entries:
            fname = entry.get("file") or ""
            if not fname:
                continue
            key = f"{video}\\clips\\{fname}"
            out[key] = entry
    return out


def load_whisper_dump_map() -> dict[str, str]:
    """labels.json — despite the name, values are OCR slide dumps, not ASR."""
    if not LABELS_FILE.exists():
        return {}
    try:
        data = json.load(open(LABELS_FILE, encoding="utf-8"))
        return {k: str(v) for k, v in data.items() if v}
    except (json.JSONDecodeError, OSError):
        return {}


def iter_clips(
    video_filter: str | None,
    min_dur: float,
    max_dur: float,
    metadata: dict[str, dict],
):
    """Yield (clip_key, clip_path, video_name, duration, metadata_entry)."""
    if not CLIPS_ROOT.exists():
        return
    for vdir in sorted(CLIPS_ROOT.iterdir()):
        if not vdir.is_dir():
            continue
        video = vdir.name
        if video_filter and video_filter.lower() not in video.lower():
            continue
        clips_dir = vdir / "clips"
        if not clips_dir.exists():
            continue
        for clip_path in sorted(clips_dir.glob("clip_*.wav")):
            key = f"{video}\\clips\\{clip_path.name}"
            m = metadata.get(key, {})
            dur = None
            if "start_sec" in m and "end_sec" in m:
                dur = float(m["end_sec"]) - float(m["start_sec"])
            else:
                try:
                    if _HAS_SD:
                        info = sf.info(str(clip_path))
                        dur = info.frames / info.samplerate
                except Exception:
                    pass
            if dur is None:
                continue
            if not (min_dur <= dur <= max_dur):
                continue
            yield key, clip_path, video, dur, m


# ---------------------------------------------------------------------------
# Audio playback (sounddevice primary, system ffplay fallback)
# ---------------------------------------------------------------------------

def play_clip(path: Path) -> None:
    if _HAS_SD:
        try:
            data, sr = sf.read(str(path), dtype="float32")
            sd.play(data, sr)
            sd.wait()
            return
        except Exception as e:
            print(f"  [sounddevice error: {e}]")
    # Fallback: try ffplay (part of ffmpeg)
    try:
        subprocess.run(
            ["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", str(path)],
            check=False,
        )
    except FileNotFoundError:
        print("  [no audio backend — install sounddevice or ffmpeg]")


# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

def load_curated() -> dict[str, dict]:
    if not CURATED_FILE.exists():
        return {}
    try:
        return json.load(open(CURATED_FILE, encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def save_curated(curated: dict) -> None:
    CURATED_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CURATED_FILE.with_suffix(".json.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(curated, f, ensure_ascii=False, indent=2, sort_keys=True)
    tmp.replace(CURATED_FILE)


# ---------------------------------------------------------------------------
# Interactive session
# ---------------------------------------------------------------------------

def run_labeling(
    video_filter: str | None,
    min_dur: float,
    max_dur: float,
    include_narration: bool = False,
) -> None:
    vocab = load_vocabulary()
    alphabet = load_alphabet()
    metadata = load_metadata_map()
    whisper_dumps = load_whisper_dump_map()
    curated = load_curated()

    clips = list(iter_clips(video_filter, min_dur, max_dur, metadata))
    if not clips:
        print(f"No clips match filter: video={video_filter!r} "
              f"dur=[{min_dur}, {max_dur}]")
        return

    # Drop narration clips unless explicitly opted in — they're multi-word
    # English-subtitled utterances and can't be labeled as single Awing words.
    if not include_narration:
        skipped_narr = sum(1 for c in clips if video_kind(c[2]) == "narration")
        clips = [c for c in clips if video_kind(c[2]) != "narration"]
    else:
        skipped_narr = 0

    total = len(clips)
    remaining = [c for c in clips if c[0] not in curated]
    already_done = total - len(remaining)

    print()
    print("=" * 72)
    print(f"Awing training-clip shortlist labeler")
    print(f"  Clips in range:   {total}")
    print(f"  Already labeled:  {already_done}")
    print(f"  Remaining:        {len(remaining)}")
    print(f"  Vocabulary size:  {len(vocab)}   Alphabet: {len(alphabet)}")
    if skipped_narr:
        print(f"  Skipped (narration, --include-narration to opt in): "
              f"{skipped_narr}")
    print("=" * 72)

    if not remaining:
        print("\nAll clips in range are already labeled. "
              "Use --min-dur/--max-dur to widen.")
        return

    new_this_session = 0

    for i, (key, path, video, dur, meta_entry) in enumerate(remaining, 1):
        kind = video_kind(video)
        # Candidate signals
        ocr_dump = meta_entry.get("ocr_suggestion") or ""
        if str(ocr_dump).lower() == "none":
            ocr_dump = ""
        whisper_dump = whisper_dumps.get(key, "")
        subtitle = meta_entry.get("subtitle_text") or ""
        if str(subtitle).lower() == "none":
            subtitle = ""

        # The labels.json dump is often richer than clip_metadata's single
        # ocr_suggestion — merge both.
        combined_dump = f"{ocr_dump} {whisper_dump}".strip()
        slide_pairs = parse_slide_dump(combined_dump)

        if kind == "letter":
            candidates = build_letter_candidates(combined_dump, alphabet)
        elif kind == "narration":
            # Opt-in: no structured candidates, user types manually.
            candidates = []
        else:
            candidates = build_candidates(dur, slide_pairs, vocab, top_n=10)

        # Header
        print()
        print("=" * 72)
        tag = {"letter": "LETTER DRILL",
               "narration": "NARRATION (multi-word)",
               "vocab": "VOCAB / SLIDE"}.get(kind, "?")
        print(f"[{i}/{len(remaining)}]  {video}   ({tag})")
        print(f"  {path.name}  ({dur:.2f}s)  "
              f"session labeled: {new_this_session}")
        if kind == "narration":
            print(f"  Subtitle (English meaning): {subtitle[:70]!r}")
            print("  Multi-word utterance — use [o] to type the Awing phrase,")
            print("  or [s] to skip. Short single-word clips are rare in this")
            print("  video; most labels here will come from re-segmentation.")
        else:
            if subtitle:
                print(f"  Subtitle:    {subtitle[:70]!r}")
            if ocr_dump:
                print(f"  OCR glyph:   {ocr_dump[:70]!r}")
            if slide_pairs:
                preview = ", ".join(f"{w} ({g[:20]})"
                                     for w, g in slide_pairs[:4])
                more = f" …+{len(slide_pairs) - 4}" if len(slide_pairs) > 4 else ""
                print(f"  Slide words: {preview}{more}")
        print()

        play_clip(path)

        if candidates:
            print("  Candidates:")
            for j, c in enumerate(candidates, 1):
                awing = c["awing"]
                english = c["english"][:45]
                note = c["note"]
                print(f"    {j:2d}. {awing:<22s}  {english:<46s}  [{note}]")
        else:
            print("  (no candidates — OCR empty and vocab ranking produced "
                  "nothing)")

        print()
        print("  [1-N] pick  [r] replay  [o] type Awing  "
              "[s] skip  [d] delete bad clip  [q] save & quit")

        while True:
            try:
                choice = input("  > ").strip().lower()
            except (KeyboardInterrupt, EOFError):
                print()
                save_curated(curated)
                print(f"\nSaved {len(curated)} total labels "
                      f"({new_this_session} this session).")
                return

            if choice == "q":
                save_curated(curated)
                print(f"\nSaved {len(curated)} total labels "
                      f"({new_this_session} this session).")
                return

            if choice == "r":
                play_clip(path)
                continue

            if choice == "s":
                break

            if choice == "d":
                confirm = input("  Delete this clip file? (y/N): ").strip().lower()
                if confirm == "y":
                    try:
                        path.unlink()
                        print(f"  Deleted {path.name}")
                    except OSError as e:
                        print(f"  Delete failed: {e}")
                break

            if choice == "o":
                manual = input("  Awing text (with tones): ").strip()
                if not manual:
                    break
                # Offer canonical lookup
                m_ascii = awing_to_ascii(manual)
                best = None
                best_score = 0.0
                for w in vocab:
                    s = score(m_ascii, w["ascii"])
                    if s > best_score:
                        best_score = s
                        best = w
                english = ""
                if best and best_score >= 0.9 and awing_to_ascii(best["awing"]) == m_ascii:
                    print(f"  Matched vocabulary: {best['awing']} — {best['english']}")
                    use = input("  Use this canonical form? (Y/n): ").strip().lower()
                    if use != "n":
                        manual = best["awing"]
                        english = best["english"]
                if not english:
                    english = input("  English meaning: ").strip()
                curated[key] = {
                    "awing": manual,
                    "english": english,
                    "source": "manual",
                    "duration": round(dur, 3),
                }
                new_this_session += 1
                if new_this_session % 5 == 0:
                    save_curated(curated)
                    print(f"  [auto-saved — {len(curated)} total]")
                break

            if choice.isdigit():
                n = int(choice)
                if 1 <= n <= len(candidates):
                    chosen = candidates[n - 1]
                    curated[key] = {
                        "awing": chosen["awing"],
                        "english": chosen["english"],
                        "source": chosen["source"],
                        "duration": round(dur, 3),
                    }
                    new_this_session += 1
                    if new_this_session % 5 == 0:
                        save_curated(curated)
                        print(f"  [auto-saved — {len(curated)} total]")
                    break

            print("  (invalid — 1-N, r, o, s, d, or q)")

    save_curated(curated)
    print(f"\nFinished. {len(curated)} total labels "
          f"({new_this_session} this session).")


# ---------------------------------------------------------------------------
# Stats / export
# ---------------------------------------------------------------------------

def run_stats(min_dur: float, max_dur: float) -> None:
    metadata = load_metadata_map()
    curated = load_curated()
    print()
    print("=" * 72)
    print(f"Shortlist labeler progress  (dur range: {min_dur}s - {max_dur}s)")
    print("=" * 72)
    per_video_total = {}
    per_video_done = {}
    for key, path, video, dur, _m in iter_clips(None, min_dur, max_dur, metadata):
        per_video_total[video] = per_video_total.get(video, 0) + 1
        if key in curated:
            per_video_done[video] = per_video_done.get(video, 0) + 1
    grand_total = sum(per_video_total.values())
    grand_done = sum(per_video_done.values())
    for v in sorted(per_video_total):
        t = per_video_total[v]
        d = per_video_done.get(v, 0)
        bar_len = 30
        filled = int(bar_len * d / t) if t else 0
        bar = "#" * filled + "." * (bar_len - filled)
        print(f"  {v[:40]:40s}  {d:4d} / {t:4d}  [{bar}]")
    print()
    print(f"  TOTAL                                     {grand_done:4d} / "
          f"{grand_total:4d}  ({100 * grand_done / grand_total:.1f}% done)"
          if grand_total else "  (no clips in range)")
    print()
    if grand_done:
        print("  Recent labels:")
        for k, v in list(curated.items())[-5:]:
            print(f"    {k.split(chr(92))[-1]:24s} {v['awing']:<18s} "
                  f"({v['english'][:30]})")


def run_export(path: Path) -> None:
    curated = load_curated()
    metadata = load_metadata_map()
    rows = []
    for key, label in curated.items():
        video_part, _, clip_name = key.replace("\\", "/").rpartition("/")
        # Normalize to absolute path on disk
        on_disk = CLIPS_ROOT / video_part.split("/")[0] / "clips" / clip_name
        m = metadata.get(key, {})
        rows.append({
            "audio_path": str(on_disk),
            "text": label["awing"],
            "english": label["english"],
            "duration": label["duration"],
            "source": label["source"],
            "subtitle_text": m.get("subtitle_text", ""),
        })
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(rows)} rows to {path}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--video", help="substring filter on video name")
    ap.add_argument("--min-dur", type=float, default=0.3,
                    help="minimum clip duration in seconds (default 0.3)")
    ap.add_argument("--max-dur", type=float, default=2.5,
                    help="maximum clip duration in seconds (default 2.5)")
    ap.add_argument("--stats", action="store_true",
                    help="show progress without labeling")
    ap.add_argument("--export", type=Path,
                    help="export curated labels to a JSON training manifest")
    ap.add_argument("--include-narration", action="store_true",
                    help="include Jesus Film / Invitation clips (off by "
                         "default — these are multi-word utterances with "
                         "English-only subtitles, not single-word drills)")
    args = ap.parse_args()

    if args.stats:
        run_stats(args.min_dur, args.max_dur)
        return
    if args.export:
        run_export(args.export)
        return
    run_labeling(args.video, args.min_dur, args.max_dur,
                 include_narration=args.include_narration)


if __name__ == "__main__":
    main()
