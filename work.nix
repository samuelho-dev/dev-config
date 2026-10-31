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

    # SSH without a 1Password agent at work
    ssh = {
      enable = true;
      onePasswordAgent.enable = false;
    };

    # Work machine has no 1Password/sops, so skip the shared global MCP servers
    # (their op:// secrets won't resolve). Project .mcp.json servers still load.
    mcp = {
      enable = true;
      targets.claude = true;
      servers = {};
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
