{
  config,
  pkgs,
  ...
}: {
  # Import dev-config Home Manager module
  imports = [./modules/home-manager];

  # Shared headless profile for DevPod and Rex; workload UID is deployment-owned.
  home = {
    username = "admin";
    homeDirectory = "/home/admin";
    stateVersion = "24.05";
  };

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
    DISABLE_AUTOUPDATER = "1"; # Keep existing Claude versions until explicit update.
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
      preferSSH = false; # Headless GitHub access uses the projected token, not a Mac SSH agent.
      extraConfig.credential."https://github.com".helper = "!gh auth git-credential";
    };
    zsh = {
      enable = true;
      # ASCII p10k config for terminals without Nerd Font support (iSH, basic SSH)
      p10kSource = ./zsh/.p10k-ascii.zsh;
    };
    mcp = {
      enable = true;
      targets.claude = true;
    };
    biome.enable = true;
    npm.enable = true;
    yazi.enable = true;
    omp.enable = true;
    pi.enable = true;
    claude-code.enable = true;
    opencode.enable = true;
    codex.enable = true;
    vercel.enable = true;

    # Disabled: macOS-specific or not needed in DevPods
    ghostty.enable = false;
    ssh.enable = false; # Tailscale handles SSH, no 1Password agent
    ssh.devpods.enable = false;
    tmux.enable = true; # Tmux inside DevPods for session management
    tmux.devpodConnect.enable = true; # Jump box: SSH into other devpods from here
    sops-env.enable = false; # No sops/1Password in containers
  };

  programs.home-manager.enable = true;
}
