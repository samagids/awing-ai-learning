#!/usr/bin/env python3
"""filter_inappropriate.py — remove kid-inappropriate vocabulary entries.

Strips entries from lib/data/awing_vocabulary.dart whose english gloss
matches an explicit blocklist. Categories:

  - Adult anatomy: vagina, penis, scrotum, testicle, breast, etc.
  - Bodily functions: urine, excrement, vomit, mucus, etc.
  - Sexual content: sex, intercourse, orgasm, prostitute, adultery, etc.
  - Violence: kill, murder, rape, stab, slaughter, behead, etc.
  - Drugs/intoxication: drunk, intoxicated, etc.
  - Occult: witch, sorcerer, demon, devil

Run: python scripts/filter_inappropriate.py [--dry-run]

Writes the cleaned file in place. Backs up the original to
lib/data/awing_vocabulary.dart.bak_filter.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_filter"

# ============================================================
# BLOCKLIST — English-gloss substrings that disqualify an entry.
# Word-boundary matching, case-insensitive.
# ============================================================

BLOCKLIST_PATTERNS = [
    # Adult anatomy
    r"\bvagina\b", r"\bpenis\b", r"\bscrotum\b", r"\btesticle\b",
    r"\bnipple\b", r"\banus\b", r"\banal\b", r"\bbuttock\b",
    r"\bgenital\b", r"\bwomb\b", r"\buter(us|ine)\b", r"\bovar(y|ies)\b",
    r"\bsperm\b", r"\bsemen\b", r"\bclitoris\b", r"\bvulva\b",
    r"\bareola\b", r"\bbreast\b",  # (chest is OK, breast is blocked)

    # Bodily functions / fluids
    r"\burine\b", r"\burinat\w*", r"\bdefecat\w*", r"\bexcrement\b",
    r"\bfeces\b", r"\bfaeces\b", r"\bvomit\w*", r"\bsnot\b",
    r"\bmucus\b", r"\bcatarrh\b", r"\bspittle\b", r"\bsaliva\b",
    r"\bmenstrual\b", r"\bmenstruation\b", r"\bmenses\b",
    r"\babscess\b", r"\bhernia\b", r"\b(?:diarrhea|diarrhoea)\b",

    # Sexual content
    r"\bsex(ual)?\b", r"\bintercourse\b", r"\borgasm\w*",
    r"\bmasturbat\w*", r"\bcopulat\w*", r"\bfornicat\w*",
    r"\bprostitut\w*", r"\bwhore\b", r"\bharlot\b",
    r"\badulter\w*", r"\bnaked\b", r"\bnude\b", r"\bnudity\b",
    r"\blust\w*", r"\bseduce\w*", r"\bseduction\b",

    # Violence
    r"\bkill\w*", r"\bmurder\w*", r"\bslaughter\w*",
    r"\b(behead|behead\w+)\b", r"\bdecapitat\w*", r"\bmutilat\w*",
    r"\btortur\w*", r"\brape\w*", r"\b(stab|stabb\w+)\b",
    r"\bstrangle\w*", r"\bstrangulat\w*",

    # Drugs / intoxication
    r"\bdrunk\w*", r"\bintoxicat\w*", r"\bopium\b", r"\bmarijuana\b",
    r"\bcocaine\b", r"\bheroin\b",

    # Death / corpses
    r"\bcorpse\b", r"\bcadaver\b", r"\bcarcass\b",

    # Occult / supernatural-evil
    r"\b(witch|witches)\b", r"\bwitchcraft\b", r"\bsorcer\w*",
    r"\bdemon(s|ic)?\b", r"\bdevil\b", r"\bsatan\w*", r"\bdamnation\b",

    # Profanity / strong insults (stay conservative)
    r"\bbastard\b", r"\bretard\w*", r"\basshole\b", r"\bdick\b",
    r"\b(?<!\w)cock(?!erel)\b",  # block "cock" but not "cockerel"

    # Specific phrases the user has flagged previously (Session 51)
    r"\b(mad person|fool|hate)\b",  # actually these were USER-REQUESTED to keep — REMOVING from blocklist below
]

# Re-compile: actually keep "mad person", "fool", "hate" since user explicitly asked for them in Session 51.
# Remove from block:
BLOCKLIST_PATTERNS = [p for p in BLOCKLIST_PATTERNS if p not in (r"\b(mad person|fool|hate)\b",)]

# Compile combined regex
BLOCKLIST_RE = re.compile("|".join(BLOCKLIST_PATTERNS), re.IGNORECASE)

# ============================================================
# AwingWord literal regex — matches a complete entry on one line.
# We assume each AwingWord(...) is on a single line (true for current
# vocab file). Returns groups for awing, english, and the full literal.
# ============================================================

AWINGWORD_RE = re.compile(
    r"^(\s*AwingWord\(.*?english:\s*'((?:[^'\\]|\\.)*)'.*?\),)"
    r"(\s*//.*)?$",
    re.MULTILINE,
)

ENGLISH_FIELD_RE = re.compile(
    r"english:\s*'((?:[^'\\]|\\.)*)'",
)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true",
                   help="Report what would change without writing")
    p.add_argument("--show-removed", action="store_true",
                   help="Print each removed line")
    args = p.parse_args()

    if not VOCAB.exists():
        print(f"ERROR: {VOCAB} not found", file=sys.stderr)
        return 1

    text = VOCAB.read_text(encoding="utf-8")
    original_lines = text.splitlines(keepends=True)

    kept_lines = []
    removed_count = 0
    removed_examples = []

    for line in original_lines:
        # Only check lines that look like AwingWord literals.
        if "AwingWord(" not in line:
            kept_lines.append(line)
            continue

        # Extract the english gloss.
        m = ENGLISH_FIELD_RE.search(line)
        if not m:
            kept_lines.append(line)
            continue

        gloss = m.group(1)
        # Decode escape sequences for matching purposes (e.g. \' → ').
        decoded = gloss.replace(r"\'", "'").replace(r"\n", " ")

        if BLOCKLIST_RE.search(decoded):
            removed_count += 1
            if len(removed_examples) < 30:
                # Try to extract awing too for the report
                awing_m = re.search(r"awing:\s*'((?:[^'\\]|\\.)*)'", line)
                awing = awing_m.group(1) if awing_m else "?"
                removed_examples.append(f"  {awing!r} = {decoded[:70]!r}")
            continue  # drop this line

        kept_lines.append(line)

    print(f"Total lines: {len(original_lines)}")
    print(f"Removed entries: {removed_count}")
    print(f"Kept lines: {len(kept_lines)} (= {len(original_lines)} - {removed_count})")
    print()
    print("Sample of removed entries (first 30):")
    for ex in removed_examples:
        print(ex)

    # Count surviving AwingWord entries
    surviving = sum(1 for ln in kept_lines if "AwingWord(" in ln)
    print()
    print(f"Surviving AwingWord literals: {surviving}")

    if args.dry_run:
        print()
        print("--dry-run set — no file written.")
        return 0

    # Backup + write
    if not BACKUP.exists():
        shutil.copy(VOCAB, BACKUP)
        print(f"Backed up original to {BACKUP.name}")
    VOCAB.write_text("".join(kept_lines), encoding="utf-8")
    print(f"Wrote cleaned file to {VOCAB}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
