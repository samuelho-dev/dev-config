{ config, pkgs, lib, ... }:

{
  imports = [
    ./base-packages.nix
    ./users.nix
    ./docker.nix
    ./shell.nix
  ];

  # Global dev-config options
  options.dev-config = {
    enable = lib.mkEnableOption "dev-config NixOS module" // {
      default = true;
    };
  };

  config = lib.mkIf config.dev-config.enable {
    # This module automatically enables:
    # - Base developer packages (git, neovim, tmux, etc.)
    # - Zsh shell configuration
    # - Docker virtualization
    # - User management with Docker group access
    #
    # All components can be individually disabled via options:
    # dev-config.packages.enable = false;
    # dev-config.docker.enable = false;
    # dev-config.shell.enable = false;
  };
}
