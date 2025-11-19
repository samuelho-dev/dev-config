#!/bin/bash
# Uninstall dev-config by removing symlinks and restoring backups

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

Uninstall dev-config by removing all symlinks and restoring backups.

OPTIONS:
  --dry-run             Show what would be removed without making changes
  -v, --verbose         Enable verbose logging
  -h, --help            Show this help message

EXAMPLES:
  # Interactive uninstallation
  bash scripts/uninstall.sh

  # Preview what would be removed
  bash scripts/uninstall.sh --dry-run

EOF
}

# =============================================================================
# Main Uninstallation
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
    log_section "🔍 DRY-RUN MODE - Preview uninstallation"
  else
    log_section "🗑️  Uninstalling dev-config..."
  fi

  # Confirm before proceeding (skip in dry-run)
  if [ "$DRY_RUN" -ne 1 ]; then
    if ! confirm "This will remove all symlinks and restore backups. Continue?" "N"; then
      log_info "Uninstallation cancelled"
      exit 0
    fi
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
main "$@"
