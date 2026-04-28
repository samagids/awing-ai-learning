#!/usr/bin/env python3
"""Apply auto-extracted content from models/auto_extract/extracted_content.json
into the app's screen files.

Reads:
  models/auto_extract/extracted_content.json (built by auto_extract_app_content.py)
  lib/data/awing_vocabulary.dart             (for finding blank words + glosses)

Writes (in --apply mode) to:
  lib/data/awing_vocabulary.dart                    — appends AwingPhrase entries
  lib/screens/medium/sentences_screen.dart          — appends _SentenceTemplate
  lib/screens/stories_screen.dart                   — appends AwingStory
  lib/screens/expert/conversation_screen.dart       — appends to _conversations
  lib/screens/expert/expert_quiz_screen.dart        — appends _QuizParagraph

Strategy:
  We APPEND new entries to existing data lists. The cleanup_fabricated_
  content.py step has already commented out the broken originals, so
  appending grows the live data without touching commented (broken)
  entries.

  For each section we find the existing list literal by looking for a
  unique "opening" marker, then insert new entries just before its
  closing `];`. Insertion points are computed by matching brace depth.

Usage:
  python3 scripts/apply_extracted_content.py             # preview
  python3 scripts/apply_extracted_content.py --apply     # write changes
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
EXTRACTED = REPO_ROOT / "models" / "auto_extract" / "extracted_content.json"
VOCAB_DART = REPO_ROOT / "lib" / "data" / "awing_vocabulary.dart"
SENTENCES_FILE = REPO_ROOT / "lib" / "screens" / "medium" / "sentences_screen.dart"
STORIES_FILE = REPO_ROOT / "lib" / "screens" / "stories_screen.dart"
CONVO_FILE = REPO_ROOT / "lib" / "screens" / "expert" / "conversation_screen.dart"
QUIZ_FILE = REPO_ROOT / "lib" / "screens" / "expert" / "expert_quiz_screen.dart"

_TONE_DIACRITICS = {"́", "̀", "̂", "̌", "̃", "̄"}


# ============================================================
# Utilities
# ============================================================

def _normalise(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if c not in _TONE_DIACRITICS)
    return unicodedata.normalize("NFC", s).lower().strip()


def _tokenise(text: str) -> list[str]:
    cleaned = re.sub(r"[.,!?;:\"\(\)\[\]…—–]", " ", text)
    return [w for w in cleaned.split() if w.strip()]


def _dart_str(s: str) -> str:
    """Single-quoted Dart string literal. Escapes:
       - backslash (so subsequent escapes work)
       - ASCII single-quote (would terminate the literal)
       - newline / carriage return / tab (Dart single-quoted strings
         cannot span lines — WEB Bible verses sometimes have embedded
         newlines in poetry / lists, which broke the previous version)
    Curly quotes (U+2018/U+2019/U+201C/U+201D) pass through unchanged
    because they're valid characters inside a Dart string literal.
    """
    s = s.replace("\\", "\\\\")
    s = s.replace("'", "\\'")
    s = s.replace("\n", "\\n")
    s = s.replace("\r", "\\r")
    s = s.replace("\t", "\\t")
    return "'" + s + "'"


def parse_vocab_glosses(path: Path) -> dict[str, str]:
    """awing_norm -> first English gloss. Used to derive blank-word
    hints + story vocabulary lists."""
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    pat = re.compile(
        r"AwingWord\(\s*awing:\s*(['\"])((?:\\.|(?!\1).)*)\1[^)]*?"
        r"english:\s*(['\"])((?:\\.|(?!\3).)*)\3",
        re.DOTALL,
    )
    out: dict[str, str] = {}
    for m in pat.finditer(text):
        awing = m.group(2).replace("\\'", "'").replace('\\"', '"')
        english = m.group(4).replace("\\'", "'").replace('\\"', '"')
        norm = _normalise(awing)
        # First English content word, no parens / commas
        clean = re.split(r"[,;()]", english)[0].strip()
        if not clean or len(clean) > 24:
            continue
        if not re.match(r"^[a-zA-Z][a-zA-Z\s'-]*$", clean):
            continue
        if norm and norm not in out:
            out[norm] = clean
    return out


def find_list_close(text: str, open_marker: str) -> int | None:
    """Find the position of the `]` that closes the list literal whose
    opening line contains `open_marker`. Matches brace depth.

    Returns 0-based char index of the closing `]`, or None.
    """
    start = text.find(open_marker)
    if start < 0:
        return None
    # Find first `[` after the marker
    bracket_open = text.find("[", start)
    if bracket_open < 0:
        return None
    depth = 0
    for i in range(bracket_open, len(text)):
        c = text[i]
        if c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                return i
    return None


def insert_before(text: str, idx: int, block: str) -> str:
    """Insert block at index idx (which should be the closing bracket)."""
    return text[:idx] + block + text[idx:]


# ============================================================
# Block formatters
# ============================================================

def fmt_phrases(phrases: list[dict]) -> str:
    out = ["", "  // Auto-extracted from Bible NT (non-biblical-feeling)"]
    for p in phrases:
        out.append(f"  // {p['ref']}")
        out.append(f"  AwingPhrase(awing: {_dart_str(p['awing'])}, "
                   f"english: {_dart_str(p['english'])}),")
    return "\n".join(out)


def fmt_sentences(sentences: list[dict], glosses: dict[str, str]) -> str:
    """Emit AwingSentence(...) entries matching sentences_screen.dart's
    actual class shape: { awing, english, words: List<AwingWord> }.

    `words` is a word-by-word breakdown — each AwingWord('w', 'gloss').
    For tokens we can look up in the vocabulary, the gloss is the
    English vocab entry. For unknown tokens we fall back to '—' so the
    kid sees the word but no spurious translation.
    """
    out = ["", "  // Auto-extracted from Bible NT (non-biblical-feeling)"]
    for s in sentences:
        out.append(f"  // {s['ref']}")
        out.append(f"  AwingSentence(")
        out.append(f"    awing: {_dart_str(s['awing'])},")
        out.append(f"    english: {_dart_str(s['english'])},")
        out.append(f"    words: [")
        for tok in _tokenise(s["awing"]):
            norm = _normalise(tok)
            gloss = glosses.get(norm, "—")
            out.append(f"      AwingWord({_dart_str(tok)}, {_dart_str(gloss)}),")
        out.append(f"    ],")
        out.append(f"  ),")
    return "\n".join(out)


def fmt_stories(stories: list[dict], glosses: dict[str, str]) -> str:
    """Emit AwingStory(...) entries matching stories_screen.dart's actual
    class shape: { titleEnglish, titleAwing, illustration, sentences,
    vocabulary, questions }. We synthesise titleAwing from the first
    sentence's first 3 tokens, set illustration to a generic book emoji,
    and emit empty `questions: []` (the screen tolerates this).
    """
    out = ["", "  // Auto-extracted from Bible NT (non-biblical-feeling)"]
    for st in stories:
        # Build vocab list
        vocab_pairs: list[tuple[str, str]] = []
        seen = set()
        for s in st["sentences"]:
            for tok in _tokenise(s["awing"]):
                norm = _normalise(tok)
                if norm in glosses and norm not in seen:
                    seen.add(norm)
                    vocab_pairs.append((tok, glosses[norm]))
                    if len(vocab_pairs) >= 6:
                        break
            if len(vocab_pairs) >= 6:
                break

        # Synthesise titleAwing from first sentence's first 3 tokens.
        first_aw = st["sentences"][0]["awing"] if st["sentences"] else ""
        title_awing = " ".join(_tokenise(first_aw)[:3]) or "Story"

        out.append(f"  // {st['ref']} — {st['title']}")
        out.append(f"  AwingStory(")
        out.append(f"    titleEnglish: {_dart_str(st['title'])},")
        out.append(f"    titleAwing: {_dart_str(title_awing)},")
        out.append(f"    illustration: {_dart_str('📖')},")
        out.append(f"    sentences: [")
        for s in st["sentences"]:
            out.append(f"      StorySentence(")
            out.append(f"        awing: {_dart_str(s['awing'])},")
            out.append(f"        english: {_dart_str(s['english'])},")
            out.append(f"      ),")
        out.append(f"    ],")
        out.append(f"    vocabulary: [")
        for tok, gloss in vocab_pairs:
            out.append(f"      StoryVocabulary(awing: {_dart_str(tok)}, "
                       f"english: {_dart_str(gloss)}),")
        out.append(f"    ],")
        out.append(f"    questions: [],")
        out.append(f"  ),")
    return "\n".join(out)


def fmt_conversations(convos: list[dict]) -> str:
    """Emit Map entries for the _conversations list. We DELIBERATELY
    omit the inner-list type annotation (was `<Map<String, String>>[...]`)
    because typed-list-literals aren't implicit-const, and that broke
    when the outer list got inferred as const. Without the type
    annotation, Dart infers the type AND propagates const correctly
    through the literal."""
    out = ["", "  // Auto-extracted from Bible NT (non-biblical-feeling)"]
    for c in convos:
        out.append(f"  // {c['ref']} — {c['title']}")
        out.append(f"  {{")
        out.append(f"    'title': {_dart_str(c['title'])},")
        out.append(f"    'lines': [")
        for ln in c["lines"]:
            out.append(f"      {{")
            out.append(f"        'speaker': {_dart_str(ln['speaker'])},")
            out.append(f"        'awing': {_dart_str(ln['awing'])},")
            out.append(f"        'english': {_dart_str(ln['english'])},")
            out.append(f"      }},")
        out.append(f"    ],")
        out.append(f"  }},")
    return "\n".join(out)


def fmt_quiz_paragraphs(paras: list[dict], glosses: dict[str, str]) -> str:
    """Emit _QuizParagraph(...) entries matching expert_quiz_screen.dart's
    actual class shape:
        _QuizParagraph(
          title: '...',
          context: '...',
          awingText: '... {0} ... {1} ... {2} ...',
          englishText: '...',
          blanks: [
            _ParagraphBlank(correctWord: 'X', choices: ['X', 'Y', 'Z', 'W']),
            ...
          ],
        )

    Distractors for each blank are picked from the vocabulary at random
    (deterministic via Python's hash for reproducibility): 3 vocab
    words that aren't the correct answer.
    """
    import random
    rng = random.Random(0)  # deterministic across runs
    vocab_words = sorted(glosses.keys())  # all known Awing words (normalised)

    out = ["", "  // Auto-extracted from Bible NT (non-biblical-feeling)"]
    for idx, p in enumerate(paras):
        awing_full = " ".join(v["awing"] for v in p["verses"])
        english_full = " ".join(v["english"] for v in p["verses"])
        marked = awing_full
        # Replace each blank's first occurrence with {N}
        for i, blank in enumerate(p["blanks"]):
            pat = re.compile(r"\b" + re.escape(blank) + r"\b", re.UNICODE)
            marked, _ = pat.subn("{" + str(i) + "}", marked, count=1)

        # Title: use ref as a fallback. Context: short English summary
        # (truncated english_full).
        title = f"Practice {idx + 1}"
        ctx = english_full[:80] + ("…" if len(english_full) > 80 else "")

        out.append(f"  // {p['ref']}")
        out.append(f"  _QuizParagraph(")
        out.append(f"    title: {_dart_str(title)},")
        out.append(f"    context: {_dart_str(ctx)},")
        out.append(f"    awingText: {_dart_str(marked)},")
        out.append(f"    englishText: {_dart_str(english_full)},")
        out.append(f"    blanks: [")
        for blank in p["blanks"]:
            blank_norm = _normalise(blank)
            # Pick 3 distractors from vocab, none equal to the correct answer.
            pool = [w for w in vocab_words if w != blank_norm and len(w) >= 2]
            distractors_norm = rng.sample(pool, min(3, len(pool)))
            # Use the surface form of the correct word, normalised forms
            # for distractors (kid sees the dictionary form).
            choices = [blank] + distractors_norm
            rng.shuffle(choices)
            choices_dart = ", ".join(_dart_str(c) for c in choices)
            out.append(f"      _ParagraphBlank(correctWord: {_dart_str(blank)}, "
                       f"choices: [{choices_dart}]),")
        out.append(f"    ],")
        out.append(f"  ),")
    return "\n".join(out)


# ============================================================
# Per-file appliers
# ============================================================

# Each tuple: (label, file, list-open-marker substring).
# Markers are taken from the actual variable declarations in each file.
TARGETS = [
    ("phrases",       VOCAB_DART,    "List<AwingPhrase>"),
    ("sentences",     SENTENCES_FILE,"List<AwingSentence> awingSentences"),
    ("stories",       STORIES_FILE,  "List<AwingStory>"),
    ("conversations", CONVO_FILE,    "_conversations ="),
    ("quiz",          QUIZ_FILE,     "List<_QuizParagraph> _allParagraphs"),
]


def apply_one(label: str, path: Path, marker: str, block: str,
              dry_run: bool) -> bool:
    """Find the list-close `]` after marker; insert block before it."""
    if not path.exists():
        print(f"  [{label}] SKIP: {path.relative_to(REPO_ROOT)} missing")
        return False
    text = path.read_text(encoding="utf-8")
    close_idx = find_list_close(text, marker)
    if close_idx is None:
        print(f"  [{label}] SKIP: marker {marker!r} not found in {path.name}")
        return False
    new_text = insert_before(text, close_idx, block + "\n")
    if dry_run:
        added_lines = block.count("\n") + 1
        print(f"  [{label}] would insert {added_lines} lines into {path.name}")
        return True
    path.write_text(new_text, encoding="utf-8")
    print(f"  [{label}] inserted into {path.relative_to(REPO_ROOT)}")
    return True


REVERT_MARKER_BEGIN = "// Auto-extracted from Bible NT (non-biblical-feeling)"


def revert_one(path: Path, dry_run: bool) -> int:
    """Remove every block we previously inserted (identified by the
    REVERT_MARKER_BEGIN comment line). Each insertion runs from that
    marker line down to (but not including) the next non-blank line
    that's at column 0 starting with `]` or `}` or `final ` or `class `,
    OR to the next blank line followed by a same-indent or shallower-indent line.

    Simpler approach: walk top to bottom; whenever we see the marker
    line, delete forward until we hit the closing `];` of the enclosing
    list literal — but that would delete the original list close too.
    So we take a smarter route: delete from the marker through the
    LAST line of the block we inserted, which always ends with `),`
    or `},`. We track brace depth from the marker.
    """
    if not path.exists():
        return 0
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")

    new_lines: list[str] = []
    i = 0
    deleted_blocks = 0
    while i < len(lines):
        if REVERT_MARKER_BEGIN in lines[i]:
            # Skip the marker line.
            i += 1
            # Walk forward eating lines until we leave the block. The
            # block consists of comments + one or more top-level
            # entries (each starts with two-space indent and ends in
            # `),` at the same indent depth). We stop when we see a
            # line that doesn't look like part of the block — typically
            # a line at depth ≤ 0 (just `]` or `];`).
            depth = 0
            while i < len(lines):
                line = lines[i]
                # Stop conditions: line that closes the enclosing list
                # at column 0 or 1 (e.g. `];` or `}`).
                stripped = line.lstrip()
                indent = len(line) - len(stripped)
                if indent <= 1 and (stripped.startswith("];")
                                     or stripped.startswith("}")):
                    break  # leave this line alone — it closes the list
                # Also stop if we hit ANOTHER auto-extracted marker
                # (defensive: shouldn't happen but avoids cascading).
                if REVERT_MARKER_BEGIN in line and depth == 0:
                    break
                for c in line:
                    if c in "({[":
                        depth += 1
                    elif c in ")}]":
                        depth -= 1
                i += 1
            deleted_blocks += 1
            continue
        new_lines.append(lines[i])
        i += 1

    if deleted_blocks == 0:
        return 0
    if not dry_run:
        path.write_text("\n".join(new_lines), encoding="utf-8")
    return deleted_blocks


def cmd_revert(only_set: set[str] | None, dry_run: bool) -> None:
    print(f"Reverting auto-extracted blocks{' (DRY RUN)' if dry_run else ''}:\n")
    for label, path, _ in TARGETS:
        if only_set is not None and label not in only_set:
            continue
        n = revert_one(path, dry_run=dry_run)
        action = "would remove" if dry_run else "removed"
        print(f"  [{label}] {action} {n} block(s) from {path.name}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--apply", action="store_true",
                    help="Write changes to source files (default: preview).")
    ap.add_argument("--revert", action="store_true",
                    help="Remove all previously-inserted auto-extracted blocks "
                         "(detected via the marker comment). Use this if a "
                         "previous --apply run produced broken output and you "
                         "want to start clean. Pair with --apply to actually "
                         "write the revert (default: revert is dry-run too).")
    ap.add_argument("--only", default=None,
                    help="Comma-separated list of sections to apply "
                         "(any of: phrases,sentences,stories,conversations,quiz). "
                         "Default: all. Useful when re-running after a partial apply "
                         "to avoid double-inserting sections that already worked.")
    args = ap.parse_args()

    if not EXTRACTED.exists():
        print(f"ERROR: {EXTRACTED} missing.")
        print("       Run scripts/auto_extract_app_content.py first.")
        return 1

    extracted = json.loads(EXTRACTED.read_text(encoding="utf-8"))
    glosses = parse_vocab_glosses(VOCAB_DART)
    print(f"Loaded extracted content + {len(glosses)} vocabulary glosses")
    print()

    blocks = {
        "phrases":       fmt_phrases(extracted.get("phrases", [])),
        "sentences":     fmt_sentences(extracted.get("sentences", []), glosses),
        "stories":       fmt_stories(extracted.get("stories", []), glosses),
        "conversations": fmt_conversations(extracted.get("conversations", [])),
        "quiz":          fmt_quiz_paragraphs(extracted.get("quiz", []), glosses),
    }

    only_set = None
    if args.only:
        only_set = {s.strip() for s in args.only.split(",")}

    if args.revert:
        cmd_revert(only_set, dry_run=not args.apply)
        return 0

    print(f"Applying to source files{' (DRY RUN)' if not args.apply else ''}:\n")
    for label, path, marker in TARGETS:
        if only_set is not None and label not in only_set:
            print(f"  [{label}] skipped (--only filter)")
            continue
        block = blocks[label]
        if not block.strip():
            print(f"  [{label}] empty block — skipping")
            continue
        apply_one(label, path, marker, block, dry_run=not args.apply)

    print()
    if args.apply:
        print("Done. Sanity check next:")
        print("  flutter pub get && flutter analyze")
    else:
        print("Preview only. Re-run with --apply to write changes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
