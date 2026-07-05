#!/usr/bin/env bash
# build.sh — Build AcreetionOS Immutable ISO
# Usage: ./build.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/../ISO}"

cd "$SCRIPT_DIR"

echo "  :: AcreetionOS Immutable — Building ISO"
echo "  :: Output: ${OUTPUT_DIR}"

# Generate build metadata
if [ -f ./generate-build-info.sh ]; then
  ./generate-build-info.sh
fi

# Clean previous build
echo "  :: Cleaning workspace..."
./refresh.sh -j 2>/dev/null || true

# Build
echo "  :: Running mkarchiso..."
./mkarchiso.sh

# Find and report ISO
FOUND_ISO=$(find "${OUTPUT_DIR}" -name "AcreetionOS-Immutable*.iso" -type f 2>/dev/null | head -1)
if [ -n "$FOUND_ISO" ]; then
  echo "  ✓ ISO: $FOUND_ISO"
  ls -lh "$FOUND_ISO"
  sha256sum "$FOUND_ISO" > "${FOUND_ISO}.sha256"
  md5sum "$FOUND_ISO" > "${FOUND_ISO}.md5"
else
  echo "  ! No ISO found in ${OUTPUT_DIR}/ — checking out/"
  ls -lh out/ 2>/dev/null || true
fi

# Clean up work dir
sudo rm -rf ./work 2>/dev/null || true
echo "  :: Done!"
