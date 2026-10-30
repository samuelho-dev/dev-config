{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.omp;
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

      vaultPath = lib.mkOption {
        type = lib.types.str;
        default = "$HOME/Obsidian/Main";
        description = "Filesystem path exposed to pi-obsidian as the default vault.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # The shared bootstrap owns the standalone CLI; plugins follow only after it succeeds.
    home.activation.installOmpPlugins = lib.hm.dag.entryAfter ["bootstrapNativeTools"] ''
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        PATH="$HOME/.local/bin:${config.home.path}/bin:$PATH" \
          OMP_PLUGINS_FILE=${pluginsFileSrc} \
          OMP_OBSIDIAN_ENABLED=${
        if cfg.obsidian.enable
        then "true"
        else "false"
      } \
          ${pkgs.bash}/bin/bash ${applyPluginsScriptSrc}
      fi
    '';

    home.activation.configureObsidianVault = lib.mkIf cfg.obsidian.enable (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ -z "''${DRY_RUN_CMD:-}" ]; then
          VAULT_PATH="${cfg.obsidian.vaultPath}"
          mkdir -p "$HOME/.config/obsidian" "$VAULT_PATH"
          if [ ! -e "$HOME/.config/obsidian/obsidian.json" ]; then
            ${pkgs.jq}/bin/jq -n --arg path "$VAULT_PATH" \
              '{vaults:{main:{path:$path,ts:0,open:true}}}' \
              > "$HOME/.config/obsidian/obsidian.json"
          fi
        fi
      ''
    );
  };
}
