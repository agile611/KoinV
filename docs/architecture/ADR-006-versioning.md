# ADR-006: Versioning Scheme (CalVer)

**Status:** Accepted  
**Date:** 2026-11-20  
**Deciders:** Agile611 Koinos RISC-V Architecture Team  

## Context

Need versioning scheme aligned with Debian's time-based releases and hardware enablement cycles.

## Decision

**Use CalVer (Calendar Versioning) exclusively. SemVer prohibited.**

## Version Scheme

| Release Type | Format | Example | When |
|-------------|--------|---------|------|
| Daily/Development | `YY.MM.DD` | `26.11.20` | Every successful CI build |
| Monthly Release | `YY.MM` | `26.11` | First stable build of month |
| Patch/Hotfix | `YY.MM.pN` | `26.11.p1` | Post-release bugfix |

## Rules

1. **No SemVer**: No `MAJOR.MINOR.PATCH`, no `v1.0.0`, no `v2.0.0-beta`
2. **Git tags**: CalVer only, no `v` prefix (`26.11.20` not `v26.11.20`)
5. **Image artifacts**: `koinos-trixie-riscv64-YY.MM.DD.img.xz`
6. **Kernel config**: `CONFIG_LOCALVERSION="-koinos-YY.MM.DD"`
6. **Bootloader**: `CONFIG_VERSION_VARIABLE="koinos-YY.MM.DD"`
7. **Changelogs**: CalVer headers only (`## 26.11.20`)

## Automation

```bash
# Daily tag (CI on main)
VERSION=$(date -u +"%y.%m.%d")
git tag -a "${VERSION}" -m "Agile611 Koinos RISC-V ${VERSION}"

# Monthly release (1st of month)
if [ $(date -u +%d) = "01" ]; then
  REL_VERSION=$(date -u +"%y.%m")
  git tag -a "${REL_VERSION}" -m "Agile611 Koinos RISC-V ${REL_VERSION} Release"
fi
```

## Consequences

- Aligns with Debian's time-based releases
- Hardware enablement tracked by date
- No semantic meaning to version numbers
- Simple automation

## Related

- ADR-001: ISA Baseline Selection
- Constitution §2.1
