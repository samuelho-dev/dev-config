{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./programs/neovim.nix
    ./programs/tmux.nix
    ./programs/zsh.nix
    ./programs/git.nix
    ./programs/ssh.nix
    ./programs/ghostty.nix
    ./services/direnv.nix
    ./services/ai-env.nix
  ];

  # Global dev-config options for Home Manager
  options.dev-config = {
    enable =
      lib.mkEnableOption "dev-config Home Manager module"
      // {
        default = true;
      };

    # Package list for user-level installation
    packages = {
      enable =
        lib.mkEnableOption "dev-config user packages"
        // {
          default = true;
        };

      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Additional packages to install for this user";
        example = lib.literalExpression "[ pkgs.kubectl pkgs.k9s ]";
      };
    };
  };

  config = lib.mkIf config.dev-config.enable {
    # Install packages at user level
    home.packages = lib.mkIf config.dev-config.packages.enable (
      lib.mkDefault (
        with pkgs;
          [
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
            bun # JavaScript/TypeScript runtime
            python3 # Python runtime

            # Build dependencies
            gnumake
            pkg-config
            imagemagick

            # Kubernetes ecosystem (moved from devShells)
            kubectl # Kubernetes CLI
            kubernetes-helm # Helm package manager
            helm-docs # Helm documentation generator
            k9s # Terminal UI for Kubernetes
            kind # Kubernetes in Docker
            argocd # GitOps continuous delivery

            # Cloud providers (moved from devShells)
            awscli2 # AWS CLI
            doctl # DigitalOcean CLI

            # Infrastructure as Code (moved from devShells)
            terraform # Infrastructure provisioning
            terraform-docs # Terraform documentation generator

            # Security & Compliance (moved from devShells)
            gitleaks # Git secrets scanner
            kubeseal # Sealed Secrets CLI
            sops # Secrets management

            # Data processing (moved from devShells)
            jq # JSON processor
            yq-go # YAML processor (Go implementation)

            # CI/CD & Git (moved from devShells)
            gh # GitHub CLI
            act # Run GitHub Actions locally
            pre-commit # Git pre-commit hooks

            # AI development tools
            # nodePackages.opencode-ai  # OpenCode CLI (not in nixpkgs, install manually)
            _1password-cli # 1Password CLI

            # Utilities
            direnv
            nix-direnv
          ]
          ++ config.dev-config.packages.extraPackages
      )
    );

    # This module automatically enables (all can be individually disabled):
    # - Neovim with config from dev-config repo
    # - Tmux with config from dev-config repo
    # - Zsh with config from dev-config repo
    # - Ghostty with config from dev-config repo
    # - Git configuration
    # - SSH configuration with 1Password agent
    # - Direnv with nix-direnv integration
    #
    # To disable specific programs:
    # dev-config.neovim.enable = false;
    # dev-config.tmux.enable = false;
    # dev-config.ssh.enable = false;
    # dev-config.ghostty.enable = false;
    #
    # To manage configs separately (e.g., Chezmoi):
    # dev-config.neovim.configSource = null;
    # dev-config.tmux.configSource = null;
    # dev-config.zsh.zshrcSource = null;
    # dev-config.ghostty.configSource = null;
  };
}
