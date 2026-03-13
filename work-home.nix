{
  config,
  pkgs,
  username,
  homeDirectory,
  ...
}: {
  # Import dev-config Home Manager module
  imports = [./modules/home-manager];

  home = {
    username = username;
    homeDirectory = homeDirectory;
    stateVersion = "24.05";
  };

  # Minimal session path
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
    "$HOME/Library/pnpm"
  ];

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
  };

  # NO sops-nix secrets at work

  dev-config = {
    enable = true;

    # Core
    zsh = {
      enable = true;
      zshrcSource = null;
      zprofileSource = null;
      p10kSource = null;
    };
    git = {
      enable = true;
      userName = "samuelho-dev";
      userEmail = "samuelho343@gmail.com";
      signing = {
        enable = true;
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAogjYBaWb3+oWrW1LYqnJVdxjbpRJ/qVSwaGyiznvcX";
      };
    };
    neovim.enable = true;
    tmux = {
      enable = true;
      devpodConnect.enable = false;
    };
    ssh = {
      enable = true;
      devpods.enable = false;
    };

    # Dev tooling
    biome = {
      enable = true;
      gritql.enable = true;
    };
    npm.enable = true;

    # Claude Code — work MCP servers, explicit trust only
    claude-code = {
      enable = true;
      litellm.enable = false;
      enableAllProjectMcpServers = false;
      mcpServers = {}; # Add work-specific servers here
    };

    # Opencode (Gemini assistant)
    opencode.enable = true;

    # Disabled at work
    ghostty.enable = false;
    yazi.enable = false;
    sops-env.enable = false;
  };

  programs.home-manager.enable = true;
}
