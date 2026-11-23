#!/bin/bash
# Agile611 Koinos RISC-V Artifact Signing Script
# Signs release artifacts with cosign and GPG

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Configuration
ARTIFACTS_DIR="${1:-/Users/guillem/code/Agile611 Koinos RISC-V/build/output}"
KEY_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/security/keys"
SIG_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/build/signatures"

mkdir -p "$SIG_DIR"

log_info "=== Agile611 Koinos RISC-V Artifact Signing ==="
echo "Artifacts dir: $ARTIFACTS_DIR"
echo "Signatures dir: $SIG_DIR"
echo ""

# Check for cosign
if ! command -v cosign &> /dev/null; then
    log_info "Installing cosign..."
    curl -sSfL https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 -o /usr/local/bin/cosign
    chmod +x /usr/local/bin/cosign
fi

# Check for GPG
if ! command -v gpg &> /dev/null; then
    log_error "GPG not installed. Install with: apt-get install gnupg"
    exit 1
fi

# Check for GPG signing key
if ! gpg --list-secret-keys | grep -q "Agile611 Koinos RISC-V"; then
    log_warn "No Agile611 Koinos RISC-V GPG key found. Generate one with:"
    echo "  gpg --full-generate-key"
    echo "  gpg --armor --export <key-id> > /Users/guillem/code/Agile611 Koinos RISC-V/security/keys/koinos-public.key"
    echo "  gpg --armor --export-secret-keys <key-id> > /Users/guillem/code/Agile611 Koinos RISC-V/security/keys/koinos-private.key"
fi

# Find artifacts
ARTIFACTS=()
for file in "$ARTIFACTS_DIR"/*.img.xz "$ARTIFACTS_DIR"/*.iso.xz "$ARTIFACTS_DIR"/*.spdx.json; do
    if [[ -f "$file" ]]; then
        ARTIFACTS+=("$file")
    fi
done

if [[ ${#ARTIFACTS[@]} -eq 0 ]]; then
    log_error "No artifacts found in $ARTIFACTS_DIR"
    exit 1
fi

log_info "Found ${#ARTIFACTS[@]} artifacts to sign"

# Create signature directory
SIG_OUTPUT_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/build/signatures/$(date -u +%y.%m.%d)"
mkdir -p "$SIG_OUTPUT_DIR"

# Sign each artifact
for artifact in "${ARTIFACTS[@]}"; do
    BASENAME=$(basename "$artifact")
    log_info "Signing: $BASENAME"
    
    # Cosign sign (keyless or with key)
    if [[ -n "${COSIGN_PRIVATE_KEY:-}" ]]; then
        cosign sign-blob --private-key "$COSIGN_PRIVATE_KEY" \
            --output-signature "$SIG_DIR/${BASENAME}.sig" \
            "$artifact"
    else
        log_warn "COSIGN_PRIVATE_KEY not set, skipping cosign"
    fi
    
    # GPG sign
    if gpg --list-secret-keys | grep -q "Agile611 Koinos RISC-V"; then
        gpg --armor --detach-sign --output "$SIG_DIR/${BASENAME}.asc" "$artifact"
        log_info "GPG signed: ${BASENAME}.asc"
    else
        log_warn "No GPG key, skipping GPG signature"
    fi
    
    # SHA256 checksum
    sha256sum "$artifact" > "$SIG_DIR/${BASENAME}.sha256"
    log_info "SHA256: ${BASENAME}.sha256"
done

# Create checksums file
log_info "Creating checksums file..."
cd /Users/guillem/code/Agile611 Koinos RISC-V/build/output
sha256sum *.img.xz *.iso.xz *.spdx.json 2>/dev/null > "$SIG_DIR/checksums.sha256"
sha512sum *.img.xz *.iso.xz *.spdx.json 2>/dev/null > "$SIG_DIR/checksums.sha512"

# Create signature manifest
cat > "$SIG_DIR/manifest.txt" << MANIFESTEOF
Agile611 Koinos RISC-V Release Signatures
========================
Version: $(date -u +%y.%m.%d)
Date: $(date -u)
Signed by: Agile611 Koinos RISC-V Release Engineering

Artifacts:
MANIFESTEOF

for artifact in "${ARTIFACTS[@]}"; do
    BASENAME=$(basename "$artifact")
    echo "- $BASENAME" >> "$SIG_DIR/manifest.txt"
    echo "  SHA256: $(sha256sum "$artifact" | cut -d' ' -f1)" >> "$SIG_DIR/manifest.txt"
    if [[ -f "$SIG_DIR/${BASENAME}.asc" ]]; then
        echo "  GPG: ${BASENAME}.asc" >> "$SIG_DIR/manifest.txt"
    fi
    if [[ -f "$SIG_DIR/${BASENAME}.sig" ]]; then
        echo "  Cosign: ${BASENAME}.sig" >> "$SIG_DIR/manifest.txt"
    fi
done

log_info "Signing complete"
echo "Signatures: $SIG_OUTPUT_DIR"
ls -la "$SIG_DIR"
