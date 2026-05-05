#!/usr/bin/env python3
"""Build a self-contained HTML page for native-speaker review of
content-audit MISMATCH and UNKNOWN entries.

Reads `models/content_audit/audit.json` (produced by
`scripts/audit_app_content.py`), filters to MISMATCH + UNKNOWN
entries, and writes `models/content_audit/reviewer.html` — a
single-file HTML page that can be opened in Chrome (file://).

Page features:
- Tabs by file (screens first, vocabulary last) with mismatch counts
- Per-row card showing: Awing, app's gloss, dictionary's gloss
  (when known), file:line link, Bible reference if any
- Five action buttons per row:
    * KEEP APP    — app gloss is fine, dict was wrong/incomplete
    * USE DICT    — replace app gloss with dict's gloss
    * EDIT        — provide your own correction (text input)
    * COMPOUND    — multi-word phrase, audit can't validate, skip
    * NEEDS-RECHECK — unsure, come back later
- localStorage persists progress per row across reload
- Export button downloads a JSON file for batch application by
  scripts/apply_audit_corrections.py

Buttons use event delegation with data-* attributes (no inline
onclick=). This is required because Awing words contain apostrophes
that break inline JavaScript string literals.

Run:
    python3 scripts/build_audit_reviewer.py
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
AUDIT_JSON = ROOT / "models" / "content_audit" / "audit.json"
OUTPUT_HTML = ROOT / "models" / "content_audit" / "reviewer.html"

FILE_ORDER = [
    "lib/screens/expert/conversation_screen.dart",
    "lib/screens/stories_screen.dart",
    "lib/screens/medium/sentences_screen.dart",
    "lib/screens/expert/expert_quiz_screen.dart",
    "lib/data/awing_vocabulary.dart",
]


def main() -> int:
    if not AUDIT_JSON.exists():
        print(f"ERROR: {AUDIT_JSON} missing. Run "
              f"`python3 scripts/audit_app_content.py` first.")
        return 1

    audit = json.loads(AUDIT_JSON.read_text(encoding="utf-8"))
    pairs = audit.get("pairs", [])

    actionable = [p for p in pairs
                  if p.get("verdict") in ("MISMATCH", "UNKNOWN")]
    by_file: dict[str, list[dict]] = {}
    for p in actionable:
        f = p.get("file", "<unknown>")
        by_file.setdefault(f, []).append(p)

    def file_sort_key(f: str) -> tuple[int, int, str]:
        if f in FILE_ORDER:
            return (0, FILE_ORDER.index(f), f)
        return (1, -len(by_file[f]), f)

    files_sorted = sorted(by_file.keys(), key=file_sort_key)

    summary = {
        "total_actionable": len(actionable),
        "files": [
            {
                "file": f,
                "count": len(by_file[f]),
                "mismatch": sum(1 for p in by_file[f]
                                if p["verdict"] == "MISMATCH"),
                "unknown": sum(1 for p in by_file[f]
                               if p["verdict"] == "UNKNOWN"),
            }
            for f in files_sorted
        ],
    }

    embedded = {
        "summary": summary,
        "groups": {f: by_file[f] for f in files_sorted},
        "files_sorted": files_sorted,
    }

    OUTPUT_HTML.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_HTML.write_text(_render_html(embedded), encoding="utf-8")

    print(f"Wrote {OUTPUT_HTML}")
    print(f"  Total actionable: {summary['total_actionable']}")
    for f in summary["files"]:
        print(f"    {f['file']:<55}  mismatch={f['mismatch']}  "
              f"unknown={f['unknown']}")
    print()
    win_path = str(OUTPUT_HTML).replace(
        "/sessions/focused-funny-clarke/mnt/Awing",
        "C:\\Users\\samag\\OneDrive\\Documents\\Claude\\Awing",
    ).replace("/", "\\")
    print(f"Open in Chrome: file:///{win_path}")
    return 0


def _render_html(data: dict) -> str:
    return _TEMPLATE.replace(
        "__PAYLOAD__", json.dumps(data, ensure_ascii=False))


_TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Awing Content Audit — Reviewer</title>
<style>
  :root {
    --bg: #f7f8fa; --card: #ffffff; --border: #d8dde6;
    --text: #1f2937; --muted: #6b7280; --primary: #2563eb;
    --green: #16a34a; --amber: #d97706; --red: #dc2626;
    --grey: #6b7280; --purple: #7c3aed;
  }
  body { font: 15px/1.5 -apple-system, "Segoe UI", Roboto, sans-serif;
    background: var(--bg); color: var(--text); margin: 0; padding: 0; }
  header { background: white; border-bottom: 1px solid var(--border);
    padding: 16px 24px; position: sticky; top: 0; z-index: 10; }
  h1 { margin: 0 0 6px 0; font-size: 20px; }
  .summary { color: var(--muted); font-size: 13px; }
  .actions-bar { margin-top: 10px; display: flex; gap: 8px;
    flex-wrap: wrap; align-items: center; }
  button { font: inherit; cursor: pointer;
    border: 1px solid var(--border); background: white;
    color: var(--text); padding: 6px 12px; border-radius: 6px; }
  button:hover { background: #f3f4f6; }
  button.primary { background: var(--primary); color: white;
    border-color: var(--primary); }
  button.primary:hover { background: #1d4ed8; }
  button[disabled] { opacity: 0.4; cursor: not-allowed; }
  .tabs { display: flex; gap: 4px; flex-wrap: wrap;
    padding: 12px 24px 0; }
  .tab { padding: 8px 14px; border: 1px solid var(--border);
    border-bottom: none; border-radius: 8px 8px 0 0; cursor: pointer;
    background: white; font-size: 13px; color: var(--muted); }
  .tab.active { background: var(--bg); color: var(--text);
    font-weight: 600; }
  .tab .count { background: var(--red); color: white;
    border-radius: 999px; padding: 2px 7px; margin-left: 6px;
    font-size: 11px; }
  .tab .done { background: var(--green); }
  main { padding: 16px 24px 80px; }
  .row { background: var(--card); border: 1px solid var(--border);
    border-radius: 8px; padding: 14px 16px; margin-bottom: 10px;
    display: grid; grid-template-columns: 1fr auto;
    gap: 12px 16px; align-items: start; }
  .row.done { opacity: 0.5; }
  .meta { font-size: 11px; color: var(--muted); margin-bottom: 4px;
    font-family: ui-monospace, "SF Mono", monospace; }
  .awing { font-size: 18px; font-weight: 600; margin-bottom: 6px; }
  .gloss-row { display: flex; gap: 18px; flex-wrap: wrap;
    font-size: 14px; }
  .gloss { padding: 4px 0; }
  .gloss .label { font-size: 11px; color: var(--muted);
    text-transform: uppercase; letter-spacing: 0.5px; display: block; }
  .gloss-app { color: var(--red); font-weight: 500; }
  .gloss-dict { color: var(--green); font-weight: 500; }
  .gloss-bible { color: var(--purple); font-style: italic; }
  .col-actions { display: flex; flex-direction: column; gap: 6px;
    min-width: 200px; }
  .col-actions button { width: 100%; text-align: left;
    font-size: 12px; padding: 6px 10px; }
  button.act-keep { border-color: var(--amber); color: var(--amber); }
  button.act-dict { border-color: var(--green); color: var(--green); }
  button.act-edit { border-color: var(--primary);
    color: var(--primary); }
  button.act-comp { border-color: var(--grey); color: var(--grey); }
  button.act-recheck { border-color: var(--purple);
    color: var(--purple); }
  button.act-keep:hover { background: #fef3c7; }
  button.act-dict:hover { background: #dcfce7; }
  button.act-edit:hover { background: #dbeafe; }
  button.act-comp:hover { background: #f3f4f6; }
  button.act-recheck:hover { background: #ede9fe; }
  button.selected { background: currentColor !important;
    color: white !important; }
  .edit-input { display: none; margin-top: 6px; padding: 6px 10px;
    font: inherit; border: 1px solid var(--primary);
    border-radius: 4px; width: 100%; box-sizing: border-box;
    font-size: 13px; }
  .edit-input.show { display: block; }
  .badge { display: inline-block; padding: 1px 6px; border-radius: 3px;
    font-size: 10px; font-weight: 600; text-transform: uppercase;
    letter-spacing: 0.5px; margin-left: 6px; }
  .badge.MISMATCH { background: #fee2e2; color: var(--red); }
  .badge.UNKNOWN { background: #fef3c7; color: var(--amber); }
  footer { position: fixed; bottom: 0; left: 0; right: 0;
    background: white; border-top: 1px solid var(--border);
    padding: 12px 24px; display: flex; gap: 12px; align-items: center;
    z-index: 5; }
  .stat { font-size: 13px; color: var(--muted); }
  .stat strong { color: var(--text); }
  .empty { padding: 60px 20px; text-align: center; color: var(--muted); }
  .decision-tag { color: var(--green); font-weight: 600;
    margin-left: 8px; }
</style>
</head>
<body>

<header>
  <h1>Awing Content Audit — Reviewer</h1>
  <div class="summary" id="summary"></div>
  <div class="actions-bar">
    <button id="btn-export" class="primary">⬇ Export corrections JSON</button>
    <button id="btn-reset" style="border-color: var(--red);
      color: var(--red);">↺ Reset all decisions</button>
    <span class="stat" style="margin-left: auto;" id="overall-stat"></span>
  </div>
</header>

<div class="tabs" id="tabs"></div>

<main id="rows"></main>

<footer>
  <span class="stat" id="footer-stat"></span>
  <div style="flex: 1;"></div>
  <button id="btn-prev">← Previous file</button>
  <button id="btn-next">Next file →</button>
</footer>

<script>
const DATA = __PAYLOAD__;
const STORAGE_KEY = 'awing_audit_reviewer_v1';

let decisions = {};
try {
  decisions = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
} catch (e) { decisions = {}; }

let activeFile = DATA.files_sorted[0];
let currentRows = [];

function saveDecisions() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(decisions));
}

function rowKey(p) { return p.file + ':' + p.line + ':' + p.awing; }

function renderHeader() {
  const total = DATA.summary.total_actionable;
  const decided = Object.keys(decisions).length;
  document.getElementById('summary').textContent =
    total + ' actionable rows across ' + DATA.summary.files.length
    + " files. Click a tab to review that file's mismatches.";
  document.getElementById('overall-stat').innerHTML =
    '<strong>' + decided + '</strong> / ' + total + ' reviewed ('
    + (decided/total*100).toFixed(0) + '%)';
  document.getElementById('footer-stat').innerHTML =
    decided + ' decisions saved locally. Export when done.';
}

function renderTabs() {
  const tabs = document.getElementById('tabs');
  tabs.innerHTML = '';
  for (const f of DATA.files_sorted) {
    const total = DATA.groups[f].length;
    const done = DATA.groups[f].filter(p => decisions[rowKey(p)]).length;
    const tab = document.createElement('div');
    tab.className = 'tab' + (f === activeFile ? ' active' : '');
    const short = f.split('/').pop();
    const countSpan = document.createElement('span');
    countSpan.className = 'count' + (done === total ? ' done' : '');
    countSpan.textContent = done + '/' + total;
    tab.textContent = short + ' ';
    tab.appendChild(countSpan);
    tab.dataset.file = f;
    tabs.appendChild(tab);
  }
}

function renderRows() {
  const container = document.getElementById('rows');
  container.innerHTML = '';
  currentRows = DATA.groups[activeFile] || [];
  if (!currentRows.length) {
    container.innerHTML = '<div class="empty">Nothing to review here.</div>';
    return;
  }
  for (let i = 0; i < currentRows.length; i++) {
    container.appendChild(renderRow(currentRows[i], i));
  }
}

function makeBtn(label, klass, dataAct, decision, disabled) {
  const b = document.createElement('button');
  b.className = klass + (decision && decision.action === dataAct
                          ? ' selected' : '');
  b.textContent = label;
  b.dataset.act = dataAct;
  if (disabled) b.disabled = true;
  return b;
}

function makeGloss(label, value, valueClass) {
  const g = document.createElement('div');
  g.className = 'gloss';
  const lbl = document.createElement('span');
  lbl.className = 'label';
  lbl.textContent = label;
  const val = document.createElement('span');
  val.className = valueClass;
  val.textContent = value;
  g.appendChild(lbl);
  g.appendChild(val);
  return g;
}

function renderRow(p, index) {
  const k = rowKey(p);
  const decision = decisions[k];
  const dictGloss = (p.vocab_says || []).join(', ') || '—';

  const div = document.createElement('div');
  div.className = 'row' + (decision ? ' done' : '');
  div.dataset.index = String(index);

  // Info column
  const info = document.createElement('div');
  info.className = 'col-info';

  const meta = document.createElement('div');
  meta.className = 'meta';
  meta.textContent = p.file + ':' + p.line;
  const badge = document.createElement('span');
  badge.className = 'badge ' + p.verdict;
  badge.textContent = p.verdict;
  meta.appendChild(badge);
  if (decision) {
    const tag = document.createElement('span');
    tag.className = 'decision-tag';
    tag.textContent = '✓ ' + decision.action.toUpperCase()
      + (decision.value ? ': "' + decision.value + '"' : '');
    meta.appendChild(tag);
  }
  info.appendChild(meta);

  const awingDiv = document.createElement('div');
  awingDiv.className = 'awing';
  awingDiv.textContent = p.awing;
  info.appendChild(awingDiv);

  const glossRow = document.createElement('div');
  glossRow.className = 'gloss-row';
  glossRow.appendChild(makeGloss('App says', p.english, 'gloss-app'));
  glossRow.appendChild(makeGloss('Dictionary says', dictGloss,
                                 'gloss-dict'));
  if (p.bible_match) {
    glossRow.appendChild(makeGloss('Bible', p.bible_match,
                                   'gloss-bible'));
  }
  info.appendChild(glossRow);

  const editInput = document.createElement('input');
  editInput.type = 'text';
  editInput.className = 'edit-input';
  editInput.placeholder =
    'Type the correct English gloss, then press Enter…';
  if (decision && decision.action === 'edit') {
    editInput.classList.add('show');
    editInput.value = decision.value || '';
  }
  info.appendChild(editInput);

  div.appendChild(info);

  // Actions column
  const actions = document.createElement('div');
  actions.className = 'col-actions';
  actions.appendChild(makeBtn("✓ KEEP APP'S GLOSS", 'act-keep',
                              'keep', decision, false));
  actions.appendChild(makeBtn('→ USE DICTIONARY', 'act-dict', 'dict',
                              decision, dictGloss === '—'));
  actions.appendChild(makeBtn('✎ EDIT (custom)', 'act-edit', 'edit',
                              decision, false));
  actions.appendChild(makeBtn('⊟ COMPOUND/PARTICLE', 'act-comp',
                              'compound', decision, false));
  actions.appendChild(makeBtn('? NEEDS RECHECK', 'act-recheck',
                              'recheck', decision, false));
  div.appendChild(actions);

  return div;
}

function decide(k, action, value) {
  decisions[k] = { action, value: value || '', ts: Date.now() };
  saveDecisions();
  renderAll();
}

function exportCorrections() {
  const corrections = [];
  for (const f of DATA.files_sorted) {
    for (const p of DATA.groups[f]) {
      const d = decisions[rowKey(p)];
      if (!d) continue;
      let newGloss = null;
      if (d.action === 'keep') newGloss = p.english;
      else if (d.action === 'dict') newGloss =
        (p.vocab_says || []).join(', ');
      else if (d.action === 'edit') newGloss = d.value;
      else continue;
      if (newGloss && newGloss !== p.english) {
        corrections.push({
          file: p.file,
          line: p.line,
          awing: p.awing,
          old_english: p.english,
          new_english: newGloss,
          decision: d.action,
        });
      }
    }
  }
  const blob = new Blob([JSON.stringify(corrections, null, 2)],
                        { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'awing_audit_corrections_'
    + new Date().toISOString().slice(0, 10) + '.json';
  a.click();
  alert('Exported ' + corrections.length + ' corrections.');
}

function resetAll() {
  if (!confirm('Erase ALL review decisions? This cannot be undone.'))
    return;
  decisions = {};
  saveDecisions();
  renderAll();
}

function prevTab() {
  const i = DATA.files_sorted.indexOf(activeFile);
  if (i > 0) { activeFile = DATA.files_sorted[i - 1]; renderAll(); }
}
function nextTab() {
  const i = DATA.files_sorted.indexOf(activeFile);
  if (i < DATA.files_sorted.length - 1) {
    activeFile = DATA.files_sorted[i + 1];
    renderAll();
  }
}

function renderAll() {
  renderHeader();
  renderTabs();
  renderRows();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// === Event delegation — single source of truth, no inline handlers ===

document.addEventListener('click', function (e) {
  // Tab clicks
  const tab = e.target.closest('.tab');
  if (tab && tab.dataset.file) {
    activeFile = tab.dataset.file;
    renderAll();
    return;
  }

  // Per-row action buttons
  const btn = e.target.closest('button[data-act]');
  if (btn) {
    const row = btn.closest('.row');
    if (!row) return;
    const idx = parseInt(row.dataset.index, 10);
    const p = currentRows[idx];
    if (!p) return;
    const k = rowKey(p);
    const action = btn.dataset.act;
    if (action === 'keep')          decide(k, 'keep', p.english);
    else if (action === 'dict')     decide(k, 'dict',
                                        (p.vocab_says || []).join(', '));
    else if (action === 'edit') {
      const input = row.querySelector('input.edit-input');
      if (input) {
        input.classList.add('show');
        input.focus();
      }
    }
    else if (action === 'compound') decide(k, 'compound', '');
    else if (action === 'recheck')  decide(k, 'recheck', '');
    return;
  }

  // Top/bottom action buttons
  if (e.target.id === 'btn-export') return exportCorrections();
  if (e.target.id === 'btn-reset')  return resetAll();
  if (e.target.id === 'btn-prev')   return prevTab();
  if (e.target.id === 'btn-next')   return nextTab();
});

// Save edit input on Enter
document.addEventListener('keydown', function (e) {
  if (e.key !== 'Enter') return;
  const input = e.target;
  if (!input.matches || !input.matches('input.edit-input')) return;
  const row = input.closest('.row');
  if (!row) return;
  const idx = parseInt(row.dataset.index, 10);
  const p = currentRows[idx];
  if (!p) return;
  const v = input.value.trim();
  if (v) decide(rowKey(p), 'edit', v);
});

// Save edit input on blur (capture phase since blur doesn't bubble)
document.addEventListener('blur', function (e) {
  const input = e.target;
  if (!input.matches || !input.matches('input.edit-input')) return;
  const row = input.closest('.row');
  if (!row) return;
  const idx = parseInt(row.dataset.index, 10);
  const p = currentRows[idx];
  if (!p) return;
  const v = input.value.trim();
  if (!v) return;
  const k = rowKey(p);
  if (!decisions[k] || decisions[k].action !== 'edit'
      || decisions[k].value !== v) {
    decide(k, 'edit', v);
  }
}, true);

renderAll();
</script>
</body>
</html>
"""


if __name__ == "__main__":
    sys.exit(main())
