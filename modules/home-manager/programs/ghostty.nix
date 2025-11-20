{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  options.dev-config.ghostty = {
    enable =
      lib.mkEnableOption "dev-config Ghostty setup"
      // {
        default = true;
      };

    package = lib.mkOption {
      type = lib.types.package;
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
    # Ghostty config location: ~/.config/ghostty/config (cross-platform)
    xdg.configFile."ghostty/config" = lib.mkIf (config.dev-config.ghostty.configSource != null) {
      source = config.dev-config.ghostty.configSource;
    };
  };
}
