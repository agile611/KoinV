#!/bin/bash
# KoinV Constitution Compliance CI Gate
# Validates all constitution requirements are met

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

ERRORS=0
WARNINGS=0

# Function to check condition
check() {
    local description="$1"
    local condition="$2"
    local severity="${3:-error}"
    
    if eval "$condition"; then
        log_info "✓ $description"
        return 0
    else
        if [[ "$severity" == "error" ]]; then
            log_error "✗ $description"
            ((ERRORS++))
        else
            log_warn "⚠ $description"
            ((WARNINGS++))
        fi
        return 1
    fi
}

log_info "=== KoinV Constitution Compliance Check ==="
echo ""

# 1. Check CalVer versioning
log_info "Checking CalVer versioning..."
check "No SemVer tags (vX.Y.Z)" "! git tag -l | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'"
check "CalVer daily tags exist (YY.MM.DD)" "git tag -l | grep -qE '^[0-9]{2}\.[0-9]{2}\.[0-9]{2}$'" warning
check "CalVer monthly tags exist (YY.MM)" "git tag -l | grep -qE '^[0-9]{2}\.[0-9]{2}$'" warning

# 2. Check SemVer prohibition in documentation
log_info "Checking SemVer prohibition in documentation..."
if grep -rE 'v[0-9]+\.[0-9]+\.[0-9]+' --include="*.md" --include="*.txt" . \
    | grep -v ".git" \
    | grep -v "SemVer PROHIBITED" \
    | grep -v "SemVer.*forbidden" \
    | grep -v "SemVer.*prohibited" \
    | grep -v "RISCVDistroArchitect.md" \
    | grep -v "analyze.md" \
    | grep -v "v1\.0\.0.*None" \
    | grep -v "v1\.0\.0.*0" \
    | grep -v "v2\.0\.0.*None" \
    | grep -v "v1\.0\.0.*0" > /dev/null; then
    log_error "SemVer references found in documentation"
    ((ERRORS++))
else
    log_info "✓ No SemVer references in documentation"
fi

# 3. Check kernel config for mandatory errata
log_info "Checking kernel config for mandatory errata..."
if [[ -f "/Users/guillem/code/KoinV/kernel/config.trixie" ]]; then
    check "CONFIG_ERRATA_THEAD" "grep -q 'CONFIG_ERRATA_THEAD=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_ERRATA_SIFIVE" "grep -q 'CONFIG_ERRATA_SIFIVE=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_ERRATA_ANDES_CMO" "grep -q 'CONFIG_ERRATA_ANDES_CMO=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_NO5LVL" "grep -q 'CONFIG_NO5LVL=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_NO4LVL" "grep -q 'CONFIG_NO4LVL=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_MODULE_SIG" "grep -q 'CONFIG_MODULE_SIG=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_HARDENED_USERCOPY" "grep -q 'CONFIG_HARDENED_USERCOPY=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_FORTIFY_SOURCE=3" "grep -q 'CONFIG_FORTIFY_SOURCE=3' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_STACKPROTECTOR_STRONG" "grep -q 'CONFIG_STACKPROTECTOR_STRONG=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_PAGE_TABLE_ISOLATION" "grep -q 'CONFIG_PAGE_TABLE_ISOLATION=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_STRICT_DEVMEM" "grep -q 'CONFIG_STRICT_DEVMEM=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_STRICT_KERNEL_RWX" "grep -q 'CONFIG_STRICT_KERNEL_RWX=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_DEBUG_RODATA" "grep -q 'CONFIG_DEBUG_RODATA=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_MODULE_SIG" "grep -q 'CONFIG_MODULE_SIG=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_ACPI" "grep -q 'CONFIG_ACPI=y' /Users/guillem/code/KoinV/kernel/config.trixie"
    check "CONFIG_EFI_STUB" "grep -q 'CONFIG_EFI_STUB=y' /Users/guillem/code/KoinV/kernel/config.trixie"
else
    log_warn "Kernel config not found at /Users/guillem/code/KoinV/kernel/config.trixie"
fi

# 4. Check for required files
log_info "Checking required files..."
check "constitution.md exists" "[[ -f /Users/guillem/code/KoinV/constitution.md ]]"
check "spec.md exists" "[[ -f /Users/guillem/code/KoinV/spec.md ]]"
check "clarifications.md exists" "[[ -f /Users/guillem/code/KoinV/clarifications.md ]]"
check "plan.md exists" "[[ -f /Users/guillem/code/KoinV/plan.md ]]"
check "checklist.md exists" "[[ -f /Users/guillem/code/KoinV/checklist.md ]]"
check "tasks.md exists" "[[ -f /Users/guillem/code/KoinV/tasks.md ]]"
check "analyze.md exists" "[[ -f /Users/guillem/code/KoinV/analyze.md ]]"
check "LICENSE.md exists" "[[ -f /Users/guillem/code/KoinV/LICENSE.md ]]"
check "README.md exists" "[[ -f /Users/guillem/code/KoinV/README.md ]]"
check "SPECKIT_PROCESS.md exists" "[[ -f /Users/guillem/code/KoinV/SPECKIT_PROCESS.md ]]"

# 5. Check directory structure
log_info "Checking directory structure..."
check "profiles/ directory" "[[ -d /Users/guillem/code/KoinV/profiles ]]"
check "overlays/ directory" "[[ -d /Users/guillem/code/KoinV/overlays ]]"
check "packages/ directory" "[[ -d /Users/guillem/code/KoinV/packages ]]"
check "kernel/ directory" "[[ -d /Users/guillem/code/KoinV/kernel ]]"
check "images/ directory" "[[ -d /Users/guillem/code/KoinV/images ]]"
check "bsp/ directory" "[[ -d /Users/guillem/code/KoinV/bsp ]]"
check "docs/ directory" "[[ -d /Users/guillem/code/KoinV/docs ]]"
check "tests/ directory" "[[ -d /Users/guillem/code/KoinV/tests ]]"
check "security/ directory" "[[ -d /Users/guillem/code/KoinV/security ]]"
check "firmware/ directory" "[[ -d /Users/guillem/code/KoinV/firmware ]]"

# 6. Check kernel config for CalVer LOCALVERSION
log_info "Checking CalVer in kernel config..."
if [[ -f "/Users/guillem/code/KoinV/kernel/config.trixie" ]]; then
    check "CONFIG_LOCALVERSION has CalVer format" "grep -q 'CONFIG_LOCALVERSION=\"-koinv-[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}\"' /Users/guillem/code/KoinV/kernel/config.trixie"
fi

# Summary
echo ""
echo "=== Compliance Summary ==="
if [[ $ERRORS -eq 0 ]]; then
    log_info "All compliance checks PASSED"
    exit 0
else
    log_error "$ERRORS error(s), $WARNINGS warning(s)"
    exit 1
fi
