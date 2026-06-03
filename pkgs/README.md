# Package Definitions

Centralized Nix package management for the dev-config ecosystem.

`pkgs/default.nix` is the single source of truth for development packages. It is
consumed by both the flake's devShells and the Home Manager modules, so package
versions stay consistent across environments.

## Quick Start

```nix
# Import in your flake
let
  devPkgs = import ./pkgs { inherit pkgs; };
in {
  # All packages
  packages = devPkgs.all devPkgs;

  # Or specific categories
  packages = devPkgs.core ++ devPkgs.linting;
}
```

## Categories

There are exactly four categories. Each is a plain list of packages.

| Category | Packages |
|----------|----------|
| **core** | git, gh, zsh, tmux, fzf, ripgrep, fd, bat, lazygit |
| **runtimes** | nodejs_24, bun, uv |
| **utilities** | direnv, nix-direnv, jq, yq-go, gnumake, pkg-config, tree-sitter |
| **linting** | biome |

Notes:
- Editor LSPs (`nixd`, `pyright`, `ts_ls`, `lua_ls`, ...) are **not** here — they
  live in `modules/home-manager/programs/neovim.nix`.
- `tree-sitter` is the CLI used to compile parsers for nvim-treesitter (main branch).
- `all` is a self-referential function: `all = self: self.core ++ self.runtimes ++ self.utilities ++ self.linting`.

## Usage

### In Home Manager

```nix
config = lib.mkIf config.dev-config.enable (let
  devPkgs = import ../../pkgs { inherit pkgs; };
in {
  home.packages = devPkgs.all devPkgs;
});
```

### In devShell

```nix
devShells.default = pkgs.mkShell {
  packages = let
    devPkgs = import ./pkgs { inherit pkgs; };
  in devPkgs.all devPkgs;
};
```

### Selective Import

```nix
let
  devPkgs = import ./pkgs { inherit pkgs; };
in {
  # Only core tools
  packages = devPkgs.core;

  # Core + linting
  packages = devPkgs.core ++ devPkgs.linting;
}
```

## Custom Packages

### monorepo-library-generator (mlg)

Effect-based library scaffolding for Nx monorepos, defined in
`pkgs/monorepo-library-generator/`:

```bash
mlg                      # Interactive mode
mlg create my-lib        # Create library
mlg-mcp                  # MCP server mode
```

## Directory Structure

```
pkgs/
+-- default.nix                  # Central package definitions (4 categories + `all`)
+-- monorepo-library-generator/  # Custom package: library scaffolding tool
    +-- default.nix
```

## Project Initialization

For workspace initialization (`biome.json`, editor configs), use
`lib.devShellHook` from the flake — not a package:

```nix
# In your project's flake.nix
inputs.dev-config.url = "github:samuelho-dev/dev-config";

devShells.default = pkgs.mkShell {
  shellHook = dev-config.lib.devShellHook;
};
```

On `nix develop`, this links `.zed/` and generates `biome.json` if missing.
Claude Code and Factory Droid configs live globally under `~/.claude/` and
`~/.factory/` via Home Manager.

## Adding Packages

### From nixpkgs

Add the package to the appropriate category list in `default.nix`:

```nix
core = [
  pkgs.git
  pkgs.gh
  pkgs.newpackage  # Add here
];
```

### New Category

```nix
# 1. Define the category
newcategory = [ pkgs.tool1 pkgs.tool2 ];

# 2. Add it to the `all` function
all = self:
  self.core
  ++ self.runtimes
  ++ self.utilities
  ++ self.newcategory  # Add here
  ++ self.linting;
```

### Custom Package

```nix
# 1. Create pkgs/my-tool/default.nix
{ pkgs, ... }: pkgs.writeShellScriptBin "my-tool" ''
  echo "Hello"
''

# 2. Reference it in default.nix (e.g. under utilities)
utilities = [
  # ...
  (pkgs.callPackage ./my-tool {})
];
```

## Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Architecture and patterns
- [Home Manager CLAUDE.md](../modules/home-manager/CLAUDE.md) - Package consumption
- [flake.nix](../flake.nix) - Flake integration
