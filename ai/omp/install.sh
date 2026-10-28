#!/usr/bin/env bash
# Shared bootstrap for Home Manager and container images; do not install Bun shims.
set -euo pipefail
if [ -x "$HOME/.local/bin/omp" ]; then
  exit 0
fi
curl -fsSL https://omp.sh/install | bash -s -- --binary
[ -x "$HOME/.local/bin/omp" ] || { echo 'omp standalone binary not installed' >&2; exit 1; }
