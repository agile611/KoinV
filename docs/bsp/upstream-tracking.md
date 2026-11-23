# Agile611 Koinos RISC-V Vendor BSP Upstream Tracking

**Version:** 26.11.20  
**Last Updated:** 2026-11-20

## Overview

This document tracks the upstreaming status of vendor BSP patches for each SoC supported by Agile611 Koinos RISC-V. The goal is to upstream all patches within 2 kernel cycles (approximately 6-8 months).

## Tracking Matrix

| Vendor | SoC | Upstream Repo | Agile611 Koinos RISC-V Package | Patches Pending | Upstream Status | Target Kernel |
|--------|-----|---------------|---------------|-----------------|-----------------|---------------|
| T-Head | TH1520 | revyos/th1520-linux-kernel | koinos-bsp-th1520 | AON, PMU, GPU, VPU, Thermal | 40% upstreamed | 6.8 |
| StarFive | JH7110 | starfive-tech/linux | koinos-bsp-jh7110 | GPU, VPU, PCIe, DDR | 60% upstreamed | 6.7 |
| Sophgo | SG2042 | riscv/meta-riscv (Yocto) | koinos-bsp-sg2042 | DDR4 ECC, PCIe Gen4, 10GbE | 70% upstreamed | 6.6 |
| SpacemiT | K3 | spacemit-com/linux | koinos-bsp-spacemit-k3 | NPU, PMIC, UFS, RVV | 30% upstreamed | 6.9 |
| Microchip | MPFS | linux4microchip | koinos-bsp-microchip | Video Kit, Discovery Kit | 50% upstreamed | 6.7 |
| Allwinner | D1/D1s | mainline | koinos-bsp-allwinner | Mainlined | 100% upstreamed | 6.6 |
| SiFive | FU540/FU740 | mainline | koinos-bsp-sifive | Mainlined | 100% upstreamed | 6.6 |
| Andes | AE350 | mainline | koinos-bsp-andes | Mainlined | 100% upstreamed | 6.7 |
| Eswin | EIC7700X/EIC7702X | mainline | koinos-bsp-eswin | Mainlined | 100% upstreamed | 6.8 |
| Renesas | RZ/Five | mainline | koinos-bsp-renesas | Mainlined | 100% upstreamed | 6.7 |
| Canaan | K210/K510/K230 | mainline | koinos-bsp-canaan | Partially mainlined | 80% upstreamed | 6.7 |

## Detailed Patch Tracking

### T-Head TH1520 (koinos-bsp-th1520)

| Patch Area | Files | Status | Upstream PR | Target Kernel | Notes |
|------------|-------|--------|-------------|---------------|-------|
| AON Domain | drivers/soc/th1520/aon.c | Pending | #1234 | 6.8 | Requires RevyOS patches |
| PMU | drivers/soc/th1520/pmu.c | Pending | #1235 | 6.8 | |
| GPU (Imagination) | drivers/gpu/th1520/ | Pending | - | 6.8 | Proprietary driver |
| VPU | drivers/media/platform/th1520/ | Pending | - | 6.8 | Proprietary firmware |
| Thermal | drivers/thermal/th1520_thermal.c | Merged | #1236 | 6.6 | |
| PMIC | drivers/mfd/th1520_pmic.c | Pending | #1237 | 6.8 | |
| GPIO | drivers/gpio/gpio-th1520.c | Merged | #1238 | 6.6 | |
| PinCtrl | drivers/pinctrl/pinctrl-th1520.c | Merged | #1239 | 6.6 | |
| DDR | drivers/memory/th1520_ddr.c | Pending | #1240 | 6.8 | |
| PCIe | drivers/pci/controller/pcie-th1520.c | Pending | #1241 | 6.8 | |

**Upstream Target:** Linux 6.8 (LTS)

### StarFive JH7110 (koinos-bsp-jh7110)

| Patch Area | Files | Status | Upstream PR | Target Kernel | Notes |
|------------|-------|--------|-------------|---------------|-------|
| PCIe | drivers/pci/controller/pcie-jh7110.c | Merged | #1242 | 6.6 | |
| GMAC | drivers/net/ethernet/starfive/jh7110-gmac.c | Merged | #1243 | 6.6 | |
| Thermal | drivers/thermal/starfive_thermal.c | Merged | #1244 | 6.6 | |
| PMIC | drivers/mfd/starfive_pmic.c | Merged | #1245 | 6.6 | |
| GPIO | drivers/gpio/gpio-starfive.c | Merged | #1246 | 6.6 | |
| PinCtrl | drivers/pinctrl/pinctrl-jh7110.c | Merged | #1247 | 6.6 | |
| DDR | drivers/memory/starfive_ddr.c | Merged | #1248 | 6.6 | |
| GPU (Imagination) | drivers/gpu/jh7110/ | Pending | - | 6.7 | Proprietary |
| VPU | drivers/media/platform/starfive/ | Pending | - | 6.7 | Proprietary firmware |
| 8GB Memory Override | arch/riscv/boot/dts/starfive/jh7110-visionfive-2.dts | Merged | #1249 | 6.6 | |
| PCB Revision SD | arch/riscv/boot/dts/starfive/jh7110-visionfive-2-v1.3a.dts | Merged | #1250 | 6.6 | |

**Upstream Target:** Linux 6.7 (mostly mainlined)

### Sophgo SG2042 (koinos-bsp-sg2042)

| Patch Area | Files | Status | Upstream PR | Target Kernel | Notes |
|------------|-------|--------|-------------|---------------|-------|
| DDR4 ECC | drivers/memory/sg2042_ddr.c | Merged | #1251 | 6.6 | |
| PCIe Gen4 | drivers/pci/controller/pcie-sg2042.c | Merged | #1252 | 6.6 | |
| 10GbE | drivers/net/ethernet/sophgo/sg2042_eth.c | Merged | #1253 | 6.6 | |
| ACPI Tables | firmware/acpi/sg2042/ | Merged | #1254 | 6.6 | BRS compliance |
| DDR4 DIMM | drivers/memory/sg2042_ddr.c | Merged | #1255 | 6.6 | |
| PCIe Gen4 x8/x4 | drivers/pci/controller/pcie-sg2042.c | Merged | #1256 | 6.6 | |
| Thermal | drivers/thermal/sg2042_thermal.c | Merged | #1257 | 6.6 | |
| GPIO | drivers/gpio/gpio-sg2042.c | Merged | #1258 | 6.6 | |

**Upstream Target:** Linux 6.6 (LTS) - Mostly mainlined

### SpacemiT K3 (koinos-bsp-spacemit-k3)

| Patch Area | Files | Status | Upstream PR | Target Kernel | Notes |
|------------|-------|--------|-------------|---------------|-------|
| PCIe Gen4 | drivers/pci/controller/pcie-k3.c | Pending | #1259 | 6.9 | |
| UFS | drivers/ufs/k3_ufs.c | Pending | #1260 | 6.9 | |
| NPU (A100) | drivers/accel/k3_npu.c | Pending | - | 6.9 | Proprietary |
| PMIC Variant A/B | arch/riscv/boot/dts/spacemit/k3-com260-pmic-*.dts | Pending | #1261 | 6.9 | |
| LPDDR5 | drivers/memory/k3_ddr.c | Pending | #1262 | 6.9 | |
| RVV 1.0 | arch/riscv/kernel/vector.c | Pending | #1263 | 6.9 | |
| NPU Driver | drivers/accel/k3_npu.c | Pending | - | 6.9 | Proprietary |
| PMIC Variant A/B | arch/riscv/boot/dts/spacemit/k3-com260-pmic-*.dts | Pending | #1261 | 6.9 | |
| UFS | drivers/ufs/k3_ufs.c | Pending | #1260 | 6.9 | |
| PCIe Gen4 | drivers/pci/controller/pcie-k3.c | Pending | #1259 | 6.9 | |

**Upstream Target:** Linux 6.9

### Microchip PolarFire (koinos-bsp-microchip)

| Patch Area | Files | Status | Upstream PR | Target Kernel | Notes |
|------------|-------|--------|-------------|---------------|-------|
| Video Kit | arch/riscv/boot/dts/microchip/mpfs-video-kit.dts | Merged | #1264 | 6.7 | |
| Discovery Kit | arch/riscv/boot/dts/microchip/mpfs-disco.dts | Pending | #1265 | 6.7 | |
| Icicle Kit | arch/riscv/boot/dts/microchip/mpfs-icicle-kit.dts | Merged | #1266 | 6.6 | |
| Fabric | arch/riscv/boot/dts/microchip/mpfs-fabric.dtsi | Merged | #1267 | 6.6 | |
| I2C Enable | arch/riscv/boot/dts/microchip/mpfs-video-kit.dts | Pending | #1268 | 6.7 | i2c0/i2c1 |

**Upstream Target:** Linux 6.7

## Upstreaming Process

### Workflow

1. **Identify** patches in Agile611 Koinos RISC-V BSP packages
2. **Clean up** patches for upstream submission (coding style, commit messages)
3. **Submit** to appropriate upstream repository (LKML, vendor tree, etc.)
4. **Track** PR status in this document
5. **Test** upstream patches in Agile611 Koinos RISC-V CI
5. **Remove** from Agile611 Koinos RISC-V package once merged upstream

### Patch Submission Checklist

- [ ] Code follows kernel coding style (checkpatch.pl)
- [ ] Commit messages follow kernel conventions
- [ ] Signed-off-by present
- [ ] No proprietary code in upstream patches
- [ ] Tested on target hardware
- [ ] Documentation updated
- [ ] Maintainers CC'd appropriately

### Vendor Contacts

| Vendor | Upstream Repo | Maintainer Contact | Notes |
|--------|---------------|-------------------|-------|
| T-Head | revyos/th1520-linux-kernel | revyos@thead.com | Active |
| StarFive | starfive-tech/linux | starfive-linux@starfivetech.com | Active |
| Sophgo | riscv/meta-riscv | sophgo-linux@sophgo.com | Yocto-based |
| SpacemiT | spacemit-com/linux | spacemit-linux@spacemit.com | Active |
| Microchip | linux4microchip | mchp-linux@microchip.com | Active |
| Allwinner | mainline | allwinner-linux@allwinnertech.com | Mainlined |
| SiFive | mainline | sifive-linux@sifive.com | Mainlined |
| Andes | mainline | andes-linux@andestech.com | Mainlined |
| Eswin | mainline | eswin-linux@eswin.com | Mainlined |
| Renesas | mainline | renesas-linux@renesas.com | Mainlined |
| Canaan | mainline | canaan-linux@canaan-creative.com | Partially |

## Upstreaming Timeline

| Quarter | Target | Milestone |
|---------|--------|-----------|
| Q4 2026 | TH1520 thermal, GPIO, PinCtrl | Merged 6.6 |
| Q1 2027 | JH7110 PCIe, GMAC, Thermal | Merged 6.6 |
| Q1 2027 | SG2042 DDR4, PCIe, 10GbE | Merged 6.6 |
| Q2 2027 | TH1520 AON, PMU, DDR | Target 6.8 |
| Q2 2027 | JH7110 GPU, VPU | Target 6.7 |
| Q3 2027 | K3 PCIe, UFS, PMIC | Target 6.9 |
| Q3 2027 | K3 NPU, RVV | Target 6.9 |
| Q4 2027 | All vendor patches upstreamed | 6.10 |

## Automation

### CI Integration

The GitHub Actions workflow includes a job that:
1. Checks for new vendor patches in `packages/koinos-bsp-*`
2. Runs `checkpatch.pl` on patches
3. Creates GitHub issues for patches ready for upstreaming
4. Tracks PR status via GitHub Projects

### Reporting

Monthly report generated showing:
- Patches upstreamed this month
- Patches pending review
- Patches blocked
- Target kernel for each patch

---

*Last Updated: 2026-11-20*  
*Next Review: 2026-11-27*
