# KoinV Technical Plan

**Version:** 26.11.20 (CalVer Daily Build)  
**Date:** 2026-11-20  
**Status:** Draft  
**Based On:** [Constitution](constitution.md) 26.11.20 | [Specification](spec.md) 26.11.20 | [Clarifications](clarifications.md) 26.11.20

---

## 1. System Architecture Overview

### 1.1 High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KOINV RISC-V DISTRIBUTION                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────┐  │
│  │   HOST       │    │   BUILD      │    │   TARGET     │    │  RUNTIME │  │
│  │   (x86_64/   │───▶│   PIPELINE   │───▶│   IMAGE      │───▶│  (riscv64)│  │
│  │   aarch64)   │    │              │    │              │    │          │  │
│  └──────────────┘    └──────────────┘    └──────────────┘    └──────────┘  │
│         │                   │                   │                   │       │
│         ▼                   ▼                   ▼                   ▼       │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                        ARTIFACT STORE                                 │  │
│  │  koinv-trixie-riscv64-YY.MM.DD.img.xz  │  SBOM  │  Kernel+DTBs       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Build Pipeline Data Flow

```
mmdebstrap (Debian Trixie)
    │
    ├─▶ Base Rootfs (glibc + systemd)
    │       │
    │       ├─▶ Overlays (etc/, boot/, usr/)
    │       │       │
    │       │       ├─▶ APT sources/pinning
    │       │       ├─▶ systemd-boot/GRUB2 configs
    │       │       ├─▶ Kernel cmdline (no5lvl/no4lvl)
    │       │       └─▶ hwcaps helpers
    │       │
    │       ├─▶ Custom Packages (.deb)
    │       │       ├─▶ koinv-base-files
    │       │       ├─▶ koinv-boot
    │       │       ├─▶ koinv-hwcaps
    │       │       └─▶ koinv-bsp-* (TH1520, SG2042, K3)
    │       │
    │       └─▶ Kernel + DTBs (cross-compiled)
    │               ├─▶ linux-image-riscv64 (mainline + errata)
    │               ├─▶ All 11 vendor DTBs
    │               └─▶ BSP patches applied
    │
    └─▶ genimage Assembly
            │
            ├─▶ Partition Layout (GPT)
            │       ├─▶ ESP (FAT32, 512 MB) → EFI/BOOT/BOOTRISCV64.EFI + DTBs + Kernel
            │       ├─▶ Rootfs (ext4, remaining)
            │       └─▶ Persistent (ext4, optional 0-4 GB)
            │
            └─▶ Final Image: koinv-trixie-riscv64-YY.MM.DD.img.xz
```

### 1.3 Runtime Boot Flow

```
M-Mode (BootROM/ZSBL)
    │
    ▼
SPL (FSBL) — DDR Init
    │
    ▼
FIT Image (OpenSBI PLATFORM=generic + U-Boot S-Mode OF_UPSTREAM)
    │
    ▼
UEFI (BOOTRISCV64.EFI)
    │
    ├─▶ systemd-boot (UKI) ──▶ Linux + DTB (from /boot on ESP)
    │
    └─▶ GRUB2 (fallback) ──▶ Linux + DTB (from /boot on ESP)
    │
    ▼ (fallback if no UEFI)
extlinux (u-boot-menu) ──▶ Linux + DTB
```

---

## 2. Technology Stack Decisions

| Layer | Decision | Version/Source | Rationale |
|-------|----------|----------------|-----------|
| **Base Distribution** | Debian 13 "Trixie" | `deb.debian.org/debian` | Stable, `riscv64` port mature, DFSG-free |
| **Rootfs Builder** | `mmdebstrap` | ≥1.0 (Debian) | Unprivileged, reproducible, variant support |
| **Image Assembler** | `genimage` | ≥16 | Declarative partition layout, multi-format |
| **Kernel** | Mainline Linux LTS | 6.6.x or 6.12.x LTS | All 11 vendor `dts/` dirs, errata support |
| **Kernel Config** | Custom `config.trixie` | Based on `defconfig` + errata | Mandatory errata, all DTBs, Sv57/Sv48/Sv39 |
| **Cross-Compiler** | `riscv64-linux-gnu-gcc` | ≥13.2 (Debian Trixie) | RV64GC baseline, glibc-hwcaps support |
| **Bootloader (UEFI)** | U-Boot + EDK2 | Mainline (U-Boot), EDK2 | `OF_UPSTREAM` UEFI, `BOOTRISCV64.EFI` |
| **Bootloader (Fallback)** | U-Boot `u-boot-menu` | Mainline | `extlinux.conf` auto-generation |
| **Firmware** | OpenSBI | Mainline | `PLATFORM=generic` for multi-board |
| **Boot Manager** | `systemd-boot-efi` + `grub-efi-riscv64` | Debian Trixie | UKI support, classic GRUB workflow |
| **DTB Management** | `u-boot-efi-dtb` | Debian Trixie | DTB override from `/boot` |
| **Device Tree Compiler** | `dtc` | ≥1.7.0 | Schema validation (`make dtbs_check`) |
| **Init System (Tier 1)** | `systemd` | ≥254 (Debian Trixie) | Standard Debian, UKI support |
| **Init System (Tier 2)** | BusyBox init | Buildroot | Minimal, no systemd, 5-50 MB |
| **C Library (Tier 1)** | glibc | ≥2.38 (backported) | `glibc-hwcaps` + `hwprobe` + `IFUNC` |
| **C Library (Tier 2)** | musl | Buildroot | Tiny, static linking friendly |
| **Compression** | `xz` | ≥5.4 | High ratio, multi-threaded (`-T0`) |
| **Virtualization** | QEMU | ≥8.0 | `virt`, `sifive_u`, `microchip-icicle` |
| **macOS Build** | Homebrew + Lima/Docker | `brew`, `lima` | Native QEMU/kernel, Linux namespaces via VM |

---

## 3. Module/Component Breakdown

### 3.1 Build-Time Modules

| Module | Path | Responsibility | Outputs |
|--------|------|----------------|---------|
| **Profiles** | `profiles/` | Package lists per variant | `base.trixie`, `desktop.trixie`, `server.trixie` |
| **Overlays** | `overlays/` | File system overlays | `etc/`, `boot/`, `usr/` tarballs |
| **Packages** | `packages/` | Custom `.deb` recipes | `koinv-base-files`, `koinv-boot`, `koinv-hwcaps`, `koinv-bsp-*` |
| **Kernel** | `kernel/` | Kernel build + DTBs | `Image`, `*.dtb`, `config.trixie`, patches |
| **Images** | `images/` | Disk image assembly | `genimage.cfg`, `build-image.sh` |
| **BSP** | `bsp/` | SoC-specific definitions | `th1520/`, `jh7110/`, `sg2042/`, `spacemit-k3/` |
| **Tests** | `tests/` | Validation scripts | `qemu-smoke.sh`, `dtbs-check.sh`, `hwcaps-verify.sh` |

### 3.2 Runtime Components (Tier 1)

| Component | Package | Purpose |
|-----------|---------|---------|
| **Base System** | `koinv-base-files` | `/etc/os-release`, `/etc/apt/sources.list`, defaults |
| **Boot** | `koinv-boot` | `systemd-boot`/`GRUB2` config, kernel cmdline, DTB hooks |
| **HWCapS** | `koinv-hwcaps` | `glibc-hwcaps` dirs, `IFUNC` helpers, `hwprobe` utils |
| **BSP: TH1520** | `koinv-bsp-th1520` | Kernel modules, firmware, DT overlays for TH1520 |
| **BSP: JH7110** | `koinv-bsp-jh7110` | Kernel modules, firmware, DT overlays for JH7110 |
| **BSP: SG2042** | `koinv-bsp-sg2042` | Kernel modules, firmware, DT overlays for SG2042 |
| **BSP: K3** | `koinv-bsp-spacemit-k3` | Kernel modules, firmware, DT overlays for K3 |

### 3.3 Runtime Components (Tier 2 Minimal)

| Component | Source | Purpose |
|-----------|--------|---------|
| **Base System** | Buildroot | `musl` + `BusyBox` + `init` |
| **Kernel** | Shared with Tier 1 | Same `Image` + `*.dtb` |
| **Boot** | `extlinux` | `u-boot-menu` generated config |

---

## 4. Interface Contracts

### 4.1 Boot Protocol Interfaces

| Interface | Specification | Implementation |
|-----------|---------------|----------------|
| **UEFI Boot** | EBBR / UEFI Spec 2.9 | `BOOTRISCV64.EFI` → `systemd-boot`/`GRUB2` |
| **DTB Handoff** | Linux DT binding | `/boot/dtb/*.dtb` on ESP, `u-boot-efi-dtb` override |
| **Kernel Cmdline** | `Documentation/admin-guide/kernel-parameters.txt` | `no5lvl`/`no4lvl` paging, `console=ttyS0,115200` |
| **extlinux Fallback** | U-Boot `extlinux.conf` | `u-boot-menu` auto-generation on kernel install |
| **ACPI** | RISC-V BRS / UEFI ACPI | Enabled in kernel for server platforms |

### 4.2 Device Tree Bindings

| Binding | Source | Validation |
|---------|--------|------------|
| **All 11 vendor `dts/`** | Mainline Linux `arch/riscv/boot/dts/` | `make dtbs_check` |
| **Custom DT overlays** | `bsp/*/overlays/` | Schema YAML in `Documentation/devicetree/bindings/` |
| **VisionFive 2 8GB** | `jh7110-common.dtsi` override | Memory node `@40000000` size = 8GB |
| **VisionFive 2 PCB rev** | `cd-gpios` vs `broken-cd` | Per-revision DT overlay |
| **PolarFire Video Kit** | `i2c0`/`i2c1` `status="okay"` | Overlay in `bsp/microchip/` |
| **SpacemiT K3 CoM260** | PMIC variant overlays | Compile-time DT overlay in `bsp/spacemit-k3/` |

### 4.3 HWCapS / Runtime Acceleration Interface

| Interface | Mechanism | Detection |
|-----------|-----------|-----------|
| **glibc-hwcaps** | `$LIB/hwcaps/RVA23U64/` | `hwprobe` syscall → `RVA23U64` capability |
| **IFUNC Resolvers** | `RISCV_HWPROBE_KEY_IMA_EXT_0` | Vector (RVV 1.0) routine selection |
| **Optimized Libraries** | `openssl`, `libgcrypt`, `libjpeg-turbo` | Built with `-march=rva23u64` in hwcaps dir |

### 4.4 Package Management Interface

| Interface | Specification |
|-----------|---------------|
| **APT Sources** | `deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware` |
| **APT Pinning** | `/etc/apt/preferences.d/koinv` (BSP packages priority) |
| **Custom Repo** | Local `.deb` repo for `koinv-*` packages |
| **SBOM** | SPDX JSON via `syft` or `cyclonedx` |

---

## 5. Data Models

### 5.1 Disk Partition Layout (GPT)

| Partition | Label | FS | Size | Mount Point | Contents |
|-----------|-------|----|------|-------------|----------|
| 1 | `ESP` | FAT32 | 512 MB | `/boot/efi` | `EFI/BOOT/BOOTRISCV64.EFI`, `dtb/`, `Image`, `loader/entries/`, `grub/` |
| 2 | `ROOTFS` | ext4 | Remaining | `/` | Debian rootfs |
| 3 | `PERSIST` | ext4 | 0-4 GB (opt) | `/var/lib/koinv` | Persistent data, logs, cache |

**Partition UUIDs**: Generated at build time; `genimage` ensures reproducibility.

### 5.2 Memory Map (Typical Tier 1 Board)

| Region | Address Range | Size | Purpose |
|--------|---------------|------|---------|
| **OpenSBI** | `0x0000_0000` – `0x0020_0000` | 2 MB | M-mode firmware |
| **U-Boot SPL** | `0x0020_0000` – `0x0040_0000` | 2 MB | FSBL (DDR init) |
| **U-Boot Proper** | `0x0040_0000` – `0x0100_0000` | 12 MB | S-mode bootloader + UEFI |
| **FDT (DTB)** | `0x0100_0000` – `0x0110_0000` | 1 MB | Device Tree Blob |
| **Kernel Image** | `0x0110_0000` – `0x0400_0000` | ~48 MB | Linux kernel (`Image`) |
| **Initramfs** | `0x0400_0000` – `0x0800_0000` | 64 MB | Initramfs (if used) |
| **System RAM** | `0x0800_0000` – `0xFFFF_FFFF` | Remaining | Linux system memory |

> **Note**: Actual addresses vary by SoC; DTB describes memory nodes. VisionFive 2 8GB uses `memory@40000000` with `reg = <0x0 0x40000000 0x0 0x80000000>`.

### 5.3 Kernel Configuration Model

| Config | Value | Source |
|--------|-------|--------|
| `CONFIG_RISCV` | `y` | Base |
| `CONFIG_64BIT` | `y` | RV64GC |
| `CONFIG_SMP` | `y` | Multi-core |
| `CONFIG_ERRATA_THEAD` | `y` | Mandatory |
| `CONFIG_ERRATA_SIFIVE` | `y` | Mandatory |
| `CONFIG_ERRATA_ANDES_CMO` | `y` | Mandatory (RZ/Five) |
| `CONFIG_JH7100_DMA_ERRATA` | `y` | Mandatory |
| `CONFIG_SV57` | `y` | 5-level paging |
| `CONFIG_SV48` | `y` | 4-level paging |
| `CONFIG_SV39` | `y` | 3-level paging |
| `CONFIG_NO5LVL` | `y` | Cmdline fallback |
| `CONFIG_NO4LVL` | `y` | Cmdline fallback |
| `CONFIG_ACPI` | `y` | BRS servers |
| `CONFIG_EFI_STUB` | `y` | UEFI boot |
| `CONFIG_LOCALVERSION` | `-koinv-YY.MM.DD` | CalVer traceability |
| `CONFIG_MODULES` | `y` (Tier 1) / `n` (Tier 2) | Tier-dependent |

---

## 6. Security Model

### 6.1 Boot Chain Security

| Layer | Mechanism | Status |
|-------|-----------|--------|
| **BootROM (M-Mode)** | Hardware RoT (vendor-specific) | Vendor-dependent |
| **OpenSBI** | Measured boot (optional) | `PLATFORM=generic` |
| **U-Boot** | Verified boot (FIT signature) | `OF_UPSTREAM` + keys |
| **UEFI** | Secure Boot (shim + MOK) | `grub-efi-riscv64` + `sbctl` |
| **Kernel** | Lockdown mode + module signing | `CONFIG_MODULE_SIG=y` |
| **Initramfs** | Measured/verified | `systemd-boot` UKI |

### 6.2 Runtime Security

| Control | Implementation |
|---------|----------------|
| **Kernel Hardening** | `CONFIG_HARDENED_USERCOPY=y`, `CONFIG_FORTIFY_SOURCE=3`, `CONFIG_STACKPROTECTOR_STRONG=y`, `CONFIG_PAGE_TABLE_ISOLATION=y` |
| **Memory Protection** | `CONFIG_STRICT_DEVMEM=y`, `CONFIG_STRICT_KERNEL_RWX=y`, `CONFIG_DEBUG_RODATA=y` |
| **Userspace** | `glibc` `FORTIFY_SOURCE=3`, `PIE`/`RELRO` by default (Debian) |
| **Mandatory Access** | AppArmor profiles (Debian default) |
| **Audit** | `auditd` + kernel audit subsystem |

### 6.3 Supply Chain Integrity

| Control | Implementation |
|---------|----------------|
| **Reproducible Builds** | Pinned commits, deterministic flags, `SOURCE_DATE_EPOCH` |
| **SBOM** | SPDX JSON for every image (`syft packages koinv-*.img.xz`) |
| **Signature** | `cosign`/`gpg` sign git tags and artifacts |
| **Verification** | `cosign verify` / `gpg --verify` in CI |

---

## 7. Deployment Architecture

### 7.1 Image Types

| Image Type | Filename Pattern | Target | Boot Method |
|------------|------------------|--------|-------------|
| **Daily Build** | `koinv-trixie-riscv64-YY.MM.DD.img.xz` | Tier 1/2, QEMU | UEFI + extlinux |
| **Monthly Release** | `koinv-trixie-riscv64-YY.MM.img.xz` | Production | UEFI + extlinux |
| **Patch/Hotfix** | `koinv-trixie-riscv64-YY.MM.pN.img.xz` | Emergency | UEFI + extlinux |
| **Tier 2 Minimal** | `koinv-trixie-riscv64-minimal-YY.MM.DD.img.xz` | Tier 2 (64-256 MB) | extlinux only |
| **QEMU Test** | `koinv-trixie-riscv64-qemu-YY.MM.DD.img.xz` | CI `virt`/`sifive_u` | UEFI |

### 7.2 Flashing Methods

| Target Media | Command | Notes |
|--------------|---------|-------|
| **SD Card** | `dd if=koinv-*.img of=/dev/mmcblkX bs=4M status=progress conv=fsync` | Most SBCs |
| **NVMe** | `dd if=koinv-*.img of=/dev/nvmeXn1 bs=4M status=progress conv=fsync` | Workstations/servers |
| **eMMC** | `dd if=koinv-*.img of=/dev/mmcblkX bs=4M status=progress conv=fsync` | Onboard storage |
| **SPI NOR (U-Boot)** | Vendor-specific (e.g., `sf update`) | Bootloader only |
| **QEMU** | `-drive file=koinv-*.img,format=raw,if=virtio` | CI testing |

### 7.3 Update Mechanisms

| Mechanism | Status | Details |
|-----------|--------|---------|
| **Full Image Reflash** | Primary (26.11.20) | `dd` new image; simple, reliable |
| **APT Package Updates** | Supported | `apt update && apt upgrade` for userspace |
| **Kernel/DTB Updates** | Supported | `apt install linux-image-riscv64` → `u-boot-efi-dtb` refreshes DTB |
| **Bootloader Updates** | Manual | `flash-kernel` / vendor SPI tools |
| **OSTree/ABRoot** | Deferred (Spec §6.3) | Atomic updates; future work |

---

## 8. Validation & Test Strategy

### 8.1 CI Pipeline Stages

| Stage | Command | Gate |
|-------|---------|------|
| **1. Kernel Config** | `make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig` | Pass |
| **2. Kernel Build** | `make -j$(nproc) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- Image dtbs` | Pass |
| **3. DTB Schema** | `make dtbs_check` | Zero errors/warnings |
| **4. Rootfs Build** | `mmdebstrap --architectures=riscv64 --variant=important --mode=unshare trixie ...` | Pass |
| **5. Image Assembly** | `genimage --config genimage.cfg ...` | Pass |
| **6. QEMU Smoke** | `qemu-system-riscv64 -machine virt -kernel Image -dtb virt.dtb -append "console=ttyS0" -nographic` | Boots to login |
| **7. HWCapS Verify** | `./tests/hwcaps-verify.sh` | `hwprobe` returns capabilities |
| **8. SBOM Generate** | `syft packages koinv-*.img.xz -o spdx-json` | Valid SPDX |

### 8.2 Per-Board Validation Matrix

| Board | Tier | Test | Frequency |
|-------|------|------|-----------|
| VisionFive 2 | 1 | UEFI boot, 8GB RAM, microSD | Daily |
| Milk-V Mars | 1 | UEFI boot, 4GB RAM | Daily |
| Star64 | 1 | UEFI boot | Weekly |
| Lichee Pi 4A | 1 | UEFI boot | Weekly |
| BeagleV-Ahead | 1 | UEFI boot, AON | Weekly |
| Milk-V Pioneer | 1 | UEFI boot, DDR4 | Weekly |
| SpacemiT K3 (Pico-ITX) | 1/2 | UEFI + ACPI, RVA23 | Weekly |
| Milk-V Duo 64M | 2 | extlinux boot, minimal | Weekly |
| LicheeRV Nano | 2 | extlinux boot, minimal | Weekly |
| QEMU `virt` | Dynamic | Smoke test | Every commit |
| QEMU `sifive_u` | Dynamic | Smoke test | Every commit |

---

## 9. Traceability Matrix

| Plan Section | Constitution Ref | Spec Ref | Clarification Ref |
|--------------|------------------|----------|-------------------|
| Architecture Overview | §1.1–1.4 | G1–G8 | — |
| Tech Stack | §1.1, §1.2 | FR-01–FR-14, FR-37 | AS-01–AS-10, DEP-01–DEP-17 |
| Module Breakdown | §1.2, §1.3 | FR-06–FR-22, FR-35–FR-40 | CL-02, CL-06, DEC-04 |
| Interface Contracts | §1.3, §3.1–3.3 | FR-09–FR-18, FR-29–FR-34 | CL-04, CL-05, CL-10, DEC-03 |
| Data Models | §1.3, §3.3 | FR-04, FR-15–FR-18 | CL-04, CL-05 |
| Security Model | §4 | NFR-07–NFR-11 | RSK-08 |
| Deployment | §1.3, §1.4 | FR-11–FR-14, FR-23–FR-26 | CL-04, CL-06, CL-07 |
| Validation | §5, §16 | AC-01–AC-16 | RSK-01–RSK-10 |

---

## 10. Open Issues / Future Work

| ID | Issue | Priority | Target |
|----|-------|----------|--------|
| **PLAN-01** | glibc 2.38+ backport for Trixie (`koinv-glibc`) | P0 | 26.11.27 |
| **PLAN-02** | `koinv-bsp-*` package build recipes | P0 | 26.11.27 |
| **PLAN-03** | Tier 2 Buildroot minimal variant config | P1 | 26.12.04 |
| **PLAN-04** | Secure Boot shim/MOK enrollment automation | P1 | 26.12.04 |
| **PLAN-05** | OSTree/ABRoot atomic update design | P2 | 26.12.11+ |
| **PLAN-06** | RVA23 opt-in overlay repository | P2 | 26.12.11+ |
| **PLAN-07** | Multi-arch image (RV64GC + RVA23 hwcaps) | P1 | 26.12.04 |
| **PLAN-08** | Automated per-board DTB override testing | P1 | 26.11.27 |

---

*Generated: 2026-11-20T12:41:00+01:00*  
*KoinV Technical Plan 26.11.20 — Derived from Constitution, Spec, and Clarifications*
