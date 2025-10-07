#!/bin/bash
# Uninstall dev-config by removing symlinks and restoring backups

set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"

# =============================================================================
# Main Uninstallation
# =============================================================================

main() {
  log_section "🗑️  Uninstalling dev-config..."

  # Confirm before proceeding
  if ! confirm "This will remove all symlinks and restore backups. Continue?" "N"; then
    log_info "Uninstallation cancelled"
    exit 0
  fi

  # Remove all symlinks
  remove_all_symlinks

  # Print completion message
  print_completion_message
}

# =============================================================================
# Symlink Removal
# =============================================================================

remove_all_symlinks() {
  log_section "🔗 Removing symlinks..."

  local removed=0
  local failed=0

  # Remove each symlink
  for target in "${SYMLINK_TARGETS[@]}"; do
    if remove_symlink "$target"; then
      ((removed++))
    else
      ((failed++))
    fi
  done

  echo ""
  log_info "Removed: $removed symlinks"
  if [ $failed -gt 0 ]; then
    log_warn "Not found: $failed symlinks"
  fi
}

# =============================================================================
# Completion Message
# =============================================================================

print_completion_message() {
  log_section "✅ Uninstallation complete!"

  echo ""
  echo "Note:"
  echo "  - Your dev-config repository at $REPO_ROOT is still intact"
  echo "  - Backups (if any) remain in your home directory"
  echo "  - Restart your terminal to apply shell config changes"
  echo ""
  echo "To reinstall: bash $REPO_ROOT/scripts/install.sh"
  echo ""
}

# Run main uninstallation
main
