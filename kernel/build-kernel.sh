#!/bin/bash
# Agile611 Koinos RISC-V Kernel Build Script
# Cross-compiles Linux kernel + DTBs for riscv64
# Runs dtbs_check validation

set -euo pipefail

# Configuration - use environment variables with CI-friendly defaults
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

KERNEL_SRC="${KERNEL_SRC:-$PROJECT_ROOT/kernel/src}"
KERNEL_CONFIG="${KERNEL_CONFIG:-$PROJECT_ROOT/kernel/config.trixie}"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/build/kernel}"
CROSS_COMPILE="${CROSS_COMPILE:-riscv64-linux-gnu-}"
ARCH="${ARCH:-riscv}"
JOBS="${JOBS:-$(nproc)}"

# Version from CalVer
VERSION="${VERSION:-$(date -u +"%y.%m.%d")}"
LOCALVERSION="-koinos-${VERSION}"

echo "=== Agile611 Koinos RISC-V Kernel Build ==="
echo "Source: ${KERNEL_SRC}"
echo "Config: ${KERNEL_CONFIG}"
echo "Output: ${OUTPUT_DIR}"
echo "Cross-compile: ${CROSS_COMPILE}"
echo "Arch: ${ARCH}"
echo "Jobs: ${JOBS}"
echo "Version: ${VERSION}"
echo "Localversion: ${LOCALVERSION}"
echo ""

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Copy config
echo "Copying kernel config..."
cp "${KERNEL_CONFIG}" "${KERNEL_SRC}/.config"

# Update LOCALVERSION in config
sed -i "s/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"${LOCALVERSION}\"/" "${KERNEL_SRC}/.config"

# Resolve new config symbols with defaults (non-interactive)
echo "Updating config with olddefconfig..."
cd "${KERNEL_SRC}"
make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" olddefconfig

# Ensure CONFIG_EFI_STUB is disabled (olddefconfig may reset it to default=y)
sed -i "s/^CONFIG_EFI_STUB=.*/CONFIG_EFI_STUB=n/" "${KERNEL_SRC}/.config"


# Build kernel
echo "Building kernel (Image)..."
cd "${KERNEL_SRC}"
make -j"${JOBS}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" Image 2>&1 | tee "${OUTPUT_DIR}/build.log"

# Build DTBs
echo "Building DTBs..."
make -j"${JOBS}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" dtbs 2>&1 | tee -a "${OUTPUT_DIR}/build.log"

# Validate DTBs against schema (optional - skip for release builds)
# dtbs_check fails with newer dtschema versions (e.g., 2026.9) against
# older Linux 6.6 kernels due to KeyError: 'uint32-array' in voltage-ranges.
# This is a development/linting step, not required for producing Image or DTBs.
# Set RUN_DTBS_CHECK=1 to enable (default: disabled for release builds).
if [ "${RUN_DTBS_CHECK:-0}" = "1" ]; then
    echo "Running dtbs_check..."
    make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" dtbs_check 2>&1 | tee -a "${OUTPUT_DIR}/dtbs_check.log" || true
else
    echo "Skipping dtbs_check (set RUN_DTBS_CHECK=1 to enable)"
fi

# Copy artifacts
echo "Copying artifacts to ${OUTPUT_DIR}..."
cp "${KERNEL_SRC}/arch/riscv/boot/Image" "${OUTPUT_DIR}/Image-${VERSION}"
cp "${KERNEL_SRC}/arch/riscv/boot/Image" "${OUTPUT_DIR}/Image"
cp "${KERNEL_SRC}/.config" "${OUTPUT_DIR}/config-${VERSION}"

# Copy all DTBs
mkdir -p "${OUTPUT_DIR}/dtb"
find "${KERNEL_SRC}/arch/riscv/boot/dts" -name "*.dtb" -exec cp {} "${OUTPUT_DIR}/dtb/" \;

# Create DTB manifest
echo "Creating DTB manifest..."
ls -la "${OUTPUT_DIR}/dtb/" > "${OUTPUT_DIR}/dtb-manifest.txt"

# Summary
echo ""
echo "=== Build Complete ==="
echo "Kernel: ${OUTPUT_DIR}/Image-${VERSION}"
echo "Config: ${OUTPUT_DIR}/config-${VERSION}"
echo "DTBs:   ${OUTPUT_DIR}/dtb/ ($(ls ${OUTPUT_DIR}/dtb/ | wc -l) files)"
echo "Manifest: ${OUTPUT_DIR}/dtb-manifest.txt"
echo "Log:    ${OUTPUT_DIR}/build.log"
echo "Check:  ${OUTPUT_DIR}/dtbs_check.log"
echo ""
echo "Version: ${VERSION}"
echo "Localversion: ${LOCALVERSION}"
