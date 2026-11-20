# KoinV Requirement Verification Checklist

**Version:** 26.11.20 (CalVer Daily Build)  
**Date:** 2026-11-20  
**Status:** Draft  
**Based On:** [Constitution](constitution.md) 26.11.20 | [Specification](spec.md) 26.11.20 | [Plan](plan.md) 26.11.20

---

## Overview

This checklist provides a traceable verification matrix linking every requirement to its validation method and pass/fail criteria. All items must pass for a release to be considered ready.

**Legend:**
- ✅ **PASS** — Verified, evidence available
- ❌ **FAIL** — Verified, does not meet criteria
- ⏳ **PENDING** — Not yet verified
- 🚫 **BLOCKED** — Cannot verify due to dependency
- 📋 **MANUAL** — Requires manual verification

---

## 1. Functional Requirements Verification (FR-01 through FR-49)

### 1.1 Core Distribution (Tier 1) — FR-01 through FR-22

| Req ID | Requirement | Validation Method | Pass Criteria | Status | Evidence |
|--------|-------------|-------------------|---------------|--------|----------|
| **FR-01** | Base user space targets `riscv64` RV64GC (RVA20) | `dpkg-architecture -qDEB_HOST_ARCH` + `readelf -A` on sample binaries | Architecture = `riscv64`; ISA flags show `rv64gc` | ⏳ | |
| **FR-02** | `mmdebstrap`/`debootstrap` with Debian 13 Trixie | Build log inspection | Rootfs created from `http://deb.debian.org/debian` trixie | ⏳ | |
| **FR-03** | `glibc-hwcaps` dirs for RVA23U64 optimized libs | `ls /usr/lib/riscv64-linux-gnu/hwcaps/` | Directory exists; contains `RVA23U64/` subdir with optimized `.so` | ⏳ | |
| **FR-04** | `IFUNC` resolvers for RVV 1.0 via `RISCV_HWPROBE_KEY_IMA_EXT_0` | `readelf -s` on glibc/openssl; runtime `hwprobe` test | IFUNC symbols present; `hwprobe` returns RVA23U64 bit | ⏳ | |
| **FR-05** | Optional RVA23 opt-in repo/overlay (`rva23_defconfig`) | Separate repo/branch exists | `rva23_defconfig` builds; `-march=rva23u64` packages installable | ⏳ | |
| **FR-06** | Unified `linux-image-riscv64` with all mainline DTBs | `dpkg -L linux-image-riscv64` | All 11 vendor `dts/` DTBs present in `/boot/dtb/` | ⏳ | |
| **FR-07** | Mandatory errata enabled: T-Head (MAE/CMO/PMU), SiFive (CIP-453/1200), JH7100 DMA, Andes CMO | `grep CONFIG_ERRATA /boot/config-*` | All 4 errata families = `y` | ⏳ | |
| **FR-08** | Sv39/Sv48/Sv57 paging with `no5lvl`/`no4lvl` cmdline fallbacks | Boot with `no5lvl`/`no4lvl`; check `dmesg` | Paging mode forced correctly (Sv48/Sv39) | ⏳ | |
| **FR-09** | Generic OpenSBI (`PLATFORM=generic`) | `opensbi --version` + `PLATFORM=generic` build | OpenSBI binary built with `PLATFORM=generic` | ⏳ | |
| **FR-10** | U-Boot with `OF_UPSTREAM` for UEFI (`BOOTRISCV64.EFI`) | `ls /usr/lib/u-boot/*/BOOTRISCV64.EFI` | UEFI binary present; `OF_UPSTREAM` in config | ⏳ | |
| **FR-11** | `systemd-boot-efi` and `grub-efi-riscv64` packages | `dpkg -l systemd-boot-efi grub-efi-riscv64` | Both packages installed | ⏳ | |
| **FR-12** | `u-boot-efi-dtb` for DTB override from `/boot` | Boot test with updated DTB in `/boot` | New DTB loaded instead of SPI DTB | ⏳ | |
| **FR-13** | Kernel ACPI enabled for BRS | `grep CONFIG_ACPI /boot/config-*` | `CONFIG_ACPI=y` | ⏳ | |
| **FR-14** | `u-boot-menu` + `flash-kernel` for non-UEFI fallback | `dpkg -l u-boot-menu flash-kernel`; `extlinux.conf` generated | Both installed; `extlinux.conf` auto-generated on kernel install | ⏳ | |
| **FR-15** | VisionFive 2 8 GiB memory node override | Boot VisionFive 2 8GB; `dmesg \| grep Memory` | 8 GB detected (not 4 GB) | ⏳ | |
| **FR-16** | VisionFive 2 PCB rev quirks (v1.2B `cd-gpios` vs v1.3A `broken-cd`) | Test both revisions; microSD detection | MicroSD works on both revisions | ⏳ | |
| **FR-17** | Microchip PolarFire Video Kit `i2c0`/`i2c1` `status="okay"` overlay | Boot with overlay; `i2cdetect -l` | Both I2C buses visible | ⏳ | |
| **FR-18** | SpacemiT K3 CoM260 TQ PMIC variant overlays | Boot both PMIC variants; voltage check | Correct voltages applied per variant | ⏳ | |
| **FR-19** | Track all 11 vendor `dts/` subdirectories | `ls kernel/arch/riscv/boot/dts/` | All 11 dirs present | ⏳ | |
| **FR-20** | Custom DTBs registered in `dtb-$(CONFIG_...)` in Makefiles | `grep dtb- kernel/arch/riscv/boot/dts/*/Makefile` | All custom DTBs listed | ⏳ | |
| **FR-21** | Cross-compile kernel: `make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig` + `make Image dtbs` | Build log | Clean build; `Image` + all `*.dtb` produced | ⏳ | |
| **FR-22** | `make dtbs_check` passes zero errors/warnings | `make dtbs_check` exit code + output | Exit 0; zero new warnings/errors | ⏳ | |

### 1.2 Tier 2 Minimal Variant — FR-23 through FR-26

| Req ID | Requirement | Validation Method | Pass Criteria | Status | Evidence |
|--------|-------------|-------------------|---------------|--------|----------|
| **FR-23** | Buildroot/musl/BusyBox minimal rootfs (5–50 MB) | `du -sh output/minimal-rootfs` | Size 5–50 MB | ⏳ | |
| **FR-24** | Share kernel + DTBs with Tier 1 | Compare `Image` + `*.dtb` checksums | Identical to Tier 1 build | ⏳ | |
| **FR-25** | Target 18 Tier 2 boards | Boot test matrix | All 18 boards boot to shell | ⏳ | |
| **FR-26** | No systemd; BusyBox init | `ls -l /sbin/init` | Symlink to BusyBox; no systemd | ⏳ | |

### 1.3 Tier 3 Exclusion — FR-27 through FR-28

| Req ID | Requirement | Validation Method | Pass Criteria | Status | Evidence |
|--------|-------------|-------------------|---------------|--------|----------|
| **FR-27** | Exclude 27 MCU/RTOS boards | `grep -r "Tier 3" docs/` | Documented as excluded | ⏳ | |
| **FR-28** | Document exclusion rationale | `README.md` + `constitution.md` | Clear rationale present | ✅ | Constitution §2 |

### 1.4 Dynamic DT Environment Support — FR-29 through FR-34

| Req ID | Requirement | Validation Method | Pass Criteria | Status | Evidence |
|--------|-------------|-------------------|---------------|--------|----------|
| **FR-29** | QEMU `virt`, `sifive_u`, `microchip-icicle`, `shakti-c`, `tt_atlantis` via `${fdtcontroladdr}` | QEMU boot test each machine | All 5 machines boot to login | ⏳ | |
| **FR-30** | Spike dynamic DTS via `riscv/dts.cc` + `dtc` | Spike boot test | Boots with generated DTB | ⏳ | |
| **FR-31** | LiteX drivers (`liteuart`, `litex`, `litex_mmc`, `litex_soc_ctrl`) | `grep CONFIG_LITEX kernel/.config` | All 4 drivers = `y` or `m` | ⏳ | |
| **FR-32** | Renode custom platforms / LiteX `csr.json` import | Renode simulation test | Boots in Renode | ⏳ | |
| **FR-33** | OpenPiton/Chipyard via OpenSBI `PLATFORM=fpga/openpiton` | OpenSBI build with platform | Builds successfully | ⏳ | |
| **FR-34** | Coreboot ACPI table generation documented | `docs/architecture/coreboot.md` | Document exists | ⏳ | |

### 1.5 Build & Release Infrastructure — FR-35 through FR-49

| Req ID | Requirement | Validation Method | Pass Criteria | Status | Evidence |
|--------|-------------|-------------------|---------------|--------|----------|
| **FR-35** | Repo structure: `profiles/`, `overlays/`, `packages/`, `kernel/`, `images/`, `bsp/`, `docs/`, `tests/` | `ls -la` | All 8 dirs present | ⏳ | |
| **FR-36** | `mmdebstrap` + `genimage` pipeline | Build script execution | Clean image assembly | ⏳ | |
| **FR-37** | Cross-build host requirements documented | `README.md` Host Requirements | All tools listed with versions | ✅ | README.md |
| **FR-37a** | macOS host support (Homebrew + Lima/Docker) | macOS CI run | Build completes on macOS | ⏳ | |
| **FR-38** | Reproducible builds (pinned commits, deterministic flags) | `diffoscope` two builds | Bit-for-bit identical | ⏳ | |
| **FR-39** | SBOM generation (SPDX/JSON) | `syft packages koinv-*.img.xz -o spdx-json` | Valid SPDX JSON output | ⏳ | |
| **FR-40** | CI pipeline: `dtbs_check`, QEMU smoke, hwcaps verify | CI run | All 3 stages pass | ⏳ | |
| **FR-41** | Daily builds use `YY.MM.DD` (e.g., `26.11.20`) | Git tag format | Tags match `YY.MM.DD` | ⏳ | |
| **FR-42** | Monthly releases use `YY.MM` (e.g., `26.11`) | Git tag format | Tags match `YY.MM` | ⏳ | |
| **FR-43** | Patch/hotfix uses `YY.MM.pN` (e.g., `26.11.p1`) | Git tag format | Tags match `YY.MM.pN` | ⏳ | |
| **FR-44** | Git annotated tags for all versions (CalVer only) | `git tag -l` | All tags CalVer; no `v` prefix | ⏳ | |
| **FR-45** | Image artifacts embed version: `koinv-trixie-riscv64-YY.MM.DD.img.xz` | `ls output/` | Filename matches pattern | ⏳ | |
| **FR-46** | Kernel config `CONFIG_LOCALVERSION="-koinv-YY.MM.DD"` | `grep LOCALVERSION kernel/.config` | Matches CalVer | ⏳ | |
| **FR-47** | U-Boot `CONFIG_VERSION_VARIABLE="koinv-YY.MM.DD"` | `grep VERSION_VARIABLE u-boot/.config` | Matches CalVer | ⏳ | |
| **FR-48** | No SemVer anywhere | `grep -r "v1\.\|v2\.\|1\.0\.0" --include="*.md" --include="*.txt"` | Zero matches | ⏳ | |
| **FR-49** | Automation: daily tag on `main` CI success; monthly tag on 1st | CI config + cron | Tags created automatically | ⏳ | |

---

## 2. Non-Functional Requirements Verification (NFR-01 through NFR-20)

### 2.1 Performance (NFR-01 through NFR-06)

| Req ID | Requirement | Target | Validation Method | Pass Criteria | Status |
|--------|-------------|--------|-------------------|---------------|--------|
| **NFR-01** | Debian `riscv64` package compatibility | 100% `main` archive installable | `apt-cache policy` + test install sample | All core packages install | ⏳ |
| **NFR-02** | `glibc-hwcaps` selection latency | <5 ms per library load | `time ld.so` with hwcaps | <5 ms measured | ⏳ |
| **NFR-03** | `IFUNC` resolver overhead | <1% vs static linking | Benchmark vector routine | <1% overhead | ⏳ |
| **NFR-04** | Kernel boot time (Tier 1) | <30 seconds | `systemd-analyze` or stopwatch | <30s to login prompt | ⏳ |
| **NFR-05** | QEMU `virt` smoke test time | <120 seconds | CI timer | Completes <120s | ⏳ |
| **NFR-06** | Tier 2 minimal boot (64 MB) | <60 seconds | Stopwatch on hardware | <60s to shell | ⏳ |

### 2.2 Security (NFR-07 through NFR-11)

| Req ID | Requirement | Target | Validation Method | Pass Criteria | Status |
|--------|-------------|--------|-------------------|---------------|--------|
| **NFR-07** | Secure boot chain (OpenSBI→U-Boot→Kernel) | UEFI Secure Boot on capable HW | `mokutil --sb-state` + boot | Secure Boot enabled | ⏳ |
| **NFR-08** | Kernel hardening flags | All enabled | `grep -E "HARDENED|FORTIFY|STACKPROTECTOR" /boot/config-*` | All = `y` | ⏳ |
| **NFR-09** | Reproducible builds | Bit-for-bit identical | `diffoscope` two builds from same source | Zero differences | ⏳ |
| **NFR-10** | SBOM includes all components | SPDX/JSON format | `syft` output validation | Valid SPDX with all packages | ⏳ |
| **NFR-11** | Firmware blob redistribution compliance | Per-board documentation | `docs/boards/*/firmware.md` | All boards documented | ⏳ |

### 2.3 Compatibility (NFR-12 through NFR-16)

| Req ID | Requirement | Target | Validation Method | Pass Criteria | Status |
|--------|-------------|--------|-------------------|---------------|--------|
| **NFR-12** | Debian Trixie package compatibility | 100% `riscv64` `main` | `apt update && apt list --installed` | All core packages | ⏳ |
| **NFR-13** | Kernel ABI stability | No breaking changes | `abi-compliance-checker` | No ABI breaks | ⏳ |
| **NFR-14** | DTB forward/backward compat | New DTB on old kernel + vice versa | Cross-boot test matrix | Boots successfully | ⏳ |
| **NFR-15** | UEFI `BOOTRISCV64.EFI` compat | `systemd-boot` + `GRUB2` | Both bootloaders work | Both boot to Linux | ⏳ |
| **NFR-16** | `extlinux` fallback compat | ≥3 non-UEFI boards | Test on 3+ boards | All boot via extlinux | ⏳ |

### 2.4 Maintainability (NFR-17 through NFR-20)

| Req ID | Requirement | Target | Validation Method | Pass Criteria | Status |
|--------|-------------|--------|-------------------|---------------|--------|
| **NFR-17** | Constitution compliance automated | CI gate on all PRs | CI pipeline check | Fails on violation | ⏳ |
| **NFR-18** | Board support status tracked | `GOOD`/`BASIC`/`CFT`/`WIP` matrix | `docs/boards/status.md` | All Tier 1 boards listed | ⏳ |
| **NFR-19** | Vendor BSP patches upstreamed | Within 2 kernel cycles | GitHub PR tracker | PRs open/merged | ⏳ |
| **NFR-20** | Documentation as code | All ADRs in `docs/architecture/` | `ls docs/architecture/` | ADRs present | ⏳ |

---

## 3. Acceptance Criteria Verification (AC-01 through AC-16)

| Criterion | Description | Validation Method | Pass Criteria | Status |
|-----------|-------------|-------------------|---------------|--------|
| **AC-01** | `mmdebstrap` builds base rootfs | Build log | Exit 0; rootfs created | ⏳ |
| **AC-02** | Kernel `defconfig` succeeds | `make defconfig` | Exit 0; `.config` created | ⏳ |
| **AC-03** | Kernel `Image dtbs` builds all DTBs | `make Image dtbs` | Exit 0; all `*.dtb` present | ⏳ |
| **AC-04** | `make dtbs_check` passes | `make dtbs_check` | Exit 0; zero warnings | ⏳ |
| **AC-05** | Mandatory errata in kernel config | `grep ERRATA .config` | All 4 families = `y` | ⏳ |
| **AC-06** | `no5lvl`/`no4lvl` paging fallbacks | `grep NO5LVL\|NO4LVL .config` | Both = `y` | ⏳ |
| **AC-07** | OpenSBI `PLATFORM=generic` builds | OpenSBI build log | Exit 0; binary produced | ⏳ |
| **AC-08** | U-Boot `OF_UPSTREAM` + `BOOTRISCV64.EFI` | U-Boot build + file check | UEFI binary present | ⏳ |
| **AC-09** | `systemd-boot-efi` + `grub-efi-riscv64` install | `dpkg -l` in rootfs | Both packages installed | ⏳ |
| **AC-10** | `u-boot-efi-dtb` DTB override works | Boot with updated DTB in `/boot` | New DTB loaded | ⏳ |
| **AC-11** | QEMU `virt` smoke test boots | `qemu-system-riscv64 -machine virt ...` | Reaches login prompt | ⏳ |
| **AC-12** | VisionFive 2 8 GiB memory detected | Boot hardware; `free -h` | Shows ~8 GB | ⏳ |
| **AC-13** | Tier 2 minimal <50 MB; boots | `du -sh` + hardware boot | <50 MB; reaches shell | ⏳ |
| **AC-14** | `glibc-hwcaps` dirs + IFUNC test | `ls /usr/lib/.../hwcaps/` + test | Dirs exist; IFUNC resolves | ⏳ |
| **AC-15** | All 11 vendor `dts/` dirs in build | `ls kernel/arch/riscv/boot/dts/` | 11 directories | ⏳ |
| **AC-16** | License compliance: SPDX headers + SBOM | `syft` + header check | SPDX valid; headers present | ⏳ |

---

## 4. Per-Board Maturity Tracking

| Board | Tier | Target Status | AC Coverage | Current Status |
|-------|------|---------------|-------------|----------------|
| VisionFive 2 | 1 | GOOD | AC-01–AC-12, AC-14–AC-16 | ⏳ |
| Milk-V Mars | 1 | GOOD | AC-01–AC-12, AC-14–AC-16 | ⏳ |
| Star64 | 1 | BASIC | AC-01–AC-11, AC-14–AC-16 | ⏳ |
| Lichee Pi 4A | 1 | GOOD | AC-01–AC-11, AC-14–AC-16 | ⏳ |
| BeagleV-Ahead | 1 | CFT | AC-01–AC-11, AC-14–AC-16 | ⏳ |
| Milk-V Pioneer | 1 | GOOD | AC-01–AC-11, AC-14–AC-16 | ⏳ |
| SpacemiT K3 Pico-ITX | 1/2 | BASIC/CFT | AC-01–AC-13, AC-14–AC-16 | ⏳ |
| Milk-V Duo 64M | 2 | BASIC | AC-13 | ⏳ |
| LicheeRV Nano | 2 | BASIC | AC-13 | ⏳ |
| QEMU `virt` | Dynamic | GOOD | AC-11 | ⏳ |

---

## 5. Traceability Summary

| Artifact | Requirements Covered | Verification Complete |
|----------|---------------------|----------------------|
| Constitution | All architectural principles | ⏳ |
| Specification | FR-01–FR-49, NFR-01–NFR-20, AC-01–AC-16 | ⏳ |
| Clarifications | CL-01–CL-10, AS-01–AS-10, DEP-01–DEP-17, RSK-01–RSK-10, DEC-01–DEC-10 | ⏳ |
| Plan | All 7 plan sections | ⏳ |

---

## 6. Release Readiness Gate

**ALL items must be ✅ PASS for release:**

- [ ] All FR-01 through FR-49: ✅ PASS
- [ ] All NFR-01 through NFR-20: ✅ PASS  
- [ ] All AC-01 through AC-16: ✅ PASS
- [ ] Per-board maturity: All Tier 1 at least BASIC
- [ ] No SemVer violations (FR-48)
- [ ] CalVer tags created (FR-44)
- [ ] SBOM generated (FR-39)
- [ ] CI pipeline green (FR-40)

---

*Generated: 2026-11-20T12:46:00+01:00*  
*KoinV Checklist 26.11.20 — Requirement Verification Matrix*
