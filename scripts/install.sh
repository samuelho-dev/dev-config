#!/bin/bash
# Bootstrap Nix + Home Manager configuration
set -e

# Colors for output
log_info() { echo -e "\033[0;36mℹ️  $1\033[0m" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }

# Container detection
is_container() {
  [ -f /.dockerenv ] || grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2>/dev/null
}

echo ""
echo "🚀 Installing dev-config (Home Manager)"
echo "   Declarative dotfile and package management with Nix"
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

# Step 3: Install Home Manager if not present
if ! command -v home-manager &>/dev/null; then
  log_info "Installing Home Manager..."
  nix run home-manager/master -- --version
  log_success "Home Manager installed"
else
  log_success "Home Manager already installed"
fi

# Step 4: Activate Home Manager configuration
log_info "Activating Home Manager (this may take 10-15 minutes on first run)..."
log_info "Home Manager will:"
log_info "  - Install all packages (Neovim, tmux, zsh, Docker, LSP servers, etc.)"
log_info "  - Create symlinks for dotfiles"
log_info "  - Install Oh My Zsh, Powerlevel10k, plugins"
log_info "  - Install tmux plugins"
log_info "  - Configure everything declaratively"
echo ""

nix run home-manager/master -- switch --flake .

log_success "Home Manager activation complete!"

# Fix ownership if running as root in container (DevPod SSH issue)
if is_container && [ "$(id -u)" -eq 0 ]; then
  ACTUAL_USER="${SUDO_USER:-vscode}"
  log_info "Container detected, fixing ownership for user: $ACTUAL_USER"
  chown -R "$ACTUAL_USER:$ACTUAL_USER" "$HOME" 2>/dev/null || true
  chown -R "$ACTUAL_USER:$ACTUAL_USER" ~/.config 2>/dev/null || true
  chown -R "$ACTUAL_USER:$ACTUAL_USER" ~/.local 2>/dev/null || true
  log_success "Ownership fixed"
fi

echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. (Optional) Set zsh as default shell:"
echo "     chsh -s \$(which zsh)"
echo "  3. (Optional) Sign in to 1Password: op signin"
echo "  4. AI credentials will auto-load when you enter dev-config directory"
echo ""
echo "Updating configuration:"
echo "  1. Edit files in ~/Projects/dev-config"
echo "  2. Run: home-manager switch --flake ~/Projects/dev-config"
echo ""
echo "For more information:"
echo "  - Neovim config: nvim/CLAUDE.md, nvim/README.md"
echo "  - Tmux config: tmux/CLAUDE.md, tmux/README.md"
echo "  - Zsh config: zsh/CLAUDE.md, zsh/README.md"
echo ""
