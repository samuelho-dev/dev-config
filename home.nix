{
  config,
  pkgs,
  username ? builtins.getEnv "USER",
  homeDirectory ? builtins.getEnv "HOME",
  ...
}: {
  # Import dev-config Home Manager module
  imports = [./modules/home-manager];

  # Home Manager needs to know your username and home directory
  # Passed via extraSpecialArgs from flake.nix
  home = {
    username = username;
    homeDirectory = homeDirectory;
    stateVersion = "24.05"; # Don't change this
  };

  # Configure sops-nix for secrets management
  sops = {
    defaultSopsFile = ./secrets/default.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # macOS-compatible paths (Home Manager handles these automatically on macOS)
    # On macOS, secrets are placed in XDG_RUNTIME_DIR or Nix store
    defaultSymlinkPath = "${config.home.homeDirectory}/.local/share/sops-nix/secrets";
    defaultSecretsMountPoint = "${config.home.homeDirectory}/.local/share/sops-nix/secrets.d";

    # Define secrets (create secrets/default.yaml with sops)
    secrets = {
      "git/userName" = {};
      "git/userEmail" = {};
      "git/signingKey" = {};
      "claude/oauth-token" = {};
      "ai/anthropic-key" = {};
      "ai/openai-key" = {};
      "ai/google-ai-key" = {};
      "ai/litellm-master-key" = {};
    };
  };

  # Add sops and age packages for secrets management
  home.packages = with pkgs; [
    sops
    age
  ];

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
