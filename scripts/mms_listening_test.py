"""
Listening test: Makaa (mcp) + Mundani (mnf) vs Swahili (swh) baseline.

Generates 15 diagnostic Awing words through three TTS backends:
  - mcp: Makaa (Meta MMS VITS, 8/9 Awing-essential chars, best scorer)
  - mnf: Mundani (Meta MMS VITS, 7/9, Momo Grassfields family)
  - swh: Current production baseline (Edge TTS Swahili with awing_to_speakable)

Emits an HTML page with side-by-side <audio> players per word so you can
A/B/C compare. Each row annotates which Awing phonological features are
under test (tones, ɛ/ɔ/ə/ɨ, ŋ, prenasalized, gh, palatalized, labialized,
long vowels, diphthongs, glottal stops).

Usage:
    python scripts/mms_listening_test.py           # generate all clips + HTML
    python scripts/mms_listening_test.py --html    # regenerate HTML only
    python scripts/mms_listening_test.py --clean   # remove output dir

Output:
    scripts/_mms_listening/
        mcp/{key}.wav
        mnf/{key}.wav
        swh/{key}.mp3
        index.html           <-- open this in a browser
"""

import asyncio
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
# Diagnostic words — 15 chosen to stress Awing phonology
# ============================================================
# Each entry: (awing_text, english, features_under_test, listen_for)
DIAGNOSTIC_WORDS = [
    ("tátə",     "father",       "high tone + schwa",
     "Clear 'tá' with high pitch, 'tə' with neutral schwa (not 'tah-tuh')"),
    ("ndé",      "neck / water", "prenasalized nd + high tone",
     "Single syllable 'ndé' — NOT 'n-day' or 'en-day'"),
    ("ghǒ",      "you",          "/ɣ/ (gh) + rising tone",
     "Voiced velar fricative (like French 'r'), rising pitch — NOT 'g-h-o'"),
    ("aghô",     "tree",         "/ɣ/ (gh) + falling tone",
     "'a' + fricative + 'ô' with falling pitch — NOT 'a-g-h-oh'"),
    ("mbɛ́'tə́", "palm wine",    "mb + ɛ + glottal stop + schwa + high tones",
     "Open-mid 'ɛ' (like English 'bet'), brief glottal break"),
    ("ŋgóonɛ́", "pepper",        "ŋg cluster + long vowel + ɛ",
     "Velar nasal + g blended, 'oo' held, ends on 'nɛ́' high"),
    ("kwɨ̌tə́",  "to move",       "labialized kw + ɨ + rising + high",
     "'kw' blended, central vowel ɨ (like Russian ы), rising then high"),
    ("pɔ̀ŋɔ́",  "they",          "ɔ + low tone + ŋ + high tone",
     "Open-mid ɔ (like English 'thought'), low-then-high pitch contour"),
    ("yǐə",     "come",          "palatal glide + diphthong + rising",
     "'yə' as single gliding syllable with rising tone — NOT 'yi-uh'"),
    ("Móonə",   "child / baby",  "long vowel + schwa",
     "Held 'oo' (longer than 'Mona'), final schwa not 'ah'"),
    ("nkǐə",    "river / song",  "nk + rising + diphthong",
     "Prenasalized nk, rising tone across ɨə"),
    ("apô",     "hand",          "basic + falling tone",
     "'a-pô' with falling pitch on second syllable"),
    ("nəpe",    "belly",         "initial schwa + pe",
     "Neutral 'nə' (not 'nah'), clear 'pe'"),
    ("Lǒ",      "Get out!",      "L + rising tone (single syllable)",
     "Single rising syllable — good clean tone test"),
    ("ntúa'ɔ",  "calabash",      "nt + diphthong + glottal + ɔ",
     "'ntú-a' as glide, brief glottal, final ɔ (not 'oh')"),
]


# ============================================================
# Paths & config
# ============================================================
SCRIPT_DIR = Path(__file__).resolve().parent
OUT_DIR = SCRIPT_DIR / "_mms_listening"
MODEL_CACHE = SCRIPT_DIR / "_mms_models"  # shared with other MMS scripts

# MMS VITS models to test
MMS_CANDIDATES = [
    ("mcp", "Makaa",    "8/9 Awing-essential chars — all 4 special vowels"),
    ("mnf", "Mundani",  "7/9 Awing-essential chars — Momo Grassfields family"),
]

# Swahili Edge TTS voice for baseline
SWH_VOICE = "sw-KE-ZuriNeural"


# ============================================================
# awing_to_speakable — exact copy from generate_audio_edge.py
# (for fair Swahili baseline comparison)
# ============================================================
def awing_to_speakable(text: str) -> str:
    """Current production transform for Swahili Edge TTS."""
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
    """Filesystem-safe ASCII key (matches Dart _audioKey)."""
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
# MMS VITS generation (via transformers)
# ============================================================
_MMS_CACHE = {}


def _load_mms_model(code: str):
    """Load VitsModel + tokenizer for a given MMS language code."""
    if code in _MMS_CACHE:
        return _MMS_CACHE[code]
    from transformers import VitsModel, AutoTokenizer
    repo = f"facebook/mms-tts-{code}"
    print(f"    Loading {repo}... ", end="", flush=True)
    model = VitsModel.from_pretrained(repo)
    tokenizer = AutoTokenizer.from_pretrained(repo)
    model.eval()
    _MMS_CACHE[code] = (model, tokenizer)
    print("ok")
    return model, tokenizer


def generate_mms(code: str, text: str, out_path: Path) -> bool:
    """Generate WAV via MMS VITS. Returns True on success."""
    try:
        import torch
        import scipy.io.wavfile
        model, tokenizer = _load_mms_model(code)
        inputs = tokenizer(text, return_tensors="pt")
        with torch.no_grad():
            output = model(**inputs).waveform
        waveform = output.numpy()[0]
        sample_rate = model.config.sampling_rate
        out_path.parent.mkdir(parents=True, exist_ok=True)
        scipy.io.wavfile.write(str(out_path), sample_rate, waveform)
        return True
    except Exception as e:
        print(f"    MMS {code} failed for {text!r}: {e}")
        return False


# ============================================================
# Swahili Edge TTS baseline
# ============================================================
async def _generate_swh_one(text: str, out_path: Path) -> bool:
    try:
        import edge_tts
        speakable = awing_to_speakable(text)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        communicate = edge_tts.Communicate(speakable, SWH_VOICE, rate="-20%")
        await communicate.save(str(out_path))
        return True
    except Exception as e:
        print(f"    SWH failed for {text!r}: {e}")
        return False


async def generate_swh_all():
    tasks = []
    for awing, _, _, _ in DIAGNOSTIC_WORDS:
        key = audio_key(awing)
        out = OUT_DIR / "swh" / f"{key}.mp3"
        tasks.append(_generate_swh_one(awing, out))
    results = await asyncio.gather(*tasks)
    return sum(1 for r in results if r), len(results)


# ============================================================
# HTML emission
# ============================================================
def emit_html():
    out_html = OUT_DIR / "index.html"
    rows = []
    for awing, english, features, listen_for in DIAGNOSTIC_WORDS:
        key = audio_key(awing)
        speakable = awing_to_speakable(awing)
        cells = []
        for code, _, _ in MMS_CANDIDATES:
            path = f"{code}/{key}.wav"
            if (OUT_DIR / path).exists():
                cells.append(
                    f'<td><audio controls preload="none" '
                    f'src="{path}"></audio></td>'
                )
            else:
                cells.append('<td class="missing">—</td>')
        # Swahili baseline
        swh_path = f"swh/{key}.mp3"
        if (OUT_DIR / swh_path).exists():
            cells.append(
                f'<td><audio controls preload="none" '
                f'src="{swh_path}"></audio>'
                f'<div class="speakable">&quot;{speakable}&quot;</div></td>'
            )
        else:
            cells.append('<td class="missing">—</td>')

        rows.append(f"""
        <tr>
          <td class="word"><span class="awing">{awing}</span>
              <div class="english">{english}</div></td>
          <td class="features">{features}</td>
          {''.join(cells)}
          <td class="listen-for">{listen_for}</td>
        </tr>
        """)

    header_cells = "".join(
        f'<th>{code}<br><span class="modelname">{name}</span></th>'
        for code, name, _ in MMS_CANDIDATES
    )
    header_cells += (
        '<th>swh<br><span class="modelname">Swahili '
        '(current baseline)</span></th>'
    )

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Awing MMS Listening Test</title>
<style>
  body {{
    font-family: -apple-system, Segoe UI, Roboto, sans-serif;
    max-width: 1400px; margin: 2em auto; padding: 0 1em;
    color: #222;
  }}
  h1 {{ margin-bottom: 0.2em; }}
  .subtitle {{ color: #666; margin-bottom: 1.5em; }}
  table {{ border-collapse: collapse; width: 100%; }}
  th, td {{ padding: 8px 10px; border-bottom: 1px solid #e0e0e0;
    vertical-align: middle; }}
  th {{ background: #f5f5f5; text-align: left; font-size: 0.9em; }}
  th .modelname {{ font-weight: normal; color: #666; font-size: 0.85em; }}
  .word .awing {{ font-size: 1.4em; font-weight: 600; }}
  .word .english {{ color: #666; font-size: 0.85em; margin-top: 2px; }}
  .features {{ font-size: 0.85em; color: #555; width: 180px; }}
  .listen-for {{ font-size: 0.85em; color: #333; font-style: italic;
    width: 300px; }}
  .missing {{ color: #ccc; text-align: center; font-style: italic; }}
  audio {{ width: 200px; }}
  .speakable {{ font-size: 0.75em; color: #999; margin-top: 2px;
    font-family: monospace; }}
  .legend {{ background: #fffbe6; border-left: 3px solid #f0c040;
    padding: 10px 16px; margin: 1em 0; }}
  .legend h3 {{ margin: 0 0 0.5em 0; font-size: 1em; }}
  .legend ul {{ margin: 0; padding-left: 1.2em; }}
  .candidate {{ margin: 0.5em 0; }}
  .candidate strong {{ color: #0a6; }}
</style>
</head>
<body>

<h1>Awing TTS listening test</h1>
<div class="subtitle">
  Session 52 · Path 1 — Compare Meta MMS candidates vs current Swahili
  baseline across 15 diagnostic Awing words.
</div>

<div class="legend">
  <h3>Candidates (from Path 3 tokenizer inspection)</h3>
  <div class="candidate"><strong>mcp</strong> Makaa —
    8/9 Awing-essential chars (all 4 special vowels ɛ ɔ ə ɨ, ŋ, 3/4 tones)
  </div>
  <div class="candidate"><strong>mnf</strong> Mundani —
    7/9 (missing ɛ; has ɔ ə ɨ ŋ, 3/4 tones; Momo Grassfields family)
  </div>
  <div class="candidate"><strong>swh</strong> Swahili (current baseline) —
    0/9 Awing-essential chars; goes through awing_to_speakable() transform
    first (shown in monospace under the player)
  </div>

  <h3 style="margin-top:1em">How to listen</h3>
  <ul>
    <li>Play each row across all three players. Don't compare between
      rows — every word has different features under test.</li>
    <li>Read the "Listen for" column first so you know what to judge.</li>
    <li>Score each model per row: better / same / worse than swh baseline.</li>
    <li>If one MMS model clearly wins on 10+ of 15 rows, swap it in.</li>
    <li>If no clear winner, the best-scoring candidate becomes the
      fine-tuning base for Path 2.</li>
  </ul>
</div>

<table>
  <thead>
    <tr>
      <th>Word</th>
      <th>Features</th>
      {header_cells}
      <th>Listen for</th>
    </tr>
  </thead>
  <tbody>
  {''.join(rows)}
  </tbody>
</table>

<p style="margin-top:2em; color:#999; font-size:0.85em;">
Generated {len(DIAGNOSTIC_WORDS)} words ×
{len(MMS_CANDIDATES) + 1} backends.
MMS clips = WAV (48kHz); swh clips = MP3 via Edge TTS.
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
    args = sys.argv[1:]
    if "--clean" in args:
        if OUT_DIR.exists():
            shutil.rmtree(OUT_DIR)
            print(f"Removed {OUT_DIR}")
        return

    if "--html" in args:
        if not OUT_DIR.exists():
            print("No clips generated yet. Run without --html first.")
            sys.exit(1)
        emit_html()
        return

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print("=" * 72)
    print(f"Awing MMS Listening Test — {len(DIAGNOSTIC_WORDS)} words × "
          f"{len(MMS_CANDIDATES) + 1} backends")
    print("=" * 72)

    # Step 1: MMS candidates
    for code, name, note in MMS_CANDIDATES:
        print(f"\n[{code}] {name} — {note}")
        ok = 0
        for awing, english, _, _ in DIAGNOSTIC_WORDS:
            key = audio_key(awing)
            out = OUT_DIR / code / f"{key}.wav"
            print(f"  {awing:12s} ({english:15s}) -> {key}.wav ... ",
                  end="", flush=True)
            if generate_mms(code, awing, out):
                print("ok")
                ok += 1
            else:
                print("FAIL")
        print(f"  {ok}/{len(DIAGNOSTIC_WORDS)} clips generated for {code}")

    # Step 2: Swahili Edge TTS baseline
    print(f"\n[swh] Swahili baseline (Edge TTS, {SWH_VOICE})")
    print("  using awing_to_speakable() normalization (current production)")
    ok, total = asyncio.run(generate_swh_all())
    print(f"  {ok}/{total} clips generated")

    # Step 3: HTML
    emit_html()

    print("\n" + "=" * 72)
    print("Done. Open scripts\\_mms_listening\\index.html in a browser.")
    print("=" * 72)


if __name__ == "__main__":
    main()
