{ config, pkgs, lib, inputs, ... }:

{
  options.dev-config.neovim = {
    enable = lib.mkEnableOption "dev-config Neovim setup" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovim;
      description = "Neovim package to use";
    };

    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = if inputs ? dev-config then "${inputs.dev-config}/nvim" else null;
      description = ''
        Path to Neovim configuration directory.
        Set to null to manage configuration separately (e.g., via Chezmoi).
      '';
      example = lib.literalExpression ''"''${inputs.dev-config}/nvim"'';
    };

    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set Neovim as the default editor (EDITOR environment variable)";
    };

    vimAlias = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Create 'vim' alias for 'nvim'";
    };

    viAlias = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Create 'vi' alias for 'nvim'";
    };
  };

  config = lib.mkIf config.dev-config.neovim.enable {
    programs.neovim = {
      enable = true;
      package = config.dev-config.neovim.package;
      defaultEditor = config.dev-config.neovim.defaultEditor;
      vimAlias = config.dev-config.neovim.vimAlias;
      viAlias = config.dev-config.neovim.viAlias;
    };

    # Symlink Neovim configuration if source is provided
    xdg.configFile."nvim" = lib.mkIf (config.dev-config.neovim.configSource != null) {
      source = config.dev-config.neovim.configSource;
      recursive = true;
    };
  };
}
