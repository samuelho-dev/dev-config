# TypeScript Strict Configuration
# Provides maximum strictness tsconfig templates for consumer projects
# Symlinked to ~/.config/tsconfig/ for easy extension
{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.typescript;

  # Path to tsconfig templates in dev-config repo
  tsconfigPath =
    if inputs ? dev-config
    then "${inputs.dev-config}/tsconfig"
    else ../../../tsconfig;
in {
  options.dev-config.typescript = {
    enable = lib.mkEnableOption "TypeScript strict configuration templates";

    strictConfigSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if builtins.pathExists tsconfigPath
        then "${tsconfigPath}/tsconfig.strict.json"
        else null;
      description = "Path to strict tsconfig template (maximum type safety)";
    };

    monorepoConfigSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if builtins.pathExists tsconfigPath
        then "${tsconfigPath}/tsconfig.monorepo.json"
        else null;
      description = "Path to monorepo tsconfig template (composite + incremental)";
    };

    libraryConfigSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if builtins.pathExists tsconfigPath
        then "${tsconfigPath}/tsconfig.library.json"
        else null;
      description = "Path to library tsconfig template (NodeNext for npm publishing)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Symlink tsconfig templates to ~/.config/tsconfig/
    # Consumer projects can extend from these:
    #   "extends": "~/.config/tsconfig/tsconfig.strict.json"
    xdg.configFile = {
      "tsconfig/tsconfig.strict.json" = lib.mkIf (cfg.strictConfigSource != null) {
        source = cfg.strictConfigSource;
      };

      "tsconfig/tsconfig.monorepo.json" = lib.mkIf (cfg.monorepoConfigSource != null) {
        source = cfg.monorepoConfigSource;
      };

      "tsconfig/tsconfig.library.json" = lib.mkIf (cfg.libraryConfigSource != null) {
        source = cfg.libraryConfigSource;
      };
    };
  };
}
