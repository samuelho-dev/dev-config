---
scope: modules/nixos/
updated: 2025-12-21
relates_to:
  - ../../CLAUDE.md
  - ../home-manager/CLAUDE.md
  - ../../flake.nix
---

# CLAUDE.md

Architectural guidance for Claude Code when working with NixOS system-level modules.

## Purpose

This directory contains **NixOS system-level modules** for configuring server/VM infrastructure. These modules provide minimal system configuration that complements Home Manager user-level configuration.

**Key distinction:**
- `modules/nixos/` → System-level (root access, services, virtualization)
- `modules/home-manager/` → User-level (dotfiles, user packages, shell)

## Architecture Overview

NixOS modules configure system-level features that require root access or system service management. They follow the standard NixOS module pattern with options and config sections.

## File Structure

```
modules/nixos/
+-- CLAUDE.md       # This file
+-- default.nix     # Module aggregator + global dev-config option
+-- docker.nix      # Docker virtualization configuration
+-- shell.nix       # System-wide Zsh shell configuration
+-- users.nix       # User account management (NOT imported by default)
```

## Module Reference

| Module | Purpose | Key Options |
|--------|---------|-------------|
| `default.nix` | Entry point, imports other modules | `dev-config.enable` |
| `docker.nix` | Docker daemon and groups | `dev-config.docker.{enable,autoAddUsers,enableOnBoot}` |
| `shell.nix` | Zsh as system shell | `dev-config.shell.{enable,defaultShell,enableCompletion}` |
| `users.nix` | User account templates | `dev-config.users.<name>.{enable,shell,extraGroups}` |

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Global enable flag | `default.nix:14` | `dev-config.enable` gates all config |
| Module composition | `default.nix:7-9` | Imports compose smaller modules |
| Option namespacing | All modules | `dev-config.<module>.<option>` |
| Explicit lib prefixes | All modules | `lib.mkOption`, `lib.mkIf` |
| Security warnings | `docker.nix:21-32` | Document security implications |

## Usage in NixOS Configuration

```nix
# In your NixOS configuration.nix or flake
{
  imports = [
    inputs.dev-config.nixosModules.default
  ];

  # Enable dev-config NixOS modules
  dev-config = {
    enable = true;

    docker = {
      enable = true;
      autoAddUsers = true;  # WARNING: Docker group = root access
      enableOnBoot = true;
    };

    shell = {
      enable = true;
      enableSyntaxHighlighting = true;
      enableAutosuggestions = true;
    };
  };
}
```

## Module Details

### default.nix

Entry point that imports all sub-modules and defines the global enable option.

```nix
options.dev-config.enable = lib.mkOption {
  type = lib.types.bool;
  default = true;
  description = "Enable minimal dev-config NixOS setup";
};
```

**When enabled:** Installs git and vim as minimal system packages.

### docker.nix

Docker virtualization with security-conscious defaults.

**Options:**
- `enable` (default: true) - Enable Docker daemon
- `autoAddUsers` (default: true) - Add dev-config users to docker group
- `enableOnBoot` (default: true) - Start Docker on boot

**Security Warning:** Docker group membership is equivalent to root access. The module includes a detailed warning in the option description.

### shell.nix

System-wide Zsh configuration.

**Options:**
- `enable` (default: true) - Enable Zsh
- `defaultShell` (default: pkgs.zsh) - Default shell package
- `enableCompletion` (default: true) - Zsh completion
- `enableSyntaxHighlighting` (default: true) - Syntax highlighting
- `enableAutosuggestions` (default: true) - Fish-like suggestions

**Effect:** Sets Zsh as the default shell for all users.

### users.nix (Not Auto-Imported)

User account templates for dev-config environments.

**Note:** This module is NOT imported by default.nix because user configuration is highly machine-specific. Import explicitly when needed.

**Options per user:**
- `enable` - Enable this user configuration
- `shell` (default: pkgs.zsh) - User's shell
- `extraGroups` (default: ["docker" "wheel"]) - Group memberships
- `isSystemUser` (default: false) - System vs normal user
- `home` (default: /home/{username}) - Home directory path

## Adding New Modules

1. **Create module file:**
   ```nix
   { config, lib, pkgs, ... }: {
     options.dev-config.newFeature = {
       enable = lib.mkEnableOption "new feature";
       # Add more options...
     };

     config = lib.mkIf config.dev-config.newFeature.enable {
       # Configuration when enabled
     };
   }
   ```

2. **Add to default.nix imports:**
   ```nix
   imports = [
     ./docker.nix
     ./shell.nix
     ./newFeature.nix  # Add here
   ];
   ```

3. **Follow conventions:**
   - Use `lib.mkOption` and `lib.mkIf`
   - Namespace under `dev-config.<moduleName>`
   - Document security implications
   - Provide sensible defaults

## NixOS vs Home Manager

| Aspect | NixOS (this directory) | Home Manager |
|--------|------------------------|--------------|
| Scope | System-wide | Per-user |
| Access | Root required | User-level |
| Examples | Docker daemon, system shell | Neovim config, dotfiles |
| When to use | Services, virtualization | Application config |

**Rule of thumb:** If it requires `sudo`, it belongs in NixOS modules.

## For Future Claude Code Instances

When modifying NixOS modules:

- [ ] **Follow Nix conventions** - explicit `lib.` prefixes, no `with lib;`
- [ ] **Namespace options** under `dev-config.<module>`
- [ ] **Document security implications** for privilege-related options
- [ ] **Provide defaults** that work out of the box
- [ ] **Add to imports** in default.nix when creating new modules
- [ ] **Test with** `nix flake check` before committing
- [ ] **Consider Home Manager** for user-level configuration instead
- [ ] **Keep minimal** - prefer Home Manager for most configuration
- [ ] **Update this CLAUDE.md** when adding new modules
- [ ] **Cross-reference** with `../home-manager/CLAUDE.md` for user-level counterparts
