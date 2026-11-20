#!/bin/bash
# KoinV DTB Schema Validation Wrapper
# Runs make dtbs_check and validates results

set -euo pipefail

# Configuration
KERNEL_SRC="${KERNEL_SRC:-/Users/guillem/code/KoinV/kernel/src}"
ARCH="${ARCH:-riscv}"
CROSS_COMPILE="${CROSS_COMPILE:-riscv64-linux-gnu-}"
OUTPUT_DIR="${OUTPUT_DIR:-/Users/guillem/code/KoinV/build/kernel}"

echo "=== KoinV DTB Schema Validation ==="
echo "Kernel source: $KERNEL_SRC"
echo "Arch: $ARCH"
echo "Cross-compile: $CROSS_COMPILE"
echo "Output: $OUTPUT_DIR"
echo ""

# Run dtbs_check
echo "Running make dtbs_check..."
cd "$KERNEL_SRC"
if make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" dtbs_check 2>&1 | tee "$OUTPUT_DIR/dtbs_check.log"; then
    echo ""
    echo "=== dtbs_check PASSED ==="
    echo "No errors or warnings found"
    exit 0
else
    echo ""
    echo "=== dtbs_check FAILED ==="
    echo "Check $OUTPUT_DIR/dtbs_check.log for details"
    exit 1
fi
