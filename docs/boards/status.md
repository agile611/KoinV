# KoinV Per-Board Status Matrix

**Version:** 26.11.20  
**Last Updated:** 2026-11-20

## Status Definitions

| Status | Meaning |
|--------|---------|
| **GOOD** | Daily driver quality - all features work, stable |
| **BASIC** | Boots and core functions work, some features WIP |
| **CFT** | Can Flash/Test - boots but significant features missing |
| **WIP** | Work In Progress - may not boot or major issues |
| **UNTESTED** | Not yet tested on physical hardware |

---

## Tier 1: Full Linux Systems (54 Boards)

### StarFive JH7110 Boards

| Board | SoC | RAM | Status | Last Tested | Notes |
|-------|-----|-----|--------|-------------|-------|
| VisionFive 2 (2GB) | JH7110 | 2 GB | GOOD | 2026-11-20 | Full support |
| VisionFive 2 (4GB) | JH7110 | 4 GB | GOOD | 2026-11-20 | Full support |
| VisionFive 2 (8GB) | JH7110 | 8 GB | GOOD | 2026-11-20 | Requires 8GB DTB overlay |
| Milk-V Mars (1GB) | JH7110 | 1 GB | GOOD | 2026-11-20 | |
| Milk-V Mars (2GB) | JH7110 | 2 GB | GOOD | 2026-11-20 | |
| Milk-V Mars (4GB) | JH7110 | 4 GB | GOOD | 2026-11-20 | |
| Milk-V Mars (8GB) | JH7110 | 8 GB | GOOD | 2026-11-20 | |
| Star64 (4GB) | JH7110 | 4 GB | BASIC | 2026-11-15 | SATA WIP |
| Star64 (8GB) | JH7110 | 8 GB | BASIC | 2026-11-15 | SATA WIP |
| PineTab-V (4GB) | JH7110 | 4 GB | CFT | 2026-11-10 | Touchscreen WIP |
| PineTab-V (8GB) | JH7110 | 8 GB | CFT | 2026-11-10 | Touchscreen WIP |
| OrangePi RV (2GB) | JH7110 | 2 GB | BASIC | 2026-11-15 | |
| OrangePi RV (4GB) | JH7110 | 4 GB | BASIC | 2026-11-15 | |
| OrangePi RV (8GB) | JH7110 | 8 GB | BASIC | 2026-11-15 | |

### SpacemiT K1/M1/K3 Boards

| Board | SoC | RAM | Status | Last Tested | Notes |
|-------|-----|-----|--------|-------------|-------|
| Banana Pi BPI-F3 (2GB) | K1 | 2 GB | BASIC | 2026-11-15 | |
| Banana Pi BPI-F3 (4GB) | K1 | 4 GB | BASIC | 2026-11-15 | |
| Banana Pi BPI-F3 (8GB) | K1 | 8 GB | BASIC | 2026-11-15 | |
| Banana Pi BPI-F3 (16GB) | K1 | 16 GB | BASIC | 2026-11-15 | |
| Lichee Pi 3A (8GB) | K1 | 8 GB | GOOD | 2026-11-15 | |
| Lichee Pi 3A (16GB) | K1 | 16 GB | GOOD | 2026-11-15 | |
| OrangePi RV2 (2GB) | K1 | 2 GB | BASIC | 2026-11-15 | |
| OrangePi RV2 (4GB) | K1 | 4 GB | BASIC | 2026-11-15 | |
| OrangePi RV2 (8GB) | K1 | 8 GB | BASIC | 2026-11-15 | |
| DC-ROMA Laptop II (8GB) | K1 | 8 GB | CFT | 2026-11-10 | |
| DC-ROMA Laptop II (16GB) | K1 | 16 GB | CFT | 2026-11-10 | |
| DC-ROMA Pad II (16GB) | K1 | 16 GB | CFT | 2026-11-10 | |
| BIT-BRICK K1 (4GB) | K1 | 4 GB | BASIC | 2026-11-15 | |
| BIT-BRICK K1 (8GB) | K1 | 8 GB | BASIC | 2026-11-15 | |
| Milk-V Jupiter (4GB) | K1/M1 | 4 GB | GOOD | 2026-11-15 | |
| Milk-V Jupiter (8GB) | K1/M1 | 8 GB | GOOD | 2026-11-15 | |
| Milk-V Jupiter (16GB) | K1/M1 | 16 GB | GOOD | 2026-11-15 | |
| MUSE Book (8GB) | M1 | 8 GB | CFT | 2026-11-10 | |
| MUSE Book (16GB) | M1 | 16 GB | CFT | 2026-11-10 | |
| Muse Pi Pro (8GB) | M1 | 8 GB | GOOD | 2026-11-15 | |
| Muse Pi Pro (16GB) | M1 | 16 GB | GOOD | 2026-11-15 | |

### T-Head TH1520 Boards

| Board | SoC | RAM | Status | Last Tested | Notes |
|-------|-----|-----|--------|-------------|-------|
| Lichee Pi 4A (8GB) | TH1520 | 8 GB | GOOD | 2026-11-20 | |
| Lichee Pi 4A (16GB) | TH1520 | 16 GB | GOOD | 2026-11-20 | |
| Lichee Console 4A (8GB) | TH1520 | 8 GB | GOOD | 2026-11-20 | |
| Lichee Console 4A (16GB) | TH1520 | 16 GB | GOOD | 2026-11-20 | |
| Lichee Cluster 4A (8GB) | TH1520 | 8 GB | BASIC | 2026-11-15 | |
| Lichee Cluster 4A (16GB) | TH1520 | 16 GB | BASIC | 2026-11-15 | |
| BeagleV-Ahead (4GB) | TH1520 | 4 GB | CFT | 2026-11-15 | AON/VPU WIP |
| Milk-V Meles (8GB) | TH1520 | 8 GB | GOOD | 2026-11-20 | |
| Milk-V Meles (16GB) | TH1520 | 16 GB | GOOD | 2026-11-20 | |

### SiFive FU740 Boards

| Board | SoC | RAM | Status | Last Tested | Notes |
|-------|-----|-----|--------|-------------|-------|
| HiFive Unmatched A00 (16GB) | FU740 | 16 GB | GOOD | 2026-11-15 | |

### Sophgo SG2042 Boards

| Board | SoC | RAM | Status | Last Tested | Notes |
|-------|-----|-----|--------|-------------|-------|
| Milk-V Pioneer | SG2042 | DDR4 DIMM | GOOD | 2026-11-20 | DDR4 DIMM slots |

### SpacemiT K3 Boards (RVA23)

| Board | SoC | RAM | Status | Last Tested | Notes |
|-------|-----|-----|--------|-------------|-------|
| SpacemiT K3 Pico-ITX (16GB) | K3 | 16 GB | BASIC | 2026-11-15 | RVA23 WIP |
| SpacemiT K3 Pico-ITX (32GB) | K3 | 32 GB | BASIC | 2026-11-15 | RVA23 WIP |
| SpacemiT K3 CoM260 TQ (16GB) | K3 | 16 GB | CFT | 2026-11-15 | PMIC variants |
| SpacemiT K3 AI Book | K3 | 16/32 GB | WIP | - | Not yet tested |
| DeepComputing Mainboard III | K3 | 16/32 GB | WIP | - | Not yet tested |
| C2201 Dual-Socket V100 | K3 | 64+ GB | WIP | - | Not yet tested |

### Other Boards

| Board | SoC | RAM | Status | Last Tested | Notes |
|-------|-----|-----|--------|-------------|-------|
| AWOL Nezha (1GB) | D1 | 1 GB | GOOD | 2026-11-15 | |
| AWOL Nezha (2GB) | D1 | 2 GB | GOOD | 2026-11-15 | |
| BeagleV-Fire (2GB) | MPFS025T | 2 GB | CFT | 2026-11-15 | |
| BeagleV Starlight | JH7100 | - | CFT | 2026-11-15 | JH7100 DMA errata |
| DC-ROMA Mainboard II (32GB) | EIC7702X | 32 GB | CFT | 2026-11-10 | |
| DC-ROMA Mainboard II (64GB) | EIC7702X | 64 GB | CFT | 2026-11-10 | |
| DC-ROMA RISC-V Mainboard (8GB) | JH7110 | 8 GB | CFT | 2026-11-10 | |
| DeepComputing FML13V05 | K3 | - | WIP | - | |
| DP1000-DEMO-M0 | UR-DP1000 | DDR4 slot | WIP | - | |
| EBC7700 | EIC7700X | LPDDR5 | CFT | 2026-11-10 | |
| EBC7702 (32GB) | EIC7702X | 32 GB | GOOD | 2026-11-15 | |
| EBC7702 (64GB) | EIC7702X | 64 GB | GOOD | 2026-11-15 | |
| HiFive Premier P550 (16GB) | EIC7700X | 16 GB | GOOD | 2026-11-15 | |
| HiFive Premier P550 (32GB) | EIC7700X | 32 GB | GOOD | 2026-11-15 | |
| HiFive Unleashed A00 | FU540-C000 | - | BASIC | 2026-11-10 | |
| Huashan Pi (1GB) | CV1812H | 1 GB | CFT | 2026-11-10 | |
| Huashan Pi (2GB) | CV1812H | 2 GB | CFT | 2026-11-10 | |
| Huashan Pi (4GB) | CV1812H | 4 GB | CFT | 2026-11-10 | |
| Milk-V Jupiter2 (8GB) | K3 | 8 GB | WIP | - | RVA23 flagship |
| Milk-V Jupiter2 (16GB) | K3 | 16 GB | WIP | - | RVA23 flagship |
| Milk-V Jupiter2 (32GB) | K3 | 32 GB | WIP | - | RVA23 flagship |
| Milk-V Megrez (8GB) | EIC7700X | 8 GB | GOOD | 2026-11-15 | |
| Milk-V Megrez (16GB) | EIC7700X | 16 GB | GOOD | 2026-11-15 | |
| Milk-V Megrez (32GB) | EIC7700X | 32 GB | GOOD | 2026-11-15 | |
| Milk-V Titan | UR-DP1000 | DDR4 slot | WIP | - | |
| OrangePi R2S (2GB) | K1 | 2 GB | CFT | 2026-11-10 | |
| OrangePi R2S (4GB) | K1 | 4 GB | CFT | 2026-11-10 | |
| OrangePi R2S (8GB) | K1 | 8 GB | CFT | 2026-11-10 | |
| PIC64GX Curiosity Kit (1GB) | PIC64GX | 1 GB | CFT | 2026-11-10 | |
| PolarFire FPGA SoC Icicle Kit (2GB) | MPFS250T | 2 GB | BASIC | 2026-11-15 | |
| Renesas RZ/Five | R9A07G043 | - | BASIC | 2026-11-15 | |
| StarPro64 (8GB) | EIC7700X | 8 GB | UNTESTED | - | |
| StarPro64 (16GB) | EIC7700X | 16 GB | UNTESTED | - | |
| StarPro64 (32GB) | EIC7700X | 32 GB | UNTESTED | - | |
| Tang Mega 138K (1GB) | AE350 | 1 GB | BASIC | 2026-11-10 | |
| UR-DP1000-EVB | UR-DP1000 | DDR4 slot | WIP | - | |
| VisionFive v1 (8GB) | JH7100 | 8 GB | GOOD | 2026-11-15 | JH7100 DMA errata |
| VisionFive 2 Lite (2GB) | JH7110S | 2 GB | BASIC | 2026-11-15 | |
| VisionFive 2 Lite (4GB) | JH7110S | 4 GB | BASIC | 2026-11-15 | |
| VisionFive 2 Lite (8GB) | JH7110S | 8 GB | BASIC | 2026-11-15 | |

---

## Tier 2: Ultra-Light / Constrained Boards (18 Boards)

| Board | SoC | RAM | Status | Last Tested | Notes |
|-------|-----|-----|--------|-------------|-------|
| D1s NeZha | D1s | 64 MB | BASIC | 2026-11-10 | |
| DongshanPI-D1s | D1s | 64 MB | CFT | 2026-11-10 | |
| DongshanPI-Nezha STU (256MB) | D1 | 256 MB | BASIC | 2026-11-10 | |
| LicheeRV Nano (256MB) | SG2002 | 256 MB | BASIC | 2026-11-10 | Heterogeneous |
| Mangopi MQ D1s (64MB) | D1s | 64 MB | BASIC | 2026-11-10 | |
| Milk-V Duo 64M | CV1800B | 64 MB | BASIC | 2026-11-10 | |
| Milk-V Duo 256M | SG2002 | 256 MB | BASIC | 2026-11-10 | Heterogeneous |
| Milk-V Duo S (512MB) | SG2000 | 512 MB | BASIC | 2026-11-10 | Heterogeneous |
| Milk-V Vega | FSL1030M | - | UNTESTED | - | |
| Pine64 Ox64 | BL808 | 768KB+64MB | BASIC | 2026-11-10 | |
| Pine64 Oz64 (512MB) | SG2000 | 512 MB | BASIC | 2026-11-10 | Heterogeneous |
| RT-Thread RDC2022 Memorial | D1s | 64 MB | UNTESTED | - | |
| Sipeed M1s Dock | BL808 | 768KB+64MB | CFT | 2026-11-10 | |
| Sipeed Maix-Bit | K210 | 8 MB | UNTESTED | - | |
| 100ASK-V853-PRO | V853 | 512MB/1GB | UNTESTED | - | Heterogeneous |
| V853 Dev Board | V853 | 512 MB | UNTESTED | - | Heterogeneous |
| TinyVision V851se | V851se | 64 MB | UNTESTED | - | Heterogeneous |
| YuzukiHD-Lizard | V851s | 64 MB | UNTESTED | - | Heterogeneous |

---

## Tier 3: MCU/RTOS Only (27 Boards) - EXCLUDED

| Board Family | Boards | Status |
|--------------|--------|--------|
| WCH QingKe | 10 boards | EXCLUDED |
| Espressif ESP32 | 6 boards | EXCLUDED |
| GigaDevice GD32VF103 | 4 boards | EXCLUDED |
| Bouffalo Lab | 4 boards | EXCLUDED |
| Other MCUs | 3 boards | EXCLUDED |

---

## Dynamic DT Targets

| Platform | Status | Notes |
|----------|--------|-------|
| QEMU virt | GOOD | Primary CI target |
| QEMU sifive_u | GOOD | Secondary CI target |
| QEMU microchip-icicle | BASIC | |
| QEMU shakti-c | UNTESTED | |
| QEMU tt_atlantis | UNTESTED | |
| Spike | BASIC | |
| LiteX + LiteX-Boards | BASIC | 250+ FPGA boards |
| Renode | BASIC | |
| OpenPiton | UNTESTED | |
| Chipyard | UNTESTED | |
| Coreboot | UNTESTED | ACPI only |

---

## Summary Statistics

| Tier | Total Boards | GOOD | BASIC | CFT | WIP | UNTESTED |
|------|--------------|------|-------|-----|-----|----------|
| Tier 1 | 54 | 22 | 18 | 8 | 6 | 0 |
| Tier 2 | 18 | 0 | 8 | 4 | 0 | 6 |
| Tier 3 | 27 | 0 | 0 | 0 | 0 | 27 (EXCLUDED) |
| Dynamic | 6 | 2 | 1 | 0 | 0 | 3 |

**Total Testable: 78 boards**  
**Currently GOOD: 22**  
**Currently BASIC: 26**  
**Currently CFT: 12**  
**Currently WIP: 6**  
**Currently UNTESTED: 9**  
**EXCLUDED: 27**

---

*Last Updated: 2026-11-20*  
*Next Review: 2026-11-27*
