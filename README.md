# RaspDacMini Compositor Build System

Docker-based build system for RaspDacMini LCD plugin prebuilt compositor packages.

## Purpose

Building the compositor from source requires:
- 15+ minutes on Pi 4 (8GB)
- 30+ minutes on Pi 4 (1-2GB)
- May fail on low-memory systems

Prebuilt packages reduce installation to ~10 seconds.

## Target Architectures

| Architecture | uname -m | Raspberry Pi Models |
|--------------|----------|---------------------|
| armhf | armv7l | Pi 4 (32-bit Volumio) |
| arm64 | aarch64 | Pi 4, Pi 5 (64-bit Volumio) |

Note: This plugin targets Pi 4 and newer only.

## Prerequisites

Docker with multi-platform support:

```bash
# Install QEMU for cross-platform builds
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Verify platforms available
docker buildx ls
```

## Building with Docker

### All Architectures

```bash
./build-matrix.sh

# With verbose output
./build-matrix.sh --verbose
```

### Single Architecture

```bash
./docker/run-docker-compositor.sh armhf
./docker/run-docker-compositor.sh arm64 --verbose
```

### Output

```
out/
  armhf/
    compositor-armv7l-node20.tar.gz
  arm64/
    compositor-aarch64-node20.tar.gz
```

## Native Build (Fallback)

If Docker/QEMU builds cause issues (crashes, performance problems), build directly on target hardware.

### On Raspberry Pi

```bash
# SSH to your Pi running Volumio
ssh volumio@<pi-ip>

# Install build dependencies
sudo apt-get update
sudo apt-get install -y build-essential python3 pkg-config \
    libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev

# Navigate to installed plugin
cd /data/plugins/system_hardware/raspdac_mini_lcd/compositor

# Clean and rebuild
rm -rf node_modules package-lock.json
npm install --omit=dev

# Build native module
cd ../native/rgb565
rm -rf node_modules build
npm install
cp build/Release/rgb565.node ../compositor/utils/

# Create prebuilt archive
cd ../compositor
ARCH=$(uname -m)
tar -czf compositor-${ARCH}-node20.tar.gz \
    node_modules/ \
    package-lock.json \
    utils/rgb565.node

# Copy to your build machine
# scp compositor-${ARCH}-node20.tar.gz user@buildmachine:~/
```

### When to Use Native Build

- Docker build produces binaries that crash on target
- QEMU emulation is too slow
- Need to debug build issues on actual hardware
- Verifying Docker-built binaries match native behavior

## Using Prebuilt Packages

Copy the appropriate archive to the plugin assets directory:

```bash
cp out/armhf/compositor-armv7l-node20.tar.gz \
   /path/to/RaspDacMini/assets/

cp out/arm64/compositor-aarch64-node20.tar.gz \
   /path/to/RaspDacMini/assets/
```

The plugin install.sh automatically detects and uses prebuilts:

```
Found prebuilt compositor for armv7l Node 20
Using prebuilt version (fast installation, no compilation needed)
```

## Archive Contents

```
compositor-armv7l-node20.tar.gz
  node_modules/           # All npm dependencies
    canvas/               # ~5-6MB, native Cairo bindings
    socket.io-client/     # Volumio API client
    stackblur-canvas/     # Image processing
    ...
  package-lock.json       # Exact dependency versions
  utils/
    rgb565.node           # Compiled native module for framebuffer
```

## Dependencies Built

### Node.js Packages
- canvas 2.11.2 (native, requires Cairo)
- socket.io-client 2.3.0
- stackblur-canvas 2.7.0

### Native Module
- rgb565.node (custom, converts RGBA to BGR565 for ILI9341)

### System Libraries (build-time only)
- libcairo2-dev
- libpango1.0-dev
- libjpeg-dev
- libgif-dev
- librsvg2-dev

## Troubleshooting

### Docker build fails with "exec format error"

QEMU not set up correctly:

```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### Build succeeds but binary crashes on Pi

Architecture mismatch. Verify:

```bash
# On Pi
uname -m
# Should match archive name (armv7l or aarch64)

file /data/plugins/.../compositor/utils/rgb565.node
# Should show correct architecture
```

If mismatch, use native build on target Pi.

### "Cannot find module 'canvas'"

Archive extraction failed or incomplete. Re-extract:

```bash
cd /data/plugins/system_hardware/raspdac_mini_lcd/compositor
rm -rf node_modules utils/rgb565.node
tar -xzf ../assets/compositor-$(uname -m)-node20.tar.gz
```

### npm install fails with memory error

System has insufficient RAM. Use prebuilt package instead of compiling from source.

## Updating Prebuilts

Rebuild when:
- compositor/package.json dependencies change
- native/rgb565/rgb565.cpp changes
- Node.js major version changes in Volumio

```bash
./clean-all.sh
./build-matrix.sh
```

## Clean Build Outputs

```bash
./clean-all.sh
```

## License

Same as RaspDacMini plugin - see main repository.
