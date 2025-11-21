{
  config,
  lib,
  pkgs,
  ...
}: let
  # TODO: Complete sops-nix integration for npm tokens
  #
  # Current Status: Module disabled (npm.enable = false in home.nix)
  #
  # Implementation Plan:
  # 1. Add sops secret declarations in home.nix:
  #    sops.secrets."npm/token" = {};
  #    sops.secrets."npm/github-token" = {};
  #
  # 2. Update this module to read tokens from sops paths:
  #    npmToken = lib.mkOption {
  #      default = if config.sops.secrets ? "npm/token"
  #                then builtins.readFile config.sops.secrets."npm/token".path
  #                else null;
  #    };
  #
  # 3. Use config.sops.secrets."npm/token".path in npmrcContent
  #
  # 4. Test with actual npm registry authentication
  #
  # 5. Re-enable module in home.nix
  #
  # Security Note: Never use builtins.pathExists or builtins.readFile during
  # evaluation - these expose secrets to the Nix store. Only reference
  # sops.secrets.*.path which are decrypted at activation time.
  cfg = config.dev-config.npm;

  # Generate .npmrc content with sops-managed authentication tokens
  npmrcContent = lib.concatStringsSep "\n" (
    lib.filter (x: x != "") [
      # Public npm registry authentication
      (lib.optionalString (cfg.npmToken != null)
        "//registry.npmjs.org/:_authToken=${cfg.npmToken}")

      # GitHub Packages configuration
      (lib.optionalString (cfg.githubPackagesToken != null) ''
        @${cfg.githubScope}:registry=https://npm.pkg.github.com/
        //npm.pkg.github.com/:_authToken=${cfg.githubPackagesToken}
      '')

      # Additional registry configuration
      (lib.optionalString (cfg.extraConfig != "") cfg.extraConfig)
    ]
  );
in {
  options.dev-config.npm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable npm authentication and registry configuration.

        Tokens are managed via sops-nix (not stored in Nix store).
        Configure tokens in secrets/default.yaml under npm section.
      '';
    };

    npmToken = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        NPM authentication token for registry.npmjs.org.

        Automatically loaded from sops secret: npm/token
        Get token from: https://www.npmjs.com/settings/~/tokens

        Security: Token is NOT stored in Nix store. Managed by sops-nix.
      '';
      example = "npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    };

    githubPackagesToken = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        GitHub Personal Access Token for GitHub Packages (npm.pkg.github.com).

        Automatically loaded from sops secret: npm/github-token
        Requires scopes: repo, write:packages, read:packages

        Security: Token is NOT stored in Nix store. Managed by sops-nix.
      '';
      example = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
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
    home.file.".npmrc" = lib.mkIf (cfg.npmToken != null || cfg.githubPackagesToken != null) {
      text = npmrcContent;
      # Restrict permissions for security (tokens are sensitive)
      onChange = ''
        chmod 600 ~/.npmrc
      '';
    };

    # Ensure Node.js tooling is available
    home.packages = [
      # npm comes bundled with nodejs_20 (installed via modules/home-manager/default.nix)
      # pnpm is a separate package
      pkgs.pnpm
    ];
  };
}
