{
  config,
  pkgs,
  lib,
  ...
}: {
  options.dev-config.shell = {
    enable =
      lib.mkEnableOption "Zsh shell configuration"
      // {
        default = true;
      };

    defaultShell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zsh;
      description = "Default shell package for the system";
    };

    enableCompletion = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable zsh completion system-wide";
    };

    enableSyntaxHighlighting = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable zsh syntax highlighting";
    };

    enableAutosuggestions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable zsh autosuggestions";
    };
  };

  config = lib.mkIf config.dev-config.shell.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = config.dev-config.shell.enableCompletion;
      syntaxHighlighting.enable = config.dev-config.shell.enableSyntaxHighlighting;
      autosuggestions.enable = config.dev-config.shell.enableAutosuggestions;
    };

    # Set zsh as the default shell for new users
    users.defaultUserShell = config.dev-config.shell.defaultShell;

    # Environment variables for zsh
    environment.variables = {
      SHELL = lib.mkDefault "${config.dev-config.shell.defaultShell}/bin/zsh";
    };
  };
}
