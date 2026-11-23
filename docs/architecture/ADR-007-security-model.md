# ADR-007: Security Model

**Status:** Accepted  
**Date:** 2026-11-20  
**Deciders:** Agile611 Koinos RISC-V Architecture Team  

## Context

Need comprehensive security model for boot chain, runtime, and supply chain.

## Decision

**Multi-layer defense-in-depth security model**

## Layers

### 1. Boot Chain Security
| Layer | Mechanism | Status |
|-------|-----------|--------|
| BootROM (M-Mode) | Hardware RoT (vendor) | Vendor-dependent |
| OpenSBI | Measured boot | `PLATFORM=generic` |
| U-Boot | Verified boot (FIT signature) | `OF_UPSTREAM` |
| UEFI | Secure Boot (shim + MOK) | `grub-efi-riscv64` + `sbctl` |
| Kernel | Lockdown + module signing | `CONFIG_MODULE_SIG=y` |
| Initramfs | Measured/verified | `systemd-boot` UKI |

### 2. Runtime Hardening
| Control | Implementation |
|---------|----------------|
| Kernel hardening | `CONFIG_HARDENED_USERCOPY`, `CONFIG_FORTIFY_SOURCE=3`, `CONFIG_STACKPROTECTOR_STRONG`, `CONFIG_PAGE_TABLE_ISOLATION` |
| Memory protection | `CONFIG_STRICT_DEVMEM`, `CONFIG_STRICT_KERNEL_RWX`, `CONFIG_DEBUG_RODATA` |
| Userspace | `glibc` `FORTIFY_SOURCE=3`, `PIE`/`RELRO` by default |
| MAC | AppArmor profiles (Debian default) |
| Audit | `auditd` + kernel audit subsystem |

### 3. Supply Chain Integrity
| Control | Implementation |
|---------|----------------|
| Reproducible builds | Pinned commits, deterministic flags, `SOURCE_DATE_EPOCH` |
| SBOM | SPDX JSON for every image (`syft`) |
| Signature | `cosign`/`gpg` sign git tags and artifacts |
| Verification | `cosign verify` / `gpg --verify` in CI |

### 4. Secure Boot Enrollment
- Shim + MOK enrollment via `mokutil`
- Kernel signing with `sbsign`
- Module signing via `scripts/sign-file`
- MOK enrollment documented per board in `docs/boards/`

## Consequences

- Secure Boot supported on capable hardware
- Kernel lockdown prevents unsigned modules
- Reproducible builds enable supply chain verification
- SBOM enables vulnerability scanning
- Artifact signing enables trust verification

## Related

- ADR-003: Kernel Strategy
- ADR-004: Boot Strategy
- ADR-006: Versioning
