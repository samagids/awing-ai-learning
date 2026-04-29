#!/usr/bin/env bash
# pack_and_upload_assets.sh
# ----------------------------------------------------------------------------
# Packs the locally-generated PAD asset tree (audio + vocabulary images +
# native recordings — currently ~945 MB) into a single tarball and uploads it
# to a GitHub Release named "pad-assets".
#
# CI workflows (build-android.yml + build-ios.yml) download this tarball
# before `flutter build` so testers receive the full content app, not the
# placeholder/empty-asset build the CI runners would otherwise produce
# (PAD assets are gitignored, so a fresh `git checkout` doesn't include them).
#
# Re-run this script whenever the asset tree changes (new vocabulary, new
# native recordings, regenerated images). Each upload OVERWRITES the existing
# release asset, so the URL stays stable and CI doesn't need any version bumps.
#
# Requirements:
#   - gh CLI logged in    (winget install GitHub.cli; gh auth login)
#   - tar + gzip          (built into WSL/Linux/macOS; on Windows use WSL)
#   - The 945 MB of assets present at android/install_time_assets/src/main/assets/
#
# Usage:
#   bash scripts/pack_and_upload_assets.sh             # pack + upload
#   bash scripts/pack_and_upload_assets.sh --dry-run   # pack only, skip upload
# ----------------------------------------------------------------------------
set -euo pipefail

# Repo root = parent of this script's dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# === Inputs ===
ASSET_DIR="android/install_time_assets/src/main/assets"
TARBALL="pad-assets.tar.gz"
RELEASE_TAG="pad-assets"
RELEASE_NAME="PAD asset bundle (audio + images)"

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

# === Sanity checks ===
if [ ! -d "$ASSET_DIR" ]; then
  echo "ERROR: $ASSET_DIR not found." >&2
  echo "Run scripts/build_and_run.sh (or .bat) once locally to generate audio + images" >&2
  echo "before packing." >&2
  exit 1
fi

ASSET_BYTES=$(du -sb "$ASSET_DIR" | awk '{print $1}')
ASSET_HUMAN=$(du -sh "$ASSET_DIR" | awk '{print $1}')
if [ "$ASSET_BYTES" -lt 100000000 ]; then
  echo "ERROR: $ASSET_DIR is only $ASSET_HUMAN — that's way smaller than expected" >&2
  echo "(should be ~900 MB+). Did the audio/image generation finish?" >&2
  exit 1
fi

if [ "$DRY_RUN" -eq 0 ]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: gh CLI not found. Install:" >&2
    echo "  winget install GitHub.cli   # Windows" >&2
    echo "  brew install gh             # macOS" >&2
    echo "  apt install gh              # Debian/Ubuntu/WSL" >&2
    echo "Then: gh auth login" >&2
    exit 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "ERROR: gh CLI not authenticated. Run: gh auth login" >&2
    exit 1
  fi
fi

# === Pack ===
echo "[1/3] Packing $ASSET_DIR ($ASSET_HUMAN) into $TARBALL ..."
echo "      This takes ~2-5 minutes for ~1 GB of files."

# tar -C avoids absolute paths inside the archive; the contents extract
# directly as audio/, images/ at whatever target the CI specifies.
tar -czf "$TARBALL" -C "$ASSET_DIR" .

TARBALL_BYTES=$(stat -c '%s' "$TARBALL" 2>/dev/null || stat -f '%z' "$TARBALL")
TARBALL_HUMAN=$(du -h "$TARBALL" | awk '{print $1}')
echo "      Created $TARBALL ($TARBALL_HUMAN, $TARBALL_BYTES bytes)"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[2/3] --dry-run set — skipping upload."
  echo
  echo "Tarball ready at $REPO_ROOT/$TARBALL"
  echo "To upload manually: gh release upload $RELEASE_TAG $TARBALL --clobber"
  exit 0
fi

# === Ensure release exists ===
echo "[2/3] Ensuring release '$RELEASE_TAG' exists ..."
if ! gh release view "$RELEASE_TAG" >/dev/null 2>&1; then
  echo "      Release doesn't exist yet — creating it."
  gh release create "$RELEASE_TAG" \
    --title "$RELEASE_NAME" \
    --notes "Audio (Edge TTS 6 voices + native recordings) + vocabulary images. Re-uploaded by scripts/pack_and_upload_assets.sh whenever the asset tree changes. CI workflows download from here." \
    --latest=false
fi

# === Upload (replace if exists) ===
echo "[3/3] Uploading $TARBALL to release '$RELEASE_TAG' ..."
echo "      This can take 10-30 minutes on a residential upload depending on size + connection."
gh release upload "$RELEASE_TAG" "$TARBALL" --clobber

echo
echo "=========================================================================="
echo "✓ DONE. Asset bundle uploaded."
echo "=========================================================================="
echo
echo "Asset URL (used by CI):"
REPO_FULL=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "  https://github.com/$REPO_FULL/releases/download/$RELEASE_TAG/$TARBALL"
echo
echo "Re-run this script whenever you regenerate audio or images."
echo "Tarball size: $TARBALL_HUMAN"
