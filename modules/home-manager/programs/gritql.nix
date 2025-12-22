# GritQL - Structural code search, linting, and rewriting
# Manages shared patterns and generates user-level config for portable environments
{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.gritql;

  # Path to gritql patterns in dev-config repo
  patternsPath =
    if inputs ? dev-config
    then "${inputs.dev-config}/gritql-patterns"
    else ../../../gritql-patterns;

  # Check if patterns directory exists
  patternsExist = builtins.pathExists patternsPath;
in {
  options.dev-config.gritql = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.dev-config.enable;
      description = "Enable GritQL with shared patterns and XDG directory support";
    };

    patternsSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if patternsExist
        then patternsPath
        else null;
      description = "Path to shared GritQL patterns directory. Set to null to disable pattern symlinking.";
    };

    exportConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Export GritQL patterns to ~/.config/grit/patterns (for init-workspace)
        and ~/.grit/patterns (for global access). Consumer projects can use
        init-workspace to link to these patterns.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Export patterns to ~/.config/grit/patterns for init-workspace to find
    # (follows same pattern as claude-code.nix exports to ~/.config/claude-code/)
    xdg.configFile."grit/patterns" = lib.mkIf (cfg.exportConfig && cfg.patternsSource != null) {
      source = cfg.patternsSource;
      recursive = true;
    };

    # Sync patterns to ~/.grit/patterns for global access
    # GritQL's default user patterns location - works in any repo without setup
    # (follows same pattern as claude-code.nix syncs to ~/.claude/)
    home.file.".grit/patterns" = lib.mkIf (cfg.exportConfig && cfg.patternsSource != null) {
      source = cfg.patternsSource;
      recursive = true;
    };
  };
}
