# KoinV Specification

**Version:** 1.0  
**Date:** 2026-11-20  
**Status:** Draft  
**Constitution:** v1.1 (2026-11-20)

---

## 1. Problem Statement & Goals

### 1.1 Problem Statement

The RISC-V hardware ecosystem is rapidly expanding but severely fragmented across multiple axes:

- **ISA Profile Fragmentation:** Pre-2026 boards (VisionFive 2, Milk-V Mars, Star64, Lichee Pi 4A, Allwinner D1, Milk-V Pioneer) implement `RV64GC`/`RVA20`, while newer silicon (SpacemiT K3, future RVA23 servers) implements `RVA23` with mandatory vector (`RVV 1.0`) and hypervisor extensions. Distributions mandating RVA23 (e.g., Ubuntu 25.10+) leave existing hardware unable to run the user space.

- **Silicon Errata & Boot Variance:** Early commercial RISC-V SoCs (T-Head C906/C910, SiFive U74/U54, Andes AX45MP, StarFive JH7100) were designed before standard extensions like `Zicbom` (cache-block management) or `Svpbmt` (page-based memory types) were ratified. Without kernel errata, these boards hang or suffer DMA failures. Board revisions introduce Device Tree quirks (memory size, microSD detection, disabled buses) that break boot if unhandled.

- **Boot Chain Inconsistency:** The privilege-level boot flow (M-Mode BootROM → SPL → FIT/OpenSBI+U-Boot → Linux) varies across vendors. Some boards ship UEFI-capable U-Boot; others ship stripped-down vendor U-Boot lacking UEFI. Device Trees may be stale in SPI flash vs. updated in `/boot`.

- **Tier Mismatch:** A single Debian `glibc`+`systemd` rootfs (≥500 MB) cannot fit on 64–256 MB boards, yet these boards run Linux kernels and share DTBs with larger boards. MCU-class boards (2 KB–1 MB SRAM) cannot run Linux at all.

- **Upstream Lag:** Vendor subsystems (GPU, NPU, video codecs, USB PHYs) often land in downstream BSP forks (`revyos/th1520-linux-kernel`, `linux4microchip`, `spacemit-com`, `starfive-tech`, `riscv/meta-riscv`) months before mainline integration.

### 1.2 Goals

| Goal ID | Goal | Success Metric |
|---------|------|----------------|
| G1 | **Universal `riscv64` Debian-compatible distribution** | Boots on all 54 Tier 1 boards with standard Debian user space |
| G2 | **RV64GC baseline with RVA23 runtime acceleration** | Base packages compile for `RV64GC`; `glibc-hwcaps`+`hwprobe`+`IFUNC` loads optimized libs on RVA23 hardware |
| G3 | **Unified kernel with mandatory errata** | Single `linux-image-riscv64` builds all DTBs; T-Head, SiFive, JH7100, Andes errata enabled |
| G4 | **UEFI-first boot with non-UEFI fallback** | `systemd-boot`/`GRUB2` + `u-boot-efi-dtb` primary; `u-boot-menu`/`extlinux` fallback verified |
| G5 | **Modular BSP layer for vendor subsystems** | Optional SoC-specific kernel/firmware packages (TH1520, SG2042, etc.) alongside mainline |
| G6 | **Tier 2 minimal variant for constrained boards** | Separate `musl`+`BusyBox`/Buildroot image (5–50 MB) sharing kernel+DTBs |
| G7 | **Reproducible, schema-validated Device Trees** | All 11 vendor `dts/` dirs tracked; custom DTBs registered in Kbuild; `make dtbs_check` passes |
| G8 | **Dynamic DT environment support** | QEMU, Spike, LiteX, Renode, OpenPiton, Coreboot boot paths documented and tested |

---

## 2. User Stories / Use Cases

### 2.1 Primary Personas

| Persona | Description | Primary Needs |
|---------|-------------|---------------|
| **SBC Developer** | Hobbyist/professional using VisionFive 2, Milk-V Mars, Star64, Lichee Pi 4A | Debian packages work out of box; serial console; easy image flash |
| **Workstation/Server Operator** | Running Sophgo SG2042, SpacemiT K3, BRS servers | UEFI boot; ACPI support; RVA23 acceleration for workloads |
| **Embedded Engineer** | Deploying on D1/D1s, Milk-V Duo, LicheeRV Nano (64–512 MB) | Minimal rootfs; same kernel/DTBs; Buildroot/musl variant |
| **CI/Automation Engineer** | Testing in QEMU, Spike, Renode, LiteX FPGA | Reproducible images; smoke tests; dynamic DT support |
| **BSP Maintainer** | Integrating vendor patches for TH1520, SG2042, K3 | Modular BSP packages; clear upstreaming path; errata handling |

### 2.2 User Stories

| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-01 | As an SBC developer, I want to flash a single image to my VisionFive 2 and boot to a Debian prompt | Image writes via `dd`; UART 115200 shows OpenSBI→U-Boot→systemd-boot→login prompt |
| US-02 | As a server operator, I want UEFI boot with ACPI on my SpacemiT K3 server | `BOOTRISCV64.EFI` loads; `systemd-boot` shows entries; ACPI tables present |
| US-03 | As an embedded engineer, I want a minimal image for my Milk-V Duo 64M | Image <50 MB; boots to BusyBox shell; shares kernel/DTB with Tier 1 |
| US-04 | As a CI engineer, I want QEMU `virt` boot smoke test in <2 minutes | `qemu-system-riscv64 -machine virt` boots to login; exits cleanly |
| US-05 | As a BSP maintainer, I want to add TH1520 GPU support without breaking mainline | `koinv-bsp-th1520` package installs alongside `linux-image-riscv64`; no conflicts |
| US-06 | As a developer on RV64GC hardware, I want `openssl` to use RVV on RVA23 hardware automatically | `openssl speed` shows vectorized routines on K3; same binary works on VisionFive 2 |
| US-07 | As a board bring-up engineer, I need `no5lvl`/`no4lvl` fallbacks for paging issues | Kernel cmdline `no5lvl` forces Sv48; `no4lvl` forces Sv39; both tested |
| US-08 | As a maintainer, I want all custom DTBs validated against schema before merge | `make dtbs_check` passes with zero new errors/warnings on PR |

---

## 3. Functional Requirements

### 3.1 Core Distribution (Tier 1)

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| FR-01 | Build base user space for `riscv64` targeting `RV64GC` (`RVA20`) ISA | P0 |
| FR-02 | Use `mmdebstrap`/`debootstrap` with Debian 13 "Trixie" repositories | P0 |
| FR-03 | Provide `glibc-hwcaps` directories for `RVA23U64` optimized libraries | P0 |
| FR-04 | Implement `IFUNC` resolvers in glibc for `RVV 1.0` routine selection via `RISCV_HWPROBE_KEY_IMA_EXT_0` | P0 |
| FR-05 | Maintain optional `RVA23` opt-in repository/overlay (`rva23_defconfig`, `-march=rva23u64`) | P1 |
| FR-06 | Build unified `linux-image-riscv64` kernel with all mainline `.dtb` files | P0 |
| FR-07 | Enable mandatory errata: `CONFIG_ERRATA_THEAD` (MAE/CMO/PMU), `CONFIG_ERRATA_SIFIVE` (CIP-453/CIP-1200), JH7100 DMA, `CONFIG_ERRATA_ANDES_CMO` | P0 |
| FR-08 | Support `Sv39`/`Sv48`/`Sv57` paging with `no5lvl` (force Sv48) and `no4lvl` (force Sv39) cmdline fallbacks | P0 |
| FR-09 | Build generic OpenSBI (`PLATFORM=generic`) | P0 |
| FR-10 | Build U-Boot with `OF_UPSTREAM` for UEFI (`BOOTRISCV64.EFI`) | P0 |
| FR-11 | Package `systemd-boot-efi` (UKIs) and `grub-efi-riscv64` for Debian Trixie | P0 |
| FR-12 | Include `u-boot-efi-dtb` for transparent DTB updates from `/boot` | P0 |
| FR-13 | Enable kernel `ACPI` support for BRS server compliance | P0 |
| FR-14 | Package `u-boot-menu` (auto-generates `extlinux.conf`) and `flash-kernel` for non-UEFI fallback | P0 |
| FR-15 | Handle VisionFive 2 8 GiB memory node override in boot scripts/overlays | P0 |
| FR-16 | Handle VisionFive 2 PCB revision quirks (`v1.2B` `cd-gpios` vs `v1.3A` `broken-cd`) | P0 |
| FR-17 | Handle Microchip PolarFire Video Kit `i2c0`/`i2c1` `status="okay"` overlays | P1 |
| FR-18 | Handle SpacemiT K3 CoM260 TQ PMIC variant overlays | P1 |
| FR-19 | Track all 11 vendor `dts/` subdirectories (`allwinner/`, `andes/`, `canaan/`, `eswin/`, `microchip/`, `renesas/`, `sifive/`, `sophgo/`, `spacemit/`, `starfive/`, `thead/`) | P0 |
| FR-20 | Register all custom/patched `.dts` files in subdirectory `Makefile` under `dtb-$(CONFIG_...)` | P0 |
| FR-21 | Cross-compile kernel: `make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig` + `make -j$(nproc) Image dtbs` | P0 |
| FR-22 | Validate DTBs: `make dtbs_check` passes with zero errors/warnings | P0 |

### 3.2 Tier 2 Minimal Variant

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| FR-23 | Build separate minimal rootfs using Buildroot/musl/BusyBox (5–50 MB) | P0 |
| FR-24 | Share kernel and `.dtb` artifacts with Tier 1 build | P0 |
| FR-25 | Target 18 Tier 2 boards (D1s, Milk-V Duo, LicheeRV Nano, Pine64 Ox64/Oz64, etc.) | P0 |
| FR-26 | Exclude `systemd`; use BusyBox init or minimal init system | P0 |

### 3.3 Tier 3 Exclusion

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| FR-27 | Explicitly exclude 27 MCU/RTOS boards (WCH, ESP32, GD32VF103, Bouffalo Lab, etc.) | P0 |
| FR-28 | Document exclusion rationale in README and constitution | P1 |

### 3.4 Dynamic DT Environment Support

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| FR-29 | Support QEMU `virt`, `sifive_u`, `microchip-icicle`, `shakti-c`, `tt_atlantis` via `${fdtcontroladdr}` | P0 |
| FR-30 | Support Spike dynamic DTS generation via `riscv/dts.cc` + `dtc` | P1 |
| FR-31 | Enable mainline LiteX drivers (`liteuart`, `litex`, `litex_mmc`, `litex_soc_ctrl`) for 250+ FPGA boards | P1 |
| FR-32 | Support Renode custom platforms / LiteX `csr.json` import | P1 |
| FR-33 | Support OpenPiton/Chipyard boot chains via OpenSBI `PLATFORM=fpga/openpiton` | P2 |
| FR-34 | Document Coreboot ACPI table generation path (no Linux `.dts`) | P2 |

### 3.5 Build & Release Infrastructure

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| FR-35 | Repository structure: `profiles/`, `overlays/`, `packages/`, `kernel/`, `images/`, `bsp/`, `docs/`, `tests/` | P0 |
| FR-36 | `mmdebstrap` + `genimage` image assembly pipeline | P0 |
| FR-37 | Cross-build host requirements documented (`qemu-user-static`, `binfmt-support`, `riscv64-linux-gnu-gcc`) | P0 |
| FR-38 | Reproducible builds: pinned upstream commits, deterministic flags | P1 |
| FR-39 | SBOM generation for license compliance | P1 |
| FR-40 | CI pipeline: `dtbs_check`, QEMU smoke test, hwcaps verification | P0 |

### 3.6 Versioning — CalVer (Calendar Versioning)

All KoinV releases and artifacts **must** use **CalVer** (Calendar Versioning) per Constitution §2.1:

| Req ID | Requirement | Priority |
|--------|-------------|----------|
| FR-41 | Daily/development builds use `YY.MM.DD` format (e.g., `26.11.20`) | P0 |
| FR-42 | Monthly stable releases use `YY.MM` format (e.g., `26.11`) | P0 |
| FR-43 | Patch/hotfix releases use `YY.MM.pN` format (e.g., `26.11.p1`) | P1 |
| FR-44 | Git annotated tags for all versions: `vYY.MM.DD`, `vYY.MM`, `vYY.MM.pN` | P0 |
| FR-45 | Image artifacts embed version: `koinv-trixie-riscv64-YY.MM.DD.img.xz` | P0 |
| FR-46 | Kernel config sets `CONFIG_LOCALVERSION="-koinv-YY.MM.DD"` | P0 |
| FR-47 | U-Boot sets `CONFIG_VERSION_VARIABLE="koinv-YY.MM.DD"` | P1 |
| FR-48 | No SemVer (`MAJOR.MINOR.PATCH`) — CalVer only | P0 |
| FR-49 | Automation: daily tag on `main` CI success; monthly tag on 1st of month | P1 |

---

## 4. Non-Functional Requirements

### 4.1 Performance

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-01 | Base user space binary compatibility on RV64GC hardware | 100% of Debian `riscv64` packages installable |
| NFR-02 | `glibc-hwcaps` library selection latency | <5 ms overhead per library load |
| NFR-03 | `IFUNC` resolver overhead for RVV routines | <1% vs. static linking |
| NFR-04 | Kernel boot time (OpenSBI → login prompt) on Tier 1 boards | <30 seconds typical |
| NFR-05 | QEMU `virt` smoke test execution time | <120 seconds |
| NFR-06 | Minimal variant (Tier 2) boot time on 64 MB board | <60 seconds |

### 4.2 Security

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-07 | Secure boot chain verification (OpenSBI → U-Boot → kernel) | UEFI Secure Boot supported on capable hardware |
| NFR-08 | Kernel hardening flags enabled (`CONFIG_HARDENED_USERCOPY`, `CONFIG_FORTIFY_SOURCE`, `CONFIG_STACKPROTECTOR_STRONG`) | All enabled |
| NFR-09 | Reproducible builds for supply-chain integrity | Bit-for-bit reproducible with pinned inputs |
| NFR-10 | SBOM includes all upstream and vendor components | SPDX/JSON format |
| NFR-11 | Firmware blob redistribution compliance documented per vendor | Per-board documentation |

### 4.3 Compatibility

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-12 | Debian 13 "Trixie" package compatibility | 100% of `riscv64` `main` archive installable |
| NFR-13 | Kernel ABI stability across point releases | No breaking changes without version bump |
| NFR-14 | DTB forward/backward compatibility | New DTBs boot on older kernels; old DTBs boot on newer kernels |
| NFR-15 | UEFI `BOOTRISCV64.EFI` compatibility with `systemd-boot` and `GRUB2` | Both bootloaders functional |
| NFR-16 | `extlinux` fallback compatibility with vendor U-Boot | Tested on ≥3 non-UEFI boards |

### 4.4 Maintainability

| Req ID | Requirement | Target |
|--------|-------------|--------|
| NFR-17 | Constitution compliance verification automated | CI gate on all PRs |
| NFR-18 | Board support status tracked explicitly (`GOOD`/`BASIC`/`CFT`/`WIP`) | Per-board matrix in docs |
| NFR-19 | Vendor BSP patches upstreamed within 2 kernel cycles | Tracked in `bsp/` with upstream PR links |
| NFR-20 | Documentation as code (Markdown in `docs/`) | All architecture decisions recorded |

---

## 5. Acceptance Criteria

### 5.1 Release Gate Criteria (All Must Pass)

| Criterion | Verification Method |
|-----------|---------------------|
| **AC-01** | `mmdebstrap` builds base rootfs without errors |
| **AC-02** | `make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig` succeeds |
| **AC-03** | `make -j$(nproc) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- Image dtbs` produces all DTBs |
| **AC-04** | `make dtbs_check` exits 0 with zero new warnings/errors |
| **AC-04** | Kernel config includes all mandatory errata (`grep -E "CONFIG_ERRATA_(THEAD|SIFIVE|ANDES)" .config`) |
| **AC-05** | Kernel config includes `CONFIG_NO5LVL` and `CONFIG_NO4LVL` (or cmdline equivalents) |
| **AC-06** | OpenSBI builds with `PLATFORM=generic` |
| **AC-07** | U-Boot builds with `OF_UPSTREAM`; `BOOTRISCV64.EFI` present |
| **AC-08** | `systemd-boot-efi` and `grub-efi-riscv64` packages install in rootfs |
| **AC-09** | `u-boot-efi-dtb` package installs; DTB override from `/boot` verified |
| **AC-10** | `u-boot-menu` generates `extlinux.conf` on kernel install |
| **AC-11** | QEMU `virt` smoke test: `qemu-system-riscv64 -machine virt -kernel Image -dtb virt.dtb -append "console=ttyS0" -nographic` boots to login |
| **AC-12** | VisionFive 2 8 GiB memory detection verified (DTB override applied) |
| **AC-13** | Tier 2 minimal image builds <50 MB; boots on Milk-V Duo 64M (or QEMU equivalent) |
| **AC-14** | `glibc-hwcaps` directories present for `RVA23U64`; `IFUNC` resolver test passes |
| **AC-15** | All 11 vendor `dts/` directories accounted for in build |
| **AC-16** | License compliance: SPDX headers on KoinV files; SBOM generated |

### 5.2 Per-Board Maturity Tracking

| Board | Tier | Target Status | Verification |
|-------|------|---------------|--------------|
| VisionFive 2 | 1 | GOOD | AC-01 through AC-12 |
| Milk-V Mars | 1 | GOOD | AC-01 through AC-12 |
| Star64 | 1 | BASIC | AC-01 through AC-11 |
| Lichee Pi 4A | 1 | GOOD | AC-01 through AC-11 |
| BeagleV-Ahead | 1 | CFT | AC-01 through AC-11 |
| Milk-V Pioneer | 1 | GOOD | AC-01 through AC-11 |
| SpacemiT K3 (Pico-ITX/CoM260) | 1/2 | BASIC/CFT | AC-01 through AC-11 + AC-13 |
| Milk-V Duo 64M | 2 | BASIC | AC-13 |
| LicheeRV Nano | 2 | BASIC | AC-13 |
| QEMU `virt` | Dynamic | GOOD | AC-11 |

*Status definitions: `GOOD` = daily driver; `BASIC` = boots, core functions; `CFT` = can flash/test; `WIP` = work in progress*

---

## 6. Scope Boundaries

### 6.1 In Scope

| Area | Details |
|------|---------|
| **Architecture** | `riscv64` only (little-endian) |
| **Base Distribution** | Debian 13 "Trixie" via `mmdebstrap`/`debootstrap` |
| **ISA Baseline** | `RV64GC` (`RVA20`) for all base packages |
| **Runtime Acceleration** | `glibc-hwcaps` + `hwprobe` + `IFUNC` for `RVA23U64`/`RVV 1.0` |
| **Kernel** | Mainline + mandatory errata + modular BSP packages |
| **Boot** | UEFI-first (`systemd-boot`/`GRUB2` + `u-boot-efi-dtb` + ACPI) + `extlinux` fallback |
| **Device Trees** | All 11 mainline vendor `dts/` dirs + vendor BSP patches + DT-schema validation |
| **Hardware Tiers** | Tier 1 (54 boards), Tier 2 (18 boards, minimal variant), Dynamic DT targets |
| **Build System** | `mmdebstrap` + `genimage` + cross-compilation toolchain |
| **Validation** | `dtbs_check`, QEMU smoke tests, hwcaps verification, board matrix |
| **Licensing** | MIT for KoinV code; upstream licenses preserved |

### 6.2 Out of Scope

| Area | Details | Rationale |
|------|---------|-----------|
| **`riscv32` Architecture** | 32-bit user space, RV32GC/IMC/IMAC | Not a Debian release architecture; MCU-class only |
| **Tier 3 MCU/RTOS Boards** | 27 boards (WCH, ESP32, GD32VF103, Bouffalo, etc.) | No MMU, insufficient RAM for Linux |
| **Proprietary GPU/NPU Stacks** | Closed-source userspace drivers (e.g., Imagination, vendor NPU SDKs) | Licensing conflicts; upstreaming responsibility of vendors |
| **Non-Debian Base** | Alpine, Arch, Fedora, Yocto, Buildroot as primary user space | Constitution mandates Debian Trixie base |
| **RVA23 Mandatory Baseline** | Requiring `RVA23` for base packages | Breaks pre-2026 hardware; separate opt-in track only |
| **Board-Specific Disk Images** | One image per board | Constitution mandates unified image + DTB/overlay mechanism |
| **Coreboot Porting** | Coreboot payload development | Uses ACPI, not Linux DT; separate firmware project |
| **Windows/BSD Ports** | Non-Linux kernels | Out of distribution scope |
| **Real-Time Kernel (`PREEMPT_RT`)** | Hard real-time patches | Optional add-on; not in base kernel config |

### 6.3 Deferred / Future Consideration

| Area | Details | Condition for Inclusion |
|------|---------|-------------------------|
| **Debian 14 "Forky" Rebase** | Migration to `RVA20U64` baseline | When Debian 14 releases and toolchain stabilizes |
| **Full RVA23 Default** | Switch base ISA to `RVA23U64` | When Tier 1 board population shifts >80% to RVA23-capable |
| **systemd-ukify UKI by Default** | Unified Kernel Images as primary artifact | When `systemd-boot` UKI workflow matures in Debian |
| **OSTree/ABRoot Atomic Updates** | Image-based transactional updates | When Debian supports natively; currently opt-in |
| **Confidential Computing (CoVE/RISC-V CCA)** | Realm/TEE support | When hardware available and Linux support mainlined |

---

## 7. Dependencies & Constraints

### 7.1 Upstream Dependencies

| Dependency | Version/Source | Constraint |
|------------|----------------|------------|
| Debian | 13 "Trixie" | Base package source |
| Linux Kernel | Mainline (latest LTS or stable) | Must support all 11 vendor `dts/` dirs |
| U-Boot | Mainline (latest) | `OF_UPSTREAM` UEFI support |
| OpenSBI | Mainline (latest) | `PLATFORM=generic` |
| glibc | ≥2.38 | `glibc-hwcaps` + `hwprobe` + `IFUNC` support |
| systemd | ≥254 | `systemd-boot-efi`, UKI support |
| dtc | ≥1.7.0 | DT-schema validation |
| QEMU | ≥8.0 | `virt`, `sifive_u`, `microchip-icicle` machines |
| mmdebstrap | ≥1.0 | Rootfs generation |
| genimage | ≥16 | Image assembly |

### 7.2 Vendor BSP Dependencies (Tracked, Not Bundled)

| Vendor | Repo | Purpose |
|--------|------|---------|
| T-Head | `revyos/th1520-linux-kernel` | TH1520 errata, AON, GPU, VPU |
| Microchip | `linux4microchip` (linux-6.12-mchp) | PolarFire Video Kit, Discovery Kit |
| SpacemiT | `spacemit-com` | K3 DTBs, PMIC overlays, AI Book |
| StarFive | `starfive-tech` | JH7110S, VisionFive 2 Lite, U-Boot DTs |
| Sophgo | `riscv/meta-riscv` (Yocto) | SG2000, Duo S, SG2042 patches |
| Kendryte/Canaan | `kendryte` SDK | K230 DTBs |

### 7.3 Constraints

| Constraint | Impact |
|------------|--------|
| Debian `riscv64` port maturity | Limits package availability vs. `amd64`/`arm64` |
| Vendor firmware redistribution | Some blobs require manual download/acceptance |
| Kernel LTS cycle | Errata backports may lag mainline |
| `glibc-hwcaps` adoption | Requires glibc ≥2.38; Debian Trixie ships 2.37 (may need backport) |
| UEFI firmware maturity | Many boards lack production UEFI; fallback path critical |
| CI hardware access | Physical board testing limited; QEMU primary validation |

---

## 8. Glossary

| Term | Definition |
|------|------------|
| **RV64GC** | RISC-V 64-bit base ISA + General extensions (M, A, F, D, C) = `RVA20` profile |
| **RVA23** | RISC-V Architecture 2023 profile: RV64GC + Vector (RVV 1.0) + Hypervisor + Crypto + Bitmanip |
| **glibc-hwcaps** | glibc mechanism to load optimized shared libraries from architecture-specific subdirectories |
| **hwprobe** | Linux syscall (`riscv_hwprobe`) exposing CPU capabilities to user space |
| **IFUNC** | Indirect function (GNU extension) for runtime function resolution based on CPU features |
| **DTB / FDT** | Device Tree Blob / Flattened Device Tree — hardware description passed to kernel |
| **OpenSBI** | Open Supervisor Binary Interface — M-mode firmware providing SBI services |
| **SPL / FSBL** | Secondary Program Loader / First Stage Boot Loader — initializes DDR |
| **FIT** | Flattened Image Tree — U-Boot multi-image container (kernel + DTB + initrd) |
| **EBBR** | Embedded Base Boot Requirements — UEFI boot spec for embedded |
| **BRS** | Boot Runtime Services — RISC-V Server Platform Specification for servers |
| **ZSBL** | Zero Stage Boot Loader — SoC-internal BootROM |
| **BSP** | Board Support Package — SoC-specific kernel/firmware/driver packages |
| **mmdebstrap** | Tool to create Debian chroots/rootfs without root privileges |
| **genimage** | Tool to generate flashable disk images from rootfs + bootloader + partitions |

---

## 9. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-20 | KoinV Team | Initial specification derived from Constitution v1.1 |

---

*This specification is governed by the [KoinV Constitution](constitution.md) v1.1. All implementation must comply with its principles and validation checklists.*
