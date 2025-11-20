{ config, pkgs, lib, ... }:

let
  # Import secrets.nix if it exists (for git user config and SSH signing key)
  secretsPath = "${config.xdg.configHome}/home-manager/secrets.nix";
  secrets = if builtins.pathExists secretsPath
    then import secretsPath
    else {};
in {
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
      default = secrets.gitUserName or null;
      description = ''
        Git user name (required for commits).
        Automatically imported from ~/.config/home-manager/secrets.nix if present.
      '';
      example = "John Doe";
    };

    userEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = secrets.gitUserEmail or null;
      description = ''
        Git user email (required for commits).
        Automatically imported from ~/.config/home-manager/secrets.nix if present.
      '';
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

    # SSH commit signing with 1Password
    signing = {
      enable = lib.mkEnableOption "Git commit signing";

      format = lib.mkOption {
        type = lib.types.enum [ "openpgp" "ssh" "x509" ];
        default = "ssh";
        description = "Signing format (use 'ssh' for 1Password)";
      };

      key = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = secrets.sshSigningKey or null;
        description = ''
          SSH public key for signing.
          Automatically imported from ~/.config/home-manager/secrets.nix if present.
          Example: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-email@example.com"
        '';
      };

      signByDefault = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Sign all commits by default (no need for -S flag)";
      };
    };

    # Prefer SSH URLs for GitHub (auto-rewrite HTTPS to SSH)
    preferSSH = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically rewrite GitHub HTTPS URLs to SSH";
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

      # SSH commit signing configuration
      signing = lib.mkIf config.dev-config.git.signing.enable {
        key = config.dev-config.git.signing.key;
        signByDefault = config.dev-config.git.signing.signByDefault;
      };

      extraConfig = {
        init.defaultBranch = config.dev-config.git.defaultBranch;
        core.editor = config.dev-config.git.editor;

        # SSH signing with 1Password
        gpg = lib.mkIf (config.dev-config.git.signing.enable && config.dev-config.git.signing.format == "ssh") {
          format = "ssh";
          ssh.program = if pkgs.stdenv.isDarwin
            then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
            else "${pkgs._1password-gui}/bin/op-ssh-sign";
        };

        # Prefer SSH URLs for GitHub (auto-rewrite HTTPS to SSH)
        url = lib.mkIf config.dev-config.git.preferSSH {
          "ssh://git@github.com/".insteadOf = "https://github.com/";
        };
      } // config.dev-config.git.extraConfig;
    };
  };
}
