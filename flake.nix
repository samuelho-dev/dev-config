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

    workUserConfigPath = ./work-user.nix;
    workUserConfig =
      if builtins.pathExists workUserConfigPath
      then import workUserConfigPath
      else null;

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

    # Project templates
    # Usage: nix flake init -t github:samuelho-dev/dev-config
    templates.default = {
      path = ./templates/default;
      description = "Basic project with dev-config integration (Claude, Zed, GritQL)";
    };

    # DevShell hook for project-level editor configs
    # Usage in consumer flakes:
    #   shellHook = dev-config.lib.devShellHook;
    #
    # NOTE: AI configs (Claude Code, Factory Droid) are now GLOBAL.
    # They are exported to ~/.claude/ by Home Manager.
    # No project-level sync is needed - these tools automatically find global configs.
    lib.devShellHook = ''
      # ====== Setup direnv for zsh integration ======
      # Creates .envrc so direnv loads the flake into your shell
      if [ ! -f .envrc ]; then
        echo "use flake" > .envrc
        printf "✓ Created .envrc (run 'direnv allow' to enable)\n"
      fi
      # Auto-allow if direnv is available and .envrc exists but not allowed
      if command -v direnv &>/dev/null && [ -f .envrc ]; then
        if ! direnv status 2>/dev/null | grep -q "Found RC allowed true"; then
          direnv allow 2>/dev/null || true
        fi
      fi

      # ====== Editor Configs (symlink from dev-config Nix store) ======

      # Zed (full directory symlink - no relative symlinks inside)
      if [ ! -L .zed ] && [ ! -d .zed ]; then
        ln -sfn ${self}/zed .zed
        printf "✓ Linked .zed/\n"
      fi

      # GritQL (full directory symlink - no relative symlinks inside)
      if [ ! -L .grit ] && [ ! -d .grit ]; then
        ln -sfn ${self}/grit .grit
        printf "✓ Linked .grit/\n"
      fi

      # ====== Extend Configs (biome) ======

      # Biome (create extends file if missing)
      if [ ! -f biome.json ]; then
        printf '%s\n' '{' '  "$schema": "https://biomejs.dev/schemas/2.0.6/schema.json",' '  "extends": ["~/.config/biome/biome.json"]' '}' > biome.json
        printf "✓ Created biome.json (extends ~/.config/biome/)\n"
      fi
    '';

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
          ${self.lib.devShellHook}
          SENTINEL="$PWD/.direnv/.dev-config-loaded"

          if [ ! -f "$SENTINEL" ] || [ "''${DEV_CONFIG_VERBOSE:-0}" = "1" ]; then
            if [ "''${DEV_CONFIG_QUIET:-0}" != "1" ]; then
              echo "📦 Dev-config development environment"
              echo ""
              echo "Tool categories loaded:"
              echo "  • Core: git, gh, zsh, tmux, fzf, ripgrep, fd, bat, lazygit"
              echo "  • Runtimes: nodejs_20, bun"
              echo "  • Linting: biome, grit"
              echo "  • Utilities: direnv, jq, yq, gnumake"
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
    in
      {
        # Default configuration (uses username from user.nix)
        # Usage: home-manager switch --flake .
        # Defaults to aarch64-darwin (macOS ARM)
        ${userConfig.username} = mkHomeConfig "aarch64-darwin";

        # Explicit configurations for specific systems
        "samuelho-macbook" = mkHomeConfig "aarch64-darwin";
        "samuelho-linux" = mkHomeConfig "x86_64-linux";

        # DevPod configuration (headless Linux container)
        # Usage: home-manager switch --flake github:samuelho-dev/dev-config#devpod
        "devpod" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          modules = [
            ./devpod-home.nix
          ];
          extraSpecialArgs = {
            inherit self;
            inputs = inputs // {dev-config = self;};
          };
        };
      }
      // (
        if workUserConfig != null
        then {
          # Work machine configuration (separate machine, no sops secrets)
          # Usage: home-manager switch --flake .#work
          "work" = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              system = "aarch64-darwin";
              config.allowUnfree = true;
            };
            modules = [
              ./work.nix
            ];
            extraSpecialArgs = {
              inherit self;
              inputs = inputs // {dev-config = self;};
              inherit (workUserConfig) username homeDirectory;
            };
          };
        }
        else {}
      );
  };
}
