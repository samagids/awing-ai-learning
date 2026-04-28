#!/usr/bin/env python3
"""Find Awing words in the Bible NT that are NOT in lib/data/awing_vocabulary.dart.

The Bible is treated here as a WORDLIST SOURCE — we're extracting general
Awing vocabulary, not biblical content for the app. Bible verses surface
words like child, water, go, eat, mother, father, etc., that appear in
ordinary Awing speech and aren't tied to religious context.

Output (under contributions/bible_vocab/):
  candidate_words.json     — new Awing words sorted by frequency, with
                             example verses showing usage context.
                             Each entry has fields:
                               awing:  the new word
                               freq:   number of occurrences in NT
                               examples: up to 3 (verse_ref, awing, english)
  candidate_words.html     — browsable preview for Dr. Sama review.

Workflow:
  1. Run this script (reads parallel + vocab, writes candidates).
  2. Open candidate_words.html. Dr. Sama / Dr. Guidion approves the
     ones that are real Awing words (not proper nouns, not Bible-only
     theological terms). Marks an English gloss for each.
  3. We add the approved entries to lib/data/awing_vocabulary.dart with
     a // source: bible_corpus comment for traceability.

This way: (a) the app's displayed phrases/sentences/stories never come
from Bible text, (b) the vocabulary still benefits from CABTAL's
authoritative translation as a wordlist source.
"""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PARALLEL = REPO_ROOT / "corpus" / "parallel" / "nt_aligned.json"
VOCAB_DART = REPO_ROOT / "lib" / "data" / "awing_vocabulary.dart"
OUT_DIR = REPO_ROOT / "contributions" / "bible_vocab"


_TONE_DIACRITICS = {"́", "̀", "̂", "̌", "̃", "̄"}


def _normalise(s: str) -> str:
    """Lowercase, strip tone marks. Used for vocab membership testing."""
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if c not in _TONE_DIACRITICS)
    return unicodedata.normalize("NFC", s).lower().strip()


def _tokenise(text: str) -> list[str]:
    """Split Awing into surface-form word tokens."""
    cleaned = re.sub(r"[.,!?;:\"\(\)\[\]…—–]", " ", text)
    return [w for w in cleaned.split() if w.strip()]


def parse_existing_vocab(path: Path) -> set[str]:
    """Return the set of normalised Awing words already in vocab.dart."""
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8")
    pat = re.compile(
        r"AwingWord\(\s*awing:\s*(['\"])((?:\\.|(?!\1).)*)\1",
        re.DOTALL,
    )
    out: set[str] = set()
    for m in pat.finditer(text):
        awing = m.group(2).replace("\\'", "'").replace('\\"', '"')
        out.add(_normalise(awing))
        # Also index without final vowel — Awing has long/short forms,
        # and vocab.dart tends to store one or the other but not both.
        # This avoids treating "shaala" as new when "shaal" is in vocab.
        if len(awing) >= 4 and awing[-1] in "aeiouəɛɔɨ":
            out.add(_normalise(awing[:-1]))
    # Also AwingPhrase entries — some single-word phrases get stored there.
    pat2 = re.compile(
        r"AwingPhrase\(\s*awing:\s*(['\"])((?:\\.|(?!\1).)*)\1",
        re.DOTALL,
    )
    for m in pat2.finditer(text):
        awing = m.group(2).replace("\\'", "'").replace('\\"', '"')
        for tok in _tokenise(awing):
            out.add(_normalise(tok))
    return out


# Known proper nouns / Bible-only terms to skip. Catches the obvious
# religious-context tokens that we don't want as general vocabulary.
# This isn't exhaustive — Dr. Sama's review is the final filter.
_BIBLE_PROPER_NOUNS = {
    # Direct transliterations of Hebrew/Greek names common in NT
    "yeso", "klisto", "yesəkristə",
    "matiye", "maakə", "lukasə", "jɔnə", "pɔlə", "petelə",
    "petər", "petəl", "andələ", "yakubə", "yakob", "yopə",
    "mali", "mariam", "yusufu", "yosuf", "abalaam", "ablaam",
    "isaakə", "yakob", "musa", "moisə", "moisi", "elia",
    "isaiya", "ysaya", "danielə", "davitə",
    # Place names
    "izlael", "yelusalemə", "judiya", "samaliya", "galilea",
    "kɔlinə", "ɛfɛsɔ", "atɛnə", "lomə", "kanan", "betəlɛhɛm",
    "betəleem", "nazaletə", "naazəletə",
    # Theological terms tied to Bible
    "klistɔ̂nə", "klistayanə",
}


def find_examples(parallel: list[dict], word_norm: str, n: int = 3) -> list[dict]:
    """Find up to n verses that contain the word (matched via NFD-stripped
    lowercase comparison). Returns dicts with ref/awing/english."""
    out = []
    for v in parallel:
        toks = _tokenise(v["awing"])
        for tok in toks:
            if _normalise(tok) == word_norm:
                out.append({
                    "ref": v["ref"],
                    "awing": v["awing"],
                    "english": v["english"],
                })
                break
        if len(out) >= n:
            break
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--min-freq", type=int, default=3,
                    help="Skip words appearing fewer than N times in NT "
                         "(low-freq tokens are usually rare conjugations or "
                         "unique forms not worth adding). Default: 3.")
    ap.add_argument("--max-candidates", type=int, default=500,
                    help="Cap on number of candidate words emitted. Default: 500.")
    args = ap.parse_args()

    if not PARALLEL.exists():
        print(f"ERROR: {PARALLEL} missing. Run scripts/build_bible_parallel.py first.")
        return 1

    print(f"Loading parallel corpus from {PARALLEL.relative_to(REPO_ROOT)}...")
    parallel = json.loads(PARALLEL.read_text(encoding="utf-8"))
    print(f"  {len(parallel)} parallel verse pairs")

    print(f"Loading existing vocabulary from {VOCAB_DART.relative_to(REPO_ROOT)}...")
    existing = parse_existing_vocab(VOCAB_DART)
    print(f"  {len(existing)} normalised entries")

    print()
    print("Scanning Bible verses for new tokens...")
    counter: Counter[str] = Counter()
    surface_form: dict[str, str] = {}  # normalised -> first-seen surface form
    for v in parallel:
        for tok in _tokenise(v["awing"]):
            norm = _normalise(tok)
            if not norm or len(norm) < 2:
                continue
            if any(c.isdigit() for c in norm):
                continue
            if norm in existing:
                continue
            if norm in _BIBLE_PROPER_NOUNS:
                continue
            counter[norm] += 1
            if norm not in surface_form:
                surface_form[norm] = tok

    new_count = len(counter)
    above_min = sum(1 for w, c in counter.items() if c >= args.min_freq)
    print(f"  {new_count} unique tokens not in vocab")
    print(f"  {above_min} appear >= {args.min_freq}x (worth reviewing)")

    print()
    print("Building candidate list with example verses...")
    candidates = []
    for norm, freq in counter.most_common():
        if freq < args.min_freq:
            break
        if len(candidates) >= args.max_candidates:
            break
        examples = find_examples(parallel, norm, n=3)
        candidates.append({
            "awing": surface_form[norm],
            "norm": norm,
            "freq": freq,
            "examples": examples,
        })

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    json_path = OUT_DIR / "candidate_words.json"
    json_path.write_text(json.dumps(candidates, ensure_ascii=False, indent=2),
                         encoding="utf-8")
    print(f"  Wrote {json_path.relative_to(REPO_ROOT)} ({len(candidates)} candidates)")

    # HTML preview
    rows = []
    for i, c in enumerate(candidates):
        ex_html = "<br>".join(
            f"<small>{html.escape(e['ref'])}: {html.escape(e['english'][:120])}"
            f"<br><em>{html.escape(e['awing'][:120])}</em></small>"
            for e in c["examples"]
        )
        rows.append(f"""
        <tr>
          <td>{i+1}</td>
          <td><strong>{html.escape(c['awing'])}</strong></td>
          <td><code>{html.escape(c['norm'])}</code></td>
          <td>{c['freq']}</td>
          <td>{ex_html}</td>
          <td><input type="text" placeholder="English gloss" data-norm="{html.escape(c['norm'])}"></td>
          <td><label><input type="checkbox" data-norm-add="{html.escape(c['norm'])}"> add</label></td>
        </tr>""")
    rows_html = "\n".join(rows)

    page = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Bible vocabulary candidates</title>
<style>
  body {{ font: 14px/1.4 system-ui, sans-serif; margin: 1.5em; max-width: 1300px; }}
  table {{ border-collapse: collapse; width: 100%; margin-top: 1em; }}
  th, td {{ padding: 6px 10px; border-bottom: 1px solid #ddd; vertical-align: top; }}
  th {{ background: #fafafa; text-align: left; position: sticky; top: 0; }}
  small {{ color: #555; font-size: 12px; }}
  input[type=text] {{ width: 14em; padding: 4px; }}
  .legend {{ background: #f0fdf4; border-left: 4px solid #16a34a;
              padding: 0.8em 1em; border-radius: 3px; }}
  button {{ padding: 8px 16px; cursor: pointer; }}
</style></head><body>
<h1>Bible vocabulary candidates</h1>
<div class="legend">
  <strong>Use:</strong> Awing words found in the NT corpus that aren't yet in
  <code>awing_vocabulary.dart</code>. Review the example verses for context.
  Type an English gloss + tick "add" for each one to keep. Click Export.
  Words you skip stay out.
</div>
<p>{len(candidates)} candidates · sorted by frequency in NT (most common first).</p>
<table>
  <thead><tr>
    <th>#</th><th>Awing</th><th>Norm</th><th>Freq</th>
    <th>Example verses</th><th>English gloss</th><th>Add?</th>
  </tr></thead>
  <tbody>{rows_html}</tbody>
</table>
<p style="margin-top:1.5em;">
  <button onclick="exportRatings()">Export approved entries (JSON)</button>
  <span id="status" style="margin-left: 1em; color: #666;"></span>
</p>
<script>
const KEY = "bible_vocab_review";
document.addEventListener("change", e => {{
  const saved = JSON.parse(localStorage.getItem(KEY) || "{{}}");
  if (e.target.dataset.norm !== undefined) {{
    saved[e.target.dataset.norm] = saved[e.target.dataset.norm] || {{}};
    saved[e.target.dataset.norm].gloss = e.target.value;
  }}
  if (e.target.dataset.normAdd !== undefined) {{
    saved[e.target.dataset.normAdd] = saved[e.target.dataset.normAdd] || {{}};
    saved[e.target.dataset.normAdd].add = e.target.checked;
  }}
  localStorage.setItem(KEY, JSON.stringify(saved));
  document.getElementById("status").textContent = "Saved locally.";
}});
const saved = JSON.parse(localStorage.getItem(KEY) || "{{}}");
document.querySelectorAll("input[data-norm]").forEach(el => {{
  const v = saved[el.dataset.norm];
  if (v && v.gloss) el.value = v.gloss;
}});
document.querySelectorAll("input[data-norm-add]").forEach(el => {{
  const v = saved[el.dataset.normAdd];
  if (v && v.add) el.checked = true;
}});
function exportRatings() {{
  const approved = Object.entries(saved)
    .filter(([k, v]) => v && v.add && v.gloss)
    .map(([k, v]) => ({{ norm: k, gloss: v.gloss }}));
  const blob = new Blob([JSON.stringify(approved, null, 2)],
                        {{type: "application/json"}});
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "bible_vocab_approved.json";
  a.click();
  URL.revokeObjectURL(url);
  document.getElementById("status").textContent = "Exported.";
}}
</script>
</body></html>"""
    html_path = OUT_DIR / "candidate_words.html"
    html_path.write_text(page, encoding="utf-8")
    print(f"  Wrote {html_path.relative_to(REPO_ROOT)}")

    print()
    print("Open the HTML in Chrome on Windows:")
    win = str(html_path).replace("/mnt/c/", "C:\\").replace("/", "\\")
    print(f"  {win}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
