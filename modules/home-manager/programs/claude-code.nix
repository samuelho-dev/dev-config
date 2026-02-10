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

  # MCP server type definitions
  mcpServerType = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.enum ["stdio" "http" "sse"];
        description = "Transport type for the MCP server";
      };

      # stdio transport options
      command = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Command to run for stdio transport";
      };

      args = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Arguments for the command (stdio transport)";
      };

      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Environment variables for the command (stdio transport)";
      };

      # http/sse transport options
      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "URL for http/sse transport";
      };

      headers = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = ''
          HTTP headers for http/sse transport.
          Values starting with "op://" will be resolved via 1Password CLI at activation time.
          Use "Bearer op://..." for Authorization headers that need the Bearer prefix.
        '';
      };
    };
  };
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

    # Global MCP servers (merged into ~/.claude.json mcpServers)
    mcpServers = lib.mkOption {
      type = lib.types.attrsOf mcpServerType;
      default = {};
      description = ''
        Global MCP servers to add to ~/.claude.json.
        These are available in all projects.

        Header values starting with "op://" are resolved via 1Password CLI at activation time.

        Example:
          mcpServers = {
            linear-server = {
              type = "http";
              url = "https://mcp.linear.app/mcp";
              headers = {
                Authorization = "Bearer op://Dev/Linear/MCP_API_KEY";
              };
            };
            effect-docs = {
              type = "stdio";
              command = "bunx";
              args = ["--bun" "effect-mcp@latest"];
            };
          };
      '';
      example = lib.literalExpression ''
        {
          linear-server = {
            type = "http";
            url = "https://mcp.linear.app/mcp";
            headers = {
              Authorization = "Bearer op://Dev/Linear/MCP_API_KEY";
            };
          };
        }
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

    # Merge enableAllProjectMcpServers and mcpServers into ~/.claude.json
    # Run after sops-nix so secrets are available
    home.activation.configureClaudeGlobalSettings = lib.hm.dag.entryAfter ["writeBoundary" "sops-nix"] (let
      # Build MCP servers JSON, resolving op:// references
      mcpServersScript = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: server: let
          # Build the server config based on transport type
          baseConfig =
            if server.type == "stdio"
            then ''
              {
                "command": ${builtins.toJSON server.command},
                "args": ${builtins.toJSON server.args},
                "env": ${builtins.toJSON server.env}
              }
            ''
            else ''
              {
                "type": "${server.type}",
                "url": ${builtins.toJSON server.url},
                "headers": {}
              }
            '';

          # Generate header resolution commands for http/sse transports
          # Supports: plain values, op:// references, and "Bearer op://" pattern
          headerCommands = lib.optionalString (server.type != "stdio" && server.headers != {}) (
            lib.concatStringsSep "\n" (lib.mapAttrsToList (headerName: headerValue: let
              # Check for "Bearer op://" pattern
              hasBearerOpPrefix = lib.hasPrefix "Bearer op://" headerValue;
              opPathFromBearer =
                if hasBearerOpPrefix
                then lib.removePrefix "Bearer " headerValue
                else null;
            in
              if hasBearerOpPrefix
              then ''
                # Resolve 1Password reference with Bearer prefix for ${headerName}
                RESOLVED_VALUE=$(${pkgs._1password-cli}/bin/op read "${opPathFromBearer}" 2>/dev/null || echo "")
                if [ -n "$RESOLVED_VALUE" ]; then
                  SERVER_CONFIG=$(echo "$SERVER_CONFIG" | ${pkgs.jq}/bin/jq --arg val "Bearer $RESOLVED_VALUE" '.headers["${headerName}"] = $val')
                else
                  echo "Warning: Could not resolve 1Password reference for ${name}.headers.${headerName}" >&2
                fi
              ''
              else if lib.hasPrefix "op://" headerValue
              then ''
                # Resolve 1Password reference for ${headerName}
                RESOLVED_VALUE=$(${pkgs._1password-cli}/bin/op read "${headerValue}" 2>/dev/null || echo "")
                if [ -n "$RESOLVED_VALUE" ]; then
                  SERVER_CONFIG=$(echo "$SERVER_CONFIG" | ${pkgs.jq}/bin/jq --arg val "$RESOLVED_VALUE" '.headers["${headerName}"] = $val')
                else
                  echo "Warning: Could not resolve 1Password reference for ${name}.headers.${headerName}" >&2
                fi
              ''
              else ''
                SERVER_CONFIG=$(echo "$SERVER_CONFIG" | ${pkgs.jq}/bin/jq --arg val ${builtins.toJSON headerValue} '.headers["${headerName}"] = $val')
              '')
            server.headers)
          );
        in ''
          # Configure MCP server: ${name}
          SERVER_CONFIG='${baseConfig}'
          ${headerCommands}
          MCP_SERVERS=$(echo "$MCP_SERVERS" | ${pkgs.jq}/bin/jq --argjson srv "$SERVER_CONFIG" '.["${name}"] = $srv')
        '')
        cfg.mcpServers);
    in ''
      CLAUDE_JSON="$HOME/.claude.json"

      # Initialize or read existing config
      if [ -f "$CLAUDE_JSON" ]; then
        CLAUDE_CONFIG=$(cat "$CLAUDE_JSON")
      else
        CLAUDE_CONFIG='{}'
      fi

      # Set enableAllProjectMcpServers
      ${lib.optionalString cfg.enableAllProjectMcpServers ''
        CLAUDE_CONFIG=$(echo "$CLAUDE_CONFIG" | ${pkgs.jq}/bin/jq '.enableAllProjectMcpServers = true')
      ''}

      # Build MCP servers configuration
      ${lib.optionalString (cfg.mcpServers != {}) ''
        # Start with existing mcpServers or empty object
        MCP_SERVERS=$(echo "$CLAUDE_CONFIG" | ${pkgs.jq}/bin/jq '.mcpServers // {}')

        ${mcpServersScript}

        # Merge MCP servers into config
        CLAUDE_CONFIG=$(echo "$CLAUDE_CONFIG" | ${pkgs.jq}/bin/jq --argjson servers "$MCP_SERVERS" '.mcpServers = $servers')
      ''}

      # Write the updated config
      $DRY_RUN_CMD echo "$CLAUDE_CONFIG" | ${pkgs.jq}/bin/jq '.' > "$CLAUDE_JSON.tmp" && \
      $DRY_RUN_CMD mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    '');

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
