# Documentation Index

Catalog of documentation in the dev-config repository. Each top-level component has a `README.md` (user-facing: what/how) and/or a `CLAUDE.md` (AI-facing: why/where).

## Root

| Doc | Description |
|-----|-------------|
| [README](../README.md) | Repository overview |
| [CLAUDE](../CLAUDE.md) | Conventions, architecture, AI guardrails (authoritative) |

## Guides (`docs/`)

| Guide | Description |
|-------|-------------|
| [INSTALLATION](./INSTALLATION.md) | Nix + flake-selected Home Manager bootstrap; safe no-activation verification |
| [CONFIGURATION](./CONFIGURATION.md) | Native CLI manifest, explicit MCP auth, user skills and machine-specific settings |
| [ARCHITECTURE](./ARCHITECTURE.md) | Native/Nix ownership, project linkage and update boundaries |
| [LINTING_POLICY](./LINTING_POLICY.md) | Type-safety and linting rules (authoritative) |
| [KEYBINDINGS_NEOVIM](./KEYBINDINGS_NEOVIM.md) | Neovim key mappings |
| [KEYBINDINGS_TMUX](./KEYBINDINGS_TMUX.md) | Tmux key mappings |
| [Skills correction coverage](./research/SKILLS_CORRECTION_COVERAGE.md) | Frozen-inventory corrections, native review coverage, preservation and deferred ownership/evidence |

## Nix Guides (`docs/nix/`)

| Guide | Description |
|-------|-------------|
| [00-quickstart](./nix/00-quickstart.md) | Selected profile setup, native checks and explicit upgrades |
| [01-concepts](./nix/01-concepts.md) | dev-config flake/devShell model |
| [02-daily-usage](./nix/02-daily-usage.md) | Common workflows |
| [03-troubleshooting](./nix/03-troubleshooting.md) | Common issues |
| [04-testing](./nix/04-testing.md) | Testing configurations (dry-run/build) |
| [06-advanced](./nix/06-advanced.md) | Overlays, multiple devShells, `.envrc.local` |
| [07-litellm-proxy-setup](./nix/07-litellm-proxy-setup.md) | LiteLLM team proxy |
| [08-home-manager](./nix/08-home-manager.md) | Home Manager + NixOS integration, option reference |
| [09-1password-ssh](./nix/09-1password-ssh.md) | 1Password CLI, secrets, SSH agent, commit signing |
| [11-strict-linting-guide](./nix/11-strict-linting-guide.md) | Biome + GritQL linting reference |
| [13-npm-publishing](./nix/13-npm-publishing.md) | NPM publishing with Nix |

## Components

| Component | README | Description |
|-----------|--------|-------------|
| ghostty | - | Ghostty terminal |
| tmux | [README](../tmux/README.md) | Terminal multiplexer (Nix-managed plugins) |
| zsh | [README](../zsh/README.md) | Shell (Oh My Zsh + Powerlevel10k) |
| nvim | [README](../nvim/README.md) | Neovim (LazyVim-based) |
| zed | - | Zed editor (Vim mode + Biome) |
| yazi | [README](../yazi/README.md) | Terminal file manager |
| biome/gritql-patterns | - | GritQL pattern sources (see [LINTING_POLICY](./LINTING_POLICY.md)) |
| modules/nixos | - | NixOS system-level modules |
| modules/home-manager | [README](../modules/home-manager/README.md) | Home Manager modules (programs + services) |
| pkgs | [README](../pkgs/README.md) | Centralized package definitions |
| scripts | [README](../scripts/README.md) | Installer, native bootstrap and non-activating checks |
| ai/bootstrap.sh | [CONFIGURATION](./CONFIGURATION.md#native-tools-versions-and-skills) | One owner for writable OMP/Pi/Claude/OpenCode/Codex/Vercel |
| ai/hooks | - | Claude Code linting/type-safety hooks |

## AI Tooling (`ai/`)

`ai/bootstrap.sh install|update|check` owns writable OMP, Pi, Claude,
OpenCode, Codex and Vercel CLIs for the enabled profile manifest; no
independent per-agent startup installer upgrades them. `ai/sync-skills.sh`
reconciles individual curated links without replacing physical user
directories or unmanaged edits. `ai/mcp/` fans out profile-selected
Claude/OMP/Codex targets with explicit `op` or `env` auth and preserves
working config on missing required input. [Configuration](./CONFIGURATION.md)
distinguishes native Vercel OAuth from the MCP child's token.
