{
  config,
  pkgs,
  username,
  homeDirectory,
  ...
}: {
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

  # Sops-only packages (everything else comes via dev-config.packages)
  home.packages = with pkgs; [
    sops
    age
  ];

  # SOPS key file is sops-specific, layered on top of base session vars
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # Personal-profile dev-config overrides (base.nix handles common enables)
  dev-config = {
    # Enable ghostty (package installed via Homebrew on macOS)
    ghostty = {
      enable = true;
      package = null; # Not available in nixpkgs, installed via Homebrew
    };

    # Enable yazi terminal file manager (with full preview support)
    yazi.enable = true;

    # Claude Code with native OAuth (use /login to switch accounts)
    claude-code = {
      enable = true;
      litellm.enable = false; # LiteLLM requires server-side config for OAuth pass-through

      # Global MCP servers (available in all projects)
      mcpServers = {
        # Effect documentation MCP server
        effect-docs = {
          type = "stdio";
          command = "bunx";
          args = ["--bun" "effect-mcp@latest"];
        };

        # Linear MCP server with 1Password API key
        linear-server = {
          type = "http";
          url = "https://mcp.linear.app/mcp";
          headers = {
            # Read from 1Password at activation time
            Authorization = "Bearer op://Dev/Linear/MCP_API_KEY";
          };
        };
      };
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
}
