#!/usr/bin/env bash
# Install a missing Pi CLI or update it only on explicit request.
set -euo pipefail
[[ -z "${DRY_RUN_CMD:-}" ]] || exit 0
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
export PATH="$PATH:$HOME/.local/bin"
action=${1:-install}
if [ "$action" = update ] || ! command -v pi >/dev/null; then
  command -v npm >/dev/null || { echo 'pi-bootstrap: npm is required' >&2; exit 1; }
  npm install --global --prefix "$HOME/.local" @earendil-works/pi-coding-agent@latest
fi
bash "$SCRIPT_DIR/apply-plugins.sh"
