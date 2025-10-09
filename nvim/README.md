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

### Buffer Navigation (Barbar)

Numbered buffer navigation like browser tabs:

- `<M-1>` to `<M-9>` - Jump to buffer 1-9
- `<M-,>` / `<M-.>` - Previous/next buffer
- `<M-c>` - Close buffer
- `<M-p>` - Pin/unpin buffer
- `<leader>bp` - Buffer picker (shows letters)
- Visual tabline with file icons and git status

**Opening files into specific buffers:**
1. `<leader>bp` - Activate buffer picker
2. Press letter (a/b/c) - Jump to that buffer
3. Open file from Neo-tree - Opens in selected buffer

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
- **Auto-detects vaults** - Searches upward for `.obsidian` directory automatically
- **Works from any location** - No need to open nvim from vault root
- **Handles symlinks** - Works with symlinked vaults properly
- `<CR>` (Enter) - Smart action: follow links, toggle checkboxes, cycle headings
- `<leader>ch` - Toggle checkboxes
- `[o` / `]o` - Navigate to previous/next link
- Zero configuration needed - adapts to any machine automatically

**Preview:**
- `<leader>mp` - Toggle browser preview
- In-buffer rendering with render-markdown.nvim
- Mermaid diagrams render inline (requires ImageMagick and `@mermaid-js/mermaid-cli`)

**Outline:**
- `<leader>o` - Toggle document outline

### CSV Viewing

- Modern CSV viewer with virtual text borders (csvview.nvim)
- Border display mode shows clean column alignment
- Automatic activation when opening CSV files
- No file modification - uses virtual text rendering

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

### Quick File Navigation (Harpoon)

- `<leader>ha` - Add current file to Harpoon
- `<leader>hm` - Toggle Harpoon menu
- `<leader>h1-4` - Jump to marked files 1-4
- `<leader>hp/hn` - Previous/Next in Harpoon list
- Mark frequently used files for instant access

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

Edit `lua/plugins/lsp.lua:149`:

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

Edit `lua/plugins/lsp.lua:221`:

```lua
formatters_by_ft = {
  lua = { 'stylua' },
  python = { 'ruff_format' },
  javascript = { 'prettier' },
  rust = { 'rustfmt' },  -- Add Rust formatter
}
```

### Adding Plugins

**Method 1:** Add to existing category file in `lua/plugins/`:

```lua
-- lua/plugins/editor.lua (or appropriate category)
return {
  -- Existing plugins...

  {
    'author/plugin-name',
    config = function()
      require('plugin-name').setup()
    end,
  },
}
```

**Method 2:** Create new category file `lua/plugins/mycategory.lua`:

```lua
return {
  {
    'author/plugin-name',
    event = 'VimEnter',
    config = function()
      require('plugin-name').setup()
    end,
  },
}
```

Then add to `init.lua:56`:
```lua
{ import = 'plugins.mycategory' },
```

## File Structure

```
nvim/
├── init.lua                 # Main entry point (81 lines)
├── lazy-lock.json           # Plugin versions (committed to git)
├── .stylua.toml             # Lua formatter config
├── CLAUDE.md                # AI assistant guidance
├── README.md                # This file
└── lua/
    ├── config/              # Core Neovim configuration
    │   ├── init.lua         # Loads all config modules
    │   ├── options.lua      # Vim options
    │   ├── autocmds.lua     # Autocommands
    │   └── keymaps.lua      # Core keybindings
    └── plugins/             # Plugin specifications by category
        ├── editor.lua       # File explorer, fuzzy finder, search
        ├── lsp.lua          # LSP configuration and formatting
        ├── completion.lua   # Autocompletion
        ├── ai.lua           # AI assistance
        ├── git.lua          # Git integration
        ├── markdown.lua     # Markdown and Obsidian
        ├── ui.lua           # UI enhancements
        ├── treesitter.lua   # Syntax highlighting
        ├── tools.lua        # Utility tools
        └── custom/          # Custom plugin utilities
            ├── diagnostics-copy.lua
            ├── controlsave.lua
            └── mermaid.lua
```

### Modular Architecture

This configuration uses a **modular architecture** instead of a single monolithic file:

- **config/** - Core Neovim settings (options, autocmds, keymaps)
- **plugins/** - Plugin specifications organized by category
- **plugins/custom/** - Custom utility modules

**Benefits:**
- 94% reduction in main file size (1823 lines → 81 lines)
- Easy to find and modify specific features
- Clear separation of concerns
- Scalable for future additions

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
