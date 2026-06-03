---
scope: pkgs/
updated: 2025-12-21
relates_to:
  - ../CLAUDE.md
  - ../modules/home-manager/default.nix
  - ../flake.nix
validation:
  max_days_stale: 30
---

# Package Definitions

Architectural guidance for the centralized package management system.

## Purpose

This directory provides a single source of truth for all development packages used across the repository. Packages are organized by category and consumed by both devShells (for development environments) and Home Manager modules (for user-level installations). This DRY approach ensures consistent package versions and eliminates duplication.

## Architecture Overview

The `default.nix` file exports an attribute set with package categories as keys and lists of packages as values. A special `all` function combines all categories into a single list. Custom packages can be defined inline (via `let ... in`) when a tool is not available in nixpkgs.

Key design decisions:
- **Category-based organization**: Packages grouped by purpose (core, runtimes, utilities, linting)
- **Self-referential `all` function**: `all = self: self.core ++ self.runtimes ++ ...` enables flexible composition
- **Custom package support**: Inline derivations or local subdirectories for packages not in nixpkgs
- **Platform-aware builds**: Custom binary packages handle multi-platform sources

## File Structure

```
pkgs/
+-- default.nix                  # Central package definitions with categories
+-- monorepo-library-generator/  # Custom package: library scaffolding tool
    +-- default.nix              # Derivation for library generator
```

Note: Workspace initialization (biome.json, editor configs) is handled by `lib.devShellHook` in flake.nix, not a separate package.

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Category attributes | default.nix | `core`, `runtimes`, `utilities`, `linting` for organized package lists |
| Self-referential all | default.nix (`all` fn) | `all = self: self.core ++ ...` enables flexible combination |
| Custom derivation | (when needed) | Inline `let ... in pkgs.mkDerivation` for packages not in nixpkgs |
| Platform sources | (when needed) | `sources.${platformKey}` for multi-platform prebuilt binaries |
| Callpackage pattern | (when needed) | `pkgs.callPackage ./subdir {}` for local packages |

## Module Reference

| Category | Purpose | Key Packages |
|----------|---------|--------------|
| **core** | Essential dev tools | git, gh, zsh, tmux, fzf, ripgrep, fd, bat, lazygit |
| **runtimes** | Language runtimes | nodejs_24, bun, uv |
| **utilities** | Dev utilities | direnv, nix-direnv, jq, yq-go, gnumake, pkg-config, tree-sitter |
| **linting** | Repo-wide linters/formatters | biome (editor LSPs live in neovim.nix) |

## Adding/Modifying

### Adding a Package from nixpkgs

1. Find the appropriate category in `default.nix`
2. Add the package to the category list:
   ```nix
   core = [
     pkgs.git
     pkgs.gh
     pkgs.newpackage  # Add here
   ];
   ```

### Adding a New Category

1. Define the new category:
   ```nix
   newcategory = [
     pkgs.package1
     pkgs.package2
   ];
   ```

2. Add to the `all` function:
   ```nix
   all = self:
     self.core
     ++ self.runtimes
     ++ self.newcategory  # Add here
     ++ self.linting;
   ```

### Adding a Custom Package

1. Create subdirectory: `pkgs/package-name/default.nix`
   ```nix
   { pkgs, ... }:
   pkgs.stdenvNoCC.mkDerivation {
     pname = "package-name";
     version = "1.0.0";
     # ... derivation details
   }
   ```

2. Reference in utilities (or appropriate category):
   ```nix
   utilities = [
     # ...
     (pkgs.callPackage ./package-name {})
   ];
   ```

### Adding Multi-Platform Binary

For pre-built binaries with platform-specific downloads:

```nix
mypackage = let
  version = "1.0.0";
  sources = {
    "aarch64-darwin" = {
      url = "https://...aarch64-darwin.tar.gz";
      sha256 = "sha256-...";
    };
    "x86_64-linux" = {
      url = "https://...x86_64-linux.tar.gz";
      sha256 = "sha256-...";
    };
  };
  platformKey = pkgs.stdenvNoCC.hostPlatform.system;
  src = sources.${platformKey} or (throw "Unsupported: ${platformKey}");
in pkgs.stdenvNoCC.mkDerivation {
  pname = "mypackage";
  inherit version;
  src = pkgs.fetchurl { inherit (src) url sha256; };
  # ...
};
```

## Usage

### In Home Manager Modules

```nix
# modules/home-manager/default.nix
config = lib.mkIf config.dev-config.enable (let
  devPkgs = import ../../pkgs { inherit pkgs; };
in {
  home.packages = (devPkgs.all devPkgs);
});
```

### In devShell

```nix
# flake.nix
devShells.default = pkgs.mkShell {
  packages = let
    devPkgs = import ./pkgs { inherit pkgs; };
  in devPkgs.all devPkgs;
};
```

### Selective Category Import

```nix
let
  devPkgs = import ./pkgs { inherit pkgs; };
in {
  # Only kubernetes tools
  packages = devPkgs.kubernetes;

  # Core + linting
  packages = devPkgs.core ++ devPkgs.linting;
}
```

See root `CLAUDE.md` for general AI conventions and guardrails.
