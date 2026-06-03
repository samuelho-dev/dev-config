# Neovim Configuration

Modular Neovim configuration (originally based on Kickstart.nvim) managed by lazy.nvim,
with LSP, completion, git tooling, markdown/Obsidian support, and AI assistance.

**Leader key:** `<space>` (spacebar). Full keybinding reference: `docs/KEYBINDINGS_NEOVIM.md`.

## Quick start

Plugins install automatically during `scripts/install.sh`. Manual install: `:Lazy sync`.

| Command | Purpose |
|---------|---------|
| `:Lazy` | Manage plugins |
| `:Mason` | Manage LSP servers/formatters (non-Nix machines) |
| `:checkhealth` | Diagnose issues |
| `:LspInfo` | Check LSP status |

## Plugin inventory

One file per category under `lua/plugins/`. The list below matches the source exactly.

### editor.lua — files, search, navigation
- **guess-indent.nvim** — auto-detect tabstop/shiftwidth
- **neo-tree.nvim** — file explorer (`\` or `<leader>e`); auto-refresh, follows current file, shows hidden/gitignored
- **nvim-lsp-file-operations** — updates imports on file move/rename
- **yazi.nvim** — terminal file manager (`<leader>fy`, `<leader>fw`, `<leader>fY`)
- **telescope.nvim** — fuzzy finder (+ fzf-native, ui-select)
- **nvim-spectre** — project-wide search/replace (ripgrep + sed)
- **harpoon** (harpoon2) — mark/jump to frequent files

### lsp.lua — language servers + formatting
- **nvim-lspconfig** with **mason.nvim**, **mason-lspconfig.nvim**, **mason-tool-installer.nvim**, **fidget.nvim**
- **conform.nvim** — formatter runner
- **lazydev.nvim** — Neovim Lua API completion (ft=lua)
- Servers: `ts_ls`, `biome`, `pyright`, `lua_ls`, `nixd`
- Formatters: stylua (lua), ruff (python), **biome** (js/ts/jsx/tsx/json/jsonc), prettier (yaml/markdown), alejandra (nix)

### completion.lua — autocompletion
- **blink.cmp** — completion engine (super-tab preset, Lua fuzzy matcher)
- **LuaSnip** — snippet engine

### ai.lua — AI assistance (all gated on env vars)
- **minuet-ai.nvim** — inline completion (OpenRouter / ZhipuAI / OpenAI)
- **codecompanion.nvim** — chat/inline (above + Anthropic)
- **avante.nvim** — Cursor-like assistant via LiteLLM proxy (`LITELLM_MASTER_KEY`)
- **yarepl.nvim** — REPL integration (claude/aider/aichat + language REPLs)

### git.lua — git integration
- **gitsigns.nvim** — gutter signs
- **lazygit.nvim** — lazygit TUI (`<leader>gg`, `<leader>gf`)
- **octo.nvim** — GitHub PRs/issues (`<leader>gp`, `<leader>gi`; needs `gh`)
- **diffview.nvim** — diffs & history (`<leader>gd`, `<leader>gh`, `<leader>gH`)
- **git-conflict.nvim** — merge conflict resolution (`<leader>gc*`)

### markdown.lua — markdown & notes
- **obsidian.nvim** — auto-detects vault by searching upward for `.obsidian`; `<leader>ch` toggle checkbox
- **render-markdown.nvim** — in-buffer rendering
- **markdown-preview.nvim** — browser preview (`<leader>mp`)
- **bullets.vim** — list/task auto-formatting
- **outline.nvim** — document outline (`<leader>o`)

### ui.lua — interface
- **which-key.nvim** — keybinding hints
- **kanagawa.nvim** — colorscheme (`kanagawa-dragon`, comments non-italic)
- **todo-comments.nvim** — highlight TODO/FIXME/NOTE
- **mini.nvim** — mini.ai, mini.surround, mini.statusline
- **vim-visual-multi** — multiple cursors (`<leader>m`, remapped off `<C-n>` to avoid blink conflict)
- **indent-blankline.nvim** — indent guides with scope highlighting

### treesitter.lua — syntax
- **nvim-treesitter** (`main` branch) — compiles parsers locally; needs `tree-sitter` CLI + C compiler
- Parsers: bash, c, diff, html, lua, luadoc, markdown, markdown_inline, query, vim, vimdoc, javascript, typescript, tsx, jsdoc, python, json, yaml, toml, css

### tools.lua / training.lua
- **csvview.nvim** — virtual-text CSV viewer (border mode; needs CSV filetype autocmd in `config/autocmds.lua`)
- **vim-be-good** — Vim motion practice games (`<leader>tv`)

## Key features

### LSP & code intelligence
`grd` definition · `grr` references · `gri` implementation · `grt` type · `grD` declaration ·
`grn` rename · `gra` code action · `gO` document symbols · `gW` workspace symbols ·
`<leader>th` toggle inlay hints · `<leader>f` format · auto-format on save (except C/C++).

### Fuzzy finding (Telescope)
`<leader>sf` files · `<leader>sg` grep · `<leader>sw` word · `<leader>sh` help ·
`<leader>sk` keymaps · `<leader>sd` diagnostics · `<leader>sr` resume · `<leader>sn` nvim config ·
`<leader><leader>` buffers · `<leader>/` current buffer.

### Search & replace (Spectre)
`<leader>rr` project search/replace · `<leader>rw` word (also visual) · `<leader>rf` current file.
In the Spectre UI: `dd` toggle a match, `<leader>R` replace all, `ti`/`th` toggle ignore-case/hidden.

### Git
`<leader>gg`/`<leader>gf` lazygit · `<leader>gp`/`<leader>gi` GitHub PRs/issues ·
`<leader>gd`/`<leader>gh`/`<leader>gH` diff/file/branch history ·
`<leader>gco/gct/gcb/gc0` conflict choose · `<leader>gcn`/`<leader>gcp` next/prev conflict.

### Markdown & Obsidian
Vault auto-detection works from any directory (searches upward for `.obsidian`, handles symlinks,
zero hardcoded paths). `<leader>ch` toggle checkbox in notes, `<leader>mp` browser preview,
`<leader>o` outline. In-buffer rendering via render-markdown.nvim.

### File navigation
- Neo-tree: `\` or `<leader>e` toggle.
- Yazi: `<leader>fy` open, `<leader>fw` in cwd, `<leader>fY` resume.
- Harpoon: `<leader>ha` add, `<leader>hm` menu, `<leader>h1`–`<leader>h4` jump, `<leader>hp`/`<leader>hn` prev/next.

### Multiple cursors (vim-visual-multi)
`<leader>m` start / select next occurrence · `<C-Down>`/`<C-Up>` add cursor · `n`/`N` next/prev ·
`q` skip · `Q` remove · `Tab` cursor/extend · `<Esc>` exit.

### AI assistance
Each tool activates only when its API key/env var is exported before launching Neovim:
- **minuet** — streaming inline completions (`OPENROUTER_API_KEY`/`ZHIPUAI_API_KEY`/`OPENAI_API_KEY`); accept with super-tab `<Tab>`/`<S-Tab>`.
- **codecompanion** — `:CodeCompanionChat` and visual-select `:CodeCompanion` (above keys or `ANTHROPIC_API_KEY`).
- **avante** — `:AvanteAsk` / `:AvanteEdit` / `:AvanteToggle` via a LiteLLM proxy; export `LITELLM_MASTER_KEY` and forward the proxy to `localhost:4000`.
- **yarepl** — `:REPLStart claude` (or `aider`, `aichat`, `observability`, `python`, `R`, `bash`, `zsh`); `:REPLSendLine` / `:REPLSendVisual`, `:REPLFocus` / `:REPLHide`. Agent dir from `CLAUDE_AGENT_ROOT` (default `~/Projects/claude-code-agent`).

### Productivity utilities
- **Diagnostic copy** (Claude Code) — `<leader>ce` errors only, `<leader>cd` all diagnostics; output has file paths, line numbers, severity grouping.
- **Quick save** — `<C-s>` in normal/insert/visual; handles read-only/special buffers and runs format-on-save.
- **TypeScript return-type stripper** — runs automatically on save for ts/tsx/js/jsx; debug via `:TSStripPreview`, `:TSStripTest`, `:TSStripNow`, `:TSStripDebug`.
- **Path copy** — `<leader>crp` relative path, `<leader>cp` absolute path.
- **Reload config** — `<leader>Rc`.
- **CSV** — automatic virtual-text column view on opening `.csv`/`.tsv`.

## Configuration

- **Add an LSP server:** `lua/plugins/lsp.lua:159` (`servers` table), then `:Mason` (non-Nix machines).
- **Add a formatter:** `lua/plugins/lsp.lua:277` (`formatters_by_ft`).
- **Add a plugin:** append to the relevant `lua/plugins/*.lua`, or create a new category file and import it at `init.lua:46-57`.
- See `nvim/CLAUDE.md` for the full where-to-add reference and architecture notes.

## Maintenance

```vim
:Lazy update     " update plugins
:Lazy restore    " restore locked versions
```

Commit `lazy-lock.json` after updating to keep versions consistent across machines.

**Troubleshooting:** `:LspInfo` / `:Mason` / `:checkhealth lsp` for LSP; `:checkhealth blink` for
completion. The `blink_cmp_fuzzy lib is not downloaded/built` warning is expected (Lua fuzzy
matcher is intentional). For auto-reload, confirm `:set autoread?` shows `autoread`.

## Resources

- Keybindings: `docs/KEYBINDINGS_NEOVIM.md`
- Kickstart.nvim: https://github.com/nvim-lua/kickstart.nvim
- lazy.nvim: https://github.com/folke/lazy.nvim
