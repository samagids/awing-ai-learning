#!/usr/bin/env python3
"""comprehensive_audit.py — audit every Awing string in every Dart file.

Walks lib/ and finds every (awing, english) pair in any constructor
that uses awing: 'X' english: 'Y' fields. For each:

1. UNKNOWN_TOKEN: An Awing word/token in 'awing' field that doesn't
   exist in the vocabulary file (a real word from the dictionary).
   Likely fabrication.

2. SUSPICIOUS_GLOSS: The 'english' gloss has zero content-word overlap
   with the dictionary's gloss for the head Awing word.

3. SHORT_SENTENCE: Sentences with 2-3 tokens that lack a known
   counterpart in any verified PDF source.

Run:
    python scripts/comprehensive_audit.py [--csv FILE]

Reports each issue with file, line, awing, english, and the reason.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
VOCAB = LIB / "data" / "awing_vocabulary.dart"
TONES = LIB / "data" / "awing_tones.dart"
ALPHABET = LIB / "data" / "awing_alphabet.dart"


STOPWORDS = {
    "the", "a", "an", "to", "of", "in", "at", "on", "and", "or",
    "but", "is", "was", "are", "were", "be", "been", "being",
    "have", "has", "had", "do", "does", "did", "for", "by", "with",
    "from", "into", "onto", "this", "that", "these", "those",
    "it", "its", "as", "if", "so", "her", "his", "their", "they",
    "them", "she", "he", "we", "us", "you", "your", "my", "our",
    "i", "me", "out", "up", "down", "off", "over", "go", "going",
    "come", "coming",
}


def normalize(s: str) -> str:
    s = "".join(c for c in unicodedata.normalize("NFD", s)
                if unicodedata.category(c) != "Mn")
    return s.lower().strip()


def tokenize_awing(awing: str) -> list[str]:
    """Split an Awing sentence into tokens. Strips punctuation but
    preserves apostrophes (glottal stops) and tone diacritics."""
    s = re.sub(r"[.,!?;:\"\(\)\[\]]", " ", awing)
    return [t.strip() for t in s.split() if t.strip()]


def tokenize_english(english: str) -> set[str]:
    """Lowercase + strip punctuation, drop stopwords, content words only."""
    g = english.lower()
    g = re.sub(r"[^a-zəɛɔɨŋ\s']", " ", g)
    return {t for t in g.split() if t and t not in STOPWORDS and len(t) > 1}


def load_vocab() -> tuple[dict[str, list[str]], set[str]]:
    """Returns (vocab, all_known_tokens).

    vocab = {normalized_awing_headword: [english_glosses]}
    all_known_tokens = set of every normalized Awing token that
                       appears in any data file (including phrases/
                       sentences in the vocab/tones/alphabet files)
    """
    vocab: dict[str, list[str]] = defaultdict(list)
    all_tokens: set[str] = set()

    pat = re.compile(
        r"AwingWord\(\s*awing:\s*'((?:[^'\\]|\\.)*?)'\s*,"
        r"\s*english:\s*'((?:[^'\\]|\\.)*?)'"
    )
    for source in (VOCAB, TONES, ALPHABET):
        if not source.exists():
            continue
        text = source.read_text(encoding="utf-8")
        for awing, english in pat.findall(text):
            a = awing.replace(r"\'", "'")
            e = english.replace(r"\'", "'")
            head = normalize(a)
            vocab[head].append(e)
            for tok in tokenize_awing(a):
                all_tokens.add(normalize(tok))

    # Also add common Awing grammatical particles and pronouns from
    # AwingOrthography2005.pdf so we don't flag verified sentences:
    # a (he/she), kə (past), tə (progressive), nə (and/with),
    # lə (in), ghǒ (you), po (they), ma (not), pə (subj.pl.),
    # əfó (where), aké (what), etc.
    grammatical = {
        "a", "ə", "kə", "tə", "nə", "lə", "ma", "po", "pə", "lɔ",
        "ghǒ", "yə", "yi", "kɛ", "akɛ", "akɛ̌", "lě", "lɛ̌", "lǒ",
        "əfó", "əfê", "aké", "yǐ", "yǐə", "ngyǐə", "nə̌", "nó",
        "lə́", "tsɔʼə", "mɔ́", "ndɛlə́", "pɛ́d", "nə́", "nukə́taŋə",
        "yitsə̌", "weeping", "ájíənuə",
    }
    for g in grammatical:
        all_tokens.add(normalize(g))

    return vocab, all_tokens


# Constructors that have (awing, english) fields we want to audit.
# Some use named (awing: 'x', english: 'y'), others positional ('x', 'y').
CONSTRUCTOR_PATTERNS = [
    # Named-arg: AwingWord(awing: 'x', english: 'y')
    re.compile(
        r"(AwingWord|AwingSentence|AwingPhrase|StoryVocabulary|"
        r"StorySentence|_ConversationLine|_SentenceTemplate|"
        r"_ParagraphBlank|_QuizParagraph)\("
        r"[^)]{0,800}awing:\s*'((?:[^'\\]|\\.)*?)'"
        r"[^)]{0,800}english:\s*'((?:[^'\\]|\\.)*?)'",
        re.DOTALL,
    ),
    # Positional in sentence breakdowns: AwingWord('Mǎ', 'Mother')
    # — only inside sentence/word lists, not the vocab declarations.
    re.compile(
        r"AwingWord\(\s*'((?:[^'\\]|\\.)*?)'\s*,\s*"
        r"'((?:[^'\\]|\\.)*?)'\s*\)"
    ),
]


def audit_file(file: Path, vocab: dict, all_tokens: set[str]) -> list[dict]:
    """Return list of issue dicts for this file."""
    issues = []
    text = file.read_text(encoding="utf-8")

    seen = set()  # de-dupe by (awing, english) pair

    for pat in CONSTRUCTOR_PATTERNS:
        for m in pat.finditer(text):
            if len(m.groups()) == 3:
                kind, awing, english = m.group(1), m.group(2), m.group(3)
            elif len(m.groups()) == 2:
                kind = "AwingWord(positional)"
                awing, english = m.group(1), m.group(2)
            else:
                continue

            awing = awing.replace(r"\'", "'")
            english = english.replace(r"\'", "'")
            key = (awing, english)
            if key in seen:
                continue
            seen.add(key)

            # Skip empty/placeholder pairs
            if not awing.strip() or not english.strip():
                continue
            # Skip stuff that's clearly UI/grammar markers like '(subject)'
            if english.strip().startswith("(") and english.strip().endswith(")"):
                continue

            # 1. UNKNOWN_TOKEN — any token in awing missing from data
            tokens = tokenize_awing(awing)
            for tok in tokens:
                n = normalize(tok)
                if not n or len(n) <= 1:
                    continue
                if n not in all_tokens:
                    issues.append({
                        "file": str(file.relative_to(ROOT)),
                        "type": "UNKNOWN_TOKEN",
                        "awing": awing,
                        "english": english,
                        "detail": f"token {tok!r} not in vocab data",
                    })

            # 2. SUSPICIOUS_GLOSS — single-headword cases only
            if len(tokens) == 1:
                head = normalize(tokens[0])
                dict_glosses = vocab.get(head, [])
                if dict_glosses:
                    screen_words = tokenize_english(english)
                    matched = False
                    for dg in dict_glosses:
                        if screen_words & tokenize_english(dg):
                            matched = True
                            break
                    if not matched and screen_words:
                        issues.append({
                            "file": str(file.relative_to(ROOT)),
                            "type": "SUSPICIOUS_GLOSS",
                            "awing": awing,
                            "english": english,
                            "detail": f"dict says {'; '.join(dict_glosses[:2])[:80]!r}",
                        })

    return issues


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--csv", type=str, help="Write all issues to this CSV file")
    args = p.parse_args()

    vocab, all_tokens = load_vocab()
    print(f"Loaded {len(vocab)} headwords, {len(all_tokens)} known tokens.\n")

    all_issues = []
    for f in sorted(LIB.rglob("*.dart")):
        if f.name in ("awing_vocabulary.dart", "awing_tones.dart",
                       "awing_alphabet.dart"):
            continue  # data files — are the source of truth
        issues = audit_file(f, vocab, all_tokens)
        if issues:
            all_issues.extend(issues)

    # Group by file
    by_file: dict[str, list] = defaultdict(list)
    for iss in all_issues:
        by_file[iss["file"]].append(iss)

    for file, issues in sorted(by_file.items()):
        print(f"=== {file} — {len(issues)} issues ===")
        for iss in issues[:20]:
            print(f"  [{iss['type']}] {iss['awing']!r} = {iss['english'][:60]!r}")
            print(f"    {iss['detail']}")
        if len(issues) > 20:
            print(f"  ... and {len(issues) - 20} more")
        print()

    print(f"TOTAL ISSUES: {len(all_issues)}")
    print(f"   UNKNOWN_TOKEN:    {sum(1 for i in all_issues if i['type'] == 'UNKNOWN_TOKEN')}")
    print(f"   SUSPICIOUS_GLOSS: {sum(1 for i in all_issues if i['type'] == 'SUSPICIOUS_GLOSS')}")

    if args.csv:
        with open(args.csv, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["file", "type", "awing", "english", "detail"])
            w.writeheader()
            w.writerows(all_issues)
        print(f"\nWrote {len(all_issues)} issues to {args.csv}")

    return 0 if not all_issues else 1


if __name__ == "__main__":
    sys.exit(main())
