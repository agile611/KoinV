# ADR-004: Boot Strategy (UEFI-First + extlinux Fallback)

**Status:** Accepted  
**Date:** 2026-11-20  
**Deciders:** KoinV Architecture Team  

## Context

RISC-V boot flow: M-Mode BootROM → SPL → FIT (OpenSBI + U-Boot) → Linux. UEFI support varies across boards.

## Decision

**UEFI-first boot with extlinux fallback**

## Boot Flow

```
M-Mode BootROM (ZSBL)
    ↓
SPL (FSBL) - DDR Init
    ↓
FIT Image (OpenSBI PLATFORM=generic + U-Boot S-Mode OF_UPSTREAM)
    ↓
UEFI (BOOTRISCV64.EFI)
    ├── systemd-boot (primary) → Linux + DTB from /boot
    └── GRUB2 (fallback) → Linux + DTB from /boot
    ↓ (fallback if no UEFI)
extlinux (u-boot-menu) → Linux + DTB
```

## Components

### OpenSBI
- `PLATFORM=generic` for multi-board support
- Single binary works across all boards

### U-Boot
- `OF_UPSTREAM` for UEFI support
- Produces `BOOTRISCV64.EFI`
- `u-boot-efi-dtb` for DTB override from `/boot`

### Bootloaders
| Bootloader | Role | Priority |
|------------|------|----------|
| systemd-boot | Primary (UKI support) | 1 |
| GRUB2 | Fallback (classic Debian) | 2 |
| extlinux | Non-UEFI fallback | 3 |

### DTB Management
- `u-boot-efi-dtb` reads DTBs from `/boot/dtb/` on ESP
- Overrides stale SPI flash DTBs
- `$fdt_addr_r` handling for early vendor U-Boot quirks

### ACPI
- Enabled in kernel (`CONFIG_ACPI=y`)
- BRS server compliance
- Works alongside Device Tree

## Board Quirks Handled

| Board | Quirk | Solution |
|-------|-------|----------|
| VisionFive 2 8GB | U-Boot defaults to 4GB | DTB override in `/boot/dtb/` |
| VisionFive 2 PCB v1.2B/v1.3A | SD card detect differs | PCB-specific DTB overlays |
| PolarFire Video Kit | i2c0/i2c1 disabled | DTB overlay with `status="okay"` |
| SpacemiT K3 CoM260 TQ | PMIC variant A/B | Compile-time DT overlays |

## Consequences

- Single image boots on all UEFI-capable boards
- extlinux fallback for legacy vendor U-Boot
- DTB updates via package manager (`u-boot-efi-dtb`)
- ACPI for BRS server compliance

## Related

- ADR-003: Kernel Strategy
- ADR-005: Hardware Tier Classification
