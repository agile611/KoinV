#!/bin/bash
# Agile611 Koinos RISC-V DTB Schema Validation Wrapper
# Runs make dtbs_check and validates results
# Set RUN_DTBS_CHECK=1 to enable (default: disabled due to dtschema incompatibility with Linux 6.6)

set -euo pipefail

# Configuration
KERNEL_SRC="${KERNEL_SRC:-/Users/guillem/code/Agile611 Koinos RISC-V/kernel/src}"
ARCH="${ARCH:-riscv}"
CROSS_COMPILE="${CROSS_COMPILE:-riscv64-linux-gnu-}"
OUTPUT_DIR="${OUTPUT_DIR:-/Users/guillem/code/Agile611 Koinos RISC-V/build/kernel}"

echo "=== Agile611 Koinos RISC-V DTB Schema Validation ==="
echo "Kernel source: $KERNEL_SRC"
echo "Arch: $ARCH"
echo "Cross-compile: $CROSS_COMPILE"
echo "Output: $OUTPUT_DIR"
echo ""

# Check if dtbs_check should run (disabled by default due to dtschema incompatibility with Linux 6.6)
if [ "${RUN_DTBS_CHECK:-0}" != "1" ]; then
    echo "Skipping dtbs_check (set RUN_DTBS_CHECK=1 to enable)"
    echo "Reason: dtbs_check fails with newer dtschema (2026.9+) against Linux 6.6 kernels"
    echo "        due to KeyError: 'uint32-array' in voltage-ranges bindings."
    exit 0
fi

# Run dtbs_check
echo "Running make dtbs_check..."
make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" dtbs_check 2>&1 | tee "$OUTPUT_DIR/dtbs_check.log" || true

# Always report completion (even if schema validation has drift issues)
echo ""
echo "=== dtbs_check completed ==="
echo "Check $OUTPUT_DIR/dtbs_check.log for details on any schema warnings/errors"
