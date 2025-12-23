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
        echo "  - biome.json and tsconfig.base.json extending ~/.config/"
        echo "  - .claude/ with agents and commands (symlinked)"
        echo "  - .opencode/ with prompts, plugins, tools (symlinked)"
        echo "  - .grit/ with patterns (symlinked)"
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
  [ -f "$BIOME_BASE" ] || log_error "Missing ~/.config/biome/biome.json. Ensure dev-config Home Manager module is activated."
  [ -f "$TSCONFIG_MONOREPO" ] || log_error "Missing ~/.config/tsconfig/tsconfig.monorepo.json. Ensure dev-config Home Manager module is activated."

  # Skip config creation if --migrate only
  if [ -z "$MIGRATE_ONLY" ]; then
    log_info "Initializing Nx workspace configs..."

    # Create biome.json (use $HOME for absolute path - biome doesn't expand ~)
    if [ -f "biome.json" ] && [ -z "$FORCE" ]; then
      log_warn "biome.json exists (use --force to overwrite)"
    else
      printf '%s\n' '{' '  "$schema": "https://biomejs.dev/schemas/2.0.6/schema.json",' "  \"extends\": [\"$HOME/.config/biome/biome.json\"]," '  "files": {' '    "include": ["./libs/**/*.ts", "./libs/**/*.tsx", "./apps/**/*.ts", "./apps/**/*.tsx"]' '  }' '}' > "biome.json"
      log_success "Created biome.json"
    fi

    # Create tsconfig.base.json (use $HOME for absolute path - tsc doesn't expand ~)
    if [ -f "tsconfig.base.json" ] && [ -z "$FORCE" ]; then
      log_warn "tsconfig.base.json exists (use --force to overwrite)"
    else
      printf '%s\n' '{' "  \"extends\": \"$HOME/.config/tsconfig/tsconfig.monorepo.json\"," '  "compilerOptions": {' '    "rootDir": ".",' '    "baseUrl": ".",' '    "paths": {}' '  },' '  "exclude": ["node_modules", "tmp", "dist"]' '}' > "tsconfig.base.json"
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

  # ============================================
  # Claude Code Configuration
  # ============================================
  if [ -d "$CLAUDE_CONFIG" ]; then
    log_info "Setting up Claude Code configuration..."

    mkdir -p .claude

    # Symlink agents directory (shared, read-only from dev-config)
    if [ -d "$CLAUDE_CONFIG/agents" ]; then
      if [ -e ".claude/agents" ] && [ ! -L ".claude/agents" ] && [ -z "$FORCE" ]; then
        log_warn ".claude/agents exists and is not a symlink (use --force to replace)"
      else
        rm -rf .claude/agents 2>/dev/null || true
        ln -sf "$CLAUDE_CONFIG/agents" .claude/agents
        log_success "Linked .claude/agents -> ~/.config/claude-code/agents"
      fi
    fi

    # Symlink commands directory (shared, read-only from dev-config)
    if [ -d "$CLAUDE_CONFIG/commands" ]; then
      if [ -e ".claude/commands" ] && [ ! -L ".claude/commands" ] && [ -z "$FORCE" ]; then
        log_warn ".claude/commands exists and is not a symlink (use --force to replace)"
      else
        rm -rf .claude/commands 2>/dev/null || true
        ln -sf "$CLAUDE_CONFIG/commands" .claude/commands
        log_success "Linked .claude/commands -> ~/.config/claude-code/commands"
      fi
    fi

    # Symlink templates directory (shared, read-only from dev-config)
    if [ -d "$CLAUDE_CONFIG/templates" ]; then
      if [ -e ".claude/templates" ] && [ ! -L ".claude/templates" ] && [ -z "$FORCE" ]; then
        log_warn ".claude/templates exists and is not a symlink (use --force to replace)"
      else
        rm -rf .claude/templates 2>/dev/null || true
        ln -sf "$CLAUDE_CONFIG/templates" .claude/templates
        log_success "Linked .claude/templates -> ~/.config/claude-code/templates"
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
    log_warn "Run 'home-manager switch --flake .' to activate dev-config module first"
  fi

  # ============================================
  # OpenCode Configuration
  # ============================================
  if [ -d "$OPENCODE_CONFIG" ]; then
    log_info "Setting up OpenCode configuration..."

    mkdir -p .opencode

    # Symlink shared directories (read-only from dev-config)
    for dir in prompts command plugin tool; do
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
    log_warn "Run 'home-manager switch --flake .' to activate dev-config module first"
  fi

  # ============================================
  # GritQL Configuration
  # ============================================
  GRIT_CONFIG="$HOME/.config/grit"
  if [ -d "$GRIT_CONFIG" ]; then
    log_info "Setting up GritQL configuration..."

    mkdir -p .grit

    # Symlink patterns directory (shared, read-only from dev-config)
    if [ -d "$GRIT_CONFIG/patterns" ]; then
      if [ -e ".grit/patterns" ] && [ ! -L ".grit/patterns" ] && [ -z "$FORCE" ]; then
        log_warn ".grit/patterns exists and is not a symlink (use --force to replace)"
      else
        rm -rf .grit/patterns 2>/dev/null || true
        ln -sf "$GRIT_CONFIG/patterns" .grit/patterns
        log_success "Linked .grit/patterns -> ~/.config/grit/patterns"
      fi
    fi

    # Create base grit.yaml if it doesn't exist
    if [ ! -f ".grit/grit.yaml" ] || [ -n "$FORCE" ]; then
      printf '%s\n' 'version: 0.0.1' 'patterns: []' > ".grit/grit.yaml"
      log_success "Created .grit/grit.yaml"
    fi
  else
    log_warn "GritQL config not found at $GRIT_CONFIG"
    log_warn "Run 'home-manager switch --flake .' to activate dev-config module first"
  fi

  echo ""
  log_success "Workspace initialized!"
  echo ""
  echo "Linting & TypeScript:"
  echo "  - biome.json extends ~/.config/biome/biome.json"
  echo "  - tsconfig.base.json extends ~/.config/tsconfig/tsconfig.monorepo.json"
  echo ""
  echo "AI Coding Tools:"
  if [ -d "$CLAUDE_CONFIG" ]; then
    echo "  - .claude/agents -> ~/.config/claude-code/agents (shared)"
    echo "  - .claude/commands -> ~/.config/claude-code/commands (shared)"
    echo "  - .claude/templates -> ~/.config/claude-code/templates (shared)"
    echo "  - .claude/settings.json (base config, extend as needed)"
  fi
  if [ -d "$OPENCODE_CONFIG" ]; then
    echo "  - .opencode/* -> ~/.config/opencode/* (prompts, plugins, tools)"
    echo "  - .opencode/opencode.json (base config, extend as needed)"
  fi
  echo ""
  echo "Code Patterns (GritQL):"
  if [ -d "$GRIT_CONFIG" ]; then
    echo "  - .grit/patterns -> ~/.config/grit/patterns (shared)"
    echo "  - .grit/grit.yaml (base config)"
  fi
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
  echo "  3. Run 'grit check .' to lint with GritQL patterns"
  echo "  4. Use 'mlg' to generate new libraries"
  echo "  5. Extend .claude/settings.json with project-specific permissions"
  echo "  6. Extend .opencode/opencode.json with project-specific settings"
''
