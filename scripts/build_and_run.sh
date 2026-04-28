#!/usr/bin/env bash
# build_and_run.sh — WSL bash equivalent of build_and_run.bat v16.0.0
#
# Fail-fast: every critical step aborts the build if it fails. Shipping
# a half-built APK with stale Dart data, missing audio, missing images,
# or an unverified webhook is worse than not shipping — so each step
# either completes or we stop cold with an error message that names
# the fix.
#
# Steps:
#   0. Deploy Apps Script webhooks via clasp (skipped if clasp absent)
#   1. Apply approved contributions (modify Dart data files)
#   2. Generate Edge TTS 6 character voices
#   3. Regenerate pronunciation-fixed words
#   4. Apply native recordings (Dr. Sama's WAVs -> audio/native/)
#   5. Generate vocabulary images (SDXL Turbo)
#   6. flutter pub get
#   7. flutter build appbundle + apk
#   8. Install on device (best-effort)
#
# Notes:
#  - Run from the repo root inside WSL: bash scripts/build_and_run.sh
#  - We invoke `flutter` directly. WSL2 interop routes that to your
#    Windows Flutter install, so no Linux SDK reinstalls.
#  - The script will fail loudly (exit 1) on any required step. Step 8
#    (install on device) is best-effort — a disconnected device is a
#    normal dev state, not a build failure.

set -euo pipefail

# Resolve repo root from the script's location (independent of cwd).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

PAD_ASSETS="android/install_time_assets/src/main/assets"
PAD_AUDIO="$PAD_ASSETS/audio"
PAD_IMAGES="$PAD_ASSETS/images/vocabulary"

# Pick a venv that has edge-tts, diffusers, etc. We check a few likely
# locations; if none is set up, the user is told to run install_dependencies.sh.
# The new install_dependencies.sh creates ~/awing_venv (outside OneDrive)
# to avoid sync-related write locks. We prefer that over the legacy
# in-repo venv (which is Windows-style and won't have bin/activate).
choose_venv() {
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        echo "$VIRTUAL_ENV"
        return 0
    fi
    for cand in "$HOME/awing_venv" "$HOME/venv_qwen3" "$REPO_ROOT/venv"; do
        if [ -x "$cand/bin/python3" ]; then
            echo "$cand"
            return 0
        fi
    done
    return 1
}

ensure_venv_active() {
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        local v
        v="$(choose_venv)" || {
            echo "ERROR: No Python venv found. Run scripts/install_dependencies.sh first."
            exit 1
        }
        echo "Activating venv at $v"
        # shellcheck disable=SC1090,SC1091
        source "$v/bin/activate"
    fi
    echo "  Python: $(which python3)"
    echo "  Pip:    $(which pip)"
}

# We call Windows Flutter via cmd.exe rather than executing the unix
# `flutter` wrapper or `flutter.bat` directly, because:
#   - The unix `flutter` script has CRLF line endings on OneDrive
#     volumes (bash refuses).
#   - WSL2 interop routes .exe files automatically but NOT .bat files —
#     bash tries to interpret .bat as a shell script (sees @ECHO etc).
# cmd.exe /c works for both cases: cmd has Windows PATH, finds
# flutter.bat, runs it cleanly, and pipes output back to bash.
flutter_cmd() {
    cmd.exe /c "flutter $*"
}

ensure_flutter_available() {
    # cmd.exe is always present on WSL when interop is enabled.
    if ! command -v cmd.exe >/dev/null 2>&1; then
        echo "ERROR: cmd.exe not available (WSL interop disabled?)."
        echo "  Check /etc/wsl.conf has [interop] enabled = true."
        exit 1
    fi
    # Verify Windows-side flutter answers via cmd.exe.
    if ! cmd.exe /c "flutter --version" >/dev/null 2>&1; then
        echo "ERROR: Windows-side 'flutter' not on cmd.exe's PATH."
        echo "  Open a Windows terminal and run 'flutter --version' to confirm."
        echo "  If that fails, fix Flutter's installation on Windows side first."
        echo "  If it works on Windows but not here, your shell may be inheriting"
        echo "  a stale environment — open a fresh WSL terminal and retry."
        exit 1
    fi
    echo "  Flutter: $(cmd.exe /c "where flutter" 2>/dev/null | head -1 | tr -d '\r')"
}

clean_tts_audio() {
    # Match the .bat's per-voice/per-category cleanup.
    for v in boy girl young_man young_woman man woman; do
        for c in alphabet vocabulary sentences stories; do
            local d="$PAD_AUDIO/$v/$c"
            if [ -d "$d" ]; then
                find "$d" -maxdepth 1 -name "*.mp3" -type f -delete 2>/dev/null || true
            fi
        done
    done
}

print_header() {
    echo "============================================"
    echo "  Awing AI Learning - Build and Run (WSL)"
    echo "============================================"
}

# ---- Setup ------------------------------------------------------------

print_header
ensure_venv_active
ensure_flutter_available
mkdir -p "$PAD_AUDIO" "$PAD_IMAGES" contributions contributions/applied
echo

# ---- Step 0: Deploy Apps Script Webhooks -----------------------------
# clasp is a Node global. We require BOTH `clasp` and `node` on the
# WSL PATH — finding clasp via Windows-side npm but no Node in WSL just
# fails with `node: not found` partway through. Skip cleanly if either
# is missing (offline builds).
echo "[0/8] Deploying and verifying Apps Script webhooks..."
if ! command -v clasp >/dev/null 2>&1 || ! command -v node >/dev/null 2>&1; then
    echo "        clasp/node not both available in WSL — skipping webhook deploy."
    echo "        To enable: sudo apt install -y nodejs npm"
    echo "                   npm install -g @google/clasp && clasp login"
elif [ ! -f "scripts/setup_and_deploy.py" ]; then
    echo "        scripts/setup_and_deploy.py not found - skipping."
else
    if ! python3 scripts/setup_and_deploy.py --webhooks; then
        echo
        echo "        ERROR: Webhook deploy failed. Build aborted."
        echo "        Run 'python3 scripts/setup_and_deploy.py --webhooks' manually."
        exit 1
    fi
    if ! python3 scripts/setup_and_deploy.py --verify; then
        echo
        echo "        ERROR: Webhook verify failed. Build aborted."
        echo "        The deployed contributions URL is missing fetch_all support."
        exit 1
    fi
    echo "        Webhooks deployed and verified."
fi
echo

# ---- Step 1: Apply Approved Contributions ----------------------------
echo "[1/8] Applying approved contributions..."
if ! python3 scripts/apply_contributions.py; then
    echo
    echo "        ERROR: Contribution application failed. Build aborted."
    echo "        Run 'python3 scripts/apply_contributions.py' to see the full error."
    exit 1
fi
echo "        Contributions applied successfully."
echo

# ---- Step 2: Edge TTS character voices --------------------------------
echo "[2/8] Generating Edge TTS character voice clips..."
echo "        6 voices: boy/girl + young_man/young_woman + man/woman"
echo "        Output: $PAD_AUDIO"
clean_tts_audio
pip install --quiet edge-tts >/dev/null 2>&1 || true
if ! python3 scripts/generate_audio_edge.py --output-dir "$PAD_AUDIO" generate; then
    echo
    echo "        ERROR: Edge TTS generation failed. Build aborted."
    echo "        Common causes: edge-tts not installed, no internet (Microsoft API),"
    echo "        ffmpeg missing."
    exit 1
fi
echo "        Edge TTS clips generated."
echo

# ---- Step 3: Regenerate pronunciation-fixed words --------------------
echo "[3/8] Checking for pronunciation fixes to regenerate..."
REGEN_FILE=""
for cand in contributions/regenerate_words_v2.json contributions/regenerate_words.json; do
    if [ -f "$cand" ]; then
        REGEN_FILE="$cand"
        break
    fi
done
if [ -n "$REGEN_FILE" ]; then
    echo "        Found $REGEN_FILE — regenerating with corrected pronunciations..."
    if ! python3 scripts/generate_audio_edge.py --output-dir "$PAD_AUDIO" \
            regenerate --regenerate-file "$REGEN_FILE"; then
        echo
        echo "        ERROR: Pronunciation regeneration failed. Build aborted."
        exit 1
    fi
    echo "        Pronunciation fixes regenerated."
else
    echo "        No pronunciation fixes to regenerate. Skipping."
fi
echo

# ---- Step 4: Apply native recordings ---------------------------------
# Dr. Sama's 197 recordings get placed at audio/native/ as the highest-
# priority audio source — see lib/services/pronunciation_service.dart.
# This step is non-fatal if the manifest is missing (fresh checkout).
echo "[4/8] Applying native recordings to audio/native/..."
if [ -f "training_data/recordings/manifest.json" ]; then
    if ! python3 scripts/apply_recordings_as_audio.py; then
        echo "        WARNING: native recordings apply failed (continuing — non-fatal)"
    else
        echo "        Native recordings applied."
    fi
else
    echo "        No recordings manifest found — skipping (non-fatal)."
fi
echo

# ---- Step 5: Vocabulary images ---------------------------------------
echo "[5/8] Generating vocabulary images (SDXL Turbo)..."
echo "        Output: $PAD_IMAGES"
if ! python3 scripts/generate_images.py --output-dir "$PAD_IMAGES" generate; then
    echo
    echo "        ERROR: Image generation failed. Build aborted."
    echo "        Common causes: diffusers/transformers/accelerate not installed,"
    echo "        no NVIDIA GPU, or SDXL Turbo not yet downloaded (~5 GB)."
    exit 1
fi
echo "        Vocabulary images generated."
echo

# ---- Step 6: flutter pub get -----------------------------------------
echo "[6/8] Installing Flutter dependencies..."
if ! flutter_cmd pub get; then
    echo
    echo "        ERROR: flutter pub get failed."
    echo "        Check pubspec.yaml and 'flutter doctor'."
    exit 1
fi
echo "        Flutter dependencies resolved."
echo

# ---- Step 7: flutter build appbundle + apk ---------------------------
echo "[7/8] Building Android App Bundle (release)..."
if ! flutter_cmd build appbundle --release; then
    echo "        WARNING: AAB build failed. Trying APK only..."
    if ! flutter_cmd build apk --release; then
        echo
        echo "        ERROR: Android build failed (both AAB and APK)."
        exit 1
    fi
fi
echo "        Also building APK for local testing..."
if ! flutter_cmd build apk --release; then
    echo
    echo "        ERROR: APK build failed (AAB built, but local-testing APK missing)."
    exit 1
fi
echo "        AAB + APK built successfully."
echo

# ---- Step 8: Install on device ---------------------------------------
echo "[8/8] Installing on connected device..."
if [ -f "scripts/setup_and_deploy.py" ]; then
    python3 scripts/setup_and_deploy.py --install || \
        echo "        (install best-effort; device may be disconnected)"
else
    flutter_cmd run || echo "        (flutter run best-effort; device may be disconnected)"
fi

echo
echo "============================================"
echo "  Build and run completed."
echo "============================================"
