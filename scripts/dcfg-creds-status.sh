#!/usr/bin/env bash
#
# dcfg-creds-status - Check AI credentials loading status
#
# Shows:
# - Last credential load time from LaunchAgent/systemd logs
# - Current environment variable status for each credential
# - Troubleshooting hints if credentials missing

set -euo pipefail

echo "=== AI Credentials Status ==="
echo ""

# Determine log file location (platform-specific)
if [[ "$OSTYPE" == "darwin"* ]]; then
  LOG_FILE="$HOME/Library/Logs/ai-env.log"
else
  # Linux - check systemd journal
  LOG_FILE="systemd"
fi

# Show last credential load
if [[ "$LOG_FILE" == "systemd" ]]; then
  echo "Last credential load (systemd journal):"
  if command -v journalctl &> /dev/null; then
    journalctl --user -u ai-env.service --no-pager -n 10 2>/dev/null || echo "⚠️  systemd journal not available"
  else
    echo "⚠️  journalctl not found"
  fi
elif [[ -f "$LOG_FILE" ]]; then
  echo "Last credential load:"
  tail -10 "$LOG_FILE"
else
  echo "⚠️  Log file not found: $LOG_FILE"
  echo "   LaunchAgent/systemd may not have run yet."
  echo ""
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   Try: launchctl start com.${USER}.ai-env"
  else
    echo "   Try: systemctl --user start ai-env.service"
  fi
fi

echo ""
echo "Credentials status:"

# Check each credential
check_cred() {
  local key="$1"
  local value="${!key:-}"
  if [[ -n "$value" ]]; then
    echo "✅ $key (length: ${#value} chars)"
  else
    echo "❌ $key (not set)"
  fi
}

check_cred "ANTHROPIC_API_KEY"
check_cred "OPENAI_API_KEY"
check_cred "LITELLM_MASTER_KEY"
check_cred "GOOGLE_AI_API_KEY"

echo ""

# Check if cache files exist
SECRETS_DIR="$HOME/.config/dev-config/secrets"
if [[ -d "$SECRETS_DIR" ]]; then
  echo "Secrets cache directory: ✅ exists"
  echo "Cache files:"
  for key in ANTHROPIC_API_KEY OPENAI_API_KEY LITELLM_MASTER_KEY GOOGLE_AI_API_KEY; do
    if [[ -f "$SECRETS_DIR/$key" ]]; then
      # Get file size (platform-specific)
      size=$(stat -f%z "$SECRETS_DIR/$key" 2>/dev/null || stat -c%s "$SECRETS_DIR/$key" 2>/dev/null)
      echo "  ✅ $key ($size bytes)"
    else
      echo "  ❌ $key (missing)"
    fi
  done
else
  echo "Secrets cache directory: ❌ not found"
  echo "  Expected: $SECRETS_DIR"
  echo "  Run: ~/Projects/dev-config/scripts/sync-secrets.sh"
fi

echo ""
echo "Troubleshooting:"
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "  - Check LaunchAgent status: launchctl list | grep ai-env"
  echo "  - Restart LaunchAgent: launchctl stop com.${USER}.ai-env && launchctl start com.${USER}.ai-env"
  echo "  - View logs: tail -f $LOG_FILE"
else
  echo "  - Check systemd status: systemctl --user status ai-env.service"
  echo "  - Restart service: systemctl --user restart ai-env.service"
  echo "  - View logs: journalctl --user -u ai-env.service -f"
fi
