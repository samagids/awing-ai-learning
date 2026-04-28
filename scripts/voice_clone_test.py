"""
Voice clone test — F5-TTS with native Awing reference speaker.

Tests Option 2 from Session 52 strategy: zero-shot voice cloning. F5-TTS
(Meta/Xiaohongshu 2024, flow-matching, 95K training hours) is strongest
open-source zero-shot cloner. We give it a clip of a native Awing speaker
(from the Awing Jesus Film WAV) and ask it to say 15 diagnostic words.

Honest expectation: voice cloning clones the SPEAKER timbre, not the
LANGUAGE phoneme inventory. F5-TTS was trained on English + Chinese, so
`ŋgóonɛ́` will still go through its English tokenizer (via
awing_to_speakable — same normalization as the shipping Swahili pipeline).
The *voice* will sound like an Awing speaker but the *pronunciation* will
still be a Swahili/English approximation of Awing.

What we're actually testing: does the timbre swap alone make the result
feel more "Awing-like" to ears that know the language? If yes, swap F5-TTS
in as the Swahili baseline replacement. If not, the ceiling of automated
TTS for Awing is genuinely reached and we fall back to Option 1 (record
native speakers directly) or Option 3 (fine-tune).

Pipeline:
  1. Extract a wide window (default 120s) from Awing Jesus Film WAV
  2. Strip silences + trim to ~15s of dense continuous speech
     (F5-TTS prefers short clips but needs them densely populated;
     a raw 10s grab from the film is mostly silence)
  3. Transcribe reference via Whisper (language='sw' — closest trained
     Bantu relative; output is approximate but sufficient for alignment)
  4. Install F5-TTS if missing
  5. For each of 15 diagnostic words:
     gen_text = awing_to_speakable(awing_text)
     F5-TTS(ref_audio, ref_text, gen_text) -> WAV
  6. Emit HTML for side-by-side listening

Install prerequisites (one-time):
    venv\\Scripts\\pip install f5-tts openai-whisper

Usage:
    python scripts/voice_clone_test.py                  # full run
    python scripts/voice_clone_test.py --ref-start 60   # start ref at 60s
    python scripts/voice_clone_test.py --reference PATH --ref-text "..."
    python scripts/voice_clone_test.py --html           # regen HTML only
    python scripts/voice_clone_test.py --clean
"""

import argparse
import os
import shutil
import sys
import unicodedata
from pathlib import Path


# ============================================================
# Venv auto-activation
# ============================================================
def _ensure_venv():
    if sys.prefix != sys.base_prefix:
        return
    script_dir = Path(__file__).resolve().parent
    venv_python = script_dir.parent / "venv" / "Scripts" / "python.exe"
    if not venv_python.exists():
        venv_python = script_dir.parent / "venv" / "bin" / "python"
    if not venv_python.exists():
        print("venv not found. Run scripts\\install_dependencies.bat first.")
        sys.exit(1)
    if os.path.abspath(str(venv_python)) == os.path.abspath(sys.executable):
        return
    import subprocess
    result = subprocess.run([str(venv_python), __file__, *sys.argv[1:]])
    sys.exit(result.returncode)


_ensure_venv()


# ============================================================
# Paths & config
# ============================================================
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
VIDEOS_DIR = REPO_ROOT / "videos"
OUT_DIR = SCRIPT_DIR / "_voice_clone_test"
REF_DIR = OUT_DIR / "_reference"
F5_DIR = OUT_DIR / "f5"

DEFAULT_SOURCE_WAV = VIDEOS_DIR / "Awing Jesus Film @Readandwriteawing.wav"


# ============================================================
# Diagnostic words — same 15 as Session 52 MMS listening test
# ============================================================
DIAGNOSTIC_WORDS = [
    ("tátə",     "father",       "high tone + schwa"),
    ("ndé",      "neck / water", "prenasalized nd + high tone"),
    ("ghǒ",      "you",          "/ɣ/ (gh) + rising tone"),
    ("aghô",     "tree",         "/ɣ/ (gh) + falling tone"),
    ("mbɛ́'tə́", "palm wine",    "mb + ɛ + glottal + schwa + high tones"),
    ("ŋgóonɛ́", "pepper",        "ŋg cluster + long vowel + ɛ"),
    ("kwɨ̌tə́",  "to move",       "labialized kw + ɨ + rising + high"),
    ("pɔ̀ŋɔ́",  "they",          "ɔ + low tone + ŋ + high tone"),
    ("yǐə",     "come",          "palatal + diphthong + rising"),
    ("Móonə",   "child",         "long vowel + schwa"),
    ("nkǐə",    "river",         "nk + rising + diphthong"),
    ("apô",     "hand",          "basic + falling tone"),
    ("nəpe",    "belly",         "initial schwa + pe"),
    ("Lǒ",      "Get out!",      "L + rising tone"),
    ("ntúa'ɔ",  "calabash",      "nt + diphthong + glottal + ɔ"),
]


# ============================================================
# Text normalization — matches production generate_audio_edge.py
# ============================================================
def awing_to_speakable(text: str) -> str:
    nfd = unicodedata.normalize("NFD", text)
    stripped = "".join(c for c in nfd if not unicodedata.combining(c))
    s = (stripped
         .replace("ɛ", "e").replace("Ɛ", "E")
         .replace("ɔ", "o").replace("Ɔ", "O")
         .replace("ə", "e").replace("Ə", "E")
         .replace("ɨ", "i").replace("Ɨ", "I"))
    s = s.replace("ŋg", "ngg").replace("Ŋg", "Ngg")
    s = s.replace("ŋk", "nk").replace("Ŋk", "Nk")
    s = s.replace("ŋ",  "ng").replace("Ŋ",  "Ng")
    s = s.replace("gh", "g").replace("Gh", "G")
    for q in ("'", "\u2019", "\u2018", "`"):
        s = s.replace(q, "")
    return s.strip()


def audio_key(text: str) -> str:
    nfd = unicodedata.normalize("NFD", text)
    ascii_base = "".join(c for c in nfd if not unicodedata.combining(c))
    ascii_base = (ascii_base
                  .replace("ɛ", "e").replace("Ɛ", "E")
                  .replace("ɔ", "o").replace("Ɔ", "O")
                  .replace("ə", "e").replace("Ə", "E")
                  .replace("ɨ", "i").replace("Ɨ", "I")
                  .replace("ŋ", "ng").replace("Ŋ", "Ng"))
    safe = "".join(c if c.isalnum() else "_" for c in ascii_base)
    while "__" in safe:
        safe = safe.replace("__", "_")
    return safe.strip("_").lower()


# ============================================================
# Step 1: Extract reference audio segment
# ============================================================
def _run_ffmpeg(cmd: list) -> tuple:
    """Run ffmpeg, return (ok, stderr)."""
    import subprocess
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        return (result.returncode == 0, result.stderr)
    except FileNotFoundError:
        return (False, "ffmpeg not found. Install: winget install Gyan.FFmpeg")


def extract_reference(source_wav: Path, start_sec: float, window_sec: float,
                      target_sec: float, out_path: Path,
                      raw_path: Path = None) -> bool:
    """
    Extract a dense-speech reference clip from source WAV.

    Strategy:
      1. Pull a `window_sec` slice starting at `start_sec` (e.g., 120s)
      2. Strip silences with ffmpeg silenceremove filter
      3. Trim the cleaned stream to `target_sec` (e.g., 15s)

    F5-TTS prefers short references (5-30s) but they must be densely
    populated with speech. A raw grab from the Jesus Film at any offset
    typically contains long pauses. Silence-stripping-then-trimming
    gives F5-TTS the dense speech chunk it actually needs.

    Output: mono 24kHz 16-bit PCM (F5-TTS native format).
    """
    if not source_wav.exists():
        print(f"  ✗ Source WAV not found: {source_wav}")
        return False
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # Step 1a: extract the wide window to a temp file
    if raw_path is None:
        raw_path = out_path.parent / "reference_raw.wav"
    cmd1 = [
        "ffmpeg", "-y", "-loglevel", "error",
        "-ss", str(start_sec),
        "-i", str(source_wav),
        "-t", str(window_sec),
        "-ac", "1",
        "-ar", "24000",
        "-sample_fmt", "s16",
        str(raw_path),
    ]
    ok, err = _run_ffmpeg(cmd1)
    if not ok:
        print(f"  ✗ Window extraction failed: {err}")
        return False
    if not raw_path.exists() or raw_path.stat().st_size < 1000:
        print(f"  ✗ Window extraction produced empty output")
        return False
    print(f"    Pulled {window_sec}s window -> {raw_path.name} "
          f"({raw_path.stat().st_size // 1024} KB)")

    # Step 1b: strip silences + trim to target length
    # silenceremove params:
    #   stop_periods=-1      remove ALL silent regions (not just leading)
    #   stop_duration=0.4    treat gaps >0.4s as silence
    #   stop_threshold=-35dB anything quieter is silence
    # atrim=duration=15       cap output at target_sec after compression
    filt = (
        f"silenceremove=stop_periods=-1:stop_duration=0.4:"
        f"stop_threshold=-35dB,atrim=duration={target_sec},asetpts=PTS-STARTPTS"
    )
    cmd2 = [
        "ffmpeg", "-y", "-loglevel", "error",
        "-i", str(raw_path),
        "-af", filt,
        "-ac", "1",
        "-ar", "24000",
        "-sample_fmt", "s16",
        str(out_path),
    ]
    ok, err = _run_ffmpeg(cmd2)
    if not ok:
        print(f"  ✗ Silence strip failed: {err}")
        return False
    if not out_path.exists() or out_path.stat().st_size < 1000:
        print(f"  ✗ Silence-stripped output is empty (window too quiet?)")
        return False

    # Report actual duration of cleaned clip (diagnostic)
    import subprocess
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(out_path)],
        capture_output=True, text=True,
    )
    try:
        dur = float(probe.stdout.strip())
        print(f"    Stripped silences -> {out_path.name} "
              f"({dur:.1f}s of continuous speech)")
    except (ValueError, AttributeError):
        print(f"    Stripped silences -> {out_path.name}")

    return True


# ============================================================
# Step 2: Transcribe reference with Whisper
# ============================================================
def transcribe_reference(ref_wav: Path, language: str = "sw") -> str:
    """
    Transcribe via Whisper. Awing is not in Whisper's supported languages;
    'sw' (Swahili) is the closest trained Bantu relative — produces rough
    phonetic approximation that's adequate for F5-TTS alignment.
    """
    try:
        import whisper
    except ImportError:
        print("  ✗ openai-whisper not installed.")
        print("    Install: venv\\Scripts\\pip install openai-whisper")
        return ""

    print(f"  Loading Whisper (base model, language={language})... ",
          end="", flush=True)
    model = whisper.load_model("base")
    print("ok")

    print("  Transcribing reference... ", end="", flush=True)
    result = model.transcribe(str(ref_wav), language=language, fp16=False)
    text = result.get("text", "").strip()
    print(f"'{text}'")
    return text


# ============================================================
# Step 3: F5-TTS generation
# ============================================================
_F5_INSTANCE = None


def get_f5():
    global _F5_INSTANCE
    if _F5_INSTANCE is not None:
        return _F5_INSTANCE
    try:
        from f5_tts.api import F5TTS
    except ImportError:
        print("  ✗ f5-tts not installed.")
        print("    Install: venv\\Scripts\\pip install f5-tts")
        print("    First run will download the model (~1.3 GB)")
        return None

    print("  Loading F5-TTS model (downloads ~1.3 GB on first run)... ",
          end="", flush=True)
    _F5_INSTANCE = F5TTS()
    print("ok")
    return _F5_INSTANCE


def generate_f5(ref_audio: Path, ref_text: str, gen_text: str,
                out_path: Path) -> bool:
    f5 = get_f5()
    if f5 is None:
        return False
    out_path.parent.mkdir(parents=True, exist_ok=True)
    # F5-TTS API kwargs vary by version. Build the call defensively:
    # newer versions dropped `file_spect`. We pass the minimal stable set
    # and fall back to positional if the kwarg names changed.
    kwargs = dict(
        ref_file=str(ref_audio),
        ref_text=ref_text,
        gen_text=gen_text,
        file_wave=str(out_path),
        remove_silence=True,
        speed=0.9,          # slightly slower for learner clarity
    )
    try:
        f5.infer(**kwargs)
        return out_path.exists() and out_path.stat().st_size > 1000
    except TypeError as e:
        # Older/newer API — try with just the four required positional args
        try:
            f5.infer(str(ref_audio), ref_text, gen_text,
                     file_wave=str(out_path))
            return out_path.exists() and out_path.stat().st_size > 1000
        except Exception as e2:
            print(f"    F5-TTS failed for {gen_text!r}: {e2}")
            return False
    except Exception as e:
        print(f"    F5-TTS failed for {gen_text!r}: {e}")
        return False


# ============================================================
# Step 4: HTML emission
# ============================================================
def emit_html(ref_text: str, ref_audio_rel: str):
    out_html = OUT_DIR / "index.html"

    rows = []
    for awing, english, features in DIAGNOSTIC_WORDS:
        key = audio_key(awing)
        speakable = awing_to_speakable(awing)
        f5_rel = f"f5/{key}.wav"
        if (OUT_DIR / f5_rel).exists():
            player = (f'<audio controls preload="none" src="{f5_rel}"></audio>'
                      f'<div class="speakable">&quot;{speakable}&quot;</div>')
        else:
            player = '<span class="missing">—</span>'

        # Link to Swahili baseline from the earlier MMS listening test if
        # it exists (side-by-side reference point)
        swh_rel = f"../_mms_listening/swh/{key}.mp3"
        if (SCRIPT_DIR / "_mms_listening" / "swh" / f"{key}.mp3").exists():
            swh_player = (f'<audio controls preload="none" src="{swh_rel}">'
                          f'</audio>')
        else:
            swh_player = '<span class="missing">— (run mms_listening_test first)</span>'

        rows.append(f"""
        <tr>
          <td class="word"><span class="awing">{awing}</span>
              <div class="english">{english}</div></td>
          <td class="features">{features}</td>
          <td>{player}</td>
          <td>{swh_player}</td>
        </tr>
        """)

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>F5-TTS voice clone test — native Awing reference</title>
<style>
  body {{ font-family: -apple-system, Segoe UI, Roboto, sans-serif;
    max-width: 1200px; margin: 2em auto; padding: 0 1em; color: #222; }}
  h1 {{ margin-bottom: 0.2em; }}
  .subtitle {{ color: #666; margin-bottom: 1.5em; }}
  table {{ border-collapse: collapse; width: 100%; }}
  th, td {{ padding: 8px 10px; border-bottom: 1px solid #e0e0e0;
    vertical-align: middle; }}
  th {{ background: #f5f5f5; text-align: left; }}
  .word .awing {{ font-size: 1.4em; font-weight: 600; }}
  .word .english {{ color: #666; font-size: 0.85em; margin-top: 2px; }}
  .features {{ font-size: 0.85em; color: #555; width: 200px; }}
  .missing {{ color: #ccc; font-style: italic; }}
  audio {{ width: 220px; }}
  .speakable {{ font-size: 0.75em; color: #999; margin-top: 2px;
    font-family: monospace; }}
  .legend {{ background: #fffbe6; border-left: 3px solid #f0c040;
    padding: 10px 16px; margin: 1em 0; }}
  .legend h3 {{ margin: 0 0 0.5em 0; font-size: 1em; }}
  .reference {{ background: #eef; padding: 10px 16px; margin: 1em 0;
    border-left: 3px solid #88a; }}
  .reference audio {{ width: 400px; }}
</style>
</head>
<body>

<h1>F5-TTS voice clone test</h1>
<div class="subtitle">
  Session 52 · Option 2 — Zero-shot voice cloning with native Awing
  speaker reference (Awing Jesus Film).
</div>

<div class="reference">
  <h3>Reference speaker (source for voice clone)</h3>
  <audio controls src="{ref_audio_rel}"></audio>
  <div style="font-family:monospace; margin-top:6px; font-size:0.9em;">
    Transcription (Whisper-sw approximation): &ldquo;{ref_text}&rdquo;
  </div>
</div>

<div class="legend">
  <h3>What to listen for</h3>
  <p>F5-TTS clones the <em>speaker's voice</em> but uses its own
  (English-trained) phoneme inventory. So the <strong>timbre</strong>
  should sound like the reference Awing speaker, while the
  <strong>pronunciation</strong> still goes through the same
  <code>awing_to_speakable()</code> transform the Swahili baseline uses.
  </p>
  <p>Judgment call per row: does the Awing-speaker timbre make the
  approximation feel closer to real Awing than the Swahili voice did?
  Or is timbre irrelevant when the phonemes are still wrong?</p>
  <p>If F5-TTS sounds noticeably better on most rows → swap it in as the
  baseline. If not → Option 2 is also dead; escalate to Option 3
  (fine-tune VITS on Awing Jesus Film).</p>
</div>

<table>
  <thead>
    <tr>
      <th>Word</th>
      <th>Features</th>
      <th>F5-TTS clone<br><span style="font-weight:normal; color:#666; font-size:0.85em">
        (native Awing voice)</span></th>
      <th>Swahili baseline<br><span style="font-weight:normal; color:#666; font-size:0.85em">
        (current production)</span></th>
    </tr>
  </thead>
  <tbody>
  {''.join(rows)}
  </tbody>
</table>

<p style="margin-top:2em; color:#999; font-size:0.85em;">
Generated {len(DIAGNOSTIC_WORDS)} words via F5-TTS zero-shot cloning.
Text normalization: <code>awing_to_speakable()</code> from production
<code>generate_audio_edge.py</code> (same transform Swahili baseline uses).
</p>

</body>
</html>
"""
    out_html.write_text(html, encoding="utf-8")
    print(f"\n✓ HTML written: {out_html}")
    print(f"  Open in browser: file:///{out_html.as_posix()}")


# ============================================================
# Main
# ============================================================
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", type=str, default=None,
                        help="Path to reference WAV (10 sec mono)")
    parser.add_argument("--ref-text", type=str, default=None,
                        help="Transcription of reference audio")
    parser.add_argument("--source", type=str, default=str(DEFAULT_SOURCE_WAV),
                        help=f"Source WAV for auto-extract "
                             f"(default: Awing Jesus Film)")
    parser.add_argument("--ref-start", type=float, default=180.0,
                        help="Reference extract start (sec) — default 180s "
                             "skips opening/title cards")
    parser.add_argument("--ref-window", type=float, default=120.0,
                        help="Source window to mine for speech (sec). "
                             "Default 120s — covers enough talk so "
                             "silence stripping yields a usable clip.")
    parser.add_argument("--ref-target", type=float, default=15.0,
                        help="Final reference length after silence "
                             "removal (sec). F5-TTS prefers 5-30s of "
                             "DENSE speech; default 15s.")
    # Backwards-compat alias
    parser.add_argument("--ref-duration", type=float, default=None,
                        help="(deprecated) alias for --ref-window")
    parser.add_argument("--html", action="store_true",
                        help="Regenerate HTML only")
    parser.add_argument("--clean", action="store_true",
                        help="Remove output dir")
    args = parser.parse_args()

    if args.clean:
        if OUT_DIR.exists():
            shutil.rmtree(OUT_DIR)
            print(f"Removed {OUT_DIR}")
        return

    if args.html:
        if not OUT_DIR.exists():
            print("No output dir yet. Run without --html first.")
            sys.exit(1)
        ref_wav = REF_DIR / "reference.wav"
        ref_txt = REF_DIR / "reference.txt"
        ref_text = ref_txt.read_text(encoding="utf-8") if ref_txt.exists() else ""
        emit_html(ref_text, f"_reference/reference.wav")
        return

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REF_DIR.mkdir(parents=True, exist_ok=True)

    print("=" * 72)
    print("F5-TTS Voice Clone Test — native Awing reference")
    print("=" * 72)

    # --------------------------------------------------------
    # Step 1: Get reference audio
    # --------------------------------------------------------
    print("\n[1/4] Reference audio")
    ref_wav = REF_DIR / "reference.wav"

    if args.reference:
        src = Path(args.reference).resolve()
        if not src.exists():
            print(f"  ✗ Reference file not found: {src}")
            sys.exit(1)
        shutil.copy(src, ref_wav)
        print(f"  Using provided reference: {src}")
    else:
        source_wav = Path(args.source)
        # Honor deprecated --ref-duration alias if provided
        window_sec = args.ref_duration if args.ref_duration else args.ref_window
        print(f"  Mining {window_sec}s window from {source_wav.name} "
              f"(start @ {args.ref_start}s)")
        print(f"  Target: {args.ref_target}s of dense speech after "
              f"silence removal")
        raw_path = REF_DIR / "reference_raw.wav"
        if not extract_reference(source_wav, args.ref_start,
                                 window_sec, args.ref_target,
                                 ref_wav, raw_path=raw_path):
            print("  ✗ Reference extraction failed")
            print("  Try a different --ref-start, or pass your own clip:")
            print("    python scripts/voice_clone_test.py "
                  "--reference <your.wav> --ref-text '...'")
            sys.exit(1)
        print(f"  ✓ Reference ready: {ref_wav}")

    # --------------------------------------------------------
    # Step 2: Transcription
    # --------------------------------------------------------
    print("\n[2/4] Reference transcription")
    ref_txt_path = REF_DIR / "reference.txt"
    if args.ref_text:
        ref_text = args.ref_text
        print(f"  Using provided: '{ref_text}'")
    else:
        ref_text = transcribe_reference(ref_wav, language="sw")
        if not ref_text:
            print("  ✗ Transcription failed. Provide --ref-text manually.")
            sys.exit(1)
    ref_txt_path.write_text(ref_text, encoding="utf-8")

    # --------------------------------------------------------
    # Step 3: F5-TTS generation
    # --------------------------------------------------------
    print("\n[3/4] F5-TTS generation")
    F5_DIR.mkdir(parents=True, exist_ok=True)

    # Touch F5 instance once before the loop (so model-load log is clean)
    if get_f5() is None:
        print("  ✗ F5-TTS unavailable. Aborting.")
        sys.exit(1)

    ok = 0
    for awing, english, _ in DIAGNOSTIC_WORDS:
        key = audio_key(awing)
        gen_text = awing_to_speakable(awing)
        out = F5_DIR / f"{key}.wav"
        print(f"  {awing:12s} ({english:15s}) -> {gen_text!r} ... ",
              end="", flush=True)
        if generate_f5(ref_wav, ref_text, gen_text, out):
            print("ok")
            ok += 1
        else:
            print("FAIL")
    print(f"  {ok}/{len(DIAGNOSTIC_WORDS)} clips generated")

    # --------------------------------------------------------
    # Step 4: HTML
    # --------------------------------------------------------
    print("\n[4/4] HTML")
    emit_html(ref_text, "_reference/reference.wav")

    print("\n" + "=" * 72)
    print("Done.")
    print(f"  Reference:  {ref_wav}")
    print(f"  Clips:      {F5_DIR}")
    print(f"  HTML:       {OUT_DIR / 'index.html'}")
    print("=" * 72)


if __name__ == "__main__":
    main()
