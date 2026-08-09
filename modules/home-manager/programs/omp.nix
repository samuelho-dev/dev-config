{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.omp;
  ompPackage = (import ../../../pkgs {inherit pkgs;}).omp-cli;
  pluginsFileSrc =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/omp/plugins.txt"
    else ../../../ai/omp/plugins.txt;
  applyPluginsScriptSrc =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/omp/apply-plugins.sh"
    else ../../../ai/omp/apply-plugins.sh;
in {
  options.dev-config.omp = {
    enable = lib.mkEnableOption "Oh My Pi (omp) coding-agent CLI";

    obsidian = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install pi-obsidian and publish a headless Obsidian vault config for OMP.";
      };

      package = lib.mkOption {
        type = lib.types.str;
        default = "pi-obsidian";
        description = "npm package that provides the OMP-compatible Obsidian extension.";
      };

      vaultPath = lib.mkOption {
        type = lib.types.str;
        default = "$HOME/Obsidian/Main";
        description = "Filesystem path exposed to pi-obsidian as the default vault.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # OMP is a pinned native Nix package. Remove launchers from the former
    # binary and Bun installs so PATH cannot select a second copy.
    home.activation.removeLegacyOmpCli = lib.hm.dag.entryBefore ["writeBoundary"] ''
      $DRY_RUN_CMD rm -f "$HOME/.local/bin/omp" "$HOME/.bun/bin/omp"
    '';
    home.packages = lib.mkIf (!config.dev-config.packages.enable) [ompPackage];

    home.activation.installOmpPlugins = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      export PATH="${ompPackage}/bin:$PATH"
      OMP_PLUGINS_FILE=${pluginsFileSrc} \
        $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${applyPluginsScriptSrc} || true
    '';

    home.activation.installPiObsidian = lib.mkIf cfg.obsidian.enable (
      lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
        $DRY_RUN_CMD ${pkgs.bun}/bin/bun add -g ${cfg.obsidian.package} 2>/dev/null || true

        VAULT_PATH="${cfg.obsidian.vaultPath}"
        $DRY_RUN_CMD mkdir -p "$HOME/.config/obsidian" "$VAULT_PATH"
        if [ -z "''${DRY_RUN_CMD:-}" ]; then
          printf '{"vaults":{"main":{"path":"%s","ts":0,"open":true}}}\n' "$VAULT_PATH" > "$HOME/.config/obsidian/obsidian.json"
        fi
      ''
    );
  };
}
