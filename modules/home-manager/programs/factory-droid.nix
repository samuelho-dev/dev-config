{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.factory-droid;

  # Path to Factory Droid config assets in dev-config repo
  factoryAssetsPath =
    if inputs ? dev-config
    then "${inputs.dev-config}/.factory"
    else ../../../.factory;
in {
  options.dev-config.factory-droid = {
    enable = lib.mkEnableOption "Factory Droid CLI configuration";

    # Configuration export for lib.devShellHook
    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if builtins.pathExists factoryAssetsPath
        then factoryAssetsPath
        else null;
      description = "Path to Factory Droid configuration directory (.factory/)";
    };

    exportConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Export Factory Droid configs directly to ~/.factory/ (global, writable).
        These are available globally in all projects without project-level sync.
      '';
    };

    # Base settings.json content (projects can extend)
    baseSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        model = "opus";
        reasoningEffort = "medium";
        diffMode = "github";
        cloudSessionSync = true;
        completionSound = "fx-ok01";
        awaitingInputSound = "fx-ack01";
        soundFocusMode = "always";
        todoDisplayMode = "pinned";
        includeCoAuthoredByDroid = true;
        enableDroidShield = true;
        enableCustomDroids = true;
        specSaveEnabled = true;
        specSaveDir = ".factory/specs";
      };
      description = "Base settings.json configuration for consumer projects";
    };
  };

  config = lib.mkIf cfg.enable {
    # Export Factory Droid configs directly to ~/.factory/ (global, writable)
    # These are available in ALL projects automatically
    home.activation.exportFactoryConfigs = lib.mkIf (cfg.exportConfig && cfg.configSource != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Source paths from dev-config
        DROIDS_SRC="${cfg.configSource}/../ai/agents"
        COMMANDS_SRC="${cfg.configSource}/../ai/commands"
        HOOKS_SRC="${cfg.configSource}/../ai/hooks"
        SKILLS_SRC="${cfg.configSource}/../ai/skills"

        # Copy droids (agents) - writable so user can add new ones
        if [ -d "$DROIDS_SRC" ]; then
          $DRY_RUN_CMD rm -rf "$HOME/.factory/droids"
          $DRY_RUN_CMD mkdir -p "$HOME/.factory"
          $DRY_RUN_CMD cp -Lr "$DROIDS_SRC" "$HOME/.factory/droids"
          $DRY_RUN_CMD chmod -R +w "$HOME/.factory/droids"
        fi

        # Copy commands - writable
        if [ -d "$COMMANDS_SRC" ]; then
          $DRY_RUN_CMD rm -rf "$HOME/.factory/commands"
          $DRY_RUN_CMD mkdir -p "$HOME/.factory"
          $DRY_RUN_CMD cp -Lr "$COMMANDS_SRC" "$HOME/.factory/commands"
          $DRY_RUN_CMD chmod -R +w "$HOME/.factory/commands"
        fi

        # Copy hooks - writable
        if [ -d "$HOOKS_SRC" ]; then
          $DRY_RUN_CMD rm -rf "$HOME/.factory/hooks"
          $DRY_RUN_CMD mkdir -p "$HOME/.factory"
          $DRY_RUN_CMD cp -Lr "$HOOKS_SRC" "$HOME/.factory/hooks"
          $DRY_RUN_CMD chmod -R +w "$HOME/.factory/hooks"
        fi

        # Copy skills - writable
        if [ -d "$SKILLS_SRC" ]; then
          $DRY_RUN_CMD rm -rf "$HOME/.factory/skills"
          $DRY_RUN_CMD mkdir -p "$HOME/.factory"
          $DRY_RUN_CMD cp -Lr "$SKILLS_SRC" "$HOME/.factory/skills"
          $DRY_RUN_CMD chmod -R +w "$HOME/.factory/skills"
        fi

        # Create default settings.json if missing
        if [ ! -f "$HOME/.factory/settings.json" ]; then
          $DRY_RUN_CMD echo '${builtins.toJSON cfg.baseSettings}' > "$HOME/.factory/settings.json"
        fi
      ''
    );
  };
}
