#!/bin/bash
# Thin wrapper that calls the main install.sh script
# This runs once before Chezmoi applies dotfiles

set -euo pipefail

INSTALL_SCRIPT="{{ .chezmoi.sourceDir }}/scripts/install.sh"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "ERROR: install.sh not found at $INSTALL_SCRIPT"
    exit 1
fi

echo "==> Running install.sh via Chezmoi automation..."
bash "$INSTALL_SCRIPT"
