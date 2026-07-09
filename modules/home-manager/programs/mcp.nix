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
      default = config.dev-config.claude-code.enable or false || config.dev-config.omp.enable or false;
      defaultText = lib.literalExpression "claude-code.enable || omp.enable";
      description = ''
        Render the canonical MCP server list into every agent CLI config
        (Claude Code, OMP, Codex). Single source of truth: ai/mcp/servers.json.
      '';
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
        On nix machines the `op` reference is resolved via 1Password; in
        containers the `env` var (K8s-injected) is used. Project-specific
        servers belong in each project's .mcp.json, not here.
      '';
    };

    extraServers = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional MCP servers merged over `servers` for this machine.";
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
        defaultText = lib.literalExpression "claude-code.enable";
        description = "Render MCP servers into ~/.claude.json.";
      };
      omp = lib.mkOption {
        type = lib.types.bool;
        default = config.dev-config.omp.enable or false;
        defaultText = lib.literalExpression "omp.enable";
        description = "Render MCP servers into ~/.omp/agent/mcp.json.";
      };
      codex = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Render MCP servers into ~/.codex/config.toml (managed block).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Fan the canonical list out to every enabled CLI. Runs after sops-nix so
    # 1Password/secret resolution inside apply-mcp.sh has credentials available.
    home.activation.configureMcpServers = lib.hm.dag.entryAfter ["writeBoundary" "sops-nix"] ''
      export PATH="${pkgs.jq}/bin:${pkgs.python3}/bin:${pkgs._1password-cli}/bin:$PATH"
      MCP_SERVERS_FILE=${serversJson} \
      MCP_ENABLE_PROJECT=${lib.boolToString cfg.enableProjectServers} \
      MCP_TARGET_CLAUDE=${
        if cfg.targets.claude
        then "1"
        else "0"
      } \
      MCP_TARGET_OMP=${
        if cfg.targets.omp
        then "1"
        else "0"
      } \
      MCP_TARGET_CODEX=${
        if cfg.targets.codex
        then "1"
        else "0"
      } \
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${applyScriptSrc} || true
    '';
  };
}
