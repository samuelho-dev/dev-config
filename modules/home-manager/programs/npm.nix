{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.npm;

  # Generate .npmrc from extraConfig only; registry auth (npm OIDC or
  # per-project .npmrc) is owned outside this module.
  generateNpmrcScript = ''
        # Generate .npmrc at activation time
        NPMRC="$HOME/.npmrc"

        # Remove existing file/symlink
        rm -f "$NPMRC"

        # Create new .npmrc with the configured registry settings
        cat > "$NPMRC" <<'NPMRC_EOF'
    ${cfg.extraConfig}
    NPMRC_EOF

        # Set restrictive permissions
        chmod 600 "$NPMRC" 2>/dev/null || true
  '';
in {
  options.dev-config.npm = {
    enable = lib.mkEnableOption ''
      npm registry configuration.

      Generates ~/.npmrc from extraConfig at activation with 600 permissions.
      Registry authentication is not managed here: use npm OIDC publishing
      tokens or a per-project .npmrc.
    '';

    extraConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Additional .npmrc configuration.
        Appended to the generated .npmrc file.
      '';
      example = ''
        registry=https://registry.npmjs.org/
        save-exact=true
      '';
    };
  };

  config = {
    # Global npm packages must never try to write into the Nix store;
    # prefix ownership is independent of registry auth handling.
    home.sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local";
    # Generate .npmrc at activation time from extraConfig. Skipped when
    # extraConfig is empty so a locally authenticated ~/.npmrc (npm login,
    # per-machine auth) is never overwritten.
    home.activation.generateNpmrc = lib.mkIf (cfg.enable && cfg.extraConfig != "") generateNpmrcScript;

    # Do not install Node/package managers from Nix here. Project repos and
    # user-level installers own those versions; Nix should not shadow them.
  };
}
