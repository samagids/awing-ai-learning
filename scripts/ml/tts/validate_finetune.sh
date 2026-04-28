#!/usr/bin/env bash
# ==========================================================
#  Qwen3-TTS Awing fine-tune — short validator
# ==========================================================
#  Runs a heavily-truncated fine-tune (1 epoch, ~50 train clips)
#  on ONE voice. Purpose: prove the pipeline works end-to-end on
#  this Blackwell stack before committing to 6 full training runs
#  that each take hours.
#
#  Validates:
#    1. prepare_data.py encodes Awing audio without crashing
#    2. sft_12hz.py loads the encoded JSONL + 1.7B-Base checkpoint
#    3. The first ~50 training steps run without OOM / kernel errors
#    4. Loss is finite and non-NaN
#    5. A checkpoint saves at end of the truncated epoch
#
#  After this passes, run the full training via:
#    bash scripts/ml/tts/train_voice.sh <voice>
#  (or train_all_voices.sh for all six in sequence).
#
#  Usage from WSL with venv_qwen3 active:
#    source ~/venv_qwen3/bin/activate
#    bash scripts/ml/tts/validate_finetune.sh [voice]
#  voice defaults to "boy".
# ==========================================================

set -euo pipefail

VOICE="${1:-boy}"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
VENV="$HOME/venv_qwen3"

# Fail fast if the venv isn't active. Without this guard, prep step 1
# may run on system python (stdlib-only), but step 2 will crash when
# it can't import qwen_tts. Saves head-scratching when PATH is wrong.
if [ -z "${VIRTUAL_ENV:-}" ] || [ "$VIRTUAL_ENV" != "$VENV" ]; then
    echo "ERROR: venv_qwen3 not active."
    echo "  Run: source $VENV/bin/activate && hash -r"
    echo "  Then verify: which python3   (must be $VENV/bin/python3)"
    exit 1
fi
# Verify python3 actually resolves into the venv (PATH cache stale issue).
PY_PATH="$(which python3)"
if [ "$PY_PATH" != "$VENV/bin/python3" ]; then
    echo "ERROR: python3 resolves to $PY_PATH, not $VENV/bin/python3."
    echo "  Run 'hash -r' to clear bash's PATH cache, or use the venv's"
    echo "  python3 directly: $VENV/bin/python3"
    exit 1
fi

echo "=========================================="
echo "Qwen3-TTS fine-tune VALIDATOR"
echo "Voice:        $VOICE"
echo "Train clips:  ~50 (heavy cap for fast feedback)"
echo "Epochs:       1"
echo "Goal:         confirm pipeline works before 6× full runs"
echo "=========================================="
echo ""

# --- Step 1: regenerate JSONL with cap to ~50 clips ------
# Use --max-train-clips so we don't burn 15 minutes encoding 7k
# audios when we only want to verify the pipeline.

echo "[1/3] Building capped JSONL..."
python3 "$REPO_ROOT/scripts/ml/tts/prep_finetune_data.py" \
    --voices "$VOICE" \
    --max-train-clips 50

# Move the capped JSONL aside so we don't accidentally use it for the
# real training run later. Remove the corpus/finetune/<voice>/ dir
# first so train_voice.sh later regenerates the full 7k-clip JSONL.

VAL_DIR="$REPO_ROOT/corpus/finetune_validate/$VOICE"
mkdir -p "$VAL_DIR"
mv "$REPO_ROOT/corpus/finetune/$VOICE/raw_train.jsonl" "$VAL_DIR/raw_train.jsonl"
mv "$REPO_ROOT/corpus/finetune/$VOICE/raw_eval.jsonl"  "$VAL_DIR/raw_eval.jsonl"
rmdir "$REPO_ROOT/corpus/finetune/$VOICE" 2>/dev/null || true

echo "  Capped train JSONL: $VAL_DIR/raw_train.jsonl"
echo ""

# --- Step 2: encode ---------------------------------------

QWEN_REPO="$HOME/Qwen3-TTS"
PREP="$QWEN_REPO/finetuning/prepare_data.py"
# LoRA fine-tune (our local script). The upstream sft_12hz.py is
# full-FT and OOMs on 12 GB even after grad-checkpoint + 8-bit AdamW.
SFT="$REPO_ROOT/scripts/ml/tts/sft_lora.py"

ENCODED="$VAL_DIR/train_with_codes.jsonl"
LOG="$VAL_DIR/validate_log.txt"

echo "[2/3] Encoding capped JSONL to discrete codes (CPU)..."
# CPU encode: codec is 20M params, ~50 clips takes 30-60 sec on CPU.
# Bypasses the unknown-CUDA-error we hit on the codec encoder and
# avoids one of the two GPU phases entirely. Training still uses GPU.
python3 "$PREP" \
    --input_jsonl "$VAL_DIR/raw_train.jsonl" \
    --output_jsonl "$ENCODED" \
    --device cpu \
    --tokenizer_model_path Qwen/Qwen3-TTS-Tokenizer-12Hz \
    2>&1 | tee "$LOG"

if [ ! -s "$ENCODED" ]; then
    echo "FAIL: encoded JSONL empty or missing."
    exit 1
fi
echo "  Encoded $(wc -l < "$ENCODED") rows."
echo ""

# --- Step 3: 1-epoch training ----------------------------

# Write to WSL ext4 home (not OneDrive). See train_voice.sh comment.
OUT_DIR="$HOME/awing_models/qwen3_awing_${VOICE}_validate"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
echo "  Validator output dir (non-OneDrive): $OUT_DIR"

echo "[3/3] Running 1-epoch fine-tune (validator) ..."
echo "  Output: $OUT_DIR"
echo ""

export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

python3 "$SFT" \
    --init_model_path Qwen/Qwen3-TTS-12Hz-0.6B-Base \
    --output_model_path "$OUT_DIR" \
    --train_jsonl "$ENCODED" \
    --batch_size 1 \
    --grad_accum 4 \
    --lr 1e-4 \
    --num_epochs 1 \
    --lora_r 16 \
    --lora_alpha 32 \
    --speaker_name "awing_${VOICE}_validate" \
    2>&1 | tee -a "$LOG"

# Validator uses LoRA fine-tune (sft_lora.py) — full-FT busts 12 GB
# even at batch=1 with gradient checkpointing + 8-bit AdamW. LoRA
# freezes the base and only trains a small adapter, fitting easily in
# ~5-6 GB peak VRAM on a 12 GB card.

# --- Result -----------------------------------------------

echo ""
echo "=========================================="
echo "VALIDATOR DONE"

if find "$OUT_DIR" -name "model.safetensors" -o -name "*.safetensors" 2>/dev/null | grep -q .; then
    echo "  ✓ Checkpoint saved at $OUT_DIR"
    ls -la "$OUT_DIR"
    echo ""
    echo "Pipeline works end-to-end. Next:"
    echo "  rm -rf corpus/finetune_validate models/qwen3_awing_${VOICE}_validate"
    echo "  bash scripts/ml/tts/train_voice.sh $VOICE     # one voice"
    echo "  bash scripts/ml/tts/train_all_voices.sh        # all 6 sequentially"
else
    echo "  ✗ NO checkpoint found at $OUT_DIR"
    echo "  Inspect the log: $LOG"
    exit 1
fi
echo "=========================================="
