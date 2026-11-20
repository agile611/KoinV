# KoinV Constitution

## Core Engineering, Testing, and Architectural Principles

This constitution establishes the immutable principles governing the KoinV RISC-V Linux distribution. All code, configuration, and process decisions must comply with these principles.

---

## 1. Architectural Pillars

### 1.1 CPU Architecture & User Space — `riscv64` (RV64GC) + glibc-hwcaps

- **64-bit Exclusive**: Target only the official 64-bit little-endian `riscv64` architecture. `riscv32` is not a supported release architecture.
- **Baseline ISA**: Compile base user-space packages for **RV64GC (RVA20)** to ensure binary compatibility with pre-2026 boards (VisionFive 2, Milk-V Mars, Star64, Lichee Pi 4A, Allwinner D1, Milk-V Pioneer) and official Debian repositories.
- **Runtime Acceleration**: Use **glibc-hwcaps** backed by the Linux **hwprobe** syscall (`RISCV_HWPROBE_KEY_IMA_EXT_0`) and **IFUNC** runtime resolvers to dynamically load optimized shared libraries (openssl, libgcrypt, libjpeg-turbo) and RVV 1.0 vector routines on RVA23-capable hardware (SpacemiT K3) without breaking RV64GC compatibility.
- **Optional RVA23 Opt-in**: Maintain a separate opt-in repository/overlay compiled with `rva23_defconfig` / `-march=rva23u64` for workloads requiring whole-system RVA23 optimization.

### 1.2 Linux Kernel Strategy — Unified Mainline + Modular BSP Layer

- **Unified Mainline Kernel**: Single kernel image (`linux-image-riscv64`) compiling all available `.dtb` files.
- **Mandatory Errata**: Enable four critical errata families in `arch/riscv/Kconfig.errata`:
  - `CONFIG_ERRATA_THEAD` with `ERRATA_THEAD_MAE`, `ERRATA_THEAD_CMO`, `ERRATA_THEAD_PMU`
  - `CONFIG_ERRATA_SIFIVE` with `ERRATA_SIFIVE_CIP_453`, `ERRATA_SIFIVE_CIP_1200`
  - StarFive JH7100 non-coherent DMA errata (SiFive cache controller errata)
  - `CONFIG_ERRATA_ANDES_CMO` (for `ARCH_R9A07G043` / Renesas RZ/Five)
- **Modular BSP Layer (RevyOS Model)**: Preserve 100% standard Debian (trixie) user space and APT ecosystem while offering modular, SoC-specific kernel and firmware packages (TH1520, SG2042, etc.) alongside mainline kernel.
- **Flexible MMU Paging**: Support Sv39, Sv48, Sv57 with automatic widest-mode selection. Expose `no5lvl` (force Sv48) and `no4lvl` (force Sv39) kernel command-line fallbacks.

### 1.3 Boot Chain, DTB Variations & UEFI/ACPI Transition

- **Privilege-Level Boot Sequence**: M-Mode BootROM → SPL (FSBL) → FIT container (OpenSBI `PLATFORM=generic` + U-Boot S-Mode) → Linux kernel + `.dtb`.
- **Critical DTB Variations Handled**:
  - Memory node overrides (VisionFive 2 8 GiB vs default 4 GiB)
  - PCB revision differences (VisionFive 2 v1.2B `cd-gpios` vs v1.3A `broken-cd`)
  - Disabled buses requiring `status = "okay"` (Microchip PolarFire Video Kit i2c0/i2c1)
  - PMIC variants via compile-time Device Tree overlays (SpacemiT K3 CoM260 TQ)
- **Primary Path (UEFI-First + EBBR/BRS)**:
  - Generic OpenSBI (`PLATFORM=generic`) + U-Boot (`OF_UPSTREAM`) → `EFI/BOOT/BOOTRISCV64.EFI`
  - `systemd-boot-efi` (UKIs) and `grub-efi-riscv64` both available
  - `u-boot-efi-dtb` for transparent DTB updates from `/boot`
  - ACPI enabled for BRS server compliance
- **Fallback Path (Non-UEFI)**: `u-boot-menu` (auto-generates `extlinux.conf`) + `flash-kernel`

### 1.4 Embedded Fallback — Minimal Rootfs for Tier 2

- Provide separate minimal image variant built via Buildroot/BusyBox (musl libc, no systemd, 5–50 MB rootfs) sharing exact same kernel and `.dtb` files.
- Covers 18 ultra-light boards (64 MB–512 MB RAM or hybrid ARM+RISC-V).

---

## 2. Hardware Tier Classification

### Tier 1 — Full Linux Systems (54 Boards)
- 64-bit, 512 MB–64 GB RAM/DDR4
- Standard Debian `riscv64` (glibc + systemd)
- Includes 2026 variants: SpacemiT K3 AI Book, PolarFire Discovery Kit, K3 CoM260 TQ, DeepComputing Mainboard III RVA23, C2201 dual-socket V100

### Tier 2 — Ultra-Light/Constrained/Hybrid (18 Boards)
- 64 MB–512 MB RAM or SRAM/PSRAM, or ARM+RISC-V heterogeneous
- Minimal musl + BusyBox/Buildroot variant (5–50 MB)
- Shares kernel and `.dtb` with Tier 1

### Tier 3 — MCUs & RTOS-Only (27 Boards)
- **EXCLUDED** from general-purpose Linux distribution
- WCH QingKe, Espressif ESP32, GigaDevice GD32VF103, Bouffalo Lab, other MCUs

### Dynamic/Non-Static DT Targets
- QEMU (`virt`, `sifive_u`, `microchip-icicle`, `shakti-c`, `tt_atlantis` via `${fdtcontroladdr}`)
- Spike (internal `riscv/dts.cc` + `dtc`)
- LiteX + LiteX-Boards (250+ FPGA boards via `csr.json`)
- Renode (custom platforms / `csr.json`)
- OpenPiton / Chipyard
- Coreboot (ACPI tables, no standard `.dts`)

---

## 3. Device Tree Sources & Build Pipeline

### Authoritative Sources (Priority Order)
1. **Mainline Linux Kernel** (`torvalds/linux` → `arch/riscv/boot/dts/`)
2. **devicetree-rebasing.git** (`src/riscv`, `Bindings/`, `include/dt-bindings`)
3. **Official U-Boot** (`u-boot/u-boot` → `dts/upstream/src/riscv/`, `arch/riscv/dts/`)
4. **Vendor BSP Forks** (`linux4microchip`, `revyos/th1520-linux-kernel`, `spacemit-com`, `starfive-tech`, `kendryte`, `riscv/meta-riscv`)
5. **Schema/Binding Docs** (`Documentation/devicetree/bindings/`)

### Eleven Silicon Families (Vendor Directories)
`allwinner/`, `andes/`, `canaan/`, `eswin/`, `microchip/`, `renesas/`, `sifive/`, `sophgo/`, `spacemit/`, `starfive/`, `thead/`

### Build & Validation Requirements
- Every custom/patched `.dts` registered in subdirectory `Makefile` under `dtb-$(CONFIG_...)`
- `make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig` succeeds
- `make -j$(nproc) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- Image dtbs` produces all `.dtb`
- `make dtbs_check` passes with zero errors/warnings against DT-Schema YAML bindings
- QEMU dynamic DTBs generated at runtime via `${fdtcontroladdr}`

---

## 4. Engineering Standards

### 4.1 Modular Architecture
- Keep build scripts, Device Tree overlays, kernel fragments, and packaging recipes clean, decoupled, and aligned with repository conventions.
- Separate concerns: user space (Debian), kernel (mainline + errata), BSP (modular), boot (UEFI-first), embedded fallback (Buildroot).

### 4.2 Defensive Error Handling
- All build scripts, fetchers, Kbuild/DTS checks, and QEMU test harnesses must include:
  - Clear error handling
  - Non-zero exit propagation
  - Structured logging

### 4.3 Code Integrity
- Preserve existing containerized/QEMU workflows
- Maintain reproducibility guarantees
- Keep configuration files and linting/validation rules intact

### 4.4 No Temporary Staging
- **Never** copy repository files to `/tmp` or external directories for inspection or processing
- Read, inspect, and modify files **in-place** within the repository workspace root
- Print all tool and terminal outputs directly to stdout in real-time

---

## 5. Testing & Validation Requirements

### 5.1 Device Tree Validation Checklist
- [ ] All 11 vendor directories present in `arch/riscv/boot/dts/`
- [ ] Every custom/patched `.dts` registered in subdirectory `Makefile` under `dtb-$(CONFIG_...)`
- [ ] `make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig` succeeds
- [ ] `make -j$(nproc) ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- Image dtbs` produces all `.dtb` files
- [ ] `make dtbs_check` passes with zero errors/warnings against DT-Schema YAML bindings
- [ ] QEMU `virt`, `sifive_u`, `microchip-icicle`, `shakti-c`, `tt_atlantis` DTBs generated at runtime via `${fdtcontroladdr}`

### 5.2 Kernel Errata Validation Checklist
- [ ] `CONFIG_ERRATA_THEAD=y` with `ERRATA_THEAD_MAE`, `ERRATA_THEAD_CMO`, `ERRATA_THEAD_PMU`
- [ ] `CONFIG_ERRATA_SIFIVE=y` with `ERRATA_SIFIVE_CIP_453`, `ERRATA_SIFIVE_CIP_1200`
- [ ] `CONFIG_ERRATA_ANDES_CMO=y` (for `ARCH_R9A07G043` / Renesas RZ/Five)
- [ ] JH7100 non-coherent DMA errata enabled
- [ ] Kernel command line supports `no5lvl` (force Sv48) and `no4lvl` (force Sv39) fallbacks

### 5.3 Boot Chain Validation Checklist
- [ ] OpenSBI built with `PLATFORM=generic`
- [ ] U-Boot built with `OF_UPSTREAM` for UEFI support
- [ ] `EFI/BOOT/BOOTRISCV64.EFI` loadable via U-Boot UEFI
- [ ] `systemd-boot-efi` and `grub-efi-riscv64` both available in Debian Trixie
- [ ] `u-boot-efi-dtb` package included for transparent DTB updates from `/boot`
- [ ] ACPI enabled in kernel for BRS server compliance
- [ ] `u-boot-menu` and `flash-kernel` available for non-UEFI fallback
- [ ] VisionFive 2 8 GiB memory node override handled
- [ ] VisionFive 2 PCB revision microSD quirks (`cd-gpios` vs `broken-cd`) addressed
- [ ] Microchip PolarFire Video Kit `i2c0`/`i2c1` `status = "okay"` handled
- [ ] SpacemiT K3 CoM260 TQ power-regulator overlays supported

### 5.4 Hardware Tier Coverage Validation Checklist
- [ ] **Tier 1 (54 boards)**: All boot with standard Debian `riscv64` (glibc + systemd)
- [ ] **Tier 2 (18 boards)**: Minimal musl + BusyBox/Buildroot variant (5–50 MB) shares kernel and `.dtb` files
- [ ] **Tier 3 (27 boards)**: Excluded from general-purpose Linux distribution builds
- [ ] **Dynamic DT targets**: QEMU, Spike, LiteX, Renode, OpenPiton/Chipyard, Coreboot boot mechanisms documented
- [ ] **2026 variants**: SpacemiT K3 AI Book, PolarFire Discovery Kit, K3 CoM260 TQ, DeepComputing Mainboard III RVA23, C2201 dual-socket V100 supported

### 5.5 QA & Test Verification Suites
- Validate build scripts, `.dts`/`.dtb` artifacts, Kconfig errata flags, UEFI/extlinux boot configurations
- QEMU boot smoke tests: `qemu-system-riscv64 -machine virt ...`
- Run repository unit, lint, or integration test suites
- Verify clean `git status` and `git diff --stat` before committing

---

## 6. Git Discipline & Commit Protocol

- Create feature branch per task: `git switch -c <slug>`
- Show `git diff --stat` before committing to verify scope
- Stage and commit with conventional commit messages:
  ```bash
  git add -A && git commit -m "<type>(<scope>): <short description>"
  ```
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- Include Co-authored-by trailer:
  ```
  Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
  ```

---

## 7. Environment & Tooling Standards

### Dynamic Environment Bootstrap
- **Debian/Rootfs Tooling**: `dtc`, `mmdebstrap`, `debootstrap`, `qemu-system-riscv64`, `riscv64-linux-gnu-gcc`
- **Cross-compilation**: `export ARCH=riscv && export CROSS_COMPILE=riscv64-linux-gnu-`
- **Python**: Use `uv` if available, else `python3 -m venv .venv`
- **Node.js**: `npm ci` or `npm install` if `package.json` exists

### Scoped Searching
- Always exclude system, hidden, and build directories:
  ```bash
  grep -rn --exclude-dir={.git,node_modules,.venv,workspaceStorage,dist,build,.next,.turbo} "pattern" .
  ```

### Deterministic Fallback Protocol
When a command fails:
1. Never repeat the exact same command
2. Never output narrative status updates
3. Switch execution medium immediately (shell → inline Python)
4. Inspect terminal output via `execute/getTerminalOutput` before fallback

---

## 8. Anti-Loop Guard & Recovery

- **Maximum 3 build/patch attempts** per issue
- If build/test fails 3× after patching: **STOP**, output exact terminal error, ask user: `"Build failed 3×. Error: <stderr>. Next step?"`
- Zero conversational preamble — every turn begins immediately with tool call
- No narrative text, internal commentary, or strategy descriptions

---

## 9. Root Workspace Isolation

- Anchor all operations strictly inside the active project repository root (`./` or `$WORKSPACE_ROOT`)
- **NEVER** inspect, search, or navigate into:
  - Parent directories (`../`)
  - System folders (`/Users/...`, `/home/...`)
  - VS Code internal storage (`.vscode/`, `workspaceStorage/`, `chat-session-resources`)

---

## 10. Reference Ecosystem Alignment

| Project Type | Reference Implementations | KoinV Alignment |
|--------------|--------------------------|-----------------|
| Generalist Binary Distros | Debian 13 "Trixie", Ubuntu, Fedora, Arch | Package base = Debian Trixie; UEFI-first boot |
| Meta-Distros & Embedded | Buildroot, Yocto `meta-riscv`, Alpine, OpenWrt | Tier 2 minimal variant via Buildroot/BusyBox |
| SBC & Community Distros | Armbian, DietPi, RevyOS, Bianbu, BredOS | Modular BSP layer following RevyOS model |
| Declarative/Source-Based | Gentoo, NixOS, GNU Guix | Optional opt-in RVA23 overlay for custom `-march` |

---

## 11. Amendment Process

This constitution may be amended only by:
1. Explicit user request with rationale
2. Unanimous agreement on architectural necessity
3. Update to this document with versioned changelog
4. All existing validation checklists updated to reflect changes

---

*KoinV Constitution v1.0 — Established 2026-11-20*
*Based on: "Comprehensive RISC-V Models, Device Trees, and Architecture Guide for a Debian-Compatible Linux Distribution"*