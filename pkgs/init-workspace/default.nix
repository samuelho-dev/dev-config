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
            echo "Creates biome.json and tsconfig.base.json extending ~/.config/ base configs."
            echo "Also migrates from eslint/prettier and runs biome schema migrations."
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
      [ -f "$BIOME_BASE" ] || log_error "Missing ~/.config/biome/biome.json. Ensure dev-config Home Manager module is activated."
      [ -f "$TSCONFIG_MONOREPO" ] || log_error "Missing ~/.config/tsconfig/tsconfig.monorepo.json. Ensure dev-config Home Manager module is activated."

      # Skip config creation if --migrate only
      if [ -z "$MIGRATE_ONLY" ]; then
        log_info "Initializing Nx workspace configs..."

        # Create biome.json
        if [ -f "biome.json" ] && [ -z "$FORCE" ]; then
          log_warn "biome.json exists (use --force to overwrite)"
        else
          cat > "biome.json" << 'BIOME_EOF'
  {
    "$schema": "https://biomejs.dev/schemas/2.0.6/schema.json",
    "extends": ["~/.config/biome/biome.json"],
    "files": {
      "include": ["./libs/**/*.ts", "./libs/**/*.tsx", "./apps/**/*.ts", "./apps/**/*.tsx"]
    }
  }
  BIOME_EOF
          log_success "Created biome.json"
        fi

        # Create tsconfig.base.json
        if [ -f "tsconfig.base.json" ] && [ -z "$FORCE" ]; then
          log_warn "tsconfig.base.json exists (use --force to overwrite)"
        else
          cat > "tsconfig.base.json" << 'TS_EOF'
  {
    "extends": "~/.config/tsconfig/tsconfig.monorepo.json",
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

      # Run migrations
      log_info "Running migrations..."

      # Migrate from ESLint if .eslintrc* exists
      if ls .eslintrc* 1>/dev/null 2>&1 || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
        log_info "Migrating from ESLint..."
        $BIOME migrate eslint --write 2>/dev/null || log_warn "ESLint migration had warnings (check output)"
        log_success "ESLint rules migrated to biome.json"
      fi

      # Migrate from Prettier if .prettierrc* exists
      if ls .prettierrc* 1>/dev/null 2>&1 || [ -f "prettier.config.js" ] || [ -f "prettier.config.mjs" ]; then
        log_info "Migrating from Prettier..."
        $BIOME migrate prettier --write 2>/dev/null || log_warn "Prettier migration had warnings (check output)"
        log_success "Prettier settings migrated to biome.json"
      fi

      # Run biome schema migration (updates config to latest schema version)
      if [ -f "biome.json" ]; then
        log_info "Updating biome.json schema..."
        $BIOME migrate --write 2>/dev/null || log_warn "Schema migration had warnings"
        log_success "biome.json schema updated"
      fi

      echo ""
      log_success "Workspace initialized!"
      echo "  - biome.json extends ~/.config/biome/biome.json"
      echo "  - tsconfig.base.json extends ~/.config/tsconfig/tsconfig.monorepo.json"
      echo ""
      if ls .eslintrc* 1>/dev/null 2>&1 || [ -f "eslint.config.js" ]; then
        echo "  ESLint configs can now be removed:"
        echo "    rm -f .eslintrc* eslint.config.* .eslintignore"
        echo ""
      fi
      if ls .prettierrc* 1>/dev/null 2>&1 || [ -f "prettier.config.js" ]; then
        echo "  Prettier configs can now be removed:"
        echo "    rm -f .prettierrc* prettier.config.* .prettierignore"
        echo ""
      fi
      echo "Next steps:"
      echo "  1. Update tsconfig.base.json paths as needed"
      echo "  2. Run 'biome check --write' to format/lint codebase"
      echo "  3. Use 'mlg' to generate new libraries"
''
