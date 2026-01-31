{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dev-config.ssh = {
    enable = lib.mkEnableOption "SSH configuration with 1Password agent";

    devpods = {
      enable = lib.mkEnableOption "DevPod SSH configuration via Tailscale";

      user = lib.mkOption {
        type = lib.types.str;
        default = "coder";
        description = "Default SSH user for DevPod connections";
      };
    };

    onePasswordAgent = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true; # Enable 1Password SSH agent
        description = "Use 1Password SSH agent for authentication and signing";
      };

      socketPath = lib.mkOption {
        type = lib.types.str;
        default =
          if pkgs.stdenv.isDarwin
          then "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          else "~/.1password/agent.sock";
        description = ''
          Path to 1Password SSH agent socket.
          macOS: ~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
          Linux: ~/.1password/agent.sock
        '';
      };
    };
  };

  config = lib.mkIf config.dev-config.ssh.enable {
    programs.ssh = {
      enable = true;

      # Use 1Password SSH agent for all connections
      extraConfig = lib.mkIf config.dev-config.ssh.onePasswordAgent.enable ''
        # 1Password SSH Agent Integration
        # Keys stored securely in 1Password, accessed via biometric unlock
        Host *
          IdentityAgent "${config.dev-config.ssh.onePasswordAgent.socketPath}"
      '';

      # GitHub-specific configuration
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/personal"; # SSH key synced from 1Password
          identitiesOnly = true; # Only use specified identity file
          forwardAgent = false; # Security best practice: disable agent forwarding
        };

        # DevPod wildcard: ephemeral workspaces on Tailscale
        "devpod-*" = lib.mkIf config.dev-config.ssh.devpods.enable {
          user = config.dev-config.ssh.devpods.user;
          forwardAgent = true; # Forward 1Password SSH agent for git operations
          extraOptions = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
            LogLevel = "ERROR"; # Suppress host key warnings (ephemeral hosts)
          };
        };
      };
    };
  };
}
