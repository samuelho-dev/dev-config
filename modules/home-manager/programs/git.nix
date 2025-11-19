{ config, pkgs, lib, ... }:

{
  options.dev-config.git = {
    enable = lib.mkEnableOption "dev-config git setup" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.git;
      description = "Git package to use";
    };

    # Core git configuration
    userName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Git user name (required for commits)";
      example = "John Doe";
    };

    userEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Git user email (required for commits)";
      example = "john@example.com";
    };

    defaultBranch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Default branch name for new repositories";
    };

    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default editor for git commit messages";
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional git configuration";
      example = lib.literalExpression ''
        {
          pull.rebase = false;
          push.autoSetupRemote = true;
        }
      '';
    };
  };

  config = lib.mkIf config.dev-config.git.enable {
    programs.git = {
      enable = true;
      package = config.dev-config.git.package;

      userName = lib.mkIf (config.dev-config.git.userName != null) config.dev-config.git.userName;
      userEmail = lib.mkIf (config.dev-config.git.userEmail != null) config.dev-config.git.userEmail;

      extraConfig = {
        init.defaultBranch = config.dev-config.git.defaultBranch;
        core.editor = config.dev-config.git.editor;
      } // config.dev-config.git.extraConfig;
    };
  };
}
