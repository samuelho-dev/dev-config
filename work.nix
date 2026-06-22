{
  username,
  homeDirectory,
  ...
}: {
  imports = [
    ./modules/home-manager
    ./modules/home-manager/profiles/base.nix
  ];

  home = {
    username = username;
    homeDirectory = homeDirectory;
    stateVersion = "24.05";
  };


  # NO sops-nix secrets at work

  # Work-profile dev-config overrides (base.nix handles common enables)
  dev-config = {
    # Work machine has no 1Password — disable git signing and SSH agent
    git.signing.enable = false;

    # Tmux: enabled, but no DevPod jump-box behavior at work
    tmux = {
      enable = true;
      devpodConnect.enable = false;
    };

    # SSH: no 1Password agent at work, no DevPod proxy
    ssh = {
      enable = true;
      onePasswordAgent.enable = false;
      devpods.enable = false;
    };

    # Claude Code — trust all project MCP servers at work
    claude-code = {
      enable = true;
      litellm.enable = false;
      enableAllProjectMcpServers = true;
      mcpServers = {}; # Add work-specific servers here
    };

    # Ghostty installed via Homebrew on macOS (not in nixpkgs)
    ghostty = {
      enable = true;
      package = null;
    };

    yazi.enable = true;

    # No sops secrets at work
    sops-env.enable = false;
  };
}
