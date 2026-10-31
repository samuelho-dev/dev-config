{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dev-config.ssh = {
    enable = lib.mkEnableOption "SSH configuration with 1Password agent";

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
      enableDefaultConfig = false;

      # SSH config blocks using the modern `settings` API (home-manager 26.05+).
      # Keys are OpenSSH directive names (HostName, User, ForwardAgent, ...) written
      # directly — no camelCase aliases, no `extraOptions`.
      settings = {
        # Wildcard block: 1Password SSH agent for all connections
        "*" = lib.mkMerge [
          {
            ForwardAgent = false;
          }
          (lib.mkIf config.dev-config.ssh.onePasswordAgent.enable {
            IdentityAgent = ''"${config.dev-config.ssh.onePasswordAgent.socketPath}"'';
          })
        ];

        "github.com" = {
          HostName = "github.com";
          User = "git";
          ForwardAgent = false; # Security best practice: disable agent forwarding
          # Uses 1Password SSH agent from wildcard block (no identitiesOnly restriction)
        };
      };
    };
  };
}
