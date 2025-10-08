#!/bin/bash
# Install dev-config with zero-touch automation
# Installs all dependencies, creates symlinks, and configures plugins

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"

# =============================================================================
# Main Installation
# =============================================================================

main() {
  log_section "🚀 Installing dev-config..."

  # Safety check
  check_sudo

  # Verify repository structure
  if ! verify_repo_files; then
    log_error "Repository structure verification failed. Aborting."
    exit 1
  fi

  # Step 1: Install core system dependencies
  install_core_dependencies

  # Step 2: Install Oh My Zsh and plugins
  install_zsh_components

  # Step 2b: Ensure zsh is the default login shell
  ensure_default_shell_is_zsh

  # Step 3: Install TPM (Tmux Plugin Manager)
  install_tpm

  # Step 4: Create symlinks
  create_all_symlinks

  # Step 5: Create .zshrc.local if it doesn't exist
  create_zshrc_local

  # Step 6: Auto-install Neovim plugins
  install_neovim_plugins

  # Step 7: Auto-install tmux plugins
  install_tmux_plugins

  # Step 8: Verify installation
  verify_installation

  # Done!
  print_completion_message
}

# =============================================================================
# Core Dependencies Installation
# =============================================================================

install_core_dependencies() {
  log_section "📦 Installing core dependencies..."

  # Install Homebrew on macOS if missing
  if is_macos && ! command_exists brew; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for current session
    if [ -f /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  # Define required packages
  local core_packages=(git zsh tmux)
  local optional_packages=(neovim fzf ripgrep lazygit imagemagick)

  local core_failures=0
  local core_failed_list=()

  # Install core packages (required)
  for package in "${core_packages[@]}"; do
    if ! install_package "$package" true; then
      log_error "Failed to install required package: $package"
      core_failed_list+=("$package")
      ((core_failures++))
    fi
  done

  if [ $core_failures -gt 0 ]; then
    log_warn "Core package installation encountered $core_failures issue(s). Please install manually and re-run install.sh for: ${core_failed_list[*]}"
  fi

  # Install optional packages (best effort)
  for package in "${optional_packages[@]}"; do
    # Handle package name differences
    local pkg_name=$package
    if is_linux; then
      case $package in
        lazygit)
          # lazygit might not be in repos, skip gracefully
          if ! install_package "$package" 2>/dev/null; then
            log_warn "lazygit not available via package manager. Install manually from: https://github.com/jesseduffield/lazygit"
            continue
          fi
          ;;
      esac
    fi

    install_package "$pkg_name" || log_warn "Optional package $package not installed"
  done

  # Install Mermaid CLI if npm is available
  if command_exists npm; then
    if ! command_exists mmdc; then
      log_info "Installing Mermaid CLI (mmdc) via npm..."
      if npm install -g @mermaid-js/mermaid-cli >/dev/null 2>&1; then
        log_success "Mermaid CLI installed"
      else
        log_warn "Failed to install Mermaid CLI via npm. Install manually with: npm install -g @mermaid-js/mermaid-cli"
      fi
    else
      log_success "Mermaid CLI already installed"
    fi
  else
    log_warn "npm not found. Mermaid CLI (mmdc) not installed. Install npm or run: npm install -g @mermaid-js/mermaid-cli"
  fi

  # Version checks
  check_tool_versions
}

check_tool_versions() {
  log_section "🔍 Checking tool versions..."

  # Check Neovim version
  if command_exists nvim; then
    local nvim_version=$(get_command_version nvim)
    if [ -n "$nvim_version" ]; then
      if version_gte "$nvim_version" "0.9.0"; then
        log_success "Neovim $nvim_version (✓ >= 0.9.0)"
      else
        log_warn "Neovim $nvim_version (< 0.9.0 - may have issues)"
      fi
    fi
  else
    log_warn "Neovim not installed - install manually or retry"
  fi

  # Check tmux version
  if command_exists tmux; then
    local tmux_version=$(get_command_version tmux -V)
    if [ -n "$tmux_version" ]; then
      if version_gte "$tmux_version" "1.9"; then
        log_success "tmux $tmux_version (✓ >= 1.9)"
      else
        log_warn "tmux $tmux_version (< 1.9 - may have issues)"
      fi
    fi
  else
    log_warn "tmux not installed - install manually or retry"
  fi

  # Check for GitHub CLI (optional)
  if ! command_exists gh; then
    log_info "GitHub CLI (gh) not installed - optional for PR/issue management"
    log_info "Install with: brew install gh (macOS) or see https://cli.github.com/"
  else
    log_success "GitHub CLI installed"
  fi

  # Confirm Mermaid CLI and ImageMagick availability
  if command_exists mmdc; then
    log_success "Mermaid CLI (mmdc) installed"
  else
    log_warn "Mermaid CLI (mmdc) missing - Mermaid previews will not render until installed"
  fi
  if command_exists convert; then
    log_success "ImageMagick installed"
  else
    log_warn "ImageMagick missing - image.nvim may not function correctly"
  fi

  if [ -z "${ZHIPUAI_API_KEY:-}" ]; then
    log_warn "ZHIPUAI_API_KEY not set - GLM-based features (Minuet & CodeCompanion) will stay offline until you export it"
  else
    log_success "Detected ZHIPUAI_API_KEY for GLM integrations"
  fi
}

# =============================================================================
# Zsh Components Installation
# =============================================================================

install_zsh_components() {
  log_section "🐚 Installing Zsh components..."

  # Install Oh My Zsh
  if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    log_info "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
  else
    log_success "Oh My Zsh already installed"
  fi

  # Install Powerlevel10k theme
  if [ ! -d "$P10K_THEME_DIR" ]; then
    log_info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_THEME_DIR"
    log_success "Powerlevel10k installed"
  else
    log_success "Powerlevel10k already installed"
  fi

  # Install zsh-autosuggestions plugin
  if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
    log_info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
    log_success "zsh-autosuggestions installed"
  else
    log_success "zsh-autosuggestions already installed"
  fi
}

# =============================================================================
# Default Shell Configuration
# =============================================================================

ensure_default_shell_is_zsh() {
  log_section "🌀 Ensuring zsh is the default shell..."

  local desired_shell
  desired_shell=$(command -v zsh || true)

  if [ -z "$desired_shell" ]; then
    log_error "zsh is required but was not found on PATH after installation."
    exit 1
  fi

  if [ -f /etc/shells ] && ! grep -qx "$desired_shell" /etc/shells; then
    log_warn "Shell $desired_shell is not listed in /etc/shells."
    log_warn "Add it with: sudo sh -c 'echo $desired_shell >> /etc/shells'"
  fi

  local login_shell=""
  if command_exists getent; then
    login_shell=$(getent passwd "$USER" | cut -d: -f7)
  elif command_exists dscl; then
    login_shell=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
  fi
  [ -z "$login_shell" ] && login_shell="${SHELL:-}"

  if [ "$login_shell" = "$desired_shell" ]; then
    log_success "Default shell already set to zsh"
  else
    log_info "Attempting to change default shell from ${login_shell:-unknown} to $desired_shell..."

    if command_exists chsh; then
      if chsh -s "$desired_shell" >/dev/null 2>&1; then
        log_success "Default shell updated to zsh. Log out or restart your terminal to apply."
      else
        log_warn "Could not change default shell automatically. Run: chsh -s \"$desired_shell\""
      fi
    else
      log_warn "chsh command not available. Update your default shell to $desired_shell manually."
    fi
  fi

  # Re-evaluate current login shell after attempting to switch
  local post_shell=""
  if command_exists getent; then
    post_shell=$(getent passwd "$USER" | cut -d: -f7)
  elif command_exists dscl; then
    post_shell=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
  fi
  [ -z "$post_shell" ] && post_shell="${SHELL:-}"

  if [ "$post_shell" = "$desired_shell" ]; then
    log_success "Verified default shell set to $desired_shell ($(zsh --version 2>/dev/null | head -n1))."
  else
    log_warn "Default shell is still ${post_shell:-unknown}. Run: chsh -s \"$desired_shell\" (after adding to /etc/shells if needed)."
  fi

  if [ "$desired_shell" = "/bin/zsh" ] && command_exists brew; then
    local brew_zsh_path
    brew_zsh_path="$(brew --prefix 2>/dev/null)/bin/zsh"
    log_warn "Using /bin/zsh. Upgrade to Homebrew zsh with:"
    log_warn "  brew install zsh"
    if [ -n "$brew_zsh_path" ]; then
      log_warn "  sudo sh -c 'echo $brew_zsh_path >> /etc/shells'"
      log_warn "  chsh -s $brew_zsh_path"
    else
      log_warn "  sudo sh -c 'echo $(brew --prefix)/bin/zsh >> /etc/shells'"
      log_warn "  chsh -s $(brew --prefix)/bin/zsh"
    fi
  fi
}

# =============================================================================
# TPM Installation
# =============================================================================

install_tpm() {
  log_section "🔌 Installing TPM (Tmux Plugin Manager)..."

  mkdir -p "$TPM_BASE_DIR"

  if [ ! -d "$TPM_DIR" ]; then
    log_info "Installing TPM into $TPM_DIR..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    log_success "TPM installed"
  else
    log_success "TPM already installed"
  fi
}

# =============================================================================
# Symlink Creation
# =============================================================================

create_all_symlinks() {
  log_section "🔗 Creating symlinks..."

  local timestamp=$(date +%Y%m%d_%H%M%S)

  # Create symlinks using the centralized paths
  create_symlink "$REPO_NVIM" "$HOME_NVIM" "$timestamp"
  create_symlink "$REPO_TMUX_CONF" "$HOME_TMUX_CONF" "$timestamp"
  create_symlink "$REPO_GHOSTTY_CONFIG" "$HOME_GHOSTTY_CONFIG" "$timestamp"
  create_symlink "$REPO_ZSHRC" "$HOME_ZSHRC" "$timestamp"
  create_symlink "$REPO_ZPROFILE" "$HOME_ZPROFILE" "$timestamp"
  create_symlink "$REPO_P10K" "$HOME_P10K" "$timestamp"
}

# =============================================================================
# Local Config Creation
# =============================================================================

create_zshrc_local() {
  if [ ! -f "$HOME_ZSHRC_LOCAL" ]; then
    log_info "Creating .zshrc.local for machine-specific configuration..."
    cat > "$HOME_ZSHRC_LOCAL" <<'EOF'
# .zshrc.local - Machine-specific zsh configuration
# This file is sourced by .zshrc and is gitignored
# Add your machine-specific PATH additions, aliases, and environment variables here

# Example: Add custom bin directory to PATH
# export PATH="$HOME/bin:$PATH"

# Example: Machine-specific aliases
# alias work-vpn="sudo openvpn /path/to/config.ovpn"

# Example: Environment variables for local development
# export DATABASE_URL="postgresql://localhost:5432/mydb"
EOF
    log_success "Created .zshrc.local template"
  else
    log_success ".zshrc.local already exists"
  fi
}

# =============================================================================
# Neovim Plugin Installation
# =============================================================================

install_neovim_plugins() {
  log_section "💎 Installing Neovim plugins..."

  if ! command_exists nvim; then
    log_warn "Neovim not found, skipping plugin installation"
    return 1
  fi

  log_info "Installing Neovim plugins via Lazy.nvim..."

  if ! command_exists pkg-config; then
    log_info "pkg-config not found; blink.cmp will use the Lua fuzzy matcher (no Rust build attempted)"
  fi

  # Run Lazy sync in headless mode
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || {
    log_warn "Neovim plugin installation completed with warnings (this is normal on first run)"
  }

  log_success "Neovim plugins installed"
}

# =============================================================================
# Tmux Plugin Installation
# =============================================================================

install_tmux_plugins() {
  log_section "🔌 Installing tmux plugins..."

  if ! command_exists tmux; then
    log_warn "tmux not found on PATH, skipping tmux plugin installation"
    return 1
  fi

  if [ ! -d "$TPM_DIR" ]; then
    log_warn "TPM not found, skipping tmux plugin installation"
    return 1
  fi

  if [ ! -f "$TPM_DIR/scripts/install_plugins.sh" ]; then
    log_warn "TPM install script not found, skipping tmux plugin installation"
    return 1
  fi

  log_info "Installing tmux plugins via TPM..."

  # Run TPM install script
  if bash "$TPM_DIR/scripts/install_plugins.sh"; then
    log_success "tmux plugins installed"
  else
    log_warn "TPM plugin installation completed with warnings"
    return 1
  fi
}

# =============================================================================
# Verification
# =============================================================================

verify_installation() {
  log_section "🔍 Verifying installation..."

  local failed=0

  # Verify symlinks
  for target in "${SYMLINK_TARGETS[@]}"; do
    if [ -L "$target" ]; then
      local link_source=$(readlink "$target")
      if [[ "$link_source" == *"dev-config"* ]]; then
        log_success "$(basename "$target") → symlinked correctly"
      else
        log_warn "$(basename "$target") → symlink exists but points to unexpected location: $link_source"
        ((failed++))
      fi
    else
      log_error "$(basename "$target") → symlink not found"
      ((failed++))
    fi
  done

  # Verify Oh My Zsh
  if [ -d "$OH_MY_ZSH_DIR" ]; then
    log_success "Oh My Zsh verified"
  else
    log_error "Oh My Zsh not found"
    ((failed++))
  fi

  # Verify TPM
  if [ -d "$TPM_DIR" ]; then
    log_success "TPM verified"
  else
    log_error "TPM not found"
    ((failed++))
  fi

  # Verify default shell
  local desired_shell
  desired_shell=$(command -v zsh || true)
  if [ -n "$desired_shell" ]; then
    local login_shell=""
    if command_exists getent; then
      login_shell=$(getent passwd "$USER" | cut -d: -f7)
    elif command_exists dscl; then
      login_shell=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
    fi
    [ -z "$login_shell" ] && login_shell="${SHELL:-}"

    if [ "$login_shell" = "$desired_shell" ]; then
      log_success "Default shell verified as zsh"
    else
      log_warn "Default shell is ${login_shell:-unknown}. Run: chsh -s \"$desired_shell\""
      ((failed++))
    fi
  fi

  if [ $failed -eq 0 ]; then
    log_section "✅ All verifications passed!"
    return 0
  else
    log_section "⚠️  $failed verification(s) failed"
    return 1
  fi
}

# =============================================================================
# Completion Message
# =============================================================================

print_completion_message() {
  log_section "✅ Installation complete!"

  echo ""
  echo "ℹ️  Your leader key is <space> (spacebar)"
  echo ""
  echo "Next steps:"
  echo "  1. Restart your terminal (or run: exec zsh)"
  echo "  2. Open Neovim - plugins are installed automatically"
  echo "  3. Start tmux - plugins are installed automatically"
  echo "  4. Try Git integration: <space>gg for lazygit in Neovim"
  echo "  5. Try markdown preview: <space>mp in a .md file"
  echo ""
  echo "Machine-specific config: Edit ~/.zshrc.local for custom PATH/aliases"
  echo ""
}

# Run main installation
main
