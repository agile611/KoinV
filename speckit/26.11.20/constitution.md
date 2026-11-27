# KoinV Constitution

## Core Engineering, Testing, and Architectural Principles

This constitution defines the immutable architectural, compatibility, and verification principles governing the KoinV RISC-V Linux distribution. All specifications, build pipelines, kernel configurations, device trees, and release artifacts must comply with these principles.

---

## 1. Architectural Pillars

### 1.1 CPU Architecture & User Space — `riscv64` (`RV64GC`) + `glibc-hwcaps`

* **64-Bit Exclusive (`riscv64`):** Target the official 64-bit little-endian `riscv64` architecture based on Debian 13 ("Trixie"). `riscv32` is not a general-purpose release architecture for KoinV.
* **Baseline ISA Compatibility:** Compile base user-space packages for **`RV64GC` (`RVA20`)** so binaries run across pre-2026 boards (such as VisionFive 2, Milk-V Mars, Star64, Lichee Pi 4A, Allwinner D1, and Milk-V Pioneer) and remain aligned with Debian repositories (where Debian 13 uses `RV64GC` and Debian 14 "Forky" is expected to raise the baseline at most to `RVA20U64`).
* **Runtime Capability Acceleration:** Use **`glibc-hwcaps`** backed by the Linux **`hwprobe`** syscall (`RISCV_HWPROBE_KEY_IMA_EXT_0` and `RVA23U64` capability detection) and **`IFUNC`** runtime resolvers to dynamically load optimized shared libraries (`openssl`, `libgcrypt`, `libjpeg-turbo`) and `RVV 1.0` vector routines on capable hardware (such as SpacemiT K3) without breaking `RV64GC` compatibility.
* **Separate `RVA23` Opt-In Track:** Keep whole-system `RVA23` (`rva23_defconfig` / `-march=rva23u64`) builds in a dedicated opt-in repository or overlay rather than replacing the default `RV64GC` user space.

### 1.2 Linux Kernel Strategy — Unified Default Kernel + Modular BSP Layer

* **Unified Mainline Kernel Package:** Maintain a default `riscv64` kernel image (`linux-image-riscv64`) compiled from upstream/mainline sources with all supported `.dtb` binaries enabled.
* **Mandatory Silicon Errata:** Keep critical hardware errata enabled in `arch/riscv/Kconfig.errata` so early or non-standard silicon boots and performs DMA reliably:
  * `CONFIG_ERRATA_THEAD` (`ERRATA_THEAD_MAE`, `ERRATA_THEAD_CMO`, `ERRATA_THEAD_PMU`)
  * `CONFIG_ERRATA_SIFIVE` (`ERRATA_SIFIVE_CIP_453`, `ERRATA_SIFIVE_CIP_1200`)
  * StarFive `JH7100` non-coherent DMA errata
  * `CONFIG_ERRATA_ANDES_CMO` (for `ARCH_R9A07G043` / Renesas RZ/Five)
* **Modular BSP Layer (RevyOS Model):** Preserve a standard Debian (`trixie`) user space and APT ecosystem while permitting modular, SoC-specific kernel and firmware packages (such as `TH1520` or `SG2042`) when mainline lacks complete subsystem or peripheral support.
* **MMU Paging Flexibility:** Support `Sv39`, `Sv48`, and `Sv57` paging modes (selecting the widest mode supported by `satp`) and provide `no5lvl` (forces `Sv48`) and `no4lvl` (forces `Sv39`) kernel command-line fallbacks.

### 1.3 Boot Chain, DTB Variations & UEFI/ACPI Transition

* **Standard Privilege Boot Flow:** Follow `M-Mode` BootROM (`ZSBL`) -> `SPL` (`FSBL`) -> FIT container (`OpenSBI` with `PLATFORM=generic` + `U-Boot` in `S-Mode`) -> Linux kernel + `.dtb` (or `ACPI`).
* **Primary UEFI-First Path (`EBBR` / `BRS`):**
  * Use generic `OpenSBI` (`PLATFORM=generic`) and modern `U-Boot` (`OF_UPSTREAM`) exposing UEFI services to load `EFI/BOOT/BOOTRISCV64.EFI`.
  * Support both `systemd-boot` (`systemd-boot-efi` / Unified Kernel Images) and `grub-efi-riscv64` on Debian Trixie.
  * Include `u-boot-efi-dtb` so UEFI boot can consume updated `.dtb` files from `/boot` even when factory SPI firmware is older, while supporting explicit `$fdt_addr_r` handling where vendor U-Boot builds require it.
  * Keep `ACPI` enabled alongside Device Tree support for `BRS` server compatibility.
* **Non-UEFI Fallback Path:** Provide `u-boot-menu` (`extlinux.conf`) and `flash-kernel` support for boards whose vendor U-Boot builds lack UEFI support.
* **Explicit Handling of Board & Revision DT Quirks:** Account for known board/revision differences in boot scripts, overlays, or kernel/DT configurations, including:
  * VisionFive 2 8 GiB memory node handling vs. default 4 GiB declarations
  * VisionFive 2 PCB revision differences (`v1.2B` `cd-gpios` vs. `v1.3A` `broken-cd`)
  * Microchip PolarFire Video Kit buses (`i2c0` / `i2c1`) requiring `status = "okay"`
  * SpacemiT K3 CoM260 TQ power-regulator variants handled via Device Tree overlays

### 1.4 Embedded Fallback — Minimal Variant for Constrained Hardware

* **Separate Minimal Image Variant:** Provide a separate minimal rootfs variant (e.g., `musl` + `BusyBox` / Buildroot, ~5–50 MB) for severely memory-constrained boards where a standard `glibc` + `systemd` rootfs ($\ge$ 500 MB) is impractical, sharing the kernel and `.dtb` artifacts where compatible.

---

## 2. Hardware Classification & Dynamic DT Targets

* **Tier 1 — Full Linux Systems (54 Entries):** 64-bit platforms with 512 MB–64 GB RAM or DDR4 slots (49 RuyiSDK boards, 4 additional models, and Renesas RZ/Five, plus documented 2026 variants such as SpacemiT K3 AI Book `k3-ai-book`, PolarFire Discovery Kit `mpfs-disco...`, K3 CoM260 TQ `k3-com260-tq.dts`, DeepComputing Mainboard III `RVA23`, and dual-socket C2201 SpacemiT V100). Tier 1 is the target tier for standard Debian `riscv64` (`glibc` + `systemd`), with per-board maturity tracked explicitly (`GOOD`, `BASIC`, `CFT`, `WIP`).
* **Tier 2 — Ultra-Light, Constrained, or Hybrid Boards (18 Boards):** Boards with 64 MB–512 MB RAM or SRAM/PSRAM only, or heterogeneous ARM+RISC-V SoCs (such as `D1s NeZha`, `Milk-V Duo 64M/256M/Duo S`, `LicheeRV Nano`, `Pine64 Ox64/Oz64`, and `Sipeed Maix-Bit`), targeted via the minimal rootfs variant.
* **Tier 3 — Microcontrollers & RTOS-Only Boards (27 Boards):** WCH QingKe, Espressif ESP32, GigaDevice GD32VF103, Bouffalo Lab, and other MCU/RTOS boards are **excluded** from general-purpose KoinV Linux distribution builds.
* **Dynamic & Non-Static DT Environments:** Support dynamic or generated hardware descriptions without assuming static `.dts` files in the kernel tree:
  * **QEMU (`qemu-system-riscv`):** `virt`, `sifive_u`, `microchip-icicle`, `shakti-c`, `tt_atlantis` via runtime `.dtb` at `${fdtcontroladdr}`
  * **Spike:** Dynamic DTS generation/compilation via `riscv/dts.cc` and `dtc`
  * **LiteX + LiteX-Boards:** 250+ FPGA targets generated from `csr.json` using mainline LiteX drivers
  * **Renode:** Custom platform definitions or LiteX `csr.json` import
  * **OpenPiton & Chipyard:** RTL/SoC-generated descriptions and boot chains
  * **Coreboot:** Firmware-generated ACPI tables rather than Linux `.dts` files

---

## 3. Device Tree Sources & Build Standards

### 3.1 Authoritative Sources (Priority Order)
1. **Mainline Linux Kernel** (`torvalds/linux` -> `arch/riscv/boot/dts/`)
2. **`devicetree-rebasing.git`** (`src/riscv`, `Bindings/`, `include/dt-bindings`)
3. **Official U-Boot** (`u-boot/u-boot` -> `dts/upstream/src/riscv/`, `arch/riscv/dts/`)
4. **Active Vendor BSP Forks** (`linux4microchip`, `revyos/th1520-linux-kernel`, `spacemit-com`, `starfive-tech`, `kendryte`, `riscv/meta-riscv`)
5. **DT-Schema & Binding Documentation** (`Documentation/devicetree/bindings/`)

Stale mirrors (`devicetree-org/devicetree-source`, `riscv-device-tree-doc`) are historical references only.

### 3.2 Eleven Silicon Subdirectories (`arch/riscv/boot/dts/`)
Track and validate across all eleven vendor subdirectories: `allwinner/`, `andes/`, `canaan/` (formerly `kendryte/`), `eswin/`, `microchip/`, `renesas/`, `sifive/`, `sophgo/`, `spacemit/`, `starfive/`, and `thead/`.

### 3.3 Build & Schema Validation Rules
* Every custom or patched `.dts` file must be registered under `dtb-$(CONFIG_...)` in its subdirectory `Makefile` so Kbuild compiles it.
* Cross-compilation (`make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig` and `make -j$(nproc) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- Image dtbs`) must succeed cleanly.
* `.dts` files must be checked against DT-Schema YAML bindings via `make dtbs_check`; any new or modified `.dts`/binding added by KoinV must introduce zero schema errors or new warnings.

---

## 4. Reproducibility, Supply-Chain Integrity & Fallback Determinism

* **Reproducible & Auditable Builds:** Pin upstream commits, BSP patch sets, and build inputs where possible; preserve deterministic build flags and document any out-of-tree patches or binary blobs.
* **Licensing & Attribution Compliance:** Respect upstream and vendor licenses (GPL/MIT/BSD/firmware terms) and maintain clear attribution for imported Device Trees, BSP patches, and ecosystem references.
* **Deterministic Fallbacks:** Never allow a known paging (`Sv57`), firmware (`UEFI` vs. `extlinux`), or memory (`64 MB` vs. `>= 512 MB`) mismatch to fail silently when a supported fallback (`no5lvl`, `no4lvl`, `$fdt_addr_r`, `u-boot-menu`, or the Tier 2 minimal variant) applies.
* **Lifecycle & Tier Governance:** Promote boards from vendor BSP overlays to mainline DT/kernel paths as upstream support matures, and explicitly document support status rather than overclaiming untested boards as fully verified.

---

## 5. Verification & Release Readiness Checklist

* [ ] `riscv64` base packages target `RV64GC` (`RVA20`), with `glibc-hwcaps` / `hwprobe` / `IFUNC` used for `RVA23` / `RVV 1.0` acceleration and any full `RVA23` build isolated to an opt-in track.
* [ ] All 11 vendor directories under `arch/riscv/boot/dts/` are accounted for, custom `.dts` entries are in `dtb-$(CONFIG_...)`, and `Image` + `dtbs` cross-build cleanly.
* [ ] KoinV-added/modified `.dts` files pass `make dtbs_check` without new errors or warnings.
* [ ] Kernel errata (`CONFIG_ERRATA_THEAD` MAE/CMO/PMU, `CONFIG_ERRATA_SIFIVE` CIP-453/CIP-1200, `JH7100` non-coherent DMA, `CONFIG_ERRATA_ANDES_CMO`) and `no5lvl` / `no4lvl` paging fallbacks are configured and tested.
* [ ] `PLATFORM=generic` OpenSBI, `OF_UPSTREAM` U-Boot UEFI (`BOOTRISCV64.EFI`), `systemd-boot-efi` / `grub-efi-riscv64`, `u-boot-efi-dtb`, `ACPI`, and `u-boot-menu` / `flash-kernel` fallbacks are verified.
* [ ] Known DT/board quirks (VisionFive 2 8 GiB memory & `v1.2B`/`v1.3A` SD card handling, PolarFire Video Kit `i2c0`/`i2c1`, SpacemiT K3 CoM260 TQ overlays) are handled.
* [ ] Tier 1, Tier 2, Tier 3 boundaries and QEMU (`qemu-system-riscv64`) boot smoke tests pass before release.

---

## 6. Constitutional Amendments

This constitution may be amended only through an explicit change proposal with technical rationale, review of impact on existing principles and checklists, and an incremented version and changelog entry in this document.

*KoinV Constitution v1.1 — Updated 2026-11-20*