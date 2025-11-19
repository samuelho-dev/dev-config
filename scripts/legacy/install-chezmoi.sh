#!/bin/bash
set -e

echo "📦 Installing Chezmoi dotfiles..."

# Install Chezmoi if not present
if ! command -v chezmoi &> /dev/null; then
    echo "Installing Chezmoi CLI..."
    curl -sfL https://get.chezmoi.io | sh -s -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Apply dotfiles from local repository
chezmoi init --apply ~/Projects/dev-config

echo "✅ Dotfiles installed successfully"
echo "Files synchronized:"
ls -la ~/.claude ~/.config/nvim ~/.zshrc 2>/dev/null || echo "Some files may not exist in your dotfiles yet"
