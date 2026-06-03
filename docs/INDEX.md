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
| [INSTALLATION](./INSTALLATION.md) | Nix + Home Manager bootstrap |
| [CONFIGURATION](./CONFIGURATION.md) | Customization and machine-specific config |
| [ARCHITECTURE](./ARCHITECTURE.md) | Flake composition and project linkage |
| [LINTING_POLICY](./LINTING_POLICY.md) | Type-safety and linting rules (authoritative) |
| [KEYBINDINGS_NEOVIM](./KEYBINDINGS_NEOVIM.md) | Neovim key mappings |
| [KEYBINDINGS_TMUX](./KEYBINDINGS_TMUX.md) | Tmux key mappings |

## Nix Guides (`docs/nix/`)

| Guide | Description |
|-------|-------------|
| [00-quickstart](./nix/00-quickstart.md) | 5-minute setup |
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

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| ghostty | - | [CLAUDE](../ghostty/CLAUDE.md) | Ghostty terminal |
| tmux | [README](../tmux/README.md) | [CLAUDE](../tmux/CLAUDE.md) | Terminal multiplexer (Nix-managed plugins) |
| zsh | [README](../zsh/README.md) | [CLAUDE](../zsh/CLAUDE.md) | Shell (Oh My Zsh + Powerlevel10k) |
| nvim | [README](../nvim/README.md) | [CLAUDE](../nvim/CLAUDE.md) | Neovim (LazyVim-based) |
| zed | - | [CLAUDE](../zed/CLAUDE.md) | Zed editor (Vim mode + Biome) |
| yazi | [README](../yazi/README.md) | [CLAUDE](../yazi/CLAUDE.md) | Terminal file manager |
| biome/gritql-patterns | - | - | GritQL pattern sources (see [LINTING_POLICY](./LINTING_POLICY.md)) |
| modules/nixos | - | [CLAUDE](../modules/nixos/CLAUDE.md) | NixOS system-level modules |
| modules/home-manager | [README](../modules/home-manager/README.md) | [CLAUDE](../modules/home-manager/CLAUDE.md) | Home Manager modules (programs + services) |
| pkgs | [README](../pkgs/README.md) | [CLAUDE](../pkgs/CLAUDE.md) | Centralized package definitions |
| scripts | [README](../scripts/README.md) | [CLAUDE](../scripts/CLAUDE.md) | Installation and utility scripts |
| ai/hooks | - | [CLAUDE](../ai/hooks/CLAUDE.md) | Claude Code linting/type-safety hooks |

## AI Tooling (`ai/`)

Functional config copied to `~/.claude/` by Home Manager — not documentation. `ai/agents/` (agent definitions), `ai/commands/` (slash commands), `ai/skills/`, `ai/hooks/` (scripts).
