#!/usr/bin/env python3
"""
Pattern Mine — improve awing_to_speakable() defaults from your recordings,
with NO ASR in the loop.

Phase 1 (this script):
  audit  → emit HTML where you listen to each of your 197 recordings side
           by side with the current Edge TTS output (one voice at a time).
           For each word you mark "good" / "needs fix" / "can't tell" and
           optionally type a candidate Swahili-style spelling that would
           sound closer to your recording.
  export → read verdicts JSON downloaded from the audit page; print a
           summary clustered by linguistic bucket so you can see where
           the default mapping struggles before Phase 2 mines for rules.
  status → file counts
  clean  → remove generated audio

Phase 2 (separate script, built after you've done a meaningful sample of
audit work — say 50+ verdicts):
  mine   → analyze your verdicts, cluster by Awing pattern, propose
           rule changes to awing_to_speakable() with affected-word
           lists and before/after audio for each candidate rule.

This script never uses Whisper or any other ASR. The only model output
is Edge TTS itself, synthesizing the current default mapping so you
can hear what the production pipeline ships today. All corrections
come from your ear and your typed candidate spellings.

Usage:
  python scripts/pattern_mine.py audit                   # all 197, young_woman voice
  python scripts/pattern_mine.py audit --voice boy       # different voice
  python scripts/pattern_mine.py audit --samples 50      # smaller batch
  python scripts/pattern_mine.py audit --force           # regenerate audio
  python scripts/pattern_mine.py status
  python scripts/pattern_mine.py clean

Then open: training_data/pattern_mine/audit.html
After rating, click "Download verdicts JSON" in the page and save into:
       training_data/pattern_mine/verdicts.json
Then:  python scripts/pattern_mine.py export

Requires: edge-tts (pip install edge-tts)
"""

import os
import sys
import json
import shutil
import argparse
import asyncio
import subprocess
from pathlib import Path
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Auto-activate venv (same pattern as record_audio.py, ab_spot_check.py)
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

MINE_DIR = PROJECT_ROOT / "training_data" / "pattern_mine"
GROUND_TRUTH_DIR = MINE_DIR / "_ground_truth"
DEFAULT_DIR = MINE_DIR / "_default"
AUDIT_MANIFEST = MINE_DIR / "audit_manifest.json"
HTML_OUT = MINE_DIR / "audit.html"
VERDICTS_PATH = MINE_DIR / "verdicts.json"   # User downloads here from page

TEMP_DIR = SCRIPT_DIR / "_pattern_mine_temp"


# ---------------------------------------------------------------------------
# Reuse production helpers + bucket detection from ab_spot_check
# ---------------------------------------------------------------------------
sys.path.insert(0, str(SCRIPT_DIR))
try:
    from generate_audio_edge import (
        VOICE_CHARACTERS,
        awing_to_speakable,
    )
except ImportError as e:
    print(f"ERROR: could not import from generate_audio_edge.py: {e}")
    sys.exit(1)

try:
    from ab_spot_check import _bucket_word, TARGET_BUCKETS
except ImportError as e:
    print(f"ERROR: could not import bucket detection from ab_spot_check.py: {e}")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Edge TTS clip generation (one voice at a time)
# ---------------------------------------------------------------------------

async def _edge_tts_to_mp3(text, voice_name, rate, pitch, output_path):
    """Generate one Edge TTS clip. Returns True on success."""
    import edge_tts
    try:
        TEMP_DIR.mkdir(parents=True, exist_ok=True)
        temp_mp3 = TEMP_DIR / f"_temp_{os.getpid()}.mp3"
        communicate = edge_tts.Communicate(
            text, voice_name, rate=rate, pitch=pitch)
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


async def _generate_default(awing, voice_id, key):
    """Generate one Edge TTS clip for the current default mapping."""
    cfg = VOICE_CHARACTERS[voice_id]
    default_text = awing_to_speakable(awing)
    out_path = DEFAULT_DIR / voice_id / f"{key}.mp3"
    ok = await _edge_tts_to_mp3(
        default_text, cfg["voice"], cfg["rate"], cfg["pitch"], out_path)
    return ok, default_text


# ---------------------------------------------------------------------------
# Subcommand: audit
# ---------------------------------------------------------------------------

def cmd_audit(args):
    """Generate Edge TTS clips for every recording, emit audit HTML."""

    if not RECORDINGS_MANIFEST.exists():
        print(f"ERROR: {RECORDINGS_MANIFEST} not found.")
        print("Run record_audio.py first to capture training references.")
        return False

    with open(RECORDINGS_MANIFEST, "r", encoding="utf-8") as f:
        all_entries = json.load(f)
    print(f"Loaded {len(all_entries)} recordings from manifest.")

    # Voice selection
    voice_id = args.voice
    if voice_id not in VOICE_CHARACTERS:
        print(f"ERROR: unknown voice '{voice_id}'.")
        print(f"Valid: {list(VOICE_CHARACTERS.keys())}")
        return False
    voice_cfg = VOICE_CHARACTERS[voice_id]
    print(f"Voice: {voice_id}  ({voice_cfg['voice']}, "
          f"{voice_cfg['description']})")

    # Sample subset if requested
    if args.samples and args.samples < len(all_entries):
        # Sort by key so subset is deterministic across runs
        all_entries = sorted(all_entries, key=lambda e: e["key"])[:args.samples]
        print(f"Limiting to first {args.samples} recordings (deterministic).")

    # Output dirs
    for d in (GROUND_TRUTH_DIR, DEFAULT_DIR / voice_id, TEMP_DIR):
        d.mkdir(parents=True, exist_ok=True)

    # Process each recording
    sample_records = []
    bucket_counts = {b: 0 for b in TARGET_BUCKETS}
    print()
    for i, entry in enumerate(all_entries, 1):
        key = entry["key"]
        awing = entry["awing"]
        english = entry.get("english", "")
        wav_src = PROJECT_ROOT / entry["wav_path"]

        buckets = _bucket_word(awing)
        bucket_tags = [b for b in buckets if b in TARGET_BUCKETS]
        for b in bucket_tags:
            bucket_counts[b] += 1

        # Copy ground-truth WAV
        gt_dst = GROUND_TRUTH_DIR / f"{key}.wav"
        if not gt_dst.exists() or args.force:
            if wav_src.exists():
                shutil.copy2(wav_src, gt_dst)
            else:
                print(f"  [{i}/{len(all_entries)}] {key}  ! source WAV missing — skipped")
                continue

        # Generate default clip
        out_path = DEFAULT_DIR / voice_id / f"{key}.mp3"
        if args.force or not out_path.exists():
            ok, default_text = asyncio.run(
                _generate_default(awing, voice_id, key))
            mark = "✓" if ok else "✗"
        else:
            default_text = awing_to_speakable(awing)
            mark = "·"  # already exists

        # Brief progress line
        if i % 25 == 0 or i == len(all_entries):
            print(f"  [{i}/{len(all_entries)}] {key:24s} "
                  f"{awing} → '{default_text}' {mark}")

        sample_records.append({
            "key": key,
            "awing": awing,
            "english": english,
            "buckets": bucket_tags,
            "default_speakable": default_text,
            "ground_truth_wav": str(gt_dst.relative_to(MINE_DIR)).replace(
                os.sep, "/"),
            "default_mp3": str(out_path.relative_to(MINE_DIR)).replace(
                os.sep, "/"),
            "wav_duration_s": entry.get("duration_s"),
        })

    # Coverage report
    print(f"\nLinguistic bucket coverage across {len(sample_records)} words:")
    for b in TARGET_BUCKETS:
        bar = "█" * min(40, bucket_counts.get(b, 0))
        print(f"  {b:18s} {bucket_counts.get(b, 0):3d}  {bar}")

    # Save manifest
    manifest = {
        "version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "voice": voice_id,
        "voice_name": voice_cfg["voice"],
        "voice_description": voice_cfg["description"],
        "n_words": len(sample_records),
        "samples": sample_records,
    }
    AUDIT_MANIFEST.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nManifest written: {AUDIT_MANIFEST}")

    # Emit HTML
    cmd_html(args)
    return True


# ---------------------------------------------------------------------------
# HTML page
# ---------------------------------------------------------------------------

HTML_TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Pattern Mine — awing_to_speakable() audit</title>
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    max-width: 1300px;
    margin: 0 auto;
    padding: 24px;
    background: #f7f8fa;
    color: #1a1a1a;
  }
  h1 { margin: 0 0 4px 0; font-size: 26px; }
  .subtitle { color: #555; font-size: 13px; margin-bottom: 16px; }
  .hint {
    background: #ecfdf5;
    border-left: 4px solid #10b981;
    padding: 12px 16px;
    margin: 16px 0;
    border-radius: 4px;
    font-size: 14px;
    line-height: 1.5;
  }
  .hint code {
    background: #d1fae5;
    padding: 1px 5px;
    border-radius: 3px;
    font-size: 12px;
  }
  .summary {
    position: sticky;
    top: 16px;
    z-index: 10;
    background: white;
    border: 2px solid #1e293b;
    border-radius: 8px;
    padding: 16px;
    margin-bottom: 24px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }
  .summary h2 { margin: 0 0 8px 0; font-size: 16px; }
  .progress {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
    margin-bottom: 12px;
  }
  .stat {
    background: #f8fafc;
    padding: 10px;
    border-radius: 6px;
    text-align: center;
  }
  .stat .label {
    font-size: 11px;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  .stat .value {
    font-size: 22px;
    font-weight: 700;
    margin-top: 2px;
  }
  .v-good { color: #047857; }
  .v-fix { color: #b91c1c; }
  .v-cant { color: #6b7280; }
  .v-todo { color: #92400e; }
  .actions {
    display: flex;
    gap: 8px;
    margin-top: 8px;
    flex-wrap: wrap;
  }
  .actions button {
    padding: 8px 12px;
    border: 1px solid #d1d5db;
    background: white;
    border-radius: 4px;
    cursor: pointer;
    font-size: 13px;
  }
  .actions button.primary {
    background: #1e293b;
    color: white;
    border-color: #1e293b;
  }
  .actions button.danger {
    background: #ef4444;
    color: white;
    border-color: #ef4444;
  }
  .actions button:hover { opacity: 0.85; }
  .filter {
    display: flex;
    gap: 8px;
    align-items: center;
    margin-top: 8px;
    flex-wrap: wrap;
  }
  .filter label { font-size: 12px; color: #64748b; }
  .filter select, .filter input[type=text] {
    padding: 4px 8px;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    font-size: 13px;
  }
  .sample {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 14px 18px;
    margin: 12px 0;
    box-shadow: 0 1px 2px rgba(0,0,0,0.04);
  }
  .sample.hidden { display: none; }
  .sample.v-good-bg { border-left: 4px solid #10b981; }
  .sample.v-fix-bg { border-left: 4px solid #ef4444; }
  .sample.v-cant-bg { border-left: 4px solid #9ca3af; }
  .sample-header {
    display: flex;
    align-items: baseline;
    gap: 12px;
    margin-bottom: 8px;
    flex-wrap: wrap;
  }
  .awing { font-size: 22px; font-weight: 600; color: #0f172a; }
  .english { color: #64748b; font-size: 14px; }
  .default-text {
    font-family: monospace;
    font-size: 12px;
    color: #475569;
    background: #f1f5f9;
    padding: 2px 6px;
    border-radius: 3px;
  }
  .key {
    font-family: monospace;
    color: #94a3b8;
    font-size: 11px;
    margin-left: auto;
  }
  .buckets { margin: 4px 0 10px 0; font-size: 11px; }
  .bucket-tag {
    display: inline-block;
    background: #f1f5f9;
    border: 1px solid #e2e8f0;
    border-radius: 10px;
    padding: 1px 7px;
    margin-right: 3px;
    color: #475569;
  }
  .audio-row {
    display: grid;
    grid-template-columns: 130px 1fr;
    gap: 10px;
    align-items: center;
    margin: 6px 0;
  }
  .audio-label {
    font-size: 12px;
    font-weight: 600;
    color: #334155;
  }
  audio { width: 100%; height: 32px; }
  .verdict-row {
    display: flex;
    gap: 6px;
    margin-top: 10px;
    flex-wrap: wrap;
  }
  .verdict-btn {
    padding: 6px 12px;
    border: 1px solid #d1d5db;
    background: white;
    border-radius: 4px;
    cursor: pointer;
    font-size: 12px;
    transition: all 0.1s;
  }
  .verdict-btn:hover { background: #f3f4f6; }
  .verdict-btn.selected.good {
    background: #d1fae5; border-color: #10b981; color: #065f46;
  }
  .verdict-btn.selected.fix {
    background: #fee2e2; border-color: #ef4444; color: #991b1b;
  }
  .verdict-btn.selected.cant {
    background: #f3f4f6; border-color: #6b7280; color: #374151;
  }
  .candidate {
    margin-top: 8px;
    display: none;
  }
  .candidate.show { display: block; }
  .candidate label {
    font-size: 12px;
    color: #64748b;
    display: block;
    margin-bottom: 4px;
  }
  .candidate input {
    width: 100%;
    padding: 6px 8px;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    font-family: monospace;
    font-size: 13px;
    box-sizing: border-box;
  }
  .candidate .help {
    font-size: 11px;
    color: #94a3b8;
    margin-top: 4px;
  }
</style>
</head>
<body>

<h1>Pattern Mine — <code>awing_to_speakable()</code> audit</h1>
<div class="subtitle">
  Generated: __GENERATED_AT__ &middot; Voice: __VOICE__ (__VOICE_DESC__) &middot;
  __N_WORDS__ words
</div>

<div class="hint">
  <b>For each word:</b> listen to the green ground-truth (your recording),
  then the orange Edge TTS output of the current default mapping
  (<code>awing_to_speakable()</code>).
  <br><br>
  Click <b>Good</b> if the Edge TTS output sounds close enough.
  Click <b>Needs fix</b> and (optionally) type a candidate Swahili-style
  spelling that you think would sound closer — for example
  <code>ghane → kwane</code> or <code>tə → ta</code>.
  <br><br>
  When you're done (or pause for the night), click
  <b>Download verdicts JSON</b> at the top and save the file as
  <code>training_data/pattern_mine/verdicts.json</code>. Then run
  <code>python scripts/pattern_mine.py export</code> to see what patterns
  emerge.
</div>

<div class="summary">
  <h2>Progress</h2>
  <div class="progress">
    <div class="stat">
      <div class="label">Total</div>
      <div class="value" id="stat-total">__N_WORDS__</div>
    </div>
    <div class="stat">
      <div class="label">Good</div>
      <div class="value v-good" id="stat-good">0</div>
    </div>
    <div class="stat">
      <div class="label">Needs fix</div>
      <div class="value v-fix" id="stat-fix">0</div>
    </div>
    <div class="stat">
      <div class="label">To do</div>
      <div class="value v-todo" id="stat-todo">__N_WORDS__</div>
    </div>
  </div>
  <div class="filter">
    <label>Show:</label>
    <select id="filter-verdict" onchange="applyFilters()">
      <option value="all">all words</option>
      <option value="todo">to-do only</option>
      <option value="good">good only</option>
      <option value="fix">needs-fix only</option>
      <option value="cant">can't-tell only</option>
    </select>
    <label>Bucket:</label>
    <select id="filter-bucket" onchange="applyFilters()">
      <option value="all">all buckets</option>
      __BUCKET_OPTIONS__
    </select>
    <label>Search:</label>
    <input type="text" id="filter-search" placeholder="Awing or English"
           oninput="applyFilters()">
  </div>
  <div class="actions">
    <button class="primary" onclick="downloadVerdicts()">
      ⬇ Download verdicts JSON
    </button>
    <button onclick="importVerdicts()">⬆ Import verdicts JSON</button>
    <button class="danger" onclick="resetAll()">Reset all</button>
  </div>
</div>

<div id="samples">__SAMPLE_BLOCKS__</div>

<input type="file" id="import-file" accept=".json" style="display:none"
       onchange="handleImportFile(this)">

<script>
const STORAGE_KEY = "awing_pattern_mine_v1";
const N_WORDS = __N_WORDS__;
const VOICE_ID = "__VOICE__";

function loadState() {
  try { return JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}"); }
  catch { return {}; }
}

function saveState(s) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(s));
}

function setVerdict(key, verdict) {
  const s = loadState();
  s[key] = s[key] || {};
  s[key].verdict = verdict;
  saveState(s);
  renderVerdict(key, verdict);
  updateSummary();
  applyFilters();
}

function setCandidate(key, candidate) {
  const s = loadState();
  s[key] = s[key] || {};
  s[key].candidate = candidate;
  saveState(s);
}

function renderVerdict(key, verdict) {
  // Buttons
  const buttons = document.querySelectorAll(
    `.verdict-btn[data-key="${key}"]`);
  buttons.forEach(b => {
    b.classList.toggle("selected",
      b.dataset.verdict === verdict);
    b.classList.remove("good", "fix", "cant");
    if (b.dataset.verdict === verdict) b.classList.add(verdict);
  });
  // Candidate input visibility
  const cand = document.querySelector(`.candidate[data-key="${key}"]`);
  if (cand) cand.classList.toggle("show", verdict === "fix");
  // Sample card border color
  const card = document.querySelector(`.sample[data-key="${key}"]`);
  if (card) {
    card.classList.remove("v-good-bg", "v-fix-bg", "v-cant-bg");
    if (verdict === "good") card.classList.add("v-good-bg");
    else if (verdict === "fix") card.classList.add("v-fix-bg");
    else if (verdict === "cant") card.classList.add("v-cant-bg");
  }
}

function updateSummary() {
  const s = loadState();
  let good = 0, fix = 0, cant = 0;
  for (const k in s) {
    const v = s[k].verdict;
    if (v === "good") good++;
    else if (v === "fix") fix++;
    else if (v === "cant") cant++;
  }
  document.getElementById("stat-good").textContent = good;
  document.getElementById("stat-fix").textContent = fix;
  document.getElementById("stat-todo").textContent =
    N_WORDS - good - fix - cant;
}

function applyFilters() {
  const fv = document.getElementById("filter-verdict").value;
  const fb = document.getElementById("filter-bucket").value;
  const fs = document.getElementById("filter-search").value
    .toLowerCase().trim();
  const s = loadState();
  document.querySelectorAll(".sample").forEach(el => {
    const k = el.dataset.key;
    const verdict = (s[k] && s[k].verdict) || "todo";
    const bs = (el.dataset.buckets || "").split(",");
    const awing = el.dataset.awing.toLowerCase();
    const english = el.dataset.english.toLowerCase();
    let show = true;
    if (fv !== "all" && verdict !== fv) show = false;
    if (fb !== "all" && !bs.includes(fb)) show = false;
    if (fs && !awing.includes(fs) && !english.includes(fs)) show = false;
    el.classList.toggle("hidden", !show);
  });
}

function downloadVerdicts() {
  const s = loadState();
  const out = {
    version: 1,
    voice: VOICE_ID,
    exported_at: new Date().toISOString(),
    n_words: N_WORDS,
    verdicts: s,
  };
  const blob = new Blob([JSON.stringify(out, null, 2)],
    { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "verdicts.json";
  a.click();
  URL.revokeObjectURL(url);
}

function importVerdicts() {
  document.getElementById("import-file").click();
}

function handleImportFile(input) {
  const file = input.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    try {
      const data = JSON.parse(e.target.result);
      if (data.verdicts) {
        if (!confirm(
          "Replace all current ratings with the imported file?")) return;
        saveState(data.verdicts);
        location.reload();
      } else {
        alert("File doesn't look like a verdicts.json export.");
      }
    } catch (e) {
      alert("Failed to parse JSON: " + e.message);
    }
  };
  reader.readAsText(file);
  input.value = "";
}

function resetAll() {
  if (!confirm("Clear ALL ratings? This cannot be undone.")) return;
  localStorage.removeItem(STORAGE_KEY);
  location.reload();
}

// Restore on load
document.addEventListener("DOMContentLoaded", () => {
  const s = loadState();
  for (const k in s) {
    if (s[k].verdict) renderVerdict(k, s[k].verdict);
    if (s[k].candidate) {
      const inp = document.querySelector(
        `.candidate input[data-key="${k}"]`);
      if (inp) inp.value = s[k].candidate;
    }
  }
  updateSummary();
  applyFilters();
});
</script>

</body>
</html>
"""


def _build_sample_block(sample):
    """Build the HTML block for one sample word."""
    key = sample["key"]
    awing = sample["awing"]
    english = sample.get("english", "")
    buckets = sample.get("buckets", [])
    default_text = sample.get("default_speakable", "")
    gt_path = sample.get("ground_truth_wav", "")
    def_path = sample.get("default_mp3", "")

    bucket_tags = "".join(
        f'<span class="bucket-tag">{b}</span>' for b in buckets
    )
    bucket_data = ",".join(buckets)

    # HTML-safe escapes for awing/english (used in data attrs + display)
    def esc(s):
        return (s.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace('"', "&quot;"))

    awing_e = esc(awing)
    english_e = esc(english)
    default_e = esc(default_text)

    return f'''
  <div class="sample" data-key="{key}" data-buckets="{bucket_data}"
       data-awing="{awing_e}" data-english="{english_e}">
    <div class="sample-header">
      <span class="awing">{awing_e}</span>
      <span class="english">{english_e}</span>
      <span class="default-text">default → "{default_e}"</span>
      <span class="key">{key}</span>
    </div>
    <div class="buckets">{bucket_tags}</div>
    <div class="audio-row">
      <div class="audio-label" style="color:#047857">▶ Recording</div>
      <audio controls preload="none" src="{gt_path}"></audio>
    </div>
    <div class="audio-row">
      <div class="audio-label" style="color:#c2410c">▶ Edge TTS</div>
      <audio controls preload="none" src="{def_path}"></audio>
    </div>
    <div class="verdict-row">
      <button class="verdict-btn" data-key="{key}" data-verdict="good"
              onclick="setVerdict('{key}', 'good')">✓ Good</button>
      <button class="verdict-btn" data-key="{key}" data-verdict="fix"
              onclick="setVerdict('{key}', 'fix')">✗ Needs fix</button>
      <button class="verdict-btn" data-key="{key}" data-verdict="cant"
              onclick="setVerdict('{key}', 'cant')">? Can't tell</button>
    </div>
    <div class="candidate" data-key="{key}">
      <label>Candidate Swahili-style spelling (optional):</label>
      <input type="text" data-key="{key}"
             placeholder='e.g. "kwana" or "ga-ne" — your guess at what would sound closer'
             oninput="setCandidate('{key}', this.value)">
      <div class="help">
        Type whatever spelling you think Edge TTS Swahili would pronounce
        closer to your recording. No need to be perfect — Phase 2 will
        cluster these to find the patterns.
      </div>
    </div>
  </div>'''


def cmd_html(args):
    """Re-emit audit.html from manifest.json."""
    if not AUDIT_MANIFEST.exists():
        print(f"ERROR: {AUDIT_MANIFEST} not found. Run 'audit' first.")
        return False

    with open(AUDIT_MANIFEST, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    samples = manifest.get("samples", [])
    sample_blocks = "\n".join(_build_sample_block(s) for s in samples)

    # Distinct buckets across all samples for the filter dropdown
    all_buckets = set()
    for s in samples:
        for b in s.get("buckets", []):
            all_buckets.add(b)
    bucket_options = "\n".join(
        f'      <option value="{b}">{b}</option>'
        for b in sorted(all_buckets)
    )

    html = HTML_TEMPLATE
    html = html.replace("__GENERATED_AT__", manifest.get("generated_at", ""))
    html = html.replace("__VOICE__", manifest.get("voice", ""))
    html = html.replace("__VOICE_DESC__", manifest.get("voice_description", ""))
    html = html.replace("__N_WORDS__", str(manifest.get("n_words", 0)))
    html = html.replace("__BUCKET_OPTIONS__", bucket_options)
    html = html.replace("__SAMPLE_BLOCKS__", sample_blocks)

    HTML_OUT.write_text(html, encoding="utf-8")
    print(f"\nAudit page emitted: {HTML_OUT}")
    print(f"\nOpen in browser:")
    if sys.platform == "win32":
        print(f"   start {HTML_OUT}")
    elif sys.platform == "darwin":
        print(f"   open {HTML_OUT}")
    else:
        print(f"   xdg-open {HTML_OUT}")
    return True


# ---------------------------------------------------------------------------
# Subcommand: export — read downloaded verdicts.json and summarize
# ---------------------------------------------------------------------------

def cmd_export(args):
    """Read verdicts.json (downloaded from page) and print a summary
    clustered by linguistic bucket. Phase 2's mine command will analyze
    candidate spellings; this command is just a sanity-check that the
    downloaded file landed in the right place and has usable data.
    """
    if not VERDICTS_PATH.exists():
        print(f"ERROR: {VERDICTS_PATH} not found.")
        print()
        print("To create it: open the audit page, click 'Download verdicts JSON',")
        print(f"and save the file as {VERDICTS_PATH}")
        return False

    with open(VERDICTS_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    verdicts = data.get("verdicts", {})

    if not AUDIT_MANIFEST.exists():
        print(f"WARNING: {AUDIT_MANIFEST} not found — bucket grouping disabled.")
        sample_buckets = {}
    else:
        with open(AUDIT_MANIFEST, "r", encoding="utf-8") as f:
            manifest = json.load(f)
        sample_buckets = {s["key"]: s.get("buckets", [])
                          for s in manifest.get("samples", [])}

    # Tally
    n_good = sum(1 for v in verdicts.values() if v.get("verdict") == "good")
    n_fix = sum(1 for v in verdicts.values() if v.get("verdict") == "fix")
    n_cant = sum(1 for v in verdicts.values() if v.get("verdict") == "cant")
    n_with_candidate = sum(
        1 for v in verdicts.values()
        if v.get("verdict") == "fix" and v.get("candidate", "").strip()
    )

    print(f"Verdicts loaded from: {VERDICTS_PATH}")
    print(f"  Voice: {data.get('voice', 'unknown')}")
    print(f"  Exported at: {data.get('exported_at', 'unknown')}")
    print(f"  Total words rated: {len(verdicts)}")
    print(f"    Good:           {n_good}")
    print(f"    Needs fix:      {n_fix}  ({n_with_candidate} with candidate spelling)")
    print(f"    Can't tell:     {n_cant}")

    if n_fix == 0:
        print("\nNo 'needs fix' verdicts yet — nothing to mine.")
        return True

    # Per-bucket failure rate
    print("\nPer-bucket failure rate (needs-fix / total rated in bucket):")
    bucket_total = {}
    bucket_fix = {}
    for key, v in verdicts.items():
        verdict = v.get("verdict")
        if verdict not in ("good", "fix"):
            continue
        for b in sample_buckets.get(key, []):
            bucket_total[b] = bucket_total.get(b, 0) + 1
            if verdict == "fix":
                bucket_fix[b] = bucket_fix.get(b, 0) + 1

    for b in sorted(bucket_total, key=lambda x: -bucket_fix.get(x, 0)):
        total = bucket_total[b]
        fix = bucket_fix.get(b, 0)
        pct = (100 * fix / total) if total else 0
        bar = "█" * int(pct / 5)
        print(f"  {b:18s} {fix:3d}/{total:3d}  ({pct:5.1f}%)  {bar}")

    # Show the needs-fix words with candidate spellings (Phase 2 input)
    if n_with_candidate:
        print(f"\nWords flagged 'needs fix' with candidate spellings "
              f"({n_with_candidate}):")
        for key, v in sorted(verdicts.items()):
            if v.get("verdict") == "fix" and v.get("candidate", "").strip():
                cand = v["candidate"].strip()
                print(f"  {key:24s} → '{cand}'")
    else:
        print("\nNo candidate spellings typed yet. Phase 2 mining works best")
        print("when at least 20-30 fixes have a candidate. Even a rough guess")
        print("helps cluster the patterns.")
    return True


# ---------------------------------------------------------------------------
# Subcommand: status
# ---------------------------------------------------------------------------

def cmd_status(args):
    print(f"Pattern-mine directory: {MINE_DIR}")
    if not MINE_DIR.exists():
        print("  (not initialized — run 'audit')")
        return True
    gt = list(GROUND_TRUTH_DIR.glob("*.wav")) if GROUND_TRUTH_DIR.exists() else []
    print(f"  Ground-truth WAVs:  {len(gt)}")
    if AUDIT_MANIFEST.exists():
        with open(AUDIT_MANIFEST, "r", encoding="utf-8") as f:
            manifest = json.load(f)
        voice = manifest.get("voice", "unknown")
        n = manifest.get("n_words", 0)
        clips = list((DEFAULT_DIR / voice).glob("*.mp3")) if (
            DEFAULT_DIR / voice).exists() else []
        print(f"  Voice:              {voice}")
        print(f"  Words in manifest:  {n}")
        print(f"  Edge TTS clips:     {len(clips)}")
    else:
        print("  (no manifest — run 'audit')")
    if HTML_OUT.exists():
        print(f"  Audit page:         {HTML_OUT}")
    if VERDICTS_PATH.exists():
        with open(VERDICTS_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        v = data.get("verdicts", {})
        n_rated = sum(1 for x in v.values() if x.get("verdict"))
        print(f"  Verdicts file:      {VERDICTS_PATH}  ({n_rated} rated)")
    else:
        print(f"  Verdicts file:      (not yet downloaded)")
    return True


# ---------------------------------------------------------------------------
# Subcommand: clean
# ---------------------------------------------------------------------------

def cmd_clean(args):
    removed = 0
    for d in (DEFAULT_DIR, TEMP_DIR):
        if d.exists():
            shutil.rmtree(d)
            removed += 1
            print(f"  Removed {d}")
    for f in (HTML_OUT,):
        if f.exists():
            f.unlink()
            removed += 1
            print(f"  Removed {f}")
    if args.deep:
        for d in (GROUND_TRUTH_DIR,):
            if d.exists():
                shutil.rmtree(d)
                removed += 1
                print(f"  Removed {d}")
        for f in (AUDIT_MANIFEST, VERDICTS_PATH):
            if f.exists():
                f.unlink()
                removed += 1
                print(f"  Removed {f}")
    if removed == 0:
        print("  (nothing to clean)")
    return True


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    p = argparse.ArgumentParser(
        description="Pattern-mine awing_to_speakable() defaults from your "
                    "recordings. NO Whisper/ASR involved.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = p.add_subparsers(dest="command", required=True)

    audit = sub.add_parser("audit",
        help="Generate Edge TTS clips for every recording, emit audit HTML")
    audit.add_argument("--voice", default="young_woman",
        help=f"Voice to audit (default: young_woman). "
             f"Valid: {','.join(VOICE_CHARACTERS.keys())}")
    audit.add_argument("--samples", type=int, default=None,
        help="Limit to first N recordings (deterministic order)")
    audit.add_argument("--force", action="store_true",
        help="Regenerate Edge TTS clips even if they exist")

    html = sub.add_parser("html",
        help="Re-emit audit.html from existing manifest.json")

    export = sub.add_parser("export",
        help="Print summary of downloaded verdicts.json")

    status = sub.add_parser("status",
        help="Show file counts at each stage")

    clean = sub.add_parser("clean",
        help="Remove generated audio + audit page")
    clean.add_argument("--deep", action="store_true",
        help="Also remove ground-truth WAVs + verdicts file + manifest")

    args = p.parse_args()
    handlers = {
        "audit": cmd_audit,
        "html": cmd_html,
        "export": cmd_export,
        "status": cmd_status,
        "clean": cmd_clean,
    }
    ok = handlers[args.command](args)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
