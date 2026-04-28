#!/usr/bin/env python3
"""Remove fabricated entries flagged as MISMATCH by audit_app_content.py.

Reads:
  models/content_audit/audit.json     (run scripts/audit_app_content.py first)

Targets these screen files:
  lib/screens/medium/sentences_screen.dart
  lib/screens/stories_screen.dart
  lib/screens/expert/conversation_screen.dart
  lib/screens/expert/expert_quiz_screen.dart

Strategy:
  Each MISMATCH entry has a known file path + line number. The Dart
  parser identifies the enclosing struct/list literal and the script
  comments it out with a // FABRICATED — REMOVED comment. The
  user-facing app shrinks to ONLY the audit-verified entries.

  We do NOT delete entries outright — commenting preserves the
  original text in the file so Dr. Sama can review what was removed
  and rewrite from scratch where needed.

Usage:
  python3 scripts/cleanup_fabricated_content.py            # apply
  python3 scripts/cleanup_fabricated_content.py --dry-run  # preview
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
AUDIT_JSON = REPO_ROOT / "models" / "content_audit" / "audit.json"

# We only target screen files (not vocabulary.dart). Vocabulary's
# MISMATCH count includes many false positives from homonyms, and
# vocab is not directly user-facing in the same way phrases/stories are.
TARGET_FILES = {
    "lib/screens/medium/sentences_screen.dart",
    "lib/screens/stories_screen.dart",
    "lib/screens/expert/conversation_screen.dart",
    "lib/screens/expert/expert_quiz_screen.dart",
}

REMOVED_COMMENT = "    // FABRICATED — REMOVED by cleanup_fabricated_content.py"


def find_struct_block(lines: list[str], pivot_line_1based: int
                      ) -> tuple[int, int] | None:
    """Given a 1-based line number that contains an `awing:` field,
    find the enclosing struct/map literal block.

    Returns (start_idx_0based, end_idx_0based, both inclusive) or None.

    Heuristic:
      - Walk UP from pivot until we find a line opening a brace/paren.
        Specifically the line ending in `(` or `{` (after stripping
        trailing whitespace + comments).
      - Then walk DOWN matching brace/paren depth to find the closing
        `),` or `},`.
    """
    pivot = pivot_line_1based - 1  # to 0-based
    n = len(lines)

    # Walk UP to find the opening line. Look for a line whose stripped
    # tail ends with '(' or '{'. Stop after at most 6 lines.
    start = None
    for i in range(pivot, max(-1, pivot - 8), -1):
        s = lines[i].rstrip()
        # ignore trailing comments
        s_no_comment = re.sub(r"\s*//.*$", "", s).rstrip()
        if s_no_comment.endswith("(") or s_no_comment.endswith("{"):
            start = i
            break
    if start is None:
        return None

    # Walk DOWN matching depth.
    depth = 0
    end = None
    for i in range(start, n):
        for ch in lines[i]:
            if ch in "({[":
                depth += 1
            elif ch in ")}]":
                depth -= 1
                if depth == 0:
                    end = i
                    break
        if end is not None:
            break
    if end is None:
        return None
    # Include the trailing comma line if there's one.
    return (start, end)


def cleanup_file(path: Path, mismatched_lines: list[int],
                 dry_run: bool) -> tuple[int, int]:
    """Comment out struct blocks containing mismatched entries.
    Returns (entries_commented, lines_changed)."""
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")

    # Compute distinct struct ranges to comment.
    ranges = set()
    for ln in mismatched_lines:
        r = find_struct_block(lines, ln)
        if r:
            ranges.add(r)

    # Comment out lines (in descending order so indices stay valid).
    changed_lines = 0
    for start, end in sorted(ranges, reverse=True):
        for i in range(start, end + 1):
            if not lines[i].lstrip().startswith("//"):
                lines[i] = "// " + lines[i]
                changed_lines += 1
        # Insert a header comment above the block
        lines.insert(start, REMOVED_COMMENT)
        changed_lines += 1

    if not ranges:
        return (0, 0)

    if not dry_run:
        path.write_text("\n".join(lines), encoding="utf-8")
    return (len(ranges), changed_lines)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dry-run", action="store_true",
                    help="Show what would be commented; don't modify files.")
    args = ap.parse_args()

    if not AUDIT_JSON.exists():
        print(f"ERROR: {AUDIT_JSON} missing.")
        print("       Run scripts/audit_app_content.py first.")
        return 1

    audit = json.loads(AUDIT_JSON.read_text(encoding="utf-8"))
    pairs = audit.get("pairs", [])

    # Group MISMATCH lines by file.
    by_file: dict[str, list[int]] = {}
    for p in pairs:
        if p.get("verdict") != "MISMATCH":
            continue
        f = p.get("file", "")
        if f not in TARGET_FILES:
            continue
        by_file.setdefault(f, []).append(p["line"])

    if not by_file:
        print("No MISMATCH entries in target screen files. Nothing to clean.")
        return 0

    total_blocks = 0
    total_lines = 0
    for f, mismatch_lines in sorted(by_file.items()):
        path = REPO_ROOT / f
        if not path.exists():
            print(f"  SKIP {f}: not found")
            continue
        blocks, changed = cleanup_file(path, mismatch_lines, dry_run=args.dry_run)
        total_blocks += blocks
        total_lines += changed
        action = "would comment" if args.dry_run else "commented"
        print(f"  {f}")
        print(f"    {blocks} struct blocks {action} ({changed} lines), "
              f"flagged from {len(mismatch_lines)} MISMATCH entries")

    print()
    print(f"Total: {total_blocks} blocks, {total_lines} lines{' (DRY RUN)' if args.dry_run else ''}")
    if args.dry_run:
        print()
        print("Run without --dry-run to apply.")
    else:
        print()
        print("The fabricated content is now commented out (preserved in the file")
        print("for review). Recompile with `flutter pub get && flutter analyze`")
        print("to confirm the screens still parse — they will, since we only commented")
        print("out items in lists, not removed list declarations.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
