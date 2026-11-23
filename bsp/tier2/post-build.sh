#!/bin/bash
# Agile611 Koinos RISC-V Tier 2 Post-Build Script
# Copies kernel and DTBs to target rootfs

set -euo pipefail

TARGET_DIR="${1}"
BUILD_DIR="${2}"

echo "=== Agile611 Koinos RISC-V Tier 2 Post-Build ==="

# Copy kernel and DTBs from kernel build
KERNEL_BUILD_DIR="${BUILD_DIR}/../kernel/build"
if [[ -f "${KERNEL_BUILD_DIR}/Image" ]]; then
    cp "${KERNEL_BUILD_DIR}/Image" "${TARGET_DIR}/boot/"
    echo "Copied kernel Image"
fi

if [[ -d "${KERNEL_BUILD_DIR}/dtb" ]]; then
    mkdir -p "${TARGET_DIR}/boot/dtb"
    cp "${KERNEL_BUILD_DIR}/dtb"/*.dtb "${TARGET_DIR}/boot/dtb/"
    echo "Copied DTBs"
fi

# Create minimal init script
cat > "${TARGET_DIR}/etc/inittab" << 'INITEOF'
::sysinit:/etc/init.d/rcS
::askfirst:-/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
::restart:/sbin/init
INITEOF

# Create minimal rcS
mkdir -p "${TARGET_DIR}/etc/init.d"
cat > "${TARGET_DIR}/etc/init.d/rcS" << 'RCEOF'
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /tmp

# Set hostname
hostname koinos-tier2

# Start networking
/sbin/ifup -a

# Start dropbear SSH
/usr/sbin/dropbear -R

# Set root password (empty by default, change on first boot)
echo "root:koinos" | chpasswd

echo "Agile611 Koinos RISC-V Tier 2 initialized"
RCEOF
chmod +x "${TARGET_DIR}/etc/init.d/rcS"

# Create network interfaces
cat > "${TARGET_DIR}/etc/network/interfaces" << 'NETEOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
NETEOF

# Create dropbear config
mkdir -p "${TARGET_DIR}/etc/dropbear"
dropbearkey -t rsa -f "${TARGET_DIR}/etc/dropbear/dropbear_rsa_host_key" 2>/dev/null || true
dropbearkey -t ecdsa -f "${TARGET_DIR}/etc/dropbear/dropbear_ecdsa_host_key" 2>/dev/null || true

# Create fstab
cat > "${TARGET_DIR}/etc/fstab" << 'FSTABEOF'
/dev/root  /  ext4  defaults,noatime  0  1
proc       /proc  proc  defaults  0  0
sysfs      /sys  sysfs  defaults  0  0
tmpfs      /run  tmpfs  defaults  0  0
tmpfs      /tmp  tmpfs  defaults  0  0
FSTABEOF

# Set root password (empty by default)
echo "root:koinos" | chroot "${TARGET_DIR}" chpasswd 2>/dev/null || echo "root:koinos" > "${TARGET_DIR}/etc/shadow"

# Create version file
echo "Agile611 Koinos RISC-V Tier 2 $(date -u +%y.%m.%d)" > "${TARGET_DIR}/etc/koinos-version"

echo "Post-build complete"
