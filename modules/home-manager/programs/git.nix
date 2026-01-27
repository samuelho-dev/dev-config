{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dev-config.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable dev-config git setup";
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
      description = "Git user name for commits.";
      example = "John Doe";
    };

    userEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Git user email for commits.";
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
        type = lib.types.enum ["openpgp" "ssh" "x509"];
        default = "ssh";
        description = "Signing format (use 'ssh' for 1Password)";
      };

      key = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SSH public key for signing (e.g., ssh-ed25519 AAAAC3...).";
        example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...";
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

  config = lib.mkIf config.dev-config.git.enable (let
    cfg = config.dev-config.git;
  in {
    programs.git = {
      enable = true;
      package = cfg.package;

      # SSH commit signing configuration
      signing = lib.mkIf cfg.signing.enable {
        key = lib.mkIf (cfg.signing.key != null) cfg.signing.key;
        signByDefault = cfg.signing.signByDefault;
      };

      # Git settings (renamed from extraConfig)
      settings =
        (
          {
            init.defaultBranch = cfg.defaultBranch;
            core.editor = cfg.editor;

            # SSH signing with 1Password
            gpg = lib.mkIf (cfg.signing.enable && cfg.signing.format == "ssh") {
              format = "ssh";
              ssh.program =
                if pkgs.stdenv.isDarwin
                then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
                else "${pkgs._1password-gui}/bin/op-ssh-sign";
            };

            # Prefer SSH URLs for GitHub (auto-rewrite HTTPS to SSH)
            url = lib.mkIf cfg.preferSSH {
              "ssh://git@github.com/".insteadOf = "https://github.com/";
            };
          }
          // lib.optionalAttrs (cfg.userName != null) {user.name = cfg.userName;}
          // lib.optionalAttrs (cfg.userEmail != null) {user.email = cfg.userEmail;}
        )
        // cfg.extraConfig;
    };
  });
}
