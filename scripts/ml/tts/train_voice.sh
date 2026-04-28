#!/usr/bin/env bash
# ==========================================================
#  Qwen3-TTS Awing fine-tune — single voice
# ==========================================================
#  Encodes the per-voice raw_train.jsonl to discrete audio codes,
#  then runs the official sft_12hz.py to fine-tune the 1.7B-Base
#  checkpoint into an Awing-fluent model in that voice.
#
#  Run from the Awing repo root inside WSL with venv_qwen3 active:
#      source ~/venv_qwen3/bin/activate
#      bash scripts/ml/tts/train_voice.sh <voice> [extra_sft_args...]
#
#  Examples:
#      bash scripts/ml/tts/train_voice.sh boy
#      bash scripts/ml/tts/train_voice.sh boy --batch_size 4 --num_epochs 5
#
#  Prereqs (all run from setup_finetune_wsl.sh + prep_finetune_data.py):
#    - ~/venv_qwen3 with qwen-tts + accelerate installed
#    - ~/Qwen3-TTS clone with finetuning/ subdir
#    - 1.7B-Base checkpoint cached
#    - corpus/finetune/<voice>/raw_train.jsonl exists
#
#  Outputs:
#    corpus/finetune/<voice>/train_with_codes.jsonl — encoded data
#    models/qwen3_awing_<voice>/                    — checkpoints
#    models/qwen3_awing_<voice>/train_log.txt       — training log
# ==========================================================

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <voice> [sft_extra_args...]"
    echo "  voice: boy | girl | young_man | young_woman | man | woman"
    exit 1
fi

VOICE="$1"
shift  # remaining args are forwarded to sft_12hz.py

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
QWEN_REPO="$HOME/Qwen3-TTS"
VENV="$HOME/venv_qwen3"

# --- Sanity checks ---------------------------------------

if [ -z "${VIRTUAL_ENV:-}" ] || [ "$VIRTUAL_ENV" != "$VENV" ]; then
    echo "ERROR: venv_qwen3 not active. Run: source $VENV/bin/activate"
    exit 1
fi

PREP="$QWEN_REPO/finetuning/prepare_data.py"
# LoRA fine-tune script (local). Upstream sft_12hz.py is full-FT and
# OOMs on 12 GB. sft_lora.py freezes the base + LoRAs the talker
# decoder layers, fits in ~5-6 GB peak.
SFT="$REPO_ROOT/scripts/ml/tts/sft_lora.py"
if [ ! -f "$PREP" ]; then
    echo "ERROR: $PREP missing. Run setup_finetune_wsl.sh."
    exit 1
fi
if [ ! -f "$SFT" ]; then
    echo "ERROR: $SFT missing."
    exit 1
fi

VOICE_DIR="$REPO_ROOT/corpus/finetune/$VOICE"
RAW_JSONL="$VOICE_DIR/raw_train.jsonl"
ENCODED_JSONL="$VOICE_DIR/train_with_codes.jsonl"

if [ ! -f "$RAW_JSONL" ]; then
    echo "ERROR: $RAW_JSONL missing."
    echo "  Run: python3 scripts/ml/tts/prep_finetune_data.py"
    exit 1
fi

# Write outputs to WSL's native ext4 home, NOT to the OneDrive-synced
# repo path. OneDrive's sync engine intermittently locks files mid-write
# during multi-hour training runs, which kills training and can corrupt
# checkpoints. Native Linux home has no such issue and is faster.
# View checkpoints from Windows via \\wsl.localhost\Ubuntu\home\samag\awing_models\
OUT_DIR="$HOME/awing_models/qwen3_awing_$VOICE"
mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/train_log.txt"
echo "[$VOICE] Output dir (non-OneDrive): $OUT_DIR"

# --- Step 1: Encode --------------------------------------
# prepare_data.py adds an 'audio_codes' field. Idempotent — if the
# encoded file is newer than the raw JSONL, skip the encode step.

if [ -f "$ENCODED_JSONL" ] && [ "$ENCODED_JSONL" -nt "$RAW_JSONL" ]; then
    echo "[$VOICE] Encoded JSONL up to date, skipping encode step."
    echo "  $ENCODED_JSONL"
else
    echo "[$VOICE] Encoding audio to discrete codes..."
    echo "  Input:  $RAW_JSONL"
    echo "  Output: $ENCODED_JSONL"
    echo "  (this can take ~5-15 min for 7k clips on RTX 5070)"
    python3 "$PREP" \
        --input_jsonl "$RAW_JSONL" \
        --output_jsonl "$ENCODED_JSONL" \
        --device cuda:0 \
        --tokenizer_model_path Qwen/Qwen3-TTS-Tokenizer-12Hz \
        2>&1 | tee -a "$LOG"
fi

ENCODED_LINES="$(wc -l < "$ENCODED_JSONL" | tr -d ' ')"
echo "[$VOICE] Encoded JSONL has $ENCODED_LINES rows."

# --- Step 2: Fine-tune (LoRA) ----------------------------
# Defaults are calibrated for 12 GB VRAM (RTX 5070) running our
# scripts/ml/tts/sft_lora.py:
#   model       Qwen/Qwen3-TTS-12Hz-0.6B-Base (frozen base + LoRA)
#   batch_size  1, grad_accum 4 (effective batch 4)
#   lr          1e-4   (LoRA convention; full-FT used 2e-6)
#   num_epochs  10
#   lora_r 16, lora_alpha 32
# Override by passing --batch_size, --lr, --lora_r, --num_epochs, etc.
# Expected peak VRAM: ~5-6 GB on a 12 GB card.

echo ""
echo "[$VOICE] Starting LoRA fine-tune of Qwen3-TTS-12Hz-1.7B-Base"
echo "  Output: $OUT_DIR"
echo "  Log:    $LOG"
echo ""

# PYTORCH_CUDA_ALLOC_CONF helps with VRAM fragmentation — same trick
# Sessions 15-16 found indispensable on Blackwell.
export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

python3 "$SFT" \
    --init_model_path Qwen/Qwen3-TTS-12Hz-0.6B-Base \
    --output_model_path "$OUT_DIR" \
    --train_jsonl "$ENCODED_JSONL" \
    --batch_size 1 \
    --grad_accum 4 \
    --lr 1e-4 \
    --num_epochs 10 \
    --lora_r 16 \
    --lora_alpha 32 \
    --speaker_name "awing_$VOICE" \
    "$@" \
    2>&1 | tee -a "$LOG"

EXIT_CODE=${PIPESTATUS[0]}

if [ "$EXIT_CODE" -ne 0 ]; then
    echo ""
    echo "[$VOICE] Training EXITED with code $EXIT_CODE"
    echo "  Log: $LOG"
    exit "$EXIT_CODE"
fi

echo ""
echo "=========================================="
echo "[$VOICE] DONE"
echo "  Checkpoints: $OUT_DIR"
echo "  Log:         $LOG"
echo "=========================================="
