#!/usr/bin/env bash
# install_dependencies.sh — WSL bash equivalent of install_dependencies.bat v3.0.0
#
# Sets up the Linux side of the dev environment under WSL2. We do NOT
# install Flutter / Android SDK / JDK on Linux — they stay on Windows
# where they're already configured, and WSL2 interop lets us call
# `flutter` from bash. We only install Linux-side things:
#   - apt: git, python3, ffmpeg, build essentials
#   - venv at <repo>/venv (or reuse $VIRTUAL_ENV if already set)
#   - pip: edge-tts, diffusers, Pillow, accelerate, transformers, etc.
#
# Run from the repo root inside WSL:
#   bash scripts/install_dependencies.sh
#
# Idempotent — safe to re-run after pulling new dependencies.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "============================================"
echo "  Awing AI Learning - WSL setup"
echo "============================================"
echo

# ---- Step 1: WSL sanity check ----------------------------------------
echo "[1/7] Checking WSL2..."
if ! grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
    echo "        WARNING: doesn't look like WSL. This script is built for WSL2 Ubuntu."
    echo "                 Continuing anyway — if you're on bare Linux, that's fine."
fi
echo "        Kernel: $(uname -r)"
echo

# ---- Step 2: apt packages --------------------------------------------
echo "[2/7] Installing apt packages (sudo required)..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    python3 python3-venv python3-pip python3-dev \
    ffmpeg libsndfile1 \
    sox
echo

# ---- Step 3: Verify Flutter (Windows-side, accessed via cmd.exe) -----
# build_and_run.sh invokes `cmd.exe /c "flutter ..."` because:
#   - the unix `flutter` shell script has CRLF on OneDrive (bash chokes)
#   - WSL2 interop only auto-routes .exe files, not .bat files —
#     calling flutter.bat directly makes bash try to parse it as a
#     shell script ("@ECHO: command not found" etc).
# So we test the same path here: `cmd.exe /c "flutter --version"`.
echo "[3/7] Checking that Windows Flutter is reachable via cmd.exe..."
if command -v cmd.exe >/dev/null 2>&1; then
    if cmd.exe /c "flutter --version" 2>/dev/null | head -1; then
        echo "        Windows-side Flutter reachable. build_and_run.sh will use this."
    else
        echo "        WARNING: cmd.exe present but 'flutter' not on its PATH."
        echo "                 Open a Windows shell and run 'flutter --version' to confirm."
        echo "                 If broken there, fix the Windows Flutter install first."
    fi
else
    echo "        WARNING: cmd.exe not available (WSL interop disabled?)."
    echo "                 Check /etc/wsl.conf has [interop] enabled = true."
fi
echo

# ---- Step 3b: Optional: Node.js for clasp (Apps Script deploy) -------
# Required only by the webhook deploy step (build step 0). Skipped
# silently if you don't use clasp.
if ! command -v node >/dev/null 2>&1; then
    echo "[3b] Node.js NOT in WSL — webhook deploy via clasp will be skipped."
    echo "        To enable webhook deploy: sudo apt install -y nodejs npm"
    echo "                                  npm install -g @google/clasp"
    echo "                                  clasp login"
    echo
fi

# ---- Step 4: Create / reuse Linux venv at ~/awing_venv ----------------
# We deliberately put the venv OUTSIDE the OneDrive-synced repo to avoid:
#   (a) OneDrive locking site-packages files mid-write (kills pip)
#   (b) collision with the existing Windows venv at <repo>/venv that has
#       Windows-style Scripts/ layout instead of Linux bin/
#   (c) the OneDrive sync overhead on every site-packages change
VENV="$HOME/awing_venv"
echo "[4/7] Creating / reusing Linux venv at $VENV..."

# Warn if a Windows-style venv exists in the repo — it'll trip people up.
if [ -d "$REPO_ROOT/venv" ] && [ ! -f "$REPO_ROOT/venv/bin/activate" ]; then
    echo "        Note: $REPO_ROOT/venv looks like a Windows venv (has Scripts/, not bin/)."
    echo "              Leaving it alone — used by the Windows .bat workflow."
fi

if [ ! -d "$VENV" ] || [ ! -f "$VENV/bin/activate" ]; then
    rm -rf "$VENV"
    python3 -m venv "$VENV"
    echo "        Created $VENV"
else
    echo "        venv already exists at $VENV — reusing"
fi
# shellcheck disable=SC1091
source "$VENV/bin/activate"
python3 -m pip install --upgrade pip setuptools wheel
echo "        Python: $(which python3)"
echo "        Pip:    $(which pip)"
echo

# ---- Step 5: PyTorch with CUDA (for image generation) ----------------
# The image generator (SDXL Turbo) needs torch + diffusers on GPU. We
# install cu128 wheels for Blackwell sm_120 (RTX 50-series) — those
# wheels also work on older Ampere/Hopper. If the user's GPU is older
# this still works, just slightly slower than cu124.
echo "[5/7] Installing PyTorch (cu128 — works on Blackwell + older)..."
python3 -m pip install --index-url https://download.pytorch.org/whl/cu128 \
    torch torchvision torchaudio || \
    echo "        WARNING: PyTorch install failed — images won't generate. Other steps still work."

python3 -c "
import torch
print(f'        torch {torch.__version__} — CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'        GPU: {torch.cuda.get_device_name(0)}')
" || true
echo

# ---- Step 6: Audio + image generation deps ---------------------------
echo "[6/7] Installing Python deps (Edge TTS, diffusers, Pillow, etc.)..."
python3 -m pip install \
    edge-tts \
    Pillow \
    pydub \
    soundfile \
    diffusers \
    transformers \
    accelerate \
    huggingface_hub
echo

# ---- Step 7: requirements.txt (if present) ---------------------------
if [ -f "scripts/requirements.txt" ]; then
    echo "[7/7] Installing scripts/requirements.txt..."
    python3 -m pip install -r scripts/requirements.txt
else
    echo "[7/7] No scripts/requirements.txt found — skipping (non-fatal)."
fi
echo

# ---- Final summary --------------------------------------------------
echo "============================================"
echo "  Setup complete."
echo "============================================"
echo "  Activate the venv before working:"
echo "    source $VENV/bin/activate"
echo
echo "  Then build:"
echo "    bash scripts/build_and_run.sh"
echo
echo "  Notes:"
echo "    - venv lives at $VENV (NOT inside the repo / OneDrive)"
echo "    - build_and_run.sh calls flutter.bat (Windows Flutter via interop)"
echo "============================================"
