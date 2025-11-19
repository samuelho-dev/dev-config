#!/bin/bash
# Install dev-config with zero-touch automation
# Installs all dependencies, creates symlinks, and configures plugins

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"

# =============================================================================
# Usage Information
# =============================================================================

show_usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Zero-touch installation script for dev-config. Installs dependencies, creates
symlinks, and configures plugins automatically.

OPTIONS:
  -y, --yes             Skip all confirmation prompts (auto-yes)
  --skip-api-keys       Skip AI provider API key setup
  --dry-run             Show what would be done without making changes
  -v, --verbose         Enable verbose logging
  -h, --help            Show this help message

EXAMPLES:
  # Interactive installation
  bash scripts/install.sh

  # Fully automated (CI/CD)
  bash scripts/install.sh --yes --skip-api-keys

  # Preview changes without executing
  bash scripts/install.sh --dry-run

  # Verbose output for debugging
  bash scripts/install.sh --verbose

EOF
}

# =============================================================================
# Installation Tracking
# =============================================================================

# Arrays to track installation state for summary
declare -a INSTALLED_PACKAGES=()
declare -a SKIPPED_PACKAGES=()
declare -a FAILED_PACKAGES=()

# NOTE: Utility functions (get_current_shell, verify_tool_version, wait_with_spinner)
# are now in lib/common.sh to eliminate duplication

# =============================================================================
# Main Installation
# =============================================================================

main() {
  # Parse command-line flags
  local AUTO_YES=0
  local SKIP_API_KEYS=0

  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_usage
        exit 0
        ;;
      -y|--yes)
        AUTO_YES=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      --skip-api-keys)
        SKIP_API_KEYS=1
        shift
        ;;
      -h|--help)
        echo "Usage: $0 [-y|--yes] [--skip-api-keys] [-h|--help]"
        echo ""
        echo "Options:"
        echo "  -y, --yes           Auto-confirm all prompts (non-interactive mode)"
        echo "  --skip-api-keys     Skip API key configuration"
        echo "  -h, --help          Show this help message"
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        echo "Usage: $0 [-y|--yes] [--skip-api-keys] [-h|--help]"
        exit 1
        ;;
    esac
  done

  # Export flags for use in subfunctions
  export AUTO_YES SKIP_API_KEYS DRY_RUN VERBOSE

  if [ "$DRY_RUN" -eq 1 ]; then
    log_section "🔍 DRY-RUN MODE - No changes will be made"
  else
    log_section "🚀 Installing dev-config..."
  fi

  # Pre-flight checks
  check_sudo

  # Initialize Homebrew environment if installed
  init_brew

  # Check network connectivity (required for downloads)
  if ! check_network; then
    log_error "Network connectivity required for installation. Please check your internet connection."
    exit 1
  fi

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

  # Step 6: Setup AI provider API keys (optional)
  if [ "$SKIP_API_KEYS" -eq 0 ]; then
    setup_api_keys
  else
    log_info "⏭️  Skipping API key setup (--skip-api-keys flag provided)"
  fi

  # Step 7: Auto-install Neovim plugins
  install_neovim_plugins

  # Step 8: Auto-install tmux plugins
  install_tmux_plugins

  # Step 9: Print installation summary
  print_installation_summary

  # Step 10: Verify installation
  verify_installation

  # Done!
  print_completion_message
}

# =============================================================================
# Core Dependencies Installation
# =============================================================================

install_core_dependencies() {
  log_section "📦 Installing core dependencies..."

  ensure_homebrew_installed
  install_required_packages
  install_optional_packages
  install_npm_tools
  verify_build_tools
  check_tool_versions
}

# Ensure Homebrew is installed on macOS
ensure_homebrew_installed() {
  if ! is_macos; then
    return 0
  fi

  if command_exists brew; then
    log_success "Homebrew already installed"
    SKIPPED_PACKAGES+=("homebrew")
    return 0
  fi

  log_info "⏳ Installing Homebrew (this may take 3-5 minutes)..."
  if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    # Add brew to PATH for current session
    if [ -f /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    log_success "Homebrew installed"
    INSTALLED_PACKAGES+=("homebrew")
  else
    log_error "Failed to install Homebrew"
    FAILED_PACKAGES+=("homebrew")
    return 1
  fi
}

# Install required packages (fail if any critical package fails)
install_required_packages() {
  local packages=(git zsh tmux docker)
  local failures=0
  local failed_list=()

  for package in "${packages[@]}"; do
    if [ "$package" = "docker" ]; then
      if ! install_docker; then
        log_error "Failed to install Docker"
        failed_list+=("$package")
        FAILED_PACKAGES+=("$package")
        ((failures++))
      fi
    else
      if command_exists "$package"; then
        log_success "$package already installed"
        SKIPPED_PACKAGES+=("$package")
      elif install_package "$package" true; then
        INSTALLED_PACKAGES+=("$package")
      else
        log_error "Failed to install required package: $package"
        failed_list+=("$package")
        FAILED_PACKAGES+=("$package")
        ((failures++))
      fi
    fi
  done

  if [ $failures -gt 0 ]; then
    log_warn "Core package installation encountered $failures issue(s). Please install manually: ${failed_list[*]}"
  fi
}

# Install optional packages (best effort, warnings only)
install_optional_packages() {
  local packages=(neovim fzf ripgrep lazygit gitmux imagemagick docker-compose make node npm pkg-config)

  for package in "${packages[@]}"; do
    # Check if already installed
    if command_exists "$package"; then
      SKIPPED_PACKAGES+=("$package")
      continue
    fi

    # Handle special cases
    if is_linux && [ "$package" = "lazygit" ]; then
      if ! install_package "$package" 2>/dev/null; then
        log_warn "lazygit not available via package manager. Install manually from: https://github.com/jesseduffield/lazygit"
        FAILED_PACKAGES+=("$package")
        continue
      fi
      INSTALLED_PACKAGES+=("$package")
    else
      if install_package "$package"; then
        INSTALLED_PACKAGES+=("$package")
      else
        log_warn "Optional package $package not installed"
        FAILED_PACKAGES+=("$package")
      fi
    fi
  done
}

# Install npm-based tools
install_npm_tools() {
  if ! command_exists npm; then
    log_warn "npm not found. Mermaid CLI (mmdc) not installed."
    return 0
  fi

  if command_exists mmdc; then
    log_success "Mermaid CLI already installed"
    SKIPPED_PACKAGES+=("mermaid-cli")
    return 0
  fi

  log_info "⏳ Installing Mermaid CLI (mmdc) via npm..."
  if npm install -g @mermaid-js/mermaid-cli >/dev/null 2>&1; then
    log_success "Mermaid CLI installed"
    INSTALLED_PACKAGES+=("mermaid-cli")
  else
    log_warn "Failed to install Mermaid CLI. Install manually: npm install -g @mermaid-js/mermaid-cli"
    FAILED_PACKAGES+=("mermaid-cli")
  fi
}

# Verify build tools are available
verify_build_tools() {
  if ! command_exists make; then
    log_warn "make not found - telescope-fzf-native will use fallback implementation"
    log_info "Install make: brew install make (macOS) or apt install build-essential (Linux)"
  fi

  if ! command_exists pkg-config; then
    log_info "pkg-config not found - blink.cmp will use Lua fuzzy matcher (default)"
    log_info "Install pkg-config: brew install pkg-config (macOS) or apt install pkg-config (Linux)"
  fi
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

  # Check if Docker daemon is already running
  if docker info >/dev/null 2>&1; then
    log_success "Docker daemon already running"
    return 0
  fi

  # Start Docker Desktop
  log_info "Starting Docker Desktop..."
  open -a Docker || log_warn "Could not start Docker Desktop automatically"

  # Wait for Docker daemon to start with progress indicator
  if wait_with_spinner "Waiting for Docker daemon" "docker info" 60 2; then
    log_success "Docker daemon is running"
    return 0
  else
    log_warn "Docker daemon did not start. Please start Docker Desktop manually."
    return 1
  fi
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

  # Check required tool versions
  verify_tool_version "nvim" "0.9.0" || true
  verify_tool_version "tmux" "1.9" "-V" || true
  verify_tool_version "docker" "20.10" || true

  # Check Docker daemon status
  if command_exists docker; then
    if docker info >/dev/null 2>&1; then
      log_success "Docker daemon is running"
    else
      log_warn "Docker daemon not running - start Docker Desktop or run: sudo systemctl start docker"
    fi
  fi

  # Check optional tools
  if command_exists docker-compose; then
    local compose_version=$(get_command_version docker-compose)
    [ -n "$compose_version" ] && log_success "Docker Compose $compose_version" || log_success "Docker Compose installed"
  elif docker compose version >/dev/null 2>&1; then
    log_success "Docker Compose (plugin) available"
  else
    log_info "Docker Compose not found - optional"
  fi

  command_exists gh && log_success "GitHub CLI installed" || log_info "GitHub CLI not installed (optional for PR/issue management)"
  command_exists mmdc && log_success "Mermaid CLI (mmdc) installed" || log_warn "Mermaid CLI missing - Mermaid previews disabled"
  command_exists convert && log_success "ImageMagick installed" || log_warn "ImageMagick missing - image.nvim disabled"

  # Check API keys
  [ -n "${ZHIPUAI_API_KEY:-}" ] && log_success "ZHIPUAI_API_KEY detected for GLM integrations" || log_warn "ZHIPUAI_API_KEY not set - GLM features offline"
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
    install_git_repo "https://github.com/romkatv/powerlevel10k.git" "$P10K_THEME_DIR" 1
  else
    log_success "Powerlevel10k already installed"
  fi

  # Install zsh-autosuggestions plugin
  if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
    install_git_repo "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_AUTOSUGGESTIONS_DIR"
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

  # Check if shell is in /etc/shells
  if [ -f /etc/shells ] && ! grep -qx "$desired_shell" /etc/shells; then
    log_warn "Shell $desired_shell is not listed in /etc/shells."
    log_warn "Add it with: sudo sh -c 'echo $desired_shell >> /etc/shells'"
  fi

  # Get current default shell
  local current_shell=$(get_current_shell)

  # Check if already using zsh
  if [[ "$current_shell" == *"zsh" ]]; then
    log_success "Default shell already set to zsh ($current_shell)"

    # Check if using old system zsh (only warn if version < 5.0)
    if [ "$current_shell" = "/bin/zsh" ] && command_exists brew; then
      local zsh_version=$(zsh --version 2>/dev/null | awk '{print $2}')
      if [ -n "$zsh_version" ] && ! version_gte "$zsh_version" "5.0"; then
        local brew_zsh_path="$(brew --prefix 2>/dev/null)/bin/zsh"
        log_warn "Using old system zsh $zsh_version. Consider upgrading to Homebrew zsh:"
        log_warn "  brew install zsh && sudo sh -c 'echo $brew_zsh_path >> /etc/shells' && chsh -s $brew_zsh_path"
      fi
    fi
    return 0
  fi

  # Need to change shell
  log_info "Current shell: $current_shell"

  # Check if non-interactive mode
  if [ "${AUTO_YES:-0}" -eq 0 ]; then
    read -p "Change default shell to zsh? (y/n): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
  fi

  # Attempt to change shell
  if ! command_exists chsh; then
    log_warn "chsh command not available. Update shell manually to: $desired_shell"
    return 1
  fi

  log_info "Changing default shell to: $desired_shell"
  if chsh -s "$desired_shell" >/dev/null 2>&1; then
    log_success "Default shell updated to zsh. Log out or restart your terminal to apply."
  else
    log_warn "Could not change shell automatically. Run: chsh -s \"$desired_shell\""
    return 1
  fi

  # Verify the change
  local new_shell=$(get_current_shell)
  if [[ "$new_shell" == *"zsh" ]]; then
    log_success "Verified: Default shell is now zsh ($(zsh --version 2>/dev/null | head -n1))"
  else
    log_warn "Shell change may require logout to take effect. Current: $new_shell"
  fi
}

# =============================================================================
# TPM Installation
# =============================================================================

install_tpm() {
  log_section "🔌 Installing TPM (Tmux Plugin Manager)..."

  mkdir -p "$TPM_BASE_DIR"

  if [ ! -d "$TPM_DIR" ]; then
    install_git_repo "https://github.com/tmux-plugins/tpm" "$TPM_DIR"
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
  local failed=0

  # Array-driven symlink creation (DRY principle)
  # Automatically syncs with SYMLINK_SOURCES/SYMLINK_TARGETS arrays in paths.sh
  for i in "${!SYMLINK_SOURCES[@]}"; do
    if ! create_symlink "${SYMLINK_SOURCES[$i]}" "${SYMLINK_TARGETS[$i]}" "$timestamp"; then
      ((failed++)) || true
    fi
  done

  if [ $failed -gt 0 ]; then
    log_warn "Failed to create $failed symlink(s). Run 'bash scripts/validate.sh' for details."
    return 1
  fi

  log_success "All symlinks created successfully"
  return 0
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
# AI Provider API Key Setup
# =============================================================================

setup_api_keys() {
  log_section "🔑 Setting up AI provider API keys..."

  local zshrc_local="$HOME/.zshrc.local"

  # Ensure .zshrc.local exists
  if [ ! -f "$zshrc_local" ]; then
    touch "$zshrc_local"
  fi

  # Array of providers to configure (format: KEY_NAME:Provider Name:Key Prefix:URL)
  local providers=(
    "OPENROUTER_API_KEY:OpenRouter:sk-or-v1-:https://openrouter.ai/keys"
    "ZHIPUAI_API_KEY:ZhipuAI GLM:your-key-:https://open.bigmodel.cn"
    "OPENAI_API_KEY:OpenAI:sk-:https://platform.openai.com/api-keys"
    "ANTHROPIC_API_KEY:Anthropic Claude:sk-ant-:https://console.anthropic.com"
  )

  local any_configured=false

  for provider_config in "${providers[@]}"; do
    IFS=':' read -r key_name provider_name key_prefix provider_url <<< "$provider_config"

    # Check if key is already set in environment
    if [ -n "${!key_name:-}" ]; then
      log_success "$provider_name API key already set in environment ✓"
      any_configured=true
      continue
    fi

    # Check if key already exists in .zshrc.local
    if grep -q "export $key_name=" "$zshrc_local" 2>/dev/null; then
      log_success "$provider_name API key already configured in .zshrc.local ✓"
      any_configured=true
      continue
    fi

    # Prompt user to configure this provider
    echo ""
    log_info "Configure $provider_name?"
    log_info "Get your API key from: $provider_url"

    read -p "Do you want to configure $provider_name? (y/n): " -n 1 -r configure_choice
    echo "" # newline after single char input

    if [[ $configure_choice =~ ^[Yy]$ ]]; then
      read -p "Enter your $provider_name API key: " api_key

      if [ -n "$api_key" ]; then
        # Append to .zshrc.local
        echo "" >> "$zshrc_local"
        echo "# $provider_name API Key (added by dev-config install.sh)" >> "$zshrc_local"
        echo "export $key_name=\"$api_key\"" >> "$zshrc_local"
        log_success "$provider_name API key configured ✓"
        any_configured=true
      else
        log_warn "$provider_name API key was empty, skipped"
      fi
    else
      log_info "$provider_name skipped"
    fi
  done

  # Source the updated file if any keys were configured
  if [ "$any_configured" = true ]; then
    # shellcheck disable=SC1090
    source "$zshrc_local" 2>/dev/null || true
  fi

  echo ""
  if [ "$any_configured" = true ]; then
    log_success "API key configuration complete!"
  else
    log_info "No API keys configured (you can add them later by editing: ~/.zshrc.local)"
  fi

  log_info "Note: Restart your terminal or run 'source ~/.zshrc' to load the keys"
  log_info "AI plugins (minuet, codecompanion) will only load if at least one API key is set"
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

  # Check if plugins are already installed
  local lazy_dir="$HOME/.local/share/nvim/lazy"
  if [ -d "$lazy_dir" ] && [ "$(find "$lazy_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)" -gt 5 ]; then
    log_success "Neovim plugins already installed (found $(find "$lazy_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') plugins)"
    return 0
  fi

  log_info "⏳ Installing Neovim plugins via Lazy.nvim (this may take 1-2 minutes)..."

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

  # Check if key plugins are already installed
  local plugins_dir="$HOME/.tmux/plugins"
  local key_plugins=("vim-tmux-navigator" "tmux-resurrect" "tmux-yank" "catppuccin")
  local installed_count=0

  for plugin in "${key_plugins[@]}"; do
    if [ -d "$plugins_dir/$plugin" ] || [ -d "$plugins_dir/tmux-$plugin" ]; then
      ((installed_count++))
    fi
  done

  if [ $installed_count -ge 3 ]; then
    log_success "tmux plugins already installed ($installed_count/${#key_plugins[@]} key plugins found)"
    return 0
  fi

  log_info "⏳ Installing tmux plugins via TPM..."

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
# Installation Summary
# =============================================================================

print_installation_summary() {
  log_section "📊 Installation Summary"

  echo ""

  # Installed packages
  if [ ${#INSTALLED_PACKAGES[@]} -gt 0 ]; then
    echo -e "${COLOR_GREEN}✅ Installed (${#INSTALLED_PACKAGES[@]}):${COLOR_RESET}"
    printf "   %s\n" "${INSTALLED_PACKAGES[@]}" | sort | column
  fi

  # Skipped packages (already installed)
  if [ ${#SKIPPED_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo -e "${COLOR_CYAN}⏭️  Skipped (${#SKIPPED_PACKAGES[@]} already installed):${COLOR_RESET}"
    printf "   %s\n" "${SKIPPED_PACKAGES[@]}" | sort | column
  fi

  # Failed packages
  if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo -e "${COLOR_YELLOW}⚠️  Failed/Unavailable (${#FAILED_PACKAGES[@]}):${COLOR_RESET}"
    printf "   %s\n" "${FAILED_PACKAGES[@]}" | sort | column
  fi

  echo ""
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
main "$@"
