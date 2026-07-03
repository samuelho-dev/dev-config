{
  config,
  lib,
  ...
}: let
  cfg = config.dev-config.omp;
in {
  options.dev-config.omp = {
    enable = lib.mkEnableOption "Oh My Pi (omp) coding-agent CLI";

    package = lib.mkOption {
      type = lib.types.str;
      default = "@oh-my-pi/pi-coding-agent";
      description = "npm package for the omp CLI (bin: omp).";
    };
  };

  config = lib.mkIf cfg.enable {
    # omp is not in nixpkgs and pulls native postinstalls (onnxruntime-node,
    # protobufjs), so it can't be a declarative nix package like claude-code.
    # Install it globally via bun when bun is available outside Nix (real-nix
    # machines run HM activation). In the devpod/orca images — where HM
    # activation does NOT run — the container entrypoint performs the same
    # `bun add -g` on boot. Both paths need bun >= 1.3.14 (see pkgs/default.nix).
    home.activation.installOmpCli = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      if command -v bun &>/dev/null; then
        if ! command -v omp &>/dev/null || ! omp --version &>/dev/null 2>&1; then
          $DRY_RUN_CMD bun add -g ${cfg.package} 2>/dev/null || true
        fi
      fi
    '';
  };
}
