{
  description = "Dev-config: Declarative development environment with sops-nix secrets management";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    ...
  }: let
    # Support multiple systems
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

    forAllSystems = fn:
      nixpkgs.lib.genAttrs systems (system:
        fn {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          inherit system;
        });

    # Shared package list (DRY - defined once, used everywhere)
    getDevPackages = pkgs:
      with pkgs; [
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

        # Runtimes
        nodejs_20
        bun
        python3

        # Build dependencies
        gnumake
        pkg-config
        imagemagick

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
        _1password-cli

        # Utilities
        direnv
        nix-direnv
      ];
  in {
    # Formatter for pre-commit hooks
    formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

    # Export reusable modules for ai-dev-env integration
    nixosModules.default = import ./modules/nixos;
    homeManagerModules.default = import ./modules/home-manager;

    # DevPod container image (pre-built for ai-dev-env)
    packages = forAllSystems ({pkgs, ...}: {
      # Pre-built Docker image with all dev tools
      devpod-image = pkgs.dockerTools.buildLayeredImage {
        name = "ghcr.io/samuelho-dev/dev-config-devpod";
        tag = "latest";

        # All dev-config tools pre-installed
        contents =
          [
            # Base system utilities (container-specific)
            pkgs.bashInteractive
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.findutils
            pkgs.which
          ]
          ++ (getDevPackages pkgs);

        config = {
          Cmd = ["${pkgs.zsh}/bin/zsh"];
          Env = [
            "PATH=${nixpkgs.lib.makeBinPath (getDevPackages pkgs)}:/bin:/usr/bin"
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

      # Convenience: buildEnv for local development
      default = pkgs.buildEnv {
        name = "dev-config-packages";
        paths = getDevPackages pkgs;
      };
    });

    # Development shells for quick environment setup
    devShells = forAllSystems ({pkgs, ...}: {
      default = pkgs.mkShell {
        buildInputs = [pkgs.home-manager];
        shellHook = ''
          echo "📦 Dev-config development environment"
          echo ""
          echo "Available commands:"
          echo "  home-manager switch --flake . - Apply configuration"
          echo "  nix flake update                - Update all inputs"
          echo "  nix flake check                 - Validate configuration"
          echo ""
        '';
      };
    });

    # Apps for configuration utilities
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
    });

    # Home Manager configurations (machine-specific)
    homeConfigurations = {
      # macOS ARM64 (M1/M2/M3)
      "samuelho-macbook" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ./home.nix
          inputs.sops-nix.homeManagerModules.sops
        ];
        extraSpecialArgs = {
          inherit self inputs;
          username = "samuelho";
          homeDirectory = "/Users/samuelho";
        };
      };

      # Linux x86_64
      "samuelho-linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ./home.nix
          inputs.sops-nix.homeManagerModules.sops
        ];
        extraSpecialArgs = {
          inherit self inputs;
          username = "samuelho";
          homeDirectory = "/home/samuelho";
        };
      };
    };
  };
}
