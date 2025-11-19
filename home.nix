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

    # Optional: Disable specific programs
    # neovim.enable = false;
    # tmux.enable = false;
    # zsh.enable = false;
    # ssh.enable = false;
    # direnv.enable = false;

    # Optional: Add extra packages
    # packages.extraPackages = with pkgs; [ kubectl k9s ];
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
