{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  hunkSource =
    if inputs ? dev-config
    then "${inputs.dev-config}/hunk"
    else ../../../hunk;
in {
  options.dev-config.hunk.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable dev-config Hunk configuration";
  };

  config = lib.mkIf (config.dev-config.enable && config.dev-config.hunk.enable) {
    xdg.configFile."hunk/config.toml".source = "${hunkSource}/config.toml";
    xdg.configFile."hunk/extensions" = lib.mkIf pkgs.stdenv.isDarwin {
      source = "${hunkSource}/extensions";
      recursive = true;
    };
  };
}
