# ADR-003: Kernel Strategy (Unified Mainline + Modular BSP)

**Status:** Accepted  
**Date:** 2026-11-20  
**Deciders:** Agile611 Koinos RISC-V Architecture Team  

## Context

RISC-V hardware has diverse SoCs with varying upstream support. Some peripherals (GPU, NPU, VPU) lack mainline drivers.

## Decision

**Unified mainline kernel + modular BSP layer (RevyOS model)**

## Rationale

1. **Single kernel image**: `linux-image-riscv64` with all DTBs
2. **Mandatory errata**: T-Head, SiFive, JH7100 DMA, Andes always enabled
3. **Modular BSP**: Optional `koinos-bsp-*` packages for vendor-specific drivers
4. **Upstream first**: Push patches upstream, remove from BSP when merged

## Kernel Configuration

### Mandatory Features
- All 11 vendor `dts/` directories
- Mandatory errata: T-Head, SiFive, JH7100 DMA, Andes
- Paging: Sv39/Sv48/Sv57 with `no5lvl`/`no4lvl` fallbacks
- Hardening: `CONFIG_HARDENED_USERCOPY`, `CONFIG_FORTIFY_SOURCE=3`, `CONFIG_STACKPROTECTOR_STRONG`
- Module signing: `CONFIG_MODULE_SIG=y`
- UEFI/ACPI: `CONFIG_EFI_STUB`, `CONFIG_ACPI`

### BSP Package Structure

| Package | SoC | Contents |
|---------|-----|----------|
| `koinos-bsp-th1520` | TH1520 | AON, PMU, GPU, VPU, Thermal, DTB overlays |
| `koinos-bsp-jh7110` | JH7110 | GPU, VPU, 8GB memory, PCB rev overlays |
| `koinos-bsp-sg2042` | SG2042 | DDR4 ECC, PCIe Gen4, 10GbE, ACPI |
| `koinos-bsp-spacemit-k3` | K3 | NPU, PMIC variants, RVV 1.0, UFS |

## Upstreaming Policy

1. All patches start in BSP packages
2. Clean up for upstream submission
5. Submit to appropriate upstream (LKML, vendor tree)
4. Track in `docs/bsp/upstream-tracking.md`
5. Remove from BSP package once merged upstream

## Consequences

- Single kernel package for all boards
- Optional BSP packages for advanced features
- Clear upstreaming path reduces maintenance burden
- Users install only needed BSP packages

## Related

- ADR-001: ISA Baseline Selection
- ADR-004: Boot Strategy
