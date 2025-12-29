---
scope: ./
updated: 2025-12-21
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

**Managed configurations:** Neovim, Tmux, Ghostty, Yazi, Zsh (Oh My Zsh + Powerlevel10k), Git (1Password SSH signing), Claude Code multi-profile, OpenCode, Biome.

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
+-- home.nix                 # Home Manager config with sops-nix secrets
+-- user.nix                 # Machine-specific values (username, homeDirectory) - GITIGNORED
+-- modules/
|   +-- home-manager/        # User-level configuration modules
|   |   +-- default.nix      # Module aggregator + global options
|   |   +-- programs/        # Per-program modules (neovim.nix, tmux.nix, etc.)
|   |   +-- services/        # Service modules (direnv.nix, sops-env.nix)
|   +-- nixos/               # System-level modules (for NixOS servers)
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
- `core`: git, zsh, tmux, fzf, ripgrep, fd, bat, lazygit
- `runtimes`: nodejs_20, bun, python3
- `kubernetes`: kubectl, helm, k9s, kind, argocd, cilium-cli
- `cloud`: awscli2, doctl, hcloud
- `iac`: terraform, terraform-docs
- `security`: gitleaks, kubeseal, sops
- `linting`: biome, hadolint, kube-linter, tflint, actionlint, yamllint, shellcheck

### Secrets Management

**Hybrid approach combining sops-nix + 1Password:**

**sops-nix** (for critical secrets):
- Git config (userName, userEmail, signingKey) in `secrets/default.yaml` (encrypted with age)
- 1Password service account token for prompt-free `op` CLI access
- Decrypted to tmpfs at Home Manager activation
- Environment variables loaded via `sops-env.nix` module
- Age key at `~/.config/sops/age/keys.txt`

**1Password** (for AI service keys):
- All AI service API keys stored in 1Password vault `xsuolbdwx4vmcp3zysjczfatam`
- Fetched on-demand via `op item get` in `load-env.sh`
- Benefits: Centralized secret management, easier rotation, better for team sharing
- Requires `OP_SERVICE_ACCOUNT_TOKEN` (loaded from sops-nix)
- See `modules/home-manager/services/sops-env.nix` for implementation

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
| `.claude/` | commands/, agents/, settings.json | Claude Code integration | Symlinked from Nix store + user customization |
| `.opencode/` | command/, plugin/, tool/ | OpenCode AI assistant | Symlinked from Nix store + user customization |
| `.factory/` | commands/, droids/, hooks/ | Factory Droid integration | Symlinked from Nix store + user customization |
| `.zed/` | Full Zed editor config | Zed editor configuration | Symlinked from Nix store (read-only) |
| `.grit/` | GritQL patterns | GritQL linting rules | Symlinked from Nix store (read-only) |
| `biome.json` | Config extends ~/.config/biome/ | Biome formatter/linter | Auto-generated if missing |

### Key Implementation Details

- **Symlink strategy**: Full-directory symlinks for configs without internal relative paths (.zed, .grit), subdirectory symlinks for configs with user customization (.claude, .opencode, .factory)
- **Nix store paths**: Uses `${self}` references in flake.nix to handle symlinks correctly in `/nix/store`
- **User customization**: Copies default settings.json and opencode.json on first run for user to customize
- **Idempotent**: Checks `if [ ! -d .claude ]` to avoid overwriting user changes

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

## AI Coding Agents (oh-my-opencode)

Multi-agent AI orchestration system for collaborative coding workflows.

### Available Agents

- **@Sisyphus**: Main orchestrator (Claude Opus 4.5, extended thinking 32k budget)
- **@oracle**: Architecture & debugging (Claude Opus 4.5 via OpenRouter)
- **@librarian**: Codebase analysis & doc research (Claude Sonnet 4.5)
- **@explore**: Fast file search & traversal (Grok 3 - free)
- **@frontend-ui-ux-engineer**: UI/UX design (Gemini 3 Pro)
- **@document-writer**: Technical writing (Gemini 3 Flash)
- **@multimodal-looker**: Image/PDF analysis (Gemini 2.5 Flash)

### Usage

```bash
# Single agent invocation
opencode
> Ask @oracle to review this architecture

# Background parallel execution
> Have @oracle design the API while @librarian researches patterns

# Keyword shortcuts
> ultrawork: Implement feature X with comprehensive testing
> ultrathink: Deep analysis of architectural implications
> search: Find all Effect.gen uses in monorepo
```

### Features

- **Built-in MCPs**: context7 (docs), websearch_exa (web), grep_app (GitHub search)
- **LSP Tools**: lsp_rename, lsp_find_references, lsp_code_actions
- **AST-Grep**: Structural code search and transformation
- **Markdown Table Formatting**: Automatic formatting of AI-generated tables with alignment support
- **Claude Code Compatibility**: Hooks, commands, skills fully supported
- **Intelligent Hooks**: Todo continuation, comment checking, context monitoring

### Configuration

Fully managed via Nix in `home.nix`:

```nix
dev-config.opencode.ohMyOpencode = {
  enable = true;
  disabledHooks = ["startup-toast"];
  # See docs/nix/12-oh-my-opencode.md for full options
};
```

**Documentation**: See `docs/nix/12-oh-my-opencode.md` for comprehensive guide.

## AI GUARDRAILS (CRITICAL) ⚠️

This repository enforces strict guardrails to prevent AI assistants from introducing type safety violations and linting rule weakening. These guardrails apply to all AI agents (Claude Code, OpenCode, ChatGPT, etc.).

### SOFT WARNING: Linting Configuration Modifications

When modifying any linting configuration file (`biome.json`, `tsconfig.json`, `.pre-commit-config.yaml`, or `biome/gritql-patterns/*.grit`), the AI must provide explicit warning and request confirmation before proceeding.

**Required warning template:**

```
⚠️  WARNING: Linting Configuration Modification Requested

This change affects the linting/type checking rules that apply to the entire codebase.
Rule modifications can have downstream effects on hundreds of files.

Change Summary:
[Details of the specific modification]

Rationale:
[Explanation of why this change is necessary]

Impact Analysis:
[What files will be affected, what rules are being changed]

Requires human approval. To approve, type: APPROVE [change description]
```

**Example usage pattern:**
1. AI identifies need to modify linting rules
2. AI displays warning with full details of the change
3. AI waits for explicit human approval with the "APPROVE" keyword
4. Only after approval does AI proceed with the modification
5. AI documents the approval in the commit message

See `docs/LINTING_POLICY.md` for complete policy and decision workflows.

### HARD ERROR: Type Safety Workarounds (STRICTLY PROHIBITED)

The following patterns are **strictly prohibited** and must never be used. If a request asks you to implement any of these patterns, you must refuse and suggest the type-safe alternative instead.

| Forbidden Pattern | Why Prohibited | Type-Safe Alternative | Example |
|------------------|---------------|-----------------------|---------|
| `value as any` | Defeats all type checking for that value | Use `Schema.decodeUnknown()` from Effect or explicit type guards | `const x: unknown = getValue(); const parsed = Schema.decodeUnknown(MySchema)(x)` |
| `@ts-ignore` comment | Suppresses type errors without fixing them | Fix the underlying type error properly | Add proper type annotations or use type guards |
| `@ts-expect-error` comment | Acknowledges error exists but ignores it | Fix the root cause | Refactor code to satisfy type constraints |
| `@ts-nocheck` comment | Disables all type checking for entire file | Add proper types to individual declarations | Split file, add gradual typing, use `as const` |
| `value as T` (non-null assertion with `as`) | Asserts type without verification | Use runtime validation with Schema or type guards | `if (value !== null && typeof value === 'T') { ... }` |
| `value!` (non-null assertion) | Suppresses null/undefined error without checking | Verify existence before use, use optional chaining | `value?.property` or `if (value) { ... }` |
| `satisfies` operator without type | Type-checking without explicit return type | Use explicit type annotation instead | `const x: MyType = { ... }` |

**Decision tree for type-related requests:**

```
Request to modify type-related code?
├─ "Just use 'as any'" → REFUSE: Suggest Schema.decodeUnknown()
├─ "Add @ts-ignore comment" → REFUSE: Fix the underlying type error
├─ "Use non-null assertion (!)" → REFUSE: Add proper null checking
├─ "The types are too strict" → PROPOSE: Discuss type narrowing, guards, or Schema validation
└─ "Simplify the types" → EVALUATE: Consider if simplification loses runtime safety
```

Enforcement mechanisms:
- **Biome rule**: `noExplicitAny: "error"` - Blocks `as any`
- **GritQL pattern**: `ban-ts-ignore.grit` - Blocks TS suppression comments
- **GritQL pattern**: `ban-non-null-assertions.grit` - Blocks `!` operator
- **Pre-commit hook**: `validate-linting-config.sh` - Blocks rule weakening

### HARD ERROR: Rule Weakening (STRICTLY PROHIBITED)

Linting rules establish minimum code quality standards. Weakening these rules (changing severity from `error` → `warn` or `off`) is not permitted without explicit approval from the project maintainer.

**Prohibited modifications:**

- Changing Biome rule level from `error` to `warn` or `off`
- Disabling TypeScript `strict` mode
- Adding new `@ts-ignore` or suppression comments
- Creating GritQL patterns that override existing error-level rules
- Modifying `.pre-commit-config.yaml` to skip validation hooks

**Decision tree for rule modification requests:**

```
Request to modify linting rules?
├─ "Add a new stricter rule" → ALLOW: This improves code quality
├─ "Change error → warn" → REFUSE: Would weaken the codebase
├─ "Disable a rule (off)" → REFUSE: Would weaken the codebase
├─ "Update rule configuration (same level)" → SOFT WARNING: Requires approval
└─ "Fix a rule that has bugs" → EVALUATE: Propose refinement, not removal
```

Enforcement mechanisms:
- **Pre-commit hook**: `validate-linting-config.sh` automatically detects and blocks rule weakening
- **Git blockers**: Cannot be bypassed without `git commit --no-verify` (which requires developer attention)

See `docs/LINTING_POLICY.md` for complete policy and enforcement details.

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
