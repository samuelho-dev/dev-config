{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.opencode;
in {
  options.dev-config.opencode = {
    enable = lib.mkEnableOption "OpenCode AI coding agent with LiteLLM fallback";

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
  };
}
