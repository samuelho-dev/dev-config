{
  config,
  lib,
  pkgs,
  username,
  homeDirectory,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in {
  imports = [
    ./modules/home-manager
    ./modules/home-manager/profiles/base.nix
  ];

  # Home Manager needs to know your username and home directory
  # Passed via extraSpecialArgs from flake.nix
  home = {
    username = username;
    homeDirectory = homeDirectory;
    stateVersion = "24.05"; # Don't change this
  };

  # Configure sops-nix for secrets management (personal Mac only: the
  # headless Rex pod has no 1Password/sops access; the sops-nix module is
  # imported everywhere but stays inert with no secrets).
  sops = lib.mkIf isDarwin {
    defaultSopsFile = ./secrets/default.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # macOS-compatible paths (Home Manager handles these automatically on macOS)
    # On macOS, secrets are placed in XDG_RUNTIME_DIR or Nix store
    defaultSymlinkPath = "${config.home.homeDirectory}/.local/share/sops-nix/secrets";
    defaultSecretsMountPoint = "${config.home.homeDirectory}/.local/share/sops-nix/secrets.d";

    # Note: keySeparator option removed in newer sops-nix (/ is now default)

    # Define secrets (matches structure in secrets/default.yaml)
    # NOTE: Only OP service account token is stored in sops-nix
    # All other secrets (git config, AI keys) are fetched from 1Password at runtime
    secrets = {
      # 1Password service account token (enables prompt-free `op` CLI)
      # Used by activation scripts to fetch git config and AI keys from 1Password
      "op/service_account_token" = {};
    };
  };

  # Sops-only packages (everything else comes via dev-config.packages)
  home.packages = lib.mkIf isDarwin (with pkgs; [
    sops
    age
  ]);

  # SOPS key file is sops-specific, layered on top of base session vars
  home.sessionVariables = lib.mkIf isDarwin {
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # Hermes is tagged; Rex must trust callers admitted by the Tailnet ACL.
  targets.darwin.defaults = lib.mkIf isDarwin {
    "com.superlogical.rex"."rex.server.tailnet-allow-tailnet-members" = true;
  };

  # Machine-specific dev-config overrides (base.nix handles common enables)
  dev-config = {
    # Ghostty via Homebrew on macOS; not provisioned in the headless pod.
    ghostty = {
      enable = isDarwin;
      package = null;
    };

    git = {
      enable = true;
      # 1Password SSH signing only where the agent exists.
      signing.enable = isDarwin;
      # Headless GitHub access uses the projected token, never SSH URLs.
      preferSSH = isDarwin;
      extraConfig = lib.mkIf isLinux {
        credential."https://github.com".helper = "!gh auth git-credential";
        url."https://github.com/".insteadOf = ["git@github.com:" "ssh://git@github.com/"];
      };
    };

    # Single repo-managed Nerd Font theme for every profile.
    zsh = {
      enable = true;
      p10kSource = ./zsh/.p10k.zsh;
    };

    mcp = {
      enable = true;
      targets.claude = true;
    };

    # 1Password-backed SSH agent and sops loading only on the personal Mac.
    ssh.enable = isDarwin;
    sops-env.enable = isDarwin;

    yazi.enable = true;
    omp.hindsight.enable = true;
    rex-worktrees.enable = true;
    rex-hermes.enable = isDarwin;

    # Optional: Add extra packages
    # packages.extraPackages = with pkgs; [ kubectl k9s ];
  };
}
