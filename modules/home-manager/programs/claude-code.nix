{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.dev-config.claude-code;
in {
  options.dev-config.claude-code = {
    enable = mkEnableOption "Claude Code CLI with multi-profile authentication";

    profiles = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          configDir = mkOption {
            type = types.str;
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

  config = mkIf cfg.enable {
    # Create shell aliases for each profile
    # OAuth tokens loaded via sops in environment, not in aliases
    programs.zsh.shellAliases =
      mapAttrs
      (name: profile: "CLAUDE_CONFIG_DIR=${profile.configDir} command claude")
      cfg.profiles;

    # Load OAuth tokens from sops secrets into environment
    programs.zsh.initContent = let
      # Check if sops secrets are configured for Claude
      sopsEnabled = config.sops.secrets ? "claude/oauth-token";

      # Load tokens from sops if available
      tokenLoader =
        if sopsEnabled
        then ''
          # Load Claude OAuth tokens from sops
          export CLAUDE_CODE_OAUTH_TOKEN="$(cat ${config.sops.secrets."claude/oauth-token".path} 2>/dev/null || echo "")"
        ''
        else "# No sops secrets configured for Claude OAuth tokens";
    in ''
      # Claude Code Profile Management
      ${tokenLoader}

      # Switch profile (persistent in current shell session)
      switch-claude() {
        local profile="''${1:=claude}"

        # Validate profile exists
        case "$profile" in
          ${concatStringsSep " | " (attrNames cfg.profiles)})
            ;;
          *)
            echo "Error: Unknown profile '$profile'"
            echo "Available profiles: ${concatStringsSep ", " (attrNames cfg.profiles)}"
            return 1
            ;;
        esac

        # Get profile config directory
        case "$profile" in
          ${concatStringsSep "\n          " (mapAttrsToList (name: profile: "${name}) export CLAUDE_CONFIG_DIR=\"${profile.configDir}\" ;;") cfg.profiles)}
        esac

        echo "✓ Switched to Claude profile: $profile"
        echo "  Config directory: $CLAUDE_CONFIG_DIR"
      }

      # List available profiles
      list-claude-profiles() {
        echo "Available Claude Code profiles:"
        ${concatStringsSep "\n        " (mapAttrsToList (name: profile: "echo '  - ${name}: ${profile.configDir}'") cfg.profiles)}
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
        ${concatStringsSep "\n        " (mapAttrsToList (name: profile: ''
          echo "Profile: ${name} (${profile.configDir})"
          if CLAUDE_CONFIG_DIR="${profile.configDir}" claude /status 2>&1 | grep -q "Authenticated"; then
            echo "  ✓ Authenticated"
          else
            echo "  ✗ Not authenticated (run: ${name} /login)"
          fi
          echo ""
        '')
        cfg.profiles)}
      }
    '';

    # Ensure config directories exist
    home.activation.createClaudeProfileDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${concatStringsSep "\n      " (mapAttrsToList (name: profile: "$DRY_RUN_CMD mkdir -p ${profile.configDir}") cfg.profiles)}
    '';
  };
}
