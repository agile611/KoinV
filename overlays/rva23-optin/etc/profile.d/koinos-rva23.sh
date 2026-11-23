#!/bin/bash
# Agile611 Koinos RISC-V RVA23 Opt-In Environment
# Source this file to enable RVA23-optimized environment variables

# Force RVA23U64 for glibc-hwcaps (requires hwprobe support)
# export GLIBC_HWCAPS_MASK=RVA23U64

# Force RVA23 for compiler (use with caution - breaks RV64GC compatibility)
# export CFLAGS="-march=rva23u64 -mtune=generic"
# export CXXFLAGS="-march=rva23u64 -mtune=generic"

# Enable RVV 1.0 auto-vectorization hints
# export RVV_ENABLE=1

echo "Agile611 Koinos RISC-V RVA23 Opt-In environment loaded"
echo "Run 'koinos-rva23-enable' to activate RVA23 optimizations"
