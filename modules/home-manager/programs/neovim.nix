{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  options.dev-config.neovim = {
    enable =
      lib.mkEnableOption "dev-config Neovim setup"
      // {
        default = true;
      };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovim;
      description = "Neovim package to use";
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

      # Install lazy-nix-helper for hybrid Nix + lazy.nvim approach
      plugins = with pkgs.vimPlugins; [
        # lazy-nix-helper-nvim  # Not available in current nixpkgs
      ];
    };

    # Install LSP servers, formatters, and build tools via Nix
    # This allows lazy-nix-helper to disable Mason on Nix systems
    home.packages = with pkgs; [
      # LSP servers
      nodePackages.typescript-language-server # TypeScript/JavaScript
      pyright # Python
      lua-language-server # Lua

      # Formatters
      stylua # Lua formatter
      nodePackages.prettier # JS/TS/JSON/YAML/Markdown
      ruff # Python formatter + linter

      # Build tools for Neovim plugins
      gnumake
      gcc
      pkg-config
      nodejs
      imagemagick

      # Mermaid CLI (for mermaid diagram rendering)
      nodePackages."@mermaid-js/mermaid-cli"
    ];

    # Symlink Neovim configuration if source is provided
    xdg.configFile."nvim" = lib.mkIf (config.dev-config.neovim.configSource != null) {
      source = config.dev-config.neovim.configSource;
      recursive = true;
    };
  };
}
