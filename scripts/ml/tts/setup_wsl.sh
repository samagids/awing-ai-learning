#!/usr/bin/env bash
# ==========================================================
#  Coqui TTS / YourTTS WSL setup for Awing multi-speaker fine-tune
# ==========================================================
#  Runs in WSL2 Ubuntu. Installs Coqui's TTS package with PyTorch
#  CUDA 12.8 (Blackwell sm_120 support), downloads the pretrained
#  YourTTS multi-speaker multilingual checkpoint, and verifies the
#  install by listing the available speakers/languages.
#
#  Run from the Awing repo root (visible inside WSL via /mnt/c):
#      cd /mnt/c/Users/samag/OneDrive/Documents/Claude/Awing
#      bash scripts/ml/tts/setup_wsl.sh
#
#  After this, run scripts/ml/tts/smoke_test.py to verify the
#  pretrained model can generate distinct voices on the RTX 5070.
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
    build-essential cmake ninja-build espeak-ng \
    python3 python3-venv python3-pip python3-dev \
    git curl ffmpeg libsndfile1

# --- 3. venv_coqui_y -------------------------------------
# Create a fresh venv specifically for this attempt, separate from
# any prior Coqui venvs so we know the dependency graph is clean.

VENV="$HOME/venv_coqui_y"

if [ -d "$VENV" ]; then
    say "venv_coqui_y already exists at $VENV — reusing"
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
assert cap[0] >= 9 or (cap[0] == 12 and cap[1] >= 0), \
    'Blackwell sm_120+ expected, got sm_' + str(cap[0]) + str(cap[1])
"

# --- 5. Coqui TTS ----------------------------------------
# coqui-tts is the maintained community fork after the original `TTS`
# package was archived. The dependency pinning here is critical — it
# was learned the hard way in Session 54 of this project:
#
#   numpy<2          coqui codebase still has numpy 1.x assumptions
#   transformers>=4.55,<5.0   coqui imports `isin_mps_friendly` which
#                             exists ONLY in this version range:
#                             added in 4.55, removed in 5.0
#   tokenizers>=0.21,<0.22    transformers 4.55's pin
#   huggingface_hub<1.0       same family of pins
#
# Without these pins, pip happily resolves transformers to 5.x and
# `from TTS.api import TTS` fails with ImportError on isin_mps_friendly.

say "Installing coqui-tts (with version pins from Sessions 54 + 56 lessons)"
# Pin notes:
#   transformers>=4.57,<5.0   coqui-tts 0.27.5 requires >=4.57 (was >=4.55
#                             in older releases). Upper bound stays <5.0
#                             because transformers 5.x removed the
#                             `isin_mps_friendly` symbol that coqui's
#                             tortoise backend imports.
#   tokenizers>=0.21,<0.22    transformers 4.57's tokenizers pin
#   huggingface_hub<1.0       transformers 4.57 still on hub <1.0
#   numpy<2                   coqui codebase has numpy 1.x assumptions
#   torchcodec                Required since PyTorch 2.9 moved audio IO
#                             out of torchaudio core. Apt's ffmpeg
#                             provides the system libs torchcodec links to.
python3 -m pip install \
    "numpy<2" \
    "transformers>=4.57,<5.0" \
    "tokenizers>=0.21,<0.22" \
    "huggingface_hub>=0.26.0,<1.0" \
    "coqui-tts>=0.27" \
    "torchcodec"

# Trainer is bundled with coqui-tts now, but verify
python3 -m pip install "coqui-tts-trainer>=0.3" || true

python3 -c "
from TTS.api import TTS
print('coqui-tts import OK')
"

# --- 6. Download YourTTS pretrained ----------------------
# Coqui caches under ~/.local/share/tts/ once we instantiate the model
# the first time. Triggering that explicitly here avoids a slow first
# step in the smoke test.

say "Downloading YourTTS pretrained checkpoint (first call only, ~600 MB)"

python3 - <<'PY'
import os, sys
# Suppress the EULA prompt that Coqui shows on first model download
os.environ["COQUI_TOS_AGREED"] = "1"
from TTS.api import TTS

print("Loading YourTTS multilingual multispeaker model...")
tts = TTS(model_name="tts_models/multilingual/multi-dataset/your_tts",
          progress_bar=False)
print("OK")
print()
print("Available speakers:", len(tts.speakers) if tts.speakers else 0)
if tts.speakers:
    print("First 10 speaker IDs:", tts.speakers[:10])
print("Available languages:", tts.languages)
PY

say "Setup complete"
echo ""
echo "Next: bash scripts/ml/tts/setup_wsl.sh (DONE)"
echo "      Then: source $VENV/bin/activate"
echo "            python3 scripts/ml/tts/smoke_test.py"
echo ""
