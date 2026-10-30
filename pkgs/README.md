# Package Definitions

Centralized Nix package management for the dev-config ecosystem.

`pkgs/default.nix` owns the cross-platform Nix CLI set consumed by devShells
and Home Manager. `Brewfile` is the opt-in Mac host-extras inventory, not a
Linux incompatibility list; selected third-party-tap tools are held external
until their source is trusted. Native coding CLIs use `ai/bootstrap.sh`.

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

There are exactly five categories. Each is a plain list of packages.

| Category | Packages |
|----------|----------|
| **core** | git, gh, zsh, tmux, fzf, ripgrep, fd, bat, lazygit, gitmux |
| **runtimes** | nodejs, pnpm, bun |
| **utilities** | direnv, nix-direnv, zoxide, jq, yq-go, gnumake, pkg-config, tree-sitter |
| **linting** | biome |
| **cloud** | docker-client, terraform, 1password-cli, stripe-cli, awscli2, cloudflared, kubectl, kubernetes-helm, k9s, argocd, supabase-cli, postgresql (`psql`), talosctl, doctl, hcloud, kubeseal, kubeconform, kustomize, sops, age, cilium-cli |

Notes:
- Editor LSPs (`nixd`, `pyright`, `ts_ls`, `lua_ls`, ...) are **not** here — they
  live in `modules/home-manager/programs/neovim.nix`.
- `tree-sitter` is the CLI used to compile parsers for nvim-treesitter (main branch).
- `all` combines `core`, `utilities`, `linting`, `runtimes`, and `cloud`.
- `omp` is deliberately **not** packaged here: a `/nix/store` copy cannot run
  `omp update`. The shared `ai/omp/install.sh` installs the standalone binary
  into `~/.local/bin` for both Home Manager and the Rex container bootstrap.
- `tool-checks.json` executes the declared shared Nix and enabled Home Manager
  launchers, including Python/pip and Nix/Home Manager; native coding CLIs use
  `ai/bootstrap.sh check`. GUI apps, optional host extras and external auth are
  not implied by this inventory or the historical 84-command runtime sample.

## Mac host ownership

`Brewfile` is the complete opt-in direct Homebrew inventory: listed formulas
are Mac host extras (including the selected development libraries `boost` and
`zlib`), and listed casks are GUI apps. `tailscale` is deliberately both a CLI
formula and a GUI cask; `nx` is an optional host-wide launcher, not the
project-local Nx version. The shared Nix set owns unversioned `helm`; an
existing Mac `helm@3` installation is preserved but superseded, not installed
on fresh hosts or removed from this one. `e1s`, `taws`, and
`hashicorp-vagrant` remain held external rather than trusted Brewfile entries.

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
+-- default.nix                  # Central package definitions (6 categories + `all`)
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
Claude Code and OMP configs live globally under `~/.claude/` and `~/.agents/`
via Home Manager.

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

- [flake.nix](../flake.nix) - Flake integration
