{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.pi;
  piSource =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/pi"
    else ../../../ai/pi;
  discoveryPath = lib.concatStringsSep ":" (
    config.home.sessionPath
    ++ lib.optional pkgs.stdenv.isDarwin "/opt/homebrew/bin"
    ++ ["/usr/local/bin" "/usr/bin" "/bin"]
  );
in {
  options.dev-config.pi.enable = lib.mkEnableOption "writable Pi CLI and shared native delegation toolbox";

  config = lib.mkIf cfg.enable {
    home.sessionPath = ["$HOME/.local/bin"];

    # Activation PATH is minimal: supply managed Node/npm and existing CLI locations.
    home.activation.bootstrapPi = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        PATH="${config.home.path}/bin:$PATH:${discoveryPath}" \
          ${pkgs.bash}/bin/bash ${piSource}/bootstrap.sh
      fi
    '';
  };
}
