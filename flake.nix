{
  description = "Dev-config: Declarative development environment with OpenCode + 1Password integration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    # Support multiple systems
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

    forAllSystems = fn:
      nixpkgs.lib.genAttrs systems (system:
        fn {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true; # Allow unfree packages (1Password CLI, etc.)
          };
          inherit system;
        });
  in {
    # Binary cache configuration (Cachix)
    nixConfig = {
      extra-substituters = ["https://dev-config.cachix.org"];
      extra-trusted-public-keys = ["dev-config.cachix.org-1:PLACEHOLDER_KEY"];
    };

    # Development shells removed - all tools now in Home Manager home.packages
    # This eliminates 2-5s terminal startup overhead from expensive shellHook
    # Tools are available system-wide without shell activation

    # Formatter for pre-commit hooks
    formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

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
    packages = forAllSystems ({pkgs, ...}: {
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
          imagemagick

          # Runtimes
          nodejs_20
          bun
          python3

          # Kubernetes ecosystem
          kubectl
          kubernetes-helm
          helm-docs
          k9s
          kind
          argocd

          # Cloud providers
          awscli2
          doctl

          # Infrastructure as Code
          terraform
          terraform-docs

          # Security & Compliance
          gitleaks
          kubeseal
          sops

          # Data processing
          jq
          yq-go

          # CI/CD & Git
          gh
          act
          pre-commit

          # AI development tools
          # nodePackages.opencode-ai  # OpenCode CLI (not in nixpkgs)
          _1password-cli # 1Password CLI

          # Additional utilities
          direnv
          nix-direnv
        ];

        config = {
          Cmd = ["${pkgs.zsh}/bin/zsh"];
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
          # Core tools
          git
          zsh
          tmux
          docker
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
          imagemagick

          # Runtimes
          nodejs_20
          bun
          python3

          # Kubernetes ecosystem
          kubectl
          kubernetes-helm
          helm-docs
          k9s
          kind
          argocd

          # Cloud providers
          awscli2
          doctl

          # Infrastructure as Code
          terraform
          terraform-docs

          # Security & Compliance
          gitleaks
          kubeseal
          sops

          # Data processing
          jq
          yq-go

          # CI/CD & Git
          gh
          act
          pre-commit

          # AI development tools
          # nodePackages.opencode-ai  # Not in nixpkgs, install manually
          _1password-cli

          # Utilities
          direnv
          nix-direnv
        ];
      };
    });

    # Apps for configuration utilities
    # NOTE: Activation now handled by Home Manager (home-manager switch --flake .)
    apps = forAllSystems ({
      pkgs,
      system,
      ...
    }: {
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

    # Home Manager standalone configuration
    # Uses home.nix for user-specific configuration
    homeConfigurations = nixpkgs.lib.genAttrs systems (
      system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          modules = [./home.nix];
          extraSpecialArgs = {inputs = {dev-config = self;};};
        }
    );
  };
}
