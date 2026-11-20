#!/bin/bash
# KoinV QEMU Smoke Test Automation
# Tests QEMU virt and sifive_u machines with KoinV image

set -euo pipefail

# Configuration
IMAGE="${1:-}"
KERNEL="${2:-}"
DTB_DIR="${3:-}"
VERSION="${VERSION:-$(date -u +"%y.%m.%d")}"
TIMEOUT="${TIMEOUT:-120}"
MEMORY="${MEMORY:-2G}"
CPUS="${CPUS:-2}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    cat << USAGE
Usage: $0 <image.xz> <kernel> <dtb_dir> [options]

Tests KoinV image on QEMU virt and sifive_u machines.

Arguments:
  image.xz    Compressed disk image (koinv-trixie-riscv64-*.img.xz)
  kernel      Kernel Image file
  dtb_dir     Directory containing DTB files

Options:
  --timeout SECONDS    Test timeout (default: 120)
  --memory SIZE        QEMU memory (default: 2G)
  --cpus N             Number of CPUs (default: 2)
  --machine LIST       Comma-separated machines (default: virt,sifive_u)
  --help               Show this help

Examples:
  $0 build/output/koinv-trixie-riscv64-26.11.20.img.xz build/kernel/Image build/kernel/dtb
  $0 --machine virt,sifive_u,shakti-c image.xz kernel dtb/
USAGE
    exit 1
}

# Parse options
MACHINES="virt,sifive_u"
while [[ $# -gt 0 ]]; do
    case $1 in
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --memory) MEMORY="$2"; shift 2 ;;
        --cpus) CPUS="$2"; shift 2 ;;
        --machine) MACHINES="$2"; shift 2 ;;
        --help) usage ;;
        *) break ;;
    esac
done

# Check required arguments
if [[ -z "$IMAGE" || -z "$KERNEL" || -z "$DTB_DIR" ]]; then
    log_error "Missing required arguments"
    usage
fi

if [[ ! -f "$IMAGE" ]]; then
    log_error "Image not found: $IMAGE"
    exit 1
fi

if [[ ! -f "$KERNEL" ]]; then
    log_error "Kernel not found: $KERNEL"
    exit 1
fi

if [[ ! -d "$DTB_DIR" ]]; then
    log_error "DTB directory not found: $DTB_DIR"
    exit 1
fi

# Decompress image
log_info "Decompressing image..."
xz -d -k "$IMAGE"
IMG_FILE="${IMAGE%.xz}"

# Test function
test_machine() {
    local machine="$1"
    local dtb_file="$DTB_DIR/$machine.dtb"
    
    if [[ ! -f "$dtb_file" ]]; then
        log_warn "DTB not found for $machine: $dtb_file"
        return 1
    fi
    
    log_info "Testing QEMU machine: $machine"
    log_info "  Kernel: $KERNEL"
    log_info "  DTB: $dtb_file"
    log_info "  Image: $IMG_FILE"
    log_info "  Memory: $MEMORY, CPUs: $CPUS"
    
    # Create PID file
    local pidfile="/tmp/qemu-$machine.pid"
    
    # Run QEMU
    timeout "$TIMEOUT" qemu-system-riscv64 \
        -machine "$machine" \
        -cpu rv64 \
        -m "$MEMORY" \
        -smp "$CPUS" \
        -drive file="$IMG_FILE",format=raw,if=virtio \
        -nographic \
        -no-reboot \
        -kernel "$KERNEL" \
        -dtb "$dtb_file" \
        -append "console=ttyS0 earlycon root=/dev/vda2 rw rootwait" \
        -device virtio-rng-pci \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -serial mon:stdio \
        -monitor none \
        -display none \
        -daemonize \
        -pidfile "$pidfile" \
        2>&1 | tee "/tmp/qemu-$machine.log" &
    
    local qemu_pid=$!
    echo "$qemu_pid" > "$pidfile"
    
    # Wait for boot
    log_info "Waiting for boot (max ${TIMEOUT}s)..."
    local elapsed=0
    local success=false
    
    while [[ $elapsed -lt $TIMEOUT ]]; do
        sleep 5
        elapsed=$((elapsed + 5))
        
        # Check for login prompt in serial output
        if grep -q "login:" "/tmp/qemu-$machine.log" 2>/dev/null; then
            success=true
            break
        fi
        
        # Check if QEMU process died
        if ! kill -0 "$qemu_pid" 2>/dev/null; then
            log_error "QEMU process died unexpectedly"
            break
        fi
    done
    
    # Cleanup
    if kill -0 "$qemu_pid" 2>/dev/null; then
        kill "$qemu_pid" 2>/dev/null || true
    fi
    rm -f "$pidfile"
    
    if [[ "$success" == true ]]; then
        log_info "${GREEN}PASS${NC}: $machine booted successfully"
        return 0
    else
        log_error "${RED}FAIL${NC}: $machine did not boot within ${TIMEOUT}s"
        return 1
    fi
}

# Main
log_info "=== KoinV QEMU Smoke Test ==="
log_info "Version: $VERSION"
log_info "Image: $IMAGE"
log_info "Kernel: $KERNEL"
log_info "DTB Dir: $DTB_DIR"
log_info "Machines: $MACHINES"
log_info "Timeout: ${TIMEOUT}s"
log_info ""

# Run tests
IFS=',' read -ra MACHINE_LIST <<< "$MACHINES"
FAILED=0
PASSED=0

for machine in "${MACHINE_LIST[@]}"; do
    if test_machine "$machine"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

# Summary
log_info "=== Test Summary ==="
log_info "Passed: $PASSED"
log_info "Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
    log_error "Some tests failed"
    exit 1
else
    log_info "All tests passed!"
    exit 0
fi
