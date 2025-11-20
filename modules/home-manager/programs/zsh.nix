{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  options.dev-config.zsh = {
    enable =
      lib.mkEnableOption "dev-config zsh setup"
      // {
        default = true;
      };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zsh;
      description = "Zsh package to use";
    };

    zshrcSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if inputs ? dev-config
        then "${inputs.dev-config}/zsh/.zshrc"
        else null;
      description = ''
        Path to .zshrc configuration file.
        Set to null to manage configuration separately (e.g., via Chezmoi).
      '';
      example = lib.literalExpression ''"''${inputs.dev-config}/zsh/.zshrc"'';
    };

    zprofileSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if inputs ? dev-config
        then "${inputs.dev-config}/zsh/.zprofile"
        else null;
      description = "Path to .zprofile configuration file";
      example = lib.literalExpression ''"''${inputs.dev-config}/zsh/.zprofile"'';
    };

    p10kSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if inputs ? dev-config
        then "${inputs.dev-config}/zsh/.p10k.zsh"
        else null;
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

      # Suppress oh-my-zsh warnings and direnv verbose output
      initExtraBeforeCompInit = ''
        # Silence oh-my-zsh warnings during initialization
        # Theme loads correctly via Nix symlinks after init completes
        ZSH_DISABLE_COMPFIX=true

        # Point to home directory for custom themes/plugins
        # This makes the Powerlevel10k symlink discoverable
        ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

        # Suppress direnv verbose loading messages
        export DIRENV_LOG_FORMAT=""
      '';

      # Enable Oh My Zsh via Home Manager
      oh-my-zsh = {
        enable = true;
        theme = "powerlevel10k/powerlevel10k";
        plugins = [
          "git"
          # Note: zsh-autosuggestions handled by programs.zsh.autosuggestion above
        ];
      };

      # Additional initialization (runs after oh-my-zsh loads)
      initExtra = ''
        # Source Powerlevel10k configuration
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        # Credentials loaded by LaunchAgent (macOS) or systemd (Linux) at login
        # No need for per-shell loading - eliminates 50ms overhead
      '';
    };

    # Install Powerlevel10k theme via Nix
    home.packages = with pkgs; [
      zsh-powerlevel10k
      # zsh-autosuggestions already enabled via programs.zsh.autosuggestion
    ];

    # Symlink Powerlevel10k theme to Oh My Zsh custom themes directory
    # This makes it available for the theme = "powerlevel10k/powerlevel10k" setting
    home.file.".oh-my-zsh/custom/themes/powerlevel10k" = {
      source = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
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
