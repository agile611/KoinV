# QEMU virt / sifive_u — KoinV Development Target

## Machine Types
| Machine | Description | Use Case |
|---------|-------------|----------|
| `virt` | Generic RISC-V virt machine | Primary CI/testing target |
| `sifive_u` | SiFive U74-like machine | SiFive-compatible testing |
| `microchip-icicle` | Microchip Icicle Kit | PolarFire testing |
| `shakti-c` | SHAKTI C-class | Academic/testing |
| `tt_atlantis` | T-Head Atlantis | T-Head testing |

## Quick Start

### Download Latest Image
```bash
# From GitHub Releases
wget https://github.com/agile611/KoinV/releases/download/26.11.20/koinv-trixie-riscv64-26.11.20.img.xz
xz -d koinv-trixie-riscv64-26.11.20.img.xz
```

### Run virt Machine
```bash
qemu-system-riscv64 \
    -machine virt \
    -cpu rv64 \
    -m 2G \
    -smp 2 \
    -drive file=koinv-trixie-riscv64-26.11.20.img,format=raw,if=virtio \
    -nographic \
    -no-reboot \
    -device virtio-rng-pci \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22
```

### Run sifive_u Machine
```bash
qemu-system-riscv64 \
    -machine sifive_u \
    -cpu rv64 \
    -m 2G \
    -smp 2 \
    -drive file=koinv-trixie-riscv64-26.11.20.img,format=raw,if=virtio \
    -nographic \
    -no-reboot \
    -device virtio-rng-pci \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22
```

## SSH Access
```bash
# Port forwarded to localhost:2222
ssh -p 2222 root@localhost
# Default password: koinv (change on first boot!)
```

## Development Workflow
1. Make changes to KoinV source
2. Run `./images/build-image.sh` (or CI pipeline)
3. Test in QEMU: `./tests/qemu-smoke.sh build/output/koinv-*.img.xz build/kernel/Image build/kernel/dtb`
4. Iterate

## CI Integration
The GitHub Actions workflow runs QEMU smoke tests on every push:
- `virt` machine test
- `sifive_u` machine test
- Both must pass for merge

## Debugging Tips
- Use `-s -S` for GDB debugging: `qemu-system-riscv64 ... -s -S`
- Connect GDB: `gdb-multiarch -ex "target remote localhost:1234" build/kernel/vmlinux`
- Use `-d in_asm,cpu` for instruction tracing
- Monitor serial output for boot messages

## Resources
- [QEMU RISC-V Documentation](https://www.qemu.org/docs/master/system/target/riscv.html)
- [KoinV CI Workflow](https://github.com/agile611/KoinV/blob/main/.github/workflows/build.yml)
