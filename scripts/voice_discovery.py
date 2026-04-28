#!/usr/bin/env python3
"""Discover Edge TTS voices that might suit the Awing app's 6 characters.

Generates one Awing test sentence in EVERY African/Bantu-family
Edge TTS voice (sw-*, en-KE-*, en-NG-*, en-TZ-*, am-*, so-*, etc),
plus a few non-African candidates. Saves WAVs to
models/edge_voice_discovery/ alongside an HTML page that lists each
clip with the voice's metadata.

Usage:
    python3 scripts/voice_discovery.py
        # generates samples for ~15-20 candidate voices

    python3 scripts/voice_discovery.py --langs sw,en-KE,am
        # narrow to specific language tags

    python3 scripts/voice_discovery.py --child-only
        # filter to voices Microsoft tagged as Young (closest to child)

After generation, open the HTML in Chrome on Windows:
    \\\\wsl.localhost\\Ubuntu\\<repo>\\models\\edge_voice_discovery\\index.html

Listen and tell me which 6 voices to use for boy/girl/young_man/
young_woman/man/woman. I'll update VOICE_CHARACTERS and we regenerate.
"""

from __future__ import annotations

import argparse
import asyncio
import html
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = REPO_ROOT / "models" / "edge_voice_discovery"

# A short Awing sentence with a mix of tricky phonemes — every candidate
# voice synthesizes this same line so they're directly comparable.
TEST_AWING = "Móonə a tə nonnɔ́ a əkwunɔ́."  # The baby is lying on the bed.
TEST_ENGLISH_GLOSS = "The baby is lying on the bed."

# Default language tag prefixes we consider Bantu-relevant or
# African-English. Edge TTS has limited Cameroon-Bantu coverage, so we
# cast a wide net and let the listener pick by ear.
DEFAULT_LANG_PREFIXES = [
    "sw-",       # Swahili (Kenya, Tanzania) — Bantu, primary candidates
    "en-KE-",    # Kenyan English
    "en-NG-",    # Nigerian English
    "en-TZ-",    # Tanzanian English (rare in catalog)
    "en-ZA-",    # South African English
    "am-",       # Amharic (Ethiopia) — not Bantu but African
    "so-",       # Somali — not Bantu but African
    "yo-",       # Yoruba (Nigeria) — Niger-Congo
    "ig-",       # Igbo (Nigeria) — Niger-Congo
    "ha-",       # Hausa (Nigeria, Niger) — Afro-Asiatic
    "zu-",       # Zulu — Bantu, no Edge TTS yet but try
    "xh-",       # Xhosa — Bantu, no Edge TTS yet but try
]


async def _list_voices_filtered(lang_prefixes, child_only):
    """Pull the live Edge TTS catalog and filter by language tag prefix."""
    import edge_tts
    catalog = await edge_tts.list_voices()
    voices = []
    for v in catalog:
        sn = v.get("ShortName", "")
        if not any(sn.startswith(p) for p in lang_prefixes):
            continue
        # Microsoft tags voices with VoiceTag content like
        # {"VoicePersonalities": [...], "ContentCategories": [...]}
        # No reliable "child" age field. We approximate by gender +
        # name patterns + the "Young" descriptor in display name.
        if child_only:
            tags = v.get("VoiceTag", {})
            cats = " ".join(tags.get("ContentCategories", []))
            personalities = " ".join(tags.get("VoicePersonalities", []))
            display = (v.get("FriendlyName") or "").lower()
            if not any(k in (cats + personalities + display).lower()
                       for k in ("young", "child", "kid", "casual")):
                continue
        voices.append(v)
    voices.sort(key=lambda v: v.get("ShortName", ""))
    return voices


async def _synth_one(voice_short_name, text, out_path):
    """Synthesize text in voice_short_name to out_path. Returns success bool."""
    import edge_tts
    try:
        c = edge_tts.Communicate(text, voice_short_name, rate="-20%", pitch="+0Hz")
        await c.save(str(out_path))
        return out_path.exists() and out_path.stat().st_size > 500
    except Exception as e:
        print(f"    {voice_short_name:30s} FAILED: {e}")
        return False


async def main_async(args):
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    lang_prefixes = (
        [p.strip() if p.endswith("-") else p.strip() + "-" for p in args.langs.split(",")]
        if args.langs else DEFAULT_LANG_PREFIXES
    )

    print(f"Filtering Edge TTS catalog by prefixes: {lang_prefixes}")
    voices = await _list_voices_filtered(lang_prefixes, args.child_only)
    print(f"Found {len(voices)} candidate voices.\n")

    if not voices:
        print("No voices matched. Try widening --langs.")
        return 1

    print(f"Test sentence: {TEST_AWING!r}")
    print(f"  ({TEST_ENGLISH_GLOSS})")
    print()

    rendered = []
    for i, v in enumerate(voices):
        sn = v.get("ShortName", "?")
        gender = v.get("Gender", "?")
        locale = v.get("Locale", "?")
        friendly = v.get("FriendlyName", sn)
        wav = OUT_DIR / f"{i:02d}_{sn}.mp3"

        print(f"[{i:02d}] {sn:30s}  {gender:6s}  {locale:8s}  -> {wav.name}")
        ok = await _synth_one(sn, TEST_AWING, wav)
        if ok:
            rendered.append({
                "idx": i, "sn": sn, "gender": gender, "locale": locale,
                "friendly": friendly, "file": wav.name,
            })

    # --- Write the HTML audition page ---------------------------------
    print(f"\nRendered {len(rendered)} voices.")
    rows = []
    for r in rendered:
        rows.append(f"""
        <tr>
          <td>{r['idx']:02d}</td>
          <td><code>{html.escape(r['sn'])}</code></td>
          <td>{html.escape(r['gender'])}</td>
          <td>{html.escape(r['locale'])}</td>
          <td><audio controls preload="none" src="{html.escape(r['file'])}"></audio></td>
          <td><input type="text" placeholder="role tag" data-sn="{html.escape(r['sn'])}"></td>
          <td><input type="number" min="1" max="5" placeholder="1-5" data-sn-quality="{html.escape(r['sn'])}"></td>
          <td>{html.escape(r['friendly'])}</td>
        </tr>""")
    rows_html = "".join(rows)

    page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Edge TTS voice discovery — Awing</title>
<style>
  body {{ font: 14px/1.45 system-ui, sans-serif; margin: 1.5em; max-width: 1200px; }}
  h1 {{ margin-bottom: 0.2em; }}
  .meta {{ color: #555; margin-bottom: 1em; }}
  table {{ border-collapse: collapse; width: 100%; }}
  th, td {{ padding: 6px 10px; border-bottom: 1px solid #e5e5e5; vertical-align: middle; }}
  th {{ text-align: left; background: #fafafa; font-weight: 600; }}
  td.sn code {{ font-size: 12px; }}
  audio {{ height: 30px; }}
  input[type=text] {{ width: 9em; padding: 3px; }}
  input[type=number] {{ width: 4em; padding: 3px; }}
  .legend {{ background: #fff7ed; padding: 1em; border-left: 4px solid #ea580c;
              border-radius: 3px; margin-bottom: 1em; }}
  button {{ padding: 8px 16px; cursor: pointer; border: 1px solid #2563eb;
            background: #2563eb; color: white; border-radius: 4px; }}
</style>
</head>
<body>

<h1>Edge TTS voice discovery — Awing</h1>
<p class="meta">
  Test sentence: <code>{html.escape(TEST_AWING)}</code> ({html.escape(TEST_ENGLISH_GLOSS)})<br>
  Voices: {len(rendered)} synthesized samples. Listen and tag.
</p>

<div class="legend">
  <strong>How to tag:</strong> in the role field, type one of
  <code>boy</code>, <code>girl</code>, <code>young_man</code>,
  <code>young_woman</code>, <code>man</code>, <code>woman</code>, or
  <code>skip</code>. In quality, 1-5 (5 = best fit). Then click Export.
</div>

<table>
  <thead>
    <tr>
      <th>#</th><th>ShortName</th><th>Gender</th><th>Locale</th>
      <th>Audio</th><th>Role</th><th>Q (1-5)</th><th>Friendly Name</th>
    </tr>
  </thead>
  <tbody>{rows_html}</tbody>
</table>

<div style="margin-top: 1.5em;">
  <button onclick="exportRatings()">Export ratings as JSON</button>
  <span id="status" style="margin-left: 1em; color: #666;"></span>
</div>

<script>
const KEY = "edge_voice_discovery_ratings";

document.addEventListener("change", e => {{
  if (!e.target.dataset) return;
  const saved = JSON.parse(localStorage.getItem(KEY) || "{{}}");
  if (e.target.dataset.sn !== undefined) {{
    saved[e.target.dataset.sn] = saved[e.target.dataset.sn] || {{}};
    saved[e.target.dataset.sn].role = e.target.value;
  }}
  if (e.target.dataset.snQuality !== undefined) {{
    saved[e.target.dataset.snQuality] = saved[e.target.dataset.snQuality] || {{}};
    saved[e.target.dataset.snQuality].quality = e.target.value;
  }}
  localStorage.setItem(KEY, JSON.stringify(saved));
  document.getElementById("status").textContent = "Saved locally.";
}});

// Restore
const saved = JSON.parse(localStorage.getItem(KEY) || "{{}}");
document.querySelectorAll("input[data-sn]").forEach(el => {{
  const sn = el.dataset.sn;
  if (saved[sn] && saved[sn].role) el.value = saved[sn].role;
}});
document.querySelectorAll("input[data-sn-quality]").forEach(el => {{
  const sn = el.dataset.snQuality;
  if (saved[sn] && saved[sn].quality) el.value = saved[sn].quality;
}});

function exportRatings() {{
  const blob = new Blob([JSON.stringify(saved, null, 2)],
                        {{type: "application/json"}});
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "edge_voice_discovery_ratings.json";
  a.click();
  URL.revokeObjectURL(url);
  document.getElementById("status").textContent = "Downloaded JSON. Paste it back to me.";
}}
</script>

</body>
</html>"""

    (OUT_DIR / "index.html").write_text(page, encoding="utf-8")
    print(f"\nAudition page: {OUT_DIR / 'index.html'}")
    print()
    win_path = str(OUT_DIR / 'index.html').replace("/mnt/c/", "C:\\").replace("/", "\\")
    print(f"Open in Chrome on Windows:")
    print(f"  {win_path}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--langs", default=None,
                    help="Comma-separated language prefixes to include "
                         "(e.g. 'sw,en-KE,am'). Default: all African + Bantu candidates.")
    ap.add_argument("--child-only", action="store_true",
                    help="Filter to voices Microsoft tagged 'Young' / 'Casual'.")
    args = ap.parse_args()
    return asyncio.run(main_async(args))


if __name__ == "__main__":
    sys.exit(main())
