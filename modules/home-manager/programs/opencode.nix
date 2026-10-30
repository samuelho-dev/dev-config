{
  config,
  lib,
  pkgs,
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
    # Keep a user-owned configuration intact; seed only when absent.
    home.activation.configureOpencode = lib.hm.dag.entryAfter ["writeBoundary"] (let
      opencodeConfig = {plugin = cfg.plugins;} // cfg.extraConfig;
      seed = pkgs.writeText "opencode-default.json" (builtins.toJSON opencodeConfig);
    in ''
      if [ -z "''${DRY_RUN_CMD:-}" ] && [ ! -e "$HOME/.config/opencode/opencode.json" ]; then
        mkdir -p "$HOME/.config/opencode"
        cp -n ${seed} "$HOME/.config/opencode/opencode.json"
      fi
    '');
  };
}
