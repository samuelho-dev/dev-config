{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.sops-env;

  # 1Password item UUID for AI service keys
  onePassAiItemId = "xsuolbdwx4vmcp3zysjczfatam";

  # Get 1Password service account token path from sops
  opServiceAccountTokenPath = config.sops.secrets."op/service_account_token".path;

  # Shell script to generate load-env.sh at activation time
  # This runs AFTER sops-nix decrypts secrets at activation time
  generateLoadEnvScript = ''
        # Create load-env.sh file at activation time
        LOAD_ENV_FILE="$HOME/.config/sops-nix/load-env.sh"
        mkdir -p "$(dirname "$LOAD_ENV_FILE")"

        # Generate the load-env.sh script with AI keys from 1Password
        cat > "$LOAD_ENV_FILE" <<'LOAD_ENV_EOF'
    # AI service API keys (fetched from 1Password vault)
    # 1Password item UUID: ${onePassAiItemId}
    # This file is generated at Home Manager activation time

    # 1Password Service Account Token (enables prompt-free op CLI)
    if [ -f "${opServiceAccountTokenPath}" ]; then
      export OP_SERVICE_ACCOUNT_TOKEN="$(cat ${opServiceAccountTokenPath})"
    fi

    # AI keys from 1Password (requires OP_SERVICE_ACCOUNT_TOKEN to be set)
    # These are fetched on-demand by scripts/shell hooks that need them
    # For shell prompt to work, source 1Password agent:
    # eval "$(op signin)"  # Or use OP_SERVICE_ACCOUNT_TOKEN for non-interactive

    # Anthropic API Key (Claude)
    if command -v op &>/dev/null && [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
      export ANTHROPIC_API_KEY="$(op item get ${onePassAiItemId} --fields label=anthropic_key 2>/dev/null || echo "")"
    fi

    # OpenAI API Key
    if command -v op &>/dev/null && [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
      export OPENAI_API_KEY="$(op item get ${onePassAiItemId} --fields label=openai_key 2>/dev/null || echo "")"
    fi

    # Google AI API Key
    if command -v op &>/dev/null && [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
      export GOOGLE_AI_API_KEY="$(op item get ${onePassAiItemId} --fields label=google_ai_key 2>/dev/null || echo "")"
    fi

    # LiteLLM Master Key
    if command -v op &>/dev/null && [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
      export LITELLM_MASTER_KEY="$(op item get ${onePassAiItemId} --fields label=litellm_master_key 2>/dev/null || echo "")"
    fi

    # OpenRouter API Key
    if command -v op &>/dev/null && [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
      export OPENROUTER_API_KEY="$(op item get ${onePassAiItemId} --fields label=openrouter_key 2>/dev/null || echo "")"
    fi
    LOAD_ENV_EOF

        chmod 644 "$LOAD_ENV_FILE"
  '';
in {
  options.dev-config.sops-env = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Load 1Password service account token from sops-nix and generate shell script
        to fetch AI service API keys from 1Password on demand.

        This hybrid approach combines:
        - Secure token storage: OP_SERVICE_ACCOUNT_TOKEN via sops-nix (encrypted at rest)
        - Centralized secrets: AI keys stored in 1Password vault (xsuolbdwx4vmcp3zysjczfatam)
        - On-demand loading: Keys fetched via `op item get` when needed

        Environment variables set:
        - OP_SERVICE_ACCOUNT_TOKEN (from sops-nix for non-interactive op CLI)
        - ANTHROPIC_API_KEY (from 1Password vault)
        - OPENAI_API_KEY (from 1Password vault)
        - GOOGLE_AI_API_KEY (from 1Password vault)
        - LITELLM_MASTER_KEY (from 1Password vault)
        - OPENROUTER_API_KEY (from 1Password vault)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Generate load-env.sh at activation time (after sops-nix decrypts secrets)
    home.activation.generateLoadEnv = lib.hm.dag.entryAfter ["sops-nix"] generateLoadEnvScript;

    # Source the script in shell initialization
    # Using programs.zsh.envExtra which runs in .zshenv (before .zshrc)
    programs.zsh.envExtra = ''
      # Load AI secrets from sops-nix (decrypted at Home Manager activation)
      if [ -f "$HOME/.config/sops-nix/load-env.sh" ]; then
        source "$HOME/.config/sops-nix/load-env.sh"
      fi
    '';

    # Also support bash
    programs.bash.bashrcExtra = ''
      # Load AI secrets from sops-nix (decrypted at Home Manager activation)
      if [ -f "$HOME/.config/sops-nix/load-env.sh" ]; then
        source "$HOME/.config/sops-nix/load-env.sh"
      fi
    '';
  };
}
