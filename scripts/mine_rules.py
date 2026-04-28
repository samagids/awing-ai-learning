#!/usr/bin/env python3
"""
mine_rules.py — Phase 2 of the pattern-mining pipeline.

Loads verdicts.json from Dr. Sama's 197-word audit + audit_manifest.json,
tests a library of candidate edits to awing_to_speakable() against the
FULL 197-word corpus, and ranks them by how many words they help vs.
hurt.

Each candidate rule is a concrete Python function that takes
(awing_original, current_default_output) and returns a modified output.
The validator applies the rule to every sample and classifies the
outcome against Dr. Sama's verdicts:

    HELP       — verdict was "fix", new output EXACTLY matches his candidate
    PARTIAL    — verdict was "fix", new output moves CLOSER to his candidate
                 (lower Levenshtein distance than default → candidate)
    HURT_FIX   — verdict was "fix", new output moves AWAY from candidate
                 (higher Levenshtein distance than default → candidate)
    HURT_GOOD  — verdict was "good", new output differs from default
                 (broke a pronunciation teacher already liked)
    NEUTRAL    — verdict was "cant" or unrated, or output unchanged

Score = HELP * 3  +  PARTIAL * 1  -  HURT_FIX * 2  -  HURT_GOOD * 5

Breaking a GOOD pronunciation is worse than missing a FIX, so HURT_GOOD
weighs heaviest. HELP beats PARTIAL because exact matches are what the
teacher actually typed.

Subcommands:
    propose   — run all seed rules through validation, emit ranked report
    list      — show verdict summary (how many fix/good/cant + by bucket)
    status    — check inputs and outputs

Usage:
    python scripts/mine_rules.py propose
    python scripts/mine_rules.py list
    python scripts/mine_rules.py status
"""

from __future__ import annotations

import json
import os
import re
import sys
import unicodedata
from pathlib import Path
from typing import Callable, Optional

# --------------------------------------------------------------------
# venv bootstrap — match the pattern used by every other script
# --------------------------------------------------------------------
def _ensure_venv():
    if sys.prefix != sys.base_prefix:
        return
    project_root = Path(__file__).resolve().parent.parent
    # Pick the venv python that matches the host OS; the other path may
    # exist on disk from a cross-platform clone but be un-executable here.
    if os.name == "nt":
        venv_python = project_root / "venv" / "Scripts" / "python.exe"
    else:
        venv_python = project_root / "venv" / "bin" / "python"
    if venv_python.exists() and os.path.abspath(str(venv_python)) != os.path.abspath(sys.executable):
        import subprocess
        result = subprocess.run([str(venv_python), __file__] + sys.argv[1:])
        sys.exit(result.returncode)

_ensure_venv()

# --------------------------------------------------------------------
# Imports that need the venv
# --------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

# Reuse the production pipeline's default mapping so any report
# differences are purely from the rule layer
from generate_audio_edge import awing_to_speakable  # noqa: E402

# --------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------
MINE_DIR = PROJECT_ROOT / "training_data" / "pattern_mine"
VERDICTS_PATH = MINE_DIR / "verdicts.json"
MANIFEST_PATH = MINE_DIR / "audit_manifest.json"
REPORT_MD_PATH = MINE_DIR / "rules_report.md"
REPORT_JSON_PATH = MINE_DIR / "rules_report.json"

# --------------------------------------------------------------------
# Levenshtein (stdlib doesn't ship it, and we don't want a pip dep)
# --------------------------------------------------------------------
def levenshtein(a: str, b: str) -> int:
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        curr = [i]
        for j, cb in enumerate(b, 1):
            ins = curr[j - 1] + 1
            dele = prev[j] + 1
            sub = prev[j - 1] + (0 if ca == cb else 1)
            curr.append(min(ins, dele, sub))
        prev = curr
    return prev[-1]


# --------------------------------------------------------------------
# Awing helpers (tone / cluster detection)
# --------------------------------------------------------------------

# Match the production tone-mark set
_TONE_HIGH = '\u0301'      # á
_TONE_LOW = '\u0300'       # à
_TONE_FALLING = '\u0302'   # â
_TONE_RISING = '\u030C'    # ǎ
_TONE_ALL = {_TONE_HIGH, _TONE_LOW, _TONE_FALLING, _TONE_RISING}

_AWING_VOWELS_BASE = set("aeiouɛɔəɨAEIOUƐƆƏƖ")

def _awing_chars_nfd(text: str):
    """Yield (base_char, tones:set) for each glyph."""
    text = unicodedata.normalize("NFC", text)
    for ch in text:
        nfd = unicodedata.normalize("NFD", ch)
        base = ""
        tones = set()
        for c in nfd:
            if c in _TONE_ALL:
                tones.add(c)
            elif unicodedata.category(c).startswith("M"):
                continue  # strip other combiners too
            else:
                base += c
        yield base, tones


def _last_awing_vowel_tone(awing: str) -> Optional[str]:
    """Tone on the last vowel ('high', 'low', 'falling', 'rising', 'mid', or None)."""
    last_tone = None
    for base, tones in _awing_chars_nfd(awing):
        if base and base[-1] in _AWING_VOWELS_BASE:
            if _TONE_HIGH in tones:
                last_tone = 'high'
            elif _TONE_LOW in tones:
                last_tone = 'low'
            elif _TONE_FALLING in tones:
                last_tone = 'falling'
            elif _TONE_RISING in tones:
                last_tone = 'rising'
            else:
                last_tone = 'mid'
    return last_tone


def _ends_with_awing_schwa(awing: str) -> bool:
    """Final character is ə (any diacritic)."""
    last_base = None
    for base, _ in _awing_chars_nfd(awing):
        if base:
            last_base = base[-1]
    return last_base == 'ə'


def _ends_with_awing_open_o(awing: str) -> bool:
    """Final character is ɔ (any diacritic)."""
    last_base = None
    for base, _ in _awing_chars_nfd(awing):
        if base:
            last_base = base[-1]
    return last_base == 'ɔ'


def _ends_with_awing_eng(awing: str) -> bool:
    """Final consonant is ŋ."""
    last_base = None
    for base, _ in _awing_chars_nfd(awing):
        if base:
            last_base = base[-1]
    return last_base == 'ŋ'


def _has_glottal(awing: str) -> bool:
    return any(ch in awing for ch in ("'", "\u2019", "\u2018", "\u02BC"))


def _glottal_positions(awing: str) -> list[int]:
    return [i for i, ch in enumerate(awing) if ch in ("'", "\u2019", "\u2018", "\u02BC")]


def _starts_with_awing_schwa(awing: str) -> bool:
    for base, _ in _awing_chars_nfd(awing):
        if base:
            return base[0] == 'ə'
    return False


# --------------------------------------------------------------------
# Rule library
#
# Each rule is (name, description, rule_fn) where rule_fn takes
# (awing_text, default_output) -> new_output
# --------------------------------------------------------------------

def rule_preserve_gh(awing: str, out: str) -> str:
    """Undo the gh→g collapse. Reapply awing_to_speakable WITHOUT the
    final gh→g step so Swahili TTS gets "gh" instead of "g".
    """
    # Start from awing and run the default pipeline but skip gh→g
    text = unicodedata.normalize("NFC", awing)
    # Strip tone diacritics
    stripped = []
    for char in text:
        nfd = unicodedata.normalize("NFD", char)
        clean = ""
        for c in nfd:
            cat = unicodedata.category(c)
            if cat.startswith("M"):
                if c in _TONE_ALL or c == '\u0303':
                    continue
            clean += c
        stripped.append(unicodedata.normalize("NFC", clean))
    text = "".join(stripped)
    text = text.replace("ŋg", "ngg").replace("Ŋg", "Ngg")
    text = text.replace("ŋk", "nk").replace("Ŋk", "Nk")
    for old, new in [
        ("Ɛ", "E"), ("ɛ", "e"),
        ("Ɔ", "O"), ("ɔ", "o"),
        ("Ə", "E"), ("ə", "e"),
        ("Ɨ", "I"), ("ɨ", "i"),
        ("Ŋ", "Ng"), ("ŋ", "ng"),
        ("ɣ", "gh"),
        ("ʼ", ""), ("\u2019", ""), ("\u2018", ""), ("'", ""),
    ]:
        text = text.replace(old, new)
    # SKIP the gh→g step here (this is the whole point of the rule)
    return re.sub(r"\s+", " ", text).strip()


def rule_final_h_any(awing: str, out: str) -> str:
    """If the output ends in a single vowel, append h.
    E.g. apo→apoh, le→leh, ade→adeh.
    """
    if not out:
        return out
    vowels = set("aeiou")
    if out[-1].lower() in vowels:
        # Only single trailing vowel (not already ending in a vowel+consonant
        # or double-vowel — we leave those alone unless another rule handles)
        return out + "h"
    return out


def rule_final_schwa_h(awing: str, out: str) -> str:
    """If the Awing word ends in ə, swap final 'e' → 'eh'.
    More targeted than rule_final_h_any.
    """
    if not _ends_with_awing_schwa(awing):
        return out
    if out.endswith("e"):
        return out + "h"
    return out


def rule_final_open_o_eh(awing: str, out: str) -> str:
    """If the Awing word ends in ɔ (any tone), swap final 'o' → 'eh'.
    Covers: cha'tɔ́→chateh, lɛdnɔ́→ledneh, sɛdnɔ́→sedneh, wâakɔ́→waakeh.
    """
    if not _ends_with_awing_open_o(awing):
        return out
    if out.endswith("o"):
        return out[:-1] + "eh"
    return out


def rule_final_eng_gg(awing: str, out: str) -> str:
    """If the Awing word ends in ŋ (not ŋg/ŋk cluster), swap final 'ng' → 'gg'.
    Covers: kóŋ→kagg (sort of — the vowel mapping is Dr. Sama's call).
    """
    if not _ends_with_awing_eng(awing):
        return out
    if out.endswith("ng"):
        return out[:-2] + "gg"
    return out


def rule_glottal_to_k(awing: str, out: str) -> str:
    """Replace apostrophe deletion with 'k' insertion.
    Reapply default but keep ' → 'k'.
    """
    # Strip tone diacritics
    text = unicodedata.normalize("NFC", awing)
    stripped = []
    for char in text:
        nfd = unicodedata.normalize("NFD", char)
        clean = ""
        for c in nfd:
            cat = unicodedata.category(c)
            if cat.startswith("M"):
                if c in _TONE_ALL or c == '\u0303':
                    continue
            clean += c
        stripped.append(unicodedata.normalize("NFC", clean))
    text = "".join(stripped)
    text = text.replace("ŋg", "ngg").replace("Ŋg", "Ngg")
    text = text.replace("ŋk", "nk").replace("Ŋk", "Nk")
    for old, new in [
        ("Ɛ", "E"), ("ɛ", "e"),
        ("Ɔ", "O"), ("ɔ", "o"),
        ("Ə", "E"), ("ə", "e"),
        ("Ɨ", "I"), ("ɨ", "i"),
        ("Ŋ", "Ng"), ("ŋ", "ng"),
        ("ɣ", "gh"),
        ("ʼ", "k"), ("\u2019", "k"), ("\u2018", "k"), ("'", "k"),
    ]:
        text = text.replace(old, new)
    text = text.replace("gh", "g").replace("Gh", "G")
    return re.sub(r"\s+", " ", text).strip()


def rule_glottal_to_g(awing: str, out: str) -> str:
    """Replace apostrophe deletion with 'g' insertion. (Many of Dr. Sama's
    glottal candidates map to g/gg rather than k: po'á→pugg, fo'â→fogg,
    ŋá'ə→nyageh, jwa'ə→njwagg)."""
    text = unicodedata.normalize("NFC", awing)
    stripped = []
    for char in text:
        nfd = unicodedata.normalize("NFD", char)
        clean = ""
        for c in nfd:
            cat = unicodedata.category(c)
            if cat.startswith("M"):
                if c in _TONE_ALL or c == '\u0303':
                    continue
            clean += c
        stripped.append(unicodedata.normalize("NFC", clean))
    text = "".join(stripped)
    text = text.replace("ŋg", "ngg").replace("Ŋg", "Ngg")
    text = text.replace("ŋk", "nk").replace("Ŋk", "Nk")
    for old, new in [
        ("Ɛ", "E"), ("ɛ", "e"),
        ("Ɔ", "O"), ("ɔ", "o"),
        ("Ə", "E"), ("ə", "e"),
        ("Ɨ", "I"), ("ɨ", "i"),
        ("Ŋ", "Ng"), ("ŋ", "ng"),
        ("ɣ", "gh"),
        ("ʼ", "g"), ("\u2019", "g"), ("\u2018", "g"), ("'", "g"),
    ]:
        text = text.replace(old, new)
    text = text.replace("gh", "g").replace("Gh", "G")
    return re.sub(r"\s+", " ", text).strip()


def rule_drop_initial_schwa(awing: str, out: str) -> str:
    """Strip leading 'e' from output if Awing word starts with ə and is
    multi-syllabic. Covers Dr. Sama's əmɔ́→mok pattern."""
    if not _starts_with_awing_schwa(awing):
        return out
    if out.startswith("e") and len(out) > 2:
        return out[1:]
    return out


def rule_double_consonant_before_final_e(awing: str, out: str) -> str:
    """If output ends in CVCe (single vowel in penult, single C before
    final e), double the final consonant. Covers ləbə→lebbe, məse→messe.
    """
    if len(out) < 4 or not out.endswith("e"):
        return out
    # pattern: [a-z]+[vowel][cons](e)$
    m = re.match(r"^(.*?)([aeiou])([a-z])e$", out)
    if not m:
        return out
    if m.group(3) in "aeiou":
        return out
    return m.group(1) + m.group(2) + m.group(3) + m.group(3) + "e"


# Composite rules — combinations worth testing
def rule_gh_plus_final_h(awing: str, out: str) -> str:
    return rule_final_h_any(awing, rule_preserve_gh(awing, out))


def rule_gh_plus_final_schwa(awing: str, out: str) -> str:
    return rule_final_schwa_h(awing, rule_preserve_gh(awing, out))


def rule_schwa_plus_open_o(awing: str, out: str) -> str:
    return rule_final_open_o_eh(awing, rule_final_schwa_h(awing, out))


def rule_schwa_plus_open_o_plus_gh(awing: str, out: str) -> str:
    return rule_final_open_o_eh(awing, rule_final_schwa_h(awing, rule_preserve_gh(awing, out)))


RULE_LIBRARY: list[tuple[str, str, Callable[[str, str], str]]] = [
    ("preserve_gh",
     "Don't collapse gh→g (keep Awing ɣ written as gh for Swahili TTS)",
     rule_preserve_gh),
    ("final_h_any",
     "Append h to any output ending in a single vowel (apo→apoh)",
     rule_final_h_any),
    ("final_schwa_h",
     "If Awing ends in ə, append h to the final e (jage→jageh)",
     rule_final_schwa_h),
    ("final_open_o_eh",
     "If Awing ends in ɔ́, change final o→eh (chato→chateh)",
     rule_final_open_o_eh),
    ("final_eng_gg",
     "If Awing ends in ŋ (standalone), change final ng→gg (kong→kogg)",
     rule_final_eng_gg),
    ("glottal_to_k",
     "Map apostrophe (') to k instead of silent-delete (tsoe→tsoke)",
     rule_glottal_to_k),
    ("glottal_to_g",
     "Map apostrophe (') to g instead of silent-delete (poa→poga)",
     rule_glottal_to_g),
    ("drop_initial_schwa",
     "If Awing starts with ə and word is long, drop leading e (emo→mo)",
     rule_drop_initial_schwa),
    ("double_cons_before_final_e",
     "Double the consonant before final e (lebe→lebbe, mese→messe)",
     rule_double_consonant_before_final_e),
    # Composites
    ("COMBO_gh_plus_final_h",
     "preserve_gh + final_h_any",
     rule_gh_plus_final_h),
    ("COMBO_gh_plus_schwa",
     "preserve_gh + final_schwa_h",
     rule_gh_plus_final_schwa),
    ("COMBO_schwa_plus_open_o",
     "final_schwa_h + final_open_o_eh",
     rule_schwa_plus_open_o),
    ("COMBO_gh_schwa_open_o",
     "preserve_gh + final_schwa_h + final_open_o_eh",
     rule_schwa_plus_open_o_plus_gh),
]


# --------------------------------------------------------------------
# Data loading
# --------------------------------------------------------------------
def load_verdicts() -> dict:
    if not VERDICTS_PATH.exists():
        print(f"ERROR: verdicts file not found at {VERDICTS_PATH}")
        print("Run the Phase 1 audit tool first:")
        print("  python scripts/pattern_mine.py audit")
        print("  python scripts/pattern_mine.py html")
        print("  [open HTML in browser, rate all 197 entries, download JSON]")
        sys.exit(1)
    with open(VERDICTS_PATH, encoding="utf-8") as f:
        return json.load(f)


def load_manifest() -> dict:
    if not MANIFEST_PATH.exists():
        print(f"ERROR: manifest file not found at {MANIFEST_PATH}")
        print("Run: python scripts/pattern_mine.py audit")
        sys.exit(1)
    with open(MANIFEST_PATH, encoding="utf-8") as f:
        return json.load(f)


def build_corpus():
    """Return list of dicts: {key, awing, english, buckets, default, verdict, candidate}."""
    verdicts_blob = load_verdicts()
    manifest = load_manifest()
    verdicts = verdicts_blob.get("verdicts", {})
    corpus = []
    for sample in manifest["samples"]:
        k = sample["key"]
        v = verdicts.get(k, {})
        corpus.append({
            "key": k,
            "awing": sample["awing"],
            "english": sample["english"],
            "buckets": sample.get("buckets", []),
            "default": sample["default_speakable"],
            "verdict": v.get("verdict"),  # may be None
            "candidate": v.get("candidate", "").strip(),
        })
    return corpus


# --------------------------------------------------------------------
# Validation harness
# --------------------------------------------------------------------
def validate_rule(rule_fn: Callable[[str, str], str], corpus: list) -> dict:
    """Apply rule_fn to every corpus entry and classify the outcome."""
    helps, partials, hurts_fix, hurts_good, neutral = [], [], [], [], []
    unchanged = 0

    for entry in corpus:
        awing = entry["awing"]
        default = entry["default"]
        verdict = entry["verdict"]
        candidate = entry["candidate"]

        try:
            new_out = rule_fn(awing, default)
        except Exception as e:
            new_out = default  # treat as no-op on error

        entry_row = {
            "key": entry["key"],
            "awing": awing,
            "english": entry["english"],
            "default": default,
            "new": new_out,
            "candidate": candidate,
            "verdict": verdict,
            "buckets": entry["buckets"],
        }

        if new_out == default:
            unchanged += 1
            continue

        if verdict == "fix" and candidate:
            if new_out.lower() == candidate.lower():
                helps.append(entry_row)
            else:
                d_default = levenshtein(default.lower(), candidate.lower())
                d_new = levenshtein(new_out.lower(), candidate.lower())
                entry_row["d_default"] = d_default
                entry_row["d_new"] = d_new
                if d_new < d_default:
                    partials.append(entry_row)
                elif d_new > d_default:
                    hurts_fix.append(entry_row)
                else:
                    neutral.append(entry_row)  # same distance, different spelling
        elif verdict == "good":
            hurts_good.append(entry_row)
        else:
            neutral.append(entry_row)  # cant or unrated

    score = len(helps) * 3 + len(partials) * 1 - len(hurts_fix) * 2 - len(hurts_good) * 5

    return {
        "helps": helps,
        "partials": partials,
        "hurts_fix": hurts_fix,
        "hurts_good": hurts_good,
        "neutral": neutral,
        "unchanged": unchanged,
        "score": score,
    }


# --------------------------------------------------------------------
# Reporting
# --------------------------------------------------------------------
def cmd_propose(_args):
    corpus = build_corpus()
    print(f"Loaded {len(corpus)} samples")
    verdict_counts = {}
    for e in corpus:
        v = e["verdict"] or "unrated"
        verdict_counts[v] = verdict_counts.get(v, 0) + 1
    print("Verdict counts:", verdict_counts)
    print()

    results = []
    for name, desc, fn in RULE_LIBRARY:
        r = validate_rule(fn, corpus)
        results.append({"name": name, "desc": desc, "result": r})
        print(
            f"{name:42s}  "
            f"score={r['score']:+4d}  "
            f"HELP={len(r['helps']):2d}  "
            f"PART={len(r['partials']):2d}  "
            f"HURT_FIX={len(r['hurts_fix']):2d}  "
            f"HURT_GOOD={len(r['hurts_good']):2d}  "
            f"unch={r['unchanged']:3d}"
        )

    results.sort(key=lambda x: x["result"]["score"], reverse=True)
    write_markdown(results, corpus)
    write_json(results, corpus)
    print()
    print(f"Wrote {REPORT_MD_PATH.relative_to(PROJECT_ROOT)}")
    print(f"Wrote {REPORT_JSON_PATH.relative_to(PROJECT_ROOT)}")
    print()
    print("Next step: open the Markdown report to pick rules to adopt,")
    print("then I'll build the Phase 3 HTML A/B player for listening tests.")


def write_markdown(results, corpus):
    lines = []
    lines.append("# Rule-Mining Report — Phase 2")
    lines.append("")
    lines.append(f"- Corpus: {len(corpus)} samples")
    vc = {}
    for e in corpus:
        v = e["verdict"] or "unrated"
        vc[v] = vc.get(v, 0) + 1
    lines.append(f"- Verdicts: {vc}")
    lines.append("")
    lines.append("Scoring: `HELP × 3 + PARTIAL × 1 − HURT_FIX × 2 − HURT_GOOD × 5`")
    lines.append("Higher score = adopt; negative score = don't adopt.")
    lines.append("")
    lines.append("## Ranked rules")
    lines.append("")
    lines.append("| Rank | Score | Rule | HELP | PART | HURT_FIX | HURT_GOOD | Unch | Description |")
    lines.append("|------|------:|------|-----:|-----:|---------:|----------:|-----:|-------------|")
    for i, r in enumerate(results, 1):
        res = r["result"]
        lines.append(
            f"| {i} | {res['score']:+d} | `{r['name']}` | "
            f"{len(res['helps'])} | {len(res['partials'])} | "
            f"{len(res['hurts_fix'])} | {len(res['hurts_good'])} | "
            f"{res['unchanged']} | {r['desc']} |"
        )
    lines.append("")

    for r in results:
        lines.append(f"## `{r['name']}`  (score = {r['result']['score']:+d})")
        lines.append("")
        lines.append(r["desc"])
        lines.append("")

        def dump_section(title, rows, show_candidate=True):
            if not rows:
                return
            lines.append(f"### {title} ({len(rows)})")
            lines.append("")
            lines.append("| key | awing | english | default | new | candidate |")
            lines.append("|-----|-------|---------|---------|-----|-----------|")
            for row in rows:
                cand = row.get("candidate", "") if show_candidate else ""
                lines.append(
                    f"| `{row['key']}` | {row['awing']} | {row['english']} | "
                    f"`{row['default']}` | `{row['new']}` | `{cand}` |"
                )
            lines.append("")

        dump_section("✅ HELP (exact match)", r["result"]["helps"])
        dump_section("🟡 PARTIAL (closer, not exact)", r["result"]["partials"])
        dump_section("❌ HURT_FIX (moved away)", r["result"]["hurts_fix"])
        dump_section("🛑 HURT_GOOD (broke a good one)", r["result"]["hurts_good"])

    REPORT_MD_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_MD_PATH.write_text("\n".join(lines), encoding="utf-8")


def write_json(results, corpus):
    payload = {
        "version": 1,
        "corpus_size": len(corpus),
        "rules": [
            {
                "name": r["name"],
                "description": r["desc"],
                "score": r["result"]["score"],
                "helps": r["result"]["helps"],
                "partials": r["result"]["partials"],
                "hurts_fix": r["result"]["hurts_fix"],
                "hurts_good": r["result"]["hurts_good"],
                "unchanged": r["result"]["unchanged"],
            }
            for r in results
        ],
    }
    REPORT_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_JSON_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


# --------------------------------------------------------------------
# List / status
# --------------------------------------------------------------------
def cmd_list(_args):
    corpus = build_corpus()
    vc, bc_fix = {}, {}
    for e in corpus:
        v = e["verdict"] or "unrated"
        vc[v] = vc.get(v, 0) + 1
        if v == "fix":
            for b in e["buckets"]:
                bc_fix[b] = bc_fix.get(b, 0) + 1

    print(f"Total samples: {len(corpus)}")
    print(f"Verdicts: {vc}")
    print()
    print("Fix verdicts by linguistic bucket (sorted):")
    for b, n in sorted(bc_fix.items(), key=lambda x: -x[1]):
        bucket_total = sum(1 for e in corpus if b in e["buckets"])
        pct = 100.0 * n / bucket_total if bucket_total else 0
        print(f"  {b:<24} {n:>3}/{bucket_total:<3}  ({pct:.0f}% flagged)")


def cmd_status(_args):
    print("Pattern-mining Phase 2 status")
    print(f"  verdicts.json:      {'OK' if VERDICTS_PATH.exists() else 'MISSING'}  ({VERDICTS_PATH})")
    print(f"  audit_manifest.json: {'OK' if MANIFEST_PATH.exists() else 'MISSING'}  ({MANIFEST_PATH})")
    print(f"  rules_report.md:    {'EXISTS' if REPORT_MD_PATH.exists() else 'not yet'}  ({REPORT_MD_PATH})")
    print(f"  rules_report.json:  {'EXISTS' if REPORT_JSON_PATH.exists() else 'not yet'}  ({REPORT_JSON_PATH})")
    if VERDICTS_PATH.exists() and MANIFEST_PATH.exists():
        corpus = build_corpus()
        vc = {}
        for e in corpus:
            v = e["verdict"] or "unrated"
            vc[v] = vc.get(v, 0) + 1
        print(f"  corpus: {len(corpus)} samples, verdicts: {vc}")


# --------------------------------------------------------------------
# Entry
# --------------------------------------------------------------------
def main():
    import argparse
    p = argparse.ArgumentParser(description="Phase 2 rule miner for awing_to_speakable()")
    sub = p.add_subparsers(dest="command", required=True)
    sub.add_parser("propose", help="Run all seed rules, emit ranked report")
    sub.add_parser("list", help="Show verdict summary by linguistic bucket")
    sub.add_parser("status", help="Check input/output files")
    args = p.parse_args()
    {"propose": cmd_propose, "list": cmd_list, "status": cmd_status}[args.command](args)


if __name__ == "__main__":
    main()
