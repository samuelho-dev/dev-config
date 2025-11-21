{
  config,
  pkgs,
  ...
}: let
  # Import machine-specific user configuration
  # NOTE: user.nix must be staged in Git (git add -f user.nix) for flake evaluation
  # but gitignored to prevent accidental commits. This is a Nix flake limitation.
  user = import ./user.nix;
in {
  # Import dev-config Home Manager module
  imports = [./modules/home-manager];

  # Home Manager needs to know your username and home directory
  # Loaded from user.nix (machine-specific, gitignored)
  home = {
    username = user.username;
    homeDirectory = user.homeDirectory;
    stateVersion = "24.05"; # Don't change this
  };

  # Enable dev-config modules (all enabled by default)
  dev-config = {
    enable = true;

    # Enable zsh module for direnv integration
    zsh = {
      enable = true;
      # Let Home Manager manage .zshrc for direnv integration
      # (Custom .zshrc from repo conflicts with Home Manager's generated config)
      zshrcSource = null;
      zprofileSource = null;
      p10kSource = null;
    };

    # Disable ghostty on macOS (not available on darwin)
    ghostty.enable = false;

    # Disable neovim module temporarily (nixpkgs compatibility)
    neovim.enable = false;

    # Enable yazi terminal file manager (with full preview support)
    yazi.enable = true;

    # Claude Code multi-profile authentication disabled (too complex to manage with Nix)
    claude-code.enable = false;

    # Optional: Disable specific programs
    # tmux.enable = false;
    # ssh.enable = false;
    # direnv.enable = false;
    # yazi.enable = false;

    # Optional: Add extra packages
    # packages.extraPackages = with pkgs; [ kubectl k9s ];
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
