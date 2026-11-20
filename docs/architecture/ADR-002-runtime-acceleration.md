# ADR-002: Runtime Acceleration Strategy (glibc-hwcaps + hwprobe + IFUNC)

**Status:** Accepted  
**Date:** 2026-11-20  
**Deciders:** KoinV Architecture Team  

## Context

RVA23-capable hardware (SpacemiT K3) supports RVV 1.0 vector extensions, but base system runs on RV64GC. Need strategy to utilize vector extensions without breaking compatibility.

## Decision

**Use three-layer runtime acceleration:**
1. **glibc-hwcaps**: Dynamic library loading from `/usr/lib/.../hwcaps/RVA23U64/`
2. **hwprobe syscall**: Kernel exposes CPU capabilities via `riscv_hwprobe` (syscall 442)
3. **IFUNC resolvers**: Runtime function selection via `RISCV_HWPROBE_KEY_IMA_EXT_0`

## Rationale

1. **Zero-cost abstraction**: No overhead on RV64GC hardware
2. **Automatic selection**: Libraries loaded based on actual hardware capabilities
3. **Granular optimization**: Per-function vectorization via IFUNC
4. **Library ecosystem**: Works with existing glibc, OpenSSL, libgcrypt, libjpeg-turbo

## Implementation

### glibc-hwcaps
- Build glibc 2.38+ with `--enable-hwcaps`
- Create `/usr/lib/riscv64-linux-gnu/hwcaps/RVA23U64/` directory
- Place optimized libraries in hwcaps directory

### hwprobe
- Kernel config: `CONFIG_RISCV_HWPROBE=y`
- Userspace queries via syscall 442 (`RISCV_HWPROBE_KEY_IMA_EXT_0`)
- Returns capability bitmask including RVA23U64 bit (0x80000000)

### IFUNC Resolvers
- Define scalar and RVV implementations
- Resolver queries hwprobe at first call
- Caches result for subsequent calls

## Libraries to Optimize

| Library | Functions | Optimization |
|---------|-----------|--------------|
| OpenSSL | AES-GCM, SHA256, RSA | RVV crypto instructions |
| libgcrypt | AES, SHA, RSA | RVV vector crypto |
| libjpeg-turbo | DCT, IDCT, color conversion | RVV vector math |
| glibc | memcpy, memset, memcmp, strlen, strcmp | RVV vector memory/string |
| BLAS/LAPACK | Matrix ops | RVV vector math |

## Consequences

- Requires glibc 2.38+ (backport to Trixie needed)
- Kernel 6.6+ for hwprobe support
- GCC 13+ for IFUNC support
- Opt-in RVA23 overlay for whole-system optimization

## Related

- ADR-001: ISA Baseline Selection
- ADR-003: Kernel Strategy
