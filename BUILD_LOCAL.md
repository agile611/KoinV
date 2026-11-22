# Building KoinV Locally on macOS

This guide covers building KoinV RISC-V disk images locally on macOS (Apple Silicon or Intel).

## Prerequisites

### 1. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Required Tools
```bash
brew install \
  qemu \
  mmdebstrap \
  genimage \
  dtc \
  xz \
  gmake \
  coreutils \
  gnu-sed \
  gnu-tar \
  grep \
  findutils \
  git
```

**Note**: `riscv64-elf-gcc` is NOT suitable for Linux kernel/userspace builds. You need `riscv64-linux-gnu-gcc` which is not available via Homebrew. Use the Lima VM approach below.

### 3. Install Lima VM (Required for mmdebstrap)
`mmdebstrap --mode=unshare` requires Linux namespaces, not available natively on macOS.

```bash
brew install lima
limactl start template://debian
# Wait for VM to boot (first run downloads ~322MB Debian cloud image)
# Lima creates a Debian 13 Trixie arm64 VM with VZ driver
```

## Native macOS Build (Partial - Kernel + QEMU Tests Only)

The following steps work natively on macOS without Lima/Docker:

### 1. Kernel Cross-Compilation (Native)
```bash
cd kernel
VERSION=$(date -u +"%y.%m.%d") ./build-kernel.sh
```
- Uses `riscv64-linux-gnu-` cross-compiler (must be available in PATH)
- Produces `Image` and `*.dtb` files
- Runs `dtbs_check` validation (requires `python3-dtschema`)

### 2. QEMU Smoke Tests (Native)
```bash
# Test virt machine (requires kernel + DTB)
qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -smp 2 \
  -kernel build/kernel/Image -dtb build/kernel/dtb/virt.dtb \
  -append "console=ttyS0 earlycon root=/dev/vda2 rw rootwait" \
  -nographic -no-reboot

# Test with fw_jump.bin (OpenSBI)
qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -smp 2 \
  -bios /opt/homebrew/Cellar/qemu/10.0.13/share/qemu/opensbi-riscv64-generic-fw_jump.bin \
  -kernel build/kernel/Image \
  -append "console=ttyS0,115200 earlycon=sbi root=/dev/vda2 rw rootwait" \
  -drive file=koinv-test.img,format=raw,if=virtio \
  -nographic -no-reboot
```

### 3. genimage Assembly (Native)
```bash
cd images
./build-image.sh
```
- `genimage` runs natively on macOS
- Creates GPT disk image with ESP, rootfs, persist partitions
- Creates ISO image with El Torito boot support

## Full Build with Lima VM (Recommended - Complete Build)

For complete build including `mmdebstrap --mode=unshare` and full userspace:

### 1. Start Lima VM
```bash
limactl start template://debian
# First run: downloads ~322MB Debian 13 Trixie arm64 cloud image
# Creates VM with 100GB disk, VZ driver (Apple Silicon)
```

### 2. Copy Project to Lima
```bash
limactl copy /Users/guillem/code/KoinV lima:/home/guillem/KoinV
```

### 3. Install Build Dependencies Inside Lima
```bash
lima shell --workdir=/home/guillem/KoinV bash -c "
  sudo apt-get update && sudo apt-get install -y \
    mmdebstrap genimage qemu-user-static binfmt-support \
    device-tree-compiler gcc-riscv64-linux-gnu xz-utils cpio kmod \
    python3-pip
  
  # Install dtschema for dtbs_check
  pip3 install --break-system-packages dtschema
  export PATH=\$PATH:~/.local/bin
"
```

### 4. Build Kernel Inside Lima
```bash
lima shell --workdir=/home/guillem/KoinV/kernel bash -c "
  export PATH=\$PATH:~/.local/bin
  VERSION=$(date -u +%y.%m.%d) ./build-kernel.sh
"
```

### 5. Full Image Build Inside Lima
```bash
lima shell --workdir=/home/guillem/KoinV/images bash -c "
  export PATH=\$PATH:~/.local/bin
  sudo -E PATH=\$PATH MMDEBSTRAP_MODE=root VERSION=$(date -u +%y.%m.%d) ./build-image.sh
"
```

### 6. Copy Results Back to macOS
```bash
limactl copy lima:/home/guillem/KoinV/build/output/koinv-trixie-riscv64-*.img.xz ~/Downloads/
limactl copy lima:/home/guillem/KoinV/build/output/koinv-trixie-riscv64-*.iso.xz ~/Downloads/
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VERSION` | `date -u +"%y.%m.%d"` | CalVer version for artifacts |
| `ARCH` | `riscv64` | Target architecture |
| `CROSS_COMPILE` | `riscv64-linux-gnu-` | Cross-compiler prefix (NOT `riscv64-elf-`) |
| `MMDEBSTRAP_MODE` | `auto` (detects CI) | `root` for CI/Lima, `unshare` for local Linux |
| `MMDEBSTRAP_VARIANT` | `important` | Debian package variant |
| `DEBIAN_MIRROR` | `http://deb.debian.org/debian` | Debian mirror URL |
| `JOBS` | `$(nproc)` | Parallel build jobs |

## Verification Checklist

After building, verify:

- [ ] Kernel `Image` builds successfully
- [ ] All DTBs generated (`ls build/kernel/dtb/ | wc -l` ≥ 8)
- [ ] `dtbs_check` passes (run in Lima/Docker)
- [ ] QEMU `virt` boots to OpenSBI prompt
- [ ] QEMU `virt` with disk image detects virtio block
- [ ] `genimage` produces valid `.img` file
- [ ] `xz` compression works
- [ ] Image file has correct GPT partitions (`fdisk -l image.img`)

## Troubleshooting

### `make` version error
macOS default `make` is 3.81. Use `gmake` (GNU Make 4.x from Homebrew):
```bash
alias make=gmake
# or
export MAKE=gmake
```

### `mmdebstrap --mode=unshare` fails
Use Lima VM or Docker as described above. Native macOS lacks Linux namespaces.

### `qemu-system-riscv64` not found
```bash
brew install qemu
```

### `dtc` not found
```bash
brew install dtc
```

### Cross-compiler issues
**Critical**: Use `riscv64-linux-gnu-gcc` (NOT `riscv64-elf-gcc`) for Linux kernel/userspace builds.
- `riscv64-elf-gcc` is for bare-metal/RTOS
- `riscv64-linux-gnu-gcc` is for Linux userspace
- Install via Lima VM: `sudo apt-get install gcc-riscv64-linux-gnu`

### `dtbs_check` fails with schema errors
Install `python3-dtschema`:
```bash
# In Lima VM
pip3 install --break-system-packages dtschema
export PATH=$PATH:~/.local/bin
```

### Lima VM disk space issues
```bash
# Check disk space
limactl shell debian df -h

# Clean apt cache
limactl shell debian sudo apt-get clean

# Remove old build directories
limactl shell debian sudo rm -rf /home/guillem/KoinV/build
```

### Lima VM network/port conflicts
```bash
# Restart Lima VM
limactl stop debian && limactl start debian

# Or recreate
limactl delete debian && limactl start template://debian
```

## Successful Build Reference (CalVer 26.11.20)

### Build Artifacts
| Artifact | Size (compressed) | SHA256 |
|----------|-------------------|--------|
| `koinv-trixie-riscv64-26.11.20.img.xz` | 123.6 MB | `9fe4368b2f2ba5a95afcc03cd35092256b9283c89fd2dd708fffdec26f7035e2` |

### Disk Image Partition Layout
| Partition | Size | Type | Label |
|-----------|------|------|-------|
| 1 (ESP) | 512 MB | EFI System (FAT32) | EFI System |
| 2 (Rootfs) | 862.9 MB | Linux filesystem (ext4) | Linux filesystem |
| 3 (Persist) | 4 GB | Linux filesystem (ext4) | Linux filesystem |

### Build Environment
- **Host**: macOS (Apple Silicon M1) via **Lima VM** (Debian 13 Trixie arm64)
- **Lima VM**: `limactl start template://debian` (VZ driver, 100 GB disk)
- **Build tools**: `mmdebstrap --mode=root`, `genimage`, `dtc`, `gcc-riscv64-linux-gnu`, `qemu-system-riscv64`
- **Kernel**: Linux 6.6.58 with CalVer `26.11.20` (`LOCALVERSION=-koinv-26.11.20`)

### Kernel Configuration Highlights
- **All 4 critical errata families enabled**:
  - T-Head: `ERRATA_THEAD_MAE`, `ERRATA_THEAD_CMO`, `ERRATA_THEAD_PMU`
  - SiFive: `ERRATA_SIFIVE_CIP_453`, `ERRATA_SIFIVE_CIP_1200`
  - StarFive JH7100: non-coherent DMA errata
  - Andes: `ERRATA_ANDES_CMO` (Renesas RZ/Five)
- **8 DTBs built and validated** via `make dtbs_check` (with `python3-dtschema`)
- **VirtIO MMIO cmdline devices** enabled for QEMU virt platform
- **Serial console**: 8250 DW support for earlycon=sbi
- **VirtIO block** and **ext4** filesystem support
- **Flexible MMU paging**: Sv39 / Sv48 / Sv57 with `no5lvl` / `no4lvl` fallbacks

### QEMU Smoke Test Results
| Test | Command | Result |
|------|---------|--------|
| **Kernel boot (no DTB)** | `qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -smp 2 -kernel Image -append 'console=ttyS0,115200 earlycon=sbi' -nographic` | ✅ OpenSBI → kernel boots |
| **Kernel + disk image** | `qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -smp 2 -bios fw_jump.bin -kernel Image -append 'console=ttyS0,115200 earlycon=sbi root=/dev/vda2 rw rootwait' -drive file=koinv.img,format=raw,if=virtio -nographic` | ✅ OpenSBI → kernel boots, detects virtio block |
| **Kernel + DTB + disk** | `qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -smp 2 -bios fw_jump.bin -kernel Image -dtb virt.dtb -append 'console=ttyS0,115200 earlycon=sbi root=/dev/vda2 rw rootwait' -drive file=koinv.img,format=raw,if=virtio -nographic` | ✅ Full boot with DTB |

## Resources

- [Lima VM Documentation](https://lima-vm.io/docs/)
- [mmdebstrap Manual](https://manpages.debian.org/testing/mmdebstrap/mmdebstrap.1.en.html)
- [genimage Documentation](https://github.com/genimage/genimage)
- [QEMU RISC-V Documentation](https://www.qemu.org/docs/master/system/target/riscv.html)
- [Debian RISC-V Port](https://wiki.debian.org/RISC-V)
