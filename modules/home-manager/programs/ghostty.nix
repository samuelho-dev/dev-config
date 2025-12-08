{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.dev-config.ghostty = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable dev-config Ghostty setup";
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = pkgs.ghostty or null;
      description = ''
        Ghostty package to use.
        Note: Ghostty may not be available in nixpkgs yet.
        Set to null if installing manually (e.g., via Homebrew on macOS).
      '';
    };

    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if inputs ? dev-config
        then "${inputs.dev-config}/ghostty/config"
        else null;
      description = ''
        Path to Ghostty configuration file.
        Set to null to manage configuration separately (e.g., via Chezmoi).
      '';
      example = lib.literalExpression ''"''${inputs.dev-config}/ghostty/config"'';
    };
  };

  config = lib.mkIf config.dev-config.ghostty.enable {
    # Install Ghostty package if available in nixpkgs
    home.packages = lib.optional (config.dev-config.ghostty.package != null) config.dev-config.ghostty.package;

    # Symlink Ghostty configuration if source is provided
    # Platform-specific paths:
    # - macOS: ~/Library/Application Support/com.mitchellh.ghostty/config
    # - Linux: ~/.config/ghostty/config (XDG standard)
    home.file = lib.mkIf (config.dev-config.ghostty.configSource != null) (
      if pkgs.stdenv.isDarwin
      then {
        "Library/Application Support/com.mitchellh.ghostty/config".source = config.dev-config.ghostty.configSource;
      }
      else {}
    );

    xdg.configFile = lib.mkIf (config.dev-config.ghostty.configSource != null) (
      if pkgs.stdenv.isLinux
      then {
        "ghostty/config".source = config.dev-config.ghostty.configSource;
      }
      else {}
    );
  };
}
