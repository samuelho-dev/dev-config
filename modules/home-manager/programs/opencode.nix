{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.opencode;
in {
  options.dev-config.opencode = {
    enable = lib.mkEnableOption "Opencode CLI with Gemini OAuth authentication";

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["opencode-gemini-auth@latest"];
      description = "Opencode plugins to configure in opencode.json";
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional top-level fields to merge into opencode.json";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install opencode CLI via bun (npm package not in nixpkgs)
    # Requires bun in PATH (provided by dev-config.npm module)
    home.activation.installOpencodeCli = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      if command -v bun &>/dev/null; then
        if ! command -v opencode &>/dev/null || ! opencode --version &>/dev/null 2>&1; then
          $DRY_RUN_CMD bun add -g opencode-ai 2>/dev/null || true
        fi
      fi
    '';

    # Generate ~/.config/opencode/opencode.json with plugin configuration
    home.activation.configureOpencode = lib.hm.dag.entryAfter ["writeBoundary"] (let
      opencodeConfig =
        {
          plugin = cfg.plugins;
        }
        // cfg.extraConfig;
    in ''
      OPENCODE_DIR="$HOME/.config/opencode"
      OPENCODE_JSON="$OPENCODE_DIR/opencode.json"

      $DRY_RUN_CMD mkdir -p "$OPENCODE_DIR"

      # Write config using jq for pretty-printing
      echo '${builtins.toJSON opencodeConfig}' | ${pkgs.jq}/bin/jq '.' > "$OPENCODE_JSON.tmp" && \
      $DRY_RUN_CMD mv "$OPENCODE_JSON.tmp" "$OPENCODE_JSON"
    '');
  };
}
