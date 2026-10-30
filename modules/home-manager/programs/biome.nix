# Biome - shared global defaults for project presets
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.biome;
  projectBiome = builtins.fromJSON (builtins.readFile ../../../biome.json);
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
    # Share portable rules without project-relative plugins, VCS and file scopes.
    home.file.".config/biome/biome.json".text = builtins.toJSON {
      inherit (projectBiome) formatter linter javascript json;
    };
  };
}
