{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.opencode;

  # Config for direct Anthropic API (default/fallback)
  # Note: provider.anthropic.options is optional - OpenCode uses ANTHROPIC_API_KEY env var by default
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    model = cfg.model;
    small_model = cfg.smallModel;
  };
in {
  options.dev-config.opencode = {
    enable = lib.mkEnableOption "OpenCode AI coding agent with LiteLLM fallback";

    model = lib.mkOption {
      type = lib.types.str;
      default = "claude-sonnet-4-20250514";
      description = "Primary model for OpenCode";
    };

    smallModel = lib.mkOption {
      type = lib.types.str;
      default = "claude-3-haiku-20240307";
      description = "Small model for quick operations";
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
    # Generate config file for direct API (fallback default)
    # Force overwrite existing config (we're managing it now)
    xdg.configFile."opencode/opencode.json" = {
      text = builtins.toJSON opencodeConfig;
      force = true;
    };

    # Shell function with fallback logic
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
  };
}
