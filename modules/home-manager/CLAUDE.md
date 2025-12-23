---
scope: modules/home-manager/
updated: 2025-12-21
relates_to:
  - ../../CLAUDE.md
  - ../../home.nix
  - ../../pkgs/default.nix
  - ./programs/neovim.nix
  - ./programs/tmux.nix
  - ./programs/zsh.nix
validation:
  max_days_stale: 30
---

# Home Manager Modules

Architectural guidance for Claude Code when working with the Home Manager module system.

## Purpose

This module system provides a declarative, composable way to configure user-level programs and services via Nix Home Manager. It enables the dev-config repository to be imported as a flake input by other projects, providing consistent development environments across machines.

## Architecture Overview

The module follows the standard Nix module pattern with `options` and `config` attributes. All program modules are imported by `default.nix` and can be individually enabled/disabled via `dev-config.<program>.enable`. Configuration sources support both bundled configs (from this repo) and external management (e.g., Chezmoi).

Key design decisions:
- **Explicit `lib.` prefixes**: Never use `with lib;` - always explicit imports
- **Flake composition support**: `inputs ? dev-config` pattern enables standalone and imported usage
- **DRY package management**: Centralized in `pkgs/default.nix`, imported once
- **Null config sources**: Set `configSource = null` to manage configs externally

## File Structure

```
modules/home-manager/
+-- default.nix              # Module aggregator, imports all programs/services
+-- programs/                # User program configurations
|   +-- biome.nix            # Biome linter/formatter
|   +-- claude-code.nix      # Claude Code AI assistant
|   +-- ghostty.nix          # Ghostty terminal emulator
|   +-- git.nix              # Git with 1Password SSH signing
|   +-- gritql.nix           # GritQL pattern linting
|   +-- neovim.nix           # Neovim editor setup
|   +-- npm.nix              # NPM configuration
|   +-- opencode.nix         # OpenCode AI assistant
|   +-- ssh.nix              # SSH with 1Password agent
|   +-- tmux.nix             # Tmux terminal multiplexer
|   +-- yazi.nix             # Yazi file manager
|   +-- zsh.nix              # Zsh shell configuration
+-- services/                # Background services
    +-- direnv.nix           # direnv with nix-direnv
    +-- sops-env.nix         # sops-nix secret environment
```

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Module options structure | programs/*.nix:8-50 | Standard `options.dev-config.<name>` with enable, package, configSource |
| Flake input detection | programs/*.nix:23-25 | `if inputs ? dev-config then ... else null` for composition |
| Explicit lib prefixes | all files | `lib.mkOption`, `lib.mkIf` - never `with lib;` |
| Config source nullability | programs/*.nix:21-32 | `lib.types.nullOr lib.types.path` allows external config management |
| Centralized packages | default.nix:52-58 | `devPkgs = import ../../pkgs` - single source of truth |

## Module Reference

| Module | Purpose | Key Options |
|--------|---------|-------------|
| **default.nix** | Aggregates all modules, defines global options | `dev-config.enable`, `dev-config.packages.enable` |
| **programs/neovim.nix** | Neovim with LazyVim config | `enable`, `package`, `configSource`, `defaultEditor` |
| **programs/tmux.nix** | Tmux with TPM plugins | `enable`, `configSource` |
| **programs/zsh.nix** | Zsh with Oh My Zsh + Powerlevel10k | `enable`, `zshrcSource`, `p10kSource` |
| **programs/git.nix** | Git with 1Password signing | `enable`, `userEmail`, `userName`, `signingKey` |
| **programs/ssh.nix** | SSH with 1Password agent | `enable`, `identityAgent` |
| **programs/ghostty.nix** | Ghostty terminal config | `enable`, `configSource` |
| **programs/yazi.nix** | Yazi file manager | `enable`, `configSource` |
| **programs/claude-code.nix** | Claude Code multi-profile | `enable`, `profiles` |
| **programs/opencode.nix** | OpenCode AI assistant | `enable`, `ohMyOpencode` |
| **programs/biome.nix** | Biome linting configs | `enable`, `configSource` |
| **programs/gritql.nix** | GritQL pattern linting | `enable`, `configSource` |
| **programs/npm.nix** | NPM configuration | `enable` |
| **services/direnv.nix** | direnv + nix-direnv | `enable` |
| **services/sops-env.nix** | Secret environment variables | `enable`, `secretsFile` |

## Adding/Modifying

### Adding a New Program Module

1. Create `programs/<name>.nix` with this structure:
   ```nix
   { config, lib, pkgs, inputs, ... }: {
     options.dev-config.<name> = {
       enable = lib.mkOption {
         type = lib.types.bool;
         default = true;
         description = "Enable dev-config <name> setup";
       };
       configSource = lib.mkOption {
         type = lib.types.nullOr lib.types.path;
         default = if inputs ? dev-config then "${inputs.dev-config}/<name>" else null;
       };
     };
     config = lib.mkIf config.dev-config.<name>.enable { ... };
   }
   ```

2. Add import to `default.nix`:
   ```nix
   imports = [
     # ... existing imports
     ./programs/<name>.nix
   ];
   ```

3. Document the module in this CLAUDE.md

### Modifying Module Options

1. Read existing module to understand current options
2. Add new options following the pattern (explicit `lib.` prefixes)
3. Update `config` section to use new options
4. Test with `home-manager build --flake .`

### Disabling a Program

Users can disable any program in their `home.nix`:
```nix
dev-config.neovim.enable = false;
dev-config.tmux.enable = false;
```

### Using External Config Management

Set `configSource = null` to prevent symlink creation:
```nix
dev-config.neovim.configSource = null;  # Manage with Chezmoi
```

## For Future Claude Code Instances

- [ ] Always use explicit `lib.` prefixes - never `with lib;`
- [ ] Check `inputs ? dev-config` pattern for flake composition support
- [ ] Test changes with `home-manager build --flake .`
- [ ] Add new modules to the import list in `default.nix`
- [ ] Keep options consistent with existing modules (enable, configSource pattern)
- [ ] Document new options in this CLAUDE.md
