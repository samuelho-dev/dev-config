# Shared base profile for all dev-config Home Manager configurations.
#
# Holds values duplicated by every wrapper config (home.nix, work-home.nix,
# devpod-home.nix). Wrappers import this file alongside ../default.nix and
# layer machine-specific or sops-bound config on top.
#
# What lives here:
#   - Common session PATH and editor variables
#   - Public git identity (userName/userEmail/signing.key are not secrets — they
#     appear in every commit and the public SSH key is the signature, not auth)
#   - dev-config feature enables that every profile turns on
#
# What does NOT live here:
#   - sops/secret wiring (only home.nix has sops)
#   - SOPS_AGE_KEY_FILE (sops-only)
#   - MCP server lists (per-profile)
#   - Disable overrides (per-profile)
{lib, ...}: {
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
    "$HOME/Library/pnpm"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
  };

  dev-config = {
    enable = lib.mkDefault true;

    git = {
      enable = lib.mkDefault true;
      userName = lib.mkDefault "samuelho-dev";
      userEmail = lib.mkDefault "samuelho343@gmail.com";
      signing = {
        enable = lib.mkDefault true;
        # SSH public key from 1Password (visible in every commit, not secret)
        key = lib.mkDefault "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAogjYBaWb3+oWrW1LYqnJVdxjbpRJ/qVSwaGyiznvcX";
      };
    };

    zsh = {
      enable = lib.mkDefault true;
      # Let Home Manager fully manage .zshrc/.zprofile/.p10k for direnv integration.
      # Wrappers can override these to bring in repo-managed sources.
      zshrcSource = lib.mkDefault null;
      zprofileSource = lib.mkDefault null;
      p10kSource = lib.mkDefault null;
    };

    npm.enable = lib.mkDefault true;
    biome.enable = lib.mkDefault true;
    opencode.enable = lib.mkDefault true;
    neovim.enable = lib.mkDefault true;
  };

  programs.home-manager.enable = true;
}
