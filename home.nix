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

    # Define secrets (matches structure in secrets/default.yaml)
    secrets = {
      # Git configuration (used by git.nix module)
      "git/userName" = {};
      "git/userEmail" = {};
      "git/signingKey" = {};

      # AI service API keys (optional, for manual use)
      "ai/anthropic-key" = {};
      "ai/openai-key" = {};
      "ai/google-ai-key" = {};
      "ai/litellm-master-key" = {};
      "ai/openrouter-key" = {};

      # NPM authentication tokens (used by npm.nix module)
      "npm/token" = {};
      "npm/github-token" = {};
    };
  };

  # Add sops and age packages for secrets management
  home.packages = [
    pkgs.sops
    pkgs.age
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

    # Kubernetes: Default kubeconfig for ArgoCD hub cluster (Hetzner)
    # Required for ArgoCD CLI in core mode (hub-spoke architecture)
    KUBECONFIG = "${config.home.homeDirectory}/.kube/config-hetzner-prod";
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

    # Enable ghostty (package installed via Homebrew on macOS)
    ghostty = {
      enable = true;
      package = null; # Not available in nixpkgs, installed via Homebrew
    };

    # Enable neovim module for Home Manager-managed config
    neovim.enable = true;

    # Enable yazi terminal file manager (with full preview support)
    yazi.enable = true;

    # Claude Code multi-profile authentication (native OAuth token management)
    claude-code.enable = true;

    # NPM authentication (tokens managed via sops-nix)
    # Add npm/token and npm/github-token to secrets/default.yaml
    npm.enable = true;

    # Biome linter/formatter (exports config for monorepo extends)
    # Generates ~/.config/biome/biome.json and GritQL patterns
    biome = {
      enable = true;
      gritql.enable = true;
    };

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
