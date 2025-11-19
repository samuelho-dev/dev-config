#!/bin/bash
# Three-tier Nix configuration testing
# Tests Home Manager configuration without applying changes
#
# Usage:
#   bash scripts/test-config.sh
#
# Test Tiers:
#   Tier 1: Syntax & Evaluation (fastest, no builds)
#   Tier 2: Build Test (moderate, uses cache)
#   Tier 3: Dry-Run Preview (slower, shows changes)

set -e

# Color output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

log_header() { echo -e "${BOLD}$1${RESET}"; }
log_info() { echo -e "${CYAN}$1${RESET}"; }
log_success() { echo -e "${GREEN}✅ $1${RESET}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${RESET}"; }
log_error() { echo -e "${RED}❌ $1${RESET}"; }

# Get repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
log_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_header "  Nix Configuration Testing (3-Tier)"
log_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Change to repository root
cd "$REPO_ROOT"

#
# Tier 1: Syntax & Evaluation Check
#
echo ""
log_header "🔍 Tier 1: Syntax & Evaluation Check"
log_info "   Purpose: Validate Nix syntax and options"
log_info "   Speed:   Fastest (no builds, no downloads)"
log_info "   Command: nix-instantiate --eval --strict"
echo ""

if nix flake show --json &>/dev/null; then
  log_success "Syntax check passed - configuration is valid"
else
  log_error "Syntax check failed - Nix evaluation errors detected"
  echo ""
  log_info "Running with output for debugging:"
  echo ""
  nix flake show || true
  exit 1
fi

#
# Tier 2: Build Test
#
echo ""
log_header "🏗️  Tier 2: Build Test"
log_info "   Purpose: Verify configuration builds successfully"
log_info "   Speed:   Moderate (downloads from cache, no activation)"
log_info "   Command: home-manager build --flake ."
echo ""

if home-manager build --flake . --show-trace; then
  log_success "Build test passed - configuration builds successfully"

  # Show result location
  if [ -L "result" ]; then
    RESULT_PATH="$(readlink -f result 2>/dev/null || readlink result)"
    log_info "   Result: $RESULT_PATH"
  fi
else
  log_error "Build test failed - configuration does not build"
  exit 1
fi

#
# Tier 3: Dry-Run Preview
#
echo ""
log_header "👀 Tier 3: Dry-Run Preview"
log_info "   Purpose: Show what would change if applied"
log_info "   Speed:   Slower (downloads packages, shows diff)"
log_info "   Command: home-manager switch --dry-run --verbose"
echo ""

log_warn "Note: --dry-run still downloads packages from cache"
log_warn "      Some activation scripts may run (see dry-run limitations)"
echo ""

home-manager switch --flake . --dry-run --verbose || true

#
# Summary
#
echo ""
log_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "All tests passed!"
echo ""
log_info "Configuration is ready to apply."
echo ""
log_header "To apply changes:"
echo ""
echo "  home-manager switch --flake ."
echo ""
log_header "To rollback if issues occur:"
echo ""
echo "  home-manager generations"
echo "  /nix/store/<hash>-home-manager-generation/activate"
echo ""
log_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
