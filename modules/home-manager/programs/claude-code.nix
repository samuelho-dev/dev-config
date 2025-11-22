{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.claude-code;
in {
  options.dev-config.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI with multi-profile authentication";

    profiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          configDir = lib.mkOption {
            type = lib.types.str;
            description = "Configuration directory for this profile";
            example = "~/.claude-work";
          };
        };
      });
      default = {
        claude = {
          configDir = "~/.claude";
        };
        claude-2 = {
          configDir = "~/.claude-2";
        };
        claude-work = {
          configDir = "~/.claude-work";
        };
      };
      description = "Claude Code authentication profiles";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create shell aliases for each profile
    # Claude Code manages its own OAuth tokens in each profile's .claude.json
    programs.zsh.shellAliases =
      lib.mapAttrs
      (name: profile: "CLAUDE_CONFIG_DIR=${profile.configDir} command claude")
      cfg.profiles;

    # Profile management functions
    # No token injection - Claude handles OAuth natively
    programs.zsh.initContent = ''
      # Claude Code Profile Management

      # Switch profile (persistent in current shell session)
      switch-claude() {
        local profile="''${1:=claude}"

        # Validate profile exists
        case "$profile" in
          ${lib.concatStringsSep " | " (lib.attrNames cfg.profiles)})
            ;;
          *)
            echo "Error: Unknown profile '$profile'"
            echo "Available profiles: ${lib.concatStringsSep ", " (lib.attrNames cfg.profiles)}"
            return 1
            ;;
        esac

        # Get profile config directory
        case "$profile" in
          ${lib.concatStringsSep "\n          " (lib.mapAttrsToList (name: profile: "${name}) export CLAUDE_CONFIG_DIR=\"${profile.configDir}\" ;;") cfg.profiles)}
        esac

        echo "✓ Switched to Claude profile: $profile"
        echo "  Config directory: $CLAUDE_CONFIG_DIR"
      }

      # List available profiles
      list-claude-profiles() {
        echo "Available Claude Code profiles:"
        ${lib.concatStringsSep "\n        " (lib.mapAttrsToList (name: profile: "echo '  - ${name}: ${profile.configDir}'") cfg.profiles)}
      }

      # Show current profile
      current-claude-profile() {
        if [ -n "$CLAUDE_CONFIG_DIR" ]; then
          echo "Current profile: $CLAUDE_CONFIG_DIR"
        else
          echo "Current profile: default (~/.claude)"
        fi
      }

      # Quick profile status check
      claude-profile-status() {
        echo "Checking authentication status for all profiles..."
        echo ""
        ${lib.concatStringsSep "\n        " (lib.mapAttrsToList (name: profile: ''
          echo "Profile: ${name} (${profile.configDir})"
          if [ -f "${profile.configDir}/.claude.json" ] && grep -q "oauthAccount" "${profile.configDir}/.claude.json" 2>/dev/null; then
            echo "  ✓ Authenticated"
          else
            echo "  ✗ Not authenticated (run: CLAUDE_CONFIG_DIR=${profile.configDir} claude setup-token)"
          fi
          echo ""
        '')
        cfg.profiles)}
      }
    '';

    # Ensure config directories exist
    home.activation.createClaudeProfileDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${lib.concatStringsSep "\n      " (lib.mapAttrsToList (name: profile: "$DRY_RUN_CMD mkdir -p ${profile.configDir}") cfg.profiles)}
    '';
  };
}
