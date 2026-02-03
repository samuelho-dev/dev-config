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
    enable = lib.mkEnableOption "Claude Code CLI with OAuth authentication";

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

    # LiteLLM pass-through proxy for traffic logging/tracking
    # Uses /anthropic endpoint - Claude Code handles OAuth natively
    litellm = {
      enable =
        (lib.mkEnableOption "Route Claude Code through LiteLLM pass-through proxy")
        // {default = true;};

      baseUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://litellm.infra.samuelho.space";
        description = ''
          LiteLLM proxy base URL (without /anthropic suffix).
          The /anthropic pass-through endpoint is appended automatically.

          Examples:
            - "http://localhost:4000" (local/port-forwarded)
            - "https://litellm.infra.samuelho.space" (Tailscale ingress)

          Pass-through mode: Claude Code authenticates with Anthropic directly
          using native OAuth. LiteLLM only logs traffic for cost tracking.

          Use /login in Claude Code to switch between accounts.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Install Claude Code CLI via bun (npm package not in nixpkgs)
    # Requires bun in PATH (provided by dev-config.npm module)
    home.activation.installClaudeCodeCli = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      if command -v bun &>/dev/null; then
        # Check if claude is already installed and up to date
        if ! command -v claude &>/dev/null || ! claude --version &>/dev/null 2>&1; then
          $DRY_RUN_CMD bun add -g @anthropic-ai/claude-code 2>/dev/null || true
        fi
      fi
    '';

    # Ensure ~/.claude directory exists
    home.activation.createClaudeConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.claude"
    '';

    # Merge enableAllProjectMcpServers into ~/.claude.json
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

    # LiteLLM pass-through configuration
    # Uses /anthropic endpoint for transparent pass-through
    # Claude Code handles OAuth natively - use /login to switch accounts
    home.sessionVariables = lib.mkIf cfg.litellm.enable {
      ANTHROPIC_BASE_URL = "${cfg.litellm.baseUrl}/anthropic";
    };
  };
}
