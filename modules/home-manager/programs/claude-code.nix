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
        Export Claude Code configs to ~/.config/claude-code/.
        Consumer projects use lib.devShellHook to link .claude/ on nix develop.
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

    # Export Claude Code configs to ~/.config/claude-code/ for lib.devShellHook
    xdg.configFile = lib.mkIf (cfg.exportConfig && cfg.configSource != null) {
      # NEW: Pull from centralized ai/ directory
      "claude-code/agents".source = cfg.configSource + "/../ai/agents";
      "claude-code/commands".source = cfg.configSource + "/../ai/commands";

      # Templates and settings stay in .claude
      "claude-code/templates".source = cfg.configSource + "/templates";

      # Generate base settings.json (projects copy and extend this)
      "claude-code/settings-base.json".text = builtins.toJSON cfg.baseSettings;
    };

    # Note: Commands/agents/templates are NOT deployed globally to ~/.claude/
    # They are only available at the project level (.claude/commands/) to avoid duplicates.
    # Use lib.devShellHook in project flakes to link .claude/ on nix develop.
  };
}
