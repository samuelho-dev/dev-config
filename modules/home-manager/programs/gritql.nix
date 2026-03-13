# GritQL - Structural code search, linting, and rewriting
# The grit binary is installed via pkgs/default.nix
# Patterns live in biome/gritql-patterns/ and are referenced by root biome.json
{
  config,
  lib,
  ...
}: {
  options.dev-config.gritql = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.dev-config.enable;
      description = "Enable GritQL (binary installed via packages)";
    };
  };
}
