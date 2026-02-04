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

      bootstrapScriptSource = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default =
          if inputs ? dev-config
          then "${inputs.dev-config}/tmux/scripts/devpod-bootstrap.sh"
          else null;
        description = "Path to DevPod bootstrap script that auto-creates sessions on tmux start";
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
      terminal = "tmux-256color";
      keyMode = "vi";
      escapeTime = 0;
      aggressiveResize = true;
      focusEvents = true;

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

      # All configuration ported from raw tmux.conf — single source of truth
      extraConfig =
        ''
          # Terminal settings
          set -as terminal-overrides ",*:Tc"
          set -as terminal-features ",*:hyperlinks"
          set -g allow-passthrough on
          set -ga update-environment TERM
          set -ga update-environment TERM_PROGRAM

          # Use login shell (inherits from environment)
          set -g default-command "''${SHELL}"

          # Window/pane settings
          setw -g pane-base-index 1
          set -g renumber-windows on
          set -g repeat-time 300

          # -------------------------------------------------------------------
          # Key Bindings
          # -------------------------------------------------------------------

          # Quick configuration reload
          bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded!"

          # Split panes using | and - (more intuitive)
          bind | split-window -h -c "#{pane_current_path}"
          bind - split-window -v -c "#{pane_current_path}"
          unbind '"'
          unbind %

          # Resize panes with Vim keys
          bind -r H resize-pane -L 5
          bind -r J resize-pane -D 5
          bind -r K resize-pane -U 5
          bind -r L resize-pane -R 5

          # Rename pane title
          bind t command-prompt -p "Pane title:" "select-pane -T '%%'"

          # Enhanced tree view showing windows with pane counts and titles
          bind w choose-tree -Zw -F "#{window_name} (#{window_panes} panes)#{?pane_title, - #{pane_title},}"

          # Full tree view with all sessions, windows, and panes
          bind W choose-tree -Z

          # -------------------------------------------------------------------
          # Copy Mode (Vi-style)
          # -------------------------------------------------------------------
          bind-key -T copy-mode-vi v send -X begin-selection
          bind-key -T copy-mode-vi V send -X select-line
          bind-key -T copy-mode-vi C-v send -X rectangle-toggle

          # macOS clipboard integration
          if-shell "uname | grep -q Darwin" {
            bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"
            bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "pbcopy"
          }

          # Enter copy mode with Prefix + Enter
          bind Enter copy-mode

          # -------------------------------------------------------------------
          # Status Bar
          # -------------------------------------------------------------------
          set -g status-position bottom
          set -g status-interval 15
          set -g status-style "bg=black,fg=white"

          set -g status-left-length 60
          set -g status-left "#[fg=green]#S #[fg=yellow]#I #[fg=cyan]#P:#[fg=magenta]#{pane_title}"

          set -g status-right-length 60
          set -g status-right "#(~/.local/bin/devpod-status.sh)#[fg=cyan]#H #[fg=yellow]%H:%M %d-%b-%y"

          setw -g window-status-format " #I: #W "
          setw -g window-status-current-format "#[fg=black,bg=cyan,bold] #I: #W "

          # Pane borders
          set -g pane-border-style "fg=colour238"
          set -g pane-active-border-style "fg=cyan"
          set -g pane-border-status top
          set -g pane-border-format "#[fg=colour238]#P: #{pane_title} #(env -u DIRENV_DIR -u DIRENV_WATCHES gitmux -cfg ~/.gitmux.conf '#{pane_current_path}')"

          # -------------------------------------------------------------------
          # Popup Windows
          # -------------------------------------------------------------------
          bind ! display-popup -E -w 60% -h 75%

          bind m command-prompt -p "New session name:" "new-session -s '%%' -c '#{pane_current_path}'"

          if-shell "command -v fzf" {
            bind ` display-popup -E -w 60% -h 50% "tmux list-sessions | fzf --reverse --header='Select session:' | cut -d: -f1 | xargs tmux switch-client -t"
          }

          if-shell "command -v fzf" {
            bind X display-popup -E "tmux list-sessions -F '#{?session_attached,,#{session_name}}' | fzf --reverse | xargs -I {} tmux kill-session -t {}"
          }

          if-shell "command -v lazygit" {
            bind g display-popup -E -w 80% -h 80% "lazygit"
          }

          # -------------------------------------------------------------------
          # Plugin Settings
          # -------------------------------------------------------------------
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-processes 'ssh'
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60'
          set -g @catppuccin_flavour 'mocha'
        ''
        + lib.optionalString config.dev-config.tmux.devpodConnect.enable ''

          # -------------------------------------------------------------------
          # DevPod Integration (Tailscale SSH sessions)
          # -------------------------------------------------------------------
          # Uses new-window for fzf picker to avoid display-popup + switch-client crash
          if-shell "command -v tailscale || [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]" {
            bind D new-window -n "devpod" "$HOME/Projects/infra/dev-config/tmux/scripts/devpod-connect.sh"
          }

          # Bootstrap: auto-create devpod sessions for online DevPods on server start
          # Run synchronously so sessions are ready before user interaction
          run-shell "bash $HOME/Projects/infra/dev-config/tmux/scripts/devpod-bootstrap.sh"
        '';
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

    home.file.".local/bin/devpod-bootstrap.sh" =
      lib.mkIf (
        config.dev-config.tmux.devpodConnect.enable
        && config.dev-config.tmux.devpodConnect.bootstrapScriptSource != null
      ) {
        source = config.dev-config.tmux.devpodConnect.bootstrapScriptSource;
        executable = true;
      };
  };
}
