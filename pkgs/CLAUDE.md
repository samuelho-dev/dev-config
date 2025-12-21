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

The `default.nix` file exports an attribute set with package categories as keys and lists of packages as values. A special `all` function combines all categories into a single list. Custom packages (like `grit`) are defined inline and included with nixpkgs packages.

Key design decisions:
- **Category-based organization**: Packages grouped by purpose (core, kubernetes, linting, etc.)
- **Self-referential `all` function**: `all = self: self.core ++ self.runtimes ++ ...` enables flexible composition
- **Custom package support**: Local derivations in subdirectories (init-workspace, monorepo-library-generator)
- **Platform-aware builds**: Custom packages handle multi-platform binaries

## File Structure

```
pkgs/
+-- default.nix                  # Central package definitions with categories
+-- init-workspace/              # Custom package: workspace initialization tool
|   +-- default.nix              # Derivation for init-workspace
+-- monorepo-library-generator/  # Custom package: library scaffolding tool
    +-- default.nix              # Derivation for library generator
```

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Category attributes | default.nix:54-142 | `core`, `kubernetes`, `linting`, etc. for organized package lists |
| Self-referential all | default.nix:145-155 | `all = self: self.core ++ ...` enables flexible combination |
| Custom derivation | default.nix:7-52 | Inline `mkDerivation` for packages not in nixpkgs |
| Platform sources | default.nix:9-26 | `sources.${platformKey}` for multi-platform binaries |
| Callpackage pattern | default.nix:128-129 | `pkgs.callPackage ./subdir {}` for local packages |

## Module Reference

| Category | Purpose | Key Packages |
|----------|---------|--------------|
| **core** | Essential dev tools | git, zsh, tmux, fzf, ripgrep, fd, bat, lazygit |
| **runtimes** | Language runtimes | nodejs_20, bun, python3 |
| **kubernetes** | K8s ecosystem | kubectl, helm, k9s, kind, argocd, cilium-cli |
| **cloud** | Cloud CLIs | awscli2, doctl, hcloud |
| **iac** | Infrastructure as Code | terraform, terraform-docs |
| **security** | Security tools | gitleaks, kubeseal, sops |
| **data** | Data processing | jq, yq-go |
| **cicd** | CI/CD tools | gh, act, pre-commit, cachix |
| **utilities** | Dev utilities | direnv, gnumake, 1password-cli, grit |
| **linting** | Linters/formatters | biome, hadolint, kube-linter, tflint, shellcheck |

## Adding/Modifying

### Adding a Package from nixpkgs

1. Find the appropriate category in `default.nix`
2. Add the package to the category list:
   ```nix
   kubernetes = [
     pkgs.kubectl
     pkgs.kubernetes-helm
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

## For Future Claude Code Instances

- [ ] Check if package exists in nixpkgs before creating custom derivation
- [ ] Use `pkgs.callPackage` for local packages in subdirectories
- [ ] Handle multiple platforms for custom binary downloads
- [ ] Update both category list AND `all` function when adding categories
- [ ] Test package installation with `nix develop` or `home-manager build --flake .`
- [ ] Add SHA256 hashes for all fetchurl sources (use `nix-prefetch-url`)
