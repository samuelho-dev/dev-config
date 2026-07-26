#!/usr/bin/env sh
# Install the canonical OMP plugin list on workstations and container runtimes.
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PLUGINS_FILE="${OMP_PLUGINS_FILE:-$SCRIPT_DIR/plugins.txt}"
PLUGIN_DIR="$HOME/.omp/plugins/node_modules"

if ! command -v omp >/dev/null 2>&1; then
  echo "omp-plugins: omp not found; skipping" >&2
  exit 0
fi
if [ ! -f "$PLUGINS_FILE" ]; then
  echo "omp-plugins: no plugin list at $PLUGINS_FILE; skipping" >&2
  exit 0
fi

while IFS= read -r plugin; do
  [ -n "$plugin" ] || continue
  [ ! -d "$PLUGIN_DIR/$plugin" ] || continue

  echo "omp-plugins: installing $plugin"
  omp install "$plugin" >/dev/null
done < "$PLUGINS_FILE"
