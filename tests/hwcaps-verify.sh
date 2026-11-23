#!/bin/bash
# Agile611 Koinos RISC-V Tier 2 HWCapS Verification
# Verifies hwcaps and IFUNC work on minimal variant

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

log_info "=== Agile611 Koinos RISC-V Tier 2 HWCapS Verification ==="
echo ""

# Check hwcaps directory
HWCAPS_DIR="/usr/lib/riscv64-linux-gnu/hwcaps/RVA23U64"
if [[ -d "$HWCAPS_DIR" ]]; then
    log_info "✓ hwcaps directory exists: $HWCAPS_DIR"
    ls -la "$HWCAPS_DIR"
else
    log_error "✗ hwcaps directory missing: $HWCAPS_DIR"
    exit 1
fi

# Check hwprobe syscall
log_info "Checking hwprobe syscall..."
if grep -q "riscv_hwprobe" /proc/kallsyms 2>/dev/null; then
    log_info "✓ hwprobe syscall available in kernel"
else
    log_warn "⚠ hwprobe syscall not found in /proc/kallsyms"
fi

# Test hwprobe via perl
log_info "Testing hwprobe syscall..."
perl -e '
    use strict;
    use warnings;
    my $key = 1;
    my $buf = pack("QQ", 0, 0);
    my $ret = syscall(442, $key, $buf, 16, 0);
    if ($ret == 0) {
        my ($val, $mask) = unpack("QQ", $buf);
        printf "hwprobe returned: value=0x%x mask=0x%x\n", $val, $mask;
        if ($val & 0x80000000) {
            print "RVA23U64 profile SUPPORTED\n";
        } else {
            print "RVA23U64 profile NOT detected\n";
        }
    } else {
        print "hwprobe syscall failed: $!\n";
    }
' 2>/dev/null || log_warn "hwprobe test failed (may need kernel support)"

# Check IFUNC support
log_info "Checking IFUNC support..."
if readelf -s /lib/riscv64-linux-gnu/libc.so.6 2>/dev/null | grep -q "IFUNC"; then
    log_info "✓ IFUNC resolvers found in libc"
else
    log_warn "⚠ IFUNC resolvers not found in libc"
fi

# Check optimized libraries
log_info "Checking optimized libraries in hwcaps..."
for lib in libcrypto.so libgcrypt.so libjpeg.so; do
    if [[ -f "/usr/lib/riscv64-linux-gnu/hwcaps/RVA23U64/$lib" ]]; then
        log_info "✓ Found optimized $lib"
    else
        log_warn "⚠ Missing optimized $lib"
    fi
done

# Check IFUNC resolvers
log_info "Checking IFUNC resolvers..."
if [[ -f "/usr/lib/riscv64-linux-gnu/hwcaps/RVA23U64/libifunc_rvv.so" ]]; then
    log_info "✓ IFUNC resolver library found"
    readelf -s /usr/lib/riscv64-linux-gnu/hwcaps/RVA23U64/libifunc_rvv.so | grep -i ifunc || true
else
    log_warn "⚠ IFUNC resolver library not found"
fi

# Test basic commands
log_info "Testing basic commands..."
for cmd in ls cat cp mv rm mkdir rmdir; do
    if command -v "$cmd" >/dev/null 2>&1; then
        log_info "✓ $cmd available"
    else
        log_warn "⚠ $cmd not found"
    fi
done

# Check init system
log_info "Checking init system..."
if [[ -f /sbin/init ]] && ! systemctl --version >/dev/null 2>&1; then
    log_info "✓ Non-systemd init (BusyBox)"
else
    log_warn "⚠ Unexpected init system"
fi

# Check memory
log_info "Checking memory..."
free -h

log_info "=== Verification Complete ==="
