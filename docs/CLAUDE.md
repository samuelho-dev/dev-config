---
scope: docs/
updated: 2026-06-03
relates_to:
  - ../CLAUDE.md
  - ./INDEX.md
  - ./LINTING_POLICY.md
---

# CLAUDE.md

Guidance for maintaining documentation in `docs/` and across the repository.

## Three-Tier Documentation Model

Each component carries up to three docs, by audience:

| File | Audience | Answers |
|------|----------|---------|
| `README.md` | Users | **What** the tool does, **how** to use it (examples, commands, keybindings, quick reference) |
| `CLAUDE.md` | AI assistants | **Why** decisions were made, **where** to change things, patterns and conventions |
| `docs/INDEX.md` | Both | Catalog of every README/CLAUDE/guide in the repo |

Keep these distinct: do not duplicate feature prose into CLAUDE.md, and do not put
architectural rationale into README.md. `docs/INDEX.md` is the authoritative catalog —
do not maintain a parallel file tree here.

## Where to Make Changes

| Change | Touch this |
|--------|-----------|
| New dependency / prerequisite | `docs/INSTALLATION.md` (+ `pkgs/default.nix` for the package) |
| New config option / env var | `docs/CONFIGURATION.md` |
| New Neovim keybinding | `docs/KEYBINDINGS_NEOVIM.md` (source: `nvim/lua/config/keymaps.lua`) |
| New tmux keybinding | `docs/KEYBINDINGS_TMUX.md` (source: `modules/home-manager/programs/tmux.nix` `extraConfig`) |
| Linting / type-safety rule | `docs/LINTING_POLICY.md` (authoritative) + `docs/nix/11-strict-linting-guide.md` |
| New GritQL pattern | `biome/gritql-patterns/*.grit` (inline header) + `docs/LINTING_POLICY.md` |
| Component architecture | that component's `CLAUDE.md` |
| Component feature / quick start | that component's `README.md` |
| New doc file (any kind) | add a row to `docs/INDEX.md` |

## Standards

- Markdown headings (`##`/`###`), fenced code blocks with language hints, tables for
  keybinding references.
- Real examples over placeholders; verify commands and file paths before documenting.
- Cross-reference with relative paths (`[INSTALLATION](./INSTALLATION.md)`).
- Remove outdated content rather than letting it drift.

See root `CLAUDE.md` for general AI conventions and guardrails.
