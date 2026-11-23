#!/bin/bash
# Agile611 Koinos RISC-V Secure Boot Setup Script
# Sets up shim + MOK (Machine Owner Key) for UEFI Secure Boot

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
KEY_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/security/keys"
MOK_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/mok"
SHIM_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/shim"
SB_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot"

log_info "=== Agile611 Koinos RISC-V Secure Boot Setup ==="
echo ""

# Create directories
mkdir -p "$KEY_DIR" "$MOK_DIR" "$SHIM_DIR" "$SB_DIR"

# Step 1: Generate MOK keys
log_info "Step 1: Generating MOK keys..."
if [[ ! -f "$KEY_DIR/MOK.key" ]]; then
    openssl req -new -x509 -newkey rsa:4096 -subj "/CN=Agile611 Koinos RISC-V MOK/" \
        -keyout "$KEY_DIR/MOK.key" -out "$KEY_DIR/MOK.crt" \
        -days 3650 -nodes -sha256 2>/dev/null
    log_info "Generated MOK.key and MOK.crt"
else
    log_info "MOK keys already exist"
fi

# Step 2: Generate kernel signing key
log_info "Step 2: Generating kernel signing key..."
if [[ ! -f "$KEY_DIR/kernel_signing_key.pem" ]]; then
    openssl req -new -x509 -newkey rsa:4096 -subj "/CN=Agile611 Koinos RISC-V Kernel Signing Key/" \
        -keyout "$KEY_DIR/kernel_signing_key.pem" -out "$KEY_DIR/kernel_signing_key.crt" \
        -days 3650 -nodes -sha256 2>/dev/null
    log_info "Generated kernel_signing_key.pem and .crt"
else
    log_info "Kernel signing key already exists"
fi

# Step 3: Convert to DER format for MOK enrollment
log_info "Step 3: Converting certificates to DER format..."
openssl x509 -in "$KEY_DIR/MOK.crt" -outform der -out "$MOK_DIR/MOK.der" 2>/dev/null
openssl x509 -in "$KEY_DIR/kernel_signing_key.crt" -outform der -out "$MOK_DIR/kernel_signing_key.der" 2>/dev/null
log_info "Converted certificates to DER format"

# Step 4: Download shim
log_info "Step 4: Downloading shim for RISC-V..."
SHIM_URL="https://github.com/rhboot/shim/releases/download/15.8/shim-15.8.tar.gz"
if [[ ! -f "$SHIM_DIR/shimriscv64.efi" ]]; then
    cd /tmp
    wget -q "$SHIM_URL" -O shim.tar.gz
    tar -xzf shim.tar.gz
    # Find the RISC-V shim binary
    find . -name "shimriscv64.efi" -exec cp {} "$SHIM_DIR/" \;
    find . -name "shimriscv64.efi.signed" -exec cp {} "$SHIM_DIR/" \;
    find . -name "mmriscv64.efi" -exec cp {} "$SHIM_DIR/" \;
    find . -name "fbx64.efi" -exec cp {} "$SHIM_DIR/" \;
    log_info "Downloaded shim binaries"
else
    log_info "Shim binaries already exist"
fi

# Step 5: Create MOK enrollment script
log_info "Step 5: Creating MOK enrollment script..."
cat > /Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/enroll-mok.sh << 'MOKSCRIPTEOF'
#!/bin/bash
# Agile611 Koinos RISC-V MOK Enrollment Script
# Run this on target hardware to enroll MOK keys

set -euo pipefail

MOK_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/mok"

echo "=== Agile611 Koinos RISC-V MOK Enrollment ==="
echo ""
echo "This script will enroll the Agile611 Koinos RISC-V MOK and kernel signing keys"
echo "into the UEFI Secure Boot database."
echo ""
echo "Prerequisites:"
echo "  - System must be booted in UEFI mode with Secure Boot enabled"
echo "  - You must have UEFI Shell access or mokutil installed"
echo ""

# Check if mokutil is available
if ! command -v mokutil &> /dev/null; then
    echo "ERROR: mokutil not found. Install it first:"
    echo "  apt-get install mokutil"
    exit 1
fi

# Check if Secure Boot is enabled
if ! mokutil --sb-state 2>/dev/null | grep -q "enabled"; then
    echo "WARNING: Secure Boot is not enabled"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Enroll MOK
echo "Enrolling Agile611 Koinos RISC-V MOK..."
if [[ -f "/Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/mok/MOK.der" ]]; then
    mokutil --import /Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/mok/MOK.der
    echo "MOK enrolled. Reboot to complete enrollment."
else
    echo "ERROR: MOK.der not found"
    exit 1
fi

# Enroll kernel signing key
echo "Enrolling kernel signing key..."
if [[ -f "/Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/mok/kernel_signing_key.der" ]]; then
    mokutil --import /Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/mok/kernel_signing_key.der
    echo "Kernel signing key enrolled. Reboot to complete enrollment."
else
    echo "ERROR: kernel_signing_key.der not found"
    exit 1
fi

echo ""
echo "MOK enrollment initiated. Reboot the system to complete the process."
echo "During reboot, you will be prompted to confirm the enrollment."
echo "Select 'Enroll MOK' -> 'Continue' -> 'Yes' -> Enter password"
MOKSCRIPTEOF
chmod +x /Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/enroll-mok.sh

# Step 6: Create kernel signing script
log_info "Step 6: Creating kernel signing script..."
cat > /Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/sign-kernel.sh << 'SIGNSCRIPTEOF'
#!/bin/bash
# Agile611 Koinos RISC-V Kernel Signing Script
# Signs kernel image and modules for Secure Boot

set -euo pipefail

KERNEL_IMAGE="${1:-}"
KEY_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/security/keys"

if [[ -z "$KERNEL_IMAGE" ]]; then
    echo "Usage: $0 <kernel_image>"
    exit 1
fi

if [[ ! -f "$KERNEL_IMAGE" ]]; then
    echo "ERROR: Kernel image not found: $KERNEL_IMAGE"
    exit 1
fi

if [[ ! -f "/Users/guillem/code/Agile611 Koinos RISC-V/security/keys/kernel_signing_key.pem" ]]; then
    echo "ERROR: Signing key not found. Run setup-secureboot.sh first."
    exit 1
fi

echo "Signing kernel: $KERNEL_IMAGE"
sbsign --key /Users/guillem/code/Agile611 Koinos RISC-V/security/keys/kernel_signing_key.pem \
       --cert /Users/guillem/code/Agile611 Koinos RISC-V/security/keys/kernel_signing_key.crt \
       --output "$KERNEL_IMAGE.signed" "$KERNEL_IMAGE"

echo "Signed kernel: $KERNEL_IMAGE.signed"
SIGNSCRIPTEOF
chmod +x /Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/sign-kernel.sh

# Step 7: Create module signing script
log_info "Step 7: Creating module signing script..."
cat > /Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/sign-modules.sh << 'MODSIGNSCRIPTEOF'
#!/bin/bash
# Agile611 Koinos RISC-V Module Signing Script
# Signs kernel modules for Secure Boot

set -euo pipefail

MODULE_DIR="${1:-/lib/modules/$(uname -r)}"
KEY_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/security/keys"

if [[ ! -d "$MODULE_DIR" ]]; then
    echo "ERROR: Module directory not found: $MODULE_DIR"
    exit 1
fi

if [[ ! -f "/Users/guillem/code/Agile611 Koinos RISC-V/security/keys/kernel_signing_key.pem" ]]; then
    echo "ERROR: Signing key not found. Run setup-secureboot.sh first."
    exit 1
fi

echo "Signing modules in: $MODULE_DIR"
find "$MODULE_DIR" -name "*.ko" | while read -r module; do
    echo "Signing: $module"
    /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha512 \
        /Users/guillem/code/Agile611 Koinos RISC-V/security/keys/kernel_signing_key.pem \
        /Users/guillem/code/Agile611 Koinos RISC-V/security/keys/kernel_signing_key.crt \
        "$module"
done

echo "All modules signed"
MODSIGNSCRIPTEOF
chmod +x /Users/guillem/code/Agile611 Koinos RISC-V/security/secureboot/sign-modules.sh

log_info "=== Secure Boot Setup Complete ==="
echo ""
echo "Generated files:"
echo "  Keys: $KEY_DIR/"
echo "  MOK: $MOK_DIR/"
echo "  Shim: $SHIM_DIR/"
echo ""
echo "Next steps:"
echo "1. Run enroll-mok.sh on target hardware to enroll MOK keys"
echo "2. Use sign-kernel.sh to sign kernel images"
echo "3. Use sign-modules.sh to sign kernel modules"
echo "4. Configure kernel with CONFIG_MODULE_SIG=y and signing key"
echo "4. Build kernel with CONFIG_MODULE_SIG_KEY pointing to kernel_signing_key.pem"
