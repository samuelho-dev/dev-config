{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.yazi;
in {
  options.dev-config.yazi = {
    enable = lib.mkEnableOption "Yazi terminal file manager";

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [
        # File previews
        pkgs.ffmpegthumbnailer # Video thumbnails and previews
        pkgs.poppler # PDF previews
        pkgs.imagemagick # Image processing/conversion

        # Archive support
        pkgs.p7zip # Archive extraction and preview

        # Data processing
        pkgs.jq # JSON file previews
        pkgs.yq-go # YAML file previews
      ];
      description = "Extra packages for Yazi file previews and operations";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        mgr = {
          ratio = [1 4 3];
          sort_by = "natural";
          sort_dir_first = true;
          show_hidden = false;
          linemode = "size";
        };
        preview = {
          max_width = 1000;
          max_height = 1000;
          cache_dir = ""; # Use default cache location
        };
      };
      description = "Yazi configuration settings (yazi.toml)";
    };

    keymap = lib.mkOption {
      type = lib.types.attrs;
      default = {
        mgr.prepend_keymap = [
          {
            on = ["<C-s>"];
            run = "search fd";
            desc = "Search files with fd";
          }
          {
            on = ["<C-g>"];
            run = "search rg";
            desc = "Search content with ripgrep";
          }
          {
            on = ["<C-z>"];
            run = "plugin zoxide";
            desc = "Jump to directory with zoxide";
          }
        ];
      };
      description = "Yazi keymap configuration (keymap.toml)";
    };

    theme = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Yazi theme configuration (theme.toml). Leave empty to use defaults.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;

      # Shell integration - generates 'yy' wrapper function
      enableZshIntegration = config.dev-config.zsh.enable or false;
      enableBashIntegration = true;

      # Wrapper function name (use 'yy' to cd on exit)
      shellWrapperName = "yy";

      # Add preview tools to PATH
      package = pkgs.yazi.override {
        inherit (cfg) extraPackages;
      };

      # Declarative configuration
      settings = cfg.settings;
      keymap = cfg.keymap;
      theme = cfg.theme;
    };
  };
}
