{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dev-config.docker = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Docker virtualization";
    };

    autoAddUsers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Automatically add all dev-config users to the docker group.
        This allows running docker commands without sudo.

        ⚠️  SECURITY WARNING: Docker group membership is equivalent to root access!
        Users in the docker group can:
        - Mount host filesystems into containers
        - Run privileged containers
        - Access root-owned files via volume mounts
        - Potentially escape to host root privileges

        For production systems, consider using rootless Docker instead:
          virtualisation.docker.rootless.enable = true;

        This option is suitable for single-user development machines where
        convenience outweighs the security implications.
      '';
    };

    enableOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Docker service on system boot";
    };
  };

  config = lib.mkIf config.dev-config.docker.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = config.dev-config.docker.enableOnBoot;
    };

    # Automatically add dev-config users to docker group
    users.users = lib.mkIf config.dev-config.docker.autoAddUsers (
      lib.mapAttrs (
        username: userCfg:
          lib.mkIf (userCfg.enable && !(builtins.elem "docker" userCfg.extraGroups)) {
            extraGroups = ["docker"];
          }
      )
      config.dev-config.users
    );
  };
}
