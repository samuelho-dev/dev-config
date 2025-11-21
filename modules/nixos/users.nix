{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dev-config.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "dev-config user setup";

        shell = lib.mkOption {
          type = lib.types.package;
          default = pkgs.zsh;
          description = "Default shell for the user";
        };

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["docker" "wheel"];
          description = "Additional groups for the user";
          example = ["docker" "wheel" "audio" "video"];
        };

        isSystemUser = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this is a system user (vs normal user)";
        };

        home = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = "Home directory path. Defaults to /home/{username}";
        };
      };
    });
    default = {};
    description = "Users to configure with dev-config setup";
    example = lib.literalExpression ''
      {
        developer = {
          enable = true;
          extraGroups = [ "docker" "wheel" ];
        };
        ci-runner = {
          enable = true;
          isSystemUser = true;
          extraGroups = [ "docker" ];
        };
      }
    '';
  };

  config = {
    users.users = lib.mapAttrs (username: cfg:
      lib.mkIf cfg.enable {
        isNormalUser = !cfg.isSystemUser;
        isSystemUser = cfg.isSystemUser;
        shell = cfg.shell;
        extraGroups = cfg.extraGroups;
        home =
          if cfg.home != null
          then cfg.home
          else "/home/${username}";
      })
    config.dev-config.users;
  };
}
