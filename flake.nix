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

    getDevPackages = pkgs: let
      devPkgs = import ./pkgs {inherit pkgs;};
    in
      devPkgs.all devPkgs;
  in {
    formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

    nixosModules.default = import ./modules/nixos;
    homeManagerModules.default = import ./modules/home-manager;

    packages = forAllSystems ({pkgs, ...}: {
      default = pkgs.buildEnv {
        name = "dev-config-packages";
        paths = getDevPackages pkgs;
      };
    });

    devShells = forAllSystems ({pkgs, ...}: {
      default = pkgs.mkShellNoCC {
        packages = getDevPackages pkgs ++ [pkgs.home-manager];

        env = {
          EDITOR = "nvim";
          NIXPKGS_ALLOW_UNFREE = "1";
        };

        shellHook = ''
          SENTINEL="$PWD/.direnv/.dev-config-loaded"

          if [ ! -f "$SENTINEL" ] || [ "''${DEV_CONFIG_VERBOSE:-0}" = "1" ]; then
            if [ "''${DEV_CONFIG_QUIET:-0}" != "1" ]; then
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
            fi

            mkdir -p "$PWD/.direnv" 2>/dev/null || true
            touch "$SENTINEL" 2>/dev/null || true
          fi
        '';
      };

      minimal = pkgs.mkShellNoCC {
        packages = [pkgs.home-manager pkgs.git];
        shellHook = ''echo "📦 Minimal Home Manager environment"'';
      };
    });

    apps = forAllSystems ({
      pkgs,
      system,
      ...
    }: {
      set-shell = {
        type = "app";
        program = toString (pkgs.writeShellScript "set-shell" ''
          ZSH_PATH="${pkgs.zsh}/bin/zsh"

          if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
          fi

          sudo chsh -s "$ZSH_PATH" "$USER"
          echo "✅ Default shell set to zsh (restart terminal to apply)"
        '');
      };
    });

    homeConfigurations = let
      mkHomeConfig = system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          modules = [
            ./home.nix
            inputs.sops-nix.homeManagerModules.sops
          ];
          extraSpecialArgs = {
            inherit self;
            inputs = inputs // {dev-config = self;};
            inherit (userConfig) username homeDirectory;
          };
        };
    in {
      # Default configuration (uses username from user.nix)
      # Usage: home-manager switch --flake .
      # Defaults to aarch64-darwin (macOS ARM)
      ${userConfig.username} = mkHomeConfig "aarch64-darwin";

      # Explicit configurations for specific systems
      "samuelho-macbook" = mkHomeConfig "aarch64-darwin";
      "samuelho-linux" = mkHomeConfig "x86_64-linux";
    };
  };
}
