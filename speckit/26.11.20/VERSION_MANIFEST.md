# KoinV Spec Kit — Version Manifest

**Version:** 26.11.20 (CalVer Daily Build)  
**Date:** 2026-11-20  
**Timestamp:** 2026-11-20T11:58:00+01:00  
**Git Commit:** 57a0a64 (clarifications.md created)  
**Source PDF:** KoinV Initial Requeriments.pdf  

---

## Files in This Version

| File | Description | Lines | SHA256 |
|------|-------------|-------|--------|
| `constitution.md` | Core engineering, testing, and architectural principles | 247 | `87b548bc404e845d73b84093feabd0a0014ce784dd10958e0b5a51fc310c65cd` |
| `spec.md` | Formal specification: problem, goals, requirements, acceptance criteria | 356 | `237017449e32110e76fa3a1ae6adb59a7b61faa8cd3b1852d18d529bd1393647` |
| `clarifications.md` | Resolved ambiguities, assumptions, dependencies, risks, decisions | 151 | `4dd03521b0cc20c32ff27f8eb1f22266a7f87d820d87b5fdad482ff0d04a9b71` |
| `SPECKIT_PROCESS.md` | Spec Kit workflow documentation for KoinV | 164 | `307bf920e58c82f5e7adadb1b4e7bad915898b1c0d6955271d498059eec71e2e` |
| `plan.md` | Technical architecture, tech stack, interface contracts, data models | 378 | `88234933e8e9c7e265ff599b0597fc6a040da2f9b67f6735045db42892775322` |
| `checklist.md` | Requirement verification matrix (FR, NFR, AC, board maturity) | 487 | `6bb89add08518585d9f3aeac43835ad38a99e207752ec9b4a929a483b90f56b1` |
| `tasks.md` | Ordered, dependency-aware task breakdown (46 tasks, 5 milestones) | 512 | `741b35c49a36f6e85d7b04bc3ef45d0fe5539ea1461797cd7c3f051aa64ebca7` |
| `VERSION_MANIFEST.md` | This manifest file | — | `7cc6adabfcdc2a44ceb63ab9adcd0c994686b1e6cb2224753d658990acadc36a` |

---

## Source Traceability

| Source | Location | SHA256 | Notes |
|--------|----------|--------|-------|
| Original PDF | `KoinV_Initial_Requeriments.pdf` | `59c5496230690970a98624ced5cffc14d9baa92fc66cd30390667a5e264dca2e` | 28 pages, 36 KB |
| Extracted text | `pdf_content.txt` | `ac9fe3c206f5301089b7497e330065bc6d6c0310f757a609216b699804acf5fb` | 1759 lines |
| Requirements summary | `pdf_requirements.txt` | `2c132e5243eb235787866a1024ba7b9854c1be2406811eafbd8e0d65ad1ef6b4` | Extracted key requirements |

---

## Spec Kit Workflow Status

| Step | Command | Output | Status |
|------|---------|--------|--------|
| 1 | `/speckit-constitution` | `constitution.md` | ✅ Complete |
| 2 | `/speckit-specify` | `spec.md` | ✅ Complete |
| 3 | `/speckit-clarify` | `clarifications.md` | ✅ Complete |
| 4 | `/speckit-plan` | `plan.md` | ✅ Complete |
| 5 | `/speckit-checklist` | `checklist.md` | ✅ Complete |
| 6 | `/speckit-tasks` | `tasks.md` | ✅ Complete |
| 7 | `/speckit-analyze` | — | ⏳ Pending |
| 8 | `/speckit-implement` | — | ⏳ Pending |

---

## Key Architectural Decisions (from Constitution)

| Decision | Value | Reference |
|----------|-------|-----------|
| Target Architecture | `riscv64` (64-bit little-endian) | §1.1 |
| Base ISA | `RV64GC` (`RVA20`) | §1.1 |
| Runtime Acceleration | `glibc-hwcaps` + `hwprobe` + `IFUNC` | §1.1 |
| Kernel Strategy | Unified mainline + mandatory errata + modular BSP | §1.2 |
| Mandatory Errata | T-Head, SiFive, JH7100 DMA, Andes | §1.2 |
| Boot Chain | UEFI-first (`systemd-boot`/`GRUB2`) + `extlinux` fallback | §1.3 |
| Tier 1 Boards | 54 boards (512 MB–64 GB RAM) | §2 |
| Tier 2 Boards | 18 boards (64–512 MB, minimal variant) | §2 |
| Tier 3 Boards | 27 MCU/RTOS boards (excluded) | §2 |
| Versioning | CalVer `YY.MM.DD` / `YY.MM` / `YY.MM.pN` | §2.1 |
| License | MIT (KoinV code); upstream licenses preserved | LICENSE.md |

---

## Requirements Summary (from Spec)

| Category | Count | Priority Breakdown |
|----------|-------|-------------------|
| Functional (FR) | 49 | P0: 28, P1: 16, P2: 5 |
| Non-Functional (NFR) | 20 | Performance: 6, Security: 5, Compatibility: 5, Maintainability: 4 |
| Acceptance Criteria (AC) | 16 | All must pass for release |
| Scope | In: 10, Out: 10, Deferred: 5 | Clear boundaries |

---

## Clarifications Summary

| Category | Count | Status |
|----------|-------|--------|
| Open Questions (CL) | 10 | 9 Resolved, 1 Open (CL-03: glibc backport) |
| Assumptions (AS) | 10 | All documented with impact |
| Dependencies (DEP) | 17 | 2 High risk (glibc, vendor BSPs) |
| Risks (RSK) | 10 | 2 High likelihood/impact |
| Stakeholder Decisions (DEC) | 10 | All recorded with owners |

---

## Plan Summary (from Technical Plan)

| Section | Key Deliverables |
|---------|------------------|
| Architecture | Component diagrams, build pipeline, boot flow |
| Tech Stack | 22 decisions (kernel, toolchain, bootloader, etc.) |
| Modules | 7 build-time, 8 runtime (Tier 1), 3 runtime (Tier 2) |
| Interfaces | UEFI, DTB, HWCapS, Package Management contracts |
| Data Models | GPT partition layout, memory map, kernel config |
| Security | Boot chain, runtime hardening, supply chain |
| Deployment | 5 image types, flashing methods, update mechanisms |
| Validation | 8 CI stages, 10-board validation matrix |

---

## Checklist Summary (from Verification Matrix)

| Category | Items | Status |
|----------|-------|--------|
| Functional Requirements (FR) | 49 | ⏳ All Pending |
| Non-Functional Requirements (NFR) | 20 | ⏳ All Pending |
| Acceptance Criteria (AC) | 16 | ⏳ All Pending |
| Per-Board Maturity | 10 Tier 1 boards | ⏳ All Pending |
| Release Readiness Gate | 8 criteria | ⏳ All Pending |

---

## Tasks Summary (from Task Breakdown)

| Milestone | Tasks | Effort | Target Date |
|-----------|-------|--------|-------------|
| M1: Foundation | 10 | 46h | 2026-11-27 |
| M2: Boot & Hardware | 12 | 58h | 2026-12-04 |
| M3: Acceleration & Tier 2 | 10 | 88h | 2026-12-11 |
| M4: Release Hardening | 10 | 42h | 2026-12-18 |
| M5: Monthly Release | 4 | 15h | 2026-12-26 |
| **Total** | **46** | **249h** | **~6 weeks** |

---

## Next Version Planning

| Target | Version | Planned Date | Focus |
|--------|---------|--------------|-------|
| Analyze | 26.12.04 | 2026-12-04 | Cross-artifact consistency validation |
| Implement | 26.12.11+ | 2026-12-11 | Execution begins (M1 tasks) |

---

## Git History (This Version)

```
270a17a docs(speckit): add plan.md — technical architecture per Spec Kit /speckit-plan
150db80 docs(readme): update repository structure with versioned speckit artifacts
2459fdf chore(speckit): enforce CalVer-only versioning, ban SemVer project-wide
51475df chore(speckit): organize spec artifacts into versioned directory 26.11.20
57a0a64 clarifications.md created
937fcdd specs primera version
cd2f867 first draft specs
38d16eb removed markdown (LICENSE)
62511c1 README.md
```

---

*Generated: 2026-11-20T12:46:00+01:00*  
*KoinV Spec Kit 26.11.20 — Traceability Manifest*
