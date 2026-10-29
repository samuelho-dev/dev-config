#!/usr/bin/env bash
# Install only when absent; leave CLI and package upgrades to the user.
set -euo pipefail
[[ -z "${DRY_RUN_CMD:-}" ]] || exit 0
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
export PATH="$PATH:$HOME/.local/bin"

if ! command -v pi >/dev/null; then
  command -v npm >/dev/null || { echo 'pi-bootstrap: npm is required' >&2; exit 1; }
  npm install --global --prefix "$HOME/.local" @earendil-works/pi-coding-agent
fi

bash "$SCRIPT_DIR/apply-plugins.sh"
