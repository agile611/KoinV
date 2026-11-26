#!/bin/bash
# Koinos RISC-V ISO Test Script for macOS (Apple Silicon)
# Tests the ISO image using QEMU on macOS

set -euo pipefail

# Get script directory to find .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env file if present (for JENKINS_USER, JENKINS_TOKEN, etc.)
if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    source "${SCRIPT_DIR}/.env"
    set +a
fi

# Configuration - Use specific version or latest successful build
# Version format: YY.MM.DD (e.g., 26.11.25) or "latest" to auto-detect from date
VERSION="${VERSION:-26.11.26}"
BUILD_NUMBER="${BUILD_NUMBER:-65}"
JENKINS_BASE="${JENKINS_BASE:-http://192.168.1.4:8080}"
JENKINS_USER="${JENKINS_USER:-guillemhs}"
JENKINS_TOKEN="${JENKINS_TOKEN:-1166ca5f14c393b12a2714c886d58e8551}"

ISO_URL="${ISO_URL:-${JENKINS_BASE}/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/output/koinos-trixie-riscv64-${VERSION}.iso}"
KERNEL_URL="${KERNEL_URL:-${JENKINS_BASE}/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/kernel/Image}"
# Use hifive-unmatched-a00.dtb (SiFive U740, compatible with QEMU virt)
DTB_URL="${DTB_URL:-${JENKINS_BASE}/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/kernel/dtb/hifive-unmatched-a00.dtb}"
# Full disk image URL for kernel boot test (has rootfs)
IMG_URL="${IMG_URL:-${JENKINS_BASE}/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/output/koinos-trixie-riscv64-${VERSION}.img}"
IMG_XZ_URL="${IMG_XZ_URL:-${JENKINS_BASE}/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/output/koinos-trixie-riscv64-${VERSION}.img.xz}"
ISO_XZ_URL="${ISO_XZ_URL:-${JENKINS_BASE}/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/output/koinos-trixie-riscv64-${VERSION}.iso.xz}"
WORK_DIR="${WORK_DIR:-/tmp/koinos-test}"
TIMEOUT="${TIMEOUT:-180}"  # Longer timeout for macOS TCG

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
            log_err "Missing: $cmd (install with: brew install qemu wget xz)"
            exit 1
        fi
    done
    log_ok "All dependencies found"
}

# Build download command - prefer curl for better auth handling
build_download_cmd() {
    local url="$1"
    local output="$2"
    if [ -n "$JENKINS_USER" ] && [ -n "$JENKINS_TOKEN" ]; then
        # Use curl for better authentication handling
        echo "curl -u \"${JENKINS_USER}:${JENKINS_TOKEN}\" -s -o ${output} ${url}"
    else
        echo "wget -q -O ${output} ${url}"
    fi
}

# Find OpenSBI firmware for RISC-V on macOS
find_firmware() {
    local firmware=""
    for f in \
        /opt/homebrew/share/qemu/opensbi-riscv64-generic-fw_dynamic.bin \
        /opt/homebrew/share/qemu/opensbi-riscv64-generic-fw_payload.bin \
        /usr/local/share/qemu/opensbi-riscv64-generic-fw_dynamic.bin \
        /usr/local/share/qemu/opensbi-riscv64-generic-fw_payload.bin \
        "$(brew --prefix qemu 2>/dev/null)/share/qemu/opensbi-riscv64-generic-fw_dynamic.bin" \
        "$HOME/koinos/overlays/boot/EFI/BOOT/BOOTRISCV64.EFI"; do
        if [ -f "$f" ]; then
            firmware="$f"
            break
        fi
    done
    echo "$firmware"
}

# Download artifacts with optional authentication
download_artifacts() {
    log_info "Creating work directory: $WORK_DIR"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    log_info "Downloading ISO from: ${ISO_URL}"
    eval "$(build_download_cmd "${ISO_URL}" koinos.iso)"

    log_info "Downloading kernel from: ${KERNEL_URL}"
    eval "$(build_download_cmd "${KERNEL_URL}" Image)"

    log_info "Downloading DTB from: ${DTB_URL}"
    eval "$(build_download_cmd "${DTB_URL}" virt.dtb)"

    log_info "Downloading full disk image from: ${IMG_URL}"
    eval "$(build_download_cmd "${IMG_URL}" koinos.img)"

    log_info "Downloading compressed disk image from: ${IMG_XZ_URL}"
    eval "$(build_download_cmd "${IMG_XZ_URL}" koinos.img.xz)"

    log_info "Downloading compressed ISO from: ${ISO_XZ_URL}"
    eval "$(build_download_cmd "${ISO_XZ_URL}" koinos.iso.xz)"

    # Verify downloads
    for f in koinos.iso Image virt.dtb koinos.img koinos.img.xz koinos.iso.xz; do
        if [ ! -s "$f" ]; then
            log_err "Download failed or empty: $f"
            log_info "Note: Jenkins may require authentication. Set JENKINS_USER and JENKINS_TOKEN env vars."
            return 1
        fi
    done

    log_ok "Artifacts downloaded: $(ls -lh koinos.iso Image virt.dtb koinos.img koinos.img.xz koinos.iso.xz | awk '{print $5, $9}')"
}

# Test: Direct kernel boot with full disk image (.img) as rootfs
# Note: QEMU virt machine generates its own DTB, so we don't need -dtb
test_kernel_boot() {
    log_info "Test: Direct kernel boot with full disk image (.img) as rootfs"
    
    # Download the full disk image (.img) for rootfs test
    local IMG_URL="${JENKINS_BASE}/job/Koinos-Release/${BUILD_NUMBER}/artifact/build/output/koinos-trixie-riscv64-${VERSION}.img"
    log_info "Downloading full disk image from: ${IMG_URL}"
    eval "$(build_download_cmd "${IMG_URL}" koinos.img)"
    
    if [ ! -s "koinos.img" ]; then
        log_err "Failed to download full disk image"
        return 1
    fi
    
    local firmware
    firmware=$(find_firmware)
    
    if [ -z "$firmware" ]; then
        log_err "No OpenSBI firmware found. Install qemu (brew install qemu) or place BOOTRISCV64.EFI at ~/koinos/overlays/boot/EFI/BOOT/BOOTRISCV64.EFI"
        return 1
    fi
    
    log_info "Using firmware: $firmware"
    
    # QEMU virt machine generates its own DTB, so we don't need -dtb
    timeout "$TIMEOUT" qemu-system-riscv64 \
        -machine virt \
        -cpu rv64 \
        -m 2G \
        -smp 2 \
        -drive file=koinos.img,format=raw,if=virtio \
        -nographic \
        -no-reboot \
        -bios "$firmware" \
        -kernel Image \
        -append "console=ttyS0 earlycon root=/dev/vda2 rw rootwait" \
        -device virtio-rng-pci \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -serial file:qemu-macos.log \
        -pidfile qemu.pid &

    QEMU_PID=$!
    sleep 60  # macOS TCG is slower, give more time
    
    if grep -q "login:" qemu-macos.log 2>/dev/null; then
        log_ok "Kernel boot test PASSED"
        kill $QEMU_PID 2>/dev/null || true
        return 0
    else
        log_err "Kernel boot test FAILED"
        cat qemu-macos.log
        kill $QEMU_PID 2>/dev/null || true
        return 1
    fi
}

# Test: UEFI boot from ISO (if firmware supports it)
test_uefi_boot() {
    log_info "Test: UEFI boot from ISO"
    
    local firmware
    firmware=$(find_firmware)
    
    if [ -z "$firmware" ]; then
        log_err "No firmware found for UEFI test"
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
        -pidfile qemu.pid &

    QEMU_PID=$!
    sleep 60
    
    if grep -q "login:" qemu-uefi.log 2>/dev/null; then
        log_ok "UEFI boot test PASSED"
        kill $QEMU_PID 2>/dev/null || true
        return 0
    else
        log_err "UEFI boot test FAILED (expected on macOS without proper UEFI firmware)"
        cat qemu-uefi.log
        kill $QEMU_PID 2>/dev/null || true
        return 1
    fi
}

# Main
# Test compressed artifacts can be decompressed and are valid
test_compressed_artifacts() {
    log_info "Test: Verify compressed artifacts can be decompressed"
    
    # Test .img.xz decompression
    log_info "Testing .img.xz decompression..."
    if xz -t koinos.img.xz 2>/dev/null; then
        log_ok ".img.xz integrity check PASSED"
    else
        log_err ".img.xz integrity check FAILED"
        return 1
    fi
    
    # Test .iso.xz decompression
    log_info "Testing .iso.xz decompression..."
    if xz -t koinos.iso.xz 2>/dev/null; then
        log_ok ".iso.xz integrity check PASSED"
    else
        log_err ".iso.xz integrity check FAILED"
        return 1
    fi
    
    # Quick decompression test (just first few MB)
    log_info "Testing quick decompression of .img.xz..."
    if xz -dc koinos.img.xz | head -c 10M > /dev/null 2>&1; then
        log_ok ".img.xz decompression test PASSED"
    else
        log_err ".img.xz decompression test FAILED"
        return 1
    fi
    
    log_info "Testing quick decompression of .iso.xz..."
    if xz -dc koinos.iso.xz | head -c 10M > /dev/null 2>&1; then
        log_ok ".iso.xz decompression test PASSED"
    else
        log_err ".iso.xz decompression test FAILED"
        return 1
    fi
    
    return 0
}

main() {
    log_info "=== Koinos RISC-V ISO Test Suite (macOS/Apple Silicon) ==="
    log_info "Note: RISC-V runs via TCG emulation on Apple Silicon (slower than Linux/KVM)"
    
    check_deps
    download_artifacts || exit 1
    
    local failed=0
    test_compressed_artifacts || failed=1
    test_kernel_boot || failed=1
    test_uefi_boot || true  # UEFI may fail on macOS, that's OK
    
    if [ $failed -eq 0 ]; then
        log_ok "=== ALL TESTS PASSED ==="
        exit 0
    else
        log_err "=== SOME TESTS FAILED ==="
        exit 1
    fi
}

main "$@"