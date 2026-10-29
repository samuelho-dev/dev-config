#!/usr/bin/env bash
# Install only when absent; the native installer owns its launcher and updates.
set -euo pipefail
[[ -z "${DRY_RUN_CMD:-}" ]] || exit 0
export PATH="$PATH:$HOME/.local/bin"

command -v claude >/dev/null && exit 0

umask 077
installer=$(mktemp "${TMPDIR:-/tmp}/claude-bootstrap.XXXXXXXXXX")
trap 'rm -f -- "$installer"' EXIT
curl -fsSL https://claude.ai/install.sh -o "$installer"
"$BASH" "$installer"
