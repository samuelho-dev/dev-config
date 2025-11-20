#!/usr/bin/env bash
#
# Sync secrets from 1Password to local cache
# Pattern: Cache-first with session reuse (minimizes biometric prompts)
#
# This script caches your 1Password session and reuses it for 30 minutes,
# eliminating biometric prompts on every shell load.
#
# Usage:
#   ./scripts/sync-secrets.sh           # Sync all secrets (uses cached session)
#   ./scripts/sync-secrets.sh --force   # Force re-sync (ignore cache age)

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

# Configuration
SECRETS_DIR="$HOME/.config/dev-config/secrets"
TOKEN_FILE="$HOME/.config/dev-config/op-token"
CACHE_AGE_SECONDS=$((24 * 60 * 60))  # 24 hours (same as External Secrets refreshInterval)

# 1Password item UUIDs (from user's infrastructure)
AI_SECRETS_ITEM="xsuolbdwx4vmcp3zysjczfatam"
AI_SECRETS_VAULT="cv7j7tu2q76z43dhchuq6rljca"  # Dev vault

# Check if sync needed (skip if cache fresh unless --force)
if [ "${1:-}" != "--force" ] && [ -f "$SECRETS_DIR/.last-sync" ]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$SECRETS_DIR/.last-sync" 2>/dev/null || echo 0) ))
  if [ "$CACHE_AGE" -lt "$CACHE_AGE_SECONDS" ]; then
    log_info "Secrets cache is fresh (${CACHE_AGE}s old, refresh after ${CACHE_AGE_SECONDS}s)"
    log_info "Use --force to re-sync now"
    exit 0
  fi
fi

# Authenticate with 1Password service account (NO biometrics!)
if [ ! -f "$TOKEN_FILE" ]; then
  log_error "Service account token not found: $TOKEN_FILE"
  log_info "Service account token should be at: $TOKEN_FILE"
  exit 1
fi

# Export service account token (no session needed, no biometrics!)
export OP_SERVICE_ACCOUNT_TOKEN=$(cat "$TOKEN_FILE")

# Verify authentication works
if ! op account get >/dev/null 2>&1; then
  log_error "Failed to authenticate with 1Password service account"
  log_info "Token may be expired or invalid"
  exit 1
fi

log_success "Authenticated with service account (no biometrics!)"

log_info "Syncing secrets from 1Password (service account, zero biometrics)..."

# Create secrets directory
mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

# Sync AI credentials from item xsuolbdwx4vmcp3zysjczfatam
# Pattern: Same as ExternalSecret spec.data[].remoteRef

log_info "Fetching AI credentials from 1Password..."

# LITELLM_MASTER_KEY
if op item get "$AI_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=litellm-master-key --reveal >/dev/null 2>&1; then
  op item get "$AI_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=litellm-master-key --reveal > "$SECRETS_DIR/LITELLM_MASTER_KEY"
  log_success "✓ LITELLM_MASTER_KEY"
else
  log_warn "Field 'litellm-master-key' not found in AI secrets item"
fi

# ANTHROPIC_API_KEY
if op item get "$AI_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=anthropic-api-key --reveal >/dev/null 2>&1; then
  op item get "$AI_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=anthropic-api-key --reveal > "$SECRETS_DIR/ANTHROPIC_API_KEY"
  log_success "✓ ANTHROPIC_API_KEY"
else
  log_warn "Field 'anthropic-api-key' not found in AI secrets item"
fi

# OPENAI_API_KEY
if op item get "$AI_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=openai-api-key --reveal >/dev/null 2>&1; then
  op item get "$AI_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=openai-api-key --reveal > "$SECRETS_DIR/OPENAI_API_KEY"
  log_success "✓ OPENAI_API_KEY"
else
  log_warn "Field 'openai-api-key' not found in AI secrets item"
fi

# SSH Private Key (GitHub authentication)
SSH_SECRETS_ITEM="vtcsjphterploxdgzvsu3rm7le"
SSH_KEY_FILE="$HOME/.ssh/personal"
SSH_PASSPHRASE_FILE="$HOME/.config/dev-config/secrets/SSH_PASSPHRASE"

log_info "Fetching SSH key and passphrase from 1Password..."

# Fetch SSH private key
if op item get "$SSH_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=SSH-PRIVATE-KEY --reveal >/dev/null 2>&1; then
  op item get "$SSH_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=SSH-PRIVATE-KEY --reveal | sed 's/^"//; s/"$//' > "$SSH_KEY_FILE"
  chmod 600 "$SSH_KEY_FILE"
  log_success "✓ SSH key synced to $SSH_KEY_FILE"
else
  log_warn "SSH-PRIVATE-KEY not found in 1Password item $SSH_SECRETS_ITEM"
fi

# Fetch SSH passphrase (stored in password field)
if op item get "$SSH_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=password --reveal >/dev/null 2>&1; then
  op item get "$SSH_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=password --reveal > "$SSH_PASSPHRASE_FILE"
  chmod 600 "$SSH_PASSPHRASE_FILE"
  log_success "✓ SSH passphrase synced"
else
  log_warn "SSH passphrase (password field) not found in 1Password item $SSH_SECRETS_ITEM"
fi

# Add more secrets as needed:
# op item get "$AI_SECRETS_ITEM" --vault "$AI_SECRETS_VAULT" --fields label=YOUR_FIELD --reveal > "$SECRETS_DIR/YOUR_ENV_VAR"

# Secure permissions (read-only for user)
chmod 600 "$SECRETS_DIR"/* 2>/dev/null || true

# Mark sync timestamp (for cache freshness check)
touch "$SECRETS_DIR/.last-sync"

log_success "Secrets synced successfully!"
log_info "Cache will refresh after $(( CACHE_AGE_SECONDS / 3600 )) hours"
log_info "Force re-sync: $0 --force"
