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
    # Validate user.nix exists and load it
    userConfigPath = ./user.nix;
    userConfig =
      if builtins.pathExists userConfigPath
      then import userConfigPath
      else
        throw ''
          ERROR: user.nix not found!

          This file contains machine-specific configuration (username, home directory).

          Create it from the template:
            cp user.nix.example user.nix
            # Edit with your username and home directory
            git add -f user.nix  # Required for flake evaluation

          See docs/nix/README.md for details.
        '';

    # Support multiple systems (using nixpkgs convention)
    systems = nixpkgs.lib.systems.flakeExposed;

    forAllSystems = fn:
      nixpkgs.lib.genAttrs systems (system:
        fn {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          inherit system;
        });

    # Import centralized package definitions (DRY - single source of truth)
    getDevPackages = pkgs: let
      devPkgs = import ./pkgs {inherit pkgs;};
    in
      devPkgs.all devPkgs;
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
            "PATH=${pkgs.lib.makeBinPath (getDevPackages pkgs)}:/bin:/usr/bin"
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
      # Full development environment (40+ tools)
      default = pkgs.mkShellNoCC {
        packages = getDevPackages pkgs ++ [pkgs.home-manager];

        env = {
          EDITOR = "nvim";
          NIXPKGS_ALLOW_UNFREE = "1";
        };

        shellHook = ''
          echo "📦 Dev-config development environment"
          echo ""
          echo "Tool categories loaded:"
          echo "  • Core: git, zsh, tmux, neovim, fzf, ripgrep"
          echo "  • Runtimes: nodejs_20, bun, python3"
          echo "  • Kubernetes: kubectl, helm, k9s, kind, argocd"
          echo "  • Cloud: aws, terraform, doctl"
          echo "  • Security: gitleaks, kubeseal, sops"
          echo ""
          echo "Commands:"
          echo "  home-manager switch --flake .   # Apply configuration"
          echo "  nix flake update                 # Update dependencies"
        '';
      };

      # Minimal shell for Home Manager operations only
      minimal = pkgs.mkShellNoCC {
        packages = [pkgs.home-manager pkgs.git];
        shellHook = ''echo "📦 Minimal Home Manager environment"'';
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
      # macOS ARM64 (M1/M2/M3) - uses user.nix for username/homeDirectory
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
          inherit self;
          # Pass inputs with dev-config = self for standalone mode
          # This allows modules to use "inputs.dev-config" consistently
          inputs = inputs // {dev-config = self;};
          inherit (userConfig) username homeDirectory;
        };
      };

      # Linux x86_64 - uses user.nix for username/homeDirectory
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
          inherit self;
          # Pass inputs with dev-config = self for standalone mode
          # This allows modules to use "inputs.dev-config" consistently
          inputs = inputs // {dev-config = self;};
          inherit (userConfig) username homeDirectory;
        };
      };
    };
  };
}
