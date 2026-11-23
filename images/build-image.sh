#!/bin/bash
# Agile611 Koinos RISC-V Master Build Script
# Orchestrates: mmdebstrap -> overlays -> packages -> kernel -> genimage -> xz
# Produces both .img.xz (GPT disk image) and .iso.xz (ISO for USB)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${BUILD_DIR:-$PROJECT_ROOT/build}"
VERSION="${VERSION:-$(date -u +"%y.%m.%d")}"
IMAGE_NAME="koinos-trixie-riscv64-${VERSION}.img"
ISO_NAME="koinos-trixie-riscv64-${VERSION}.iso"
COMPRESSED_IMAGE="${IMAGE_NAME}.xz"
COMPRESSED_ISO="${ISO_NAME}.xz"

# Paths
MMDEBSTRAP_PROFILE="${MMDEBSTRAP_PROFILE:-$PROJECT_ROOT/profiles/base.trixie}"
KERNEL_BUILD_SCRIPT="${KERNEL_BUILD_SCRIPT:-$PROJECT_ROOT/kernel/build-kernel.sh}"
GENIMAGE_CFG="${GENIMAGE_CFG:-$PROJECT_ROOT/images/genimage.cfg}"
OVERLAYS_DIR="${OVERLAYS_DIR:-$PROJECT_ROOT/overlays}"
PACKAGES_DIR="${PACKAGES_DIR:-$PROJECT_ROOT/packages}"

# Build options
MMDEBSTRAP_MODE="${MMDEBSTRAP_MODE:-auto}"
MMDEBSTRAP_VARIANT="${MMDEBSTRAP_VARIANT:-important}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

echo "=== Agile611 Koinos RISC-V Image Build ==="
echo "Version: $VERSION"
echo "Build dir: $BUILD_DIR"
echo "Profile: $MMDEBSTRAP_PROFILE"
echo "Kernel script: $KERNEL_BUILD_SCRIPT"
echo "Genimage cfg: $GENIMAGE_CFG"
echo "Overlays: $OVERLAYS_DIR"
echo "Packages: $PACKAGES_DIR"
echo "MMDEBSTRAP_MODE: $MMDEBSTRAP_MODE"
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

# Use root mode for CI (unshare requires special privileges)
if [[ "$MMDEBSTRAP_MODE" == "auto" ]]; then
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        MMDEBSTRAP_MODE="root"
    else
        MMDEBSTRAP_MODE="unshare"
    fi
fi

echo "Using mmdebstrap mode: $MMDEBSTRAP_MODE"

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

# Prepare genimage input structure for GPT image
mkdir -p "$GENIMAGE_INPUT/boot"
mkdir -p "$GENIMAGE_INPUT/dtb"
mkdir -p "$GENIMAGE_INPUT/rootfs"

# Create ESP directory structure (for ESP partition)
ESP_DIR="$GENIMAGE_INPUT/esp"
mkdir -p "$ESP_DIR/EFI/BOOT"
mkdir -p "$ESP_DIR/loader/entries"
mkdir -p "$ESP_DIR/dtb"

# Copy EFI bootloader (BOOTRISCV64.EFI)
cp "$OVERLAYS_DIR/boot/EFI/BOOT/BOOTRISCV64.EFI" "$ESP_DIR/EFI/BOOT/BOOTRISCV64.EFI"

# Copy systemd-boot
cp "$OVERLAYS_DIR/boot/loader/loader.conf" "$ESP_DIR/loader/loader.conf"
cp "$OVERLAYS_DIR/boot/loader/entries/koinos-trixie-riscv64.conf" "$ESP_DIR/loader/entries/koinos-trixie-riscv64.conf"

# Copy DTBs
cp "$KERNEL_BUILD_DIR/dtb"/*.dtb "$ESP_DIR/dtb/"

# Copy Kernel
cp "$KERNEL_BUILD_DIR/Image" "$ESP_DIR/Image"

# Copy cmdline
cp "$OVERLAYS_DIR/boot/cmdline.txt" "$ESP_DIR/cmdline.txt"

# Prepare ISO root directory structure
echo "Preparing ISO root directory..."
ISO_ROOT="$GENIMAGE_INPUT/iso-root"
mkdir -p "$ISO_ROOT/EFI/BOOT"
mkdir -p "$ISO_ROOT/loader/entries"
mkdir -p "$ISO_ROOT/dtb"
mkdir -p "$ISO_ROOT/boot"

# Copy EFI bootloader
cp "$OVERLAYS_DIR/boot/EFI/BOOT/BOOTRISCV64.EFI" "$ISO_ROOT/EFI/BOOT/BOOTRISCV64.EFI"

# Copy systemd-boot
cp "$OVERLAYS_DIR/boot/loader/loader.conf" "$ISO_ROOT/loader/loader.conf"
cp "$OVERLAYS_DIR/boot/loader/entries/koinos-trixie-riscv64.conf" "$ISO_ROOT/loader/entries/koinos-trixie-riscv64.conf"

# Copy DTBs
cp "$KERNEL_BUILD_DIR/dtb"/*.dtb "$ISO_ROOT/dtb/"

# Copy Kernel
cp "$KERNEL_BUILD_DIR/Image" "$ISO_ROOT/boot/Image"

# Copy cmdline
cp "$OVERLAYS_DIR/boot/cmdline.txt" "$ISO_ROOT/boot/cmdline.txt"

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
COMPRESSED_IMAGE="${IMAGE_NAME}.xz"
COMPRESSED_ISO="${ISO_NAME}.xz"

if [[ -f "$OUTPUT_IMAGE" ]]; then
    echo "Compressing $OUTPUT_IMAGE -> ${IMAGE_NAME}.xz"
    xz -T0 -v "$OUTPUT_IMAGE"
    mv "$OUTPUT_IMAGE.xz" "$GENIMAGE_OUTPUT/${IMAGE_NAME}.xz"
    
    echo ""
    echo "=== GPT Disk Image Complete ==="
    echo "Image: $GENIMAGE_OUTPUT/${IMAGE_NAME}.xz"
    echo "Size: $(du -h "$GENIMAGE_OUTPUT/${IMAGE_NAME}.xz" | cut -f1)"
    echo "SHA256: $(sha256sum "$GENIMAGE_OUTPUT/${IMAGE_NAME}.xz" | cut -d' ' -f1)"
else
    echo "ERROR: GPT image not found at $OUTPUT_IMAGE"
    exit 1
fi

if [[ -f "$OUTPUT_ISO" ]]; then
    echo "Compressing $OUTPUT_ISO -> ${ISO_NAME}.xz"
    xz -T0 -v "$OUTPUT_ISO"
    mv "$OUTPUT_ISO.xz" "$GENIMAGE_OUTPUT/${ISO_NAME}.xz"
    
    echo ""
    echo "=== ISO Image Complete ==="
    echo "ISO: $GENIMAGE_OUTPUT/${ISO_NAME}.xz"
    echo "Size: $(du -h "$GENIMAGE_OUTPUT/${ISO_NAME}.xz" | cut -f1)"
    echo "SHA256: $(sha256sum "$GENIMAGE_OUTPUT/${ISO_NAME}.xz" | cut -d' ' -f1)"
else
    echo "WARNING: ISO image not found at $OUTPUT_ISO"
fi

echo ""
echo "=== Build Complete ==="
echo "Output directory: $GENIMAGE_OUTPUT"
ls -lh "$GENIMAGE_OUTPUT"/*.xz 2>/dev/null || true
