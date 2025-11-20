#!/usr/bin/env bash
#
# test-renovate.sh - Test Renovate configuration locally
#
# Usage:
#   GITHUB_TOKEN=ghp_xxx bash scripts/test-renovate.sh
#   GITHUB_TOKEN=ghp_xxx bash scripts/test-renovate.sh --dry-run
#
# Prerequisites:
#   - Docker installed
#   - GitHub token with repo access
#   - Internet connection

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}" >&2; }
log_success() { echo -e "${GREEN}✅ $1${NC}" >&2; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}" >&2; }
log_error() { echo -e "${RED}❌ $1${NC}" >&2; }

# Check prerequisites
if ! command -v docker &>/dev/null; then
  log_error "Docker is required but not installed"
  exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  log_error "GITHUB_TOKEN environment variable is required"
  echo ""
  echo "Usage:"
  echo "  GITHUB_TOKEN=ghp_your_token bash scripts/test-renovate.sh"
  echo ""
  echo "Generate token at: https://github.com/settings/tokens/new"
  echo "Required scopes: repo, workflow"
  exit 1
fi

# Determine mode
DRY_RUN="${1:-}"
if [ "$DRY_RUN" = "--dry-run" ]; then
  log_info "Running in DRY-RUN mode (no PRs will be created)"
  DRY_RUN_FLAG="true"
else
  log_warn "Running in PRODUCTION mode (PRs will be created)"
  read -p "Continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Aborted"
    exit 0
  fi
  DRY_RUN_FLAG="false"
fi

# Get repository info
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_NAME="samuelho-dev/dev-config"

log_info "Testing Renovate configuration for $REPO_NAME"
echo ""

# Step 1: Validate renovate.json syntax
log_info "Step 1/3: Validating renovate.json syntax..."

if ! docker run --rm -v "$REPO_ROOT:/repo" renovate/renovate:latest \
  renovate-config-validator /repo/renovate.json; then
  log_error "renovate.json validation failed"
  exit 1
fi

log_success "renovate.json is valid"
echo ""

# Step 2: Test Renovate with dry-run
log_info "Step 2/3: Running Renovate bot..."

if docker run --rm \
  -e RENOVATE_TOKEN="$GITHUB_TOKEN" \
  -e RENOVATE_DRY_RUN="$DRY_RUN_FLAG" \
  -e LOG_LEVEL=debug \
  -v "$REPO_ROOT:/repo" \
  renovate/renovate:latest \
  renovate --platform=github "$REPO_NAME" 2>&1 | tee /tmp/renovate-test.log; then
  log_success "Renovate execution completed"
else
  log_error "Renovate execution failed"
  echo ""
  echo "Check logs at: /tmp/renovate-test.log"
  exit 1
fi

echo ""

# Step 3: Analyze results
log_info "Step 3/3: Analyzing results..."

# Count dependencies found
DEPS_FOUND=$(grep -c "Found.*dependencies" /tmp/renovate-test.log || echo "0")
log_info "Dependencies found: $DEPS_FOUND package files"

# Check for updates
if grep -q "Branch created" /tmp/renovate-test.log; then
  BRANCHES=$(grep -c "Branch created" /tmp/renovate-test.log)
  log_info "Branches that would be created: $BRANCHES"
  grep "Branch created" /tmp/renovate-test.log | sed 's/^/  - /'
elif grep -q "No changes required" /tmp/renovate-test.log; then
  log_success "Repository is up-to-date (no updates needed)"
else
  log_warn "No updates detected (check logs for details)"
fi

# Check for errors
if grep -q "ERROR:" /tmp/renovate-test.log; then
  log_error "Errors detected during execution:"
  grep "ERROR:" /tmp/renovate-test.log | sed 's/^/  - /'
  echo ""
  log_info "Full logs available at: /tmp/renovate-test.log"
  exit 1
fi

echo ""
log_success "Renovate test completed successfully"

if [ "$DRY_RUN_FLAG" = "true" ]; then
  echo ""
  log_info "DRY-RUN mode: No PRs were created"
  log_info "Remove --dry-run to create actual PRs"
else
  echo ""
  log_success "Production mode: PRs have been created"
  log_info "View PRs: https://github.com/$REPO_NAME/pulls"
fi

echo ""
echo "Next steps:"
echo "  1. Review dependency updates in GitHub"
echo "  2. Test updates locally: git fetch && git checkout renovate/..."
echo "  3. Merge via GitHub UI after CI passes"
