#!/usr/bin/env bash
# ==========================================================
#  Qwen3-TTS Awing fine-tune — orchestrate all 6 voices
# ==========================================================
#  Runs train_voice.sh sequentially for boy, girl, young_man,
#  young_woman, man, woman. Each voice produces its own
#  Awing-fluent fine-tuned model under models/qwen3_awing_<voice>/.
#
#  Resume-safe: if a voice's training_complete marker exists,
#  it's skipped (so re-running after a crash continues from the
#  next voice).
#
#  Run from the Awing repo root inside WSL with venv_qwen3 active:
#      source ~/venv_qwen3/bin/activate
#      bash scripts/ml/tts/train_all_voices.sh
#
#  Run a subset:
#      bash scripts/ml/tts/train_all_voices.sh boy girl
#
#  Forward training args (e.g. fewer epochs for testing):
#      bash scripts/ml/tts/train_all_voices.sh -- --num_epochs 3
#
#  All-voice estimated time on RTX 5070: many hours. Run overnight.
# ==========================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
DEFAULT_VOICES=("boy" "girl" "young_man" "young_woman" "man" "woman")

# Parse: voices come before --, sft args come after.
VOICES=()
SFT_ARGS=()
PAST_DASHDASH=0
for arg in "$@"; do
    if [ "$arg" = "--" ]; then
        PAST_DASHDASH=1
        continue
    fi
    if [ "$PAST_DASHDASH" = "1" ]; then
        SFT_ARGS+=("$arg")
    else
        VOICES+=("$arg")
    fi
done

if [ ${#VOICES[@]} -eq 0 ]; then
    VOICES=("${DEFAULT_VOICES[@]}")
fi

echo "=========================================="
echo "Qwen3-TTS Awing fine-tune — all voices"
echo "Voices to train: ${VOICES[*]}"
if [ ${#SFT_ARGS[@]} -gt 0 ]; then
    echo "Extra sft_12hz args: ${SFT_ARGS[*]}"
fi
echo "=========================================="
echo ""

# Build the JSONL inputs for every voice up front so we fail fast if
# the corpus is missing, rather than after voice 1's training already
# spent 3 hours.
echo "[prep] Building raw JSONLs for all voices..."
python3 "$REPO_ROOT/scripts/ml/tts/prep_finetune_data.py" \
    --voices "${VOICES[@]}"
echo ""

# Train each voice sequentially.
for v in "${VOICES[@]}"; do
    OUT="$REPO_ROOT/models/qwen3_awing_$v"
    DONE_MARKER="$OUT/training_complete.txt"
    if [ -f "$DONE_MARKER" ]; then
        echo "[$v] Already complete (marker $DONE_MARKER). Skipping."
        continue
    fi

    echo ""
    echo "##########################################"
    echo "# [$v] Starting fine-tune"
    echo "# $(date)"
    echo "##########################################"

    if ! bash "$REPO_ROOT/scripts/ml/tts/train_voice.sh" "$v" "${SFT_ARGS[@]}"; then
        echo ""
        echo "[$v] FAILED — aborting orchestrator."
        echo "  Re-run this script after fixing the issue; finished voices skip."
        exit 1
    fi

    # Mark complete so resume-safe re-runs skip this voice.
    date > "$DONE_MARKER"
    echo "[$v] Marked complete at $DONE_MARKER"
done

echo ""
echo "=========================================="
echo "All voices complete."
echo "Models under: $REPO_ROOT/models/qwen3_awing_<voice>/"
for v in "${VOICES[@]}"; do
    OUT="$REPO_ROOT/models/qwen3_awing_$v"
    if [ -d "$OUT" ]; then
        SIZE=$(du -sh "$OUT" 2>/dev/null | cut -f1)
        echo "  $v: $OUT ($SIZE)"
    fi
done
echo "=========================================="
