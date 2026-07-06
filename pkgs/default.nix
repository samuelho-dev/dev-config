# Package definitions for dev-config
# Single source of truth for all development packages
# Used by both devShells and Home Manager modules
{pkgs}: let
  # Bun 1.3.14 — nixpkgs (even unstable HEAD) is pinned at 1.3.13, but omp
  # (@oh-my-pi/pi-coding-agent) refuses to run on < 1.3.14. Override the
  # prebuilt-binary sources with the 1.3.14 release; keep all build logic.
  bun-latest = pkgs.bun.overrideAttrs (old: {
    version = "1.3.14";
    # src is computed from passthru.sources via finalAttrs (recomputes below);
    # the version/src heuristic can't see that, so assert intent explicitly.
    __intentionallyOverridingVersion = true;
    passthru =
      old.passthru
      // {
        sources = {
          "aarch64-darwin" = pkgs.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-darwin-aarch64.zip";
            hash = "sha256-2LliIYKK1vl6x6wKt+lYcjQa92MAHogD6CZ2UsJlJiA=";
          };
          "aarch64-linux" = pkgs.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-linux-aarch64.zip";
            hash = "sha256-on/7Y6gxA3WDbg1vZorhf6jY0YuIw3yCHGUzGXOhmjs=";
          };
          "x86_64-darwin" = pkgs.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-darwin-x64-baseline.zip";
            hash = "sha256-PjWtb1OXGpg0v55nhuKt9ytfGSHMmpxf3gc9KXKUQHY=";
          };
          "x86_64-linux" = pkgs.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-linux-x64.zip";
            hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
          };
        };
      };
  });
in {
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

  # JavaScript/TypeScript runtimes + package managers
  # On PATH for every dev surface (devShell + Home Manager + DevPod image).
  runtimes = [
    pkgs.nodejs_26 # Node.js 26 (latest stable) - also provides npm + corepack
    pkgs.pnpm # repo pins packageManager: pnpm@10.x
    bun-latest # Bun 1.3.14 (overridden — omp needs >= 1.3.14; see top of file)
  ];

  # Combine all packages into a single list
  all = self:
    self.core
    ++ self.utilities
    ++ self.linting
    ++ self.runtimes;
}
