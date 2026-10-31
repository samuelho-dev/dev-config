#!/bin/bash
# Bootstrap Nix + Home Manager configuration
set -e

# Colors for output
log_info() { echo -e "\033[0;36mℹ️  $1\033[0m" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }

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
  cat >>~/.config/nix/nix.conf <<EOF
experimental-features = nix-command flakes
EOF
  log_success "Nix flakes enabled"
fi

# Step 3: Use Home Manager from this flake's locked input, not a moving branch.
log_info "Checking this flake's Home Manager..."
nix run .#home-manager -- --version

# Step 4: Activate Home Manager configuration
log_info "Activating Home Manager (this may take 10-15 minutes on first run)..."
log_info "Home Manager will:"
log_info "  - Install all packages (Neovim, tmux, zsh, Docker, LSP servers, etc.)"
log_info "  - Create symlinks for dotfiles"
log_info "  - Install Oh My Zsh, Powerlevel10k, plugins"
log_info "  - Install tmux plugins"
log_info "  - Configure everything declaratively"
echo ""

nix run .#home-manager -- switch --flake .

log_success "Home Manager activation complete!"

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
echo "  - Neovim config: nvim/README.md"
echo "  - Tmux config: tmux/README.md"
echo "  - Zsh config: zsh/README.md"
echo ""
