{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.sops-env;

  # 1Password item UUID for AI service keys (from module option)
  onePassAiItemId = cfg.onePasswordItemId;
  onePassAiVault = cfg.onePasswordVault;

  # Get 1Password service account token path from sops (guarded for non-sops configs)
  opServiceAccountTokenPath =
    if (config ? sops) && (config.sops.secrets ? "op/service_account_token")
    then config.sops.secrets."op/service_account_token".path
    else null;

  # Activation-time generator for ~/.config/sops-nix/load-env.sh.
  #
  # Runs AFTER sops-nix decrypts the op service-account token. It resolves the AI keys ONCE here
  # (a single `op` call) and bakes them in as literal exports, so the file that ~/.zshenv sources on
  # every shell does ZERO network/`op` work — sourcing it is ~1ms instead of ~1s. Re-run
  # `home-manager switch` (or `darwin-rebuild switch`) to refresh the keys.
  generateLoadEnvScript = ''
    LOAD_ENV_FILE="$HOME/.config/sops-nix/load-env.sh"
    mkdir -p "$(dirname "$LOAD_ENV_FILE")"

    # Resolve the op CLI: PATH first, then common install locations (op is usually Homebrew's, which
    # may not be on the activation PATH).
    OP_BIN="$(command -v op 2>/dev/null || true)"
    if [ -z "$OP_BIN" ]; then
      for candidate in /opt/homebrew/bin/op /usr/local/bin/op; do
        [ -x "$candidate" ] && { OP_BIN="$candidate"; break; }
      done
    fi

    TMP="$(mktemp "$LOAD_ENV_FILE.XXXXXX")"

    # Static prelude: header + the service-account token (read from its sops file at shell time, so the
    # token itself is never copied into this generated file).
    {
      printf '%s\n' "# AI service API keys for 1Password vault '${onePassAiVault}', item ${onePassAiItemId}."
      printf '%s\n' "# RESOLVED ONCE at Home Manager activation and baked in as literals below."
      printf '%s\n' "# Sourced from ~/.zshenv on EVERY shell, so it stays cheap: no per-shell 'op' calls."
      printf '%s\n' "# Refresh the keys by re-running: home-manager switch (or darwin-rebuild switch)."
      printf '%s\n' ""
      printf '%s\n' 'if [ -f "${opServiceAccountTokenPath}" ]; then'
      printf '%s\n' '  export OP_SERVICE_ACCOUNT_TOKEN="$(cat ${opServiceAccountTokenPath})"'
      printf '%s\n' 'fi'
      printf '%s\n' ""
    } > "$TMP"

    # Resolve all five keys in ONE op call and append only non-empty, non-placeholder exports.
    KEYS_OK=0
    if [ -n "$OP_BIN" ] && [ -f "${opServiceAccountTokenPath}" ]; then
      if OP_SERVICE_ACCOUNT_TOKEN="$(cat ${opServiceAccountTokenPath})" \
         "$OP_BIN" item get ${onePassAiItemId} --vault ${onePassAiVault} --format json \
           --fields label=ANTHROPIC_API_KEY,label=OPENAI_API_KEY,label=GOOGLE_AI_STUDIO_KEY,label=LITELLM_KEY,label=OPENROUTER_API_KEY \
           --reveal 2>/dev/null \
         | ${pkgs.jq}/bin/jq -r '
             def field($label): first(.[] | select(.label == $label).value) // "";
             def export($env; $label):
               field($label) as $value
               | select($value != "" and ($value | startswith("PLACEHOLDER_") | not))
               | "export \($env)=" + ($value | @sh);
             export("ANTHROPIC_API_KEY"; "ANTHROPIC_API_KEY"),
             export("OPENAI_API_KEY"; "OPENAI_API_KEY"),
             export("GOOGLE_AI_API_KEY"; "GOOGLE_AI_STUDIO_KEY"),
             export("LITELLM_MASTER_KEY"; "LITELLM_KEY"),
             export("OPENROUTER_API_KEY"; "OPENROUTER_API_KEY")
           ' >> "$TMP" 2>/dev/null \
         && grep -q '^export ANTHROPIC_API_KEY=' "$TMP"; then
        KEYS_OK=1
      fi
    fi

    if [ "$KEYS_OK" = 1 ]; then
      chmod 600 "$TMP"
      mv -f "$TMP" "$LOAD_ENV_FILE"
    else
      rm -f "$TMP"
      echo "dev-config.sops-env: could not resolve AI keys at activation (op missing, or vault/item unreachable); left existing $LOAD_ENV_FILE unchanged" >&2
    fi
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
        - Centralized secrets: AI keys stored in 1Password vault
        - On-demand loading: Keys fetched via `op item get` when needed

        Environment variables set when their 1Password values are non-empty and non-placeholder:
        - OP_SERVICE_ACCOUNT_TOKEN (from sops-nix for non-interactive op CLI)
        - ANTHROPIC_API_KEY (from 1Password vault)
        - OPENAI_API_KEY (from 1Password vault)
        - GOOGLE_AI_API_KEY (from 1Password vault)
        - LITELLM_MASTER_KEY (from 1Password vault)
        - OPENROUTER_API_KEY (from 1Password vault)
      '';
    };

    onePasswordItemId = lib.mkOption {
      type = lib.types.str;
      default = "xsuolbdwx4vmcp3zysjczfatam";
      description = "1Password item UUID for AI service keys";
    };

    onePasswordVault = lib.mkOption {
      type = lib.types.str;
      default = "Dev";
      description = ''
        1Password vault holding the AI keys item. Required: the service-account `op` CLI
        rejects `item get` without a vault ("a vault query must be provided").
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
