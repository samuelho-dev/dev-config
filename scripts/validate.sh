#!/bin/bash
# Validate dev-config installation and environment

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"

# =============================================================================
# Main Validation
# =============================================================================

main() {
  log_section "🔍 Validating dev-config installation..."

  local issues=0

  # Check repository structure
  issues=$((issues + $(check_repository_structure)))

  # Check symlinks
  issues=$((issues + $(check_symlinks)))

  # Check dependencies
  issues=$((issues + $(check_dependencies)))

  # Check external tools
  issues=$((issues + $(check_external_tools)))

  # Print summary
  print_summary $issues
}

# =============================================================================
# Repository Structure Check
# =============================================================================

check_repository_structure() {
  log_section "📁 Checking repository structure..."

  local issues=0

  if ! verify_repo_files; then
    ((issues++))
  else
    log_success "All repository files present"
  fi

  echo $issues
}

# =============================================================================
# Symlink Validation
# =============================================================================

check_symlinks() {
  log_section "🔗 Checking symlinks..."

  local issues=0

  for target in "${SYMLINK_TARGETS[@]}"; do
    if [ -L "$target" ]; then
      local link_source=$(readlink "$target")
      if [[ "$link_source" == *"dev-config"* ]]; then
        log_success "$(basename "$target") → correctly symlinked"
      else
        log_warn "$(basename "$target") → symlink exists but points elsewhere: $link_source"
        ((issues++))
      fi
    else
      if [ -e "$target" ]; then
        log_warn "$(basename "$target") → exists but is not a symlink (backup not yet created)"
        ((issues++))
      else
        log_info "$(basename "$target") → not installed (run install.sh)"
        ((issues++))
      fi
    fi
  done

  echo $issues
}

# =============================================================================
# Dependency Checks
# =============================================================================

check_dependencies() {
  log_section "📦 Checking dependencies..."

  local issues=0

  # Required dependencies
  local required=(git zsh tmux docker)
  for cmd in "${required[@]}"; do
    if command_exists "$cmd"; then
      log_success "$cmd installed"
    else
      log_error "$cmd NOT installed (required)"
      ((issues++))
    fi
  done

  # Check Docker specifically
  if command_exists docker; then
    local docker_version=$(get_command_version docker)
    if [ -n "$docker_version" ]; then
      if version_gte "$docker_version" "20.10"; then
        log_success "Docker $docker_version (✓ >= 20.10)"
      else
        log_warn "Docker $docker_version (< 20.10, may have compatibility issues)"
        ((issues++))
      fi
    else
      log_success "Docker installed"
    fi
    
    # Check if Docker daemon is running
    if docker info >/dev/null 2>&1; then
      log_success "Docker daemon is running"
    else
      log_warn "Docker daemon is not running - start Docker Desktop or run: sudo systemctl start docker"
      ((issues++))
    fi
  else
    log_error "Docker NOT installed (required)"
    ((issues++))
  fi

  # Check Docker Compose
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
    log_info "Docker Compose not found (optional but recommended)"
  fi

  # Important optional dependencies
  local optional=(nvim fzf rg lazygit gh make node npm convert mmdc)
  for cmd in "${optional[@]}"; do
    if command_exists "$cmd"; then
      local version=""
      case $cmd in
        nvim)
          version=$(get_command_version nvim)
          if [ -n "$version" ]; then
            if version_gte "$version" "0.9.0"; then
              log_success "$cmd $version (✓ >= 0.9.0)"
            else
              log_warn "$cmd $version (< 0.9.0, may have issues)"
              ((issues++))
            fi
          else
            log_success "$cmd installed"
          fi
          ;;
        *)
          log_success "$cmd installed"
          ;;
      esac
    else
      log_info "$cmd not installed (optional but recommended)"
    fi
  done

  # Check build tools
  if command_exists make; then
    log_success "make installed (telescope-fzf-native can build native binaries)"
  else
    log_warn "make not installed - telescope-fzf-native will use fallback implementation"
  fi

  if command_exists pkg-config; then
    log_success "pkg-config installed (blink.cmp can use the Rust fuzzy matcher)"
  else
    log_info "pkg-config not installed; blink.cmp stays on the Lua fuzzy matcher (default configuration)"
  fi

  # Check Node.js ecosystem
  if command_exists node; then
    local node_version=$(get_command_version node)
    if [ -n "$node_version" ]; then
      log_success "Node.js $node_version installed"
    else
      log_success "Node.js installed"
    fi
  else
    log_warn "Node.js not installed - Mermaid CLI (mmdc) will not be available"
  fi

  if command_exists npm; then
    log_success "npm installed"
  else
    log_warn "npm not installed - Mermaid CLI (mmdc) will not be available"
  fi

  # Check Mermaid CLI
  if command_exists mmdc; then
    log_success "Mermaid CLI (mmdc) installed"
  else
    log_warn "Mermaid CLI (mmdc) not installed - Mermaid previews will not render"
  fi

  # Check ImageMagick
  if command_exists convert; then
    log_success "ImageMagick installed"
  else
    log_warn "ImageMagick not installed - image.nvim may not function correctly"
  fi

  echo $issues
}

# =============================================================================
# External Tools Check
# =============================================================================

check_external_tools() {
  log_section "🔧 Checking external tools..."

  local issues=0

  # Check Oh My Zsh
  if [ -d "$OH_MY_ZSH_DIR" ]; then
    log_success "Oh My Zsh installed"
  else
    log_warn "Oh My Zsh not installed"
    ((issues++))
  fi

  # Check Powerlevel10k
  if [ -d "$P10K_THEME_DIR" ]; then
    log_success "Powerlevel10k theme installed"
  else
    log_warn "Powerlevel10k theme not installed"
    ((issues++))
  fi

  # Check zsh-autosuggestions
  if [ -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
    log_success "zsh-autosuggestions plugin installed"
  else
    log_warn "zsh-autosuggestions plugin not installed"
    ((issues++))
  fi

  # Check TPM
  if [ -d "$TPM_DIR" ]; then
    log_success "TPM (Tmux Plugin Manager) installed"
  else
    log_warn "TPM not installed"
    ((issues++))
  fi

  # Check .zshrc.local
  if [ -f "$HOME_ZSHRC_LOCAL" ]; then
    log_success ".zshrc.local exists (machine-specific config)"
  else
    log_info ".zshrc.local not found (will be created on install)"
  fi

  # Check Mason-installed tools (if Neovim is available)
  if command_exists nvim; then
    log_info "Checking Mason-installed tools..."
    
    # Check if Mason tools are installed
    local mason_tools=("stylua" "prettier" "ruff" "ts_ls" "pyright" "lua_ls")
    local mason_available=0
    
    for tool in "${mason_tools[@]}"; do
      if command_exists "$tool"; then
        ((mason_available++))
      fi
    done
    
    if [ $mason_available -gt 0 ]; then
      log_success "$mason_available Mason tools available (run :Mason in Neovim to see all)"
    else
      log_warn "No Mason tools detected - run :Mason in Neovim to install LSP servers and formatters"
    fi
  fi

  echo $issues
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
  local issues=$1

  echo ""
  if [ $issues -eq 0 ]; then
    log_section "✅ Validation passed! No issues found."
    echo ""
    echo "Your dev-config is properly installed and configured."
    echo ""
    return 0
  else
    log_section "⚠️  Validation completed with $issues issue(s)."
    echo ""
    echo "To fix issues, run: bash $REPO_ROOT/scripts/install.sh"
    echo ""
    return 1
  fi
}

# Run main validation
main
