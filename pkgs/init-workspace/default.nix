{
  lib,
  writeShellScriptBin,
  biome,
}:
writeShellScriptBin "init-workspace" ''
    set -e

    # Colors
    log_info() { echo -e "\033[0;36mℹ️  $1\033[0m"; }
    log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
    log_warn() { echo -e "\033[0;33m⚠️  $1\033[0m"; }
    log_error() { echo -e "\033[0;31m❌ $1\033[0m"; exit 1; }

    # Config paths
    BIOME_BASE="$HOME/.config/biome/biome.json"
    TSCONFIG_MONOREPO="$HOME/.config/tsconfig/tsconfig.monorepo.json"
    CLAUDE_CONFIG="$HOME/.config/claude-code"
    OPENCODE_CONFIG="$HOME/.config/opencode"
    BIOME="${biome}/bin/biome"

    # Parse arguments
    FORCE=""
    MIGRATE_ONLY=""
    while [[ $# -gt 0 ]]; do
      case $1 in
        --force) FORCE=1; shift ;;
        --migrate) MIGRATE_ONLY=1; shift ;;
        -h|--help)
          echo "Usage: init-workspace [OPTIONS]"
          echo ""
          echo "Initializes workspace with dev-config configurations:"
          echo "  - biome.json extending ~/.config/biome/"
          echo "  - tsconfig.base.json extending ~/.config/tsconfig/"
          echo "  - .claude/ with agents and commands (symlinked)"
          echo "  - .opencode/ with plugins and tools (symlinked)"
          echo "  - Migrates from eslint/prettier if present"
          echo ""
          echo "Options:"
          echo "  --force    Overwrite existing config files"
          echo "  --migrate  Only run migrations (skip config creation)"
          echo "  -h, --help Show this help message"
          exit 0
          ;;
        *) shift ;;
      esac
    done

    # Verify prerequisites
    [ -f "$BIOME_BASE" ] || log_warn "Missing ~/.config/biome/biome.json (biome extends will fail)"

    # Skip config creation if --migrate only
    if [ -z "$MIGRATE_ONLY" ]; then
      log_info "Initializing workspace configs..."

      # Create biome.json (use $HOME for absolute path - biome doesn't expand ~)
      if [ -f "biome.json" ] && [ -z "$FORCE" ]; then
        log_warn "biome.json exists (use --force to overwrite)"
      else
        cat > "biome.json" << BIOME_EOF
  {
    "\$schema": "https://biomejs.dev/schemas/2.0.6/schema.json",
    "extends": ["$HOME/.config/biome/biome.json"]
  }
  BIOME_EOF
        log_success "Created biome.json"
      fi

      # Create tsconfig.base.json if tsconfig monorepo exists
      if [ -f "$TSCONFIG_MONOREPO" ]; then
        if [ -f "tsconfig.base.json" ] && [ -z "$FORCE" ]; then
          log_warn "tsconfig.base.json exists (use --force to overwrite)"
        else
          cat > "tsconfig.base.json" << TS_EOF
  {
    "extends": "$HOME/.config/tsconfig/tsconfig.monorepo.json",
    "compilerOptions": {
      "rootDir": ".",
      "baseUrl": ".",
      "paths": {}
    },
    "exclude": ["node_modules", "tmp", "dist"]
  }
  TS_EOF
          log_success "Created tsconfig.base.json"
        fi
      fi
    fi

    # Run migrations if biome is available
    if [ -f "biome.json" ]; then
      log_info "Running migrations..."

      # Migrate from ESLint if .eslintrc* exists
      if ls .eslintrc* 1>/dev/null 2>&1 || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
        log_info "Migrating from ESLint..."
        $BIOME migrate eslint --write 2>/dev/null || log_warn "ESLint migration had warnings"
        log_success "ESLint rules migrated to biome.json"
      fi

      # Migrate from Prettier if .prettierrc* exists
      if ls .prettierrc* 1>/dev/null 2>&1 || [ -f "prettier.config.js" ] || [ -f "prettier.config.mjs" ]; then
        log_info "Migrating from Prettier..."
        $BIOME migrate prettier --write 2>/dev/null || log_warn "Prettier migration had warnings"
        log_success "Prettier settings migrated to biome.json"
      fi
    fi

    # ============================================
    # Claude Code Configuration
    # ============================================
    if [ -d "$CLAUDE_CONFIG" ]; then
      log_info "Setting up Claude Code configuration..."

      mkdir -p .claude

      # Symlink agents directory
      if [ -d "$CLAUDE_CONFIG/agents" ]; then
        if [ -e ".claude/agents" ] && [ ! -L ".claude/agents" ] && [ -z "$FORCE" ]; then
          log_warn ".claude/agents exists and is not a symlink (use --force to replace)"
        else
          rm -rf .claude/agents 2>/dev/null || true
          ln -sf "$CLAUDE_CONFIG/agents" .claude/agents
          log_success "Linked .claude/agents -> ~/.config/claude-code/agents"
        fi
      fi

      # Symlink commands directory
      if [ -d "$CLAUDE_CONFIG/commands" ]; then
        if [ -e ".claude/commands" ] && [ ! -L ".claude/commands" ] && [ -z "$FORCE" ]; then
          log_warn ".claude/commands exists and is not a symlink (use --force to replace)"
        else
          rm -rf .claude/commands 2>/dev/null || true
          ln -sf "$CLAUDE_CONFIG/commands" .claude/commands
          log_success "Linked .claude/commands -> ~/.config/claude-code/commands"
        fi
      fi

      # Copy base settings.json (project can extend)
      if [ -f "$CLAUDE_CONFIG/settings-base.json" ]; then
        if [ -f ".claude/settings.json" ] && [ -z "$FORCE" ]; then
          log_warn ".claude/settings.json exists (use --force to overwrite)"
        else
          cp "$CLAUDE_CONFIG/settings-base.json" .claude/settings.json
          log_success "Created .claude/settings.json (base config)"
        fi
      fi
    else
      log_warn "Claude Code config not found at $CLAUDE_CONFIG"
      log_warn "Run 'home-manager switch --flake <dev-config>' first"
    fi

    # ============================================
    # OpenCode Configuration
    # ============================================
    if [ -d "$OPENCODE_CONFIG" ]; then
      log_info "Setting up OpenCode configuration..."

      mkdir -p .opencode

      # Symlink shared directories
      for dir in command plugin tool; do
        if [ -d "$OPENCODE_CONFIG/$dir" ]; then
          if [ -e ".opencode/$dir" ] && [ ! -L ".opencode/$dir" ] && [ -z "$FORCE" ]; then
            log_warn ".opencode/$dir exists and is not a symlink (use --force to replace)"
          else
            rm -rf ".opencode/$dir" 2>/dev/null || true
            ln -sf "$OPENCODE_CONFIG/$dir" ".opencode/$dir"
            log_success "Linked .opencode/$dir -> ~/.config/opencode/$dir"
          fi
        fi
      done

      # Copy base opencode.json (project can extend)
      if [ -f "$OPENCODE_CONFIG/opencode-base.json" ]; then
        if [ -f ".opencode/opencode.json" ] && [ -z "$FORCE" ]; then
          log_warn ".opencode/opencode.json exists (use --force to overwrite)"
        else
          cp "$OPENCODE_CONFIG/opencode-base.json" .opencode/opencode.json
          log_success "Created .opencode/opencode.json (base config)"
        fi
      fi
    else
      log_warn "OpenCode config not found at $OPENCODE_CONFIG"
      log_warn "Run 'home-manager switch --flake <dev-config>' first"
    fi

    echo ""
    log_success "Workspace initialized!"
    echo ""
    echo "Created:"
    [ -f "biome.json" ] && echo "  - biome.json (extends ~/.config/biome/)"
    [ -f "tsconfig.base.json" ] && echo "  - tsconfig.base.json (extends ~/.config/tsconfig/)"
    [ -d ".claude" ] && echo "  - .claude/ (agents, commands, settings)"
    [ -d ".opencode" ] && echo "  - .opencode/ (command, plugin, tool)"
    echo ""
    if ls .eslintrc* 1>/dev/null 2>&1 || [ -f "eslint.config.js" ]; then
      echo "You can now remove ESLint configs:"
      echo "  rm -f .eslintrc* eslint.config.* .eslintignore"
      echo ""
    fi
    if ls .prettierrc* 1>/dev/null 2>&1 || [ -f "prettier.config.js" ]; then
      echo "You can now remove Prettier configs:"
      echo "  rm -f .prettierrc* prettier.config.* .prettierignore"
      echo ""
    fi
''
