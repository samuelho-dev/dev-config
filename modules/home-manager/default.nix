{ config, pkgs, lib, inputs, ... }:

{
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
    enable = lib.mkEnableOption "dev-config Home Manager module" // {
      default = true;
    };

    # Package list for user-level installation
    packages = {
      enable = lib.mkEnableOption "dev-config user packages" // {
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

          # Build dependencies
          gnumake
          pkg-config
          nodejs_20
          imagemagick

          # AI development tools
          # nodePackages.opencode-ai  # OpenCode CLI (not in nixpkgs, install manually)
          _1password-cli             # 1Password CLI
          jq                         # JSON parsing

          # Additional utilities
          gh          # GitHub CLI
          direnv
          nix-direnv
          pre-commit
        ] ++ config.dev-config.packages.extraPackages
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
