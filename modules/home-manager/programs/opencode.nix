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

  # Helper function to parse plugin name and version from strings like "package@version"
  # Returns { name = "package"; version = "version"; } or { name = "package"; version = "latest"; }
  parsePlugin = plugin: let
    parts = lib.splitString "@" plugin;
    # Handle scoped packages like @org/package@version
    hasScope = lib.hasPrefix "@" plugin;
    parsedParts =
      if hasScope
      then
        if builtins.length parts == 3
        then {
          name = "@${builtins.elemAt parts 1}";
          version = builtins.elemAt parts 2;
        }
        else {
          name = plugin;
          version = "latest";
        }
      else if builtins.length parts == 2
      then {
        name = builtins.elemAt parts 0;
        version = builtins.elemAt parts 1;
      }
      else {
        name = plugin;
        version = "latest";
      };
  in
    parsedParts;
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

    # Export OpenCode configs to ~/.config/opencode/
    xdg.configFile =
      # Base configs for init-workspace (symlinked from repo)
      (lib.mkIf (cfg.exportConfig && cfg.configSource != null) {
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
      })
      # oh-my-opencode generated configs
      // (lib.mkIf cfg.ohMyOpencode.enable {
        # Generate package.json with oh-my-opencode dependency and additional plugins
        "opencode/package.json".text = let
          parsedOhMyOpencode = parsePlugin cfg.ohMyOpencode.package;
        in
          builtins.toJSON {
            dependencies =
              {
                # Pin versions to prevent "update completed" spam on every launch
                # renovate: datasource=npm depName=@opencode-ai/plugin
                "@opencode-ai/plugin" = "1.0.184";
                # renovate: datasource=npm depName=oh-my-opencode
                "${parsedOhMyOpencode.name}" = parsedOhMyOpencode.version;
              }
              // builtins.listToAttrs (
                map (plugin: let
                  parsed = parsePlugin plugin;
                in {
                  name = parsed.name;
                  value = parsed.version;
                })
                cfg.additionalPlugins
              );
          };

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
      });
  };
}
