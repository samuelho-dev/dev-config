---
scope: zed/
updated: 2025-12-24
relates_to:
  - ../CLAUDE.md
  - ../biome.json
  - ../nvim/CLAUDE.md
---

# CLAUDE.md

Guidance for the Zed editor configuration in this directory.

## Purpose

Zed config tuned to mirror the Neovim workflow: Vim mode, Space leader, and Biome
as the primary JS/TS/JSON formatter/linter.

## Files

- `settings.json` → `~/.config/zed/settings.json` — editor settings, formatters, LSP.
- `keymap.json` → `~/.config/zed/keymap.json` — Vim-style, LazyVim-inspired bindings.

Both are symlinked by Home Manager. Changes take effect after restarting Zed.

## Conventions

- Keep keybindings in sync with `nvim/lua/config/keymaps.lua` so muscle memory carries
  between editors (Space leader, `Ctrl-h/j/k/l` pane nav, `g r *` LSP, `Space e`/`Space f`).
- Point the Biome LSP at the shared config: `lsp.biome.settings.config_path = "~/.config/biome/biome.json"`.
- Biome owns TypeScript/TSX/JavaScript/JSON (auto-fix + organize imports). Other languages
  use external formatters: Lua `stylua`, Python `ruff`, YAML/Markdown `prettier` — same as
  Neovim's conform setup.
- `vim_mode: true`; add new languages under `languages` with an `external` formatter, and new
  bindings under the appropriate `context` (e.g. `VimControl && !VimWaiting`).

See root `CLAUDE.md` for general AI conventions and guardrails.
