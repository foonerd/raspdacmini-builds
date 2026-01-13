#!/bin/bash
# raspdacmini-builds docker/run-docker-compositor.sh
# Core Docker build logic for RaspDacMini LCD compositor

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cd "$REPO_DIR"

VERBOSE=0

# Parse arguments
ARCH="$1"
shift || true

for arg in "$@"; do
  if [[ "$arg" == "--verbose" ]]; then
    VERBOSE=1
  fi
done

# Show usage if missing required parameters
if [ -z "$ARCH" ]; then
  echo "Usage: $0 <arch> [--verbose]"
  echo ""
  echo "Arguments:"
  echo "  arch: armhf, arm64"
  echo "  --verbose: Show detailed build output"
  echo ""
  echo "Example:"
  echo "  $0 arm64"
  echo "  $0 armhf --verbose"
  exit 1
fi

# Platform mappings for Docker
declare -A PLATFORM_MAP
PLATFORM_MAP=(
  ["armhf"]="linux/arm/v7"
  ["arm64"]="linux/arm64"
)

# uname -m output mapping (for archive naming)
declare -A UNAME_MAP
UNAME_MAP=(
  ["armhf"]="armv7l"
  ["arm64"]="aarch64"
)

# Validate architecture
if [[ -z "${PLATFORM_MAP[$ARCH]}" ]]; then
  echo "Error: Unknown architecture: $ARCH"
  echo "Supported: armhf, arm64"
  exit 1
fi

PLATFORM="${PLATFORM_MAP[$ARCH]}"
UNAME_ARCH="${UNAME_MAP[$ARCH]}"
DOCKERFILE="docker/Dockerfile.compositor.$ARCH"
IMAGE_NAME="raspdacmini-compositor-builder:$ARCH"
OUTPUT_DIR="out/$ARCH"

if [ ! -f "$DOCKERFILE" ]; then
  echo "Error: Dockerfile not found: $DOCKERFILE"
  exit 1
fi

echo "========================================"
echo "Building RaspDacMini compositor for $ARCH"
echo "========================================"
echo "  Platform: $PLATFORM"
echo "  Target arch (uname -m): $UNAME_ARCH"
echo "  Dockerfile: $DOCKERFILE"
echo "  Image: $IMAGE_NAME"
echo "  Output: $OUTPUT_DIR"
echo ""

# Build Docker image with platform flag
echo "[+] Building Docker image..."
if [[ "$VERBOSE" -eq 1 ]]; then
  DOCKER_BUILDKIT=1 docker build --platform=$PLATFORM --progress=plain -t "$IMAGE_NAME" -f "$DOCKERFILE" .
else
  docker build --platform=$PLATFORM --progress=auto -t "$IMAGE_NAME" -f "$DOCKERFILE" . 2>&1 | grep -E "^\[|^#|^Step|error|Error" || true
fi
echo "[+] Docker image built: $IMAGE_NAME"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run build inside container
echo "[+] Running build inside container..."
if [[ "$VERBOSE" -eq 1 ]]; then
  docker run --rm --platform=$PLATFORM \
    -v "$(pwd)/scripts:/build/scripts:ro" \
    -v "$(pwd)/$OUTPUT_DIR:/build/output" \
    -e "ARCH=$ARCH" \
    -e "UNAME_ARCH=$UNAME_ARCH" \
    "$IMAGE_NAME" \
    bash /build/scripts/build-compositor.sh
else
  docker run --rm --platform=$PLATFORM \
    -v "$(pwd)/scripts:/build/scripts:ro" \
    -v "$(pwd)/$OUTPUT_DIR:/build/output" \
    -e "ARCH=$ARCH" \
    -e "UNAME_ARCH=$UNAME_ARCH" \
    "$IMAGE_NAME" \
    bash /build/scripts/build-compositor.sh 2>&1 | grep -E "^\[|^Error|^npm|warning:|error:" || true
fi

echo ""
echo "[+] Build complete for $ARCH"
echo "[+] Output in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
