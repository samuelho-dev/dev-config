#!/usr/bin/env bash
# Install missing plugins from the canonical list; never removes or re-enables user choices.
set -euo pipefail
[[ -z "${DRY_RUN_CMD:-}" ]] || exit 0
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PLUGINS_FILE="${CLAUDE_PLUGINS_FILE:-$SCRIPT_DIR/plugins.txt}"
command -v claude >/dev/null || { echo 'claude-plugins: claude not found; skipping' >&2; exit 0; }
marketplaces=$(claude plugin marketplace list)
installed=$(claude plugin list)
while read -r plugin repo || [ -n "$plugin" ]; do
  case "$plugin" in ''|'#'*) continue ;; esac
  marketplace=${plugin#*@}
  if ! grep -qx "  ❯ $marketplace" <<< "$marketplaces"; then
    echo "claude-plugins: adding marketplace $repo"
    claude plugin marketplace add "$repo" >/dev/null
    marketplaces+=$'\n'"  ❯ $marketplace"
  fi
  grep -qx "  ❯ $plugin" <<< "$installed" && continue
  echo "claude-plugins: installing $plugin"
  claude plugin install "$plugin" >/dev/null
done < "$PLUGINS_FILE"
