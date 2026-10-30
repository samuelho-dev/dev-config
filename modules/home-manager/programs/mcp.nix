{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.mcp;

  # Canonical MCP assets in the dev-config repo (single source of truth).
  serversFileSrc =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/mcp/servers.json"
    else ../../../ai/mcp/servers.json;
  applyScriptSrc =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/mcp/apply-mcp.sh"
    else ../../../ai/mcp/apply-mcp.sh;

  canonicalServers = (builtins.fromJSON (builtins.readFile serversFileSrc)).mcpServers;

  # Merge defaults with any consumer additions, then hand the resolved list to
  # the shared fan-out script (the same one the container entrypoints call).
  mergedServers = cfg.servers // cfg.extraServers;
  serversJson = pkgs.writeText "mcp-servers.json" (builtins.toJSON {mcpServers = mergedServers;});
in {
  options.dev-config.mcp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = (config.dev-config.claude-code.enable or false) || (config.dev-config.omp.enable or false) || (config.dev-config.codex.enable or false);
      defaultText = lib.literalExpression "claude-code.enable || omp.enable || codex.enable";
      description = "Render shared MCP servers for enabled agent CLIs.";
    };

    servers = lib.mkOption {
      type = lib.types.attrs;
      default = canonicalServers;
      defaultText = lib.literalExpression "builtins.fromJSON (ai/mcp/servers.json)";
      description = ''
        Global MCP servers made available to all agent CLIs, in .mcp.json shape
        (a map of name -> { type, command, args, env, url, headers }).

        Entries may carry an `auth` object instead of a literal header so the
        same definition works across secret backends:
          auth = { header = "Authorization"; prefix = "Bearer "; op = "op://…"; env = "LINEAR_API_KEY"; };
        DEV_CONFIG_MCP_AUTH_SOURCE=op selects 1Password references; env selects
        only environment variables. Project-specific servers belong in projects.
      '';
    };

    extraServers = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional MCP servers merged over `servers` for this machine.";
    };

    authSource = lib.mkOption {
      type = lib.types.enum ["env" "op"];
      default =
        if pkgs.stdenv.isDarwin
        then "op"
        else "env";
      description = "Credential source for MCP rendering (environment may override DEV_CONFIG_MCP_AUTH_SOURCE).";
    };

    enableProjectServers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Trust and load project-level .mcp.json servers. Sets Claude Code's
        `enableAllProjectMcpServers` and OMP's `mcp.enableProjectConfig`.
      '';
    };

    targets = {
      claude = lib.mkOption {
        type = lib.types.bool;
        default = config.dev-config.claude-code.enable or false;
        description = "Render MCP servers into ~/.claude.json when Claude Code is enabled.";
      };
      omp = lib.mkOption {
        type = lib.types.bool;
        default = config.dev-config.omp.enable or false;
        defaultText = lib.literalExpression "omp.enable";
        description = "Render MCP servers into ~/.omp/agent/mcp.json.";
      };
      codex = lib.mkOption {
        type = lib.types.bool;
        default = config.dev-config.codex.enable or false;
        description = "Render MCP servers into ~/.codex/config.toml when Codex is enabled.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Render after secrets are available. A failure must fail activation rather
    # than clearing any previously working MCP configuration.
    home.activation.configureMcpServers = lib.hm.dag.entryAfter ["writeBoundary" "sops-nix"] ''
      export PATH="${pkgs.python3}/bin:${lib.optionalString (cfg.authSource == "op") "${pkgs._1password-cli}/bin:"}$PATH"
      DEV_CONFIG_MCP_AUTH_SOURCE="''${DEV_CONFIG_MCP_AUTH_SOURCE:-${cfg.authSource}}" \
      MCP_SERVERS_FILE=${serversJson} \
      MCP_ENABLE_PROJECT=${lib.boolToString cfg.enableProjectServers} \
      MCP_TARGET_CLAUDE=${
        if cfg.targets.claude && (config.dev-config.claude-code.enable or false)
        then "1"
        else "0"
      } \
      MCP_TARGET_OMP=${
        if cfg.targets.omp && (config.dev-config.omp.enable or false)
        then "1"
        else "0"
      } \
      MCP_TARGET_CODEX=${
        if cfg.targets.codex && (config.dev-config.codex.enable or false)
        then "1"
        else "0"
      } \
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${applyScriptSrc}
    '';
  };
}
