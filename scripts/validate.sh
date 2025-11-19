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

  # Required dependencies (from paths.sh)
  for cmd in "${REQUIRED_PACKAGES[@]}"; do
    if command_exists "$cmd"; then
      # Check version if specified in MIN_VERSIONS
      if [ -n "${MIN_VERSIONS[$cmd]:-}" ]; then
        if ! verify_tool_version "$cmd" "${MIN_VERSIONS[$cmd]}"; then
          ((issues++))
        fi
      else
        log_success "$cmd installed"
      fi
    else
      log_error "$cmd NOT installed (required)"
      ((issues++))
    fi
  done

  # Check Docker daemon status
  local docker_status
  check_docker_daemon
  docker_status=$?
  case $docker_status in
    0)
      log_success "Docker daemon is running"
      ;;
    1)
      log_warn "Docker daemon is not running - start Docker Desktop or run: sudo systemctl start docker"
      ((issues++))
      ;;
    2)
      # Already reported as not installed above
      ;;
  esac

  # Optional dependencies (from paths.sh)
  for cmd in "${OPTIONAL_PACKAGES[@]}"; do
    if command_exists "$cmd"; then
      # Check version if specified in MIN_VERSIONS
      if [ -n "${MIN_VERSIONS[$cmd]:-}" ]; then
        if ! verify_tool_version "$cmd" "${MIN_VERSIONS[$cmd]}"; then
          ((issues++))
        fi
      else
        log_success "$cmd installed"
      fi
    else
      log_info "$cmd not installed (optional but recommended)"
    fi
  done

  # Build tools (from paths.sh) - already checked above in BUILD_PACKAGES loop

  # Additional specific tool checks (with usage notes)
  if ! command_exists make; then
    log_verbose "telescope-fzf-native will use fallback implementation without make"
  fi

  if ! command_exists pkg-config; then
    log_verbose "blink.cmp will use Lua fuzzy matcher without pkg-config"
  fi

  if ! command_exists node; then
    log_verbose "Mermaid CLI (mmdc) requires Node.js"
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
