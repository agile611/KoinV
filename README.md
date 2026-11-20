# KoinV Linux

**KoinV** (*koinós* + V) is a modern `riscv64` Linux distribution built on **Debian 13 ("Trixie")**, designed around a shared foundation for maximum RISC-V board and Device Tree compatibility.

---

## Why KoinV?

The RISC-V ecosystem spans many SoCs, firmware generations, and ISA profiles. KoinV aims to give you a **Debian-compatible** system that:

- **Preserves broad hardware compatibility:** Uses `RV64GC` as its baseline user space so existing pre-RVA23 `riscv64` boards continue to boot cleanly alongside newer hardware.
- **Accelerates modern silicon at runtime:** Uses `glibc-hwcaps` (via kernel `hwprobe`) and `IFUNC` dispatch for optimized routines on capable CPUs (such as RVV / RVA23) without forcing an incompatible global ISA floor.
- **Unifies booting and Device Trees:** Targets UEFI boot (`systemd-boot` or `GRUB2`) with `u-boot-efi-dtb` to keep Device Trees aligned with installed kernels, while retaining `u-boot-menu` (`extlinux`) fallback support for legacy or non-UEFI U-Boot builds.
- **Combines mainline and SoC support:** Ships a unified kernel with silicon errata enabled, paired with optional BSP/firmware packages (inspired by the RevyOS approach) for boards whose drivers or Device Trees are still landing upstream.

---

## Architecture & Compatibility Strategy

### ISA Baseline: RV64GC (RVA20)

KoinV compiles its base user space for **RV64GC** (the `RVA20` profile), matching Debian 13 "Trixie" and ensuring binaries run on pre-2026 boards such as:

- VisionFive 2 (JH7110)
- Milk-V Mars (JH7110)
- Star64 (JH7110)
- Lichee Pi 4A (TH1520)
- Allwinner D1 / D1s
- Milk-V Pioneer (SG2042)

This avoids the fragmentation caused by distributions that mandate RVA23 (e.g., Ubuntu 25.10+), which would leave these boards unable to run the user space.

### Runtime Acceleration: glibc-hwcaps + hwprobe + IFUNC

On RVA23-capable hardware (SpacemiT K3, future RVA23 servers), KoinV leverages:

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
| **Tier 4: 32-bit / No-MMU MCUs** | WCH QingKe, Espressif ESP32, GigaDevice GD32VF103, Bouffalo Lab, others | **Out of scope** — KoinV targets `riscv64` Linux only |

> **Note**: The 11 silicon families in mainline Linux (`allwinner/`, `andes/`, `canaan/`, `eswin/`, `microchip/`, `renesas/`, `sifive/`, `sophgo/`, `spacemit/`, `starfive/`, `thead/`) are all tracked. Vendor BSP forks (`revyos/th1520-linux-kernel`, `linux4microchip`, `spacemit-com`, `starfive-tech`, `riscv/meta-riscv`) provide early support for boards not yet upstreamed.

---

## Quick Start

### 1. Flash the Image

```bash
# Decompress and write to target media (SD card, NVMe, or eMMC)
xz -d koinv-trixie-riscv64.img.xz
sudo dd if=koinv-trixie-riscv64.img of=/dev/sdX bs=4M status=progress conv=fsync
```

> **Replace `/dev/sdX`** with your actual target device (e.g., `/dev/mmcblk0`, `/dev/nvme0n1`). **Double-check** — `dd` is destructive.

### 2. Connect Serial Console

Most RISC-V boards expose a UART for early boot debugging:

```
Baud: 115200
Data bits: 8
Parity: None
Stop bits: 1
Flow control: None
```

You will see: **OpenSBI → U-Boot → systemd-boot/GRUB2 → Linux kernel → systemd**

### 3. Paging Fallback (If Needed)

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
koinv/
├── profiles/           # mmdebstrap package lists and build profiles
│   ├── base.trixie     # Minimal important packages
│   ├── desktop.trixie  # Desktop environment profile
│   └── server.trixie   # Server/headless profile
├── overlays/           # Base files, APT sources/pinning, boot hooks
│   ├── etc/            # /etc overlays (apt, systemd, network)
│   ├── boot/           # Bootloader configs, kernel cmdline snippets
│   └── usr/            # /usr/local scripts, hwcaps helpers
├── packages/           # Custom .deb recipes (base-files, boot, hwcaps, bsp)
│   ├── koinv-base-files/
│   ├── koinv-boot/
│   ├── koinv-hwcaps/
│   └── koinv-bsp-*/
├── kernel/             # Kernel configs, DTB notes, and BSP patches
│   ├── config.trixie   # Base kernel config (defconfig + errata)
│   ├── config.bsp-*/   # BSP-specific kernel configs
│   └── patches/        # BSP patches not yet upstreamed
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
│   └── hwcaps-verify.sh # Runtime hwcaps verification
├── constitution.md     # Core engineering principles
├── LICENSE.md          # MIT License
├── SPECKIT_PROCESS.md  # Spec Kit workflow documentation
└── README.md           # This file
```

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

### Build Commands

```bash
# 1. Build base Debian 13 (trixie) riscv64 rootfs
mmdebstrap \
  --architectures=riscv64 \
  --variant=important \
  --mode=unshare \
  trixie ./build/koinv-trixie-riscv64.tar \
  http://deb.debian.org/debian

# 2. Apply overlays (boot configs, hwcaps, APT pinning)
tar -C ./build/koinv-trixie-riscv64 -xf ./overlays/boot/boot-overlay.tar
tar -C ./build/koinv-trixie-riscv64 -xf ./overlays/etc/etc-overlay.tar

# 3. Install custom packages (base-files, boot, hwcaps, BSP)
# (Build .debs from packages/ first, then install into rootfs)
for deb in ./packages/*.deb; do
  dpkg -x "$deb" ./build/koinv-trixie-riscv64/
done

# 4. Build kernel + DTBs (cross-compiled)
cd ./kernel
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig
make -j$(nproc) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- Image dtbs
make dtbs_check  # Validate against DT-Schema
cp arch/riscv/boot/Image ./build/koinv-trixie-riscv64/boot/
cp arch/riscv/boot/dts/*.dtb ./build/koinv-trixie-riscv64/boot/dtb/

# 5. Assemble final disk image with genimage
cd ./images
genimage --config genimage.cfg --inputpath ../build/koinv-trixie-riscv64 --outputpath ../output/

# 6. Compress for distribution
xz -T0 ../output/koinv-trixie-riscv64.img
```

> See `images/genimage.cfg` for partition layout (EFI system partition, rootfs, optional persistent data) and bootloader placement.

---

## Project Status & Notes

| Aspect | Status |
|--------|--------|
| **Overall** | Early / active development — test on non-critical hardware first |
| **Tier 1 boards** | Booting with mainline kernel + UEFI (varies by board) |
| **Tier 2 boards** | UEFI + ACPI support in progress |
| **Tier 3 minimal variant** | Planned (Buildroot/musl) |
| **glibc-hwcaps / IFUNC** | Infrastructure in place; optimized libs WIP |
| **BSP packages** | TH1520, SG2042 in progress |
| **CI / QEMU smoke tests** | Configured |

### Known Quirks & Caveats

- **VisionFive 2 8 GiB**: U-Boot `jh7110-common.dtsi` defaults to 4 GiB; DTB override needed for full RAM detection
- **VisionFive 2 PCB revisions**: v1.2B uses `cd-gpios` for microSD; v1.3A uses `broken-cd` — kernel 6.10–6.15 regressions possible
- **Microchip PolarFire Video Kit**: `i2c0`/`i2c1` disabled in DT; require `status = "okay"` overlay
- **SpacemiT K3 CoM260 TQ**: Dual PMIC variants need compile-time DT overlays for voltage configuration
- **Vendor firmware blobs**: OpenSBI/U-Boot/EDK2 may need board-specific flashing; redistribution rules vary by SoC vendor

---

## Contributing

1. **Read the Constitution**: [`constitution.md`](constitution.md) — core principles, validation checklists, git discipline
2. **Follow Spec Kit workflow**: [`SPECKIT_PROCESS.md`](SPECKIT_PROCESS.md) — specification-driven development
3. **Branch & commit**:
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
   ```
5. **Open PR** with clear description linking to spec/task if applicable

See [`docs/contributing/`](docs/contributing/) for detailed guides.

---

## License

| Component | License |
|-----------|---------|
| **KoinV scripts, configs, build recipes, documentation** | [MIT](LICENSE.md) |
| **Upstream Debian packages** | Respective DFSG-free licenses (GPL, LGPL, MIT, BSD, etc.) |
| **Linux kernel, U-Boot, Buildroot, dtc, QEMU** | GPL-2.0-only / GPL-2.0+ |
| **OpenSBI, EDK2** | BSD-2-Clause |
| **glibc** | LGPL-2.1+ |
| **Vendor firmware blobs** | Proprietary (redistribution per vendor terms) |

> **Important**: The MIT license applies **only to KoinV-specific code**. When distributing KoinV images, you must comply with all applicable upstream licenses (particularly GPL-2.0 for kernel/U-Boot/Buildroot, which requires source distribution).

---

## Links & Resources

- **Repository**: https://github.com/agile611/KoinV
- **Issues**: https://github.com/agile611/KoinV/issues
- **Discussions**: https://github.com/agile611/KoinV/discussions
- **Debian RISC-V Port**: https://wiki.debian.org/RISC-V
- **RISC-V ISA Specifications**: https://riscv.org/specifications/
- **devicetree-rebasing.git**: https://git.kernel.org/pub/scm/utils/dtc/devicetree-rebasing.git
- **RevyOS (BSP model reference)**: https://github.com/revyos

---

*KoinV — Building a universal RISC-V Linux distribution on Debian Trixie*  
*License: MIT — Copyright (c) 2026 KoinV Project Contributors*
