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

  # Shell script to inject tokens from sops secrets
  injectTokensScript = ''
    # Read tokens from sops secret files and inject into .npmrc
    NPMRC="$HOME/.npmrc"

    ${lib.optionalString (npmToken != null) ''
      if [ -f "${npmToken}" ]; then
        NPM_TOKEN=$(cat "${npmToken}")
        sed -i.bak "s|__NPM_TOKEN__|$NPM_TOKEN|g" "$NPMRC"
      fi
    ''}

    ${lib.optionalString (githubPackagesToken != null) ''
      if [ -f "${githubPackagesToken}" ]; then
        GITHUB_TOKEN=$(cat "${githubPackagesToken}")
        sed -i.bak "s|__GITHUB_PACKAGES_TOKEN__|$GITHUB_TOKEN|g" "$NPMRC"
      fi
    ''}

    # Clean up backup file
    rm -f "$NPMRC.bak"

    # Set restrictive permissions
    chmod 600 "$NPMRC"
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
    # Generate .npmrc in home directory with sops-managed tokens
    home.file.".npmrc" = lib.mkIf (npmToken != null || githubPackagesToken != null) {
      text = npmrcTemplate;
      # Inject tokens from sops secrets at activation time
      onChange = injectTokensScript;
    };

    # Ensure Node.js tooling is available
    home.packages = [
      # npm comes bundled with nodejs_20 (installed via modules/home-manager/default.nix)
      # pnpm is a separate package
      pkgs.pnpm
    ];
  };
}
