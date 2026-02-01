{
  config,
  pkgs,
  ...
}: {
  # Import dev-config Home Manager module
  imports = [./modules/home-manager];

  # DevPod user configuration (coder user in Kubernetes container)
  home = {
    username = "coder";
    homeDirectory = "/home/coder";
    stateVersion = "24.05";
  };

  # Minimal session path for containers
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
  ];

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
  };

  # Enable dev-config with DevPod-appropriate modules
  dev-config = {
    enable = true;

    # Core tools (work in headless Linux containers)
    neovim.enable = true;
    git = {
      enable = true;
      userName = "samuelho-dev";
      userEmail = "samuelho343@gmail.com";
      signing.enable = false; # No 1Password SSH agent in containers
    };
    zsh = {
      enable = true;
      zshrcSource = null;
      zprofileSource = null;
      p10kSource = null;
    };
    claude-code = {
      enable = true;
      litellm.enable = false;
    };
    biome = {
      enable = true;
      gritql.enable = true;
    };
    npm.enable = true;
    yazi.enable = true;

    # Disabled: macOS-specific or not needed in DevPods
    ghostty.enable = false;
    ssh.enable = false; # Tailscale handles SSH, no 1Password agent
    ssh.devpods.enable = false;
    tmux.enable = false; # No tmux inside DevPods (tmux is on the client)
    tmux.devpodConnect.enable = false;
    factory-droid.enable = false;
    sops-env.enable = false; # No sops/1Password in containers
  };

  programs.home-manager.enable = true;
}
