#!/bin/bash
# Update dev-config by pulling latest changes from Git

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

Update dev-config by pulling latest changes from Git and reloading configurations.

OPTIONS:
  --dry-run             Show what would be done without making changes
  -v, --verbose         Enable verbose logging
  -h, --help            Show this help message

EXAMPLES:
  # Standard update
  bash scripts/update.sh

  # Preview changes without pulling
  bash scripts/update.sh --dry-run

EOF
}

# =============================================================================
# Main Update
# =============================================================================

main() {
  # Parse command-line flags
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_usage
        exit 0
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

  # Export flags
  export DRY_RUN VERBOSE

  if [ "$DRY_RUN" -eq 1 ]; then
    log_section "🔍 DRY-RUN MODE - Preview update"
  else
    log_section "🔄 Updating dev-config..."
  fi

  # Change to repository root
  cd "$REPO_ROOT"

  # Safety checks
  check_git_safety

  # Handle uncommitted changes
  handle_uncommitted_changes

  # Pull latest changes
  pull_latest_changes

  # Reload configurations
  reload_configs

  # Print completion message
  print_completion_message
}

# =============================================================================
# Git Operations
# =============================================================================

check_git_safety() {
  log_verbose "Checking git safety..."

  # Check if branch has upstream
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  local upstream
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")

  if [ -z "$upstream" ]; then
    log_warn "Current branch '$current_branch' has no upstream tracking branch"
    if [ "$DRY_RUN" -ne 1 ]; then
      if ! confirm "Pull from origin/$current_branch anyway?" "Y"; then
        exit 0
      fi
    fi
  fi

  # Check for unpushed commits
  if [ -n "$upstream" ]; then
    local unpushed
    unpushed=$(git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unpushed" -gt 0 ]; then
      log_warn "You have $unpushed unpushed commit(s) on $current_branch"
      if [ "$DRY_RUN" -ne 1 ]; then
        if ! confirm "Continue pull (may create merge commit)?" "N"; then
          exit 0
        fi
      fi
    fi
  fi
}

handle_uncommitted_changes() {
  # Check for uncommitted changes
  if [ -n "$(git status --porcelain)" ]; then
    log_warn "You have uncommitted changes in the repository:"
    git status --short
    echo ""

    if [ "$DRY_RUN" -eq 1 ]; then
      log_dry_run "Would stash uncommitted changes"
      return 0
    fi

    if confirm "Stash changes and continue?" "N"; then
      git stash push -m "Auto-stash before update $(date +%Y-%m-%d_%H:%M:%S)"
      log_success "Changes stashed"
    else
      log_error "Update cancelled"
      exit 1
    fi
  fi
}

pull_latest_changes() {
  log_section "📥 Pulling latest changes..."

  # Get current branch
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  if [ "$DRY_RUN" -eq 1 ]; then
    log_dry_run "Would pull from origin/$current_branch"

    # Show what would be pulled
    local ahead
    ahead=$(git rev-list --count HEAD..origin/"$current_branch" 2>/dev/null || echo "0")
    if [ "$ahead" -gt 0 ]; then
      log_info "$ahead commit(s) would be pulled:"
      git log --oneline HEAD..origin/"$current_branch" 2>/dev/null || true
    else
      log_info "Already up to date"
    fi
    return 0
  fi

  # Pull from origin
  if git pull origin "$current_branch"; then
    log_success "Successfully pulled latest changes from $current_branch"
  else
    log_error "Failed to pull changes. Please resolve conflicts manually."
    exit 1
  fi
}

# =============================================================================
# Configuration Reload
# =============================================================================

reload_configs() {
  log_section "🔄 Reloading configurations..."

  if [ "$DRY_RUN" -eq 1 ]; then
    log_dry_run "Would reload tmux config (if running)"
    log_info "Note: Neovim and shell require manual restart"
    return 0
  fi

  # Reload tmux config if tmux is running
  if command_exists tmux && tmux list-sessions &> /dev/null; then
    if tmux source-file "$HOME_TMUX_CONF" 2>/dev/null; then
      log_success "tmux config reloaded"
    else
      log_warn "tmux reload failed (restart tmux manually)"
    fi
  else
    log_info "tmux not running (restart when ready)"
  fi

  # Note about Neovim
  log_info "Neovim: Restart to apply changes"

  # Note about shell
  log_info "Shell: Restart terminal or run 'exec zsh'"
}

# =============================================================================
# Completion Message
# =============================================================================

print_completion_message() {
  log_section "✅ Update complete!"

  echo ""
  echo "Next steps:"
  echo "  1. Restart Neovim to apply changes"
  echo "  2. Reload shell config: exec zsh (or restart terminal)"
  echo "  3. If tmux plugins were updated, reload with: Prefix + r"
  echo ""
}

# Run main update
main "$@"
