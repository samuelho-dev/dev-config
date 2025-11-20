{ config, pkgs, lib, inputs, ... }:

{
  options.dev-config.tmux = {
    enable = lib.mkEnableOption "dev-config tmux setup" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tmux;
      description = "Tmux package to use";
    };

    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = if inputs ? dev-config then "${inputs.dev-config}/tmux/tmux.conf" else null;
      description = ''
        Path to tmux configuration file.
        Set to null to manage configuration separately (e.g., via Chezmoi).
      '';
      example = lib.literalExpression ''"''${inputs.dev-config}/tmux/tmux.conf"'';
    };

    gitmuxConfigSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = if inputs ? dev-config then "${inputs.dev-config}/tmux/gitmux.conf" else null;
      description = "Path to gitmux configuration file";
      example = lib.literalExpression ''"''${inputs.dev-config}/tmux/gitmux.conf"'';
    };

    # Declarative options matching our tmux.conf settings
    prefix = lib.mkOption {
      type = lib.types.str;
      default = "C-a";
      description = "Tmux prefix key";
    };

    baseIndex = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Base index for windows and panes";
    };

    mouse = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable mouse support";
    };

    historyLimit = lib.mkOption {
      type = lib.types.int;
      default = 10000;
      description = "Scrollback buffer size";
    };
  };

  config = lib.mkIf config.dev-config.tmux.enable {
    programs.tmux = {
      enable = true;
      package = config.dev-config.tmux.package;
      prefix = config.dev-config.tmux.prefix;
      baseIndex = config.dev-config.tmux.baseIndex;
      mouse = config.dev-config.tmux.mouse;
      historyLimit = config.dev-config.tmux.historyLimit;

      # Install tmux plugins via Nix (replaces TPM)
      plugins = with pkgs.tmuxPlugins; [
        sensible           # tmux-sensible
        resurrect          # tmux-resurrect (save/restore sessions)
        continuum          # tmux-continuum (auto-save)
        battery            # tmux-battery (battery status)
        cpu                # tmux-cpu (CPU/RAM status)
        catppuccin         # catppuccin/tmux (theme)
        vim-tmux-navigator # christoomey/vim-tmux-navigator
        yank               # tmux-yank (clipboard integration)
        tmux-fzf           # sainnhe/tmux-fzf (fuzzy finder)
      ];
    };

    # Symlink tmux configuration if source is provided
    home.file.".tmux.conf" = lib.mkIf (config.dev-config.tmux.configSource != null) {
      source = config.dev-config.tmux.configSource;
    };

    # Symlink gitmux configuration if source is provided
    home.file.".gitmux.conf" = lib.mkIf (config.dev-config.tmux.gitmuxConfigSource != null) {
      source = config.dev-config.tmux.gitmuxConfigSource;
    };
  };
}
