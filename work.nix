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
      signing.enable = false; # No 1Password on work machine
    };
    neovim.enable = true;
    tmux = {
      enable = true;
      devpodConnect.enable = false;
    };
    ssh = {
      enable = true;
      onePasswordAgent.enable = false; # No 1Password on work machine
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
      enableAllProjectMcpServers = true;
      mcpServers = {}; # Add work-specific servers here
    };

    # Opencode (Gemini assistant)
    opencode.enable = true;

    ghostty = {
      enable = true;
      package = null; # Installed via Homebrew on macOS (not in nixpkgs)
    };
    yazi.enable = true;
    sops-env.enable = false; # No sops secrets at work
  };

  programs.home-manager.enable = true;
}
