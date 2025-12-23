{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.sops-env;

  # Get secret paths directly (secrets are defined in home.nix)
  anthropicKeyPath = config.sops.secrets."ai/anthropic_key".path;
  openaiKeyPath = config.sops.secrets."ai/openai_key".path;
  googleAiKeyPath = config.sops.secrets."ai/google_ai_key".path;
  litellmKeyPath = config.sops.secrets."ai/litellm_master_key".path;
  openrouterKeyPath = config.sops.secrets."ai/openrouter_key".path;

  # Shell script to generate load-env.sh at activation time
  # This runs AFTER sops-nix decrypts secrets at activation time
  # Secrets are read from tmpfs (~/.local/share/sops-nix/secrets.d/)
  generateLoadEnvScript = ''
        # Create load-env.sh file at activation time
        LOAD_ENV_FILE="$HOME/.config/sops-nix/load-env.sh"
        mkdir -p "$(dirname "$LOAD_ENV_FILE")"

        # Generate the load-env.sh script with actual secret paths
        cat > "$LOAD_ENV_FILE" <<LOAD_ENV_EOF
    # AI service API keys (loaded from sops-nix decrypted paths)
    # This file is generated at Home Manager activation time

    # Anthropic API Key (Claude)
    if [ -f "${anthropicKeyPath}" ]; then
      export ANTHROPIC_API_KEY="\$(cat ${anthropicKeyPath})"
    fi

    # OpenAI API Key
    if [ -f "${openaiKeyPath}" ]; then
      export OPENAI_API_KEY="\$(cat ${openaiKeyPath})"
    fi

    # Google AI API Key
    if [ -f "${googleAiKeyPath}" ]; then
      export GOOGLE_AI_API_KEY="\$(cat ${googleAiKeyPath})"
    fi

    # LiteLLM Master Key
    if [ -f "${litellmKeyPath}" ]; then
      export LITELLM_MASTER_KEY="\$(cat ${litellmKeyPath})"
    fi

    # OpenRouter API Key
    if [ -f "${openrouterKeyPath}" ]; then
      export OPENROUTER_API_KEY="\$(cat ${openrouterKeyPath})"
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
        Load AI service API keys from sops-nix secrets into environment variables.

        This eliminates the need for 1Password CLI queries on every shell startup.
        Secrets are decrypted once at Home Manager activation and exported to shell.

        Security: Secrets are read from tmpfs (macOS: ~/.local/share/sops-nix/secrets.d)
        and never written to disk unencrypted.

        Environment variables loaded:
        - ANTHROPIC_API_KEY (Claude API)
        - OPENAI_API_KEY (OpenAI API)
        - GOOGLE_AI_API_KEY (Google AI API)
        - LITELLM_MASTER_KEY (LiteLLM proxy master key)
        - OPENROUTER_API_KEY (OpenRouter multi-model API)
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
