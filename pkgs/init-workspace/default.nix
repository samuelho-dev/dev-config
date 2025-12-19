{
  lib,
  writeShellScriptBin,
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

    # Parse arguments
    FORCE=""
    while [[ $# -gt 0 ]]; do
      case $1 in
        --force) FORCE=1; shift ;;
        -h|--help)
          echo "Usage: init-workspace [--force]"
          echo ""
          echo "Creates biome.json and tsconfig.base.json extending ~/.config/ base configs."
          echo "Requires dev-config Home Manager to be activated."
          echo ""
          echo "Options:"
          echo "  --force    Overwrite existing config files"
          echo "  -h, --help Show this help message"
          exit 0
          ;;
        *) shift ;;
      esac
    done

    # Verify prerequisites
    [ -f "$BIOME_BASE" ] || log_error "Missing ~/.config/biome/biome.json. Run: home-manager switch --flake ~/Projects/dev-config"
    [ -f "$TSCONFIG_MONOREPO" ] || log_error "Missing ~/.config/tsconfig/tsconfig.monorepo.json. Run: home-manager switch --flake ~/Projects/dev-config"

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

    echo ""
    log_success "Workspace initialized!"
    echo "  - biome.json extends ~/.config/biome/biome.json"
    echo "  - tsconfig.base.json extends ~/.config/tsconfig/tsconfig.monorepo.json"
    echo ""
    echo "Next steps:"
    echo "  1. Update tsconfig.base.json paths as needed"
    echo "  2. Use 'mlg' to generate new libraries"
''
