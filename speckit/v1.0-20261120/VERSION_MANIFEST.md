# KoinV Spec Kit — Version Manifest

**Version:** v1.0  
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
| 4 | `/speckit-plan` | `plan.md` | ⏳ Pending |
| 5 | `/speckit-checklist` | `checklist.md` | ⏳ Pending |
| 6 | `/speckit-tasks` | `tasks.md` | ⏳ Pending |
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

## Next Version Planning

| Target | Version | Planned Date | Focus |
|--------|---------|--------------|-------|
| Plan | v1.1 | 2026-11-27 | Architecture diagrams, tech stack, interface contracts |
| Checklist | v1.1 | 2026-11-27 | Requirement verification matrix |
| Tasks | v1.1 | 2026-11-27 | Ordered task breakdown with dependencies |
| Analyze | v1.2 | 2026-12-04 | Cross-artifact consistency validation |
| Implement | v1.2+ | 2026-12-11 | Execution begins |

---

## Git History (This Version)

```
57a0a64 clarifications.md created
937fcdd specs primera version
cd2f867 first draft specs
38d16eb removed markdown (LICENSE)
62511c1 README.md
```

---

*Generated: 2026-11-20T12:33:00+01:00*  
*KoinV Spec Kit v1.0 — Traceability Manifest*
