#!/usr/bin/env python3
"""Fix orphan `},` and `],` lines left by cleanup_fabricated_content.py.

Problem: the cleanup script's brace-depth tracking didn't account for
already-commented braces, so when nested `{ title, lines: [{...}, {...}] }`
maps were partially commented, the OUTER `},` was left dangling without
its matching `{`.

This script walks each target file. When it sees a non-comment closing
line like `  },` or `  ],` that directly follows a stretch of `//`-
prefixed lines AND has no matching opening above (heuristic: nearest
non-comment line of equal-or-shallower indent is also a closing line
or another orphan), it comments it out too.

Conservative: only modifies isolated close-bracket-only lines that
follow comments. Won't touch valid code.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

TARGETS = [
    REPO_ROOT / "lib" / "screens" / "medium" / "sentences_screen.dart",
    REPO_ROOT / "lib" / "screens" / "stories_screen.dart",
    REPO_ROOT / "lib" / "screens" / "expert" / "conversation_screen.dart",
    REPO_ROOT / "lib" / "screens" / "expert" / "expert_quiz_screen.dart",
]

# A "close-only" line: just whitespace + 1-3 closing chars + optional comma.
# Examples: "  },", "    ],", "  ],", "},"
CLOSE_ONLY = re.compile(r"^\s*[\)\}\]]+,?\s*$")
# Comment-only line: starts with `//` after optional whitespace
COMMENT_ONLY = re.compile(r"^\s*//")


def _strip_strings(s: str) -> str:
    """Remove string literals from a Dart line so brace counting isn't
    confused by `'{'` or `'}'` inside strings. Conservative — handles
    single, double, triple quotes."""
    # Triple quotes first
    s = re.sub(r"'''.*?'''", "''", s, flags=re.DOTALL)
    s = re.sub(r'""".*?"""', '""', s, flags=re.DOTALL)
    # Single quotes (with escapes)
    s = re.sub(r"'(?:\\.|[^'\\])*'", "''", s)
    s = re.sub(r'"(?:\\.|[^"\\])*"', '""', s)
    return s


def _net_braces(line: str) -> int:
    """Net brace/bracket delta on this line (opens minus closes).
    Skips strings. Negative means more closes than opens."""
    s = _strip_strings(line)
    opens = sum(s.count(c) for c in "({[")
    closes = sum(s.count(c) for c in ")}]")
    return opens - closes


_OPEN_TO_CLOSE = {"(": ")", "{": "}", "[": "]"}
_CLOSE_TO_OPEN = {v: k for k, v in _OPEN_TO_CLOSE.items()}


def fix_file(path: Path, dry_run: bool) -> int:
    """Comment out close-bracket-only lines that don't match the most
    recently opened bracket (when commented lines are excluded).

    Walks forward, maintaining a STACK of open brackets from
    non-commented lines. When a close-only line tries to close a
    bracket type that doesn't match the top of stack, it's an orphan —
    most likely because its matching opener was commented out by
    cleanup_fabricated_content.py.

    Example detected: `},` at line 406 of conversation_screen.dart.
    Numeric depth alone wouldn't catch this — depth goes 1→0, not
    negative — but the most recent unclosed open was `[` (the outer
    `_conversations = [`), not `{`, so the `}` mismatches.
    """
    if not path.exists():
        return 0
    lines = path.read_text(encoding="utf-8").split("\n")

    is_comment = [bool(COMMENT_ONLY.match(L)) for L in lines]

    fixed = 0
    stack: list[str] = []
    for i, line in enumerate(lines):
        if is_comment[i] or not line.strip():
            continue
        s = _strip_strings(line)
        line_is_orphan = False

        # Process all bracket chars on this line in order.
        for c in s:
            if c in "({[":
                stack.append(c)
            elif c in ")}]":
                expected_open = _CLOSE_TO_OPEN[c]
                if stack and stack[-1] == expected_open:
                    stack.pop()
                else:
                    # Mismatch! This close doesn't match the top of stack.
                    if CLOSE_ONLY.match(line):
                        # The whole line is just brackets — safe to neutralise.
                        line_is_orphan = True
                    # We bail here; the rest of this line probably has
                    # cascading mismatches that we don't trust.
                    break

        if line_is_orphan:
            lines[i] = "// " + line + "  // orphan close — no matching open above"
            fixed += 1
            # We've effectively undone the line — restore the stack to
            # what it was before processing it. (We mutated stack while
            # iterating; in practice for a close-only line with one
            # close char, stack is unchanged from the failed match, so
            # this is a no-op.)

    if fixed == 0:
        return 0
    if not dry_run:
        path.write_text("\n".join(lines), encoding="utf-8")
    return fixed


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dry-run", action="store_true",
                    help="Preview, don't modify.")
    args = ap.parse_args()

    total = 0
    for path in TARGETS:
        n = fix_file(path, dry_run=args.dry_run)
        action = "would comment" if args.dry_run else "commented"
        print(f"  {path.relative_to(REPO_ROOT)}: {n} orphan close-line(s) {action}")
        total += n

    print()
    print(f"Total: {total}{' (DRY RUN)' if args.dry_run else ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
