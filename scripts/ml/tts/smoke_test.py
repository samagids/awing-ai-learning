#!/usr/bin/env python3
"""Smoke-test the pretrained YourTTS model BEFORE we commit to fine-tuning.

Purpose: prove on Dr. Sama's specific Blackwell RTX 5070 + cu128 + WSL
stack that:
  1. The pretrained YourTTS model loads
  2. CUDA inference works without crashes
  3. Different speaker IDs produce audibly different voices
  4. The speakers we'd want for the 6-character app (boy / girl /
     young M / young F / older M / older F) actually exist or have
     plausible substitutes among the pretrained set.

If this script succeeds, we move on to Awing fine-tuning. If it fails,
we know early — before sinking days into a training run that wouldn't
have produced anything anyway.

Outputs:
  /tmp/awing_smoke_test/
      speaker_<id>.wav         — same English sentence, each voice
      _summary.txt             — list of speakers + observations

Run inside WSL with the venv activated:
  source ~/venv_coqui_y/bin/activate
  python3 scripts/ml/tts/smoke_test.py
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from typing import Any

# Suppress the Coqui EULA prompt
os.environ.setdefault("COQUI_TOS_AGREED", "1")

# Output goes to a Windows-accessible folder so the audition HTML page
# can be opened from Chrome on Windows. The relative wav paths inside
# the HTML resolve cleanly under file:// or any local HTTP server.
REPO_ROOT = Path(__file__).resolve().parents[3]
OUT_DIR = REPO_ROOT / "models" / "tts_audition" / "smoke_test"
TEST_SENTENCE_EN = (
    "The voice of the people speaking together creates a great sound."
)
LANG = "en"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument(
        "--all", action="store_true",
        help="Synthesize for every speaker in the pretrained pool "
             "(slower; use after the initial 8-voice sanity check.)",
    )
    ap.add_argument(
        "--n", type=int, default=8,
        help="Number of speakers to sample (ignored if --all). Default 8.",
    )
    args = ap.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print("Loading torch + Coqui TTS...")
    import torch
    if not torch.cuda.is_available():
        print("ERROR: CUDA not available in this venv. Run setup_wsl.sh.")
        return 1
    cap = torch.cuda.get_device_capability(0)
    print(f"  GPU: {torch.cuda.get_device_name(0)} | sm_{cap[0]}{cap[1]}")
    print(f"  CUDA: {torch.version.cuda} | torch: {torch.__version__}")

    from TTS.api import TTS

    print("\nLoading YourTTS pretrained model...")
    try:
        tts = TTS(
            model_name="tts_models/multilingual/multi-dataset/your_tts",
            progress_bar=False,
        ).to("cuda")
    except Exception as e:
        print(f"ERROR loading model: {e}")
        return 1

    # Coqui's YourTTS sometimes returns speaker IDs with trailing
    # newlines (a long-standing bug in their speaker-list parser).
    # Strip whitespace and dedup so the same speaker doesn't get tested
    # twice and doesn't appear twice in the audition page.
    raw_speakers = tts.speakers or []
    seen = set()
    speakers = []
    for s in raw_speakers:
        clean = (s or "").strip()
        if clean and clean not in seen:
            seen.add(clean)
            speakers.append(clean)

    languages = tts.languages or []
    print(f"\n  Speakers available: {len(speakers)} (after dedup; "
          f"raw count {len(raw_speakers)})")
    print(f"  Languages available: {languages}")
    if not speakers:
        print("ERROR: no speakers exposed by pretrained model. Check Coqui install.")
        return 1
    if LANG not in languages:
        print(f"  WARNING: '{LANG}' not in pretrained languages {languages}")
        print(f"  Will try anyway with first language: {languages[0]}")
        lang_to_use = languages[0]
    else:
        lang_to_use = LANG

    # Decide which speakers to render audio for.
    n_speakers = len(speakers)
    if args.all:
        sample_speakers = list(speakers)
        print(f"\n  --all mode: synthesizing for every speaker "
              f"({n_speakers} total)")
    else:
        n_to_test = min(args.n, n_speakers)
        indices = [int(i * (n_speakers - 1) / max(1, n_to_test - 1))
                   for i in range(n_to_test)]
        sample_speakers = [speakers[i] for i in indices]
        print(f"\n  --n mode: sampling {n_to_test} of {n_speakers} speakers")

    n_to_test = len(sample_speakers)
    print(f"\nSynthesising '{TEST_SENTENCE_EN[:50]}...' for "
          f"{n_to_test} speakers:\n")
    summary: list[dict[str, Any]] = []
    for i, spk in enumerate(sample_speakers):
        out_path = OUT_DIR / f"speaker_{i:02d}_{_safe(spk)}.wav"
        try:
            tts.tts_to_file(
                text=TEST_SENTENCE_EN,
                speaker=spk,
                language=lang_to_use,
                file_path=str(out_path),
            )
            size_kb = out_path.stat().st_size // 1024
            print(f"  [{i:02d}] {spk:24s}  ->  {out_path.name}  ({size_kb} KB)")
            summary.append({"index": i, "speaker": spk,
                            "file": out_path.name, "size_kb": size_kb})
        except Exception as e:
            print(f"  [{i:02d}] {spk:24s}  ERROR: {e}")
            summary.append({"index": i, "speaker": spk, "error": str(e)})

    # Quick visual: file sizes should differ a bit per speaker if voices
    # are actually different (different prosody/duration).
    sizes = [s.get("size_kb", 0) for s in summary if "size_kb" in s]
    if sizes:
        print(f"\nFile size range: {min(sizes)}–{max(sizes)} KB "
              f"(if all identical, voices may be collapsed)")

    # Write the audition HTML page — same style as the earlier bake-off
    # pages so Dr. Sama can open it in Chrome and click through.
    _write_audition_html(OUT_DIR, summary, speakers, TEST_SENTENCE_EN, lang_to_use)

    # Also dump a plain summary.txt for non-browser inspection.
    summary_path = OUT_DIR / "_summary.txt"
    with open(summary_path, "w", encoding="utf-8") as f:
        f.write(f"Test sentence: {TEST_SENTENCE_EN}\n")
        f.write(f"Language: {lang_to_use}\n")
        f.write(f"Pretrained model: tts_models/multilingual/multi-dataset/your_tts\n")
        f.write(f"Total pretrained speakers: {len(speakers)}\n\n")
        f.write("Sampled speakers:\n")
        for s in summary:
            if "error" in s:
                f.write(f"  [{s['index']:02d}] {s['speaker']:24s}  ERROR: {s['error']}\n")
            else:
                f.write(f"  [{s['index']:02d}] {s['speaker']:24s}  "
                        f"{s['file']}  ({s['size_kb']} KB)\n")
        f.write("\nAll pretrained speaker IDs:\n")
        for spk in speakers:
            f.write(f"  {spk}\n")

    print(f"\nSummary written to {summary_path}")
    html_path = OUT_DIR / "index.html"
    print(f"Audition page: {html_path}")
    print()
    print("Open in Chrome on Windows:")
    print(f"  file:///mnt/c/Users/samag/OneDrive/Documents/Claude/Awing/"
          f"models/tts_audition/smoke_test/index.html")
    print("  (or via Windows Explorer: C:\\Users\\samag\\OneDrive\\"
          "Documents\\Claude\\Awing\\models\\tts_audition\\smoke_test\\index.html)")
    print()
    print("If 8 voices sound clearly different, smoke test PASS.")
    print("Then we proceed to the Awing fine-tune.")
    return 0


def _write_audition_html(out_dir: Path, rows: list[dict[str, Any]],
                         all_speakers: list[str], sentence: str,
                         language: str) -> None:
    """Emit an interactive audition page mirroring the old bake-off UX."""
    import json as _json

    # Only entries with successful audio render
    playable = [r for r in rows if "file" in r]

    rows_html = []
    for r in playable:
        rows_html.append(f"""
        <tr data-spk="{_html_safe(r['speaker'])}" data-idx="{r['index']}">
          <td class="idx">{r['index']:02d}</td>
          <td class="spk">{_html_safe(r['speaker'])}</td>
          <td class="audio">
            <audio controls preload="none" src="{_html_safe(r['file'])}"></audio>
          </td>
          <td class="rate">
            <select data-key="role">
              <option value="">— role —</option>
              <option value="boy">boy</option>
              <option value="girl">girl</option>
              <option value="young_man">young man</option>
              <option value="young_woman">young woman</option>
              <option value="man">man (older)</option>
              <option value="woman">woman (older)</option>
              <option value="skip">skip — bad fit</option>
            </select>
          </td>
          <td class="quality">
            <select data-key="quality">
              <option value="">— quality —</option>
              <option value="5">5 — clear, distinctive</option>
              <option value="4">4 — good</option>
              <option value="3">3 — usable</option>
              <option value="2">2 — poor</option>
              <option value="1">1 — broken/garbled</option>
            </select>
          </td>
          <td class="notes">
            <input type="text" data-key="notes" placeholder="optional notes" />
          </td>
        </tr>""")

    speakers_listing = "\n".join(
        f"          <li>{_html_safe(s)}</li>" for s in all_speakers
    )

    html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Awing TTS — Smoke test audition</title>
<style>
  body {{ font: 15px/1.45 system-ui, sans-serif; margin: 1.5em; max-width: 1100px; }}
  h1 {{ margin-bottom: 0.2em; }}
  h2 {{ margin-top: 1.5em; }}
  .meta {{ color: #555; margin-bottom: 1em; }}
  .meta code {{ background: #f4f4f4; padding: 0 4px; border-radius: 3px; }}
  table {{ border-collapse: collapse; width: 100%; margin-top: 1em; }}
  th, td {{ padding: 8px 10px; border-bottom: 1px solid #e5e5e5; vertical-align: middle; }}
  th {{ text-align: left; background: #fafafa; font-weight: 600; }}
  td.idx {{ font-family: monospace; color: #888; width: 3em; }}
  td.spk {{ font-family: monospace; font-size: 13px; max-width: 200px;
            overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }}
  td.audio audio {{ height: 30px; }}
  select, input {{ padding: 4px 6px; font-size: 14px; border: 1px solid #ccc;
                   border-radius: 3px; background: white; }}
  input[type=text] {{ width: 12em; }}
  .actions {{ margin-top: 1em; padding: 1em; background: #f9f9f9;
              border-radius: 6px; }}
  button {{ padding: 8px 16px; font-size: 14px; cursor: pointer;
            border: 1px solid #888; background: white; border-radius: 4px;
            margin-right: 0.5em; }}
  button.primary {{ background: #2563eb; color: white; border-color: #2563eb; }}
  details {{ margin-top: 2em; }}
  details summary {{ cursor: pointer; color: #555; }}
  pre {{ background: #f4f4f4; padding: 12px; border-radius: 4px;
         overflow-x: auto; max-height: 200px; }}
</style>
</head>
<body>

<h1>YourTTS smoke-test audition</h1>
<p class="meta">
  Pretrained model: <code>tts_models/multilingual/multi-dataset/your_tts</code><br>
  Total speakers in pretrained set: <strong>{len(all_speakers)}</strong><br>
  Test sentence (<code>{language}</code>): "{_html_safe(sentence)}"<br>
  GPU: NVIDIA RTX 5070 (Blackwell, sm_120)
</p>

<h2>What you're listening for</h2>
<ol>
  <li>Do these 8 voices sound clearly <em>different</em> from each other?
      That's the threshold for proceeding with the Awing fine-tune.</li>
  <li>Among them, can you imagine 6 fitting your character roles
      (boy / girl / young man / young woman / older man / older woman)?
      Tag each one in the dropdowns below.</li>
  <li>Note overall quality — broken/garbled outputs would mean the
      Blackwell driver stack has a kernel issue worth diagnosing.</li>
</ol>

<table>
  <thead>
    <tr>
      <th>#</th><th>Speaker ID</th><th>Audio</th>
      <th>Best fit role</th><th>Quality</th><th>Notes</th>
    </tr>
  </thead>
  <tbody>
{"".join(rows_html)}
  </tbody>
</table>

<div class="actions">
  <button class="primary" onclick="exportRatings()">Save my ratings (JSON)</button>
  <button onclick="clearRatings()">Clear all</button>
  <span id="status" style="margin-left: 1em; color: #666;"></span>
</div>

<details>
  <summary>All {len(all_speakers)} pretrained speaker IDs (for reference)</summary>
  <pre><ol>
{speakers_listing}
  </ol></pre>
</details>

<script>
const RATINGS_KEY = "awing_yourtts_smoke_ratings";
const SPEAKERS = {_json.dumps([r['speaker'] for r in playable])};

// Restore ratings from localStorage
function restore() {{
  const saved = JSON.parse(localStorage.getItem(RATINGS_KEY) || "{{}}");
  document.querySelectorAll("tr[data-spk]").forEach(tr => {{
    const spk = tr.dataset.spk;
    const r = saved[spk] || {{}};
    tr.querySelectorAll("[data-key]").forEach(el => {{
      const k = el.dataset.key;
      if (r[k] !== undefined) el.value = r[k];
    }});
  }});
}}

// Persist on every change
document.addEventListener("change", e => {{
  if (!e.target.dataset.key) return;
  const tr = e.target.closest("tr[data-spk]");
  if (!tr) return;
  const saved = JSON.parse(localStorage.getItem(RATINGS_KEY) || "{{}}");
  saved[tr.dataset.spk] = saved[tr.dataset.spk] || {{}};
  saved[tr.dataset.spk][e.target.dataset.key] = e.target.value;
  localStorage.setItem(RATINGS_KEY, JSON.stringify(saved));
  document.getElementById("status").textContent =
    "Saved locally — click Export when done.";
}});

function exportRatings() {{
  const saved = JSON.parse(localStorage.getItem(RATINGS_KEY) || "{{}}");
  const blob = new Blob([JSON.stringify(saved, null, 2)],
                        {{ type: "application/json" }});
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "awing_yourtts_smoke_ratings.json";
  a.click();
  URL.revokeObjectURL(url);
  document.getElementById("status").textContent =
    "Downloaded awing_yourtts_smoke_ratings.json — paste it back to me.";
}}

function clearRatings() {{
  if (!confirm("Clear all your ratings on this page?")) return;
  localStorage.removeItem(RATINGS_KEY);
  document.querySelectorAll("[data-key]").forEach(el => el.value = "");
  document.getElementById("status").textContent = "Cleared.";
}}

restore();
</script>

</body>
</html>"""

    (out_dir / "index.html").write_text(html, encoding="utf-8")


def _html_safe(s: str) -> str:
    return (s.replace("&", "&amp;")
             .replace("<", "&lt;")
             .replace(">", "&gt;")
             .replace('"', "&quot;"))


def _safe(s: str) -> str:
    return "".join(c if c.isalnum() else "_" for c in s)[:24]


if __name__ == "__main__":
    sys.exit(main())
