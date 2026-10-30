{lib, ...}: {
  options.dev-config.vercel.enable = lib.mkEnableOption "writable native Vercel CLI and vc alias";
}
