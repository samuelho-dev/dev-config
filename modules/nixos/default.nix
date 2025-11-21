{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./docker.nix
    ./shell.nix
  ];

  # Global dev-config options
  options.dev-config = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable minimal dev-config NixOS setup";
    };
  };

  config = lib.mkIf config.dev-config.enable {
    # Minimal system packages (only essentials)
    environment.systemPackages = [
      pkgs.git # System-wide version control
      pkgs.vim # Minimal editor for emergency access
    ];

    # This module provides minimal system-level configuration:
    # - Docker daemon (optional, see docker.nix)
    # - Zsh shell enablement (see shell.nix)
    # - Essential system utilities only
    #
    # User packages should be managed via Home Manager
  };
}
