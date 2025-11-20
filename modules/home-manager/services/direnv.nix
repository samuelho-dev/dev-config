{
  config,
  pkgs,
  lib,
  ...
}: {
  options.dev-config.direnv = {
    enable =
      lib.mkEnableOption "dev-config direnv setup"
      // {
        default = true;
      };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.direnv;
      description = "Direnv package to use";
    };

    enableNixDirenv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable nix-direnv integration for fast Nix shell loading";
    };

    nix-direnv = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.nix-direnv;
        description = "nix-direnv package to use";
      };
    };
  };

  config = lib.mkIf config.dev-config.direnv.enable {
    programs.direnv = {
      enable = true;
      package = config.dev-config.direnv.package;
      enableZshIntegration = true; # Auto-add direnv hooks to zsh
      nix-direnv = lib.mkIf config.dev-config.direnv.enableNixDirenv {
        enable = true;
        package = config.dev-config.direnv.nix-direnv.package;
      };
    };

    # Environment variable to suppress direnv logs (already in our .zshrc)
    home.sessionVariables = {
      DIRENV_LOG_FORMAT = lib.mkDefault "";
    };
  };
}
