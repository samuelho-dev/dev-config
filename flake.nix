{
  description = "Dev-config: Declarative development environment with OpenCode + 1Password integration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      # Support multiple systems
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      forAllSystems = fn: nixpkgs.lib.genAttrs systems (system: fn {
        pkgs = import nixpkgs { inherit system; };
        inherit system;
      });
    in
    {
      # Binary cache configuration (Cachix)
      nixConfig = {
        extra-substituters = [ "https://dev-config.cachix.org" ];
        extra-trusted-public-keys = [ "dev-config.cachix.org-1:PLACEHOLDER_KEY" ];
      };

      # Development shells
      devShells = forAllSystems ({ pkgs, ... }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # Core tools
            git
            zsh
            tmux
            docker

            # Development tools
            neovim
            fzf
            ripgrep
            fd
            bat
            lazygit
            gitmux

            # Build dependencies
            gnumake
            pkg-config
            nodejs_20
            imagemagick

            # AI Development Tools
            nodePackages.opencode-ai  # OpenCode CLI
            _1password                 # 1Password CLI
            jq                         # JSON parsing for op output

            # Utilities
            gh  # GitHub CLI (optional but recommended)
            direnv
            nix-direnv
            pre-commit
          ];

          shellHook = ''
            echo "🤖 AI Development Environment"
            echo "  Neovim: $(nvim --version 2>/dev/null | head -n1)"
            echo "  Tmux: $(tmux -V 2>/dev/null)"
            echo "  OpenCode: $(opencode --version 2>/dev/null || echo 'not found')"
            echo "  1Password CLI: $(op --version 2>/dev/null || echo 'not found')"
            echo ""

            # Load AI credentials from 1Password
            if command -v op &>/dev/null && command -v jq &>/dev/null; then
              # Check if authenticated
              if op account get &>/dev/null 2>&1; then
                # Fetch all AI tokens from "Dev" vault, "ai" item
                source ${./scripts/load-ai-credentials.sh}
              else
                echo "⚠️  Not signed in to 1Password. Run: op signin"
              fi
            fi

            # Install pre-commit hooks if not already installed
            if [ ! -f .git/hooks/pre-commit ]; then
              echo "🔧 Installing pre-commit hooks..."
              ${pkgs.pre-commit}/bin/pre-commit install
            fi
          '';
        };
      });

      # Export reusable modules for ai-dev-env integration
      nixosModules = {
        # Default module (recommended)
        default = import ./modules/nixos;

        # Legacy alias for backwards compatibility
        dev-config = import ./modules/nixos;
      };

      homeManagerModules = {
        # Default module (recommended)
        default = import ./modules/home-manager;

        # Legacy alias for backwards compatibility
        dev-config = import ./modules/home-manager;
      };

      # DevPod container image (pre-built for ai-dev-env)
      packages = forAllSystems ({ pkgs, ... }: {
        # Pre-built Docker image with all dev tools
        devpod-image = pkgs.dockerTools.buildLayeredImage {
          name = "ghcr.io/samuelho-dev/dev-config-devpod";
          tag = "latest";

          # All dev-config tools pre-installed
          contents = with pkgs; [
            # Base system utilities
            bashInteractive
            coreutils
            gnugrep
            gnused
            findutils
            which

            # Core development tools
            git
            zsh
            tmux
            docker
            neovim

            # CLI utilities
            fzf
            ripgrep
            fd
            bat
            lazygit
            gitmux

            # Build dependencies
            gnumake
            pkg-config
            nodejs_20
            imagemagick

            # AI development tools
            nodePackages.opencode-ai  # OpenCode CLI
            _1password                 # 1Password CLI
            jq                         # JSON parsing

            # Additional utilities
            gh          # GitHub CLI
            direnv
            nix-direnv
            pre-commit
          ];

          config = {
            Cmd = [ "${pkgs.zsh}/bin/zsh" ];
            Env = [
              "PATH=/bin:/usr/bin"
              "HOME=/home/vscode"
              "SHELL=${pkgs.zsh}/bin/zsh"
            ];
            User = "vscode";
            WorkingDir = "/workspace";
          };

          # Create vscode user in image
          extraCommands = ''
            mkdir -p etc home/vscode workspace tmp
            echo "vscode:x:1000:1000::/home/vscode:${pkgs.zsh}/bin/zsh" > etc/passwd
            echo "vscode:x:1000:" > etc/group
            chmod 1777 tmp
          '';

          # Layer optimization (modern Docker supports 128 layers)
          maxLayers = 100;
        };

        # Convenience: buildEnv for local development (not for containers)
        default = pkgs.buildEnv {
          name = "dev-config-packages";
          paths = with pkgs; [
            git zsh tmux docker neovim
            fzf ripgrep fd bat lazygit gitmux
            gnumake pkg-config nodejs_20 imagemagick
            nodePackages.opencode-ai _1password jq
            gh direnv nix-direnv pre-commit
          ];
        };
      });

      # Apps for activation and configuration
      apps = forAllSystems ({ pkgs, system, ... }: {
        # Main activation script (creates symlinks using existing lib/common.sh)
        activate = {
          type = "app";
          program = toString (pkgs.writeShellScript "activate" ''
            set -e

            # Colors
            CYAN='\033[0;36m'
            GREEN='\033[0;32m'
            NC='\033[0m'

            log_info() { echo -e "''${CYAN}ℹ️  $1''${NC}" >&2; }
            log_success() { echo -e "''${GREEN}✅ $1''${NC}" >&2; }

            # Source existing library functions (reuse proven logic!)
            source ${./scripts/lib/common.sh}
            source ${./scripts/lib/paths.sh}

            TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

            log_info "Creating symlinks with backups..."

            # Neovim
            create_symlink "$REPO_NVIM" "$HOME_NVIM" "$TIMESTAMP"

            # Tmux
            create_symlink "$REPO_TMUX_CONF" "$HOME_TMUX_CONF" "$TIMESTAMP"
            create_symlink "$REPO_GITMUX_CONF" "$HOME_GITMUX_CONF" "$TIMESTAMP"

            # Zsh
            create_symlink "$REPO_ZSHRC" "$HOME_ZSHRC" "$TIMESTAMP"
            create_symlink "$REPO_ZPROFILE" "$HOME_ZPROFILE" "$TIMESTAMP"
            create_symlink "$REPO_P10K" "$HOME_P10K" "$TIMESTAMP"

            # Ghostty (platform-specific)
            create_symlink "$REPO_GHOSTTY_CONFIG" "$HOME_GHOSTTY_CONFIG" "$TIMESTAMP"

            # Create .zshrc.local if missing
            if [ ! -f "$HOME_ZSHRC_LOCAL" ]; then
              log_info "Creating .zshrc.local template..."
              cat > "$HOME_ZSHRC_LOCAL" <<'EOF'
# Machine-specific zsh configuration (gitignored)
# Add your custom PATH, aliases, secrets here

# Example: Docker aliases (uncomment to use)
# alias d='docker'
# alias dc='docker-compose'
# alias dcu='docker-compose up'
# alias dcd='docker-compose down'

# Example: Custom PATH
# export PATH="$HOME/custom/bin:$PATH"
EOF
              log_success "Created .zshrc.local"
            fi

            # Install Oh My Zsh if missing
            if [ ! -d "$OH_MY_ZSH_DIR" ]; then
              log_info "Installing Oh My Zsh..."
              RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
              log_success "Oh My Zsh installed"
            fi

            # Install Powerlevel10k theme
            if [ ! -d "$P10K_THEME_DIR" ]; then
              log_info "Installing Powerlevel10k..."
              git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_THEME_DIR"
              log_success "Powerlevel10k installed"
            fi

            # Install zsh-autosuggestions
            if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]; then
              log_info "Installing zsh-autosuggestions..."
              git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
              log_success "zsh-autosuggestions installed"
            fi

            # Install TPM
            if [ ! -d "$TPM_DIR" ]; then
              log_info "Installing TPM..."
              git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
              log_success "TPM installed"
            fi

            # Auto-install Neovim plugins
            if command -v nvim &> /dev/null; then
              log_info "Installing Neovim plugins (headless)..."
              nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
              log_success "Neovim plugins installed"
            fi

            # Auto-install tmux plugins
            if [ -f "$TPM_DIR/scripts/install_plugins.sh" ]; then
              log_info "Installing tmux plugins..."
              bash "$TPM_DIR/scripts/install_plugins.sh" &>/dev/null
              log_success "tmux plugins installed"
            fi

            log_success "Activation complete!"
            echo ""
            echo "Next steps:"
            echo "  1. Restart your terminal (or run: exec zsh)"
            echo "  2. Sign in to 1Password: op signin"
            echo "  3. AI credentials will auto-load in dev-config directory"
          '');
        };

        # Set default shell to zsh
        set-shell = {
          type = "app";
          program = toString (pkgs.writeShellScript "set-shell" ''
            ZSH_PATH="${pkgs.zsh}/bin/zsh"

            # Add zsh to /etc/shells if not present
            if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
              echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
            fi

            # Change shell
            sudo chsh -s "$ZSH_PATH" "$USER"
            echo "✅ Default shell set to zsh (restart terminal to apply)"
          '');
        };

        # Configure OpenCode with 1Password
        setup-opencode = {
          type = "app";
          program = toString (pkgs.writeShellScript "setup-opencode" ''
            set -e

            CYAN='\033[0;36m'
            GREEN='\033[0;32m'
            YELLOW='\033[1;33m'
            NC='\033[0m'

            log_info() { echo -e "''${CYAN}ℹ️  $1''${NC}" >&2; }
            log_success() { echo -e "''${GREEN}✅ $1''${NC}" >&2; }
            log_warn() { echo -e "''${YELLOW}⚠️  $1''${NC}" >&2; }

            # Check if 1Password CLI is installed
            if ! command -v op &>/dev/null; then
              log_warn "1Password CLI not found. It should be installed via Nix."
              exit 1
            fi

            # Check if signed in
            if ! op account get &>/dev/null 2>&1; then
              log_info "Signing in to 1Password..."
              op signin
            fi

            # Fetch AI credentials
            log_info "Fetching AI credentials from 1Password (Dev vault, ai item)..."

            # Test if item exists
            if ! op item get "ai" --vault "Dev" &>/dev/null 2>&1; then
              log_warn "Could not find 'ai' item in 'Dev' vault"
              echo ""
              echo "Please create a 1Password item with the following structure:"
              echo "  Vault: Dev"
              echo "  Item Name: ai"
              echo "  Fields:"
              echo "    - ANTHROPIC_API_KEY (password)"
              echo "    - OPENAI_API_KEY (password)"
              echo "    - GOOGLE_AI_API_KEY (password)"
              echo ""
              echo "See docs/nix/05-1password-setup.md for details"
              exit 1
            fi

            # Create OpenCode config directory
            mkdir -p ~/.config/opencode

            log_success "OpenCode configured!"
            echo ""
            echo "To use OpenCode with auto-loaded credentials:"
            echo "  1. Run: source ~/.config/opencode/.env (or add to .zshrc.local)"
            echo "  2. Or use: op run -- opencode (auto-injects credentials)"
            echo ""
            echo "Credentials are loaded from 1Password Dev/ai item"
          '');
        };
      });
    };
}
