---
scope: modules/home-manager/programs/
updated: 2025-12-21
relates_to:
  - ../CLAUDE.md
  - ../default.nix
  - ../services/CLAUDE.md
validation:
  max_days_stale: 30
---

# Home Manager Program Modules

Architectural guidance for the 11 program modules that configure user-level applications.

## Purpose

This directory contains individual Nix modules that declaratively configure development tools (Neovim, tmux, zsh, git, etc.). Each module follows a consistent pattern with `enable`, `package`, and `configSource` options, allowing fine-grained control over tool installation and configuration management.

## Architecture Overview

All modules follow the standard Nix module pattern with `options.dev-config.<program>` namespace. Modules are designed for **flake composition** - they detect whether they're being used standalone or imported via `inputs ? dev-config` pattern. This enables external repositories to consume these modules while maintaining local development flexibility.

Key design principles:
- **Explicit `lib.` prefixes**: Never use `with lib;` - always explicit imports
- **Nullable configSource**: Set to `null` to manage configs externally (e.g., Chezmoi)
- **Modular packages**: Each module installs only its required dependencies
- **Shell integration**: Modules auto-enable zsh/bash integration where applicable

## File Structure

```
programs/
+-- biome.nix             # Biome linter/formatter configuration
+-- claude-code.nix       # Claude Code AI assistant profiles
+-- ghostty.nix           # Ghostty terminal emulator config
+-- git.nix               # Git with 1Password SSH signing
+-- gritql.nix            # GritQL pattern linting
+-- neovim.nix            # Neovim editor with LSP servers
+-- npm.nix               # NPM configuration and packages
+-- python.nix            # Python 3 with pip and development packages
+-- ssh.nix               # SSH with 1Password agent integration
+-- tmux.nix              # Tmux terminal multiplexer
+-- yazi.nix              # Yazi file manager
+-- zsh.nix               # Zsh shell with Oh My Zsh + Powerlevel10k
```

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Options structure | all files:8-50 | `options.dev-config.<name>.enable/package/configSource` |
| Flake detection | neovim.nix:23-25 | `if inputs ? dev-config then ... else null` |
| Config symlinks | neovim.nix:92-95 | `xdg.configFile."<name>" = { source = ...; };` |
| Shell integration | zsh.nix:40-50 | Auto-enable zsh/bash hooks via Home Manager |
| Package installation | neovim.nix:69-89 | `home.packages = [ ... ];` for tool dependencies |
| Nullable path type | all files:22 | `lib.types.nullOr lib.types.path` for external management |

## Module Reference

| Module | Purpose | Key Options | Dependencies |
|--------|---------|-------------|--------------|
| **neovim.nix** | Neovim with LazyVim | `enable`, `package`, `configSource`, `defaultEditor`, `vimAlias` | LSP servers, formatters, gcc, make |
| **tmux.nix** | Terminal multiplexer | `enable`, `configSource` | TPM plugins |
| **zsh.nix** | Shell configuration | `enable`, `zshrcSource`, `p10kSource` | Oh My Zsh, Powerlevel10k |
| **git.nix** | Git + 1Password signing | `enable`, `userName`, `userEmail`, `signingKey` | git, gh CLI |
| **ssh.nix** | SSH + 1Password agent | `enable`, `identityAgent` | 1Password SSH agent |
| **ghostty.nix** | Terminal emulator | `enable`, `configSource` | None |
| **yazi.nix** | File manager | `enable`, `configSource` | fd, ripgrep, bat, ffmpegthumbnailer |
| **claude-code.nix** | Claude Code assistant | `enable`, `profiles` | Node.js |
| **python.nix** | Python 3 + pip + dev | `enable`, `package`, `enablePip`, `packages` | Python 3, pip, setuptools, pytest, black, ruff, mypy |
| **biome.nix** | Linting/formatting | `enable`, `configSource` | biome binary |
| **gritql.nix** | GritQL pattern linting | `enable`, `configSource` | grit binary |
| **npm.nix** | NPM configuration | `enable` | Node.js |

## Adding/Modifying

### Creating a New Program Module

1. **Create the module file** `programs/<name>.nix`:
   ```nix
   { config, lib, pkgs, inputs, ... }: {
     options.dev-config.<name> = {
       enable = lib.mkOption {
         type = lib.types.bool;
         default = true;
         description = "Enable dev-config <name> setup";
       };

       package = lib.mkOption {
         type = lib.types.package;
         default = pkgs.<name>;
         description = "<Name> package to use";
       };

       configSource = lib.mkOption {
         type = lib.types.nullOr lib.types.path;
         default = if inputs ? dev-config
                   then "${inputs.dev-config}/<name>"
                   else null;
         description = "Path to configuration. Set to null for external management.";
       };
     };

     config = lib.mkIf config.dev-config.<name>.enable {
       home.packages = [ config.dev-config.<name>.package ];

       xdg.configFile."<name>" = lib.mkIf (config.dev-config.<name>.configSource != null) {
         source = config.dev-config.<name>.configSource;
         recursive = true;
       };
     };
   }
   ```

2. **Add import to `default.nix`**:
   ```nix
   imports = [
     # ... existing imports
     ./programs/<name>.nix
   ];
   ```

3. **Document in parent CLAUDE.md** (`../CLAUDE.md`)

### Modifying Existing Module

1. Read module to understand current structure
2. Add new options following existing patterns
3. Use explicit `lib.` prefixes (never `with lib;`)
4. Update `config` section to use new options
5. Test: `home-manager build --flake .`

### Disabling a Program

In user's `home.nix`:
```nix
dev-config.<name>.enable = false;
```

### External Config Management

For tools managed by Chezmoi or other dotfile managers:
```nix
dev-config.<name>.configSource = null;
```

## Common Issues

### Config symlink conflicts

**Symptom:** `home-manager switch` fails with "file exists" error

**Fix:** Remove conflicting file manually or use `home.file.<name>.force = true`

### Missing dependencies

**Symptom:** Program fails to start with missing binary

**Fix:** Add required packages to `home.packages` in the module

### Shell integration not working

**Symptom:** Tool doesn't auto-activate in shell

**Fix:** Check `enableZshIntegration = true` is set in the module

## For Future Claude Code Instances

- [ ] Always use explicit `lib.` prefixes - never `with lib;`
- [ ] Follow the `enable/package/configSource` pattern for consistency
- [ ] Check `inputs ? dev-config` for flake composition support
- [ ] Add new modules to `../default.nix` imports
- [ ] Install tool-specific dependencies via `home.packages`
- [ ] Document new modules in `../CLAUDE.md` module reference table
- [ ] Test with `home-manager build --flake .` before committing
