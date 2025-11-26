{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.dev-config.zsh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable dev-config zsh setup";
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

      # Initialization content with proper ordering for optimal shell startup
      initContent = lib.mkMerge [
        # Powerlevel10k instant prompt - MUST be first (mkOrder 100)
        # This enables near-instant shell startup while loading continues in background
        (lib.mkOrder 100 ''
          # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
          # Initialization code that may require console input (password prompts, [y/n]
          # confirmations, etc.) must go above this block; everything else may go below.
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi
        '')

        # Early init before compinit (mkOrder 550)
        # Suppress oh-my-zsh warnings and direnv verbose output
        (lib.mkOrder 550 ''
          # Silence oh-my-zsh warnings during initialization
          # Theme loads correctly via Nix symlinks after init completes
          ZSH_DISABLE_COMPFIX=true

          # Point to home directory for custom themes/plugins
          # This makes the Powerlevel10k symlink discoverable
          ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

          # Suppress direnv verbose loading messages
          export DIRENV_LOG_FORMAT=""
        '')

        # Additional initialization (runs after compinit - default order ~1000)
        ''
          # Source Powerlevel10k configuration
          [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

          # Credentials loaded by LaunchAgent (macOS) or systemd (Linux) at login
          # No need for per-shell loading - eliminates 50ms overhead
        ''

        # Late init - source machine-specific config (mkOrder 1500)
        # This runs after everything else, allowing local overrides
        (lib.mkOrder 1500 ''
          # Source machine-specific configuration (gitignored)
          # Put custom aliases, PATH additions, or local settings in ~/.zshrc.local
          [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
        '')
      ];

      # Enable Oh My Zsh via Home Manager
      oh-my-zsh = {
        enable = true;
        theme = "powerlevel10k/powerlevel10k";
        plugins = [
          "git"
          # Note: zsh-autosuggestions handled by programs.zsh.autosuggestion above
        ];
      };
    };

    # Install Powerlevel10k theme via Nix
    home.packages = [
      pkgs.zsh-powerlevel10k
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
