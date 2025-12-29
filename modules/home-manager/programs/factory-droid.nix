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
        Export Factory Droid configs to ~/.config/factory-droid/.
        Consumer projects use lib.devShellHook to link .factory/ on nix develop.
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
    # Export Factory Droid configs to ~/.config/factory-droid/ for lib.devShellHook
    xdg.configFile = lib.mkIf (cfg.exportConfig && cfg.configSource != null) {
      # Pull from centralized ai/ directory
      "factory-droid/droids".source = cfg.configSource + "/../ai/agents";
      "factory-droid/commands".source = cfg.configSource + "/../ai/commands";
      "factory-droid/hooks".source = cfg.configSource + "/../ai/hooks";

      # Settings stay in .factory
      "factory-droid/settings-base.json".text = builtins.toJSON cfg.baseSettings;
    };

    # Note: Commands/droids/hooks are NOT deployed globally to ~/.factory/
    # They are only available at the project level (.factory/commands/) to avoid duplicates.
    # Use lib.devShellHook in project flakes to link .factory/ on nix develop.
  };
}
