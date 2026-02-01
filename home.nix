{
  config,
  pkgs,
  username,
  homeDirectory,
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

  # Add sops and age packages for secrets management
  # Note: Main dev packages come from modules/home-manager/default.nix via dev-config.packages
  home.packages = with pkgs; [
    sops
    age
  ];

  # Add user-local directories to PATH (prepended, so they take precedence)
  home.sessionPath = [
    "$HOME/.nix-profile/bin" # Home Manager packages (cachix, etc.)
    "$HOME/.local/bin" # Claude CLI, user scripts
    "$HOME/.bun/bin" # Bun package manager (if installed)
    "$HOME/Library/pnpm" # pnpm package manager (if installed)
  ];

  # Global session variables (exported to all shells)
  home.sessionVariables = {
    # SOPS key file for manual sops CLI usage
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Default editors (neovim)
    EDITOR = "nvim";
    VISUAL = "nvim";

    # Claude Code: maintain project working directory across bash sessions
    CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";

    # Kubernetes: Combined kubeconfig for all clusters
    # Includes both hetzner-prod (ArgoCD hub) and homelab contexts
    KUBECONFIG = "${config.home.homeDirectory}/.kube/config:${config.home.homeDirectory}/.kube/config-hetzner-prod:${config.home.homeDirectory}/.kube/config-homelab";
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

    # Git configuration (public info, not secrets)
    git = {
      enable = true;
      userName = "samuelho-dev";
      userEmail = "samuelho343@gmail.com";
      signing = {
        enable = true;
        # SSH public key from 1Password (visible in commits, not secret)
        # Get via: op read "op://Dev/GitHub SSH Key/public key"
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAogjYBaWb3+oWrW1LYqnJVdxjbpRJ/qVSwaGyiznvcX";
      };
    };

    # Enable ghostty (package installed via Homebrew on macOS)
    ghostty = {
      enable = true;
      package = null; # Not available in nixpkgs, installed via Homebrew
    };

    # Enable neovim module for Home Manager-managed config
    neovim.enable = true;

    # Enable yazi terminal file manager (with full preview support)
    yazi.enable = true;

    # Claude Code with native OAuth (use /login to switch accounts)
    claude-code = {
      enable = true;
      litellm.enable = false; # LiteLLM requires server-side config for OAuth pass-through
    };

    # Factory Droid integration
    factory-droid.enable = true;

    # NPM authentication (token managed via sops-nix)
    # Add npm/token to secrets/default.yaml
    npm.enable = true;

    # Biome linter/formatter (exports config for monorepo extends)
    # Generates ~/.config/biome/biome.json and GritQL patterns
    biome = {
      enable = true;
      gritql.enable = true;
    };

    # SSH configuration with 1Password agent + DevPod Tailscale proxy
    ssh.enable = true;
    ssh.devpods.enable = true;
    tmux.devpodConnect.enable = true;

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
