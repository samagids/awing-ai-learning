#!/usr/bin/env python3
"""Apply all known patches to ~/Qwen3-TTS/finetuning/{sft_12hz,prepare_data}.py.

Why a Python patcher (not sed):
The sed chains were getting brittle as we discovered each new compat
issue running sft_12hz.py on:
  - WSL2 + cu128 + Blackwell (no flash-attn, no nvcc)
  - accelerate >= 0.30 (logging_dir validation)
  - 12 GB VRAM (AdamW fp32 state busts the budget)
  - Default sft_12hz.py upstream (double-shift loss bug, Issue #189)

This script is idempotent. Each patch checks for its own marker before
applying so re-running it after a partial fix is safe.

Patches applied to sft_12hz.py:
  (a) Double-shift loss bug (Issue #189) — labels[1:] / logits[:-1] removed.
  (b) Accelerator logging_dir — adds project_dir=args.output_model_path.
  (c) Flash attention — swaps "flash_attention_2" -> "sdpa".
  (d) Gradient checkpointing — model.gradient_checkpointing_enable() after load.
  (e) 8-bit AdamW — swaps torch.optim.AdamW for bitsandbytes.optim.AdamW8bit.
                    Requires `pip install bitsandbytes` separately.
  (f) text_projection bridge — wrap text_embedding through talker.text_projection
                    so its output (text_hidden_size=2048) lines up with
                    codec_embedding (hidden_size=1024) on the 0.6B variant.
                    Mirrors the inference code path. Required for 0.6B-Base;
                    benign on 1.7B-Base where text_projection is identity-shaped.

Patches applied to prepare_data.py:
  (g) BATCH_INFER_NUM 32 -> 1 — hard-codes batch size 1 during codec
                    encoding. The Mimi codec's conv intermediate tensors
                    scale with batch and at batch=32 OOM'd a 10 GB WSL
                    on CPU. batch=1 caps RAM at ~3 GB.
  (h) gc.collect()  — explicit GC + cuda cache empty between batches so
                    intermediate tensors are freed promptly.

Run from anywhere (uses $HOME):
    python3 scripts/ml/tts/patch_sft.py
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

DEFAULT_PATH = Path(os.path.expanduser("~/Qwen3-TTS/finetuning/sft_12hz.py"))
PREP_PATH = Path(os.path.expanduser("~/Qwen3-TTS/finetuning/prepare_data.py"))


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PATH
    if not path.exists():
        print(f"ERROR: {path} not found.")
        print("  Run scripts/ml/tts/setup_finetune_wsl.sh to clone the repo first.")
        return 1

    # Apply the prepare_data.py patches separately — independent file.
    if PREP_PATH.exists():
        _patch_prepare_data(PREP_PATH)
    else:
        print(f"WARNING: {PREP_PATH} not found — skipping prepare_data patches")

    src = path.read_text(encoding="utf-8")
    orig = src

    # Make a one-shot backup before our first edit.
    backup = path.with_suffix(path.suffix + ".orig")
    if not backup.exists():
        backup.write_text(src, encoding="utf-8")
        print(f"Backup saved: {backup}")

    applied = []
    skipped = []

    # --- (a) Double-shift loss bug (Issue #189) ----------------------
    if "shift_labels = labels[..., 1:].contiguous()" in src:
        src = src.replace(
            "shift_labels = labels[..., 1:].contiguous()",
            "shift_labels = labels.contiguous()",
        )
        src = src.replace(
            "shift_logits = logits[..., :-1, :].contiguous()",
            "shift_logits = logits.contiguous()",
        )
        applied.append("(a) double-shift loss bug")
    else:
        skipped.append("(a) double-shift bug not present")

    # --- (b) Accelerator logging_dir ---------------------------------
    if 'log_with="tensorboard")' in src:
        src = src.replace(
            'log_with="tensorboard")',
            'log_with="tensorboard", project_dir=args.output_model_path)',
        )
        applied.append("(b) Accelerator project_dir")
    else:
        skipped.append("(b) Accelerator project_dir already set")

    # --- (c) Flash attention -> sdpa ---------------------------------
    if 'attn_implementation="flash_attention_2"' in src:
        src = src.replace(
            'attn_implementation="flash_attention_2"',
            'attn_implementation="sdpa"',
        )
        applied.append("(c) flash_attention_2 -> sdpa")
    else:
        skipped.append("(c) attn_implementation already sdpa")

    # --- (d) Gradient checkpointing ----------------------------------
    if "gradient_checkpointing_enable" not in src:
        # Insert after the AutoConfig load — that's the safest anchor that
        # comes after the model is bound to qwen3tts.
        anchor = "config = AutoConfig.from_pretrained(MODEL_PATH)"
        replacement = (
            "config = AutoConfig.from_pretrained(MODEL_PATH)\n"
            "    # Patch (d): gradient checkpointing — saves activation VRAM\n"
            "    qwen3tts.model.gradient_checkpointing_enable()"
        )
        if anchor in src:
            src = src.replace(anchor, replacement)
            applied.append("(d) gradient_checkpointing_enable")
        else:
            skipped.append("(d) couldn't find AutoConfig anchor")
    else:
        skipped.append("(d) gradient_checkpointing already enabled")

    # --- (f) text_projection bridge for 0.6B model dim mismatch ------
    # The 0.6B-Base config has talker.text_hidden_size=2048 (text encoder
    # vocab) and talker.hidden_size=1024 (audio decoder). The model class
    # `Qwen3TTSTalkerForConditionalGeneration` already defines a
    # `text_projection` MLP (2048->2048->1024) AND every inference code
    # path runs text_embedding output through it. sft_12hz.py is the only
    # site that skips the projection, accessing model.talker.model
    # .text_embedding directly. This adds back the projection.
    #
    # We deliberately apply this patch unconditionally (not 0.6B-only)
    # because the inference path always uses text_projection — keeping
    # train/inference consistent is correct, and on 1.7B the projection
    # is identity-shaped (2048->2048->2048) so the math is preserved.

    OLD_F = ("input_text_embedding = model.talker.model.text_embedding"
             "(input_text_ids) * text_embedding_mask")
    NEW_F = ("input_text_embedding = model.talker.text_projection("
             "model.talker.model.text_embedding(input_text_ids)) "
             "* text_embedding_mask")
    if OLD_F in src:
        src = src.replace(OLD_F, NEW_F)
        applied.append("(f) text_projection bridge")
    elif "model.talker.text_projection(" in src:
        skipped.append("(f) text_projection bridge already applied")
    else:
        skipped.append("(f) text_embedding line pattern not found")

    # --- (e) 8-bit AdamW from bitsandbytes ---------------------------
    if "AdamW8bit" not in src:
        # Replace `from torch.optim import AdamW` with bnb 8-bit AdamW.
        # Handle both bare import and grouped import variants.
        patched_e = False

        bare = re.compile(r"^from torch\.optim import AdamW\s*$", re.MULTILINE)
        if bare.search(src):
            src = bare.sub(
                "# Patch (e): swapped torch AdamW for bitsandbytes 8-bit\n"
                "from bitsandbytes.optim import AdamW8bit as AdamW",
                src, count=1,
            )
            patched_e = True

        # Handle `from torch.optim import AdamW, ...` or
        # `from torch.optim import ..., AdamW, ...`
        if not patched_e:
            grouped = re.compile(
                r"^(from torch\.optim import .*?)\bAdamW\b(.*)$",
                re.MULTILINE,
            )
            m = grouped.search(src)
            if m:
                # Drop AdamW from the torch.optim import, add the bnb import below.
                line = m.group(0)
                cleaned = re.sub(r",\s*AdamW", "", line)
                cleaned = re.sub(r"AdamW\s*,\s*", "", cleaned)
                if "AdamW" in cleaned:
                    # was the only one — drop the entire line
                    cleaned = ""
                src = src.replace(
                    line,
                    (cleaned + "\n" if cleaned else "")
                    + "# Patch (e): bitsandbytes 8-bit AdamW\n"
                    + "from bitsandbytes.optim import AdamW8bit as AdamW",
                )
                patched_e = True

        if patched_e:
            applied.append("(e) 8-bit AdamW")
        else:
            skipped.append("(e) couldn't find AdamW import to swap")
    else:
        skipped.append("(e) AdamW8bit already imported")

    # --- Write back if anything changed ------------------------------
    if src != orig:
        path.write_text(src, encoding="utf-8")
        print(f"Patched: {path}")
    else:
        print(f"No changes needed: {path}")

    print()
    if applied:
        print("Applied:")
        for a in applied:
            print(f"  {a}")
    if skipped:
        print("Skipped (already patched or not present):")
        for s in skipped:
            print(f"  {s}")

    # If we patched (e), bitsandbytes must be installed for the file
    # to even import. Check and warn loudly.
    if "(e) 8-bit AdamW" in applied:
        try:
            import bitsandbytes  # noqa: F401
            print("\n  bitsandbytes already installed.")
        except ImportError:
            print("\n  WARNING: bitsandbytes not installed.")
            print("           Run: pip install bitsandbytes")

    return 0


def _patch_prepare_data(path: Path) -> None:
    """Patches (g) and (h) on prepare_data.py.

    (g) BATCH_INFER_NUM 32 -> 1: at batch 32 the Mimi codec encoder's
        intermediate tensors balloon enough to OOM a 10 GB WSL on CPU.
        Batch 1 caps peak RAM around 3 GB during encoding.
    (h) gc.collect() between batches: explicit cleanup so intermediate
        tensors are freed promptly instead of waiting on Python's GC.
    """
    src = path.read_text(encoding="utf-8")
    orig = src

    backup = path.with_suffix(path.suffix + ".orig")
    if not backup.exists():
        backup.write_text(src, encoding="utf-8")
        print(f"Backup saved: {backup}")

    applied = []
    skipped = []

    # (g) batch size 32 -> 1
    if "BATCH_INFER_NUM = 32" in src:
        src = src.replace("BATCH_INFER_NUM = 32", "BATCH_INFER_NUM = 1")
        applied.append("(g) BATCH_INFER_NUM 32 -> 1")
    elif "BATCH_INFER_NUM = 1" in src:
        skipped.append("(g) BATCH_INFER_NUM already 1")
    else:
        skipped.append("(g) BATCH_INFER_NUM constant not found")

    # Patch (h) was: gc.collect() between batches. Disabled because it
    # made assumptions about the loop structure that don't hold in
    # upstream prepare_data.py — the inserted `del batch_audios` blew
    # up the next iteration with UnboundLocalError. At BATCH_INFER_NUM=1
    # the memory pressure is small enough that explicit GC isn't needed.
    skipped.append("(h) skipped — unsafe given upstream loop structure")

    if src != orig:
        path.write_text(src, encoding="utf-8")
        print(f"Patched: {path}")

    print()
    if applied:
        print("prepare_data.py applied:")
        for a in applied:
            print(f"  {a}")
    if skipped:
        print("prepare_data.py skipped:")
        for s in skipped:
            print(f"  {s}")


if __name__ == "__main__":
    sys.exit(main())
