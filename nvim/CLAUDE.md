---
id: CLAUDE
aliases: []
tags: []
---
# CLAUDE.md

AI-guidance for the Neovim configuration in this directory. Source of truth is the
`.lua` files — this doc summarizes their structure and tells you where to make changes.
User-facing feature docs live in `README.md`; full keybinding tables live in
`docs/KEYBINDINGS_NEOVIM.md` (repo root).

## Architecture

Modular config managed by **lazy.nvim**. Two concerns are kept separate:

- `lua/config/` — core Neovim settings, **no plugin dependencies**, loaded eagerly on startup.
- `lua/plugins/` — lazy-loaded plugin specs, one file per category, each returning a spec table.
- `lua/plugins/custom/` — plain Lua utility modules (NOT plugin specs), required directly.

```
nvim/
├── init.lua                 # Entry point (81 lines): bootstraps lazy.nvim, imports config + plugin categories
├── lazy-lock.json           # Plugin version lock (committed to git)
├── .stylua.toml             # Lua formatter config
├── lua/
│   ├── config/
│   │   ├── init.lua         # Loads options → autocmds → keymaps (order matters)
│   │   ├── options.lua      # vim options, leader key, provider disabling, .venv python detection
│   │   ├── autocmds.lua     # autoread/checktime, CSV filetype detection, highlight-on-yank
│   │   └── keymaps.lua      # core keybindings + custom-utility wiring + :TSStrip* commands
│   └── plugins/
│       ├── editor.lua       # file explorer, finder, search/replace, navigation
│       ├── lsp.lua          # LSP servers + conform.nvim formatters + lazydev
│       ├── completion.lua   # blink.cmp + LuaSnip
│       ├── ai.lua           # minuet, codecompanion, avante, yarepl
│       ├── git.lua          # gitsigns, lazygit, octo, diffview, git-conflict
│       ├── markdown.lua     # obsidian, render-markdown, preview, bullets, outline
│       ├── ui.lua           # which-key, kanagawa, todo-comments, mini, visual-multi, indent
│       ├── treesitter.lua   # nvim-treesitter (main branch)
│       ├── tools.lua        # csvview
│       ├── training.lua     # vim-be-good
│       └── custom/
│           ├── diagnostics-copy.lua          # copy LSP diagnostics for AI workflows
│           ├── controlsave.lua               # Ctrl+S save (calls the TS stripper)
│           └── typescript-return-stripper.lua # tree-sitter removal of TS return types
```

### Loading flow

1. `init.lua:17-28` bootstraps lazy.nvim (auto-clones on first launch).
2. `init.lua:32` → `require 'config'` → `lua/config/init.lua` loads, in order:
   `config.options` (sets `vim.g.mapleader` first), then `config.autocmds`, then `config.keymaps`.
   **Leader must be set before plugins load**, so options is always first.
3. `init.lua:46-58` calls `require('lazy').setup{}` importing the 10 plugin categories.
4. Plugins lazy-load per their triggers.

**Constraint:** `config/` modules must NOT `require` plugins (plugins aren't loaded yet).
They MAY `require 'plugins.custom.*'` (those are pure Lua). Plugin keybindings belong in the
plugin spec (`keys`/`config`), never in `config/keymaps.lua`.

### lazy.nvim trigger reference

| Trigger | Loads when | Example in this config |
|---------|-----------|------------------------|
| `event` | a Neovim event fires | telescope `VimEnter`; minuet `InsertEnter`; indent `BufReadPost` |
| `cmd` | a command is run | lazygit `LazyGit`; spectre `Spectre`; yarepl `REPLStart` |
| `ft` | a filetype opens | obsidian/render-markdown `markdown`; lazydev `lua`; csvview `csv` |
| `keys` | a mapping is pressed | yazi `<leader>fy`; outline `<leader>o`; vim-be-good `<leader>tv` |
| `cond` | predicate returns true | ai plugins gate on API-key env vars (see AI section) |
| `dependencies` | parent spec loads | plenary, nui, web-devicons across many specs |

## Where to add things (verified against source)

| Task | File:anchor | Notes |
|------|-------------|-------|
| Add LSP server | `lua/plugins/lsp.lua:159` (`servers` table) | key = server name, value = config table; capabilities auto-merged at `lsp.lua:211-215` |
| Add formatter | `lua/plugins/lsp.lua:277` (`formatters_by_ft`) | also add the tool to the Mason list at `lsp.lua:229-235` (non-Nix path) |
| Add LSP keybinding | `lua/plugins/lsp.lua:45-125` (`LspAttach` autocmd) | buffer-local `map()` helper at line 48 |
| Add completion source | `lua/plugins/completion.lua:69-74` (`sources`) | |
| Add plugin (existing category) | append to the relevant `lua/plugins/*.lua` return table | pick a lazy trigger |
| Add plugin category | new `lua/plugins/<name>.lua`, then import at `init.lua:46-57` | |
| Add core keybinding | `lua/config/keymaps.lua` | non-plugin only |
| Add vim option | `lua/config/options.lua` | leader/providers stay at top |
| Add autocmd | `lua/config/autocmds.lua` | filetype detection MUST end with `doautocmd FileType <ft>` to trigger lazy loading (see CSV at `autocmds.lua:21-29`) |
| Add custom utility | new `lua/plugins/custom/<name>.lua` returning `M`; wire keymap in `config/keymaps.lua` | |

## LSP & formatting

`lua/plugins/lsp.lua` configures servers via the Neovim 0.11+ native API
(`vim.lsp.config` / `vim.lsp.enable`, `lsp.lua:205-243`). It branches on
`is_nix_managed()` (`lsp.lua:37-42`): on Nix, binaries come from `~/.nix-profile/bin`
and Mason auto-enable is OFF; otherwise Mason installs and auto-enables.

**Servers (`lsp.lua:159-203`):** `ts_ls`, `biome` (single-file, root-pattern resolution
to `biome.json`/git root/`~/.config/biome`), `pyright`, `lua_ls`, `nixd` (formats via `alejandra`).

**Formatters — conform.nvim (`lsp.lua:248-300`):** `stylua` (lua), `ruff_format` (python),
**`biome`** for js/ts/jsx/tsx/json/jsonc (run as `check --fix --unsafe`, `lsp.lua:294-298`),
`prettier` for yaml/markdown, `alejandra` for nix. Format-on-save enabled for all but C/C++
(`lsp.lua:264-276`); manual format `<leader>f`.

## Completion

`lua/plugins/completion.lua`: `blink.cmp` (super-tab preset) + `LuaSnip`. Sources are
`lsp, path, snippets, lazydev`. **lazydev** is defined in `lsp.lua:6-15` (ft=lua) and pulled
in as a blink dependency — do not duplicate it. Fuzzy matcher is forced to the **Lua impl**
(`completion.lua:82-85`, `prebuilt_binaries.download = false`) to avoid native build deps;
the resulting `blink_cmp_fuzzy lib is not downloaded/built` healthcheck warning is expected.

## AI integration (`lua/plugins/ai.lua`)

Four plugins, each gated by `cond` on environment variables (set in shell before launch):

| Plugin | Loads when | Purpose |
|--------|-----------|---------|
| `minuet-ai.nvim` | `OPENROUTER_API_KEY` \|\| `ZHIPUAI_API_KEY` \|\| `OPENAI_API_KEY` (`ai.lua:10-12`) | inline completion via blink; auto-detects provider in priority order |
| `codecompanion.nvim` | any of the above OR `ANTHROPIC_API_KEY` (`ai.lua:63-65`) | chat/inline; builds openrouter+zhipuai adapters, defaults by priority |
| `avante.nvim` | `LITELLM_MASTER_KEY` (`ai.lua:151-153`) | Cursor-like assistant pointed at a LiteLLM proxy `http://localhost:4000/v1`; `build='make'` |
| `yarepl.nvim` | `cmd = REPL*` (`ai.lua:203-216`) | REPLs for aichat/claude/aider/observability + python/R/bash/zsh; agent dir from `CLAUDE_AGENT_ROOT` (default `~/Projects/claude-code-agent`) |

## Treesitter (`lua/plugins/treesitter.lua`)

Pinned to the **`main` branch** (the rewrite for Neovim 0.11+; `master` errors on Neovim 0.12
during markdown injection). Consequences:
- Parsers are installed via `require('nvim-treesitter').install(list)` and **compiled locally** —
  requires the `tree-sitter` CLI (from `pkgs.tree-sitter`) and a C compiler (`pkgs.gcc`).
- Highlighting/indent are wired manually in a `FileType` autocmd (`treesitter.lua:48-64`),
  not via the old `setup{}` API.

Parser list (`treesitter.lua:11-35`): bash, c, diff, html, lua, luadoc, markdown,
markdown_inline, query, vim, vimdoc, javascript, typescript, tsx, jsdoc, python, json, yaml,
toml, css.

## Custom utilities (`lua/plugins/custom/`)

These are plain modules returning `M`, wired up in `config/keymaps.lua:41-55`.

**diagnostics-copy.lua** — `copy_errors_only()` (`<leader>ce`), `copy_all_diagnostics()`
(`<leader>cd`). Reads `vim.diagnostic.get()`, groups by severity, writes both `+` and `*`
registers. Output is formatted for pasting into Claude Code.

**controlsave.lua** — `save()`, `save_all()`, `format_and_save()`, `setup(opts)`. Bound to
`<C-s>` in n/i/v modes (`keymaps.lua:57-68`). Validates buffer state (read-only, no name,
special buftypes), then calls the TS stripper before writing. Integrates with conform
format-on-save.

**typescript-return-stripper.lua** — removes function return-type annotations via a tree-sitter
query (function/arrow/method/method-signature `return_type`). Edits bottom-to-top to preserve
ranges; parameter types are preserved. `setup()` is called at `keymaps.lua:49-55`
(`enabled=true`, `notify_on_strip=true`). Runs automatically through `controlsave.save()`.
Debug user-commands at `keymaps.lua:92-113`: `:TSStripPreview`, `:TSStripTest`, `:TSStripNow`,
`:TSStripDebug`.

> Note: older docs referenced a `custom/mermaid.lua` and an `image.nvim` markdown handler.
> Neither exists in the current config — `markdown.lua` ships no inline-diagram renderer.
> Do not re-add references to them.

## Key conventions

- `lazy-lock.json` is committed; after `:Lazy update`, commit it
  (`git add nvim/lazy-lock.json`). `:Lazy restore` re-pins.
- Leader key is `<space>` (`config/options.lua:7-8`).
- Format Lua with stylua (`.stylua.toml`).
- When adding/changing keybindings, update `docs/KEYBINDINGS_NEOVIM.md`; for user-facing
  features update `nvim/README.md`; for architecture update this file.
