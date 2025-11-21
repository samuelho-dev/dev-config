{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.npm;

  # Read tokens from sops secrets at activation time (not evaluation time)
  # This is secure - tokens are decrypted only during home-manager activation
  # and never exposed to the Nix store
  npmToken =
    if config.sops.secrets ? "npm/token"
    then config.sops.secrets."npm/token".path
    else null;

  githubPackagesToken =
    if config.sops.secrets ? "npm/github-token"
    then config.sops.secrets."npm/github-token".path
    else null;

  # Generate .npmrc content template (tokens injected at activation time)
  # Note: We use placeholder tokens that get replaced by the onChange script
  npmrcTemplate = lib.concatStringsSep "\n" (
    lib.filter (x: x != "") [
      # Public npm registry authentication (if token available)
      (lib.optionalString (npmToken != null)
        "//registry.npmjs.org/:_authToken=__NPM_TOKEN__")

      # GitHub Packages configuration (if token available)
      (lib.optionalString (githubPackagesToken != null) ''
        @${cfg.githubScope}:registry=https://npm.pkg.github.com/
        //npm.pkg.github.com/:_authToken=__GITHUB_PACKAGES_TOKEN__
      '')

      # Additional registry configuration
      (lib.optionalString (cfg.extraConfig != "") cfg.extraConfig)
    ]
  );

  # Shell script to generate .npmrc with actual tokens from sops secrets
  generateNpmrcScript = ''
        # Generate .npmrc file at activation time with real tokens
        NPMRC="$HOME/.npmrc"

        # Remove existing file/symlink
        rm -f "$NPMRC"

        # Create new .npmrc with actual tokens
        cat > "$NPMRC" <<'NPMRC_EOF'
    ${npmrcTemplate}
    NPMRC_EOF

        # Inject real tokens from sops secrets
        ${lib.optionalString (npmToken != null) ''
      if [ -f "${npmToken}" ]; then
        NPM_TOKEN=$(cat "${npmToken}")
        ${pkgs.gnused}/bin/sed -i.bak "s|__NPM_TOKEN__|$NPM_TOKEN|g" "$NPMRC"
      fi
    ''}

        ${lib.optionalString (githubPackagesToken != null) ''
      if [ -f "${githubPackagesToken}" ]; then
        GITHUB_TOKEN=$(cat "${githubPackagesToken}")
        ${pkgs.gnused}/bin/sed -i.bak "s|__GITHUB_PACKAGES_TOKEN__|$GITHUB_TOKEN|g" "$NPMRC"
      fi
    ''}

        # Clean up backup file
        rm -f "$NPMRC.bak"

        # Set restrictive permissions
        chmod 600 "$NPMRC" 2>/dev/null || true
  '';
in {
  options.dev-config.npm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable npm authentication and registry configuration.

        Tokens are automatically loaded from sops secrets:
        - npm/token: NPM registry authentication (registry.npmjs.org)
        - npm/github-token: GitHub Packages authentication (npm.pkg.github.com)

        Configuration:
        1. Add tokens to secrets/default.yaml:
           npm:
             token: npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
             github-token: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

        2. Encrypt with sops:
           sops secrets/default.yaml

        Security: Tokens are never exposed to Nix store. They are decrypted
        at Home Manager activation time and injected into ~/.npmrc with 600 permissions.
      '';
    };

    githubScope = lib.mkOption {
      type = lib.types.str;
      default = "samuelho-dev";
      description = ''
        GitHub username or organization for scoped packages.
        Used for @scope:registry configuration.
      '';
    };

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

  config = lib.mkIf cfg.enable {
    # Generate .npmrc at activation time with sops-managed tokens
    # Run after sops-nix to ensure secrets are decrypted
    home.activation.generateNpmrc = lib.mkIf (npmToken != null || githubPackagesToken != null) (
      lib.hm.dag.entryAfter ["sops-nix"] generateNpmrcScript
    );

    # Ensure Node.js tooling is available
    home.packages = [
      # npm comes bundled with nodejs_20 (installed via modules/home-manager/default.nix)
      # pnpm is a separate package
      pkgs.pnpm
    ];
  };
}
