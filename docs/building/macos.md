# Building Agile611 Koinos RISC-V on macOS

This guide covers building Agile611 Koinos RISC-V RISC-V disk images on macOS (Apple Silicon and Intel).

## Prerequisites

### 1. Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Required Tools
```bash
brew install \
  qemu \
  riscv64-elf-gcc \
  mmdebstrap \
  genimage \
  dtc \
  xz \
  gmake \
  coreutils \
  gnu-sed \
  gnu-tar \
  grep \
  findutils
```

### 3. Lima VM (for mmdebstrap --mode=unshare)
`mmdebstrap --mode=unshare` requires Linux kernel namespaces (user, mount, pid), which are not available natively on macOS.

```bash
brew install lima
limactl start template://debian
# Wait for VM to boot, then:
lima shell
# Inside Lima VM, you have full Linux environment
```

**Alternative: Docker**
```bash
# Run build inside Docker container
docker run --rm --privileged -v $(pwd):/work debian:trixie bash -c "
  apt-get update && apt-get install -y mmdebstrap genimage qemu-user-static binfmt-support
  cd /work && ./images/build-image.sh
"
```

## Native macOS Build (Partial)

The following steps work natively on macOS without Lima/Docker:

### 1. Kernel Cross-Compilation
```bash
cd kernel
VERSION=$(date -u +"%y.%m.%d") ./build-kernel.sh
```
- Uses `riscv64-elf-gcc` from Homebrew
- Produces `Image` and `*.dtb` files
- Runs `dtbs_check` validation

### 2. QEMU Smoke Tests
```bash
# Test virt machine
qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -smp 2 \
  -kernel build/kernel/Image -dtb build/kernel/dtb/virt.dtb \
  -append "console=ttyS0 earlycon root=/dev/vda2 rw rootwait" \
  -nographic -no-reboot

# Test sifive_u machine
qemu-system-riscv64 -machine sifive_u -cpu rv64 -m 2G -smp 2 \
  -kernel build/kernel/Image -dtb build/kernel/dtb/sifive_u.dtb \
  -append "console=ttyS0 earlycon root=/dev/vda2 rw rootwait" \
  -nographic -no-reboot
```

### 3. genimage Assembly
```bash
cd images
./build-image.sh
```
- `genimage` runs natively on macOS
- Creates GPT disk image with ESP, rootfs, persist partitions

## Full Build with Lima VM (Recommended)

For complete build including `mmdebstrap --mode=unshare`:

```bash
# 1. Start Lima VM
limactl start template://debian

# 2. Copy project to Lima
limactl copy /Users/guillem/code/Agile611 Koinos RISC-V lima:/home/guillem/Agile611 Koinos RISC-V

# 3. Run build inside Lima
lima shell --workdir=/home/guillem/Agile611 Koinos RISC-V bash -c "
  sudo apt-get update && sudo apt-get install -y \
    mmdebstrap genimage qemu-user-static binfmt-support \
    device-tree-compiler gcc-riscv64-linux-gnu xz-utils cpio kmod
  
  # Build kernel (can also be done on host)
  cd kernel && VERSION=$(date -u +%y.%m.%d) ./build-kernel.sh
  
  # Full image build
  cd images && VERSION=$(date -u +%y.%m.%d) ./build-image.sh
"

# 4. Copy result back
limactl copy lima:/home/guillem/Agile611 Koinos RISC-V/build/output/koinos-trixie-riscv64-*.img.xz ~/Downloads/
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VERSION` | `date -u +"%y.%m.%d"` | CalVer version for artifacts |
| `ARCH` | `riscv64` | Target architecture |
| `CROSS_COMPILE` | `riscv64-elf-` | Cross-compiler prefix |
| `MMDEBSTRAP_MODE` | `unshare` | mmdebstrap isolation mode |
| `MMDEBSTRAP_VARIANT` | `important` | Debian package variant |
| `DEBIAN_MIRROR` | `http://deb.debian.org/debian` | Debian mirror URL |
| `JOBS` | `$(sysctl -n hw.ncpu)` | Parallel build jobs |

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
Use `riscv64-elf-gcc` from Homebrew for bare-metal/kernel builds. For userspace, you need `riscv64-linux-gnu-gcc` which may require building from source or using a Docker image.

## CI/CD on macOS

GitHub Actions runners are Linux-based. For macOS-specific testing, use:
```yaml
jobs:
  macos-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install tools
        run: brew install qemu riscv64-elf-gcc gmake
      - name: Test kernel build
        run: cd kernel && ./build-kernel.sh
      - name: Test QEMU
        run: qemu-system-riscv64 -machine virt -kernel build/kernel/Image ...
```

## Known Limitations on macOS

| Feature | Status | Workaround |
|---------|--------|------------|
| `mmdebstrap --mode=unshare` | ❌ Not supported | Use Lima VM or Docker |
| `binfmt-support` / `qemu-user-static` | ❌ Not supported | Use Lima VM or Docker |
| `riscv64-linux-gnu-gcc` (userspace) | ⚠️ Not in Homebrew | Build from source or use Docker |
| `genimage` | ✅ Native | Works |
| `qemu-system-riscv64` | ✅ Native | Works |
| Kernel cross-compile | ✅ Native | Works with `riscv64-elf-gcc` |
| `dtbs_check` | ✅ Native | Works |

## Verification Checklist

After building on macOS, verify:

- [ ] Kernel `Image` builds successfully
- [ ] All DTBs generated (`ls build/kernel/dtb/ | wc -l` > 100)
- [ ] `dtbs_check` passes (run in Lima/Docker)
- [ ] QEMU `virt` boots to login prompt
- [ ] QEMU `sifive_u` boots to login prompt
- [ ] `genimage` produces valid `.img` file
- [ ] `xz` compression works
- [ ] Image file has correct GPT partitions (`fdisk -l image.img`)

## Resources

- [Lima VM Documentation](https://lima-vm.io/docs/)
- [mmdebstrap Manual](https://manpages.debian.org/testing/mmdebstrap/mmdebstrap.1.en.html)
- [genimage Documentation](https://github.com/genimage/genimage)
- [QEMU RISC-V Documentation](https://www.qemu.org/docs/master/system/target/riscv.html)
- [Debian RISC-V Port](https://wiki.debian.org/RISC-V)
