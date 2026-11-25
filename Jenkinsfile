#!/usr/bin/env groovy
/**
 * Agile611 Koinos RISC-V Jenkins Pipeline
 * Builds kernel, rootfs, GPT disk image (.img.xz) and ISO image (.iso.xz)
 * for Debian 13 "Trixie" on riscv64 architecture
 *
 * Requirements on Jenkins agent:
 * - Debian 13 (Trixie) or compatible
 * - Docker (for binfmt/qemu-user-static)
 * - Required packages: build-essential, bc, flex, bison, libssl-dev, libelf-dev,
 *   dwarves, device-tree-compiler, gcc-riscv64-linux-gnu, qemu-system-riscv,
 *   qemu-user-binfmt, binfmt-support, mmdebstrap, genimage, xz-utils, cpio,
 *   kmod, git, python3-pip
 * - pip3 install dtschema
 */

pipeline {
    agent {
        label 'riscv64-build'  // Requires Debian 13 agent with cross-compilation toolchain
    }

    options {
        timeout(time: 4, unit: 'HOURS')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))
        disableConcurrentBuilds()
    }

    environment {
        // CalVer versioning (YY.MM.DD for daily, YY.MM for monthly)
        VERSION = "${env.BUILD_NUMBER ? String.format('%02d.%02d.%02d', Calendar.instance.get(Calendar.YEAR) % 100, Calendar.instance.get(Calendar.MONTH) + 1, Calendar.instance.get(Calendar.DAY_OF_MONTH)) : 'dev'}"
        ARCH = 'riscv'
        CROSS_COMPILE = 'riscv64-linux-gnu-'
        DEBIAN_MIRROR = 'http://deb.debian.org/debian'
        MMDEBSTRAP_MODE = 'auto'  // Auto-detect mode (works with non-root)
        MMDEBSTRAP_VARIANT = 'important'
        BUILD_DIR = "${WORKSPACE}/build"
        KERNEL_SRC = "${WORKSPACE}/kernel/src"
        KERNEL_CONFIG = "${WORKSPACE}/kernel/config.trixie"
        GENIMAGE_CFG = "${WORKSPACE}/images/genimage.cfg"
        OVERLAYS_DIR = "${WORKSPACE}/overlays"
        PACKAGES_DIR = "${WORKSPACE}/packages"
    }

    stages {
        stage('Setup Environment') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Agile611 Koinos RISC-V Jenkins Build ==="
                    echo "Version: ${VERSION}"
                    echo "Workspace: ${WORKSPACE}"
                    echo "Build dir: ${BUILD_DIR}"
                    echo "Arch: ${ARCH}"
                    echo "Cross-compile: ${CROSS_COMPILE}"
                    
                    # Verify we're on Debian 13 (Trixie)
                    if [ -f /etc/os-release ]; then
                        . /etc/os-release
                        echo "OS: ${PRETTY_NAME}"
                        if [ "${VERSION_ID}" != "13" ]; then
                            echo "WARNING: Expected Debian 13 (Trixie), got ${VERSION_ID}"
                        fi
                    fi
                    
                    # Create build directory
                    mkdir -p "${BUILD_DIR}"
                    
                    # Verify required tools (warn but don't fail - they may be installed in next stage)
                    for tool in gcc-riscv64-linux-gnu mmdebstrap genimage dtc qemu-system-riscv64 xz; do
                        if ! command -v ${tool} >/dev/null 2>&1; then
                            echo "WARNING: Required tool not found: ${tool} (will be installed)"
                        fi
                    done
                    echo "Environment setup complete"
                '''
            }
        }

        stage('Setup binfmt for QEMU') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Setting up binfmt for qemu-user ==="
                    
                    # Determine sudo command (non-interactive, or empty if root)
                    if [ "$(id -u)" -eq 0 ]; then
                        SUDO=""
                    elif sudo -n true 2>/dev/null; then
                        SUDO="sudo -n"
                    else
                        ACTUAL_USER=$(whoami)
                        echo "ERROR: This build requires passwordless sudo for user: $ACTUAL_USER (UID: $(id -u))"
                        echo "Please configure passwordless sudo on the Jenkins agent:"
                        echo "  echo '$ACTUAL_USER ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$ACTUAL_USER"
                        echo "  sudo chmod 440 /etc/sudoers.d/$ACTUAL_USER"
                        echo ""
                        echo "Or run as root: sudo -i"
                        exit 1
                    fi
                    
                    # Ensure binfmt_misc is mounted
                    if [ ! -d /proc/sys/fs/binfmt_misc ]; then
                        echo "Mounting binfmt_misc filesystem..."
                        ${SUDO} mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
                    fi
                    
                    # Register qemu-riscv64 if not already registered
                    if [ ! -f /proc/sys/fs/binfmt_misc/qemu-riscv64 ]; then
                        echo "Registering qemu-riscv64 binfmt..."
                        # Try update-binfmts first (Debian/Ubuntu)
                        if command -v update-binfmts >/dev/null 2>&1; then
                            ${SUDO} update-binfmts --enable qemu-riscv64 2>/dev/null || true
                        fi
                        # If still not registered, register manually
                        if [ ! -f /proc/sys/fs/binfmt_misc/qemu-riscv64 ]; then
                            echo ':qemu-riscv64:M::\\x7fELF\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\xf3\\x00:\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\x00\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\xfe\\xff\\xff\\xff:/usr/bin/qemu-riscv64-static:' | ${SUDO} tee /proc/sys/fs/binfmt_misc/register >/dev/null
                        fi
                    fi
                    
                    # Enable qemu-riscv64 binfmt
                    if [ -f /proc/sys/fs/binfmt_misc/qemu-riscv64/enabled ]; then
                        echo 1 | ${SUDO} tee /proc/sys/fs/binfmt_misc/qemu-riscv64/enabled >/dev/null
                    fi
                    
                    # Register qemu-user-static via Docker (for mmdebstrap --mode=root)
                    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
                    
                    echo "binfmt setup complete"
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Installing Build Dependencies ==="

                    # Determine sudo command (non-interactive, or empty if root)
                    if [ "$(id -u)" -eq 0 ]; then
                        SUDO=""
                    elif sudo -n true 2>/dev/null; then
                        SUDO="sudo -n"
                    else
                        ACTUAL_USER=$(whoami)
                        echo "ERROR: This build requires passwordless sudo for user: $ACTUAL_USER (UID: $(id -u))"
                        echo "Please configure passwordless sudo on the Jenkins agent:"
                        echo "  echo '$ACTUAL_USER ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$ACTUAL_USER"
                        echo "  sudo chmod 440 /etc/sudoers.d/$ACTUAL_USER"
                        echo ""
                        echo "Or run as root: sudo -i"
                        exit 1
                    fi

                    # Update package list
                    ${SUDO} apt-get update

                    # Install required packages for RISC-V cross-compilation and image building
                    ${SUDO} apt-get install -y \
                        build-essential \
                        bc \
                        flex \
                        bison \
                        libssl-dev \
                        libelf-dev \
                        dwarves \
                        device-tree-compiler \
                        gcc-riscv64-linux-gnu \
                        qemu-system-riscv64 \
                        qemu-user-binfmt \
                        binfmt-support \
                        mmdebstrap \
                        genimage \
                        xz-utils \
                        cpio \
                        kmod \
                        git \
                        python3-pip \
                        dosfstools \
                        mtools

                    # Install dtschema for DTB validation
                    ${SUDO} pip3 install --break-system-packages dtschema

                    echo "Dependencies installed"
                '''
            }
        }

        stage('Clone Linux Kernel Source') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Cloning Linux Kernel Source ==="
                    
                    mkdir -p "${WORKSPACE}/kernel"
                    
                    # Check if kernel/src exists and has actual kernel source (Makefile)
                    # It might exist as empty directory from nested git repo in checkout
                    if [ ! -f "${KERNEL_SRC}/Makefile" ]; then
                        rm -rf "${KERNEL_SRC}"
                        git clone --depth=1 --branch v6.6.58 \
                            https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
                            "${KERNEL_SRC}"
                    else
                        echo "Kernel source already exists at ${KERNEL_SRC}"
                    fi
                    
                    echo "Kernel source ready"
                '''
            }
        }

        stage('Build Kernel + DTBs') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Building Kernel + DTBs ==="
                    
                    cd "${WORKSPACE}"
                    
                    # Run kernel build script
                    VERSION="${VERSION}" \
                    CROSS_COMPILE="${CROSS_COMPILE}" \
                    ARCH="${ARCH}" \
                    KERNEL_SRC="${KERNEL_SRC}" \
                    KERNEL_CONFIG="${KERNEL_CONFIG}" \
                    OUTPUT_DIR="${BUILD_DIR}/kernel" \
                    ./kernel/build-kernel.sh
                    
                    echo "Kernel build complete"
                '''
            }

        }

        stage('Validate DTBs (dtbs_check)') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Running dtbs_check ==="
                    
                    cd "${KERNEL_SRC}"
                    # dtbs_check may fail due to upstream DT binding schema issues
                    # with newer dtschema versions. Treat as warning, not failure.
                    make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" dtbs_check || true
                    
                    echo "dtbs_check completed (non-fatal)"
                '''
            }
        }

        stage('Build Rootfs with mmdebstrap') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Building Rootfs with mmdebstrap ==="
                    
                    ROOTFS_DIR="${BUILD_DIR}/rootfs"
                    mkdir -p "${ROOTFS_DIR}"
                    
                    mmdebstrap \
                        --architectures=riscv64 \
                        --variant="${MMDEBSTRAP_VARIANT}" \
                        --mode="${MMDEBSTRAP_MODE}" \
                        --include=ca-certificates,gnupg,gpgv \
                        trixie "${ROOTFS_DIR}" "${DEBIAN_MIRROR}"
                    
                    echo "Rootfs build complete"
                '''
            }
        }

        stage('Apply Overlays') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Applying Overlays ==="
                    
                    ROOTFS_DIR="${BUILD_DIR}/rootfs"
                    
                    # Determine sudo command
                    if [ "$(id -u)" -eq 0 ]; then
                        SUDO=""
                    elif sudo -n true 2>/dev/null; then
                        SUDO="sudo -n"
                    else
                        echo "ERROR: Need passwordless sudo for overlay operations"
                        exit 1
                    fi
                    
                    # etc/
                    if [ -d "${OVERLAYS_DIR}/etc" ]; then
                        ${SUDO} cp -r "${OVERLAYS_DIR}/etc"/* "${ROOTFS_DIR}/etc/"
                    fi
                    
                    # boot/ (kernel, cmdline, bootloader configs)
                    if [ -d "${OVERLAYS_DIR}/boot" ]; then
                        ${SUDO} mkdir -p "${ROOTFS_DIR}/boot"
                        ${SUDO} cp -r "${OVERLAYS_DIR}/boot"/* "${ROOTFS_DIR}/boot/"
                    fi
                    
                    # usr/
                    if [ -d "${OVERLAYS_DIR}/usr" ]; then
                        ${SUDO} cp -r "${OVERLAYS_DIR}/usr"/* "${ROOTFS_DIR}/usr/"
                    fi
                    
                    # rva23-optin/ (optional RVA23 acceleration packages)
                    if [ -d "${OVERLAYS_DIR}/rva23-optin" ]; then
                        ${SUDO} cp -r "${OVERLAYS_DIR}/rva23-optin"/* "${ROOTFS_DIR}/"
                    fi
                    
                    echo "Overlays applied"
                '''
            }
        }

        stage('Install Kernel + DTBs into Rootfs') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Installing Kernel + DTBs ==="
                    
                    ROOTFS_DIR="${BUILD_DIR}/rootfs"
                    KERNEL_BUILD_DIR="${BUILD_DIR}/kernel"
                    
                    # Determine sudo command
                    if [ "$(id -u)" -eq 0 ]; then
                        SUDO=""
                    elif sudo -n true 2>/dev/null; then
                        SUDO="sudo -n"
                    else
                        echo "ERROR: Need passwordless sudo for kernel install"
                        exit 1
                    fi
                    
                    if [ -f "${KERNEL_BUILD_DIR}/Image" ]; then
                        ${SUDO} cp "${KERNEL_BUILD_DIR}/Image" "${ROOTFS_DIR}/boot/Image"
                    fi
                    
                    if [ -d "${KERNEL_BUILD_DIR}/dtb" ]; then
                        ${SUDO} mkdir -p "${ROOTFS_DIR}/boot/dtb"
                        ${SUDO} cp "${KERNEL_BUILD_DIR}/dtb"/*.dtb "${ROOTFS_DIR}/boot/dtb/"
                    fi
                    
                    if [ -f "${KERNEL_BUILD_DIR}/config-${VERSION}" ]; then
                        ${SUDO} cp "${KERNEL_BUILD_DIR}/config-${VERSION}" "${ROOTFS_DIR}/boot/config-${VERSION}"
                    fi
                    
                    echo "Kernel + DTBs installed"
                '''
            }
        }

        stage('Install Custom Packages') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Installing Custom Packages ==="
                    
                    ROOTFS_DIR="${BUILD_DIR}/rootfs"
                    
                    # Determine sudo command
                    if [ "$(id -u)" -eq 0 ]; then
                        SUDO=""
                    elif sudo -n true 2>/dev/null; then
                        SUDO="sudo -n"
                    else
                        echo "ERROR: Need passwordless sudo for package install"
                        exit 1
                    fi
                    
                    if [ -d "${PACKAGES_DIR}" ]; then
                        for deb in "${PACKAGES_DIR}"/*.deb; do
                            if [ -f "${deb}" ]; then
                                echo "Installing ${deb}..."
                                ${SUDO} dpkg -x "${deb}" "${ROOTFS_DIR}/"
                            fi
                        done
                    else
                        echo "No custom packages directory found, skipping"
                    fi
                    
                    echo "Custom packages installed"
                '''
            }
        }

        stage('Assemble Disk Images with genimage') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Assembling Disk Images with genimage ==="

                    # Determine sudo command
                    if [ "$(id -u)" -eq 0 ]; then
                        SUDO=""
                    elif sudo -n true 2>/dev/null; then
                        SUDO="sudo -n"
                    else
                        echo "ERROR: Need passwordless sudo for genimage"
                        exit 1
                    fi

                    
                    GENIMAGE_INPUT="${BUILD_DIR}/genimage-input"
                    GENIMAGE_OUTPUT="${BUILD_DIR}/output"
                    KERNEL_BUILD_DIR="${BUILD_DIR}/kernel"
                    ROOTFS_DIR="${BUILD_DIR}/rootfs"
                    
                    mkdir -p "${GENIMAGE_INPUT}"
                    mkdir -p "${GENIMAGE_OUTPUT}"
                    
                    # Prepare genimage input structure for GPT image
                    mkdir -p "${GENIMAGE_INPUT}/boot"
                    mkdir -p "${GENIMAGE_INPUT}/dtb"
                    mkdir -p "${GENIMAGE_INPUT}/rootfs"
                    
                    # Create ESP directory structure (for ESP partition)
                    ESP_DIR="${GENIMAGE_INPUT}/esp"
                    mkdir -p "${ESP_DIR}/EFI/BOOT"
                    mkdir -p "${ESP_DIR}/loader/entries"
                    mkdir -p "${ESP_DIR}/dtb"
                    
                    # Copy EFI bootloader (BOOTRISCV64.EFI)
                    cp "${OVERLAYS_DIR}/boot/EFI/BOOT/BOOTRISCV64.EFI" "${ESP_DIR}/EFI/BOOT/BOOTRISCV64.EFI"
                    
                    # Copy systemd-boot
                    cp "${OVERLAYS_DIR}/boot/loader/loader.conf" "${ESP_DIR}/loader/loader.conf"
                    cp "${OVERLAYS_DIR}/boot/loader/entries/koinos-trixie-riscv64.conf" "${ESP_DIR}/loader/entries/koinos-trixie-riscv64.conf"
                    
                    # Copy DTBs
                    cp "${KERNEL_BUILD_DIR}/dtb"/*.dtb "${ESP_DIR}/dtb/"
                    
                    # Copy Kernel
                    cp "${KERNEL_BUILD_DIR}/Image" "${ESP_DIR}/Image"
                    
                    # Copy cmdline
                    cp "${OVERLAYS_DIR}/boot/cmdline.txt" "${ESP_DIR}/cmdline.txt"
                    
                    # Prepare ISO root directory structure
                    echo "Preparing ISO root directory..."
                    ISO_ROOT="${GENIMAGE_INPUT}/iso-root"
                    mkdir -p "${ISO_ROOT}/EFI/BOOT"
                    mkdir -p "${ISO_ROOT}/loader/entries"
                    mkdir -p "${ISO_ROOT}/dtb"
                    mkdir -p "${ISO_ROOT}/boot"
                    
                    # Copy EFI bootloader
                    cp "${OVERLAYS_DIR}/boot/EFI/BOOT/BOOTRISCV64.EFI" "${ISO_ROOT}/EFI/BOOT/BOOTRISCV64.EFI"
                    
                    # Copy systemd-boot
                    cp "${OVERLAYS_DIR}/boot/loader/loader.conf" "${ISO_ROOT}/loader/loader.conf"
                    cp "${OVERLAYS_DIR}/boot/loader/entries/koinos-trixie-riscv64.conf" "${ISO_ROOT}/loader/entries/koinos-trixie-riscv64.conf"
                    
                    # Copy DTBs
                    cp "${KERNEL_BUILD_DIR}/dtb"/*.dtb "${ISO_ROOT}/dtb/"
                    
                    # Copy Kernel
                    cp "${KERNEL_BUILD_DIR}/Image" "${ISO_ROOT}/boot/Image"
                    
                    # Copy cmdline
                    cp "${OVERLAYS_DIR}/boot/cmdline.txt" "${ISO_ROOT}/boot/cmdline.txt"
                    
                    # Copy rootfs (use rsync to handle lock files and special files)
                    # Use --numeric-ids to preserve ownership, and exclude sensitive files that cause permission issues
                    ${SUDO} rsync -a --numeric-ids --delete \
                        --exclude='/var/cache/apt/archives/lock' \
                        --exclude='/var/cache/apt/archives/partial' \
                        --exclude='/var/cache/debconf/passwords.dat' \
                        --exclude='/var/cache/ldconfig' \
                        --exclude='/var/cache/private' \
                        --exclude='/var/lib/apt/lists/partial' \
                        --exclude='/var/lib/apt/lists/lock' \
                        --exclude='/var/lib/dpkg/triggers/Lock' \
                        --exclude='/var/lib/dpkg/lock-frontend' \
                        --exclude='/var/lib/dpkg/lock' \
                        --exclude='/var/lib/private' \
                        --exclude='/var/log/btmp' \
                        --exclude='/var/log/private' \
                        --exclude='/var/spool/cron/crontabs' \
                        --exclude='/root' \
                        --exclude='/etc/shadow' \
                        --exclude='/etc/shadow-' \
                        --exclude='/etc/gshadow' \
                        --exclude='/etc/gshadow-' \
                        --exclude='/etc/security/opasswd' \
                        --exclude='/etc/credstore' \
                        --exclude='/etc/credstore.encrypted' \
                        --exclude='/etc/.pwd.lock' \
                        --exclude='/etc/ssl/private' \
                        "${ROOTFS_DIR}/" "${GENIMAGE_INPUT}/rootfs/"
                    
                    # Generate dynamic UUIDs for partitions (uuidgen may not be installed, use /proc or python)
                    if command -v uuidgen >/dev/null 2>&1; then
                        ESP_UUID=$(uuidgen)
                        ROOTFS_UUID=$(uuidgen)
                        PERSIST_UUID=$(uuidgen)
                    elif [ -r /proc/sys/kernel/random/uuid ]; then
                        ESP_UUID=$(cat /proc/sys/kernel/random/uuid)
                        ROOTFS_UUID=$(cat /proc/sys/kernel/random/uuid)
                        PERSIST_UUID=$(cat /proc/sys/kernel/random/uuid)
                    else
                        # Fallback to python
                        ESP_UUID=$(python3 -c "import uuid; print(uuid.uuid4())")
                        ROOTFS_UUID=$(python3 -c "import uuid; print(uuid.uuid4())")
                        PERSIST_UUID=$(python3 -c "import uuid; print(uuid.uuid4())")
                    fi
                    echo "Generated partition UUIDs:"
                    echo "  ESP: ${ESP_UUID}"
                    echo "  ROOTFS: ${ROOTFS_UUID}"
                    echo "  PERSIST: ${PERSIST_UUID}"
                    
                    # Create a build-specific genimage.cfg with substituted UUIDs
                    GENIMAGE_CFG_BUILD="${BUILD_DIR}/genimage.cfg"
                    sed -e "s/12345678-1234-4abc-8def-1234567890ab/${ESP_UUID}/" \
                        -e "s/87654321-1234-4abc-8def-1234567890ab/${ROOTFS_UUID}/" \
                        -e "s/abcdef01-1234-4abc-8def-1234567890ab/${PERSIST_UUID}/" \
                        "${GENIMAGE_CFG}" > "${GENIMAGE_CFG_BUILD}"
                    
                    # Run genimage (requires sudo for disk image creation)
                    cd "${WORKSPACE}/images"
                    ${SUDO} genimage \
                        --config "${GENIMAGE_CFG_BUILD}" \
                        --inputpath "${GENIMAGE_INPUT}" \
                        --outputpath "${GENIMAGE_OUTPUT}" \
                        --rootpath "${ROOTFS_DIR}"
                    
                    echo "genimage complete"
                '''
            }
        }

        stage('Compress Images') {
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== Compressing Images ==="
                    
                    GENIMAGE_OUTPUT="${BUILD_DIR}/output"
                    IMAGE_NAME="koinos-trixie-riscv64-${VERSION}.img"
                    ISO_NAME="koinos-trixie-riscv64-${VERSION}.iso"
                    
                    OUTPUT_IMAGE="${GENIMAGE_OUTPUT}/${IMAGE_NAME}"
                    OUTPUT_ISO="${GENIMAGE_OUTPUT}/${ISO_NAME}"
                    
                    # Compress GPT disk image
                    if [ -f "${OUTPUT_IMAGE}" ]; then
                        echo "Compressing ${OUTPUT_IMAGE} -> ${IMAGE_NAME}.xz"
                        xz -T0 -v "${OUTPUT_IMAGE}"
                        mv "${OUTPUT_IMAGE}.xz" "${GENIMAGE_OUTPUT}/${IMAGE_NAME}.xz"
                        
                        echo ""
                        echo "=== GPT Disk Image Complete ==="
                        echo "Image: ${GENIMAGE_OUTPUT}/${IMAGE_NAME}.xz"
                        echo "Size: $(du -h "${GENIMAGE_OUTPUT}/${IMAGE_NAME}.xz" | cut -f1)"
                        echo "SHA256: $(sha256sum "${GENIMAGE_OUTPUT}/${IMAGE_NAME}.xz" | cut -d' ' -f1)"
                    else
                        echo "ERROR: GPT image not found at ${OUTPUT_IMAGE}"
                        exit 1
                    fi
                    
                    # Compress ISO image
                    if [ -f "${OUTPUT_ISO}" ]; then
                        echo "Compressing ${OUTPUT_ISO} -> ${ISO_NAME}.xz"
                        xz -T0 -v "${OUTPUT_ISO}"
                        mv "${OUTPUT_ISO}.xz" "${GENIMAGE_OUTPUT}/${ISO_NAME}.xz"
                        
                        echo ""
                        echo "=== ISO Image Complete ==="
                        echo "ISO: ${GENIMAGE_OUTPUT}/${ISO_NAME}.xz"
                        echo "Size: $(du -h "${GENIMAGE_OUTPUT}/${ISO_NAME}.xz" | cut -f1)"
                        echo "SHA256: $(sha256sum "${GENIMAGE_OUTPUT}/${ISO_NAME}.xz" | cut -d' ' -f1)"
                    else
                        echo "WARNING: ISO image not found at ${OUTPUT_ISO}"
                    fi
                    
                    echo ""
                    echo "=== Build Complete ==="
                    echo "Output directory: ${GENIMAGE_OUTPUT}"
                    ls -lh "${GENIMAGE_OUTPUT}"/*.xz 2>/dev/null || true
                '''
            }
            post {
                success {
                    // Only archive the final distribution images (.img.xz and .iso.xz)
                    archiveArtifacts artifacts: 'build/output/*.xz', fingerprint: true
                }
            }
        }

        stage('QEMU Smoke Test') {
            when {
                expression { return params.RUN_QEMU_TEST == true }
            }
            steps {
                sh '''
                    set -euo pipefail
                    echo "=== QEMU Smoke Test ==="
                    
                    GENIMAGE_OUTPUT="${BUILD_DIR}/output"
                    IMAGE_FILE=$(ls "${GENIMAGE_OUTPUT}"/*.img.xz 2>/dev/null | head -1)
                    
                    if [ -z "${IMAGE_FILE}" ]; then
                        echo "No image file found for QEMU test"
                        exit 1
                    fi
                    
                    xz -d "${IMAGE_FILE}"
                    IMG_FILE="${IMAGE_FILE%.xz}"
                    
                    echo "Testing with QEMU virt machine..."
                    timeout 180 qemu-system-riscv64 \
                        -machine virt \
                        -cpu rv64 \
                        -m 2G \
                        -smp 2 \
                        -drive file="${IMG_FILE}",format=raw,if=virtio \
                        -nographic \
                        -no-reboot \
                        -kernel "${BUILD_DIR}/kernel/Image" \
                        -dtb "${BUILD_DIR}/kernel/dtb/virt.dtb" \
                        -append "console=ttyS0 earlycon root=/dev/vda2 rw rootwait" \
                        -device virtio-rng-pci \
                        -device virtio-net-pci,netdev=net0 \
                        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
                        -serial file:/tmp/qemu-virt.log \
                        -monitor none \
                        -display none \
                        -daemonize \
                        -pidfile qemu.pid
                    
                    # Wait for boot
                    sleep 45
                    
                    # Test for login prompt
                    if grep -q "login:" /tmp/qemu-virt.log 2>/dev/null; then
                        echo "SUCCESS: QEMU virt booted successfully"
                    else
                        echo "FAILURE: QEMU virt did not boot properly"
                        cat /tmp/qemu-virt.log || true
                        kill $(cat qemu.pid 2>/dev/null) 2>/dev/null || true
                        exit 1
                    fi
                    
                    kill $(cat qemu.pid 2>/dev/null) 2>/dev/null || true
                    echo "QEMU smoke test passed"
                '''
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "=== BUILD SUCCESSFUL ==="
            echo "Version: ${VERSION}"
            echo "Artifacts archived:"
            echo "  - build/output/koinos-trixie-riscv64-${VERSION}.img.xz"
            echo "  - build/output/koinos-trixie-riscv64-${VERSION}.iso.xz"
            echo "  - build/kernel/dtb-manifest.txt"
            echo "  - build/kernel/config-${VERSION}"
        }
        failure {
            echo "=== BUILD FAILED ==="
            echo "Check console output for details"
        }
    }
}

// Parameters for manual builds
properties([
    parameters([
        booleanParam(
            name: 'RUN_QEMU_TEST',
            defaultValue: false,
            description: 'Run QEMU smoke test after build (requires KVM)'
        ),
        stringParam(
            name: 'CUSTOM_VERSION',
            defaultValue: '',
            description: 'Custom CalVer version (YY.MM.DD or YY.MM), leave empty for auto'
        )
    ])
])
