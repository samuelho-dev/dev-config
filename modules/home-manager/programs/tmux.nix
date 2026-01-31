{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: {
  options.dev-config.tmux = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable dev-config tmux setup";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tmux;
      description = "Tmux package to use";
    };

    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if inputs ? dev-config
        then "${inputs.dev-config}/tmux/tmux.conf"
        else null;
      description = ''
        Path to tmux configuration file.
        Set to null to manage configuration separately (e.g., via Chezmoi).
      '';
      example = lib.literalExpression ''"''${inputs.dev-config}/tmux/tmux.conf"'';
    };

    gitmuxConfigSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if inputs ? dev-config
        then "${inputs.dev-config}/tmux/gitmux.conf"
        else null;
      description = "Path to gitmux configuration file";
      example = lib.literalExpression ''"''${inputs.dev-config}/tmux/gitmux.conf"'';
    };

    devpodConnect = {
      enable = lib.mkEnableOption "DevPod tmux integration (Tailscale-based)";

      connectScriptSource = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default =
          if inputs ? dev-config
          then "${inputs.dev-config}/tmux/scripts/devpod-connect.sh"
          else null;
        description = "Path to DevPod connect script";
      };

      statusScriptSource = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default =
          if inputs ? dev-config
          then "${inputs.dev-config}/tmux/scripts/devpod-status.sh"
          else null;
        description = "Path to DevPod status bar script";
      };

      mutagenHookScriptSource = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default =
          if inputs ? dev-config
          then "${inputs.dev-config}/tmux/scripts/devpod-mutagen-hook.sh"
          else null;
        description = "Path to Mutagen auto-sync hook script for DevPod sessions";
      };
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
        sensible # tmux-sensible
        resurrect # tmux-resurrect (save/restore sessions)
        continuum # tmux-continuum (auto-save)
        battery # tmux-battery (battery status)
        cpu # tmux-cpu (CPU/RAM status)
        catppuccin # catppuccin/tmux (theme)
        vim-tmux-navigator # christoomey/vim-tmux-navigator
        yank # tmux-yank (clipboard integration)
        tmux-fzf # sainnhe/tmux-fzf (fuzzy finder)
      ];

      # Extra configuration
      extraConfig =
        ''
          # Enable passthrough for yazi image previews
          set -g allow-passthrough on
          set -ga update-environment TERM
          set -ga update-environment TERM_PROGRAM
        ''
        + lib.optionalString config.dev-config.tmux.devpodConnect.enable ''

          # DevPod Integration (Tailscale SSH sessions)
          if-shell "command -v tailscale || [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]" {
            bind D display-popup -E -w 70% -h 60% "~/.local/bin/devpod-connect.sh"
          }

          # Auto-start Mutagen sync for DevPod sessions (works with resurrect restore too)
          set-hook -g session-created 'run-shell "~/.local/bin/devpod-mutagen-hook.sh #{session_name}"'
        '';
    };

    # Symlink tmux configuration if source is provided
    home.file.".tmux.conf" = lib.mkIf (config.dev-config.tmux.configSource != null) {
      source = config.dev-config.tmux.configSource;
    };

    # Symlink gitmux configuration if source is provided
    home.file.".gitmux.conf" = lib.mkIf (config.dev-config.tmux.gitmuxConfigSource != null) {
      source = config.dev-config.tmux.gitmuxConfigSource;
    };

    # DevPod integration scripts (symlinked to ~/.local/bin/)
    home.file.".local/bin/devpod-connect.sh" =
      lib.mkIf (
        config.dev-config.tmux.devpodConnect.enable
        && config.dev-config.tmux.devpodConnect.connectScriptSource != null
      ) {
        source = config.dev-config.tmux.devpodConnect.connectScriptSource;
        executable = true;
      };

    home.file.".local/bin/devpod-status.sh" =
      lib.mkIf (
        config.dev-config.tmux.devpodConnect.enable
        && config.dev-config.tmux.devpodConnect.statusScriptSource != null
      ) {
        source = config.dev-config.tmux.devpodConnect.statusScriptSource;
        executable = true;
      };

    home.file.".local/bin/devpod-mutagen-hook.sh" =
      lib.mkIf (
        config.dev-config.tmux.devpodConnect.enable
        && config.dev-config.tmux.devpodConnect.mutagenHookScriptSource != null
      ) {
        source = config.dev-config.tmux.devpodConnect.mutagenHookScriptSource;
        executable = true;
      };
  };
}
