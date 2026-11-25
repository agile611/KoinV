#!/bin/bash
# Koinos RISC-V ISO Test Script for Debian/Ubuntu
# Tests the ISO image using QEMU on the build agent

set -euo pipefail

# Configuration - Use specific version or latest successful build
BUILD_NUMBER="${BUILD_NUMBER:-lastSuccessfulBuild}"
ISO_URL="${ISO_URL:-https://jenkins.tatsukai.com/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/output/koinos-trixie-riscv64-*.iso}"
KERNEL_URL="${KERNEL_URL:-https://jenkins.tatsukai.com/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/kernel/Image}"
DTB_URL="${DTB_URL:-https://jenkins.tatsukai.com/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/kernel/dtb/virt.dtb}"
WORK_DIR="${WORK_DIR:-/tmp/koinos-test}"
TIMEOUT="${TIMEOUT:-120}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${YELLOW}[INFO]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
log_err() { echo -e "${RED}[ERR]${NC} $*"; }

# Check dependencies
check_deps() {
    log_info "Checking dependencies..."
    for cmd in qemu-system-riscv64 wget xz sha256sum; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_err "Missing: $cmd"
            exit 1
        fi
    done
    log_ok "All dependencies found"
}

# Find OpenSBI firmware for RISC-V on Debian
find_firmware() {
    local firmware=""
    for f in \
        /usr/share/qemu/opensbi-riscv64-generic-fw_dynamic.bin \
        /usr/share/qemu/opensbi-riscv64-generic-fw_payload.bin \
        /usr/lib/qemu/opensbi-riscv64-generic-fw_dynamic.bin \
        /usr/lib/qemu/opensbi-riscv64-generic-fw_payload.bin; do
        if [ -f "$f" ]; then
            firmware="$f"
            break
        fi
    done
    echo "$firmware"
}

# Download artifacts with proper URL resolution
download_artifacts() {
    log_info "Creating work directory: $WORK_DIR"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    # Resolve the actual ISO URL (Jenkins doesn't support glob in URL)
    log_info "Resolving ISO URL..."
    local iso_base="https://jenkins.tatsukai.com/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/output/"
    local iso_name
    iso_name=$(wget -q -O- "${iso_base}" | grep -o 'koinos-trixie-riscv64-[0-9]\+\.[0-9]\+\.[0-9]\+\.iso' | head -1)
    if [ -z "$iso_name" ]; then
        log_err "Could not resolve ISO name from Jenkins"
        return 1
    fi
    local resolved_iso_url="${iso_base}${iso_name}"
    log_info "Resolved ISO: ${iso_name}"

    log_info "Downloading ISO..."
    wget -q "${resolved_iso_url}" -O koinos.iso

    log_info "Downloading kernel..."
    wget -q "${KERNEL_URL}" -O Image

    log_info "Downloading DTB..."
    wget -q "${DTB_URL}" -O virt.dtb

    # Verify downloads
    for f in koinos.iso Image virt.dtb; do
        if [ ! -s "$f" ]; then
            log_err "Download failed or empty: $f"
            return 1
        fi
    done

    log_ok "Artifacts downloaded: $(ls -lh koinos.iso Image virt.dtb | awk '{print $5, $9}')"
}

# Test 1: Direct ISO boot (UEFI with OpenSBI)
test_uefi_boot() {
    log_info "Test 1: UEFI boot from ISO (OpenSBI)"
    
    local firmware
    firmware=$(find_firmware)
    
    if [ -z "$firmware" ]; then
        log_err "No OpenSBI firmware found. Install qemu-system-riscv64 (provides opensbi-riscv64)"
        return 1
    fi

    timeout "$TIMEOUT" qemu-system-riscv64 \
        -machine virt \
        -cpu rv64 \
        -m 2G \
        -smp 2 \
        -drive file=koinos.iso,format=raw,if=virtio \
        -nographic \
        -no-reboot \
        -bios "$firmware" \
        -device virtio-rng-pci \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -serial file:qemu-uefi.log \
        -daemonize \
        -pidfile qemu.pid

    sleep 30
    
    if grep -q "login:" qemu-uefi.log 2>/dev/null; then
        log_ok "UEFI boot test PASSED"
        kill $(cat qemu.pid) 2>/dev/null || true
        return 0
    else
        log_err "UEFI boot test FAILED"
        cat qemu-uefi.log
        kill $(cat qemu.pid) 2>/dev/null || true
        return 1
    fi
}

# Test 2: Direct kernel boot with ISO as rootfs
test_kernel_boot() {
    log_info "Test 2: Direct kernel boot with ISO as rootfs"
    
    local firmware
    firmware=$(find_firmware)
    
    if [ -z "$firmware" ]; then
        log_err "No OpenSBI firmware found for kernel boot"
        return 1
    fi

    timeout "$TIMEOUT" qemu-system-riscv64 \
        -machine virt \
        -cpu rv64 \
        -m 2G \
        -smp 2 \
        -drive file=koinos.iso,format=raw,if=virtio \
        -nographic \
        -no-reboot \
        -bios "$firmware" \
        -kernel Image \
        -dtb virt.dtb \
        -append "console=ttyS0 earlycon root=/dev/vda2 rw rootwait" \
        -device virtio-rng-pci \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -serial file:qemu-kernel.log \
        -daemonize \
        -pidfile qemu.pid

    sleep 30
    
    if grep -q "login:" qemu-kernel.log 2>/dev/null; then
        log_ok "Kernel boot test PASSED"
        kill $(cat qemu.pid) 2>/dev/null || true
        return 0
    else
        log_err "Kernel boot test FAILED"
        cat qemu-kernel.log
        kill $(cat qemu.pid) 2>/dev/null || true
        return 1
    fi
}

# Main
main() {
    log_info "=== Koinos RISC-V ISO Test Suite (Debian) ==="
    
    check_deps
    download_artifacts || exit 1
    
    local failed=0
    test_uefi_boot || failed=1
    test_kernel_boot || failed=1
    
    if [ $failed -eq 0 ]; then
        log_ok "=== ALL TESTS PASSED ==="
        exit 0
    else
        log_err "=== SOME TESTS FAILED ==="
        exit 1
    fi
}

main "$@"