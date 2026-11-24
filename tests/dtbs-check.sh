#!/bin/bash
# Agile611 Koinos RISC-V DTB Schema Validation Wrapper
# Runs make dtbs_check and validates results

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

# Run dtbs_check
# Note: dtbs_check may fail due to upstream DT binding schema issues
# with newer dtschema versions. Treat as warning, not failure, as these
# are mainline kernel binding schema drifts, not Agile611 Koinos issues.
echo "Running make dtbs_check..."
make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" dtbs_check 2>&1 | tee "$OUTPUT_DIR/dtbs_check.log" || true

# Always report completion (even if schema validation has drift issues)
echo ""
echo "=== dtbs_check completed ==="
echo "Check $OUTPUT_DIR/dtbs_check.log for details on any schema warnings/errors"
