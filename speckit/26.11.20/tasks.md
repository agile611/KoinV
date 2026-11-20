# KoinV Task Breakdown

**Version:** 26.11.20 (CalVer Daily Build)  
**Date:** 2026-11-20  
**Status:** Draft  
**Based On:** [Constitution](constitution.md) 26.11.20 | [Specification](spec.md) 26.11.20 | [Plan](plan.md) 26.11.20 | [Checklist](checklist.md) 26.11.20

---

## Task Organization

### Milestones

| Milestone | Target Date | Focus |
|-----------|-------------|-------|
| **M1: Foundation** | 2026-11-27 | Core build pipeline, kernel, rootfs |
| **M2: Boot & Hardware** | 2026-12-04 | UEFI boot, DTB handling, Tier 1 boards |
| **M3: Acceleration & Tier 2** | 2026-12-11 | glibc-hwcaps, IFUNC, minimal variant |
| **M4: Release Hardening** | 2026-12-18 | Security, reproducibility, CI/CD, docs |
| **M5: 26.11 Monthly Release** | 2026-12-26 | First stable monthly release |

---

## Task Breakdown

### M1: Foundation (2026-11-27)

| Task ID | Title | Description | Dependencies | Effort | Owner | Acceptance Criteria |
|---------|-------|-------------|--------------|--------|-------|---------------------|
| **T-001** | Initialize repository structure | Create all 8 directories: `profiles/`, `overlays/`, `packages/`, `kernel/`, `images/`, `bsp/`, `docs/`, `tests/` | None | 2h | DevOps | `ls` shows all dirs; `.gitkeep` in each |
| **T-002** | Create base mmdebstrap profile | `profiles/base.trixie` with `important` variant packages for `riscv64` | T-001 | 4h | DevOps | `mmdebstrap` builds rootfs successfully |
| **T-003** | Create desktop/server profiles | `profiles/desktop.trixie`, `profiles/server.trixie` extending base | T-002 | 2h | DevOps | Profiles parse; produce different package sets |
| **T-004** | Set up kernel source + config | Clone mainline Linux LTS (6.6 or 6.12); create `kernel/config.trixie` with all errata + DTBs | T-001 | 8h | Kernel | `make defconfig` succeeds; errata enabled |
| **T-005** | Implement kernel build script | `kernel/build-kernel.sh` cross-compiles `Image` + `dtbs`; runs `dtbs_check` | T-004 | 4h | Kernel | Clean build; all DTBs; `dtbs_check` passes |
| **T-006** | Create base overlays | `overlays/etc/` (APT sources, systemd), `overlays/boot/` (kernel cmdline, bootloader), `overlays/usr/` (hwcaps helpers) | T-001 | 6h | DevOps | Overlays apply cleanly to rootfs |
| **T-007** | Implement genimage config | `images/genimage.cfg` with GPT: ESP (512MB FAT32), Rootfs (ext4), Persist (ext4 optional) | T-001 | 4h | DevOps | `genimage` produces valid disk image |
| **T-008** | Create master build script | `images/build-image.sh` orchestrating mmdebstrap → overlays → packages → kernel → genimage → xz | T-002, T-005, T-006, T-007 | 8h | DevOps | Single command produces `koinv-trixie-riscv64-YY.MM.DD.img.xz` |
| **T-009** | Set up CI pipeline (GitHub Actions) | `.github/workflows/build.yml`: kernel build, dtbs_check, rootfs, image assembly, QEMU smoke | T-005, T-008 | 6h | DevOps | CI runs on push; all stages pass |
| **T-010** | Document macOS build (Homebrew + Lima/Docker) | `docs/building/macos.md` with step-by-step | T-008 | 2h | Docs | Verified on macOS host |

---

### M2: Boot & Hardware (2026-12-04)

| Task ID | Title | Description | Dependencies | Effort | Owner | Acceptance Criteria |
|---------|-------|-------------|--------------|--------|-------|---------------------|
| **T-011** | Build OpenSBI `PLATFORM=generic` | Compile OpenSBI; integrate into build pipeline | T-004 | 4h | Firmware | `fw_payload.bin` produced; `PLATFORM=generic` |
| **T-012** | Build U-Boot with `OF_UPSTREAM` UEFI | Compile U-Boot; produce `BOOTRISCV64.EFI`; integrate | T-011 | 8h | Firmware | UEFI binary boots in QEMU `virt` |
| **T-013** | Integrate `systemd-boot-efi` + `grub-efi-riscv64` | Add to rootfs; configure `loader/entries/` + `grub.cfg` | T-002, T-012 | 6h | Boot | Both bootloaders appear in UEFI menu |
| **T-014** | Implement `u-boot-efi-dtb` DTB override | Configure U-Boot to read DTBs from `/boot/dtb/` on ESP | T-012 | 4h | Boot | Updated DTB in `/boot` overrides SPI DTB |
| **T-015** | Implement `u-boot-menu` + `flash-kernel` fallback | Add packages; verify `extlinux.conf` auto-generation | T-012 | 4h | Boot | `extlinux.conf` generated on kernel install |
| **T-016** | VisionFive 2 8GB memory DTB override | Create overlay for `jh7110-common.dtsi` memory node @40000000 = 8GB | T-004 | 4h | DT | Boots VisionFive 2 8GB; detects full RAM |
| **T-017** | VisionFive 2 PCB revision DT overlays | v1.2B `cd-gpios` + v1.3A `broken-cd` overlays for microSD | T-004 | 4h | DT | MicroSD works on both revisions |
| **T-018** | PolarFire Video Kit I2C overlays | `i2c0`/`i2c1` `status="okay"` overlays in `bsp/microchip/` | T-004 | 2h | DT | I2C buses visible on boot |
| **T-019** | SpacemiT K3 CoM260 TQ PMIC overlays | Dual PMIC variant overlays in `bsp/spacemit-k3/` | T-004 | 4h | DT | Correct voltages per variant |
| **T-020** | QEMU smoke test automation | `tests/qemu-smoke.sh` testing `virt`, `sifive_u`, `microchip-icicle` | T-012 | 4h | QA | All 3 machines boot to login |
| **T-021** | DTB schema validation automation | `tests/dtbs-check.sh` wrapper for `make dtbs_check` | T-005 | 2h | QA | Zero errors/warnings in CI |
| **T-022** | Per-board documentation | `docs/boards/<board>/` with flashing, DTB, quirks | T-016–T-019 | 8h | Docs | All Tier 1 boards documented |

---

### M3: Acceleration & Tier 2 (2026-12-11)

| Task ID | Title | Description | Dependencies | Effort | Owner | Acceptance Criteria |
|---------|-------|-------------|--------------|--------|-------|---------------------|
| **T-023** | Backport glibc 2.38+ to Trixie | Create `packages/koinv-glibc/` with backported glibc; build `.deb` | T-001 | 16h | Toolchain | `glibc-hwcaps` + `hwprobe` + `IFUNC` functional |
| **T-024** | Implement `koinv-hwcaps` package | `packages/koinv-hwcaps/` creates `/usr/lib/.../hwcaps/RVA23U64/` dirs; installs optimized libs | T-023 | 8h | Toolchain | `openssl`/`libgcrypt`/`libjpeg-turbo` in hwcaps dir |
| **T-025** | Verify IFUNC resolvers for RVV 1.0 | Test `RISCV_HWPROBE_KEY_IMA_EXT_0` detection + vector routine selection | T-023 | 8h | Toolchain | `hwprobe` returns RVA23U64; IFUNC selects vector code |
| **T-026** | Create RVA23 opt-in overlay repo structure | Separate `rva23/` overlay with `rva23_defconfig` + `-march=rva23u64` packages | T-023 | 4h | Toolchain | Opt-in builds work; don't affect main |
| **T-027** | Build Tier 2 minimal variant (Buildroot) | `bsp/tier2/buildroot/` config: musl, BusyBox, no systemd, shared kernel/DTBs | T-004, T-005 | 16h | Embedded | <50 MB rootfs; boots on Milk-V Duo 64M |
| **T-028** | Tier 2 hwcaps verification | `tests/hwcaps-verify.sh` tests `hwprobe` + IFUNC on minimal variant | T-023, T-027 | 4h | QA | Runtime acceleration works on Tier 2 |
| **T-029** | BSP package: `koinv-bsp-th1520` | Kernel modules, firmware, DT overlays for TH1520 in `packages/koinv-bsp-th1520/` | T-004, T-016 | 8h | BSP | Installs alongside mainline kernel |
| **T-030** | BSP package: `koinv-bsp-jh7110` | Kernel modules, firmware, DT overlays for JH7110 in `packages/koinv-bsp-jh7110/` | T-004, T-016, T-017 | 8h | BSP | Installs alongside mainline kernel |
| **T-031** | BSP package: `koinv-bsp-sg2042` | Kernel modules, firmware, DT overlays for SG2042 in `packages/koinv-bsp-sg2042/` | T-004 | 8h | BSP | Installs alongside mainline kernel |
| **T-032** | BSP package: `koinv-bsp-spacemit-k3` | Kernel modules, firmware, DT overlays for K3 in `packages/koinv-bsp-spacemit-k3/` | T-004, T-019 | 8h | BSP | Installs alongside mainline kernel |

---

### M4: Release Hardening (2026-12-18)

| Task ID | Title | Description | Dependencies | Effort | Owner | Acceptance Criteria |
|---------|-------|-------------|--------------|--------|-------|---------------------|
| **T-033** | Kernel hardening flags | Enable `HARDENED_USERCOPY`, `FORTIFY_SOURCE=3`, `STACKPROTECTOR_STRONG`, `PAGE_TABLE_ISOLATION`, `MODULE_SIG` | T-004 | 4h | Security | All flags = `y` in `.config` |
| **T-034** | Secure Boot: shim + MOK enrollment | Package `shim` + `mokutil`; document per-board enrollment in `docs/boards/` | T-013 | 8h | Security | `mokutil --sb-state` shows enabled |
| **T-035** | Reproducible builds | Pin all source commits; set `SOURCE_DATE_EPOCH`; strip timestamps; `diffoscope` verification | T-008 | 8h | Release | Two builds from same source = bit-for-bit identical |
| **T-036** | SBOM generation (SPDX JSON) | Integrate `syft` in CI; generate SBOM for each image artifact | T-009 | 4h | Release | Valid SPDX JSON for every image |
| **T-037** | Artifact signing (cosign/gpg) | Sign git tags + image artifacts; verify in CI | T-009 | 4h | Release | `cosign verify` / `gpg --verify` passes |
| **T-038** | CalVer tagging automation | CI job: daily tag on `main` success; monthly tag on 1st; patch tag manual | T-009 | 4h | Release | Tags created automatically in CalVer format |
| **T-039** | Constitution compliance CI gate | Script validating: no SemVer, CalVer tags, required files, checklist items | T-009, T-035 | 4h | QA | PR fails if constitution violated |
| **T-040** | Per-board status matrix | `docs/boards/status.md` with `GOOD`/`BASIC`/`CFT`/`WIP` for all Tier 1 | T-022 | 2h | Docs | All 54 Tier 1 boards listed |
| **T-041** | Vendor BSP upstream tracking | `docs/bsp/upstream-tracking.md` with PR links + kernel cycle targets | T-029–T-032 | 2h | Docs | All BSP patches tracked |
| **T-042** | Architecture Decision Records | `docs/architecture/ADR-*.md` for key decisions (ISA, boot, BSP, versioning) | T-001 | 4h | Docs | ADRs present for all major decisions |

---

### M5: 26.11 Monthly Release (2026-12-26)

| Task ID | Title | Description | Dependencies | Effort | Owner | Acceptance Criteria |
|---------|-------|-------------|--------------|--------|-------|---------------------|
| **T-043** | Full integration test | Run complete build → image → QEMU smoke → hardware test (available boards) | All prior | 8h | QA | All checklist items ✅ PASS |
| **T-044** | Release image creation | Tag `26.11`; build release image; generate SBOM; sign artifacts | T-038, T-036, T-037 | 4h | Release | `koinv-trixie-riscv64-26.11.img.xz` + SBOM + sig |
| **T-045** | Release notes | `RELEASE-NOTES-26.11.md` with changes, known issues, upgrade notes | T-044 | 2h | Docs | Published with release |
| **T-046** | Announce + publish | GitHub Release; update `README.md` status; announce on channels | T-045 | 1h | PM | Release public |

---

## Dependency Graph (Critical Path)

```
T-001 → T-002 → T-004 → T-005 → T-008 → T-009 → T-035 → T-038 → T-043 → T-044
                    ↓
              T-011 → T-012 → T-013 → T-014 → T-020
                    ↓
              T-016 → T-017 → T-022
                    ↓
              T-023 → T-024 → T-025 → T-027 → T-028
```

**Critical Path Duration:** ~80 hours (2 weeks) assuming parallel execution where possible.

---

## Task Status Tracking

| Task ID | Status | Started | Completed | Blocker |
|---------|--------|---------|-----------|---------|
| T-001 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-002 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-003 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-004 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-005 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-006 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-007 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-008 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-009 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-010 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-011 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-012 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-013 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-014 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-015 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-016 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-017 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-018 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-019 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-020 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-021 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-022 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-023 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-024 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-025 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-026 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-027 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-028 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-029 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-030 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-031 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-032 | ✅ DONE | 2026-11-20 | 2026-11-20 | |
| T-033 | ⏳ PENDING | | | |
| T-034 | ⏳ PENDING | | | |
| T-035 | ⏳ PENDING | | | |
| T-036 | ⏳ PENDING | | | |
| T-037 | ⏳ PENDING | | | |
| T-038 | ⏳ PENDING | | | |
| T-039 | ⏳ PENDING | | | |
| T-040 | ⏳ PENDING | | | |
| T-041 | ⏳ PENDING | | | |
| T-042 | ⏳ PENDING | | | |
| T-043 | ⏳ PENDING | | | |
| T-044 | ⏳ PENDING | | | |
| T-045 | ⏳ PENDING | | | |
| T-046 | ⏳ PENDING | | | |

---

## Effort Summary

| Milestone | Tasks | Total Effort | Target Date |
|-----------|-------|--------------|-------------|
| M1: Foundation | 10 | 46h | 2026-11-27 |
| M2: Boot & Hardware | 12 | 58h | 2026-12-04 |
| M3: Acceleration & Tier 2 | 10 | 88h | 2026-12-11 |
| M4: Release Hardening | 10 | 42h | 2026-12-18 |
| M5: Monthly Release | 4 | 15h | 2026-12-26 |
| **Total** | **46** | **249h** | **~6 weeks** |

---

## Traceability

| Task | Spec FR/NFR/AC | Plan Section | Checklist Item |
|------|----------------|--------------|----------------|
| T-001–T-010 | FR-35, FR-36, FR-37, FR-37a | Plan §3.1 | FR-35–FR-37a |
| T-011–T-022 | FR-09–FR-18, FR-29–FR-34 | Plan §4.1, §4.2 | FR-09–FR-18, AC-07–AC-12 |
| T-023–T-032 | FR-03, FR-04, FR-05, FR-23–FR-26 | Plan §3.2, §4.3 | FR-03–FR-05, FR-23–FR-26, AC-13–AC-14 |
| T-033–T-042 | NFR-07–NFR-11, NFR-17–NFR-20 | Plan §6, §7 | NFR-07–NFR-11, NFR-17–NFR-20 |
| T-043–T-046 | All AC | Plan §7, §8 | All AC-01–AC-16 |

---

*Generated: 2026-11-20T12:46:00+01:00*  
*KoinV Tasks 26.11.20 — Ordered, Dependency-Aware Task Breakdown*
