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

    additionalPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["@franlol/opencode-md-table-formatter@0.0.3"];
      description = "Additional OpenCode plugins to install and register";
      example = ["plugin-name@version" "another-plugin"];
    };

    # Dependencies for local TypeScript plugins in plugin/
    pluginDependencies = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["effect"];
      description = "NPM packages required by local plugins (e.g., effect for Schema validation)";
      example = ["effect" "zod" "@effect/schema"];
    };

    ohMyOpencode = {
      enable = lib.mkEnableOption "oh-my-opencode plugin for multi-agent orchestration";

      package = lib.mkOption {
        type = lib.types.str;
        default = "oh-my-opencode@2.4.2";
        description = "npm package name with version (e.g., 'oh-my-opencode@2.4.2')";
      };

      disabledAgents = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of agents to disable";
        example = ["oracle" "frontend-ui-ux-engineer"];
      };

      disabledHooks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["startup-toast"];
        description = "List of hooks to disable";
      };

      disabledMcps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of MCPs to disable";
      };

      enableGoogleAuth = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable built-in Google Auth (false when using OpenRouter)";
      };

      modelOverrides = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = {};
        description = "Agent model overrides (if different from defaults)";
        example = lib.literalExpression ''
          {
            oracle = { model = "openrouter/anthropic/claude-opus-4-5"; };
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # OpenCode wrapper with LiteLLM fallback
    # Tries LiteLLM proxy first, falls back to direct Anthropic API
    programs.zsh.initContent = ''
      # Cache the actual opencode binary path at shell init
      # whence -p finds external commands only, avoiding the function we're about to define
      _OPENCODE_BIN=$(whence -p opencode 2>/dev/null || echo "")

      opencode() {
        local litellm_url="${cfg.litellmUrl}"

        if [[ -z "$_OPENCODE_BIN" ]]; then
          echo "Error: opencode binary not found in PATH" >&2
          echo "Install via: brew install opencode" >&2
          return 1
        fi

        # Check if LiteLLM proxy is available (fast timeout)
        if ${pkgs.curl}/bin/curl -s --connect-timeout ${toString cfg.litellmTimeout} "$litellm_url/health" >/dev/null 2>&1; then
          # LiteLLM available - use proxy with master key
          echo "→ Using LiteLLM proxy" >&2
          ANTHROPIC_API_KEY="$LITELLM_MASTER_KEY" \
          ANTHROPIC_BASE_URL="$litellm_url" \
          "$_OPENCODE_BIN" "$@"
        else
          # LiteLLM unavailable - use direct Anthropic API
          echo "→ Using direct API" >&2
          "$_OPENCODE_BIN" "$@"
        fi
      }
    '';

    # Export OpenCode configs to ~/.config/opencode/
    # NOTE: plugin/tool/command/prompts are copied via activation script (not symlinked)
    # to allow Bun to resolve dependencies from ~/.config/opencode/node_modules
    xdg.configFile = lib.mkMerge [
      # Base config only - directories are copied by activation script
      (lib.mkIf (cfg.exportConfig && cfg.configSource != null) {
        "opencode/opencode-base.json".source = cfg.configSource + "/opencode.json";
      })
      # oh-my-opencode generated configs
      # NOTE: OpenCode auto-installs plugins listed in opencode.json on startup
      (lib.mkIf cfg.ohMyOpencode.enable {
        # Generate OpenCode base configuration with all plugins
        "opencode/opencode.json".text = builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
          autoupdate = true;
          plugin = ["oh-my-opencode"] ++ cfg.additionalPlugins;
        };

        # Generate oh-my-opencode configuration
        "opencode/oh-my-opencode.json".text = builtins.toJSON {
          "$schema" = "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json";

          # Disable Google Auth (using OpenRouter instead)
          google_auth = cfg.ohMyOpencode.enableGoogleAuth;

          # Feature toggles
          disabled_agents = cfg.ohMyOpencode.disabledAgents;
          disabled_hooks = cfg.ohMyOpencode.disabledHooks;
          disabled_mcps = cfg.ohMyOpencode.disabledMcps;

          # Agent model configuration (OpenRouter + Claude Max 20)
          agents =
            {
              # Main orchestrator (Claude Max 20)
              Sisyphus = {
                model = "anthropic/claude-opus-4-5";
                temperature = 0.7;
              };

              # Architecture & debugging (OpenRouter fallback)
              oracle = {
                model = "openrouter/anthropic/claude-opus-4-5";
                temperature = 0.3;
              };

              # Codebase analysis (Claude Max 20)
              librarian = {
                model = "anthropic/claude-sonnet-4-5";
                temperature = 0.5;
              };

              # Fast search (Grok via OpenRouter - free)
              explore = {
                model = "openrouter/x-ai/grok-3";
                temperature = 0.2;
              };

              # Frontend specialist (Gemini via OpenRouter)
              frontend-ui-ux-engineer = {
                model = "openrouter/google/gemini-3-pro-high";
                temperature = 0.8;
              };

              # Documentation writer (Gemini Flash via OpenRouter)
              document-writer = {
                model = "openrouter/google/gemini-3-flash";
                temperature = 0.6;
              };

              # Multimodal analysis (Gemini 2.5 Flash via OpenRouter)
              multimodal-looker = {
                model = "openrouter/google/gemini-2.5-flash";
                temperature = 0.5;
              };
            }
            // cfg.ohMyOpencode.modelOverrides;

          # Claude Code compatibility (full support)
          claude_code = {
            mcp = true;
            commands = true;
            skills = true;
            agents = true;
            hooks = true;
          };
        };
      })
    ];

    # Activation script to copy local assets and install dependencies
    # This ensures Bun can resolve deps from ~/.config/opencode/node_modules
    home.activation.setupOpencodePlugins = lib.mkIf (cfg.enable && cfg.ohMyOpencode.enable) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        OPENCODE_DIR="$HOME/.config/opencode"
        SOURCE_DIR="${cfg.configSource}"

        run ${pkgs.coreutils}/bin/mkdir -p "$OPENCODE_DIR"

        # Copy local assets (plugin, tool, command, prompts) with proper permissions
        # Using rsync to handle Nix store read-only files properly
        for dir in plugin tool command prompts; do
          if [ -d "$SOURCE_DIR/$dir" ]; then
            run ${pkgs.coreutils}/bin/rm -rf "$OPENCODE_DIR/$dir"
            run ${pkgs.coreutils}/bin/mkdir -p "$OPENCODE_DIR/$dir"
            run ${pkgs.rsync}/bin/rsync -a --chmod=u+rw "$SOURCE_DIR/$dir/" "$OPENCODE_DIR/$dir/"
          fi
        done

        # Create/update package.json with plugin dependencies
        DEPS_JSON=$(${pkgs.jq}/bin/jq -n \
          --argjson deps '${builtins.toJSON (builtins.listToAttrs (map (pkg: {
            name = pkg;
            value = "latest";
          })
          cfg.pluginDependencies))}' \
          '{name: "opencode-local-plugins", private: true, dependencies: $deps}')
        run ${pkgs.coreutils}/bin/echo "$DEPS_JSON" > "$OPENCODE_DIR/package.json"

        # Install dependencies if needed (check hash to avoid unnecessary installs)
        DEPS_HASH=$(echo "${builtins.concatStringsSep " " cfg.pluginDependencies}" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1)
        HASH_FILE="$OPENCODE_DIR/.deps-hash"

        if [ ! -d "$OPENCODE_DIR/node_modules" ] || [ ! -f "$HASH_FILE" ] || [ "$(cat "$HASH_FILE" 2>/dev/null)" != "$DEPS_HASH" ]; then
          run ${pkgs.bun}/bin/bun install --cwd "$OPENCODE_DIR"
          run ${pkgs.coreutils}/bin/echo "$DEPS_HASH" > "$HASH_FILE"
        fi
      ''
    );
  };
}
