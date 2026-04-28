#!/usr/bin/env python3
"""Validate Qwen3-TTS tokenizer compatibility with Awing text.

Why this matters
----------------
Qwen3-TTS-12Hz-1.7B-Base was pretrained on 10 languages (zh, en, ja, ko,
de, fr, ru, pt, es, it). Awing is not one of them. Whether we can
fine-tune the model for Awing depends on whether its tokenizer can
represent Awing text efficiently.

Qwen models use byte-level BPE, so every UTF-8 character is technically
representable — there's no UNK. But Awing's special characters (ɛ ɔ ə ɨ
ŋ ɣ + combining tone diacritics) may explode into multi-byte/multi-token
sequences that are hard for the model to learn from a few thousand
training clips. This script measures the damage.

What it reports
---------------
1. Per-character token counts for each Awing-special character.
2. Token-per-character ratio on a sample of Awing words.
3. Token-per-character ratio on a sample of Awing Bible verses.
4. List of Awing words whose tokenization is suspicious (>3 tokens
   per character — likely too granular to learn).
5. A go/no-go verdict at the end.

If verdict is GO: proceed to data prep + fine-tune.
If verdict is CONCERNING: review specific characters; we may need to
   pre-substitute Awing-special chars with Latin near-equivalents
   (similar to Session 19's awing_to_speakable() approach).
If verdict is NO-GO: tokenizer fundamentally can't represent Awing;
   we'd need to extend the tokenizer (much more involved).

Run inside WSL with venv_qwen3 activated:
  source ~/venv_qwen3/bin/activate
  python3 scripts/ml/tts/check_tokenizer.py
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
VOCAB_DART = REPO_ROOT / "lib" / "data" / "awing_vocabulary.dart"
BIBLE_DIR = REPO_ROOT / "corpus" / "raw" / "bible" / "azocab"
OUT_DIR = REPO_ROOT / "models" / "tts_audition" / "tokenizer_check"
MODEL_ID = "Qwen/Qwen3-TTS-12Hz-1.7B-Base"

# Awing-specific characters we care most about. These are the ones the
# Latin-trained Qwen tokenizer is least likely to handle efficiently.
AWING_SPECIAL_CHARS = [
    "ɛ", "ɔ", "ə", "ɨ", "ŋ", "ɣ",      # Awing-specific phonemes
    "á", "à", "â", "ǎ",                # Tone-marked vowels (sample)
    "ɛ́", "ɛ̀", "ɛ̂", "ɛ̌",                # Tone on ɛ
    "ɔ́", "ɔ̀", "ɔ̂", "ɔ̌",                # Tone on ɔ
    "ə́", "ə̀", "ə̂", "ə̌",                # Tone on ə
    "ɨ́", "ɨ̀", "ɨ̂", "ɨ̌",                # Tone on ɨ
    "'",                                # Glottal stop
]


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Loading tokenizer for {MODEL_ID}...")
    try:
        from transformers import AutoTokenizer
    except ImportError as e:
        print(f"ERROR importing transformers: {e}")
        return 1

    try:
        tok = AutoTokenizer.from_pretrained(MODEL_ID, trust_remote_code=True)
    except Exception as e:
        print(f"ERROR loading tokenizer: {e}")
        print(f"  Make sure setup_finetune_wsl.sh has run and the model is cached.")
        return 1

    print(f"  Tokenizer class: {type(tok).__name__}")
    print(f"  Vocab size: {tok.vocab_size}")
    print(f"  Special tokens: {tok.all_special_tokens}\n")

    # Quick sanity check: round-trip ASCII English.
    en_test = "The quick brown fox jumps over the lazy dog."
    en_ids = tok(en_test, add_special_tokens=False).input_ids
    en_decode = tok.decode(en_ids)
    print(f"English round-trip: {len(en_ids)} tokens for {len(en_test)} chars "
          f"(ratio {len(en_ids)/len(en_test):.2f})")
    if en_decode.strip() != en_test:
        print(f"  WARNING: round-trip differs:")
        print(f"    in:  {en_test!r}")
        print(f"    out: {en_decode!r}")
    print()

    # --- 1. Per-Awing-character token counts ------------------------
    print("Per-character token costs (Awing-specific characters):")
    print(f"  {'char':<8} {'unicode':<22} {'tokens':<8} {'token IDs'}")
    char_table = []
    for ch in AWING_SPECIAL_CHARS:
        ids = tok(ch, add_special_tokens=False).input_ids
        names = unicodedata.name(ch[0], "?")
        if len(ch) > 1:
            names += f" + {len(ch)-1} combining"
        print(f"  {ch:<8} {names[:22]:<22} {len(ids):<8} {ids}")
        char_table.append({"char": ch, "name": names, "tokens": len(ids), "ids": ids})
    print()

    expensive_chars = [c for c in char_table if c["tokens"] >= 3]
    if expensive_chars:
        print(f"  {len(expensive_chars)} characters explode to 3+ tokens "
              f"(harder to learn). Review:")
        for c in expensive_chars:
            print(f"    {c['char']}  ({c['name']}) -> {c['tokens']} tokens")
        print()

    # --- 2. Awing words from the vocabulary file --------------------
    print("Loading Awing words from awing_vocabulary.dart...")
    awing_words = _load_awing_words(VOCAB_DART)
    print(f"  Loaded {len(awing_words)} Awing word strings.\n")

    word_ratios: list[float] = []
    if awing_words:
        worst = []  # (ratio, word, tokens, ids)
        for w in awing_words:
            if not w.strip():
                continue
            ids = tok(w, add_special_tokens=False).input_ids
            ratio = len(ids) / max(1, len(w))
            word_ratios.append(ratio)
            worst.append((ratio, w, len(ids), ids))
        worst.sort(key=lambda r: -r[0])

        avg = sum(word_ratios) / len(word_ratios)
        print(f"Awing word tokenization (n={len(word_ratios)}):")
        print(f"  Mean tokens/char: {avg:.2f}")
        print(f"  Max tokens/char:  {max(word_ratios):.2f}")
        print(f"  Min tokens/char:  {min(word_ratios):.2f}")
        print()

        # Show the 10 worst-tokenized words.
        print("Top 10 worst-tokenized words (highest token/char ratio):")
        for r, w, n, ids in worst[:10]:
            print(f"  {r:5.2f}  {w!r:<24}  {n} tokens  {ids[:12]}{'...' if len(ids) > 12 else ''}")
        print()

    # --- 3. Awing Bible verses (training data) ----------------------
    print("Loading sample of Awing Bible verses (from corpus/raw)...")
    verses = _load_bible_verses(BIBLE_DIR, max_verses=200)
    bible_mean: float | None = None
    if verses:
        print(f"  Sampled {len(verses)} verses.")
        bible_ratios: list[float] = []
        oov_chars: Counter[str] = Counter()
        all_chars: Counter[str] = Counter()
        for v in verses:
            ids = tok(v, add_special_tokens=False).input_ids
            bible_ratios.append(len(ids) / max(1, len(v)))
            for ch in v:
                all_chars[ch] += 1
                # If a single character takes >2 tokens, it's expensive.
                if len(tok(ch, add_special_tokens=False).input_ids) > 2:
                    oov_chars[ch] += 1
        bible_mean = sum(bible_ratios) / len(bible_ratios)
        print(f"  Mean tokens/char on Bible text: {bible_mean:.2f}")
        print(f"  Total unique characters in sample: {len(all_chars)}")
        print(f"  Characters that take 3+ tokens each:")
        if not oov_chars:
            print(f"    (none — all characters tokenize in 1-2 tokens)")
        for ch, n in oov_chars.most_common(20):
            name = unicodedata.name(ch, repr(ch))
            print(f"    {ch!r:<6}  {name[:40]:<40}  appears in {n} verses")
        print()
    else:
        print(f"  No Bible verses found at {BIBLE_DIR}. Skipping.\n")

    # --- 4. Verdict --------------------------------------------------
    verdict, reasons = _verdict(char_table, word_ratios)
    print("=" * 60)
    print(f"VERDICT: {verdict}")
    for r in reasons:
        print(f"  - {r}")
    print("=" * 60)

    # Dump report so it can be reviewed later or shared.
    report_path = OUT_DIR / "tokenizer_report.json"
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump({
            "model_id": MODEL_ID,
            "tokenizer_class": type(tok).__name__,
            "vocab_size": tok.vocab_size,
            "verdict": verdict,
            "reasons": reasons,
            "char_table": char_table,
            "awing_word_count": len(awing_words),
            "awing_word_mean_ratio": (
                sum(word_ratios) / len(word_ratios) if word_ratios else None
            ),
            "awing_word_max_ratio": max(word_ratios) if word_ratios else None,
            "bible_mean_ratio": bible_mean,
            "expensive_chars": [c["char"] for c in expensive_chars],
        }, f, ensure_ascii=False, indent=2)
    print(f"\nReport saved: {report_path}")

    return 0 if verdict == "GO" else (2 if verdict == "CONCERNING" else 1)


def _load_awing_words(dart_path: Path) -> list[str]:
    """Extract every awing: 'word' literal from the Dart vocab file.

    We don't care about category/definition here — just the raw Awing
    text we'll feed the tokenizer.
    """
    if not dart_path.exists():
        return []
    text = dart_path.read_text(encoding="utf-8")
    # Match awing: 'word' or awing: "word" — handle escaped apostrophes.
    pattern = r"awing:\s*(['\"])((?:\\.|(?!\1).)*)\1"
    words = []
    for m in re.finditer(pattern, text):
        raw = m.group(2).replace("\\'", "'").replace('\\"', '"')
        if raw:
            words.append(raw)
    return words


def _load_bible_verses(corpus_dir: Path, max_verses: int = 200) -> list[str]:
    """Sample verses from the aligned Bible corpus to test training-time text."""
    if not corpus_dir.exists():
        return []
    out = []
    for verses_json in sorted(corpus_dir.rglob("*.verses.json")):
        try:
            entries = json.loads(verses_json.read_text(encoding="utf-8"))
        except Exception:
            continue
        for e in entries:
            t = (e.get("text") or "").strip()
            if t:
                out.append(t)
            if len(out) >= max_verses:
                return out
    return out


def _verdict(char_table: list[dict], word_ratios: list[float]) -> tuple[str, list[str]]:
    """Render a go/no-go decision based on the measured tokenization cost.

    Heuristics, all calibrated against typical multilingual fine-tunes:
      - GO if: no character takes >4 tokens, mean word token/char ratio <2.0
      - CONCERNING if: 1-3 characters take >4 tokens, OR mean ratio 2.0-3.0
      - NO-GO if: many characters at >4 tokens, OR mean ratio >3.0
    """
    reasons = []
    very_expensive = [c for c in char_table if c["tokens"] >= 4]

    mean_word_ratio = (
        sum(word_ratios) / len(word_ratios) if word_ratios else None
    )

    if very_expensive:
        reasons.append(
            f"{len(very_expensive)} Awing-special characters take 4+ tokens each: "
            f"{', '.join(c['char'] for c in very_expensive)}"
        )

    if mean_word_ratio is not None:
        reasons.append(
            f"Mean tokens-per-character on Awing words: {mean_word_ratio:.2f}"
        )

    # Decide
    if not very_expensive and (mean_word_ratio is None or mean_word_ratio < 2.0):
        return ("GO", reasons + [
            "Tokenizer represents Awing efficiently. Proceed to data prep.",
        ])
    if len(very_expensive) <= 3 and (mean_word_ratio is None or mean_word_ratio < 3.0):
        return ("CONCERNING", reasons + [
            "Some Awing characters are expensive but the bulk tokenises OK.",
            "Recommend: proceed with fine-tune, but watch loss curves carefully.",
            "If training plateaus, consider pre-substituting expensive characters.",
        ])
    return ("NO-GO", reasons + [
        "Tokenizer represents Awing too granularly. Fine-tune unlikely to converge.",
        "Recommend: pre-substitute Awing-special chars (e.g. ɛ→eh, ɔ→aw) before "
        "feeding to the model — same approach as Session 19's awing_to_speakable.",
    ])


if __name__ == "__main__":
    sys.exit(main())
