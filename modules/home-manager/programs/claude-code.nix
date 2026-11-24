{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.claude-code;
  pluginsFileSrc =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/claude/plugins.txt"
    else ../../../ai/claude/plugins.txt;
  applyPluginsScriptSrc =
    if inputs ? dev-config
    then "${inputs.dev-config}/ai/claude/apply-plugins.sh"
    else ../../../ai/claude/apply-plugins.sh;
in {
  options.dev-config.claude-code.enable = lib.mkEnableOption "writable native Claude Code CLI";

  # The shared bootstrap owns the native CLI; plugins follow only after it succeeds.
  config.home.activation.installClaudePlugins = lib.mkIf cfg.enable (
    lib.hm.dag.entryAfter ["bootstrapNativeTools"] ''
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        PATH="$HOME/.local/bin:${config.home.path}/bin:$PATH" \
          CLAUDE_PLUGINS_FILE=${pluginsFileSrc} \
          ${pkgs.bash}/bin/bash ${applyPluginsScriptSrc}
      fi
    ''
  );
}
