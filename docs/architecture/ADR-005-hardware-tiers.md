# ADR-005: Hardware Tier Classification

**Status:** Accepted  
**Date:** 2026-11-20  
**Deciders:** Agile611 Koinos RISC-V Architecture Team  

## Context

RISC-V hardware varies dramatically in capabilities. Need clear classification for support strategy.

## Decision

**Three-tier classification based on RAM and MMU capability**

## Tier Definitions

### Tier 1: Full Linux Systems (54 Boards)
- **RAM**: 512 MB – 64 GB (or DDR4 slots)
- **MMU**: Yes (Sv39/Sv48/Sv57)
- **Architecture**: `riscv64` (RV64GC baseline)
- **User Space**: Debian 13 "Trixie" (glibc + systemd)
- **Kernel**: Unified mainline + BSP packages
- **Boot**: UEFI-first + extlinux fallback

**Examples**: VisionFive 2, Milk-V Mars, Star64, Lichee Pi 4A, Milk-V Pioneer, SpacemiT K3, HiFive Unmatched

### Tier 2: Ultra-Light / Constrained / Hybrid (18 Boards)
- **RAM**: 64 MB – 512 MB (or SRAM/PSRAM)
- **MMU**: Yes (Sv39) or heterogeneous (ARM + RISC-V)
- **Architecture**: `riscv64` (RV64GC baseline)
- **User Space**: Buildroot + musl + BusyBox (5–50 MB)
- **Init**: BusyBox init (no systemd)
- **Kernel**: Shared with Tier 1 (same DTBs)
- **Boot**: extlinux (UEFI often unavailable)

**Examples**: Milk-V Duo 64M/256M, LicheeRV Nano, Pine64 Ox64/Oz64, D1s NeZha

### Tier 3: MCU/RTOS Only (27 Boards) - EXCLUDED
- **RAM**: 2 KB – 1 MB SRAM (or up to 16-32 MB PSRAM)
- **MMU**: No
- **Architecture**: `riscv32` or `rv32imc`
- **OS**: RTOS only (RT-Thread, FreeRTOS, Zephyr, LiteOS)
- **Linux**: Not supported

**Examples**: WCH QingKe, ESP32-C3/C6, GD32VF103, Bouffalo Lab BL602/702

## Dynamic/Non-Static DT Targets

| Platform | DT Source | Integration |
|----------|-----------|-------------|
| QEMU (virt, sifive_u, etc.) | Runtime (`${fdtcontroladdr}`) | Primary CI target |
| Spike | Runtime (`riscv/dts.cc` + `dtc`) | Compatible |
| LiteX + LiteX-Boards | `csr.json` → DT | 250+ FPGA boards |
| Renode | Custom platforms / `csr.json` | Simulation |
| OpenPiton/Chipyard | RTL-generated | FPGA/ASIC |
| Coreboot | ACPI tables | No Linux DTB |

## Consequences

- Clear support boundaries
- Tier 1 gets full Debian experience
- Tier 2 gets minimal but functional Linux
- Tier 3 explicitly excluded (no false expectations)
- Dynamic DT targets documented and supported where possible

## Related

- ADR-001: ISA Baseline Selection
- ADR-003: Kernel Strategy
- ADR-004: Boot Strategy
