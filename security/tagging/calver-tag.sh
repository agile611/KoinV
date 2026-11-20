#!/bin/bash
# KoinV CalVer Tagging Automation
# Automates CalVer tagging for daily builds and monthly releases

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Function to create daily tag
create_daily_tag() {
    local version=$(date -u +"%y.%m.%d")
    log_info "Creating daily tag: $version"
    
    if git tag -l | grep -q "^${version}$"; then
        log_warn "Tag $version already exists"
        return 0
    fi
    
    git tag -a "${version}" -m "KoinV ${version}"
    git push origin "${version}"
    log_info "Created and pushed daily tag: ${version}"
}

# Function to create monthly release tag
create_monthly_tag() {
    local version=$(date -u +"%y.%m")
    log_info "Creating monthly release tag: $version"
    
    if git tag -l | grep -q "^${version}$"; then
        log_warn "Tag $version already exists"
        return 0
    fi
    
    git tag -a "${version}" -m "KoinV ${version} Release"
    git push origin "${version}"
    log_info "Created and pushed monthly release tag: ${version}"
}

# Function to create patch tag
create_patch_tag() {
    local base_version="${1:-}"
    local patch_num="${2:-1}"
    
    if [[ -z "$base_version" ]]; then
        log_error "Base version required for patch tag"
        exit 1
    fi
    
    local version="${base_version}.p${patch_num}"
    log_info "Creating patch tag: $version"
    
    if git tag -l | grep -q "^${version}$"; then
        log_warn "Tag $version already exists"
        return 0
    fi
    
    git tag -a "${version}" -m "KoinV ${version} Hotfix"
    git push origin "${version}"
    log_info "Created and pushed patch tag: ${version}"
}

# Function to verify CalVer compliance
verify_calver_tags() {
    log_info "Verifying CalVer tag compliance..."
    
    # Check for SemVer tags
    if git tag -l | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "ERROR: SemVer tags found (prohibited):"
        git tag -l | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$'
        return 1
    fi
    
    # Check for CalVer daily tags
    if ! git tag -l | grep -qE '^[0-9]{2}\.[0-9]{2}\.[0-9]{2}$'; then
        echo "WARNING: No CalVer daily tags found"
    fi
    
    # Check for CalVer monthly tags
    if ! git tag -l | grep -qE '^[0-9]{2}\.[0-9]{2}$'; then
        log_warn "No CalVer monthly tags found"
    fi
    
    log_info "CalVer tag compliance check complete"
    return 0
}

# Main
case "${1:-}" in
    daily)
        create_daily_tag
        ;;
    monthly)
        create_monthly_tag
        ;;
    patch)
        create_patch_tag "${2:-}" "${3:-1}"
        ;;
    verify)
        verify_calver_tags
        ;;
    *)
        echo "Usage: $0 {daily|monthly|patch|verify} [args]"
        echo "  daily                    - Create daily tag (YY.MM.DD)"
        echo "  monthly                  - Create monthly release tag (YY.MM)"
        echo "  patch <base> [num]       - Create patch tag (YY.MM.pN)"
        echo "  verify                   - Verify CalVer compliance"
        exit 1
        ;;
esac
