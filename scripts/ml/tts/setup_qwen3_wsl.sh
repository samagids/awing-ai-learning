#!/usr/bin/env bash
# ==========================================================
#  Qwen3-TTS-VoiceDesign WSL setup for Awing 6-voice TTS
# ==========================================================
#  Runs in WSL2 Ubuntu. Installs the qwen-tts package with
#  PyTorch CUDA 12.8 (Blackwell sm_120 support), downloads the
#  Qwen3-TTS-12Hz-1.7B-VoiceDesign checkpoint, and verifies
#  that the model loads.
#
#  WHY a separate venv from venv_coqui_y:
#    qwen-tts pulls a different transformers/tokenizers/torch
#    pin set than coqui-tts. Keeping them in separate venvs
#    avoids the dependency-resolution dance that bit us in
#    Sessions 54-55.
#
#  Run from the Awing repo root (visible inside WSL via /mnt/c):
#      cd /mnt/c/Users/samag/OneDrive/Documents/Claude/Awing
#      bash scripts/ml/tts/setup_qwen3_wsl.sh
#
#  After this:
#      source ~/venv_qwen3/bin/activate
#      python3 scripts/ml/tts/smoke_test_qwen3.py
# ==========================================================

set -euo pipefail

say() { printf "\n==========================\n %s\n==========================\n" "$*"; }

# --- 1. Verify WSL + GPU ---------------------------------

say "Checking WSL + NVIDIA GPU"

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "WARNING: doesn't look like WSL. Script assumes Ubuntu in WSL2."
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "ERROR: nvidia-smi not found. WSL2 GPU passthrough requires:"
    echo "  - Windows side: NVIDIA driver 570+ (Blackwell-ready)"
    echo "  - WSL2: up-to-date Ubuntu (run \`wsl --update\` on Windows)"
    exit 1
fi
nvidia-smi | head -20
echo ""

# --- 2. System packages ----------------------------------

say "Installing system packages"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build \
    python3 python3-venv python3-pip python3-dev \
    git curl ffmpeg libsndfile1

# --- 3. venv_qwen3 ---------------------------------------

VENV="$HOME/venv_qwen3"

if [ -d "$VENV" ]; then
    say "venv_qwen3 already exists at $VENV — reusing"
else
    say "Creating $VENV"
    python3 -m venv "$VENV"
fi

# shellcheck disable=SC1091
source "$VENV/bin/activate"
python3 -m pip install --upgrade pip setuptools wheel

# --- 4. PyTorch with cu128 (Blackwell sm_120) ------------

say "Installing PyTorch cu128"
python3 -m pip install --index-url https://download.pytorch.org/whl/cu128 \
    torch torchvision torchaudio

python3 -c "
import torch
assert torch.cuda.is_available(), 'CUDA not available in WSL'
cap = torch.cuda.get_device_capability(0)
print('GPU:', torch.cuda.get_device_name(0), f'| sm_{cap[0]}{cap[1]}')
print('CUDA:', torch.version.cuda, '| torch:', torch.__version__)
print('bfloat16 supported:', torch.cuda.is_bf16_supported())
"

# --- 5. qwen-tts -----------------------------------------
# qwen-tts is the Alibaba-published runtime for Qwen3-TTS models.
# It pulls in transformers + tokenizers + huggingface_hub at the
# pins it needs. We let it resolve those itself rather than
# pre-pinning, since this is a fresh venv and there's nothing to
# conflict with.

say "Installing qwen-tts"
python3 -m pip install -U qwen-tts soundfile

python3 -c "
import qwen_tts
print('qwen_tts OK | version:', getattr(qwen_tts, '__version__', '?'))
from qwen_tts import Qwen3TTSModel
print('Qwen3TTSModel import OK')
"

# --- 6. flash-attn (best effort) -------------------------
# Qwen3-TTS recommends flash_attention_2 for speed. The official
# wheels target sm_80/86/89/90 — Blackwell sm_120 may or may not
# work depending on whether their nightly/source build supports
# it. We TRY but accept failure: smoke_test_qwen3.py falls back
# to "sdpa" which works on every CUDA-capable GPU.

say "Trying flash-attn (best effort; falls back to sdpa if it fails)"
python3 -m pip install flash-attn --no-build-isolation \
    || echo "  flash-attn install failed — that's OK, smoke test will use 'sdpa'."

# --- 7. Download VoiceDesign checkpoint ------------------
# The 1.7B-VoiceDesign variant is the one that supports
# natural-language voice prompts. Pre-fetch so the smoke test
# doesn't hang on first download.

say "Downloading Qwen3-TTS-12Hz-1.7B-VoiceDesign checkpoint"
echo "  (~4 GB, one-time, cached under ~/.cache/huggingface)"

python3 - <<'PY'
import os, sys
from huggingface_hub import snapshot_download

model_id = "Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign"
print(f"Snapshotting {model_id}...")
path = snapshot_download(model_id)
print(f"Cached at: {path}")
PY

say "Setup complete"
echo ""
echo "Next:"
echo "  source $VENV/bin/activate"
echo "  python3 scripts/ml/tts/smoke_test_qwen3.py"
echo ""
echo "Then open the audition page in Chrome on Windows:"
echo "  C:\\Users\\samag\\OneDrive\\Documents\\Claude\\Awing\\models\\tts_audition\\qwen3_smoke_test\\index.html"
echo ""
