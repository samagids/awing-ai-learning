#!/usr/bin/env python3
"""Smoke-test Qwen3-TTS-12Hz-1.7B-VoiceDesign for the 6-voice Awing app.

Why this script exists
----------------------
Session 56 pivoted from Piper (single voice + pitch shift, rejected by
Dr. Sama) to YourTTS (multi-speaker pretrained pool). The YourTTS smoke
test (smoke_test.py) succeeded on the Blackwell stack — 8 of the
pretrained voices loaded and produced clean English audio — but Dr.
Sama listened and reported that NONE of them sound like children.
YourTTS's pretrained pool is adult-only.

Qwen3-TTS-12Hz-1.7B-VoiceDesign (Alibaba, released Jan 2026) takes a
different approach: instead of a fixed pool of pretrained speakers, it
generates a voice from a NATURAL-LANGUAGE PROMPT. The model card's own
documentation includes an example like "a cute child's voice, around 8
years old" — exactly the constraint we're trying to satisfy.

This smoke test is the gate before we commit to the Qwen3 path:
  1. Does the model load on Blackwell sm_120 + cu128 + WSL2?
  2. Does it actually produce 6 distinct voices when given 6 different
     prompts (vs. mode-collapsing to one voice)?
  3. Do the boy/girl prompts produce voices that SOUND LIKE CHILDREN —
     not just adults pitched up?
  4. Is the audio quality usable (no garble, no Blackwell kernel issues)?

If all four pass, we proceed to writing the Awing fine-tuning pipeline.
If 3 fails (boy/girl sound like adults), we keep looking. If 1 or 4
fails, we have a stack issue worth diagnosing before sinking days into
training.

Outputs
-------
  models/tts_audition/qwen3_smoke_test/
      role_<role>_v<N>.wav    — 6 roles × 2 prompt variants = 12 clips
      _summary.txt            — text summary
      index.html              — interactive audition page (Chrome on Win)

Run inside WSL with the venv activated:
  source ~/venv_qwen3/bin/activate
  python3 scripts/ml/tts/smoke_test_qwen3.py
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import traceback
from pathlib import Path
from typing import Any

# Output goes to a Windows-accessible folder so the audition HTML page
# can be opened from Chrome on Windows. Keep this in sync with the
# YourTTS smoke test so the two pages live side-by-side under tts_audition/.
REPO_ROOT = Path(__file__).resolve().parents[3]
OUT_DIR = REPO_ROOT / "models" / "tts_audition" / "qwen3_smoke_test"

# Same English sentence as the YourTTS smoke test, on purpose, so Dr.
# Sama can A/B the two architectures with identical text content.
TEST_SENTENCE_EN = (
    "The voice of the people speaking together creates a great sound."
)
LANGUAGE = "English"

MODEL_ID = "Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign"

# Two prompt variants per role. The first is descriptive (age + tone +
# context); the second uses a different framing (relational metaphor)
# in case one phrasing lands better than the other.
#
# CRITICAL CONSTRAINT FROM DR. SAMA:
#   "non of these voices sound like boy or girl. children like it when
#    things sound like them."
# So the boy/girl prompts MUST anchor on a concrete child age (7-8) and
# explicitly note the high-pitched, light timbre that distinguishes a
# child's voice from an adult's.
ROLE_PROMPTS: dict[str, list[str]] = {
    "boy": [
        "A cheerful 7-year-old boy with a high-pitched, light, energetic "
        "voice, speaking like a child excitedly explaining his favorite "
        "game to a friend.",
        "A young boy around 8 years old, bright and curious tone with a "
        "small child's high pitch, speaking like he is reading a picture "
        "book aloud to his classmates.",
    ],
    "girl": [
        "A bright 7-year-old girl with a clear, high-pitched, sweet voice, "
        "sounding playful and happy like a child telling a fun story to "
        "her friends at school.",
        "A young girl around 8 years old with a soft, light, child's "
        "voice, gentle and expressive, like she is whispering a secret to "
        "her best friend.",
    ],
    "young_man": [
        "A friendly young man in his early twenties, warm and clear voice, "
        "calm and approachable like a kind college student introducing "
        "himself to a new classmate.",
        "A 22-year-old man with a relaxed, encouraging tone, speaking like "
        "a kind older brother explaining something patiently to his younger "
        "sibling.",
    ],
    "young_woman": [
        "A friendly young woman in her early twenties, warm and clear "
        "voice, lively and bright, like a kind teacher reading aloud to a "
        "class of children.",
        "A 22-year-old woman with a cheerful, gentle voice, speaking like "
        "a caring older sister telling a fun story.",
    ],
    "man": [
        "A kind older man in his fifties, deep, warm, and reassuring voice, "
        "speaking slowly and patiently like a grandfather telling a calm "
        "bedtime story.",
        "A 55-year-old man with a steady, experienced tone, speaking like "
        "a wise village elder explaining something important with care.",
    ],
    "woman": [
        "A warm older woman in her fifties, gentle and clear voice, "
        "speaking softly and patiently like a grandmother reading to her "
        "grandchildren.",
        "A 55-year-old woman with a calm, caring tone, speaking like an "
        "experienced teacher reading a familiar story to her class.",
    ],
}

ROLE_ORDER = ["boy", "girl", "young_man", "young_woman", "man", "woman"]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument(
        "--attn", default="auto",
        choices=["auto", "flash_attention_2", "sdpa", "eager"],
        help="Attention implementation. 'auto' tries flash_attention_2 "
             "first, falls back to sdpa. Use 'sdpa' to skip flash-attn "
             "entirely (works on every GPU). Default: auto.",
    )
    ap.add_argument(
        "--dtype", default="bfloat16",
        choices=["bfloat16", "float16", "float32"],
        help="Model dtype. bfloat16 is recommended on Blackwell. Use "
             "float16 if bf16 fails. Default: bfloat16.",
    )
    ap.add_argument(
        "--variants", type=int, default=2, choices=[1, 2],
        help="Prompt variants per role (1 or 2). Default 2 — gives the "
             "user two phrasings to compare per role.",
    )
    args = ap.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print("Loading torch...")
    import torch
    if not torch.cuda.is_available():
        print("ERROR: CUDA not available in this venv. Run setup_qwen3_wsl.sh.")
        return 1
    cap = torch.cuda.get_device_capability(0)
    print(f"  GPU: {torch.cuda.get_device_name(0)} | sm_{cap[0]}{cap[1]}")
    print(f"  CUDA: {torch.version.cuda} | torch: {torch.__version__}")
    print(f"  bf16 supported: {torch.cuda.is_bf16_supported()}")

    dtype_map = {
        "bfloat16": torch.bfloat16,
        "float16": torch.float16,
        "float32": torch.float32,
    }
    dtype = dtype_map[args.dtype]

    # Decide attention implementation. flash_attention_2 may not be
    # built for sm_120 yet; auto-fallback to sdpa keeps the smoke test
    # alive even if flash-attn is missing or broken.
    attn = args.attn
    if attn == "auto":
        try:
            import flash_attn  # noqa: F401
            attn = "flash_attention_2"
            print("  flash-attn detected; using flash_attention_2")
        except ImportError:
            attn = "sdpa"
            print("  flash-attn not installed; using sdpa")

    print(f"\nLoading {MODEL_ID}...")
    print(f"  dtype={args.dtype}  attn={attn}")
    try:
        from qwen_tts import Qwen3TTSModel
    except ImportError as e:
        print(f"ERROR importing qwen_tts: {e}")
        print("  Run: pip install -U qwen-tts")
        return 1

    try:
        model = Qwen3TTSModel.from_pretrained(
            MODEL_ID,
            device_map="cuda:0",
            dtype=dtype,
            attn_implementation=attn,
        )
    except Exception as e:
        # If flash-attn was the culprit, automatically retry with sdpa.
        # Otherwise surface the error.
        if attn == "flash_attention_2":
            print(f"WARNING: load failed with flash_attention_2: {e}")
            print("  Retrying with sdpa...")
            try:
                model = Qwen3TTSModel.from_pretrained(
                    MODEL_ID,
                    device_map="cuda:0",
                    dtype=dtype,
                    attn_implementation="sdpa",
                )
                attn = "sdpa"
            except Exception as e2:
                print(f"ERROR loading model with sdpa: {e2}")
                traceback.print_exc()
                return 1
        else:
            print(f"ERROR loading model: {e}")
            traceback.print_exc()
            return 1

    # Report VRAM after model load — gives us a baseline for whether a
    # full Awing fine-tune is feasible on this card.
    if torch.cuda.is_available():
        used_gb = torch.cuda.memory_allocated() / 1e9
        reserved_gb = torch.cuda.memory_reserved() / 1e9
        print(f"  VRAM after load: allocated {used_gb:.1f} GB | "
              f"reserved {reserved_gb:.1f} GB")

    import soundfile as sf

    print(f"\nSynthesising '{TEST_SENTENCE_EN[:50]}...' for "
          f"{len(ROLE_ORDER)} roles × {args.variants} variants:\n")
    summary: list[dict[str, Any]] = []
    rendered_index = 0
    for role in ROLE_ORDER:
        prompts = ROLE_PROMPTS[role][:args.variants]
        for vi, prompt in enumerate(prompts, 1):
            out_path = OUT_DIR / f"role_{role}_v{vi}.wav"
            print(f"  [{rendered_index:02d}] {role:14s} v{vi}")
            print(f"       prompt: {prompt[:80]}{'...' if len(prompt) > 80 else ''}")
            try:
                wavs, sr = model.generate_voice_design(
                    text=TEST_SENTENCE_EN,
                    language=LANGUAGE,
                    instruct=prompt,
                )
                # qwen_tts returns wavs as a list of arrays (one per
                # batch element). We synthesise one at a time so wavs[0]
                # is the only entry.
                audio = wavs[0]
                sf.write(str(out_path), audio, sr)
                size_kb = out_path.stat().st_size // 1024
                duration_s = len(audio) / sr if hasattr(audio, "__len__") else 0
                print(f"       -> {out_path.name}  ({size_kb} KB, "
                      f"{duration_s:.1f}s, {sr} Hz)")
                summary.append({
                    "index": rendered_index,
                    "role": role,
                    "variant": vi,
                    "prompt": prompt,
                    "file": out_path.name,
                    "size_kb": size_kb,
                    "duration_s": round(duration_s, 2),
                    "sr": sr,
                })
            except Exception as e:
                print(f"       ERROR: {e}")
                traceback.print_exc()
                summary.append({
                    "index": rendered_index,
                    "role": role,
                    "variant": vi,
                    "prompt": prompt,
                    "error": str(e),
                })
            rendered_index += 1

    # File-size sanity check. If every clip is the same byte-for-byte size,
    # the model has likely mode-collapsed to one voice (a la Session 54).
    sizes = [s.get("size_kb", 0) for s in summary if "size_kb" in s]
    if sizes:
        size_range = max(sizes) - min(sizes)
        print(f"\nFile size range: {min(sizes)}-{max(sizes)} KB "
              f"(spread {size_range} KB)")
        if size_range < 5:
            print("  WARNING: clips are nearly identical in size. "
                  "Voices may be collapsed — listen carefully on the "
                  "audition page before deciding.")

    _write_summary(OUT_DIR, summary, attn, args.dtype)
    _write_audition_html(OUT_DIR, summary, attn, args.dtype)

    html_path = OUT_DIR / "index.html"
    print(f"\nAudition page: {html_path}")
    print()
    print("Open in Chrome on Windows:")
    print(f"  file:///mnt/c/Users/samag/OneDrive/Documents/Claude/Awing/"
          f"models/tts_audition/qwen3_smoke_test/index.html")
    print("  (or via Windows Explorer: C:\\Users\\samag\\OneDrive\\"
          "Documents\\Claude\\Awing\\models\\tts_audition\\"
          "qwen3_smoke_test\\index.html)")
    print()
    print("Listening checklist:")
    print("  1. Are the 6 roles audibly DIFFERENT from each other?")
    print("  2. Do boy & girl actually sound like CHILDREN (not adults)?")
    print("  3. Is the English clear and intelligible?")
    print("  4. Do the two variants per role sound noticeably different?")
    print()
    print("If 1+2+3 pass, we proceed to Awing fine-tuning of Qwen3-TTS.")
    print("If 2 fails, we keep looking for a different model.")
    return 0


def _write_summary(out_dir: Path, rows: list[dict[str, Any]],
                   attn: str, dtype: str) -> None:
    p = out_dir / "_summary.txt"
    with open(p, "w", encoding="utf-8") as f:
        f.write(f"Model: {MODEL_ID}\n")
        f.write(f"Test sentence: {TEST_SENTENCE_EN}\n")
        f.write(f"Language: {LANGUAGE}\n")
        f.write(f"Attention: {attn}  |  Dtype: {dtype}\n\n")
        for r in rows:
            if "error" in r:
                f.write(f"  [{r['index']:02d}] {r['role']:14s} v{r['variant']}  "
                        f"ERROR: {r['error']}\n")
            else:
                f.write(f"  [{r['index']:02d}] {r['role']:14s} v{r['variant']}  "
                        f"{r['file']}  ({r['size_kb']} KB, "
                        f"{r['duration_s']}s, {r['sr']} Hz)\n")
        f.write("\nPrompts used:\n")
        for r in rows:
            f.write(f"  [{r['index']:02d}] {r['role']:14s} v{r['variant']}: "
                    f"{r['prompt']}\n")
    print(f"Summary written to {p}")


def _write_audition_html(out_dir: Path, rows: list[dict[str, Any]],
                         attn: str, dtype: str) -> None:
    """Emit an interactive audition page tailored to the voice-design test.

    Layout differs from the YourTTS audition:
      - Rows are ROLES, not anonymous speakers — each row labelled by role.
      - Per row: per-variant audio + per-variant ratings (sounds like role?
        Y/N, quality 1-5, notes).
      - Aggregate verdict button: "Does Qwen3-TTS solve the child-voice
        problem? Yes / No / Mixed" — that's the real question.
    """
    playable = [r for r in rows if "file" in r]

    # Group rows by role so each role's variants sit together.
    by_role: dict[str, list[dict[str, Any]]] = {}
    for r in playable:
        by_role.setdefault(r["role"], []).append(r)

    role_blocks = []
    for role in ROLE_ORDER:
        role_rows = by_role.get(role, [])
        if not role_rows:
            continue
        variant_html = []
        for r in role_rows:
            v = r["variant"]
            row_id = f"{role}_v{v}"
            variant_html.append(f"""
            <tr data-row="{row_id}">
              <td class="vlabel">v{v}</td>
              <td class="audio">
                <audio controls preload="none" src="{_html_safe(r['file'])}"></audio>
                <div class="meta">{r.get('duration_s', '?')}s · {r.get('sr', '?')} Hz · {r.get('size_kb', '?')} KB</div>
              </td>
              <td class="match">
                <select data-key="match">
                  <option value="">— sounds like {_role_label(role).lower()}? —</option>
                  <option value="yes">Yes — sounds like {_role_label(role).lower()}</option>
                  <option value="close">Close — almost</option>
                  <option value="no">No — wrong age/character</option>
                </select>
              </td>
              <td class="quality">
                <select data-key="quality">
                  <option value="">— quality —</option>
                  <option value="5">5 — clear, natural</option>
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
            # Show prompt under the audio rows so user can read what
            # they're listening to without unfurling.
            variant_html.append(f"""
            <tr data-prompt-for="{row_id}">
              <td colspan="5" class="prompt">prompt: <em>{_html_safe(r['prompt'])}</em></td>
            </tr>""")
        role_blocks.append(f"""
        <h3 class="role-h">{_role_label(role)}</h3>
        <table class="role-tbl">
          <thead>
            <tr>
              <th>v</th><th>Audio</th><th>Match</th><th>Quality</th><th>Notes</th>
            </tr>
          </thead>
          <tbody>
{"".join(variant_html)}
          </tbody>
        </table>""")

    rendered_blocks = "\n".join(role_blocks)

    html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Qwen3-TTS smoke test — Awing voice design</title>
<style>
  body {{ font: 15px/1.45 system-ui, sans-serif; margin: 1.5em; max-width: 1100px; }}
  h1 {{ margin-bottom: 0.2em; }}
  h2 {{ margin-top: 1.5em; }}
  h3.role-h {{ margin: 1.5em 0 0.4em; padding: 0.3em 0.6em;
               background: #eef4ff; border-left: 4px solid #2563eb;
               border-radius: 3px; }}
  .meta {{ color: #555; margin-bottom: 1em; }}
  .meta code {{ background: #f4f4f4; padding: 0 4px; border-radius: 3px; }}
  table.role-tbl {{ border-collapse: collapse; width: 100%; }}
  th, td {{ padding: 6px 10px; border-bottom: 1px solid #e5e5e5; vertical-align: middle; }}
  th {{ text-align: left; background: #fafafa; font-weight: 600; }}
  td.vlabel {{ font-family: monospace; color: #888; width: 3em; }}
  td.audio {{ width: 320px; }}
  td.audio audio {{ height: 30px; }}
  td.audio .meta {{ font-size: 12px; color: #888; margin: 0; }}
  td.prompt {{ background: #fcfcfc; color: #555; font-size: 13px;
               padding-top: 0; padding-bottom: 12px;
               border-bottom: 2px solid #e5e5e5; }}
  td.prompt em {{ font-family: monospace; font-style: normal; font-size: 12.5px; }}
  select, input {{ padding: 4px 6px; font-size: 14px; border: 1px solid #ccc;
                   border-radius: 3px; background: white; }}
  input[type=text] {{ width: 12em; }}
  .actions {{ margin-top: 1em; padding: 1em; background: #f9f9f9;
              border-radius: 6px; }}
  button {{ padding: 8px 16px; font-size: 14px; cursor: pointer;
            border: 1px solid #888; background: white; border-radius: 4px;
            margin-right: 0.5em; }}
  button.primary {{ background: #2563eb; color: white; border-color: #2563eb; }}
  .verdict {{ margin: 1.5em 0; padding: 1em; background: #fff7ed;
              border-left: 4px solid #ea580c; border-radius: 3px; }}
  .verdict h3 {{ margin: 0 0 0.6em; }}
  .verdict label {{ display: block; margin: 0.3em 0; cursor: pointer; }}
  .verdict textarea {{ width: 100%; min-height: 4em; padding: 6px;
                       font: inherit; border: 1px solid #ccc;
                       border-radius: 3px; }}
  .checklist {{ background: #f0fdf4; border-left: 4px solid #16a34a;
                padding: 0.8em 1em; border-radius: 3px; }}
  .checklist ol {{ margin: 0.5em 0 0 1.2em; padding: 0; }}
</style>
</head>
<body>

<h1>Qwen3-TTS — Awing voice design smoke test</h1>
<p class="meta">
  Model: <code>{MODEL_ID}</code><br>
  Test sentence (English): "{_html_safe(TEST_SENTENCE_EN)}"<br>
  Attention: <code>{_html_safe(attn)}</code> · Dtype: <code>{_html_safe(dtype)}</code><br>
  GPU: NVIDIA RTX 5070 (Blackwell, sm_120)
</p>

<div class="checklist">
  <strong>Listening checklist (the four questions that matter):</strong>
  <ol>
    <li>Do the 6 roles sound <em>audibly different</em> from each other?</li>
    <li>Do <strong>boy</strong> and <strong>girl</strong> sound like
        actual <em>children</em> — not adults speaking gently?</li>
    <li>Is the English clear and intelligible (no garble)?</li>
    <li>Do the two variants per role sound noticeably different?</li>
  </ol>
</div>

{rendered_blocks}

<div class="verdict">
  <h3>Overall verdict</h3>
  <p>The single most important question:</p>
  <label><input type="radio" name="verdict" value="yes_proceed">
    <strong>Yes — proceed with Qwen3-TTS Awing fine-tune.</strong>
    The boy/girl voices sound like children. Worth investing
    training time.</label>
  <label><input type="radio" name="verdict" value="mixed">
    <strong>Mixed — some roles work, some don't.</strong>
    Adult roles fine; children still off. Try better prompts before
    deciding.</label>
  <label><input type="radio" name="verdict" value="no_keep_looking">
    <strong>No — boy/girl still don't sound like kids.</strong>
    Move on; keep looking for a different model.</label>
  <label><input type="radio" name="verdict" value="broken">
    <strong>Broken — audio quality unusable / model failed.</strong>
    Diagnose the stack before any architecture decision.</label>
  <p style="margin-top:1em;">
    <label>Free-text notes (anything you want me to know):</label>
    <textarea data-key="verdict_notes"
              placeholder="e.g. 'boy v2 was close but too soft', 'man sounds Asian-accented' "></textarea>
  </p>
</div>

<div class="actions">
  <button class="primary" onclick="exportRatings()">Save my ratings (JSON)</button>
  <button onclick="clearRatings()">Clear all</button>
  <span id="status" style="margin-left: 1em; color: #666;"></span>
</div>

<script>
const RATINGS_KEY = "awing_qwen3_smoke_ratings";
const ROWS = {json.dumps([r['file'] for r in playable])};

// Restore from localStorage
function restore() {{
  const saved = JSON.parse(localStorage.getItem(RATINGS_KEY) || "{{}}");
  document.querySelectorAll("tr[data-row]").forEach(tr => {{
    const id = tr.dataset.row;
    const r = (saved.rows && saved.rows[id]) || {{}};
    tr.querySelectorAll("[data-key]").forEach(el => {{
      const k = el.dataset.key;
      if (r[k] !== undefined) el.value = r[k];
    }});
  }});
  if (saved.verdict) {{
    const radio = document.querySelector(`input[name=verdict][value="${{saved.verdict}}"]`);
    if (radio) radio.checked = true;
  }}
  if (saved.verdict_notes) {{
    const ta = document.querySelector("textarea[data-key=verdict_notes]");
    if (ta) ta.value = saved.verdict_notes;
  }}
}}

document.addEventListener("change", e => {{
  const saved = JSON.parse(localStorage.getItem(RATINGS_KEY) || "{{}}");
  saved.rows = saved.rows || {{}};
  if (e.target.dataset.key) {{
    const tr = e.target.closest("tr[data-row]");
    if (tr) {{
      saved.rows[tr.dataset.row] = saved.rows[tr.dataset.row] || {{}};
      saved.rows[tr.dataset.row][e.target.dataset.key] = e.target.value;
    }} else if (e.target.tagName === "TEXTAREA") {{
      saved.verdict_notes = e.target.value;
    }}
  }}
  if (e.target.name === "verdict") {{
    saved.verdict = e.target.value;
  }}
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
  a.download = "awing_qwen3_smoke_ratings.json";
  a.click();
  URL.revokeObjectURL(url);
  document.getElementById("status").textContent =
    "Downloaded awing_qwen3_smoke_ratings.json — paste it back to me.";
}}

function clearRatings() {{
  if (!confirm("Clear all your ratings on this page?")) return;
  localStorage.removeItem(RATINGS_KEY);
  document.querySelectorAll("[data-key]").forEach(el => el.value = "");
  document.querySelectorAll("input[name=verdict]").forEach(el => el.checked = false);
  document.getElementById("status").textContent = "Cleared.";
}}

restore();
</script>

</body>
</html>"""

    (out_dir / "index.html").write_text(html, encoding="utf-8")


def _role_label(role: str) -> str:
    return {
        "boy": "Boy (~7 years old)",
        "girl": "Girl (~7 years old)",
        "young_man": "Young man (~22)",
        "young_woman": "Young woman (~22)",
        "man": "Older man (~55)",
        "woman": "Older woman (~55)",
    }.get(role, role)


def _html_safe(s: str) -> str:
    return (s.replace("&", "&amp;")
             .replace("<", "&lt;")
             .replace(">", "&gt;")
             .replace('"', "&quot;"))


if __name__ == "__main__":
    sys.exit(main())
