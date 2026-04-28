"""
Inspect MMS tokenizer vocabularies to check Awing character support.

For each of the 11 available MMS TTS models, download just the tokenizer
(not the full VITS weights — saves ~900 MB vs loading all models) and
report which Awing-essential characters each tokenizer natively contains.

A model whose tokenizer lacks a character CANNOT produce that character's
phoneme natively — it will drop it, map it to UNK, or substitute a similar
char. That means:
  - No ɛ in vocab → every "ɛ" in Awing input is silently changed before
    synthesis, so the resulting audio won't match the target phoneme.
  - No tone diacritics in vocab → model can't distinguish tonal pairs
    regardless of input.

This is Path 3 from Session 52's narrowing strategy: rule out models that
are architecturally incapable of producing Awing phonemes before we waste
time on listening tests.

Usage:
    python scripts/inspect_mms_tokenizers.py

Output:
    Matrix of 11 models x target Awing characters (✓ / ✗).
    Summary grouping: full support / partial / cannot produce natively.
"""

import json
import os
import sys
import unicodedata
from pathlib import Path


# ============================================================
# Venv auto-activation (matches pattern from generate_audio_edge.py)
# ============================================================
def _ensure_venv():
    if sys.prefix != sys.base_prefix:
        return
    script_dir = Path(__file__).resolve().parent
    venv_python = script_dir.parent / "venv" / "Scripts" / "python.exe"
    if not venv_python.exists():
        venv_python = script_dir.parent / "venv" / "bin" / "python"
    if not venv_python.exists():
        print("venv not found. Run scripts\\install_dependencies.bat first.")
        sys.exit(1)
    if os.path.abspath(str(venv_python)) == os.path.abspath(sys.executable):
        return
    import subprocess
    result = subprocess.run([str(venv_python), __file__, *sys.argv[1:]])
    sys.exit(result.returncode)


_ensure_venv()


# ============================================================
# Model candidates (11 available per Session 52 probe)
# ============================================================
MMS_MODELS = [
    ("pny", "Pinyin (Cameroonian)",  "T1 Ngemba — Awing's own subgroup"),
    ("ybb", "Yemba",                 "T2 Eastern Grassfields (Bamileke)"),
    ("lns", "Lamnso'",               "T3 Ring Grassfields"),
    ("mnf", "Mundani",               "T4 Momo Grassfields"),
    ("bss", "Akoose",                "T5 S.Bantoid (Session 8 baseline)"),
    ("mcu", "Mambila",               "T5 S.Bantoid (Session 8 baseline)"),
    ("mcp", "Makaa",                 "T5 S.Bantoid (Session 8 baseline)"),
    ("hau", "Hausa",                 "T6 Non-Bantu reference"),
    ("ful", "Fulfulde",              "T6 Non-Bantu reference"),
    ("yor", "Yoruba",                "T6 Non-Bantu, 3-tone system"),
    ("swh", "Swahili",               "T6 Current baseline"),
]


# ============================================================
# Target Awing characters + phonological roles
# ============================================================
# Special vowels (Awing-specific, not in standard Bantu 5-vowel)
SPECIAL_VOWELS = [
    ("ɛ", "open-mid front"),
    ("ɔ", "open-mid back"),
    ("ə", "schwa"),
    ("ɨ", "close central"),
]

# Velar nasal (prenasalized consonants: ŋg, ŋk)
SPECIAL_CONSONANTS = [
    ("ŋ", "velar nasal"),
]

# Tone diacritics (combining marks — Awing is a 5-tone language)
# NFD-decomposed: base char + combining mark
TONE_MARKS = [
    ("\u0301", "combining acute (H)"),
    ("\u0300", "combining grave (L)"),
    ("\u0302", "combining circumflex (fall)"),
    ("\u030C", "combining caron (rise)"),
]

# Full probe set: test each char as standalone AND inside a common base
# (tokenizers sometimes store precomposed forms like "á" U+00E1 but
# not the combining mark alone — we check both)
PRECOMPOSED_TONES = [
    ("á", "a + acute"),
    ("à", "a + grave"),
    ("â", "a + circumflex"),
    ("ǎ", "a + caron"),
]


# ============================================================
# Vocab inspection
# ============================================================
def get_tokenizer_vocab(model_code: str):
    """
    Download tokenizer.json + vocab.json + tokenizer_config.json for a model.
    Returns the set of tokens (chars) the model's tokenizer recognizes,
    plus a dict of any other metadata found.

    Uses huggingface_hub to fetch just the tokenizer files (~50 KB each),
    NOT the full VITS weights (~83 MB per model).
    """
    from huggingface_hub import hf_hub_download
    from huggingface_hub.utils import HfHubHTTPError

    repo_id = f"facebook/mms-tts-{model_code}"
    tokens = set()
    metadata = {}

    # Try vocab.json first — it's the canonical char-level vocab for VITS
    try:
        vocab_path = hf_hub_download(
            repo_id=repo_id,
            filename="vocab.json",
            repo_type="model",
        )
        with open(vocab_path, "r", encoding="utf-8") as f:
            vocab = json.load(f)
        # vocab.json is {"char": id, ...}
        tokens.update(vocab.keys())
        metadata["vocab_size"] = len(vocab)
        metadata["source"] = "vocab.json"
    except HfHubHTTPError as e:
        metadata["vocab_error"] = str(e)

    # Also check tokenizer_config.json for special tokens
    try:
        cfg_path = hf_hub_download(
            repo_id=repo_id,
            filename="tokenizer_config.json",
            repo_type="model",
        )
        with open(cfg_path, "r", encoding="utf-8") as f:
            cfg = json.load(f)
        metadata["tokenizer_class"] = cfg.get("tokenizer_class", "?")
        metadata["is_uroman"] = cfg.get("is_uroman", False)
    except HfHubHTTPError:
        pass

    return tokens, metadata


def char_in_vocab(char: str, tokens: set) -> bool:
    """
    A char is "in vocab" if:
      - The char itself is a token, OR
      - Any token contains the char as a substring (multi-char tokens),
      - OR the NFD-decomposed form appears in any token.
    """
    if char in tokens:
        return True
    nfd = unicodedata.normalize("NFD", char)
    if nfd in tokens:
        return True
    for tok in tokens:
        if char in tok or nfd in tok:
            return True
    return False


# ============================================================
# Main
# ============================================================
def main():
    print("=" * 72)
    print("MMS Tokenizer Inspection — Awing Character Support")
    print("=" * 72)
    print()
    print(f"Checking {len(MMS_MODELS)} models for Awing-essential chars.")
    print("(Downloads only tokenizer files, not VITS weights — ~1 MB total)")
    print()

    # Collect vocab for each model
    results = {}
    for code, name, tier in MMS_MODELS:
        print(f"  {code:4s} {name:28s} ", end="", flush=True)
        try:
            tokens, meta = get_tokenizer_vocab(code)
            results[code] = {
                "name": name,
                "tier": tier,
                "tokens": tokens,
                "meta": meta,
            }
            uroman_flag = " (uroman)" if meta.get("is_uroman") else ""
            print(f"✓ {meta.get('vocab_size', '?')} tokens{uroman_flag}")
        except Exception as e:
            print(f"✗ {type(e).__name__}: {e}")
            results[code] = {
                "name": name,
                "tier": tier,
                "tokens": set(),
                "meta": {"error": str(e)},
            }

    print()
    print("=" * 72)
    print("Character Support Matrix")
    print("=" * 72)
    print()

    # Build the full probe list
    probe_chars = (
        [(c, role, "vowel") for c, role in SPECIAL_VOWELS]
        + [(c, role, "consonant") for c, role in SPECIAL_CONSONANTS]
        + [(c, role, "tone") for c, role in TONE_MARKS]
        + [(c, role, "precomposed") for c, role in PRECOMPOSED_TONES]
    )

    # Print header — char labels
    char_labels = [f"{c}" for c, _, _ in probe_chars]
    col_w = 4
    header = f"{'code':5s}" + "".join(f"{lbl:^{col_w}}" for lbl in char_labels)
    print(header)
    print("-" * len(header))

    # Print row per model
    per_model_results = {}
    for code, _, _ in MMS_MODELS:
        info = results[code]
        tokens = info["tokens"]
        row = f"{code:5s}"
        supported = []
        missing = []
        for char, role, category in probe_chars:
            has = char_in_vocab(char, tokens) if tokens else False
            row += f"{'✓' if has else '✗':^{col_w}}"
            if has:
                supported.append((char, role, category))
            else:
                missing.append((char, role, category))
        print(row)
        per_model_results[code] = {
            "supported": supported,
            "missing": missing,
            "is_uroman": info["meta"].get("is_uroman", False),
        }

    print()
    print("Legend: ✓ = char/substring found in tokenizer vocab")
    print("        ✗ = tokenizer cannot produce this phoneme natively")
    print()

    # ========================================================
    # Summary — group models by Awing compatibility
    # ========================================================
    print("=" * 72)
    print("Summary by Compatibility")
    print("=" * 72)
    print()

    # Count essential chars (all non-precomposed)
    # Precomposed á/à/â/ǎ are optional — if a model has the base + combining
    # mark, it can still render them.
    essential_vowels = set(c for c, _ in SPECIAL_VOWELS)
    essential_cons = set(c for c, _ in SPECIAL_CONSONANTS)
    essential_tones = set(c for c, _ in TONE_MARKS)

    def score(code):
        r = per_model_results[code]
        sup = set(c for c, _, _ in r["supported"])
        v = len(essential_vowels & sup)
        c = len(essential_cons & sup)
        t = len(essential_tones & sup)
        return v, c, t

    ranked = sorted(
        [(code, score(code)) for code, _, _ in MMS_MODELS],
        key=lambda x: (-x[1][0] - x[1][1] - x[1][2], x[0]),
    )

    full = []
    partial = []
    incompatible = []
    uroman = []

    for code, (v, c, t) in ranked:
        r = per_model_results[code]
        info = results[code]
        # uroman models romanize all input to ASCII anyway — they can't
        # preserve Awing chars regardless of vocab contents
        if r["is_uroman"]:
            uroman.append((code, info["name"], info["tier"], v, c, t))
            continue
        total_essential = v + c + t
        max_essential = len(essential_vowels) + len(essential_cons) + len(essential_tones)
        if total_essential == max_essential:
            full.append((code, info["name"], info["tier"], v, c, t))
        elif total_essential >= max_essential // 2:
            partial.append((code, info["name"], info["tier"], v, c, t))
        else:
            incompatible.append((code, info["name"], info["tier"], v, c, t))

    def print_group(label: str, group: list):
        if not group:
            print(f"  {label}: (none)")
            print()
            return
        print(f"  {label}:")
        for code, name, tier, v, c, t in group:
            total_e = len(essential_vowels) + len(essential_cons) + len(essential_tones)
            print(
                f"    {code:4s} {name:28s} "
                f"vowels {v}/{len(essential_vowels)} "
                f"cons {c}/{len(essential_cons)} "
                f"tones {t}/{len(essential_tones)}  "
                f"({tier})"
            )
        print()

    print_group("FULL Awing support (recommended candidates)", full)
    print_group("PARTIAL support (missing some essentials)", partial)
    print_group("INCOMPATIBLE (missing most essentials)", incompatible)
    print_group("UROMAN (romanizes all input — cannot preserve Awing chars)", uroman)

    # ========================================================
    # Recommendation
    # ========================================================
    print("=" * 72)
    print("Recommendation")
    print("=" * 72)
    print()

    if full:
        top = full[0]
        print(f"  Strongest candidate: {top[0]} ({top[1]})")
        print(f"    Tier: {top[2]}")
        print(f"    Has all Awing-essential characters in tokenizer vocab.")
        print()
        print(f"  Next step: run a listening test on {top[0]}")
        print(f"    (generate 10-20 Awing words and compare against current")
        print(f"     Swahili Edge TTS baseline)")
    elif partial:
        print("  No model has full Awing char support.")
        print("  Best partial candidates (in order):")
        for code, name, tier, v, c, t in partial[:3]:
            print(f"    {code} ({name}) — {tier}")
        print()
        print("  Next step: consider fine-tuning the best-ranked Tier 1/2")
        print("  candidate on native Awing recordings (Path 2 from Session 52).")
    else:
        print("  No MMS model has meaningful Awing char support.")
        print("  Stick with current Swahili (swh) Edge TTS + per-word")
        print("  speakable_override pipeline (Sessions 48-49).")
        print()
        print("  Consider Path 2: fine-tune pny (Tier 1 Ngemba) base on")
        print("  native Awing recordings for a proper custom model.")

    print()


if __name__ == "__main__":
    main()
