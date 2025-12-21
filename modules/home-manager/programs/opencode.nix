{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.opencode;

  # Path to OpenCode config assets in dev-config repo
  opencodeAssetsPath =
    if inputs ? dev-config
    then "${inputs.dev-config}/.opencode"
    else ../../../.opencode;
in {
  options.dev-config.opencode = {
    enable = lib.mkEnableOption "OpenCode AI coding agent with LiteLLM fallback";

    # Configuration export for init-workspace
    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if builtins.pathExists opencodeAssetsPath
        then opencodeAssetsPath
        else null;
      description = "Path to OpenCode configuration directory (.opencode/)";
    };

    exportConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Export OpenCode configs to ~/.config/opencode/.
        Consumer projects can use init-workspace to link to these configs.
      '';
    };

    litellmUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:4000";
      description = "LiteLLM proxy URL to try first";
    };

    litellmTimeout = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Timeout in seconds for LiteLLM health check";
    };
  };

  config = lib.mkIf cfg.enable {
    # Shell function with fallback logic
    # OpenCode config is managed by user via `opencode auth` or ~/.config/opencode/opencode.json
    programs.zsh.initContent = ''
      # OpenCode with LiteLLM fallback
      opencode() {
        local litellm_url="${cfg.litellmUrl}"

        # Check if LiteLLM proxy is available (fast timeout)
        if ${pkgs.curl}/bin/curl -s --connect-timeout ${toString cfg.litellmTimeout} "$litellm_url/health" >/dev/null 2>&1; then
          # LiteLLM available - use proxy with master key
          echo "→ Using LiteLLM proxy" >&2
          ANTHROPIC_API_KEY="$LITELLM_MASTER_KEY" \
          ANTHROPIC_BASE_URL="$litellm_url" \
          command /opt/homebrew/bin/opencode "$@"
        else
          # LiteLLM unavailable - use direct Anthropic API
          echo "→ Using direct API" >&2
          # ANTHROPIC_API_KEY already set via sops-env
          command /opt/homebrew/bin/opencode "$@"
        fi
      }
    '';

    # Export OpenCode configs to ~/.config/opencode/ for init-workspace
    xdg.configFile = lib.mkIf (cfg.exportConfig && cfg.configSource != null) {
      # Symlink prompts directory (shared, read-only)
      "opencode/prompts".source = cfg.configSource + "/prompts";

      # Symlink command directory (shared, read-only)
      "opencode/command".source = cfg.configSource + "/command";

      # Symlink plugin directory (shared, read-only)
      "opencode/plugin".source = cfg.configSource + "/plugin";

      # Symlink tool directory (shared, read-only)
      "opencode/tool".source = cfg.configSource + "/tool";

      # Copy base config (projects copy and extend this)
      "opencode/opencode-base.json".source = cfg.configSource + "/opencode.json";
    };
  };
}
