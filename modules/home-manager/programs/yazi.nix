{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.dev-config.yazi;
in {
  options.dev-config.yazi = {
    enable = mkEnableOption "Yazi terminal file manager";

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        # File previews
        ffmpegthumbnailer # Video thumbnails and previews
        poppler # PDF previews
        imagemagick # Image processing/conversion

        # Archive support
        p7zip # Archive extraction and preview

        # Data processing
        jq # JSON file previews
        yq-go # YAML file previews
      ];
      description = "Extra packages for Yazi file previews and operations";
    };

    settings = mkOption {
      type = types.attrs;
      default = {
        manager = {
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

    keymap = mkOption {
      type = types.attrs;
      default = {
        manager.prepend_keymap = [
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

    theme = mkOption {
      type = types.attrs;
      default = {};
      description = "Yazi theme configuration (theme.toml). Leave empty to use defaults.";
    };
  };

  config = mkIf cfg.enable {
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
