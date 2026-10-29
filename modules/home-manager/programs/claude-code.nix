{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.claude-code;
  claudeSource =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/claude"
    else ../../../ai/claude;
  discoveryPath = lib.concatStringsSep ":" (
    config.home.sessionPath
    ++ lib.optional pkgs.stdenv.isDarwin "/opt/homebrew/bin"
    ++ ["/usr/local/bin" "/usr/bin" "/bin"]
  );
in {
  options.dev-config.claude-code.enable = lib.mkEnableOption "writable native Claude Code CLI";

  config = lib.mkIf cfg.enable {
    home.sessionPath = ["$HOME/.local/bin"];

    # Supply installer tools and bounded CLI discovery only to this activation.
    home.activation.bootstrapClaudeCode = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        PATH="${lib.makeBinPath [pkgs.curl pkgs.coreutils]}:${config.home.path}/bin:$PATH:${discoveryPath}" \
          ${pkgs.bash}/bin/bash ${claudeSource}/bootstrap.sh
      fi
    '';
  };
}
