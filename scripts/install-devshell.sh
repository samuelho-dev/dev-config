#!/bin/bash
# Nix devShell + direnv installation for dev-config
# Simpler approach: devShell + direnv instead of full Home Manager
#
# Usage:
#   bash scripts/install-devshell.sh
#
# What this does:
#   1. Installs Nix (if not present)
#   2. Enables flakes
#   3. Installs direnv (Homebrew or system package manager)
#   4. Installs nix-direnv (Nix profile)
#   5. Configures direnvrc
#   6. Creates symlinks for configs (uses lib/common.sh)
#   7. Installs Oh My Zsh, Powerlevel10k, TPM
#   8. Allows .envrc for automatic environment loading

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"

echo ""
echo "🚀 Installing dev-config (devShell + direnv)"
echo "   Nix-based development environment with auto-loading"
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

# Step 2: Enable flakes
mkdir -p ~/.config/nix
if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
  cat >> ~/.config/nix/nix.conf <<EOF
experimental-features = nix-command flakes
EOF
  log_success "Nix flakes enabled"
fi

# Step 3: Install direnv (system-wide for shell hook)
if ! command -v direnv &>/dev/null; then
  log_info "Installing direnv..."
  if is_macos; then
    brew install direnv
  else
    install_package direnv
  fi
  log_success "direnv installed"
else
  log_success "direnv already installed"
fi

# Step 4: Install nix-direnv (for 'use flake' support)
if [ ! -f ~/.nix-profile/share/nix-direnv/direnvrc ]; then
  log_info "Installing nix-direnv..."
  nix --extra-experimental-features 'nix-command flakes' profile install nixpkgs#nix-direnv
  log_success "nix-direnv installed"
else
  log_success "nix-direnv already installed"
fi

# Step 5: Configure direnvrc
mkdir -p ~/.config/direnv
if [ ! -f ~/.config/direnv/direnvrc ]; then
  log_info "Configuring direnvrc..."
  cat > ~/.config/direnv/direnvrc <<EOF
# nix-direnv integration for fast Nix shell loading
source \$HOME/.nix-profile/share/nix-direnv/direnvrc
EOF
  log_success "direnvrc configured"
else
  log_success "direnvrc already configured"
fi

# Step 6: Create symlinks using shared library
log_info "Creating symlinks for dotfiles..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

for source_path in "${SYMLINK_SOURCES[@]}"; do
  target_path="${SYMLINK_TARGETS[$i]}"
  create_symlink "$source_path" "$target_path" "$TIMESTAMP"
  ((i++))
done

# Step 7: Install Oh My Zsh + Powerlevel10k + TPM
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
  log_info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  log_success "Oh My Zsh installed"
fi

if [ ! -d "$P10K_THEME_DIR" ]; then
  log_info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_THEME_DIR"
  log_success "Powerlevel10k installed"
fi

if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
  log_info "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
  log_success "zsh-autosuggestions installed"
fi

if [ ! -d "$TPM_DIR" ]; then
  log_info "Installing TPM (Tmux Plugin Manager)..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  log_success "TPM installed"
fi

# Step 8: Allow .envrc for automatic loading
log_info "Allowing .envrc for automatic environment loading..."
cd "$REPO_ROOT"
direnv allow

log_success "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. cd ~/Projects/dev-config"
echo "  3. direnv will automatically load the Nix environment"
echo "  4. (Optional) Sign in to 1Password: op signin"
echo "  5. AI credentials will auto-load from 1Password"
echo ""
echo "The Nix environment provides:"
echo "  - Neovim, tmux, zsh, Docker"
echo "  - fzf, ripgrep, lazygit, gh"
echo "  - 1Password CLI, OpenCode (manual install)"
echo "  - All LSP servers and formatters"
echo ""
