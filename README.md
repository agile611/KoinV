# Agile611 Koinos RISC-V Linux

**Agile611 Koinos RISC-V** (*koinós*) is a modern `riscv64` Linux distribution built on **Debian 13 ("Trixie")**, designed around a shared foundation for maximum RISC-V board and Device Tree compatibility.

---

## Why Agile611 Koinos RISC-V?

The RISC-V ecosystem spans many SoCs, firmware generations, and ISA profiles. Agile611 Koinos RISC-V aims to give you a **Debian-compatible** system that:

- **Preserves broad hardware compatibility:** Uses `RV64GC` as its baseline user space so existing pre-RVA23 `riscv64` boards continue to boot cleanly alongside newer hardware.
- **Accelerates modern silicon at runtime:** Uses `glibc-hwcaps` (via kernel `hwprobe`) and `IFUNC` dispatch for optimized routines on capable CPUs (such as RVV / RVA23) without forcing an incompatible global ISA floor.
- **Unifies booting and Device Trees:** Targets UEFI boot (`systemd-boot` or `GRUB2`) with `u-boot-efi-dtb` to keep Device Trees aligned with installed kernels, while retaining `u-boot-menu` (`extlinux`) fallback support for legacy or non-UEFI U-Boot builds.
- **Combines mainline and SoC support:** Ships a unified kernel with silicon errata enabled, paired with optional BSP/firmware packages (inspired by the RevyOS approach) for boards whose drivers or Device Trees are still landing upstream.

---

## Architecture & Compatibility Strategy

### ISA Baseline: RV64GC (RVA20)

Agile611 Koinos RISC-V compiles its base user space for **RV64GC** (the `RVA20` profile), matching Debian 13 "Trixie" and ensuring binaries run on pre-2026 boards such as:

- VisionFive 2 (JH7110)
- Milk-V Mars (JH7110)
- Star64 (JH7110)
- Lichee Pi 4A (TH1520)
- Allwinner D1 / D1s
- Milk-V Pioneer (SG2042)

This avoids the fragmentation caused by distributions that mandate RVA23 (e.g., Ubuntu 25.10+), which would leave these boards unable to run the user space.

### Runtime Acceleration: glibc-hwcaps + hwprobe + IFUNC

On RVA23-capable hardware (SpacemiT K3, future RVA23 servers), Agile611 Koinos RISC-V leverages:

| Mechanism | Purpose |
|-----------|---------|
| **glibc-hwcaps** | Dynamic loading of optimized shared libraries (`openssl`, `libgcrypt`, `libjpeg-turbo`) when `hwprobe` reports RVA23U64 support |
| **IFUNC resolvers** | Per-function runtime selection of RVV 1.0 vectorized routines via `RISCV_HWPROBE_KEY_IMA_EXT_0` |
| **Optional RVA23 overlay** | Separate opt-in repository compiled with `rva23_defconfig` / `-march=rva23u64` for whole-system optimization |

This provides **performance on new silicon without breaking old silicon**.

### Kernel Strategy: Unified Mainline + Modular BSP Layer

- **Single kernel image** (`linux-image-riscv64`) compiling all available `.dtb` files
- **Mandatory errata enabled** in `arch/riscv/Kconfig.errata`:
  - T-Head: `ERRATA_THEAD_MAE`, `ERRATA_THEAD_CMO`, `ERRATA_THEAD_PMU`
  - SiFive: `ERRATA_SIFIVE_CIP_453`, `ERRATA_SIFIVE_CIP_1200`
  - StarFive JH7100: non-coherent DMA errata
  - Andes: `ERRATA_ANDES_CMO` (Renesas RZ/Five)
- **Modular BSP packages** (RevyOS model): SoC-specific kernel/firmware packages (TH1520, SG2042, etc.) alongside mainline kernel
- **Flexible MMU paging**: Sv39 / Sv48 / Sv57 with `no5lvl` (force Sv48) and `no4lvl` (force Sv39) kernel cmdline fallbacks

### Boot Chain: UEFI-First with Fallback

```
M-Mode BootROM → SPL (FSBL) → FIT (OpenSBI PLATFORM=generic + U-Boot S-Mode) → Linux + DTB
```

| Path | Components | Use Case |
|------|------------|----------|
| **Primary (UEFI)** | OpenSBI generic + U-Boot OF_UPSTREAM → `EFI/BOOT/BOOTRISCV64.EFI` → `systemd-boot` (UKIs) or `GRUB2` + `u-boot-efi-dtb` + ACPI | Modern boards, BRS servers |
| **Fallback (non-UEFI)** | `u-boot-menu` (auto-generates `extlinux.conf`) + `flash-kernel` | Legacy vendor U-Boot, no UEFI |

---

## Target Hardware & Scope

| Tier | Boards / Profiles | Support Approach |
|------|-------------------|------------------|
| **Tier 1: SBCs & Dev Boards (512 MB+ RAM)** | StarFive JH7110 (VisionFive 2, Milk-V Mars, Star64, PineTab-V), SpacemiT K1/M1/K3 (Banana Pi BPI-F3, Lichee Pi 3A, OrangePi RV2, DC-ROMA), T-Head TH1520 (Lichee Pi 4A, BeagleV-Ahead, Milk-V Meles), SiFive FU740 (HiFive Unmatched), Sophgo SG2042 (Milk-V Pioneer) | Primary target — full `riscv64` Debian 13 user space + unified/BSP kernel |
| **Tier 2: Workstations & Servers** | Sophgo SG2044, BRS-aligned RVA23 platforms, SpacemiT K3 CoM260 TQ, DeepComputing Mainboard III, C2201 dual-socket V100 | UEFI + FDT/ACPI support |
| **Tier 3: Low-RAM MMU Boards (64–256 MB)** | Allwinner D1/D1s (MangoPi MQ Pro, Lichee RV Dock), Sophgo CV1800B/SG200x (Milk-V Duo 64M/256M, LicheeRV Nano) | Separate minimal/non-systemd variant (musl + BusyBox/Buildroot, 5–50 MB) sharing kernel & DTBs |
| **Tier 4: 32-bit / No-MMU MCUs** | WCH QingKe, Espressif ESP32, GigaDevice GD32VF103, Bouffalo Lab, others | **Out of scope** — Agile611 Koinos RISC-V targets `riscv64` Linux only |

> **Note**: The 11 silicon families in mainline Linux (`allwinner/`, `andes/`, `canaan/`, `eswin/`, `microchip/`, `renesas/`, `sifive/`, `sophgo/`, `spacemit/`, `starfive/`, `thead/`) are all tracked. Vendor BSP forks (`revyos/th1520-linux-kernel`, `linux4microchip`, `spacemit-com`, `starfive-tech`, `riscv/meta-riscv`) provide early support for boards not yet upstreamed.

---

## Quick Start

### 1. Download Artifacts

**From Jenkins (latest successful build):**
```bash
# GPT disk image (for SD/NVMe/eMMC)
wget https://jenkins.tatsukai.com/job/Koinos-Release/lastSuccessfulBuild/artifact/build/output/koinos-trixie-riscv64-*.img.xz

# ISO image (for USB/DVD boot)
wget https://jenkins.tatsukai.com/job/Koinos-Release/lastSuccessfulBuild/artifact/build/output/koinos-trixie-riscv64-*.iso.xz

# Uncompressed ISO (ready to burn)
wget https://jenkins.tatsukai.com/job/Koinos-Release/lastSuccessfulBuild/artifact/build/output/koinos-trixie-riscv64-*.iso
```

### 2. Flash the Image

```bash
# Decompress and write to target media (SD card, NVMe, or eMMC)
xz -d koinos-trixie-riscv64.img.xz
sudo dd if=koinos-trixie-riscv64.img of=/dev/sdX bs=4M status=progress conv=fsync
```

> **Replace `/dev/sdX`** with your actual target device (e.g., `/dev/mmcblk0`, `/dev/nvme0n1`). **Double-check** — `dd` is destructive.

### 3. Burn ISO to USB

```bash
# Decompress ISO if needed
xz -d koinos-trixie-riscv64.iso.xz

# Burn to USB
sudo dd if=koinos-trixie-riscv64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

### 4. Connect Serial Console

Most RISC-V boards expose a UART for early boot debugging:

```
Baud: 115200
Data bits: 8
Parity: None
Stop bits: 1
Flow control: None
```

You will see: **OpenSBI → U-Boot → systemd-boot/GRUB2 → Linux kernel → systemd**

### 5. Paging Fallback (If Needed)

If a board, emulator, or runtime struggles with 5-level paging (`Sv57`), append to kernel command line:

| Parameter | Effect |
|-----------|--------|
| `no5lvl` | Forces 4-level paging (Sv48, 48-bit VA) |
| `no4lvl` | Forces 3-level paging (Sv39, 39-bit VA) |

In `systemd-boot`: edit the entry at boot or modify `/boot/loader/entries/*.conf`.
In `GRUB2`: edit `/boot/grub/grub.cfg` or use `grub-editenv`.
In `extlinux`: edit `/boot/extlinux/extlinux.conf`.

---

## Repository Structure

```
koinos/
├── profiles/           # mmdebstrap package lists and build profiles
│   ├── base.trixie     # Minimal important packages
│   ├── desktop.trixie  # Desktop environment profile
│   └── server.trixie   # Server/headless profile
├── overlays/           # Base files, APT sources/pinning, boot hooks
│   ├── etc/            # /etc overlays (apt, systemd, network)
│   ├── boot/           # Bootloader configs, kernel cmdline snippets
│   │   ├── EFI/BOOT/BOOTRISCV64.EFI
│   │   ├── loader/loader.conf
│   │   ├── loader/entries/koinos-trixie-riscv64.conf
│   │   ├── cmdline.txt
│   │   └── grub/grub.cfg
│   ├── usr/            # /usr/local scripts, hwcaps helpers
│   │   └── local/bin/koinos-hwcaps-detect
│   └── rva23-optin/    # Optional RVA23 acceleration packages
├── packages/           # Custom .deb recipes (base-files, boot, hwcaps, bsp)
│   ├── koinos-base-files/
│   ├── koinos-boot/
│   ├── koinos-hwcaps/
│   └── koinos-bsp-*/
├── kernel/             # Kernel configs, DTB notes, and BSP patches
│   ├── config.trixie   # Base kernel config (defconfig + errata)
│   ├── config.bsp-*/   # BSP-specific kernel configs
│   └── patches/        # BSP patches not yet upstreamed
│   ├── build-kernel.sh # Kernel build script with dtbs_check
│   └── src/            # Linux kernel source (cloned at build time)
├── images/             # genimage configs and image assembly scripts
│   ├── genimage.cfg    # Partition layout, bootloader placement
│   └── build-image.sh  # Orchestration script
├── bsp/                # Board Support Package definitions
│   ├── th1520/
│   ├── jh7110/
│   ├── sg2042/
│   └── spacemit-k3/
├── docs/               # Documentation
│   ├── boards/         # Per-board flashing/DTB notes
│   ├── architecture/   # Architecture decision records
│   └── contributing/   # Contribution guides
├── tests/              # Validation scripts
│   ├── qemu-smoke.sh   # QEMU boot test
│   ├── dtbs-check.sh   # make dtbs_check wrapper
│   ├── hwcaps-verify.sh # Runtime hwcaps verification
│   ├── test-iso-debian.sh # ISO test suite for Debian agents
│   └── test-iso-macos.sh  # ISO test suite for macOS (Apple Silicon)
├── speckit/            # Spec Kit specification artifacts (versioned)
│   ├── current -> 26.11.20    # Symlink to latest version
│   ├── 26.11.20/             # CalVer daily build snapshot
│   │   ├── constitution.md   # Core engineering principles
│   │   ├── spec.md           # Formal specification
│   │   ├── clarifications.md # Resolved ambiguities
│   │   ├── SPECKIT_PROCESS.md # Workflow documentation
│   │   └── VERSION_MANIFEST.md # Traceability manifest
│   ├── KoinV_Initial_Requeriments.pdf
│   ├── pdf_content.txt
│   └── pdf_requirements.txt
├── constitution.md     # Core engineering principles (symlink to speckit/current/constitution.md)
├── LICENSE.md          # MIT License
├── SPECKIT_PROCESS.md  # Spec Kit workflow documentation (symlink to speckit/current/SPECKIT_PROCESS.md)
├── Jenkinsfile         # Jenkins CI pipeline
├── .github/
│   └── workflows/
│       └── build.yml   # GitHub Actions CI pipeline
└── README.md           # This file
```

> **Note**: `constitution.md`, `spec.md`, `clarifications.md`, and `SPECKIT_PROCESS.md` are maintained in the versioned `speckit/26.11.20/` directory per CalVer. Root-level symlinks point to `speckit/current/` for convenience.

---

## Building an Image

### Host Requirements

- **Build host**: `x86_64` or `aarch64` Linux
- **Tools**: `mmdebstrap`, `genimage`, `qemu-user-static`, `binfmt-support`, `dtc`, `riscv64-linux-gnu-gcc`
- **Debian/Ubuntu host**:
  ```bash
  sudo apt update && sudo apt install -y \
    mmdebstrap genimage qemu-user-static binfmt-support \
    device-tree-compiler gcc-riscv64-linux-gnu
  ```
- **macOS host** (via Homebrew + Lima/Docker):
  ```bash
  brew install qemu riscv64-elf-gcc mmdebstrap genimage dtc xz
  # mmdebstrap --mode=unshare requires Linux namespaces:
  # Use Lima VM: limactl start template://debian
  # Or Docker: docker run --privileged --rm -v $(pwd):/work debian:trixie
  ```

### Build Commands

```bash
# 1. Build base Debian 13 (trixie) riscv64 rootfs
mmdebstrap \
  --architectures=riscv64 \
  --variant=important \
  --mode=unshare \
  trixie ./build/koinos-trixie-riscv64.tar \
  http://deb.debian.org/debian

# 2. Apply overlays (boot configs, hwcaps, APT pinning)
tar -C ./build/koinos-trixie-riscv64 -xf ./overlays/boot/boot-overlay.tar
tar -C ./build/koinos-trixie-riscv64 -xf ./overlays/etc/etc-overlay.tar

# 3. Install custom packages (base-files, boot, hwcaps, BSP)
# (Build .debs from packages/ first, then install into rootfs)
for deb in ./packages/*.deb; do
  dpkg -x "$deb" ./build/koinos-trixie-riscv64/
done

# 4. Build kernel + DTBs (cross-compiled)
cd ./kernel
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig
make -j$(nproc) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- Image dtbs
make dtbs_check  # Validate against DT-Schema
cp arch/riscv/boot/Image ./build/koinos-trixie-riscv64/boot/
cp arch/riscv/boot/dts/*.dtb ./build/koinos-trixie-riscv64/boot/dtb/

# 5. Assemble final disk image with genimage
cd ./images
genimage --config genimage.cfg --inputpath ../build/koinos-trixie-riscv64 --outputpath ../output/

# 6. Compress for distribution
xz -T0 ../output/koinos-trixie-riscv64.img
```

> See `images/genimage.cfg` for partition layout (EFI system partition, rootfs, optional persistent data) and bootloader placement.

---

## Jenkins CI Pipeline

The project uses a **Jenkins declarative pipeline** (`Jenkinsfile`) that runs on a Debian 13 agent with `riscv64-build` label.

### Pipeline Stages

| Stage | Description |
|-------|-------------|
| **Setup Environment** | Verify Debian 13, create build dirs, check tools |
| **Setup binfmt for QEMU** | Register `qemu-riscv64` for cross-architecture execution |
| **Install Dependencies** | Install build tools, cross-compiler, `dtschema` |
| **Clone Linux Kernel Source** | Clone Linux 6.6.58 from kernel.org |
| **Build Kernel + DTBs** | Cross-compile kernel Image + DTBs via `kernel/build-kernel.sh` |
| **Validate DTBs** | Run `dtbs_check` (optional, disabled by default due to dtschema drift) |
| **Build Rootfs** | `mmdebstrap` Debian 13 riscv64 rootfs |
| **Apply Overlays** | Copy `/etc`, `/boot`, `/usr` overlays |
| **Install Kernel + DTBs** | Copy kernel Image, DTBs, config to rootfs |
| **Install Custom Packages** | Extract `.deb` packages into rootfs |
| **Assemble Disk Images** | `genimage` creates GPT `.img` and ISO `.iso` |
| **Compress Images** | `xz -k` creates `.xz` archives, keeps uncompressed files |
| **QEMU Smoke Test** | Optional: boot test on `virt` and `sifive_u` machines |

### Key Pipeline Features

- **Dynamic UUID generation**: Partition UUIDs generated at build time via `uuidgen`/`/proc/sys/kernel/random/uuid`/Python fallback
- **Parallel artifact handling**: `esp`, `rootfs`, `iso-root` directories copied to working directory for `genimage`
- **Artifact archiving**: All four artifacts archived:
  - `koinos-trixie-riscv64-<VERSION>.img.xz` (compressed GPT)
  - `koinos-trixie-riscv64-<VERSION>.iso.xz` (compressed ISO)
  - `koinos-trixie-riscv64-<VERSION>.img` (uncompressed GPT)
  - `koinos-trixie-riscv64-<VERSION>.iso` (uncompressed ISO, ready to burn)
- **dtbs_check optional**: Disabled by default due to dtschema 2026.9+ incompatibility with Linux 6.6; enable with `RUN_DTBS_CHECK=1`

### GitHub Actions

Parallel CI via `.github/workflows/build.yml`:
- Runs on `ubuntu-26.04`
- Same stages as Jenkins
- Optional `dtbs_check` via `workflow_dispatch` input `run_dtbs_check`
- Monthly releases on `YY.MM` tags
- Daily CalVer tags on `main` branch

---

## Test Scripts

### Debian Agent Test Suite

```bash
# Run full test suite on Jenkins agent
./tests/test-iso-debian.sh
```

**Features:**
- Downloads ISO, kernel, DTB from Jenkins
- Test 1: UEFI boot (OpenSBI + systemd-boot)
- Test 2: Direct kernel boot with ISO as rootfs
- Checks for login prompt in QEMU serial output

### macOS (Apple Silicon) Test Suite

```bash
# Install QEMU first
brew install qemu

# Run tests
./tests/test-iso-macos.sh
```

**Features:**
- Finds OpenSBI firmware from Homebrew qemu installation
- Test 1: Direct kernel boot with ISO as rootfs (primary)
- Test 2: UEFI boot (optional, may fail without proper firmware)
- Handles TCG emulation performance on Apple Silicon

---

## Latest Build (CalVer 26.11.25)

### Build Artifacts

| Artifact | Size | SHA256 |
|----------|------|--------|
| `koinos-trixie-riscv64-26.11.25.img.xz` | 119 MB | `3b0306da141059b64841f9a372e0573595f4ac870c341255935dee0363cb8a8c` |
| `koinos-trixie-riscv64-26.11.25.iso.xz` | 3.5 MB | `715215be8341903df84d8c643c9b32bd11669c571a2667bc53c89c075e3f56be` |
| `koinos-trixie-riscv64-26.11.25.img` | 6.7 GB | (uncompressed) |
| `koinos-trixie-riscv64-26.11.25.iso` | 15 MB | (uncompressed, ready to burn) |

### Disk Image Partition Layout

| Partition | Size | Type | Label |
|-----------|------|------|-------|
| 1 (ESP) | 512 MB | EFI System (FAT32) | EFI System |
| 2 (Rootfs) | 2 GB | Linux filesystem (ext4) | Linux filesystem |
| 3 (Persist) | 4 GB | Linux filesystem (ext4) | Linux filesystem |

### Build Environment

- **Host**: macOS (Apple Silicon M1) via **Lima VM** (Debian 13 Trixie arm64)
- **Lima VM**: `limactl start template://debian` (VZ driver, 100 GB disk)
- **Build tools**: `mmdebstrap --mode=root`, `genimage`, `dtc`, `gcc-riscv64-linux-gnu`, `qemu-system-riscv64`
- **Kernel**: Linux 6.6.58 with CalVer `26.11.25` (`LOCALVERSION=-koinos-26.11.25`)

### Kernel Configuration Highlights

- **All 4 critical errata families enabled**:
  - T-Head: `ERRATA_THEAD_MAE`, `ERRATA_THEAD_CMO`, `ERRATA_THEAD_PMU`
  - SiFive: `ERRATA_SIFIVE_CIP_453`, `ERRATA_SIFIVE_CIP_1200`
  - StarFive JH7100: non-coherent DMA errata
  - Andes: `ERRATA_ANDES_CMO` (Renesas RZ/Five)
- **DTBs built** for: `hifive-unleashed-a00`, `hifive-unmatched-a00`, `jh7100-beaglev-starlight`, `jh7100-starfive-visionfive-v1`, `jh7110-starfive-visionfive-2-v1.2a`, `jh7110-starfive-visionfive-2-v1.3b`, `th1520-beaglev-ahead`, `th1520-lichee-pi-4a`
- **VirtIO MMIO cmdline devices** enabled for QEMU virt platform
- **Serial console**: 8250 DW support for earlycon=sbi
- **VirtIO block** and **ext4** filesystem support
- **Flexible MMU paging**: Sv39 / Sv48 / Sv57 with `no5lvl` / `no4lvl` fallbacks

### QEMU Smoke Test Results

| Test | Command | Result |
|------|---------|--------|
| **Kernel boot (no DTB)** | `qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -smp 2 -kernel Image -append 'console=ttyS0,115200 earlycon=sbi' -nographic` | ✅ OpenSBI → kernel boots |
| **Kernel + disk image** | `qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -smp 2 -bios fw_jump.bin -kernel Image -append 'console=ttyS0,115200 earlycon=sbi root=/dev/vda2 rw rootwait' -drive file=koinos.img,format=raw,if=virtio -nographic` | ✅ OpenSBI → kernel boots, detects virtio block |
| **Kernel + DTB + disk** | `qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -smp 2 -bios fw_jump.bin -kernel Image -dtb virt.dtb -append 'console=ttyS0,115200 earlycon=sbi root=/dev/vda2 rw rootwait' -drive file=koinos.img,format=raw,if=virtio -nographic` | ✅ Full boot with DTB |

> **Note**: The QEMU virt platform uses dynamic DTB generation via `${fdtcontroladdr}`. The custom `virt.dtb` provides explicit serial and virtio MMIO nodes for reliable early console and block device detection.

---

## Project Status & Notes

| Aspect | Status |
|--------|--------|
| **Overall** | Active development — test on non-critical hardware first |
| **Tier 1 boards** | Booting with mainline kernel + UEFI (varies by board) |
| **Tier 2 boards** | UEFI + ACPI support in progress |
| **Tier 3 minimal variant** | Planned (Buildroot/musl) |
| **glibc-hwcaps / IFUNC** | Infrastructure in place; optimized libs WIP |
| **BSP packages** | TH1520, SG2042 in progress |
| **CI / QEMU smoke tests** | Configured and passing |

### Known Quirks & Caveats

- **VisionFive 2 8 GiB**: U-Boot `jh7110-common.dtsi` defaults to 4 GiB; DTB override needed for full RAM detection
- **VisionFive 2 PCB revisions**: v1.2B uses `cd-gpios` for microSD; v1.3A uses `broken-cd` — kernel 6.10–6.15 regressions possible
- **Microchip PolarFire Video Kit**: `i2c0`/`i2c1` disabled in DT; require `status = "okay"` overlay
- **SpacemiT K3 CoM260 TQ**: Dual PMIC variants need compile-time DT overlays for voltage configuration
- **Vendor firmware blobs**: OpenSBI/U-Boot/EDK2 may need board-specific flashing; redistribution rules vary by SoC vendor

---

## Contributing

1. **Read the Constitution**: [`speckit/current/constitution.md`](speckit/current/constitution.md) — core principles, validation checklists, git discipline
2. **Follow Spec Kit workflow**: [`speckit/current/SPECKIT_PROCESS.md`](speckit/current/SPECKIT_PROCESS.md) — specification-driven development
3. **Branch & commit** (CalVer only — no SemVer):
   ```bash
   git switch -c feat/your-feature
   # ... make changes ...
   git add -A && git commit -m "feat(scope): description"
   ```
4. **Run validation** before PR:
   ```bash
   ./tests/dtbs-check.sh
   ./tests/qemu-smoke.sh
   ./tests/hwcaps-verify.sh
   ./tests/test-iso-debian.sh
   ./tests/test-iso-macos.sh
   ```
5. **Open PR** with clear description linking to spec/task if applicable

See [`docs/contributing/`](docs/contributing/) for detailed guides.

---

## License

| Component | License |
|-----------|---------|
| **Agile611 Koinos RISC-V scripts, configs, build recipes, documentation** | [MIT](LICENSE.md) |
| **Upstream Debian packages** | Respective DFSG-free licenses (GPL, LGPL, MIT, BSD, etc.) |
| **Linux kernel, U-Boot, Buildroot, dtc, QEMU** | GPL-2.0-only / GPL-2.0+ |
| **OpenSBI, EDK2** | BSD-2-Clause |
| **glibc** | LGPL-2.1+ |
| **Vendor firmware blobs** | Proprietary (redistribution per vendor terms) |

> **Important**: The MIT license applies **only to Agile611 Koinos RISC-V-specific code**. When distributing Agile611 Koinos RISC-V images, you must comply with all applicable upstream licenses (particularly GPL-2.0 for kernel/U-Boot/Buildroot, which requires source distribution).

---

## Links & Resources

- **Repository**: https://github.com/agile611/Agile611 Koinos RISC-V
- **Issues**: https://github.com/agile611/Agile611 Koinos RISC-V/issues
- **Discussions**: https://github.com/agile611/Agile611 Koinos RISC-V/discussions
- **Jenkins CI**: https://jenkins.tatsukai.com/job/Koinos-Release/
- **Debian RISC-V Port**: https://wiki.debian.org/RISC-V
- **RISC-V ISA Specifications**: https://riscv.org/specifications/
- **devicetree-rebasing.git**: https://git.kernel.org/pub/scm/utils/dtc/devicetree-rebasing.git
- **RevyOS (BSP model reference)**: https://github.com/revyos
- **Spec Kit Artifacts**: [`speckit/current/`](speckit/current/) (latest CalVer snapshot)

---

*Agile611 Koinos RISC-V — Building a universal RISC-V Linux distribution on Debian Trixie*  
*License: MIT — Copyright (c) 2026 Agile611 Koinos RISC-V Project Contributors*
