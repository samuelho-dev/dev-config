{ config, pkgs, lib, ... }:

{
  options.dev-config.packages = {
    enable = lib.mkEnableOption "dev-config base packages" // {
      default = true;
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages to install beyond the base set";
      example = lib.literalExpression "[ pkgs.kubectl pkgs.k9s ]";
    };
  };

  config = lib.mkIf config.dev-config.packages.enable {
    environment.systemPackages = lib.mkDefault (
      with pkgs; [
        # Core system utilities
        git
        zsh
        tmux
        docker

        # Text editors and IDE tools
        neovim

        # CLI utilities for fuzzy finding and search
        fzf
        ripgrep
        fd
        bat

        # Git tools
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
        jq                         # JSON parsing for op output

        # Additional utilities
        gh          # GitHub CLI (for Octo.nvim PR/issue management)
        direnv      # Auto-activate environments
        nix-direnv  # Nix integration for direnv
        pre-commit  # Git hooks framework
      ] ++ config.dev-config.packages.extraPackages
    );
  };
}
