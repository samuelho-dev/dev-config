#!/bin/bash
# Load AI credentials in DevPod/container environments
# Supports both biometric (local) and service account (remote)
#
# Usage:
#   source .devcontainer/load-ai-credentials.sh
#
# Environment variables:
#   OP_SERVICE_ACCOUNT_TOKEN - 1Password service account token (for remote/container environments)
#
# How it works:
#   1. If OP_SERVICE_ACCOUNT_TOKEN is set, use service account authentication
#   2. Otherwise, try interactive authentication (biometric, requires 1Password app)
#   3. Fall back gracefully if authentication fails

if [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
  echo "🔐 Using 1Password service account for AI credentials"
  export OP_SERVICE_ACCOUNT_TOKEN
else
  echo "💡 No OP_SERVICE_ACCOUNT_TOKEN set, trying interactive authentication"

  # Check if 1Password CLI is available
  if ! command -v op &>/dev/null; then
    echo "⚠️  1Password CLI not found, skipping credential loading"
    return 0
  fi

  # Try interactive authentication (requires 1Password app + biometric)
  if ! op account get &>/dev/null 2>&1; then
    echo "⚠️  Not authenticated to 1Password"
    echo "   For remote environments, set OP_SERVICE_ACCOUNT_TOKEN environment variable"
    echo "   For local development, run: op signin"
    return 0
  fi

  echo "✅ Using 1Password interactive authentication"
fi

# Source the main credentials loading script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../scripts/load-ai-credentials.sh" ]; then
  source "$SCRIPT_DIR/../scripts/load-ai-credentials.sh"
else
  echo "⚠️  Main credentials script not found at: $SCRIPT_DIR/../scripts/load-ai-credentials.sh"
  return 1
fi
