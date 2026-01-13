#!/bin/bash
# raspdacmini-builds build-matrix.sh
# Build RaspDacMini compositor for all supported architectures

set -e

VERBOSE=""

# Parse arguments
for arg in "$@"; do
  if [[ "$arg" == "--verbose" ]]; then
    VERBOSE="--verbose"
  fi
done

echo "========================================"
echo "RaspDacMini Compositor Build Matrix"
echo "========================================"
echo ""

# Build for supported architectures (Pi 4+ only)
ARCHITECTURES=("armhf" "arm64")

for ARCH in "${ARCHITECTURES[@]}"; do
  echo ""
  echo "----------------------------------------"
  echo "Building for: $ARCH"
  echo "----------------------------------------"
  ./docker/run-docker-compositor.sh "$ARCH" $VERBOSE
done

echo ""
echo "========================================"
echo "Build Matrix Complete"
echo "========================================"
echo ""
echo "Output structure:"
for ARCH in "${ARCHITECTURES[@]}"; do
  if [ -d "out/$ARCH" ]; then
    echo "  out/$ARCH/"
    ls -lh "out/$ARCH/" 2>/dev/null | tail -n +2 | awk '{printf "    %s  %s\n", $9, $5}'
  fi
done

echo ""
echo "To use these prebuilts:"
echo "  1. Copy compositor-{arch}-node20.tar.gz to plugin assets/"
echo "  2. Plugin install.sh will auto-detect and use prebuilt"
