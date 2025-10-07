#!/bin/bash
# Update dev-config by pulling latest changes from Git

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"

# =============================================================================
# Main Update
# =============================================================================

main() {
  log_section "🔄 Updating dev-config..."

  # Change to repository root
  cd "$REPO_ROOT"

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

handle_uncommitted_changes() {
  # Check for uncommitted changes
  if [ -n "$(git status --porcelain)" ]; then
    log_warn "You have uncommitted changes in the repository:"
    git status --short
    echo ""

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
  local current_branch=$(git rev-parse --abbrev-ref HEAD)

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
main
