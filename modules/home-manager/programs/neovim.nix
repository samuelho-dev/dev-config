{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: {
  options.dev-config.neovim = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable dev-config Neovim setup";
    };

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

      # Plugins managed by lazy.nvim in nvim/lua/plugins/
      # Nix only provides LSP servers/formatters as binaries
      plugins = [];
    };

    # Install LSP servers, formatters, and build tools via Nix
    # On Nix systems, lsp.lua detects ~/.nix-profile/bin binaries and skips Mason auto-install
    home.packages = [
      # LSP servers
      pkgs.nodePackages.typescript-language-server # TypeScript/JavaScript
      pkgs.pyright # Python
      pkgs.lua-language-server # Lua
      pkgs.biome # JavaScript/TypeScript/JSON linter + formatter

      # Formatters
      pkgs.stylua # Lua formatter
      pkgs.nodePackages.prettier # JS/TS/JSON/YAML/Markdown
      pkgs.ruff # Python formatter + linter

      # Build tools for Neovim plugins
      pkgs.gnumake
      pkgs.gcc
      pkgs.pkg-config
      # Note: nodejs_20 is included via pkgs/default.nix runtimes
      pkgs.imagemagick

      # Mermaid CLI (for mermaid diagram rendering)
      pkgs.nodePackages."@mermaid-js/mermaid-cli"
    ];

    # Symlink Neovim configuration if source is provided
    xdg.configFile."nvim" = lib.mkIf (config.dev-config.neovim.configSource != null) {
      source = config.dev-config.neovim.configSource;
      recursive = true;
    };
  };
}
