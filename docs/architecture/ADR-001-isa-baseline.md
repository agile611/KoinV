# ADR-001: ISA Baseline Selection (RV64GC/RVA20)

**Status:** Accepted  
**Date:** 2026-11-20  
**Deciders:** Agile611 Koinos RISC-V Architecture Team  

## Context

The RISC-V ecosystem has multiple ISA profiles:
- **RV64GC (RVA20)**: Base 64-bit ISA + MAFD + C extensions. Supported by all pre-2026 boards.
- **RVA23**: RV64GC + Vector (RVV 1.0) + Hypervisor + Crypto + Bitmanip. Required by Ubuntu 25.10+.

## Decision

**Use RV64GC (RVA20) as the baseline ISA for all Agile611 Koinos RISC-V base packages.**

## Rationale

1. **Maximum Hardware Compatibility**: Pre-2026 boards (VisionFive 2, Milk-V Mars, Star64, Lichee Pi 4A, Allwinner D1, Milk-V Pioneer) only support RV64GC/RVA20.
2. **Debian Alignment**: Debian 13 "Trixie" uses RV64GC baseline; Debian 14 "Forky" expected to raise to at most RVA20U64.
3. **Runtime Acceleration**: Use `glibc-hwcaps` + `hwprobe` + `IFUNC` to dynamically load RVA23-optimized libraries on capable hardware (SpacemiT K3).
4. **No Fragmentation**: Avoids splitting distribution into incompatible repositories.

## Consequences

- Base packages compile for RV64GC, run on all hardware
- RVA23 acceleration via `glibc-hwcaps` + `hwprobe` + `IFUNC` at runtime
- Optional RVA23 opt-in overlay for whole-system optimization
- No mandatory RVA23 requirement for base system

## Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Mandatory RVA23 | Maximum performance on new hardware | Breaks all pre-2026 boards | Rejected |
| Dual repositories (RV64GC + RVA23) | Clean separation | Maintenance burden, user confusion | Rejected |
| RV64GC baseline + hwcaps | Compatibility + performance | Complexity in toolchain | **Accepted** |

## Related

- ADR-002: Runtime Acceleration Strategy
- ADR-003: Kernel Strategy
