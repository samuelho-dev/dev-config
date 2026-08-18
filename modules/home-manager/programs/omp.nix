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
    # omp is NOT a Nix package: /nix/store is read-only, so `omp update`
    # refuses to self-update there. Install the standalone binary into
    # ~/.local/bin (on home.sessionPath) once, then let omp update itself.
    home.activation.bootstrapOmpCli = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -z "''${DRY_RUN_CMD:-}" ] && [ ! -x "$HOME/.local/bin/omp" ]; then
        PATH="${lib.makeBinPath [pkgs.curl pkgs.coreutils pkgs.gnugrep pkgs.gnused]}:$PATH" \
          ${pkgs.curl}/bin/curl -fsSL https://omp.sh/install \
          | ${pkgs.bash}/bin/bash -s -- --binary || true
      fi
    '';

    home.activation.installOmpPlugins = lib.hm.dag.entryAfter ["bootstrapOmpCli"] ''
      export PATH="$HOME/.local/bin:$PATH"
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
