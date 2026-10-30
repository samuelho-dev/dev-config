#!/usr/bin/env bash
# Shared bootstrap for Home Manager and container images; do not install Bun shims.
set -euo pipefail
action=${1:-install}
if [ "$action" = update ] && [ -x "$HOME/.local/bin/omp" ]; then
  "$HOME/.local/bin/omp" update
  exit
fi
if [ -e "$HOME/.local/bin/omp" ] || [ -L "$HOME/.local/bin/omp" ]; then
  if [ -x "$HOME/.local/bin/omp" ]; then exit 0; fi
  echo 'omp launcher exists but cannot execute; refusing to overwrite' >&2
  exit 1
fi
umask 077
installer=$(mktemp "${TMPDIR:-/tmp}/omp-bootstrap.XXXXXXXXXX")
trap 'rm -f -- "$installer"' EXIT
curl -fsSL https://omp.sh/install -o "$installer"
PI_INSTALL_DIR="$HOME/.local/bin" bash "$installer" --binary
[ -x "$HOME/.local/bin/omp" ] || { echo 'omp standalone binary not installed' >&2; exit 1; }
