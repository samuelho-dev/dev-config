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
    # Shell aliases for Claude Code
    programs.zsh.shellAliases = {
      cc = "claude --dangerously-skip-permissions";
    };

    # Install Claude Code CLI when bun is already available outside Nix.
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

    # dev-config skills belong in the global skill roots discovered by Claude
    # and omp (~/.claude/skills, ~/.agents/skills). Agents and commands are not
    # exported, and stale global copies of them do not persist.
    home.activation.exportClaudeConfigs = lib.mkIf (cfg.exportConfig && cfg.configSource != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD rm -rf "$HOME/.claude/agents" "$HOME/.claude/commands"

        SKILLS_SRC="${cfg.configSource}/../ai/skills"
        if [ -d "$SKILLS_SRC" ]; then
          for DEST in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
            $DRY_RUN_CMD mkdir -p "$DEST"
            for SKILL in "$SKILLS_SRC"/*/; do
              [ -d "$SKILL" ] || continue
              NAME="$(basename "$SKILL")"
              $DRY_RUN_CMD rm -rf "$DEST/$NAME"
              $DRY_RUN_CMD cp -Lr "''${SKILL%/}" "$DEST/$NAME"
              $DRY_RUN_CMD chmod -R +w "$DEST/$NAME"
            done
          done
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
