---
scope: ./
updated: 2026-04-03
relates_to:
  - ./home.nix
  - ./flake.nix
  - ./modules/home-manager/CLAUDE.md
  - ./pkgs/CLAUDE.md
  - ./docs/CLAUDE.md
validation:
  max_days_stale: 30
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Centralized development configuration repository using **Nix + Home Manager** for declarative, reproducible dotfile and package management.

**Managed configurations:** Neovim, Tmux, Ghostty, Yazi, Zsh (Oh My Zsh + Powerlevel10k), Git (1Password SSH signing), Claude Code multi-profile, Biome.

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

# Enter development shell
nix develop
```

## Architecture

### Flake Structure

```
flake.nix                    # Entry point: exports homeManagerModules, nixosModules, devShells
+-- home.nix                 # Personal Home Manager config with sops-nix secrets
+-- work.nix                 # Work machine config (no sops, lean profile)
+-- user.nix                 # Machine-specific values (username, homeDirectory) - GITIGNORED
+-- work-user.nix            # Work machine-specific values - GITIGNORED
+-- modules/
|   +-- home-manager/        # User-level configuration modules
|   |   +-- default.nix      # Module aggregator + global options
|   |   +-- programs/        # Per-program modules (neovim.nix, tmux.nix, etc.)
|   |   +-- services/        # Service modules (direnv.nix, sops-env.nix)
|   +-- nixos/               # System-level modules (for NixOS servers)
+-- ai/                      # Source of truth for AI configs (exported globally by Nix)
|   +-- skills/              # Effect/Nx skills (exported to ~/.claude/skills + ~/.agents/skills)
|   +-- hooks/               # PostToolUse/UserPromptSubmit hooks (referenced in-repo)
+-- .claude/                 # Project-level Claude Code config (NOT commands/agents)
|   +-- settings.json        # Project hooks (references ai/hooks/)
|   +-- templates/           # CLAUDE.md and README.md templates
+-- pkgs/default.nix         # Centralized package definitions (DRY)
+-- secrets/default.yaml     # sops-nix encrypted secrets
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
- `core`: git, gh, zsh, tmux, fzf, ripgrep, fd, bat, lazygit
- `runtimes`: nodejs_24, bun, uv
- `utilities`: direnv, nix-direnv, jq, yq-go, gnumake, pkg-config, tree-sitter
- `linting`: biome (editor LSPs like nixd/pyright live in neovim.nix, not here)

### Secrets Management

**1Password-first approach with sops-nix bootstrap:**

**sops-nix** (bootstrap only):
- Only stores `op/service_account_token` in `secrets/default.yaml` (encrypted with age)
- Decrypted to tmpfs at Home Manager activation
- Enables non-interactive 1Password CLI access
- Age key at `~/.config/sops/age/keys.txt`

**Git config** (not secrets - set in Nix):
- `userName`, `userEmail`, `signing.key` set directly in `home.nix`
- These are public info visible in every commit
- See `dev-config.git` options in `home.nix`

**1Password** (AI service keys):
- All secrets stored in 1Password vault item `xsuolbdwx4vmcp3zysjczfatam` (vault: Dev)
- Fetched at shell startup via `~/.config/sops-nix/load-env.sh`
- Fields: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_AI_STUDIO_KEY`, `LITELLM_KEY`, `OPENROUTER_API_KEY`

**1Password SSH Agent** for authentication:
- SSH keys stored in 1Password vault (never on disk)
- Automatic commit signing via `op-ssh-sign`
- See `modules/home-manager/programs/ssh.nix` and `git.nix`

## Configuration Files (Dotfiles)

Dotfiles in `nvim/`, `tmux/`, `zsh/`, `ghostty/`, `yazi/` are version controlled and symlinked by Home Manager. Edit them directly - no rebuild needed (just reload the application).

Component-specific documentation:
- `nvim/CLAUDE.md` - Neovim plugin system, LSP, lazy loading
- `tmux/CLAUDE.md` - Tmux (Nix-managed plugins, no TPM), DevPod integration
- `zsh/CLAUDE.md` - Oh My Zsh, Powerlevel10k
- `docs/LINTING_POLICY.md` - Strict linting rules, GritQL patterns, AI guardrails

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

## Flake Composition & devShellHook

This repo can be imported as a flake input in consumer projects to provide:
1. Home Manager modules for User profile configuration
2. devShellHook for project-level editor/tool configuration auto-setup

### Usage in Consumer Repos

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  dev-config.url = "github:samuelho-dev/dev-config";
};

outputs = { self, nixpkgs, dev-config, ... }: {
  devShells.default = { pkgs, ... }: {
    buildInputs = [ /* project dependencies */ ];
    shellHook = ''
      ${dev-config.lib.devShellHook}
      echo "🚀 Project environment ready"
    '';
  };
};
```

### What devShellHook Does

Auto-creates project-level editor configurations on `nix develop`:

| Directory | Contents | Purpose | Management |
|-----------|----------|---------|------------|
| `.envrc` | `use flake` | direnv loads the flake into the shell | Created if missing, then auto-`direnv allow` |
| `.zed/` | Full Zed editor config | Zed editor configuration | Symlinked from Nix store (read-only) |
| `biome.json` | Extends `~/.config/biome/` | Biome formatter/linter | Auto-generated if missing |

### Key Implementation Details

- **Symlink strategy**: Full-directory symlink for `.zed` (no internal relative paths); `.envrc` and `biome.json` are generated in-place, not symlinked
- **Nix store paths**: Uses `${self}` references in flake.nix to handle symlinks correctly in `/nix/store`
- **Idempotent**: Each file/link is created only when absent, so user edits are never overwritten

### The `inputs ? dev-config` Pattern

Enables both standalone and composed usage:

```nix
# When imported as flake input
configSource = if inputs ? dev-config then "${inputs.dev-config}/nvim" else null;

# When used standalone
if inputs ? dev-config then ... else null  # Falls back gracefully
```

This pattern in modules enables dev-config to work both:
- **Standalone**: `home-manager switch --flake .` in this repo
- **Composed**: Imported as `inputs.dev-config` in other projects

## AI GUARDRAILS (CRITICAL) ⚠️

`docs/LINTING_POLICY.md` is the **single source of truth** for linting and
type-safety rules (full tables, decision trees, warning template, enforcement).
This section is the enforced summary — applies to all AI agents (Claude Code, ChatGPT, etc.).

### HARD ERROR: Type-safety workarounds (PROHIBITED)

Never emit these. If asked, REFUSE and propose the type-safe alternative
(`Schema.decodeUnknown()`, type guards, optional chaining, explicit annotations):

- `value as any` / `value as T` — unverified assertion
- `value!` — non-null assertion
- `@ts-ignore` / `@ts-expect-error` / `@ts-nocheck` — error suppression
- `satisfies` without an explicit type

Enforced by: Biome (`noExplicitAny`, `noNonNullAssertion`), GritQL
(`ban-type-assertions.grit`), and `scripts/validate-linting-config.sh`.

### HARD ERROR: Rule weakening (PROHIBITED)

Never weaken linting rules: `error` → `warn`/`off`, disabling TS `strict`,
adding suppression comments, GritQL patterns that override error-level rules, or
editing `.pre-commit-config.yaml` to skip hooks. Adding *stricter* rules is fine.
Enforced by `validate-linting-config.sh` (cannot bypass without `--no-verify`).

### SOFT WARNING: Linting-config edits require APPROVE

Before modifying `biome.json`, `tsconfig*.json`, `.pre-commit-config.yaml`, or
`biome/gritql-patterns/*.grit`: show the warning template from
`docs/LINTING_POLICY.md` (change summary, rationale, impact), then wait for the
human to type `APPROVE <description>`. Document the approval in the commit.

## Key Conventions

- **Formatter:** `alejandra` (run via `nix fmt`)
- **Nix style:** Explicit `lib.` prefixes, no `with` statements
- **Module options:** Use `lib.mkEnableOption` for optional features
- **Testing:** Always run `nix flake show --json` before committing Nix changes
- **Symlinks:** Home Manager manages all symlinks - never create manually

## For Future Claude Code Instances

When working with this repository:

### General Practices
- [ ] **Check flake validity** before committing: `nix flake show --json`
- [ ] **Format Nix files** with: `nix fmt`
- [ ] **Test configuration** before applying: `home-manager build --flake .`
- [ ] **Follow module patterns** in `modules/home-manager/programs/` for new programs
- [ ] **Use explicit `lib.` prefixes** - never use `with lib;`
- [ ] **Add packages** to `pkgs/default.nix` by category, not scattered in modules
- [ ] **Stage `user.nix`** before flake evaluation: `git add -f user.nix`
- [ ] **Update component CLAUDE.md** when modifying that component's architecture
- [ ] **Reference docs/** for user-facing documentation updates
- [ ] **Consult `modules/home-manager/CLAUDE.md`** for Home Manager module patterns

### AI Guardrails (CRITICAL) ⚠️
- [ ] **NEVER use `as any`** - Forbidden pattern. Use `Schema.decodeUnknown()` instead
- [ ] **NEVER add `@ts-ignore` or `@ts-nocheck` comments** - Forbidden pattern. Fix the type error properly
- [ ] **NEVER use non-null assertions (`!`)** - Forbidden pattern. Add proper null checking instead
- [ ] **NEVER weaken linting rules** - Changing severity from `error` → `warn/off` is blocked by pre-commit
- [ ] **ALWAYS warn before modifying linting configs** - Show warning template, wait for "APPROVE" confirmation
- [ ] **ALWAYS consult `docs/LINTING_POLICY.md`** when in doubt about type safety or linting rule changes
- [ ] **ALWAYS follow decision trees** in CLAUDE.md for type-related and rule-modification requests
- [ ] **NEVER bypass pre-commit hooks** - Use `git commit --no-verify` only with explicit justification and developer attention
