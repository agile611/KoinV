#!/bin/bash
# KoinV Kernel Build Script
# Cross-compiles Linux kernel + DTBs for riscv64
# Runs dtbs_check validation

set -euo pipefail

# Configuration
KERNEL_SRC="${KERNEL_SRC:-/Users/guillem/code/KoinV/kernel/src}"
KERNEL_CONFIG="${KERNEL_CONFIG:-/Users/guillem/code/KoinV/kernel/config.trixie}"
OUTPUT_DIR="${OUTPUT_DIR:-/Users/guillem/code/KoinV/build/kernel}"
CROSS_COMPILE="${CROSS_COMPILE:-riscv64-elf-}"
ARCH="${ARCH:-riscv}"
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc)}"

# Version from CalVer
VERSION="${VERSION:-$(date -u +"%y.%m.%d")}"
LOCALVERSION="-koinv-${VERSION}"

echo "=== KoinV Kernel Build ==="
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

# Build kernel
echo "Building kernel (Image)..."
cd "${KERNEL_SRC}"
gmake -j"${JOBS}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" Image 2>&1 | tee "${OUTPUT_DIR}/build.log"

# Build DTBs
echo "Building DTBs..."
gmake -j"${JOBS}" ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" dtbs 2>&1 | tee -a "${OUTPUT_DIR}/build.log"

# Validate DTBs against schema
echo "Running dtbs_check..."
gmake ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" dtbs_check 2>&1 | tee -a "${OUTPUT_DIR}/dtbs_check.log"

# Check dtbs_check result
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "ERROR: dtbs_check failed!"
    exit 1
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
