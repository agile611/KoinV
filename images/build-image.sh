#!/bin/bash
# KoinV Master Build Script
# Orchestrates: mmdebstrap -> overlays -> packages -> kernel -> genimage -> xz
# Produces both .img.xz (GPT disk image) and .iso.xz (ISO for USB)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build}"
VERSION="${VERSION:-$(date -u +"%y.%m.%d")}"
IMAGE_NAME="koinv-trixie-riscv64-${VERSION}.img"
ISO_NAME="koinv-trixie-riscv64-${VERSION}.iso"
COMPRESSED_IMAGE="${IMAGE_NAME}.xz"
COMPRESSED_ISO="${ISO_NAME}.xz"

# Paths
MMDEBSTRAP_PROFILE="${MMDEBSTRAP_PROFILE:-$PROJECT_ROOT/profiles/base.trixie}"
KERNEL_BUILD_SCRIPT="${KERNEL_BUILD_SCRIPT:-$PROJECT_ROOT/kernel/build-kernel.sh}"
GENIMAGE_CFG="${GENIMAGE_CFG:-$PROJECT_ROOT/images/genimage.cfg}"
OVERLAYS_DIR="${OVERLAYS_DIR:-$PROJECT_ROOT/overlays}"
PACKAGES_DIR="${PACKAGES_DIR:-$PROJECT_ROOT/packages}"

# Build options
MMDEBSTRAP_MODE="${MMDEBSTRAP_MODE:-unshare}"
MMDEBSTRAP_VARIANT="${MMDEBSTRAP_VARIANT:-important}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

echo "=== KoinV Image Build ==="
echo "Version: $VERSION"
echo "Build dir: $BUILD_DIR"
echo "Profile: $MMDEBSTRAP_PROFILE"
echo "Kernel script: $KERNEL_BUILD_SCRIPT"
echo "Genimage cfg: $GENIMAGE_CFG"
echo "Overlays: $OVERLAYS_DIR"
echo "Packages: $PACKAGES_DIR"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

# Step 1: Build kernel + DTBs
echo "=== Step 1: Building Kernel ==="
if [[ -x "$KERNEL_BUILD_SCRIPT" ]]; then
    VERSION="$VERSION" "$KERNEL_BUILD_SCRIPT"
else
    echo "ERROR: Kernel build script not found or not executable: $KERNEL_BUILD_SCRIPT"
    exit 1
fi

# Step 2: Build rootfs with mmdebstrap
echo "=== Step 2: Building Rootfs with mmdebstrap ==="
ROOTFS_DIR="$BUILD_DIR/rootfs"
mkdir -p "$ROOTFS_DIR"

mmdebstrap \
    --architectures=riscv64 \
    --variant="$MMDEBSTRAP_VARIANT" \
    --mode="$MMDEBSTRAP_MODE" \
    --include=ca-certificates,gnupg,gpgv \
    trixie "$ROOTFS_DIR" "$DEBIAN_MIRROR"

# Step 3: Apply overlays
echo "=== Step 3: Applying Overlays ==="
# etc/
if [[ -d "$OVERLAYS_DIR/etc" ]]; then
    cp -r "$OVERLAYS_DIR/etc"/* "$ROOTFS_DIR/etc/"
fi

# boot/ (kernel, cmdline, bootloader configs)
if [[ -d "$OVERLAYS_DIR/boot" ]]; then
    mkdir -p "$ROOTFS_DIR/boot"
    cp -r "$OVERLAYS_DIR/boot"/* "$ROOTFS_DIR/boot/"
fi

# usr/
if [[ -d "$OVERLAYS_DIR/usr" ]]; then
    cp -r "$OVERLAYS_DIR/usr"/* "$ROOTFS_DIR/usr/"
fi

# Step 4: Install kernel + DTBs into rootfs
echo "=== Step 4: Installing Kernel + DTBs ==="
KERNEL_BUILD_DIR="$PROJECT_ROOT/build/kernel"
if [[ -f "$KERNEL_BUILD_DIR/Image" ]]; then
    cp "$KERNEL_BUILD_DIR/Image" "$ROOTFS_DIR/boot/Image"
fi
if [[ -d "$KERNEL_BUILD_DIR/dtb" ]]; then
    mkdir -p "$ROOTFS_DIR/boot/dtb"
    cp "$KERNEL_BUILD_DIR/dtb"/*.dtb "$ROOTFS_DIR/boot/dtb/"
fi
if [[ -f "$KERNEL_BUILD_DIR/config-${VERSION}" ]]; then
    cp "$KERNEL_BUILD_DIR/config-${VERSION}" "$ROOTFS_DIR/boot/config-${VERSION}"
fi

# Step 5: Install custom packages
echo "=== Step 5: Installing Custom Packages ==="
if [[ -d "$PACKAGES_DIR" ]]; then
    for deb in "$PACKAGES_DIR"/*.deb; do
        if [[ -f "$deb" ]]; then
            echo "Installing $deb..."
            dpkg -x "$deb" "$ROOTFS_DIR/"
        fi
    done
fi

# Step 6: Generate disk image with genimage (both .img and .iso)
echo "=== Step 6: Assembling Disk Images with genimage ==="
GENIMAGE_INPUT="$BUILD_DIR/genimage-input"
GENIMAGE_OUTPUT="$BUILD_DIR/output"

mkdir -p "$GENIMAGE_INPUT"
mkdir -p "$GENIMAGE_OUTPUT"

# Prepare genimage input structure
mkdir -p "$GENIMAGE_INPUT/boot"
mkdir -p "$GENIMAGE_INPUT/dtb"
mkdir -p "$GENIMAGE_INPUT/rootfs"

# Copy boot assets
cp "$KERNEL_BUILD_DIR/Image" "$GENIMAGE_INPUT/boot/Image"
cp "$KERNEL_BUILD_DIR/dtb"/*.dtb "$GENIMAGE_INPUT/dtb/"
cp "$OVERLAYS_DIR/boot/cmdline.txt" "$GENIMAGE_INPUT/boot/cmdline.txt"

# Copy bootloader binaries (need to be built separately)
# For now, create placeholder
mkdir -p "$GENIMAGE_INPUT/boot/EFI/BOOT"
touch "$GENIMAGE_INPUT/boot/EFI/BOOT/BOOTRISCV64.EFI"

# Create GRUB EFI image for ISO El Torito
mkdir -p "$GENIMAGE_INPUT/boot/grub"
# Create minimal grub.cfg for ISO
cat > "$GENIMAGE_INPUT/boot/grub/grub.cfg" << 'GRUBEOF'
set timeout=5
set default=0

menuentry "KoinV Linux" {
    linux /Image console=ttyS0,115200 earlycon root=/dev/sr0 rw rootwait
    devicetree /dtb/$(uname -m).dtb
}
GRUBEOF

# Create minimal EFI image for El Torito (placeholder)
dd if=/dev/zero of="$GENIMAGE_INPUT/boot/grub/efi.img" bs=1M count=4 2>/dev/null
mkfs.vfat "$GENIMAGE_INPUT/boot/grub/efi.img" 2>/dev/null || true

# Copy rootfs
cp -r "$ROOTFS_DIR"/* "$GENIMAGE_INPUT/rootfs/"

# Run genimage
cd "$PROJECT_ROOT/images"
genimage \
    --config "$GENIMAGE_CFG" \
    --inputpath "$GENIMAGE_INPUT" \
    --outputpath "$GENIMAGE_OUTPUT" \
    --rootpath "$ROOTFS_DIR"

# Step 7: Compress images
echo "=== Step 7: Compressing Images ==="
OUTPUT_IMAGE="$GENIMAGE_OUTPUT/$IMAGE_NAME"
OUTPUT_ISO="$GENIMAGE_OUTPUT/$ISO_NAME"

if [[ -f "$OUTPUT_IMAGE" ]]; then
    echo "Compressing $OUTPUT_IMAGE -> $COMPRESSED_IMAGE"
    xz -T0 -v "$OUTPUT_IMAGE"
    mv "$OUTPUT_IMAGE.xz" "$GENIMAGE_OUTPUT/$COMPRESSED_IMAGE"
    
    echo ""
    echo "=== GPT Disk Image Complete ==="
    echo "Image: $GENIMAGE_OUTPUT/$COMPRESSED_IMAGE"
    echo "Size: $(du -h "$GENIMAGE_OUTPUT/$COMPRESSED_IMAGE" | cut -f1)"
    echo "SHA256: $(sha256sum "$GENIMAGE_OUTPUT/$COMPRESSED_IMAGE" | cut -d' ' -f1)"
else
    echo "ERROR: GPT image not found at $OUTPUT_IMAGE"
    exit 1
fi

if [[ -f "$OUTPUT_ISO" ]]; then
    echo "Compressing $OUTPUT_ISO -> $COMPRESSED_ISO"
    xz -T0 -v "$OUTPUT_ISO"
    mv "$OUTPUT_ISO.xz" "$GENIMAGE_OUTPUT/$COMPRESSED_ISO"
    
    echo ""
    echo "=== ISO Image Complete ==="
    echo "ISO: $GENIMAGE_OUTPUT/$COMPRESSED_ISO"
    echo "Size: $(du -h "$GENIMAGE_OUTPUT/$COMPRESSED_ISO" | cut -f1)"
    echo "SHA256: $(sha256sum "$GENIMAGE_OUTPUT/$COMPRESSED_ISO" | cut -d' ' -f1)"
else
    echo "WARNING: ISO image not found at $OUTPUT_ISO (may need GRUB EFI image)"
fi

echo ""
echo "=== Build Complete ==="
echo "Output directory: $GENIMAGE_OUTPUT"
ls -lh "$GENIMAGE_OUTPUT"/*.xz 2>/dev/null || true
