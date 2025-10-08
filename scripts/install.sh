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
  local core_packages=(git zsh tmux docker)
  local optional_packages=(neovim fzf ripgrep lazygit imagemagick docker-compose make node npm pkg-config)

  local core_failures=0
  local core_failed_list=()

  # Install core packages (required)
  for package in "${core_packages[@]}"; do
    if [ "$package" = "docker" ]; then
      if ! install_docker; then
        log_error "Failed to install Docker"
        core_failed_list+=("$package")
        ((core_failures++))
      fi
    else
      if ! install_package "$package" true; then
        log_error "Failed to install required package: $package"
        core_failed_list+=("$package")
        ((core_failures++))
      fi
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

  # Check for build tools
  if ! command_exists make; then
    log_warn "make not found - telescope-fzf-native will use fallback implementation"
    log_info "Install make for better performance: brew install make (macOS) or apt install build-essential (Linux)"
  fi

  if ! command_exists pkg-config; then
    log_info "pkg-config not found - blink.cmp will use Lua fuzzy matcher (default)"
    log_info "Install pkg-config for Rust optimization: brew install pkg-config (macOS) or apt install pkg-config (Linux)"
  fi

  # Version checks
  check_tool_versions
}

# =============================================================================
# Docker Installation
# =============================================================================

install_docker() {
  log_info "Installing Docker..."

  # Check if Docker is already installed and running
  if command_exists docker && docker info >/dev/null 2>&1; then
    log_success "Docker already installed and running"
    return 0
  fi

  if is_macos; then
    install_docker_macos
  elif is_linux; then
    install_docker_linux
  else
    log_error "Docker installation not supported on this platform"
    return 1
  fi
}

install_docker_macos() {
  log_info "Installing Docker Desktop for macOS..."
  
  # Try Homebrew cask first
  if command_exists brew; then
    if brew list --cask docker >/dev/null 2>&1; then
      log_success "Docker Desktop already installed via Homebrew"
    else
      log_info "Installing Docker Desktop via Homebrew..."
      if brew install --cask docker; then
        log_success "Docker Desktop installed via Homebrew"
      else
        log_warn "Failed to install via Homebrew, trying alternative method"
        install_docker_macos_manual
        return $?
      fi
    fi
  else
    log_warn "Homebrew not available, trying manual installation"
    install_docker_macos_manual
    return $?
  fi

  # Start Docker Desktop
  log_info "Starting Docker Desktop..."
  open -a Docker || log_warn "Could not start Docker Desktop automatically"
  
  # Wait for Docker daemon to start
  log_info "Waiting for Docker daemon to start..."
  local attempts=0
  local max_attempts=30
  while [ $attempts -lt $max_attempts ]; do
    if docker info >/dev/null 2>&1; then
      log_success "Docker daemon is running"
      return 0
    fi
    sleep 2
    ((attempts++))
  done
  
  log_warn "Docker daemon did not start automatically. Please start Docker Desktop manually."
  return 1
}

install_docker_macos_manual() {
  log_info "Please install Docker Desktop manually:"
  log_info "1. Download from: https://www.docker.com/products/docker-desktop/"
  log_info "2. Install the .dmg file"
  log_info "3. Start Docker Desktop"
  log_info "4. Run this script again"
  return 1
}

install_docker_linux() {
  log_info "Installing Docker for Linux..."
  
  # Check if Docker is already installed
  if command_exists docker; then
    log_success "Docker already installed"
    return 0
  fi

  # Try package manager first
  local pm=$(detect_package_manager)
  case $pm in
    apt)
      install_docker_linux_apt
      ;;
    dnf)
      install_docker_linux_dnf
      ;;
    pacman)
      install_docker_linux_pacman
      ;;
    zypper)
      install_docker_linux_zypper
      ;;
    *)
      install_docker_linux_script
      ;;
  esac

  # Add user to docker group
  if groups "$USER" | grep -q docker; then
    log_success "User already in docker group"
  else
    log_info "Adding user to docker group..."
    sudo usermod -aG docker "$USER"
    log_warn "Please log out and log back in for group changes to take effect"
  fi

  # Start and enable Docker service
  if command_exists systemctl; then
    log_info "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
  fi

  return 0
}

install_docker_linux_apt() {
  log_info "Installing Docker via apt..."
  
  # Update package index
  sudo apt update
  
  # Install prerequisites
  sudo apt install -y ca-certificates curl gnupg lsb-release
  
  # Add Docker's official GPG key
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  
  # Add Docker repository
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  # Install Docker
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_linux_dnf() {
  log_info "Installing Docker via dnf..."
  sudo dnf install -y docker docker-compose
}

install_docker_linux_pacman() {
  log_info "Installing Docker via pacman..."
  sudo pacman -S --noconfirm docker docker-compose
}

install_docker_linux_zypper() {
  log_info "Installing Docker via zypper..."
  sudo zypper install -y docker docker-compose
}

install_docker_linux_script() {
  log_info "Installing Docker via official installation script..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  rm get-docker.sh
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

  # Check Docker version
  if command_exists docker; then
    local docker_version=$(get_command_version docker)
    if [ -n "$docker_version" ]; then
      if version_gte "$docker_version" "20.10"; then
        log_success "Docker $docker_version (✓ >= 20.10)"
      else
        log_warn "Docker $docker_version (< 20.10 - may have compatibility issues)"
      fi
    else
      log_success "Docker installed"
    fi
    
    # Check if Docker daemon is running
    if docker info >/dev/null 2>&1; then
      log_success "Docker daemon is running"
    else
      log_warn "Docker daemon is not running - start Docker Desktop or run: sudo systemctl start docker"
    fi
  else
    log_warn "Docker not installed - install manually or retry"
  fi

  # Check Docker Compose (optional)
  if command_exists docker-compose; then
    local compose_version=$(get_command_version docker-compose)
    if [ -n "$compose_version" ]; then
      log_success "Docker Compose $compose_version"
    else
      log_success "Docker Compose installed"
    fi
  elif docker compose version >/dev/null 2>&1; then
    log_success "Docker Compose (plugin) available"
  else
    log_info "Docker Compose not found - install with: brew install docker-compose (macOS) or see https://docs.docker.com/compose/install/"
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

# Docker aliases (uncomment to use)
# alias d='docker'
# alias dc='docker-compose'
# alias dcu='docker-compose up'
# alias dcd='docker-compose down'
# alias dcb='docker-compose build'
# alias dcr='docker-compose run'
# alias dps='docker ps'
# alias dpsa='docker ps -a'
# alias di='docker images'
# alias drm='docker rm'
# alias drmi='docker rmi'
# alias dstop='docker stop'
# alias dstart='docker start'
# alias dexec='docker exec -it'
# alias dlogs='docker logs'
# alias dprune='docker system prune'
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
  echo "  6. Test Docker: docker run hello-world"
  echo ""
  echo "Machine-specific config: Edit ~/.zshrc.local for custom PATH/aliases"
  echo ""
  echo "Docker setup:"
  echo "  - macOS: Docker Desktop should start automatically"
  echo "  - Linux: You may need to log out/in for docker group changes"
  echo "  - Test with: docker run hello-world"
  echo "  - Docker aliases available in ~/.zshrc.local (uncomment to use)"
  echo ""
}

# Run main installation
main
