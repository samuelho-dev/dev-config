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

    enableUserConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Generate a user-level grit.yaml config at ~/.config/grit/grit.yaml
        that references the shared patterns. This enables patterns to be
        available globally across all repositories.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Symlink shared patterns to XDG config directory
    # Patterns become available at ~/.config/grit/patterns/
    xdg.configFile."grit/patterns" = lib.mkIf (cfg.patternsSource != null) {
      source = cfg.patternsSource;
      recursive = true;
    };

    # Generate user-level grit.yaml with expanded pattern paths
    # This enables patterns to be discoverable globally without per-repo setup
    home.activation.gritUserConfig = lib.mkIf cfg.enableUserConfig (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
                GRIT_USER_CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/grit"
                mkdir -p "$GRIT_USER_CONFIG"

                # Generate grit.yaml with pattern paths
                # Uses the actual XDG path for portability
                cat > "$GRIT_USER_CONFIG/grit.yaml" <<'EOF'
        version: 0.0.1
        # Shared patterns from dev-config repository
        # Symlinked by Home Manager to ~/.config/grit/patterns/
        patterns:
          - file: ${config.xdg.configHome}/grit/patterns/**/*.md
          - file: ${config.xdg.configHome}/grit/patterns/**/*.grit
        EOF
                run echo "Generated $GRIT_USER_CONFIG/grit.yaml"
      ''
    );
  };
}
