{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.claude-code;

  # Path to Claude Code config assets in dev-config repo
  claudeAssetsPath =
    if inputs ? dev-config
    then "${inputs.dev-config}/.claude"
    else ../../../.claude;
in {
  options.dev-config.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI with multi-profile authentication";

    # Configuration export for lib.devShellHook
    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if builtins.pathExists claudeAssetsPath
        then claudeAssetsPath
        else null;
      description = "Path to Claude Code configuration directory (.claude/)";
    };

    exportConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Export Claude Code configs (agents, commands) directly to ~/.claude/.
        These are available globally in all projects without project-level sync.
      '';
    };

    # Base settings.json content (projects can extend)
    baseSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        hooks.enabled = false;
      };
      description = "Base settings.json configuration for consumer projects";
    };

    # Enable project-level MCP servers from .mcp.json files
    enableAllProjectMcpServers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Automatically trust and enable all MCP servers defined in project-level .mcp.json files.
        This adds "enableAllProjectMcpServers": true to ~/.claude.json.
        Security note: Only enable if you trust all projects you work on.
      '';
    };

    litellm = {
      enable =
        (lib.mkEnableOption "Route Claude Code through LiteLLM gateway")
        // {default = true;};

      baseUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://litellm.infra.samuelho.space";
        description = "LiteLLM API endpoint (https://host or http://localhost:4000 when port-forwarding).";
      };

      authTokenEnvVar = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "LITELLM_MASTER_KEY";
        description = "Environment variable containing the LiteLLM master/virtual key to forward as ANTHROPIC_AUTH_TOKEN.";
      };

      customHeaders = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["x-litellm-api-key: Bearer $LITELLM_MASTER_KEY"];
        description = ''
          Optional headers forwarded with every Claude Code request (newline separated via ANTHROPIC_CUSTOM_HEADERS).
          Leave empty to disable. Defaults to sending the LiteLLM key header required for Claude Max routing.
        '';
      };
    };

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

    # Merge enableAllProjectMcpServers into ~/.claude.json
    # Uses jq to preserve existing settings while adding/updating our managed keys
    home.activation.configureClaudeGlobalSettings = lib.mkIf cfg.enableAllProjectMcpServers (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        CLAUDE_JSON="$HOME/.claude.json"
        if [ -f "$CLAUDE_JSON" ]; then
          # Merge setting into existing config
          $DRY_RUN_CMD ${pkgs.jq}/bin/jq '.enableAllProjectMcpServers = true' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && \
          $DRY_RUN_CMD mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
        else
          # Create new config with just this setting
          $DRY_RUN_CMD echo '{"enableAllProjectMcpServers": true}' > "$CLAUDE_JSON"
        fi
      ''
    );

    # Export Claude Code configs directly to ~/.claude/ (global, writable)
    # These are available in ALL projects automatically via Claude Code's config hierarchy
    home.activation.exportClaudeConfigs = lib.mkIf (cfg.exportConfig && cfg.configSource != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Source paths from dev-config
        AGENTS_SRC="${cfg.configSource}/../ai/agents"
        COMMANDS_SRC="${cfg.configSource}/../ai/commands"

        # Copy agents (writable so user can add new ones)
        if [ -d "$AGENTS_SRC" ]; then
          $DRY_RUN_CMD rm -rf "$HOME/.claude/agents"
          $DRY_RUN_CMD mkdir -p "$HOME/.claude"
          $DRY_RUN_CMD cp -Lr "$AGENTS_SRC" "$HOME/.claude/agents"
          $DRY_RUN_CMD chmod -R +w "$HOME/.claude/agents"
        fi

        # Copy commands (writable so user can add new ones)
        if [ -d "$COMMANDS_SRC" ]; then
          $DRY_RUN_CMD rm -rf "$HOME/.claude/commands"
          $DRY_RUN_CMD mkdir -p "$HOME/.claude"
          $DRY_RUN_CMD cp -Lr "$COMMANDS_SRC" "$HOME/.claude/commands"
          $DRY_RUN_CMD chmod -R +w "$HOME/.claude/commands"
        fi
      ''
    );

    home.sessionVariables = lib.mkIf cfg.litellm.enable (let
      mkEnvRef = envName: "$" + envName;
      authToken =
        if cfg.litellm.authTokenEnvVar == null
        then null
        else mkEnvRef cfg.litellm.authTokenEnvVar;
      customHeadersValue =
        if cfg.litellm.customHeaders == []
        then null
        else lib.concatStringsSep "\n" cfg.litellm.customHeaders;
    in
      {
        ANTHROPIC_BASE_URL = cfg.litellm.baseUrl;
      }
      // lib.optionalAttrs (authToken != null) {
        ANTHROPIC_AUTH_TOKEN = authToken;
        ANTHROPIC_API_KEY = authToken;
      }
      // lib.optionalAttrs (customHeadersValue != null) {
        ANTHROPIC_CUSTOM_HEADERS = customHeadersValue;
      });
  };
}
