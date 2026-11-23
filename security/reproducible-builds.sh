#!/bin/bash
# Agile611 Koinos RISC-V Reproducible Builds Configuration
# Ensures bit-for-bit reproducible builds

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

log_info "=== Agile611 Koinos RISC-V Reproducible Builds Setup ==="
echo ""

# Configuration
BUILD_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/build"
REPRO_DIR="/Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible"

mkdir -p "$REPRO_DIR"

# Step 1: Set environment variables for reproducibility
log_info "Setting reproducible build environment variables..."

cat > /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible-env.sh << 'REPROENVEOF'
#!/bin/bash
# Agile611 Koinos RISC-V Reproducible Build Environment
# Source this file before building for reproducible builds

# Set fixed timestamps
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date -u -d '2026-11-20 00:00:00' +%s)}"
export BUILD_DATE="${BUILD_DATE:-2026-11-20}"
export BUILD_TIME="00:00:00"

# Force deterministic builds
export DEB_BUILD_OPTIONS="reproducible=+all"
export DEB_BUILD_MAINT_OPTIONS="reproducible=+all"

# Force deterministic compiler output
export GCC_COLORS="never"
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export TZ=UTC

# Strip timestamps from binaries
export STRIP_TIMESTAMPS=1

# Force deterministic archive creation
export TAR_OPTIONS="--sort=name --mtime=@${SOURCE_DATE_EPOCH} --owner=0 --group=0 --numeric-owner"
export GZIP_OPTIONS="-n"

# Python reproducibility
export PYTHONHASHSEED=0
export PYTHONDONTWRITEBYTECODE=1

# Rust reproducibility (if applicable)
export RUSTFLAGS="-C debuginfo=0 -C strip=symbols"

# Go reproducibility (if applicable)
export GOFLAGS="-trimpath"

# CMake reproducibility
export CMAKE_BUILD_TYPE=Release
export CMAKE_C_FLAGS="-fdebug-prefix-map=${PWD}=."
export CMAKE_CXX_FLAGS="-fdebug-prefix-map=${PWD}=."

# Meson reproducibility
export MESON_FORCE_REPRODUCIBLE=1

# Cargo reproducibility
export CARGO_PROFILE_RELEASE_STRIP=symbols
export CARGO_PROFILE_RELEASE_DEBUG=false

echo "Reproducible build environment configured"
echo "SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH"
REPROENVEOF

chmod +x /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible-env.sh

# Step 2: Create diffoscope comparison script
log_info "Creating diffoscope comparison script..."
cat > /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible/diffoscope-compare.sh << 'DIFFEOF'
#!/bin/bash
# Agile611 Koinos RISC-V Diffoscope Comparison Script
# Compares two builds for reproducibility

set -euo pipefail

BUILD1="${1:-}"
BUILD2="${2:-}"

if [[ -z "$BUILD1" || -z "$BUILD2" ]]; then
    echo "Usage: $0 <build1_dir> <build2_dir>"
    exit 1
fi

if [[ ! -d "$BUILD1" || ! -d "$BUILD2" ]]; then
    echo "ERROR: Both build directories must exist"
    exit 1
fi

echo "=== Agile611 Koinos RISC-V Reproducibility Check ==="
echo "Comparing: $BUILD1 vs $BUILD2"
echo ""

# Install diffoscope if not present
if ! command -v diffoscope &> /dev/null; then
    echo "Installing diffoscope..."
    sudo apt-get update && sudo apt-get install -y diffoscope
fi

# Run diffoscope
echo "Running diffoscope comparison..."
diffoscope --max-diff-block-lines=100 --max-diff-input-lines=100 \
    --text "$BUILD1" "$BUILD2" 2>&1 | tee /tmp/diffoscope-report.txt

# Check result
if grep -q "No differences found" /tmp/diffoscope-report.txt; then
    echo ""
    echo "=== RESULT: BUILDS ARE REPRODUCIBLE ==="
    exit 0
else
    echo ""
    echo "=== RESULT: BUILDS DIFFER ==="
    echo "See /tmp/diffoscope-report.txt for details"
    exit 1
fi
DIFFEOF
chmod +x /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible/diffoscope-compare.sh

# Step 3: Create reproducible build verification script
log_info "Creating reproducible build verification script..."
cat > /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible/verify-reproducible.sh << 'VERIFYEOF'
#!/bin/bash
# Agile611 Koinos RISC-V Reproducible Build Verification
# Runs two builds and compares them for reproducibility

set -euo pipefail

PROJECT_ROOT="/Users/guillem/code/Agile611 Koinos RISC-V"
BUILD_DIR="/tmp/koinos-repro-test"

log_info() { echo -e "\033[0;32m[INFO]\033[0m $*"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $*"; }

echo "=== Agile611 Koinos RISC-V Reproducibility Verification ==="
echo ""

# Clean and create build directories
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/build1" "$BUILD_DIR/build2"

cd /Users/guillem/code/Agile611 Koinos RISC-V

# Source reproducible environment
source /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible-env.sh

# Build 1
log_info "Starting Build 1..."
SOURCE_DATE_EPOCH=1795161600 BUILD_DIR="/tmp/koinos-repro-test/build1" ./images/build-image.sh 2>&1 | tee /tmp/build1.log

# Build 2
log_info "Starting Build 2..."
SOURCE_DATE_EPOCH=1795161600 BUILD_DIR="/tmp/koinos-repro-test/build2" ./images/build-image.sh 2>&1 | tee /tmp/build2.log

# Compare outputs
log_info "Comparing build outputs..."
if diffoscope --max-diff-block-lines=100 --max-diff-input-lines=100 \
    /tmp/koinos-repro-test/build1/output /tmp/koinos-repro-test/build2/output 2>&1 | tee /tmp/diffoscope-report.txt; then
    if grep -q "No differences found" /tmp/diffoscope-report.txt; then
        echo ""
        echo "=== SUCCESS: Builds are reproducible ==="
        exit 0
    else
        log_error "Builds are NOT reproducible"
        exit 1
    fi
else
    log_error "Diffoscope failed"
    exit 1
fi
VERIFYEOF
chmod +x /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible/verify-reproducible.sh

log_info "Reproducible builds setup complete"
echo ""
echo "Generated files:"
echo "  Environment: /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible-env.sh"
echo "  Diffoscope compare: /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible/diffoscope-compare.sh"
echo "  Verify script: /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible/verify-reproducible.sh"
echo ""
echo "Usage:"
echo "  source /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible-env.sh"
echo "  ./images/build-image.sh"
echo "  /Users/guillem/code/Agile611 Koinos RISC-V/security/reproducible/verify-reproducible.sh"
