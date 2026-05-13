# Biome - Fast formatter and linter for JS/TS/JSON
# Config lives in repo root biome.json; this module just installs the package
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.biome;
in {
  options.dev-config.biome = {
    enable = lib.mkEnableOption "Biome linter and formatter";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.biome;
      description = "Biome package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
  };
}
