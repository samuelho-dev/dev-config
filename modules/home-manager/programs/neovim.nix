{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.neovim;
  updater = pkgs.writeShellApplication {
    name = "update-neovim-plugins";
    runtimeInputs = [pkgs.git pkgs.coreutils];
    text = ''
      export HOME=${lib.escapeShellArg config.home.homeDirectory}
      export XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome}
      export XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome}
      export XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome}
      export XDG_CACHE_HOME=${lib.escapeShellArg config.xdg.cacheHome}
      export PATH=${lib.escapeShellArg "${config.home.profileDirectory}/bin:${config.home.homeDirectory}/.local/bin:${lib.makeBinPath [pkgs.git pkgs.coreutils]}"}:/usr/bin:/bin

      mkdir -p "$XDG_STATE_HOME/nvim"
      exec ${lib.escapeShellArg "${config.programs.neovim.finalPackage}/bin/nvim"} --headless -i NONE \
        --cmd ${lib.escapeShellArg "lua vim.opt.rtp:prepend(${builtins.toJSON (toString cfg.configSource)})"} \
        --cmd 'lua vim.g.dev_config_plugin_update = true' \
        -u ${lib.escapeShellArg "${cfg.configSource}/init.lua"} \
        -c ${lib.escapeShellArg "luafile ${cfg.configSource}/update-plugins.lua"} \
        >> "$XDG_STATE_HOME/nvim/update-plugins.log" 2>&1
    '';
  };
in {
  options.dev-config.neovim = {
    enable = lib.mkEnableOption "dev-config Neovim setup";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovim-unwrapped;
      description = "Neovim package to use (unwrapped, Home Manager will wrap it)";
    };

    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default =
        if inputs ? dev-config
        then "${inputs.dev-config}/nvim"
        else null;
      description = ''
        Path to Neovim configuration directory.
        Set to null to manage configuration separately (e.g., via Chezmoi).
      '';
      example = lib.literalExpression ''"''${inputs.dev-config}/nvim"'';
    };

    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set Neovim as the default editor (EDITOR environment variable)";
    };

    vimAlias = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Create 'vim' alias for 'nvim'";
    };

    viAlias = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Create 'vi' alias for 'nvim'";
    };
  };

  config = lib.mkIf config.dev-config.neovim.enable {
    programs.neovim = {
      enable = true;
      package = config.dev-config.neovim.package;
      defaultEditor = config.dev-config.neovim.defaultEditor;
      vimAlias = config.dev-config.neovim.vimAlias;
      viAlias = config.dev-config.neovim.viAlias;

      # No Python/Ruby remote-plugin hosts needed (providers disabled in nvim config).
      # Set explicitly to adopt the new (26.05) defaults and silence the legacy warnings.
      withPython3 = false;
      withRuby = false;

      # Plugins managed by lazy.nvim in nvim/lua/plugins/
      # Nix only provides LSP servers/formatters as binaries
      plugins = [];
    };

    # Expose editor tools inside Neovim's wrapper, independent of the shell PATH.
    programs.neovim.extraPackages = [
      # LSP servers
      pkgs.typescript-language-server # TypeScript/JavaScript
      pkgs.pyright # Python
      pkgs.lua-language-server # Lua
      pkgs.biome # JavaScript/TypeScript/JSON linter + formatter

      # Formatters
      pkgs.stylua # Lua formatter
      pkgs.prettier # JS/TS/JSON/YAML/Markdown
      pkgs.ruff # Python formatter + linter
      pkgs.alejandra # Nix formatter (matches `nix fmt`; used by nixd LSP)

      # Nix LSP (eval-based diagnostics/completion for .nix editing)
      pkgs.nixd

      # Build tools for Neovim plugins
      pkgs.gnumake
      pkgs.gcc
      pkgs.pkg-config
      pkgs.imagemagick

      # Mermaid CLI (for mermaid diagram rendering)
      pkgs.mermaid-cli
    ];

    # Also expose the same editor tools to the user's shell.
    home.packages = config.programs.neovim.extraPackages ++ lib.optional (cfg.configSource != null) updater;

    # Symlink Neovim configuration if source is provided
    xdg.configFile."nvim" = lib.mkIf (config.dev-config.neovim.configSource != null) {
      source = config.dev-config.neovim.configSource;
      recursive = true;
    };

    launchd.agents.update-neovim-plugins = lib.mkIf (pkgs.stdenv.isDarwin && cfg.configSource != null) {
      enable = true;
      config = {
        ProgramArguments = ["${updater}/bin/update-neovim-plugins"];
        RunAtLoad = true;
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 0;
          }
        ];
      };
    };

    systemd.user.services.update-neovim-plugins = lib.mkIf (pkgs.stdenv.isLinux && cfg.configSource != null) {
      Unit.Description = "Update Neovim plugins";
      Service = {
        Type = "oneshot";
        ExecStart = "${updater}/bin/update-neovim-plugins";
      };
    };
    systemd.user.timers.update-neovim-plugins = lib.mkIf (pkgs.stdenv.isLinux && cfg.configSource != null) {
      Unit.Description = "Update Neovim plugins daily";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
