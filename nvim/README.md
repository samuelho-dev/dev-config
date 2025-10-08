# Neovim Configuration

Modern Neovim configuration based on Kickstart.nvim with LSP, completion, and git integration.

## Overview

This configuration provides:
- **LSP support** for TypeScript, Python, and Lua
- **Auto-completion** with blink.cmp
- **Git integration** (lazygit, GitHub PRs/issues, diff viewing)
- **Markdown support** with Obsidian vault integration
- **Fuzzy finding** with Telescope
- **Custom diagnostic copy** for Claude Code workflows

**Leader key:** `<space>` (spacebar)

## Quick Start

### Installation

Neovim plugins are automatically installed during `scripts/install.sh`.

Manual plugin installation:
```vim
:Lazy sync
```

### Essential Commands

| Command | Purpose |
|---------|---------|
| `:Lazy` | Manage plugins |
| `:Mason` | Manage LSP servers/formatters |
| `:checkhealth` | Diagnose issues |
| `:LspInfo` | Check LSP status |

## Key Features

### LSP & Code Intelligence

**Navigation:**
- `grd` - Go to definition
- `grr` - Find references
- `gri` - Go to implementation
- `grt` - Go to type definition
- `grn` - Rename symbol
- `gra` - Code actions

**Symbols:**
- `gO` - Document symbols
- `gW` - Workspace symbols

**Formatting:**
- `<leader>f` - Format buffer
- Auto-format on save (except C/C++)

### Fuzzy Finding (Telescope)

- `<leader>sf` - Find files
- `<leader>sg` - Live grep
- `<leader>sh` - Search help
- `<leader>sk` - Search keymaps
- `<leader><leader>` - Switch buffers
- `<leader>/` - Search in current buffer

### Search and Replace (Spectre)

Project-wide search and replace with visual interface:

- `<leader>rr` - Open Spectre (search and replace in project)
- `<leader>rw` - Replace word under cursor
- `<leader>rf` - Replace in current file only
- `<leader>rw` (visual mode) - Replace selected text

**In Spectre UI:**
- Enter search term and replacement
- `dd` - Toggle individual match on/off
- `<leader>R` - Replace all (after review)
- `<leader>rc` - Replace current line only
- `ti` - Toggle ignore case
- `th` - Toggle search hidden files
- `<leader>o` - Show all options
- `<leader>q` - Send to quickfix list

Powered by ripgrep for blazing fast search!

### Git Integration

**lazygit:**
- `<leader>gg` - Open lazygit
- `<leader>gf` - Lazygit for current file

**GitHub (requires `gh` CLI):**
- `<leader>gp` - List Pull Requests
- `<leader>gi` - List Issues

**Diff & History:**
- `<leader>gd` - Open diff view
- `<leader>gh` - File history
- `<leader>gH` - Branch history

**Merge Conflicts:**
- `<leader>gco` - Choose ours
- `<leader>gct` - Choose theirs
- `<leader>gcb` - Choose both
- `<leader>gcn` - Next conflict

### Markdown & Note-Taking

**Obsidian Integration:**
- `gf` - Follow markdown links
- `<leader>ch` - Toggle checkboxes
- Auto-detects vault from file location

**Preview:**
- `<leader>mp` - Toggle browser preview
- In-buffer rendering with render-markdown.nvim
- Mermaid diagrams render inline (requires ImageMagick and `@mermaid-js/mermaid-cli`)

**Outline:**
- `<leader>o` - Toggle document outline

### CSV Highlighting

- Automatic rainbow column highlighting for CSV/TSV dialects
- Commands like `:RainbowDelim`, `:RainbowAlign`, and `:CSVLint` for manual control
- Loads when opening CSV-style files or running a Rainbow CSV command

### Mermaid Diagrams

Inline previews use `image.nvim` + Mermaid CLI. Install the supporting tools once per machine:

```bash
brew install imagemagick          # or your package manager of choice
npm install -g @mermaid-js/mermaid-cli
```

Ghostty implements the Kitty graphics protocol, so diagrams also render there (keep an eye on upstream Ghostty releases for graphics fixes).

### AI Assistance

- **Streaming Completions (Minuet)**  
  - Powered by GLM 4.5 via `minuet-ai.nvim` + `blink.cmp`.  
  - Export `ZHIPUAI_API_KEY` before launching Neovim.  
  - Completions stream automatically; use `<Tab>`/`<S-Tab>` (super-tab preset) to accept or cycle.

- **Chat & Refactors (CodeCompanion)**  
  - `:CodeCompanionChat` opens a dedicated buffer backed by GLM 4.5.  
  - Use inline actions (visual select → `:CodeCompanion`) for targeted edits.  
  - You can still configure additional adapters (Claude, OpenAI) in `init.lua` if you need higher quality or ACP agents.

- **Infrastructure REPLs (yarepl)**  
  - `:REPLStart claude` attaches to the Claude CLI in your `CLAUDE_AGENT_ROOT` (defaults to `~/Projects/claude-code-agent`).  
  - Additional presets: `aider`, `cursor` (runs `cursor-agent`), `observability` (runs `./scripts/start-system.sh`), and `sqlite` for the agent database.  
  - Toggle focus/hide with `:REPLFocus`, `:REPLHide`, and send code with `:REPLSendLine` / `:REPLSendVisual`.

### File Explorer

- `\` or `<leader>e` - Toggle Neo-tree
- Auto-refreshes on external changes
- Follows current file

### Multiple Cursors

- `<leader>m` - Start multi-cursor mode, select word under cursor
- `<leader>m` (again) - Select next occurrence
- `<C-Down>` / `<C-Up>` - Add cursor down/up
- `<C-LeftMouse>` - Add cursor at mouse click

**In multi-cursor mode:**
- `n` / `N` - Get next/previous occurrence
- `[` / `]` - Select next/previous cursor
- `q` - Skip current and get next
- `Q` - Remove current cursor
- `Tab` - Switch between cursor and extend mode
- `<Esc>` - Exit multi-cursor mode

### Indentation Guides

Visual indentation guides show vertical lines for each indentation level, making nested code easier to read.

- **Automatic:** Guides appear automatically in all code files
- **Scope highlighting:** Current code block/scope is highlighted
- **Works with:** Spaces and tabs
- **Excluded from:** Terminal, help files, file explorer

No keybindings needed - it's always active!

### Diagnostic Copy (Claude Code Integration)

- `<leader>ce` - Copy **E**rrors only
- `<leader>cd` - Copy all **D**iagnostics

Output includes file paths, line numbers, and severity grouping - perfect for pasting into Claude Code!

### Quick Save (controlsave.nvim)

**Custom plugin for quick file saving.**

- `<C-s>` - Save current file (normal, insert, visual mode)

**Features:**
- Industry-standard `Ctrl+S` keybinding (matches VS Code, IntelliJ)
- Works across all modes seamlessly
- Error handling for read-only files and special buffers
- Integrates with conform.nvim auto-format on save

**Traditional Vim commands:**
- `:w` - Save current file
- `:wa` - Save all files
- `:wq` - Save and quit

## Configuration

### Adding LSP Servers

Edit `init.lua` around line 707:

```lua
local servers = {
  ts_ls = {},          -- TypeScript
  pyright = {},        -- Python
  lua_ls = {},         -- Lua
  rust_analyzer = {},  -- Add Rust
  gopls = {},          -- Add Go
}
```

Restart Neovim, then `:Mason` to install.

### Adding Formatters

Edit `init.lua` around line 809:

```lua
formatters_by_ft = {
  lua = { 'stylua' },
  python = { 'ruff_format' },
  javascript = { 'prettier' },
  rust = { 'rustfmt' },  -- Add Rust formatter
}
```

### Adding Plugins

Add to `require('lazy').setup({ ... })` block in `init.lua`:

```lua
{
  'author/plugin-name',
  config = function()
    require('plugin-name').setup()
  end,
},
```

Or create a file in `lua/custom/plugins/` and uncomment line 1224:
```lua
{ import = 'custom.plugins' },
```

## File Structure

```
nvim/
├── init.lua                 # Main config (~1200 lines, read top-to-bottom)
├── lazy-lock.json           # Plugin versions (committed to git)
├── .stylua.toml             # Lua formatter config
└── lua/
    ├── custom/plugins/      # Your custom plugins
    │   └── diagnostics-copy.lua
    └── kickstart/           # Kickstart modules (optional)
```

## Updating Plugins

```vim
:Lazy update              " Update plugins
:Lazy restore             " Restore to locked versions
```

Commit `lazy-lock.json` after updating to keep versions consistent across machines.

## Troubleshooting

### LSP not working
```vim
:LspInfo                  " Check LSP client status
:Mason                    " Install/reinstall LSP servers
:checkhealth lsp          " Diagnose LSP issues
```

### Completion not showing
```vim
:checkhealth blink        " Check blink.cmp status
```

### `pkg-config` warning on startup
- We pin blink.cmp to the Lua fuzzy matcher, so missing `pkg-config` is expected.
- Install `pkg-config` if you want to experiment with the optional Rust matcher.

### File not auto-reloading
Check that autoread is enabled: `:set autoread?`

Should show `autoread` (no "no" prefix).

## Resources

- Full keybindings: See `docs/KEYBINDINGS_NEOVIM.md` in repository root
- Kickstart.nvim: https://github.com/nvim-lua/kickstart.nvim
- lazy.nvim: https://github.com/folke/lazy.nvim
- Mason: https://github.com/mason-org/mason.nvim
