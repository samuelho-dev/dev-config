#!/bin/bash
# Zero-touch Nix bootstrap for dev-config
# Replaces 372-line shell script with 50-line Nix-powered installation
#
# Usage:
#   bash scripts/install.sh
#
# What this does:
#   1. Installs Nix (if not present)
#   2. Enables flakes
#   3. Activates dev environment (symlinks, plugins, tools)
#   4. Sets zsh as default shell

set -e

# Colors for output
log_info() { echo -e "\033[0;36mℹ️  $1\033[0m" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }

echo ""
echo "🚀 Installing dev-config (Nix-powered)"
echo "   This will install all dependencies and configure your environment"
echo ""

# Step 1: Install Nix if not present
if ! command -v nix &>/dev/null; then
  log_info "Installing Nix (Determinate Systems installer - 2-3 minutes)..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

  # Source Nix environment
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi

  log_success "Nix installed"
else
  log_success "Nix already installed ($(nix --version))"
fi

# Step 2: Enable flakes and nix-command (if not already enabled)
mkdir -p ~/.config/nix
if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
  cat >> ~/.config/nix/nix.conf <<EOF
experimental-features = nix-command flakes
EOF
  log_success "Nix flakes enabled"
fi

# Step 3: Activate dev environment (builds packages, creates symlinks)
log_info "Activating dev-config environment (this may take 5-10 minutes on first run)..."
nix run .#activate

# Step 4: Set default shell to zsh (via Nix)
log_info "Setting default shell to zsh..."
nix run .#set-shell

log_success "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. (Optional) Sign in to 1Password: op signin"
echo "  3. AI credentials will auto-load when you enter dev-config directory"
echo "  4. Use OpenCode: opencode (credentials auto-injected if 1Password authenticated)"
echo ""
echo "For more information:"
echo "  - Quick start: docs/nix/00-quickstart.md"
echo "  - OpenCode setup: docs/nix/04-opencode-integration.md"
echo "  - 1Password setup: docs/nix/05-1password-setup.md"
echo ""
