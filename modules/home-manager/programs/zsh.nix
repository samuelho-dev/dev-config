{ config, pkgs, lib, inputs, ... }:

{
  options.dev-config.zsh = {
    enable = lib.mkEnableOption "dev-config zsh setup" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zsh;
      description = "Zsh package to use";
    };

    zshrcSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = if inputs ? dev-config then "${inputs.dev-config}/zsh/.zshrc" else null;
      description = ''
        Path to .zshrc configuration file.
        Set to null to manage configuration separately (e.g., via Chezmoi).
      '';
      example = lib.literalExpression ''"''${inputs.dev-config}/zsh/.zshrc"'';
    };

    zprofileSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = if inputs ? dev-config then "${inputs.dev-config}/zsh/.zprofile" else null;
      description = "Path to .zprofile configuration file";
      example = lib.literalExpression ''"''${inputs.dev-config}/zsh/.zprofile"'';
    };

    p10kSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = if inputs ? dev-config then "${inputs.dev-config}/zsh/.p10k.zsh" else null;
      description = "Path to Powerlevel10k theme configuration";
      example = lib.literalExpression ''"''${inputs.dev-config}/zsh/.p10k.zsh"'';
    };

    # Declarative options
    enableCompletion = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable zsh completion system";
    };

    enableAutosuggestions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable fish-like autosuggestions";
    };

    enableSyntaxHighlighting = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable syntax highlighting";
    };
  };

  config = lib.mkIf config.dev-config.zsh.enable {
    programs.zsh = {
      enable = true;
      package = config.dev-config.zsh.package;
      enableCompletion = config.dev-config.zsh.enableCompletion;
      autosuggestion.enable = config.dev-config.zsh.enableAutosuggestions;
      syntaxHighlighting.enable = config.dev-config.zsh.enableSyntaxHighlighting;
    };

    # Symlink zsh configurations if sources are provided
    home.file.".zshrc" = lib.mkIf (config.dev-config.zsh.zshrcSource != null) {
      source = config.dev-config.zsh.zshrcSource;
    };

    home.file.".zprofile" = lib.mkIf (config.dev-config.zsh.zprofileSource != null) {
      source = config.dev-config.zsh.zprofileSource;
    };

    home.file.".p10k.zsh" = lib.mkIf (config.dev-config.zsh.p10kSource != null) {
      source = config.dev-config.zsh.p10kSource;
    };
  };
}
