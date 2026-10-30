{lib, ...}: {
  options.dev-config.claude-code.enable = lib.mkEnableOption "writable native Claude Code CLI";
}
