#!/bin/bash
# raspdacmini-builds scripts/build-compositor.sh
# Build script for RaspDacMini LCD compositor (runs inside Docker container)

set -e

echo "[+] Starting RaspDacMini compositor build"
echo "[+] Architecture: $ARCH"
echo "[+] Target uname -m: $UNAME_ARCH"
echo "[+] Node version: $(node --version)"
echo "[+] npm version: $(npm --version)"
echo ""

# Directories
BUILD_BASE="/build"
SOURCE_DIR="$BUILD_BASE/RaspDacMini"
COMPOSITOR_DIR="$SOURCE_DIR/compositor"
NATIVE_DIR="$SOURCE_DIR/native/rgb565"
OUTPUT_DIR="$BUILD_BASE/output"

mkdir -p "$OUTPUT_DIR"

#
# Step 1: Clone RaspDacMini from GitHub
#
echo "[+] Cloning RaspDacMini from GitHub..."
cd "$BUILD_BASE"

if [ ! -d "RaspDacMini" ]; then
  git clone --depth 1 https://github.com/foonerd/RaspDacMini.git
fi

#
# Step 2: Install compositor dependencies
#
echo ""
echo "[+] Installing compositor dependencies..."
cd "$COMPOSITOR_DIR"

# Clean any existing builds
rm -rf node_modules package-lock.json

# Install production dependencies only
npm install --omit=dev

if [ $? -ne 0 ]; then
  echo "[!] ERROR: npm install failed"
  exit 1
fi

echo "[+] Compositor dependencies installed"

#
# Step 3: Build native rgb565 module
#
echo ""
echo "[+] Building native rgb565 module..."
cd "$NATIVE_DIR"

# Clean any existing builds
rm -rf node_modules build

# Install native module dependencies and build
npm install

if [ $? -ne 0 ]; then
  echo "[!] ERROR: Native module build failed"
  exit 1
fi

# Find the built module
RGB565_NODE=$(find . -name 'rgb565.node' -type f | head -1)
if [ -z "$RGB565_NODE" ]; then
  echo "[!] ERROR: rgb565.node not found after build"
  exit 1
fi

echo "[+] Native module built: $RGB565_NODE"

# Copy to compositor utils directory
mkdir -p "$COMPOSITOR_DIR/utils"
cp "$RGB565_NODE" "$COMPOSITOR_DIR/utils/rgb565.node"

#
# Step 4: Create prebuilt archive
#
echo ""
echo "[+] Creating prebuilt archive..."
cd "$COMPOSITOR_DIR"

# Archive naming: compositor-{uname_arch}-node{major}.tar.gz
NODE_MAJOR=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
ARCHIVE_NAME="compositor-${UNAME_ARCH}-node${NODE_MAJOR}.tar.gz"

# Create archive with required files
tar -czf "$OUTPUT_DIR/$ARCHIVE_NAME" \
    node_modules/ \
    package-lock.json \
    utils/rgb565.node

if [ $? -ne 0 ]; then
  echo "[!] ERROR: Failed to create archive"
  exit 1
fi

#
# Step 5: Verify and report
#
echo ""
echo "[+] Build complete"
echo "[+] Output files:"
ls -lh "$OUTPUT_DIR"

echo ""
echo "[+] Archive contents:"
tar -tzf "$OUTPUT_DIR/$ARCHIVE_NAME" | head -20
echo "  ... (truncated)"

echo ""
echo "[+] Verifying native module..."
file "$COMPOSITOR_DIR/utils/rgb565.node"

echo ""
echo "[+] Checking node_modules size:"
du -sh "$COMPOSITOR_DIR/node_modules"

echo ""
echo "[+] Archive ready: $ARCHIVE_NAME"
