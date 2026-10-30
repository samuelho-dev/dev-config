{lib, ...}: {
  options.dev-config.codex.enable = lib.mkEnableOption "writable native Codex CLI";
}
