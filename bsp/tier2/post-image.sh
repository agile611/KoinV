#!/bin/bash
# Agile611 Koinos RISC-V Tier 2 Post-Image Script
# Creates final images for Tier 2 boards

set -euo pipefail

BINARIES_DIR="${1}"
BUILD_DIR="${2}"

echo "=== Agile611 Koinos RISC-V Tier 2 Post-Image ==="

VERSION="${VERSION:-$(date -u +%y.%m.%d)}"

# Compress rootfs
if [[ -f "${BINARIES_DIR}/rootfs.ext2" ]]; then
    xz -T0 -v "${BINARIES_DIR}/rootfs.ext2"
    mv "${BINARIES_DIR}/rootfs.ext2.xz" "${BINARIES_DIR}/koinos-trixie-riscv64-minimal-$(date -u +%y.%m.%d).img.xz"
    echo "Created minimal rootfs image"
fi

# Create minimal ISO for USB boot
if [[ -f "${BINARIES_DIR}/rootfs.ext2" ]]; then
    # Create minimal ISO with GRUB
    mkdir -p /tmp/iso/boot/grub
    cp "${BUILD_DIR}/images/rootfs.ext2" /tmp/iso/rootfs.img
    
    cat > /tmp/iso/boot/grub/grub.cfg << 'GRUBEOF'
set timeout=5
set default=0

menuentry "Agile611 Koinos RISC-V Tier 2" {
    linux /boot/Image console=ttyS0,115200 earlycon root=/dev/sr0 rw rootwait
    devicetree /dtb/$(uname -m).dtb
}
GRUBEOF
    
    # Create minimal ISO
    grub-mkrescue -o "${BINARIES_DIR}/koinos-trixie-riscv64-minimal-$(date -u +%y.%m.%d).iso" /tmp/iso 2>/dev/null || true
    if [[ -f "${BINARIES_DIR}/koinos-trixie-riscv64-minimal-$(date -u +%y.%m.%d).iso" ]]; then
        xz -T0 -v "${BINARIES_DIR}/koinos-trixie-riscv64-minimal-$(date -u +%y.%m.%d).iso"
        mv "${BINARIES_DIR}/koinos-trixie-riscv64-minimal-$(date -u +%y.%m.%d).iso.xz" "${BINARIES_DIR}/koinos-trixie-riscv64-minimal-$(date -u +%y.%m.%d).iso.xz"
    fi
fi

echo "Post-image complete"
