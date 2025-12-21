# Package Definitions

Centralized Nix package management for the dev-config ecosystem.

## Quick Start

```nix
# Import in your flake
let
  devPkgs = import ./pkgs { inherit pkgs; };
in {
  # All packages
  packages = devPkgs.all devPkgs;

  # Or specific categories
  packages = devPkgs.kubernetes ++ devPkgs.linting;
}
```

## Features

| Category | Packages |
|----------|----------|
| **core** | git, zsh, tmux, fzf, ripgrep, fd, bat, lazygit |
| **runtimes** | nodejs_20, bun, python3 |
| **kubernetes** | kubectl, helm, k9s, kind, argocd, cilium-cli |
| **cloud** | awscli2, doctl, hcloud |
| **iac** | terraform, terraform-docs |
| **security** | gitleaks, kubeseal, sops |
| **data** | jq, yq-go |
| **cicd** | gh, act, pre-commit, cachix |
| **utilities** | direnv, gnumake, 1password-cli, grit |
| **linting** | biome, hadolint, kube-linter, tflint, shellcheck |

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
  in devPkgs.core ++ devPkgs.linting;
};
```

### Selective Import

```nix
let
  devPkgs = import ./pkgs { inherit pkgs; };
in {
  # Only core tools
  packages = devPkgs.core;

  # Core + kubernetes
  packages = devPkgs.core ++ devPkgs.kubernetes;
}
```

## Custom Packages

### init-workspace

Initializes Nx workspaces with dev-config configurations:

```bash
init-workspace           # Create biome.json, tsconfig.base.json
init-workspace --force   # Overwrite existing configs
init-workspace --migrate # Only run ESLint/Prettier migrations
```

### mlg (Monorepo Library Generator)

Effect-based library scaffolding for Nx monorepos:

```bash
mlg                      # Interactive mode
mlg create my-lib        # Create library
mlg-mcp                  # MCP server mode
```

## Directory Structure

```
pkgs/
+-- default.nix                  # Central package definitions
+-- init-workspace/              # Workspace initialization tool
|   +-- default.nix
+-- monorepo-library-generator/  # Library scaffolding tool
    +-- default.nix
```

## Adding Packages

### From nixpkgs

```nix
# In default.nix
kubernetes = [
  pkgs.kubectl
  pkgs.newpackage  # Add here
];
```

### New Category

```nix
# 1. Define category
newcategory = [ pkgs.tool1 pkgs.tool2 ];

# 2. Add to 'all' function
all = self: self.core ++ self.newcategory ++ ...;
```

### Custom Package

```nix
# 1. Create pkgs/my-tool/default.nix
{ pkgs }: pkgs.writeShellScriptBin "my-tool" ''
  echo "Hello"
''

# 2. Reference in default.nix
utilities = [
  (pkgs.callPackage ./my-tool {})
];
```

## Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Architecture and patterns
- [Home Manager CLAUDE.md](../modules/home-manager/CLAUDE.md) - Package consumption
- [flake.nix](../flake.nix) - Flake integration
