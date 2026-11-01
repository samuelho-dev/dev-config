{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  source =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/bootstrap.sh"
    else ../../../ai/bootstrap.sh;
  skillsSource =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/sync-skills.sh"
    else ../../../ai/sync-skills.sh;
  enabled =
    lib.optional config.dev-config.omp.enable "omp"
    ++ lib.optional config.dev-config.pi.enable "pi"
    ++ lib.optional config.dev-config.claude-code.enable "claude"
    ++ lib.optional config.dev-config.opencode.enable "opencode"
    ++ lib.optional config.dev-config.codex.enable "codex"
    ++ lib.optional config.dev-config.vercel.enable "vercel"
    ++ lib.optional config.dev-config.rex-worktrees.enable "rex-worktrees";
in {
  config = lib.mkIf config.dev-config.enable {
    home.sessionPath = ["$HOME/.local/bin"];
    xdg.configFile."dev-config/native-tools".text = lib.concatMapStringsSep "\n" (tool: tool) enabled + "\n";
    home.activation.bootstrapNativeTools = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        PATH="$HOME/.local/bin:${config.home.path}/bin:${lib.makeBinPath [pkgs.curl pkgs.coreutils pkgs.bash]}:$PATH${lib.optionalString pkgs.stdenv.isDarwin ":/opt/homebrew/bin"}:/usr/local/bin:/usr/bin:/bin" \
          ${pkgs.bash}/bin/bash ${source} install ${lib.escapeShellArgs enabled}
      fi
    '';
    home.activation.syncNativeSkills = lib.hm.dag.entryAfter ["bootstrapNativeTools"] ''
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        ${pkgs.bash}/bin/bash ${skillsSource}
      fi
    '';
  };
}
