{writeShellScriptBin}:
writeShellScriptBin "sync-ai-config" ''
  set -e

  # Colors
  log_info() { echo -e "\033[0;36mℹ️  $1\033[0m"; }
  log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
  log_warn() { echo -e "\033[0;33m⚠️  $1\033[0m"; }
  log_error() { echo -e "\033[0;31m❌ $1\033[0m"; exit 1; }

  # Default dev-config location (can be overridden with DEV_CONFIG_PATH)
  DEV_CONFIG="''${DEV_CONFIG_PATH:-$HOME/Projects/infra/dev-config}"

  # Parse arguments
  FORCE=""
  TOOL=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      --force|-f) FORCE=1; shift ;;
      --claude) TOOL="claude"; shift ;;
      --factory) TOOL="factory"; shift ;;
      --all) TOOL=""; shift ;;
      -h|--help)
        echo "Usage: sync-ai-config [OPTIONS]"
        echo ""
        echo "Syncs AI configurations from dev-config repo to global config directories."
        echo "Creates writable copies so you can add new agents/commands."
        echo ""
        echo "Options:"
        echo "  --force, -f  Overwrite existing directories"
        echo "  --claude     Only sync ~/.claude/"
        echo "  --factory    Only sync ~/.factory/"
        echo "  --all        Sync all (default)"
        echo "  -h, --help   Show this help"
        echo ""
        echo "Environment:"
        echo "  DEV_CONFIG_PATH  Override dev-config location"
        echo "                   (default: ~/Projects/infra/dev-config)"
        echo ""
        echo "Examples:"
        echo "  sync-ai-config              # Sync all AI configs"
        echo "  sync-ai-config --force      # Force overwrite all"
        echo "  sync-ai-config --claude     # Only sync Claude Code configs"
        exit 0
        ;;
      *) shift ;;
    esac
  done

  # Verify dev-config exists
  if [ ! -d "$DEV_CONFIG/ai" ]; then
    log_error "dev-config not found at $DEV_CONFIG"
    echo "Set DEV_CONFIG_PATH or run: home-manager switch --flake <dev-config>"
    exit 1
  fi

  sync_dir() {
    local src="$1"
    local dst="$2"
    local name="$3"

    if [ ! -d "$src" ]; then
      log_warn "Source not found: $src"
      return
    fi

    if [ -d "$dst" ] && [ -z "$FORCE" ]; then
      log_warn "$name exists (use --force to overwrite)"
      return
    fi

    rm -rf "$dst"
    cp -Lr "$src" "$dst"
    chmod -R +w "$dst"
    log_success "Synced $name"
  }

  # ============================================
  # Claude Code (~/.claude/)
  # ============================================
  if [ -z "$TOOL" ] || [ "$TOOL" = "claude" ]; then
    log_info "Syncing Claude Code configuration..."
    mkdir -p "$HOME/.claude"

    sync_dir "$DEV_CONFIG/ai/agents" "$HOME/.claude/agents" "~/.claude/agents"
    sync_dir "$DEV_CONFIG/ai/commands" "$HOME/.claude/commands" "~/.claude/commands"
  fi

  # ============================================
  # Factory Droid (~/.factory/)
  # ============================================
  if [ -z "$TOOL" ] || [ "$TOOL" = "factory" ]; then
    log_info "Syncing Factory Droid configuration..."
    mkdir -p "$HOME/.factory"

    sync_dir "$DEV_CONFIG/ai/agents" "$HOME/.factory/droids" "~/.factory/droids"
    sync_dir "$DEV_CONFIG/ai/commands" "$HOME/.factory/commands" "~/.factory/commands"
    sync_dir "$DEV_CONFIG/ai/hooks" "$HOME/.factory/hooks" "~/.factory/hooks"
    sync_dir "$DEV_CONFIG/ai/skills" "$HOME/.factory/skills" "~/.factory/skills"
  fi

  echo ""
  log_success "AI config sync complete!"
  echo ""
  echo "Synced (writable copies):"
  [ -z "$TOOL" ] || [ "$TOOL" = "claude" ] && [ -d "$HOME/.claude/agents" ] && echo "  • ~/.claude/ (agents, commands)"
  [ -z "$TOOL" ] || [ "$TOOL" = "factory" ] && [ -d "$HOME/.factory/droids" ] && echo "  • ~/.factory/ (droids, commands, hooks, skills)"
  echo ""
  echo "To add a new agent:"
  echo "  1. Create ~/.claude/agents/my-agent.md"
  echo "  2. Copy to $DEV_CONFIG/ai/agents/"
  echo "  3. git add, commit, push"
  echo ""
  echo "To refresh after pulling dev-config:"
  echo "  sync-ai-config --force"
''
