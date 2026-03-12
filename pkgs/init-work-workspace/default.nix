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
          echo "  - Migrates from eslint/prettier if present"
          echo ""
          echo "Note: AI configs (Claude Code, Factory Droid) are now GLOBAL."
          echo "      They are managed in ~/.claude/ and ~/.factory/"
          echo "      Use 'sync-ai-config' to refresh them from dev-config."
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

    echo ""
    log_success "Workspace initialized!"
    echo ""
    echo "Created:"
    [ -f "biome.json" ] && echo "  - biome.json (extends ~/.config/biome/)"
    [ -f "tsconfig.base.json" ] && echo "  - tsconfig.base.json (extends ~/.config/tsconfig/)"
    echo ""
    echo "Note: AI configs are managed globally via Home Manager:"
    echo "  - ~/.claude/ (agents, commands)"
    echo "  - ~/.factory/ (droids, commands, hooks, skills)"
    echo ""
    echo "To refresh AI configs: sync-ai-config --force"
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
