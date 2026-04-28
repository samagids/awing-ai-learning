#!/usr/bin/env bash
# ==========================================================
#  Qwen3-TTS Awing fine-tuning environment setup (WSL2)
# ==========================================================
#  Extends the existing ~/venv_qwen3 environment with the
#  fine-tuning dependencies, clones the official QwenLM/Qwen3-TTS
#  repo for its sft_12hz.py + prepare_data.py + dataset.py, and
#  pre-downloads the Qwen3-TTS-12Hz-1.7B-Base checkpoint that
#  we'll fine-tune from.
#
#  Run from the Awing repo root inside WSL:
#      cd /mnt/c/Users/samag/OneDrive/Documents/Claude/Awing
#      bash scripts/ml/tts/setup_finetune_wsl.sh
#
#  Prereq: setup_qwen3_wsl.sh has already run and ~/venv_qwen3
#  exists with qwen-tts installed.
# ==========================================================

set -euo pipefail

say() { printf "\n==========================\n %s\n==========================\n" "$*"; }

# --- 1. Verify prereqs -----------------------------------

say "Verifying prerequisites"

VENV="$HOME/venv_qwen3"
if [ ! -d "$VENV" ]; then
    echo "ERROR: $VENV not found."
    echo "  Run scripts/ml/tts/setup_qwen3_wsl.sh first to create the base venv."
    exit 1
fi

# shellcheck disable=SC1091
source "$VENV/bin/activate"

python3 -c "import qwen_tts; print('qwen_tts OK')" || {
    echo "ERROR: qwen_tts not installed in $VENV. Re-run setup_qwen3_wsl.sh."
    exit 1
}

python3 -c "
import torch
assert torch.cuda.is_available(), 'CUDA not available'
print('GPU:', torch.cuda.get_device_name(0))
print('VRAM:', round(torch.cuda.get_device_properties(0).total_memory / 1e9, 1), 'GB')
"

# --- 2. Clone the official repo --------------------------
# We need sft_12hz.py, prepare_data.py, dataset.py from upstream.
# Clone into the user's home dir so it survives WSL session restarts.

REPO_DIR="$HOME/Qwen3-TTS"
if [ -d "$REPO_DIR/.git" ]; then
    say "Updating Qwen3-TTS repo at $REPO_DIR"
    git -C "$REPO_DIR" fetch origin
    git -C "$REPO_DIR" pull --ff-only origin main || \
        echo "  WARNING: pull failed (probably local edits). Continuing with current state."
else
    say "Cloning QwenLM/Qwen3-TTS into $REPO_DIR"
    git clone https://github.com/QwenLM/Qwen3-TTS.git "$REPO_DIR"
fi

ls -la "$REPO_DIR/finetuning/" || {
    echo "ERROR: finetuning/ subdir missing from clone."
    exit 1
}

# --- 3. Install fine-tuning dependencies -----------------
# The fine-tuning recipe needs accelerate + datasets + tensorboard
# beyond what qwen-tts ships with at inference time. bitsandbytes
# provides 8-bit AdamW which is REQUIRED to fit the 1.7B model on
# 12 GB VRAM (RTX 5070) — full fp32 AdamW state alone is ~13.6 GB.

say "Installing fine-tuning dependencies"
python3 -m pip install \
    "accelerate>=0.30" \
    "datasets>=2.18" \
    "tensorboard" \
    "soundfile" \
    "librosa" \
    "bitsandbytes>=0.43" \
    "peft>=0.10"

# --- 4. Pre-download Qwen3-TTS-12Hz-1.7B-Base ------------
# The fine-tune base. ~3 GB. Cached under ~/.cache/huggingface so future
# runs and the 6 LoRA fine-tunes share the cache.
#
# Why 1.7B and not 0.6B: with full fine-tuning, 1.7B busts 12 GB. With
# LoRA the base is FROZEN (no gradients, no optimizer state for it) so
# the 1.7B base just sits at ~3.4 GB inference-mode VRAM. The trainable
# LoRA adapter adds <100 MB. Peak VRAM with grad checkpointing: ~5-6 GB
# on a 12 GB card. We get 1.7B's quality ceiling without the OOM.

say "Downloading Qwen3-TTS-12Hz-1.7B-Base checkpoint"
echo "  (~3 GB, one-time, cached under ~/.cache/huggingface)"

python3 - <<'PY'
import os
from huggingface_hub import snapshot_download

model_id = "Qwen/Qwen3-TTS-12Hz-0.6B-Base"
print(f"Snapshotting {model_id}...")
path = snapshot_download(model_id)
print(f"Cached at: {path}")
PY

# --- 5. Install sox (silences pydub fallback warning) ----
# pydub looks for `sox` on $PATH and falls back to ffmpeg if missing.
# It works either way, but the warning spam in training logs is noisy.

say "Installing sox (suppresses pydub fallback warning during training)"
sudo apt-get install -y --no-install-recommends sox || \
    echo "  sox install failed — non-fatal, training still works via ffmpeg."

# --- 6. Patch sft_12hz.py --------------------------------
# Five idempotent patches managed by patch_sft.py. Each has been
# observed in real runs on this stack (WSL2 + cu128 + Blackwell + 12 GB):
#
#   (a) Double-shift in loss (Issue #189 in QwenLM/Qwen3-TTS).
#   (b) Missing project_dir on Accelerator (newer accelerate>=0.30).
#   (c) Hardcoded flash_attention_2 (no nvcc in WSL = unbuildable).
#   (d) No gradient checkpointing — needed to fit activations.
#   (e) Full fp32 AdamW — busts 12 GB VRAM. Swap for 8-bit AdamW.

say "Patching sft_12hz.py via patch_sft.py"
python3 "$(dirname "$0")/patch_sft.py" "$REPO_DIR/finetuning/sft_12hz.py"

# --- 7. Verify imports -----------------------------------

say "Verifying training-stack imports"
python3 -c "
import torch
import accelerate
import datasets
import qwen_tts
print('torch    :', torch.__version__)
print('accelerate:', accelerate.__version__)
print('datasets :', datasets.__version__)
print('qwen_tts : (no __version__ exposed)')
print()
print('Fine-tuning environment ready.')
"

say "Setup complete"
echo ""
echo "Next steps:"
echo "  1. Verify Awing tokenizer compatibility:"
echo "     python3 scripts/ml/tts/check_tokenizer.py"
echo ""
echo "  2. (After tokenizer check passes) Prep training data:"
echo "     python3 scripts/ml/tts/prep_finetune_data.py"
echo ""
echo "  3. (After data prep) Run a 100-step validator on one voice:"
echo "     bash scripts/ml/tts/validate_finetune.sh boy"
echo ""
echo "  4. (After validator passes) Run all 6 voices sequentially:"
echo "     bash scripts/ml/tts/train_all_voices.sh"
echo ""
echo "Repo cloned at: $REPO_DIR"
echo "Fine-tuning recipe: $REPO_DIR/finetuning/"
