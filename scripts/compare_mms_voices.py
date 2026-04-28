#!/usr/bin/env python
"""
Compare Meta MMS TTS models for Awing pronunciation.

Generates the same 10 diagnostic Awing words through every available MMS
model (from scripts/probe_mms_languages.py), then emits an HTML page that
lets the developer A/B/C listen side-by-side against the native YouTube
extractions in assets/audio/{alphabet,vocabulary}/.

Usage:
  python scripts\\compare_mms_voices.py                 # full run: all 11 models
  python scripts\\compare_mms_voices.py --codes pny,ybb # subset
  python scripts\\compare_mms_voices.py --clean         # wipe output dir
  python scripts\\compare_mms_voices.py --html-only     # skip generation, just rebuild index.html

Output:
  scripts/_mms_compare/{code}/{key}.wav   per-model synthesized clips
  scripts/_mms_compare/native/{key}.mp3   copied from assets/audio/...
  scripts/_mms_compare/index.html         scoring grid — open in browser

Model cache (managed by ttsmms):
  scripts/_mms_compare/_models/{code}/    VITS checkpoints (~83 MB each)

Disk: ~900 MB total for all 11 models. Re-runs skip already-downloaded models.
"""
import os
import sys
import shutil
import subprocess
import argparse
from pathlib import Path


# ---------------------------------------------------------------------------
# Auto-activate venv (same pattern as generate_audio_edge.py / record_audio.py)
# ---------------------------------------------------------------------------
def _ensure_venv() -> None:
    if sys.prefix != sys.base_prefix:
        return  # already inside a venv
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    venv_python = project_root / "venv" / "Scripts" / "python.exe"
    if not venv_python.exists():
        print("WARNING: venv not found at", venv_python)
        print("  Run scripts\\install_dependencies.bat first.")
        return
    if os.path.abspath(str(venv_python)) == os.path.abspath(sys.executable):
        return  # already the venv interpreter
    result = subprocess.run([str(venv_python), __file__] + sys.argv[1:])
    sys.exit(result.returncode)


_ensure_venv()


# ---------------------------------------------------------------------------
# Imports that require the venv
# ---------------------------------------------------------------------------
try:
    from ttsmms import TTS
except ImportError:
    print("ERROR: ttsmms not installed in the venv.")
    print("  Run:  venv\\Scripts\\pip install ttsmms")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Candidates — 11 MMS models that probe_mms_languages.py confirmed available.
# ---------------------------------------------------------------------------
MMS_MODELS = [
    # (code, display_name, tier)
    ("pny", "Pinyin (Cameroonian)", "T1 Ngemba — Awing's own subgroup"),
    ("ybb", "Yemba",                "T2 Eastern Grassfields (Bamileke)"),
    ("lns", "Lamnso'",              "T3 Ring Grassfields"),
    ("mnf", "Mundani",              "T4 Momo Grassfields"),
    ("bss", "Akoose",               "T5 S.Bantoid (Session 8 baseline)"),
    ("mcu", "Mambila",              "T5 S.Bantoid (Session 8 baseline)"),
    ("mcp", "Makaa",                "T5 S.Bantoid (Session 8 baseline)"),
    ("hau", "Hausa",                "T6 Non-Bantu reference"),
    ("ful", "Fulfulde",             "T6 Non-Bantu reference"),
    ("yor", "Yoruba",               "T6 Non-Bantu, 3-tone system"),
    ("swh", "Swahili",              "T6 Current baseline"),
]


# ---------------------------------------------------------------------------
# Awing orthography → ASCII-normalized input that every MMS model can parse.
# Mirrors generate_audio_edge.py :: awing_to_speakable() verbatim so this
# comparison matches what we'd ship in production if we swapped voice.
# ---------------------------------------------------------------------------
def awing_to_speakable(text: str) -> str:
    import unicodedata
    # Strip combining tone diacritics (acute, grave, circumflex, caron, ...)
    nfd = unicodedata.normalize("NFD", text)
    stripped = "".join(c for c in nfd if not unicodedata.combining(c))
    # Special-vowel collapse (Awing → Bantu-5-vowel equivalents)
    s = (stripped
         .replace("ɛ", "e").replace("Ɛ", "E")
         .replace("ɔ", "o").replace("Ɔ", "O")
         .replace("ə", "e").replace("Ə", "E")
         .replace("ɨ", "i").replace("Ɨ", "I"))
    # ŋ clusters — handle before isolated ŋ
    s = s.replace("ŋg", "ngg").replace("Ŋg", "Ngg")
    s = s.replace("ŋk", "nk").replace("Ŋk", "Nk")
    s = s.replace("ŋ",  "ng").replace("Ŋ",  "Ng")
    # Session 49 fix — Swahili TTS spells "g-h" for /ɣ/; collapse to g
    s = s.replace("gh", "g").replace("Gh", "G")
    # Apostrophes / glottal stops — strip all variants
    for q in ("'", "'", "'", "`"):
        s = s.replace(q, "")
    return s.strip()


# ---------------------------------------------------------------------------
# Diagnostic word battery — 10 words, each drawn from app vocabulary so we
# have native YouTube extractions to A/B against. Every distinctive Awing
# feature appears at least twice across the set.
#
# IMPORTANT: `awing` is the orthography (shown in HTML for reference).
# `speakable` is what actually gets passed to every MMS model — identical
# string for all 11 so we compare like-for-like.
# ---------------------------------------------------------------------------
_RAW_WORDS = [
    # (awing_text,  safe_key,  english_gloss,     feature description)
    ("tátə",       "tatə",    "father",           "control: simple H tone + ə"),
    ("ndé",        "nde",     "water",            "prenasal nd + H tone"),
    ("ghǒ",        "gho",     "you",              "/ɣ/ (gh) + rising tone ǒ"),
    ("aghô",       "agho",    "yes / okay",       "/ɣ/ (gh) + falling tone ô"),
    ("mbɛ́'tə́",     "mbetə",   "to climb",         "prenasal mb + ɛ + glottal + ə"),
    ("ŋgóonɛ́",     "ngoone",  "banana",           "prenasal ŋg + long oo + ɛ + H-H"),
    ("kwɨ̌tə́",      "kwitə",   "to boil",          "labialized kw + ɨ + rising + ə + H"),
    ("pɔ̀ŋɔ́",      "pongo",   "bag",              "ɔ (open-o) L→H + ŋ (eng)"),
    ("yǐə",        "yie",     "to come",          "diphthong iə + rising tone"),
    ("Móonə",      "moonə",   "baby",             "long vowel oo + ə"),
]

# (awing, safe_key, english, feature, speakable_for_all_models)
DIAGNOSTIC_WORDS = [
    (awing, key, english, feature, awing_to_speakable(awing))
    for (awing, key, english, feature) in _RAW_WORDS
]


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
OUTPUT_DIR = SCRIPT_DIR / "_mms_compare"
MODEL_CACHE = OUTPUT_DIR / "_models"
NATIVE_DIR = OUTPUT_DIR / "native"
ASSETS_AUDIO = PROJECT_ROOT / "assets" / "audio"
PAD_AUDIO = PROJECT_ROOT / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _audio_key_variants(awing_text: str, primary_key: str) -> list:
    """
    Try several filename keys to locate a native extract. Mirrors the logic
    in pronunciation_service.dart / generate_audio_edge.py _audio_key, plus
    the legacy flat-dir naming from extract_audio_clips.py.
    """
    import unicodedata
    # Decompose and strip combining marks (tone diacritics)
    nfd = unicodedata.normalize("NFD", awing_text)
    stripped = "".join(c for c in nfd if not unicodedata.combining(c))
    mapped = (stripped
              .replace("ɛ", "e").replace("ɔ", "o")
              .replace("ə", "e").replace("ɨ", "i")
              .replace("ŋ", "ng")
              .replace("'", "").replace("'", "").replace("'", "")
              .lower())
    variants = [primary_key, mapped]
    # Also try with ə→e in primary_key (Flutter uses schwa→e in some places)
    variants.append(primary_key.replace("ə", "e"))
    # Dedup preserving order
    seen = set()
    out = []
    for v in variants:
        if v and v not in seen:
            seen.add(v)
            out.append(v)
    return out


def find_native_clip(awing_text: str, primary_key: str) -> Path:
    """
    Search for a matching native-recorded clip across all known audio dirs.
    Priority: PAD assets > legacy flat assets. Returns None if nothing found.
    """
    search_roots = []
    # Legacy flat dirs (native YouTube extractions from Session 7)
    for sub in ("alphabet", "vocabulary"):
        search_roots.append(ASSETS_AUDIO / sub)
    # PAD voice dirs (character voices — NOT native but better than nothing)
    for voice in ("boy", "girl", "young_man", "young_woman", "man", "woman"):
        for sub in ("alphabet", "vocabulary", "sentences", "stories"):
            search_roots.append(PAD_AUDIO / voice / sub)
            search_roots.append(ASSETS_AUDIO / voice / sub)

    keys = _audio_key_variants(awing_text, primary_key)
    for root in search_roots:
        for key in keys:
            candidate = root / f"{key}.mp3"
            if candidate.exists():
                return candidate
    return None


def prepare_native_refs() -> dict:
    """Copy all found native clips into _mms_compare/native/ and return map."""
    NATIVE_DIR.mkdir(parents=True, exist_ok=True)
    found = {}
    print("\nLocating native reference clips...")
    for awing, key, english, feature, speakable in DIAGNOSTIC_WORDS:
        clip = find_native_clip(awing, key)
        if clip is None:
            print(f"  [--]  {awing:12s} ({english}): no native clip")
            continue
        dest = NATIVE_DIR / f"{key}.mp3"
        if not dest.exists() or dest.stat().st_mtime < clip.stat().st_mtime:
            shutil.copy2(clip, dest)
        rel_src = clip.relative_to(PROJECT_ROOT)
        print(f"  [OK]  {awing:12s} ({english}): {rel_src}")
        found[key] = dest.name
    return found


def generate_for_model(code: str, display: str, tier: str) -> int:
    """Load MMS model for {code} and synthesize all 10 diagnostic words."""
    out_dir = OUTPUT_DIR / code
    out_dir.mkdir(parents=True, exist_ok=True)
    model_dir = MODEL_CACHE / code

    print(f"\n[{code}] {display}  ({tier})")
    print(f"  Downloading / loading model (cache: {model_dir.relative_to(PROJECT_ROOT)})...")
    try:
        # ttsmms downloads to target dir if not present
        tts = TTS(str(model_dir)) if model_dir.exists() else TTS(code, target_dir=str(MODEL_CACHE))
    except TypeError:
        # Older ttsmms signatures
        try:
            from ttsmms import download
            if not model_dir.exists():
                download(code, str(MODEL_CACHE))
            tts = TTS(str(model_dir))
        except Exception as e:
            print(f"  ERROR: failed to load {code}: {e}")
            return 0
    except Exception as e:
        print(f"  ERROR: failed to load {code}: {e}")
        return 0

    ok = 0
    for awing, key, english, feature, speakable in DIAGNOSTIC_WORDS:
        wav_path = out_dir / f"{key}.wav"
        try:
            # Every model receives the SAME ASCII-normalized input so we
            # compare like-for-like. ttsmms signatures differ across versions.
            try:
                tts.synthesis(speakable, wav_path=str(wav_path))
            except TypeError:
                result = tts.synthesis(speakable)
                if isinstance(result, dict) and "x" in result:
                    import soundfile as sf
                    sf.write(str(wav_path), result["x"], result.get("sampling_rate", 16000))
            if wav_path.exists() and wav_path.stat().st_size > 0:
                ok += 1
                print(f"    [OK]  {awing:12s}  (fed: {speakable!r})  -> {key}.wav")
            else:
                print(f"    [--]  {awing:12s}: empty output (fed: {speakable!r})")
        except Exception as e:
            print(f"    [ERR] {awing:12s}: {e}  (fed: {speakable!r})")
    return ok


def build_html(native_map: dict, attempted_codes: list) -> Path:
    """Emit index.html with audio grid + scoring form."""
    html_path = OUTPUT_DIR / "index.html"

    # Sniff which models actually produced output
    active_models = []
    for code, display, tier in MMS_MODELS:
        if code not in attempted_codes:
            continue
        count = len(list((OUTPUT_DIR / code).glob("*.wav"))) if (OUTPUT_DIR / code).exists() else 0
        if count > 0:
            active_models.append((code, display, tier, count))

    # Begin HTML
    parts = ["""<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<title>MMS Voice Comparison — Awing</title>
<style>
  body { font-family: system-ui, sans-serif; margin: 1.5rem; background: #fafafa; }
  h1 { margin: 0 0 .25rem; }
  .sub { color: #666; margin-bottom: 1.5rem; }
  table { border-collapse: collapse; background: white; }
  th, td { border: 1px solid #ddd; padding: 6px 10px; vertical-align: middle; font-size: 13px; }
  th { background: #f0f0f0; position: sticky; top: 0; z-index: 1; text-align: left; }
  th.rotated { writing-mode: vertical-rl; transform: rotate(180deg); height: 120px; white-space: nowrap; }
  td.word { font-size: 18px; font-weight: 600; min-width: 110px; }
  td.gloss { color: #666; font-size: 11px; font-style: italic; max-width: 200px; }
  td.word .fed { color: #333; font-size: 11px; font-style: normal; margin-top: 4px; }
  td.word .fed code { background: #eef; padding: 1px 5px; border-radius: 3px; font-family: Consolas, monospace; }
  td.native { background: #fff8d4; }
  audio { width: 160px; height: 30px; }
  .missing { color: #bbb; font-size: 11px; font-style: italic; }
  .tier-T1 { background: #d7f5d7; }
  .tier-T2 { background: #e8f5d7; }
  .tier-T3 { background: #f5f5d7; }
  .tier-T4 { background: #f5e8d7; }
  .tier-T5 { background: #f0e0e0; }
  .tier-T6 { background: #ececec; }
  .legend { margin: 1rem 0; font-size: 12px; }
  .legend span { padding: 3px 10px; margin-right: 6px; border: 1px solid #ccc; }
</style></head><body>
<h1>MMS Voice Comparison — Awing</h1>
<p class="sub">Every model received the <strong>same ASCII-normalized string</strong>
(shown in each row under "fed to every model") — the exact <code>awing_to_speakable()</code>
transform used in production, so all 11 models are pronouncing the same target.
Tier 1 is Awing's own Ngemba subgroup; tier 5 is the Session 8 baseline;
tier 6 includes the current production voice (swh / Swahili).
Native column (yellow) is extracted from YouTube lesson videos.</p>

<div class="legend">
  <span class="tier-T1">Tier 1 Ngemba</span>
  <span class="tier-T2">Tier 2 Eastern Grassfields</span>
  <span class="tier-T3">Tier 3 Ring Grassfields</span>
  <span class="tier-T4">Tier 4 Momo Grassfields</span>
  <span class="tier-T5">Tier 5 S.Bantoid</span>
  <span class="tier-T6">Tier 6 non-Bantu / reference</span>
</div>

<table>
<thead><tr>
<th>Word / Feature</th>
<th class="native">Native (YouTube)</th>
"""]

    for code, display, tier, _ in active_models:
        tier_class = "tier-" + tier.split()[0]
        parts.append(f'<th class="rotated {tier_class}">{code} — {display}<br><small>{tier}</small></th>\n')
    parts.append("</tr></thead><tbody>\n")

    for awing, key, english, feature, speakable in DIAGNOSTIC_WORDS:
        parts.append("<tr>\n")
        parts.append(
            f'<td class="word">{awing}'
            f'<div class="gloss">{english} — {feature}</div>'
            f'<div class="fed">fed to every model: <code>{speakable}</code></div>'
            f'</td>\n')
        # Native column
        native_name = native_map.get(key)
        if native_name:
            parts.append(f'<td class="native"><audio controls preload="none" src="native/{native_name}"></audio></td>\n')
        else:
            parts.append('<td class="native"><span class="missing">no native clip</span></td>\n')
        # Per-model columns
        for code, _, tier, _ in active_models:
            tier_class = "tier-" + tier.split()[0]
            wav = OUTPUT_DIR / code / f"{key}.wav"
            if wav.exists():
                parts.append(f'<td class="{tier_class}"><audio controls preload="none" src="{code}/{key}.wav"></audio></td>\n')
            else:
                parts.append(f'<td class="{tier_class}"><span class="missing">failed</span></td>\n')
        parts.append("</tr>\n")

    parts.append("""
</tbody></table>

<h2 style="margin-top:2rem">Scoring template</h2>
<p>For each row, rank your top 3 codes by how close they sound to the native cell.
After all 10 words, the code appearing most often in your top-3 wins.
If the winner is from Tier 1–4, we swap it in as the new production voice.
If the best candidate is still noticeably worse than native, we move to
fine-tuning on the native recordings.</p>

<pre style="background:#fff;padding:1rem;border:1px solid #ddd">
Word        | 1st | 2nd | 3rd | notes
------------+-----+-----+-----+-----------------------------------------
tátə        |     |     |     |
ndé         |     |     |     |
ghǒ         |     |     |     |
aghô        |     |     |     |
mbɛ́'tə́      |     |     |     |
ŋgóonɛ́      |     |     |     |
kwɨ̌tə́       |     |     |     |
pɔ̀ŋɔ́       |     |     |     |
yǐə         |     |     |     |
Móonə       |     |     |     |
</pre>

</body></html>
""")

    html_path.write_text("".join(parts), encoding="utf-8")
    print(f"\nHTML grid written to: {html_path.relative_to(PROJECT_ROOT)}")
    return html_path


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--codes", help="Comma-separated subset, e.g. 'pny,ybb,yor' (default: all)")
    ap.add_argument("--clean", action="store_true", help="Wipe output dir and rerun")
    ap.add_argument("--html-only", action="store_true", help="Skip generation, just rebuild index.html")
    args = ap.parse_args()

    if args.clean:
        if OUTPUT_DIR.exists():
            # Keep the model cache — it's 900 MB
            for entry in OUTPUT_DIR.iterdir():
                if entry.name == "_models":
                    continue
                if entry.is_dir():
                    shutil.rmtree(entry)
                else:
                    entry.unlink()
            print(f"Cleaned {OUTPUT_DIR.relative_to(PROJECT_ROOT)} (kept _models/ cache)")
        else:
            print("Nothing to clean.")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    MODEL_CACHE.mkdir(parents=True, exist_ok=True)

    # Filter models
    if args.codes:
        wanted = {c.strip() for c in args.codes.split(",")}
        models = [m for m in MMS_MODELS if m[0] in wanted]
        if not models:
            print(f"No matching codes in {args.codes}. Available:",
                  ", ".join(m[0] for m in MMS_MODELS))
            return 1
    else:
        models = MMS_MODELS

    # Always refresh native refs (cheap)
    native_map = prepare_native_refs()

    if not args.html_only:
        print(f"\nGenerating {len(DIAGNOSTIC_WORDS)} words x {len(models)} models = "
              f"{len(DIAGNOSTIC_WORDS) * len(models)} clips")
        total_ok = 0
        for code, display, tier in models:
            total_ok += generate_for_model(code, display, tier)
        print(f"\n=== {total_ok} / {len(DIAGNOSTIC_WORDS) * len(models)} clips generated ===")

    build_html(native_map, [m[0] for m in models])

    print("\nNext: open scripts\\_mms_compare\\index.html in a browser and listen.")
    print("Use the scoring template at the bottom of the page to rank.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
