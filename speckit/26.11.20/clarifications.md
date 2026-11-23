# Agile611 Koinos RISC-V Clarifications

**Version:** 1.0  
**Date:** 2026-11-20  
**Status:** Draft  
**Related:** [Constitution](constitution.md) 26.11.20 | [Specification](spec.md) 26.11.20

---

## 1. Open Questions with Resolutions

| ID | Question | Resolution | Rationale |
|----|----------|------------|-----------|
| **CL-01** | Which Debian repository mirror to use for `mmdebstrap`? | Default to `http://deb.debian.org/debian` with `deb.debian.org` CDN; allow override via `DEBIAN_MIRROR` env var | CDN provides geo-routing; override for air-gapped/CI environments |
| **CL-02** | Should Agile611 Koinos RISC-V build its own kernel or use Debian's `linux-image-riscv64`? | **Build own kernel** from mainline + BSP patches; Debian's kernel lacks mandatory errata and full DTB set | Constitution §1.2 mandates unified kernel with all errata enabled; Debian kernel is generic |
| **CL-03** | How to handle `glibc-hwcaps` on Debian Trixie (glibc 2.37) which lacks full support? | **Backport glibc ≥2.38** to Trixie via `koinos-glibc` package; use `hwprobe` syscall directly if backport delayed | Constitution §1.1 requires `glibc-hwcaps` + `hwprobe` + `IFUNC`; Trixie ships 2.37 |
| **CL-04** | What is the exact partition layout for the disk image? | **GPT with 3 partitions**: 1) ESP (FAT32, 512 MB, `EFI/BOOT/BOOTRISCV64.EFI`, DTBs, kernel), 2) Rootfs (ext4, remaining space), 3) Optional persistent data (ext4, 0–4 GB) | UEFI boot requires ESP; `u-boot-efi-dtb` reads DTBs from `/boot` on ESP |
| **CL-05** | How to version the kernel package (`linux-image-riscv64`) vs. distribution image? | **Kernel**: `CONFIG_LOCALVERSION="-koinos-YY.MM.DD"`; **Image**: `koinos-trixie-riscv64-YY.MM.DD.img.xz`; both use CalVer | Constitution §2.1 CalVer; kernel version embedded for traceability |
| **CL-06** | Should Tier 2 minimal variant use Buildroot or `mmdebstrap --variant=minbase` + musl? | **Buildroot** for Tier 2; `mmdebstrap` is glibc-only. Buildroot provides musl, BusyBox, initramfs integration | Constitution §1.4: "musl + BusyBox / Buildroot, 5–50 MB" |
| **CL-07** | How to handle vendor firmware blobs that cannot be redistributed? | **Separate `firmware/` directory** with `fetch-firmware.sh` scripts per board; user runs manually; document in `docs/boards/` | Legal compliance; Constitution §4: "Licensing & Attribution Compliance" |
| **CL-08** | What init system for Tier 2 minimal variant? | **BusyBox init** (static `/init` symlink); no systemd, no OpenRC | Constitution §1.4: "without systemd" |
| **CL-09** | Should Agile611 Koinos RISC-V provide OTA/ABRoot atomic updates? | **Deferred** (Constitution §6.3); current focus: reproducible image builds. Add `ostree`/`abroot` as opt-in later | Out of scope per spec §6.2; Debian lacks native support yet |
| **CL-10** | How to handle Secure Boot on boards with varying UEFI implementations? | **Enable shim + MOK** in `grub-efi-riscv64`; document per-board enrollment in `docs/boards/`; `systemd-boot` UKI with `sbctl` signing | Constitution §1.3: UEFI-first; NFR-07: Secure Boot on capable hardware |

---

## 2. Assumptions Made

| ID | Assumption | Impact if Wrong |
|----|------------|-----------------|
| **AS-01** | Debian 13 "Trixie" `riscv64` port provides ≥95% of required packages | If key packages missing, must build from source or backport (increases maintenance) |
| **AS-02** | Mainline Linux kernel supports all 11 vendor `dts/` directories for target boards | If gaps exist, BSP patches required (increases kernel maintenance burden) |
| **AS-03** | `glibc-hwcaps` + `hwprobe` + `IFUNC` works reliably on RVA23 hardware (SpacemiT K3) | If broken, RVA23 acceleration fails; fallback to baseline RV64GC performance |
| **AS-04** | `qemu-system-riscv64` ≥8.0 on macOS (Apple Silicon/Intel) correctly emulates `virt` and `sifive_u` | If broken, CI smoke tests fail on macOS; must use Linux CI runners |
| **AS-05** | U-Boot `OF_UPSTREAM` + `BOOTRISCV64.EFI` works on all Tier 1 boards | If vendor U-Boot lacks UEFI, fallback to `u-boot-menu`/`extlinux` (tested per AC-10) |
| **AS-06** | `mmdebstrap --mode=unshare` works in Lima VM / Docker on macOS | If broken, macOS builds require remote Linux runner |
| **AS-07** | `genimage` runs natively on macOS for image assembly | If broken, final image step requires Linux |
| **AS-08** | Vendor BSP patches (TH1520, SG2042, K3) apply cleanly to mainline kernel LTS | If conflicts, kernel version pinning or patch backporting needed |
| **AS-09** | `make dtbs_check` passes for all mainline DTBs without Agile611 Koinos RISC-V modifications | If warnings/errors, must fix upstream or carry local binding patches |
| **AS-10** | Tier 2 boards (64–512 MB) can boot mainline kernel with same DTBs as Tier 1 | If DTB differences exist, must maintain separate DTB sets |

---

## 3. Dependencies Identified

| ID | Dependency | Type | Version/Source | Risk |
|----|------------|------|----------------|------|
| **DEP-01** | Debian 13 "Trixie" `riscv64` archive | Upstream | `deb.debian.org` | Medium — package lag vs. amd64 |
| **DEP-02** | Linux Kernel Mainline (LTS) | Upstream | `kernel.org` | Low — stable API |
| **DEP-03** | U-Boot Mainline | Upstream | `u-boot.org` | Low — UEFI support mature |
| **DEP-04** | OpenSBI Mainline | Upstream | `github.com/riscv-software-src/opensbi` | Low — `PLATFORM=generic` stable |
| **DEP-05** | glibc ≥2.38 (for `hwprobe`/`hwcaps`) | Upstream | `gnu.org` / Debian backport | **High** — Trixie has 2.37; must backport |
| **DEP-06** | systemd ≥254 (for `systemd-boot-efi`, UKI) | Upstream | Debian Trixie | Low — Trixie ships 252+ |
| **DEP-07** | QEMU ≥8.0 | Upstream | `qemu.org` / Homebrew | Low — mature RISC-V support |
| **DEP-08** | `mmdebstrap` ≥1.0 | Upstream | Debian | Low — mature |
| **DEP-09** | `genimage` ≥16 | Upstream | `github.com/genimage/genimage` | Low — mature |
| **DEP-10** | `dtc` ≥1.7.0 | Upstream | `kernel.org` | Low — mature |
| **DEP-11** | T-Head BSP (`revyos/th1520-linux-kernel`) | Vendor | GitHub | **High** — downstream patches, may lag |
| **DEP-12** | Microchip BSP (`linux4microchip`) | Vendor | GitHub | Medium — PolarFire support |
| **DEP-13** | SpacemiT BSP (`spacemit-com`) | Vendor | GitHub | **High** — K3 RVA23 patches |
| **DEP-14** | StarFive BSP (`starfive-tech`) | Vendor | GitHub | Medium — JH7110 support |
| **DEP-15** | Sophgo BSP (`riscv/meta-riscv`) | Vendor | Yocto | Medium — SG2042/SG2000 |
| **DEP-16** | Lima VM | Tool | `github.com/lima-vm/lima` | Medium — macOS dependency |
| **DEP-17** | Docker Desktop / Colima | Tool | Docker Inc. | Medium — macOS dependency |

---

## 4. Risk Mitigations

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| **RSK-01** | glibc 2.37 in Trixie breaks `glibc-hwcaps`/`hwprobe` | High | High | Backport glibc 2.38+ as `koinos-glibc` package; test `hwprobe` syscall directly |
| **RSK-02** | Vendor BSP patches conflict with mainline kernel LTS | Medium | High | Pin kernel version; maintain patch queue; upstream aggressively |
| **RSK-03** | `mmdebstrap --mode=unshare` fails in Lima/Docker on macOS | Medium | Medium | Document Linux runner fallback; CI on GitHub Actions (Linux) |
| **RSK-04** | Board-specific DTB quirks cause boot failures (VisionFive 2 8GB, PCB revs) | High | Medium | Automated DTB override tests in CI; per-board `docs/boards/` docs |
| **RSK-05** | UEFI firmware missing/broken on Tier 1 boards | Medium | High | `u-boot-menu`/`extlinux` fallback tested per AC-10; document per board |
| **RSK-06** | `make dtbs_check` fails on mainline DTBs due to schema drift | Low | Medium | Track kernel version; submit binding fixes upstream |
| **RSK-07** | Tier 2 minimal variant kernel too large for 64 MB RAM | Low | High | Kernel config: disable unused drivers; `CONFIG_MODULES=n`; initramfs only |
| **RSK-08** | Firmware blob redistribution legal issues | Medium | High | Separate `fetch-firmware.sh`; no blobs in repo; document per vendor |
| **RSK-09** | CalVer tag automation fails (CI permissions, date edge cases) | Low | Low | Manual tag verification; `date -u` for UTC consistency |
| **RSK-10** | Debian `riscv64` package set missing critical packages | Low | Medium | Build from source via `koinos-packages/`; track in `docs/known-gaps.md` |

---

## 5. Stakeholder Decisions

| ID | Decision | Decided By | Date | Notes |
|----|----------|------------|------|-------|
| **DEC-01** | Base ISA = RV64GC (RVA20), not RVA23 | Architecture Team | 2026-11-20 | Per Constitution §1.1; aligns with Debian Trixie |
| **DEC-02** | Runtime acceleration via `glibc-hwcaps` + `IFUNC`, not separate RVA23 repo | Architecture Team | 2026-11-20 | Per Constitution §1.1; opt-in RVA23 overlay deferred |
| **DEC-03** | UEFI-first boot (`systemd-boot`/`GRUB2`) with `extlinux` fallback | Boot Team | 2026-11-20 | Per Constitution §1.3; BRS server readiness |
| **DEC-04** | Modular BSP layer (RevyOS model) for vendor subsystems | Kernel Team | 2026-11-20 | Per Constitution §1.2; `koinos-bsp-*` packages |
| **DEC-05** | Tier 2 minimal variant via Buildroot/musl, not `mmdebstrap` | Embedded Team | 2026-11-20 | Per Constitution §1.4; glibc incompatible |
| **DEC-06** | CalVer `YY.MM.DD` daily, `YY.MM` monthly, `YY.MM.pN` patch | Release Team | 2026-11-20 | Per Constitution §2.1; no SemVer |
| **DEC-07** | macOS build via Homebrew + Lima/Docker for `mmdebstrap` | CI Team | 2026-11-20 | Per Spec §7.1.1; native QEMU/kernel build |
| **DEC-08** | Exclude Tier 3 MCU/RTOS boards entirely | Product Team | 2026-11-20 | Per Constitution §2; no MMU/Linux support |
| **DEC-09** | MIT License for Agile611 Koinos RISC-V code; upstream licenses preserved | Legal | 2026-11-20 | Per LICENSE.md; GPL/BSD for kernel/U-Boot/etc. |
| **DEC-10** | Single unified disk image (GPT + ESP + rootfs) for all Tier 1 | Image Team | 2026-11-20 | Per Spec FR-04; DTB/overlay handles board diffs |

---

## 6. Traceability Matrix

| Clarification | Constitution Ref | Spec Ref | Status |
|---------------|------------------|----------|--------|
| CL-01 (Debian mirror) | §3.1 | FR-02 | Resolved |
| CL-02 (Own kernel) | §1.2, §3.2 | FR-06, FR-07 | Resolved |
| CL-03 (glibc backport) | §1.1 | FR-03, FR-04 | **Open** — needs backport work |
| CL-04 (Partition layout) | §1.3 | FR-11, FR-12 | Resolved |
| CL-05 (Kernel vs image version) | §2.1 | FR-45, FR-46 | Resolved |
| CL-06 (Buildroot for Tier 2) | §1.4 | FR-23, FR-24 | Resolved |
| CL-07 (Firmware blobs) | §4 | FR-19, NFR-11 | Resolved — fetch scripts |
| CL-08 (BusyBox init) | §1.4 | FR-26 | Resolved |
| CL-09 (OTA deferred) | §6.3 | — | Resolved — deferred |
| CL-10 (Secure Boot) | §1.3 | NFR-07 | Resolved — shim + MOK |

| Assumption | Constitution Ref | Spec Ref | Validation |
|------------|------------------|----------|------------|
| AS-01 (Debian package coverage) | §1.1 | NFR-12 | Monitor `apt-cache search` |
| AS-02 (Mainline DTB coverage) | §3.2 | FR-19, FR-20 | `make dtbs_check` |
| AS-03 (glibc-hwcaps on RVA23) | §1.1 | FR-03, FR-04 | Test on K3 hardware |
| AS-04 (QEMU on macOS) | — | FR-37a, NFR-05 | CI smoke test |
| AS-05 (U-Boot UEFI on Tier 1) | §1.3 | FR-10, FR-11 | Per-board testing |
| AS-06 (Lima/Docker mmdebstrap) | — | FR-37a | macOS CI validation |
| AS-07 (genimage on macOS) | — | FR-36 | macOS CI validation |
| AS-08 (BSP patch apply) | §1.2 | DEP-11–15 | Kernel build CI |
| AS-09 (dtbs_check clean) | §3.3 | FR-22 | CI gate |
| AS-10 (Tier 2 same DTBs) | §1.4 | FR-24 | Boot test on Tier 2 |

---

## 7. Next Steps

1. **Immediate (Week 1):**
   - [ ] Backport glibc 2.38+ to Trixie as `koinos-glibc` package (CL-03)
   - [ ] Validate `mmdebstrap` in Lima VM on macOS (AS-06)
   - [ ] Test `genimage` on macOS (AS-07)

2. **Short-term (Week 2–3):**
   - [ ] Build kernel with all errata + `dtbs_check` (FR-07, FR-22)
   - [ ] Implement DTB override mechanism for VisionFive 2 8GB (FR-15)
   - [ ] Create `fetch-firmware.sh` templates per board (CL-07)

3. **Medium-term (Month 1):**
   - [ ] Build Tier 2 Buildroot minimal variant (FR-23)
   - [ ] Implement CalVer tagging automation (FR-44, FR-49)
   - [ ] Document per-board quirks in `docs/boards/` (RSK-04)

---

*This document will be updated as clarifications are resolved. All changes must reference Constitution and Spec sections.*
