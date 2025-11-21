{
  config,
  pkgs,
  lib,
  ...
}: let
  # Import secrets.nix if it exists (for npm tokens)
  secretsPath = "${config.xdg.configHome}/home-manager/secrets.nix";
  secrets =
    if builtins.pathExists secretsPath
    then import secretsPath
    else {};

  cfg = config.dev-config.npm;

  # Generate .npmrc content with authentication tokens
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
    enable =
      lib.mkEnableOption "dev-config npm authentication and registry configuration"
      // {
        default = true;
      };

    # NPM authentication tokens
    npmToken = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = secrets.npmToken or null;
      description = ''
        NPM authentication token for registry.npmjs.org.
        Automatically imported from ~/.config/home-manager/secrets.nix if present.
        Get token from: https://www.npmjs.com/settings/~/tokens
      '';
      example = "npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    };

    githubPackagesToken = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = secrets.githubPackagesToken or null;
      description = ''
        GitHub Personal Access Token for GitHub Packages (npm.pkg.github.com).
        Automatically imported from ~/.config/home-manager/secrets.nix if present.
        Requires scopes: repo, write:packages, read:packages
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
    # Generate .npmrc in home directory
    home.file.".npmrc" = lib.mkIf (cfg.npmToken != null || cfg.githubPackagesToken != null) {
      text = npmrcContent;
      # Restrict permissions for security (tokens are sensitive)
      onChange = ''
        chmod 600 ~/.npmrc
      '';
    };

    # Ensure Node.js with npm is available
    # (Already installed via modules/home-manager/default.nix line 68)
    home.packages = with pkgs; [
      # npm comes bundled with nodejs_20
      # pnpm is a separate package (not yet in home.packages)
      pnpm
    ];
  };
}
