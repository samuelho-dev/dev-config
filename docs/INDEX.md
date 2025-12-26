# Documentation Index

Central catalog of all documentation in the dev-config repository.

**Last Updated**: 2025-12-24
**Coverage**: ~93% (target: 90%)

---

## Quick Navigation

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| **Root** | [README](../README.md) | [CLAUDE](../CLAUDE.md) | Repository overview and conventions |
| **docs** | [README](./README.md) | [CLAUDE](./CLAUDE.md) | Documentation hub |

---

## Core Configuration Components

### Terminal & Shell

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| **ghostty** | [README](../ghostty/README.md) | [CLAUDE](../ghostty/CLAUDE.md) | Ghostty terminal configuration |
| **tmux** | [README](../tmux/README.md) | [CLAUDE](../tmux/CLAUDE.md) | Terminal multiplexer setup |
| **zsh** | [README](../zsh/README.md) | [CLAUDE](../zsh/CLAUDE.md) | Shell configuration (Oh My Zsh + Powerlevel10k) |

### Editor Configuration

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| **nvim** | [README](../nvim/README.md) | [CLAUDE](../nvim/CLAUDE.md) | Neovim configuration (LazyVim-based) |
| **zed** | - | [CLAUDE](../zed/CLAUDE.md) | Zed editor configuration (Vim mode + Biome) |
| **nvim/lua** | [README](../nvim/lua/README.md) | [CLAUDE](../nvim/lua/CLAUDE.md) | Lua configuration modules |
| **nvim/lua/config** | [README](../nvim/lua/config/README.md) | [CLAUDE](../nvim/lua/config/CLAUDE.md) | Core Neovim settings |
| **nvim/lua/plugins** | [README](../nvim/lua/plugins/README.md) | [CLAUDE](../nvim/lua/plugins/CLAUDE.md) | Plugin configurations |
| **nvim/lua/plugins/custom** | [README](../nvim/lua/plugins/custom/README.md) | [CLAUDE](../nvim/lua/plugins/custom/CLAUDE.md) | Custom plugin implementations |

### Developer Tools

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| **yazi** | [README](../yazi/README.md) | [CLAUDE](../yazi/CLAUDE.md) | Terminal file manager |
| **biome** | [README](../biome/README.md) | [CLAUDE](../biome/CLAUDE.md) | Linting and formatting configuration |
| **iac-linting** | [README](../iac-linting/README.md) | [CLAUDE](../iac-linting/CLAUDE.md) | Infrastructure-as-Code linting |
| **gritql-patterns** | - | [CLAUDE](../gritql-patterns/CLAUDE.md) | 246+ GritQL patterns across 17 languages |

---

## Nix & Home Manager

### NixOS Modules

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| **modules/nixos** | - | [CLAUDE](../modules/nixos/CLAUDE.md) | NixOS system-level modules (docker, shell, users) |

### Home Manager Modules

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| **modules/home-manager** | [README](../modules/home-manager/README.md) | [CLAUDE](../modules/home-manager/CLAUDE.md) | Home Manager module system overview |
| **modules/home-manager/programs** | - | [CLAUDE](../modules/home-manager/programs/CLAUDE.md) | 12 program modules (neovim, tmux, zsh, etc.) |
| **modules/home-manager/services** | - | [CLAUDE](../modules/home-manager/services/CLAUDE.md) | 2 service modules (direnv, sops-env) |

### Package Definitions

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| **pkgs** | [README](../pkgs/README.md) | [CLAUDE](../pkgs/CLAUDE.md) | Centralized package definitions by category |

### Nix Guides

| Guide | Description |
|-------|-------------|
| [00-quickstart](./nix/00-quickstart.md) | Quick start guide |
| [01-concepts](./nix/01-concepts.md) | Core Nix concepts |
| [02-daily-usage](./nix/02-daily-usage.md) | Daily usage patterns |
| [03-troubleshooting](./nix/03-troubleshooting.md) | Common issues and solutions |
| [04-opencode-integration](./nix/04-opencode-integration.md) | OpenCode integration guide |
| [05-1password-setup](./nix/05-1password-setup.md) | 1Password integration |
| [06-advanced](./nix/06-advanced.md) | Advanced Nix patterns |
| [07-litellm-proxy-setup](./nix/07-litellm-proxy-setup.md) | LiteLLM proxy configuration |
| [07-nixos-integration](./nix/07-nixos-integration.md) | NixOS integration |
| [08-home-manager](./nix/08-home-manager.md) | Home Manager deep dive |
| [08-testing](./nix/08-testing.md) | Testing Nix configurations |
| [09-1password-ssh](./nix/09-1password-ssh.md) | 1Password SSH agent setup |
| [10-biome-integration](./nix/10-biome-integration.md) | Biome linting integration |
| [10-npm-publishing](./nix/10-npm-publishing.md) | NPM publishing with Nix |
| [11-strict-linting-guide](./nix/11-strict-linting-guide.md) | Strict linting configuration |
| [12-oh-my-opencode](./nix/12-oh-my-opencode.md) | Oh-My-OpenCode agent system |

---

## Scripts & Utilities

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| **scripts** | [README](../scripts/README.md) | [CLAUDE](../scripts/CLAUDE.md) | Installation and utility scripts |

---

## AI & Development Tools

### Claude Code & OpenCode

| Component | README | CLAUDE | Description |
|-----------|--------|--------|-------------|
| **.claude/commands/** | - | Documented | 13+ slash commands |
| **.claude/agents/** | - | [CLAUDE](../.claude/agents/CLAUDE.md) | 42+ agent definitions |
| **.opencode/** | [README](../.opencode/README.md) | - | OpenCode configuration overview |
| **.opencode/lib/** | - | [CLAUDE](../.opencode/lib/CLAUDE.md) | Shared Effect-TS schemas and utilities |
| **.opencode/plugin/** | - | [CLAUDE](../.opencode/plugin/CLAUDE.md) | Guardrail plugins (gritql, mlg) |
| **.opencode/tool/** | - | [CLAUDE](../.opencode/tool/CLAUDE.md) | Custom tools (gritql, mlg) |
| **.opencode/command/** | - | Partial | 4 OpenCode commands |

---

## Reference Documentation

### Keybindings

| Reference | Description |
|-----------|-------------|
| [Neovim Keybindings](./KEYBINDINGS_NEOVIM.md) | Complete Neovim key mappings |
| [Tmux Keybindings](./KEYBINDINGS_TMUX.md) | Tmux prefix and key mappings |

### Setup Guides

| Guide | Description |
|-------|-------------|
| [Installation](./INSTALLATION.md) | Complete installation guide |
| [Configuration](./CONFIGURATION.md) | Configuration options |

---

## Documentation Coverage Summary

| Category | README | CLAUDE | Status |
|----------|--------|--------|--------|
| Root & docs | ✅ | ✅ | Complete |
| Terminal/Shell (ghostty, tmux, zsh) | ✅ | ✅ | Complete |
| Editors (nvim, zed) | ✅ | ✅ | Complete |
| Developer Tools (yazi, biome) | ✅ | ✅ | Complete |
| TypeScript configs | ✅ | ✅ | Complete |
| IaC linting | ✅ | ✅ | Complete |
| NixOS modules | - | ✅ | CLAUDE only |
| Home Manager modules | ✅ | ✅ | Complete |
| Home Manager programs | - | ✅ | CLAUDE only |
| Home Manager services | - | ✅ | CLAUDE only |
| Packages (pkgs/) | ✅ | ✅ | Complete |
| Scripts | ✅ | ✅ | Complete |
| GritQL patterns | - | ✅ | CLAUDE only |
| AI Tools (.opencode/, .claude/) | Partial | ✅ | CLAUDE complete |

**Overall: ~92%** (target: 90%) ✅

---

## Recent Updates (2025-12-24)

### Documentation Update (Latest)

| File | Action | Description |
|------|--------|-------------|
| `zed/CLAUDE.md` | Created | Architecture for Zed editor config |
| `ghostty/CLAUDE.md` | Fixed | Added frontmatter |
| `tmux/CLAUDE.md` | Fixed | Added frontmatter, ASCII trees |
| `zsh/CLAUDE.md` | Fixed | Added frontmatter, ASCII trees |
| `.opencode/lib/CLAUDE.md` | Fixed | Converted inline YAML to frontmatter |
| `.opencode/plugin/CLAUDE.md` | Fixed | Converted inline YAML to frontmatter |
| `.opencode/tool/CLAUDE.md` | Fixed | Converted inline YAML to frontmatter |

### Previous Updates (2025-12-21)

| File | Action | Description |
|------|--------|-------------|
| `scripts/README.md` | Created | User guide for installation scripts |
| `iac-linting/README.md` | Created | User guide for IaC linting configs |
| `.claude/agents/CLAUDE.md` | Created | Architecture for 42+ agent definitions |
| `modules/nixos/CLAUDE.md` | Created | Architecture for NixOS system modules |
| `./CLAUDE.md` | Fixed | Added checklist, converted Unicode→ASCII |
| `nvim/CLAUDE.md` | Fixed | Converted Unicode→ASCII trees |
| `biome/CLAUDE.md` | Fixed | Added frontmatter, checklist |
| `yazi/CLAUDE.md` | Fixed | Added frontmatter |
| `docs/CLAUDE.md` | Fixed | Added frontmatter |

### Previous Documentation Created

| File | Type | Description |
|------|------|-------------|
| `modules/home-manager/README.md` | README | User guide for Home Manager modules |
| `modules/home-manager/programs/CLAUDE.md` | CLAUDE | Architecture for 12 program modules |
| `modules/home-manager/services/CLAUDE.md` | CLAUDE | Architecture for 2 service modules |
| `biome/README.md` | README | User guide for Biome linting |
| `pkgs/README.md` | README | User guide for package definitions |
| `yazi/README.md` | README | User guide for Yazi file manager |
| `scripts/CLAUDE.md` | CLAUDE | Architecture for shell scripts |
| `iac-linting/CLAUDE.md` | CLAUDE | Architecture for IaC linting |
| `gritql-patterns/CLAUDE.md` | CLAUDE | Architecture for 246+ GritQL patterns |

---

## How to Use This Index

1. **New to the repo?** Start with [README](../README.md) and [CLAUDE](../CLAUDE.md)
2. **Setting up?** Follow [Installation](./INSTALLATION.md) then [Quick Start](./nix/00-quickstart.md)
3. **Customizing?** Check component-specific CLAUDE.md files
4. **Contributing?** Read the relevant CLAUDE.md before making changes

---

## Regenerating This Index

This index is auto-generated by the `/update-documentation` command:

```bash
/update-documentation . update
```

Last regenerated: 2025-12-24
