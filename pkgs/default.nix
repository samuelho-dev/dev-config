# Package definitions for dev-config
# Single source of truth for all development packages
# Used by both devShells and Home Manager modules
{pkgs}: {
  # Core development tools
  core = [
    pkgs.git
    pkgs.gh
    pkgs.zsh
    pkgs.tmux
    pkgs.fzf
    pkgs.ripgrep
    pkgs.fd
    pkgs.bat
    pkgs.lazygit
  ];


  # Development utilities
  utilities = [
    pkgs.direnv
    pkgs.nix-direnv
    pkgs.jq
    pkgs.yq-go
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.tree-sitter # CLI to compile parsers (required by nvim-treesitter main branch)
  ];

  # Linting and formatting tools (repo-wide: devShell, pre-commit, biome.json)
  # Note: editor LSPs (nixd, pyright, ...) live in modules/home-manager/programs/neovim.nix
  linting = [
    pkgs.biome # Fast formatter and linter for JS/TS/JSON/CSS
  ];

  # Combine all packages into a single list
  all = self:
    self.core
    ++ self.utilities
    ++ self.linting;
}
