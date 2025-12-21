# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Centralized development configuration repository using **Nix + Home Manager** for declarative, reproducible dotfile and package management.

**Managed configurations:** Neovim, Tmux, Ghostty, Yazi, Zsh (Oh My Zsh + Powerlevel10k), Git (1Password SSH signing), Claude Code multi-profile, OpenCode, Biome, TypeScript strict configs.

## Essential Commands

```bash
# Apply Home Manager configuration
home-manager switch --flake .

# Test configuration without applying
home-manager build --flake .

# Preview changes (dry-run)
home-manager switch --flake . --dry-run

# Validate flake syntax
nix flake show --json

# Update all dependencies
nix flake update

# Enter development shell (40+ DevOps tools)
nix develop
```

## Architecture

### Flake Structure

```
flake.nix                    # Entry point: exports homeManagerModules, nixosModules, devShells
├── home.nix                 # Home Manager config with sops-nix secrets
├── user.nix                 # Machine-specific values (username, homeDirectory) - GITIGNORED
├── modules/
│   ├── home-manager/        # User-level configuration modules
│   │   ├── default.nix      # Module aggregator + global options
│   │   ├── programs/        # Per-program modules (neovim.nix, tmux.nix, etc.)
│   │   └── services/        # Service modules (direnv.nix, sops-env.nix)
│   └── nixos/               # System-level modules (for NixOS servers)
├── pkgs/default.nix         # Centralized package definitions (DRY)
└── secrets/default.yaml     # sops-nix encrypted secrets
```

### Home Manager Module Pattern

Every program module follows this structure:

```nix
{ config, lib, pkgs, inputs, ... }:
let cfg = config.dev-config.programName;
in {
  options.dev-config.programName = {
    enable = lib.mkEnableOption "Program configuration";
    configSource = lib.mkOption {
      default = if inputs ? dev-config then "${inputs.dev-config}/program" else null;
    };
  };
  config = lib.mkIf cfg.enable { ... };
}
```

**Key patterns:**
- Always use explicit `lib.` prefixes (never `with lib;`)
- Use `inputs ? dev-config` for flake composition support
- Alphabetical parameter order: `{ config, lib, pkgs, inputs, ... }`

### Package Management

All packages defined centrally in `pkgs/default.nix` by category:
- `core`: git, zsh, tmux, fzf, ripgrep, fd, bat, lazygit
- `runtimes`: nodejs_20, bun, python3
- `kubernetes`: kubectl, helm, k9s, kind, argocd, cilium-cli
- `cloud`: awscli2, doctl, hcloud
- `iac`: terraform, terraform-docs
- `security`: gitleaks, kubeseal, sops
- `linting`: biome, hadolint, kube-linter, tflint, actionlint, yamllint, shellcheck

### Secrets Management

**sops-nix** with age encryption:
- Secrets in `secrets/default.yaml` (encrypted)
- Decrypted to tmpfs at Home Manager activation
- Environment variables loaded via `sops-env.nix` module
- Age key at `~/.config/sops/age/keys.txt`

**1Password SSH Agent** for authentication:
- SSH keys stored in 1Password vault (never on disk)
- Automatic commit signing
- See `modules/home-manager/programs/ssh.nix` and `git.nix`

## Configuration Files (Dotfiles)

Dotfiles in `nvim/`, `tmux/`, `zsh/`, `ghostty/`, `yazi/` are version controlled and symlinked by Home Manager. Edit them directly - no rebuild needed (just reload the application).

Component-specific documentation:
- `nvim/CLAUDE.md` - Neovim plugin system, LSP, lazy loading
- `tmux/CLAUDE.md` - Tmux plugins and TPM
- `zsh/CLAUDE.md` - Oh My Zsh, Powerlevel10k
- `biome/CLAUDE.md` - Strict linting rules, GritQL patterns

## Machine Setup

1. Clone repository and create `user.nix`:
   ```bash
   cp user.nix.example user.nix
   # Edit with your username and homeDirectory
   git add -f user.nix  # Required for flake evaluation (gitignored but must be staged)
   ```

2. Run installation:
   ```bash
   bash scripts/install.sh  # Installs Nix, Home Manager, applies config
   ```

3. For secrets, create age key and decrypt:
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   # Add public key to .sops.yaml, re-encrypt secrets
   ```

## Flake Composition

This repo can be imported as a flake input in other projects:

```nix
inputs.dev-config.url = "github:samuelho-dev/dev-config";

# Use modules
modules = [ dev-config.homeManagerModules.default ];
```

The `inputs ? dev-config` pattern in modules enables both standalone and composition usage.

## Key Conventions

- **Formatter:** `alejandra` (run via `nix fmt`)
- **Nix style:** Explicit `lib.` prefixes, no `with` statements
- **Module options:** Use `lib.mkEnableOption` for optional features
- **Testing:** Always run `nix flake show --json` before committing Nix changes
- **Symlinks:** Home Manager manages all symlinks - never create manually
