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

          opReference = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "1Password reference for OAuth token (e.g., op://Personal/Claude Work/oauth-token)";
            example = "op://Personal/Claude Code Work/oauth-token";
          };

          apiKey = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Optional API key reference (alternative to OAuth)";
            example = "op://Personal/Claude API/key";
          };
        };
      });
      default = {
        claude = {
          configDir = "~/.claude";
          opReference = "op://Dev/ai/claude-code-oauth-token";
        };
        claude-2 = {
          configDir = "~/.claude-2";
          opReference = "op://Dev/ai/claude-code-oauth-token-2";
        };
        claude-work = {
          configDir = "~/.claude-work";
          opReference = "op://Dev/ai/claude-code-oauth-token-work";
        };
      };
      description = "Claude Code authentication profiles with 1Password integration";
    };
  };

  config = mkIf cfg.enable {
    # Create shell aliases for each profile with 1Password OAuth injection
    programs.zsh.shellAliases =
      mapAttrs
      (
        name: profile: let
          # Build environment variable string for authentication
          authEnv =
            if profile.opReference != null
            then "CLAUDE_CODE_OAUTH_TOKEN=$(op read '${profile.opReference}' 2>/dev/null || echo '')"
            else if profile.apiKey != null
            then "ANTHROPIC_API_KEY=$(op read '${profile.apiKey}' 2>/dev/null || echo '')"
            else "";

          # Add config directory
          configEnv = "CLAUDE_CONFIG_DIR=${profile.configDir}";

          # Combine environment variables
          fullEnv =
            if authEnv != ""
            then "${authEnv} ${configEnv}"
            else configEnv;
        in "${fullEnv} claude"
      )
      cfg.profiles;

    # Add profile management helper functions
    programs.zsh.initExtra = ''
      # Claude Code Profile Management

      # Switch profile (persistent in current shell session)
      switch-claude() {
        local profile="''${1:=default}"

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
          echo "Profile: ${name}"
          if CLAUDE_CONFIG_DIR="${profile.configDir}" ${
            if profile.opReference != null
            then "CLAUDE_CODE_OAUTH_TOKEN=$(op read '${profile.opReference}' 2>/dev/null || echo '')"
            else ""
          } claude /status 2>&1 | grep -q "Authenticated"; then
            echo "  ✓ Authenticated"
          else
            echo "  ✗ Not authenticated"
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
