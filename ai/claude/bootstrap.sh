#!/usr/bin/env bash
# Install missing native Claude; explicit updates refresh the writable native copy.
set -euo pipefail
[[ -z "${DRY_RUN_CMD:-}" ]] || exit 0
export PATH="$HOME/.local/bin:$PATH"
action=${1:-install}
if [ "$action" = update ] && [ -x "$HOME/.local/bin/claude" ]; then
  env -u DISABLE_AUTOUPDATER "$HOME/.local/bin/claude" update
  exit
fi
if [ "$action" = install ] && command -v claude >/dev/null; then exit 0; fi
umask 077
installer=$(mktemp "${TMPDIR:-/tmp}/claude-bootstrap.XXXXXXXXXX")
trap 'rm -f -- "$installer"' EXIT
curl -fsSL https://claude.ai/install.sh -o "$installer"
bash "$installer"
