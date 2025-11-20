{ config, pkgs, ... }:

{
  # Import dev-config Home Manager module
  imports = [ ./modules/home-manager ];

  # Home Manager needs to know your username and home directory
  # These will be set automatically by the install script
  home = {
    username = builtins.getEnv "USER";
    homeDirectory = builtins.getEnv "HOME";
    stateVersion = "24.05";  # Don't change this
  };

  # Enable dev-config modules (all enabled by default)
  dev-config = {
    enable = true;

    # Disable zsh module temporarily (using existing dotfiles)
    zsh.enable = false;

    # Disable ghostty on macOS (not available on darwin)
    ghostty.enable = false;

    # Disable neovim module temporarily (nixpkgs compatibility)
    neovim.enable = false;

    # Optional: Disable specific programs
    # tmux.enable = false;
    # ssh.enable = false;
    # direnv.enable = false;

    # Optional: Add extra packages
    # packages.extraPackages = with pkgs; [ kubectl k9s ];
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
