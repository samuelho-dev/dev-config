# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with Neovim configuration in this directory.

## Architecture Overview

This Neovim configuration is based on **Kickstart.nvim** - a single-file (~1200 line) starter configuration designed for learning and customization.

**Design Philosophy:**
- Single `init.lua` file for core config (readable top-to-bottom)
- Custom plugins in `lua/custom/plugins/` for extensions
- Version-locked plugins via `lazy-lock.json` (committed to git)
- Minimal abstractions - every line is understandable

## File Structure

```
nvim/
├── init.lua                          # Main configuration (~1200 lines)
├── lazy-lock.json                    # Plugin version lock (committed)
├── .stylua.toml                      # Lua formatter config
└── lua/
    ├── custom/plugins/
    │   ├── init.lua                  # Custom plugin loader (empty template)
    │   └── diagnostics-copy.lua      # Claude Code integration
    └── kickstart/                    # Kickstart modules (optional)
        ├── health.lua
        └── plugins/                  # Additional kickstart plugins
```

## Core Architecture

### Plugin Manager: lazy.nvim
- Auto-bootstraps on first launch (lines 222-236)
- Plugins defined in `require('lazy').setup({ ... })` (lines 248-1250)
- Lock file: `lazy-lock.json` ensures consistent versions across machines

**Important commands:**
- `:Lazy` - Open plugin manager UI
- `:Lazy sync` - Install/update/remove plugins
- `:Lazy restore` - Restore to lazy-lock.json versions
- `:Lazy update` - Update all plugins

### LSP Configuration (lines 500-777)

**LSP Servers (defined ~line 707):**
```lua
local servers = {
  ts_ls = {},      -- TypeScript/JavaScript
  pyright = {},    -- Python
  lua_ls = {},     -- Lua
}
```

**Adding a new LSP:**
1. Add to `servers` table in init.lua:707
   ```lua
   rust_analyzer = {},
   gopls = {},
   ```
2. Restart Neovim
3. Run `:Mason` to install the server

**LSP Keybindings (defined in LspAttach autocommand ~line 559):**
- `grd` - Go to definition
- `grr` - Find references
- `gri` - Go to implementation
- `grt` - Go to type definition
- `grn` - Rename symbol
- `gra` - Code actions
- `gO` - Document symbols
- `gW` - Workspace symbols

### Formatters & Linters (lines 779-823)

**Managed by Conform.nvim + Mason:**
```lua
formatters_by_ft = {
  lua = { 'stylua' },
  python = { 'ruff_format' },
  javascript = { 'prettier' },
  typescript = { 'prettier' },
  -- Add more as needed
}
```

**Auto-format on save:** Enabled for all languages except C/C++
**Manual format:** `<leader>f`

### Autocompletion: blink.cmp (lines 825-922)

- Snippet engine: LuaSnip
- Sources: LSP, path, snippets, lazydev
- Preset: 'default' (recommended)
- Keybindings:
  - `<c-y>` - Accept completion
  - `<c-space>` - Show docs
  - `<c-n>/<c-p>` or arrow keys - Select item
  - `<tab>/<s-tab>` - Navigate snippet fields

### nvim-spectre (Search and Replace)

**Purpose:** Project-wide search and replace with visual UI.

**Features:**
- Visual interface for search and replace
- Preview all changes before applying
- Toggle individual matches on/off
- Supports regex patterns
- Multiple search/replace engines (ripgrep + sed)

**Configuration location:** Lines ~542-709

**Keybindings:**
- `<leader>rr` - Open Spectre UI (project-wide)
- `<leader>rw` - Replace word under cursor
- `<leader>rf` - Replace in current file only
- `<leader>rw` (visual) - Replace selection

**In Spectre UI (internal mappings):**
- `dd` - Toggle line (exclude/include match)
- `<cr>` - Jump to file
- `<leader>R` - Replace all matches
- `<leader>rc` - Replace current line
- `<leader>o` - Show options menu
- `ti` - Toggle ignore case
- `th` - Toggle search hidden files
- `trs` - Switch to sed engine
- `<leader>q` - Send to quickfix
- `<leader>l` - Resume last search

**Important notes:**
- Uses ripgrep (rg) for search - fast and respects .gitignore
- Uses sed for replace by default
- `live_update` disabled - won't auto-search while typing (performance)
- Opens in vertical split (`vnew`)
- Preview before replace - safe to use
- Lazy-loaded on command or keybinding

**Common workflows:**
1. **Replace across project:** `<leader>rr` → enter search → enter replacement → review → `<leader>R`
2. **Replace word:** Place cursor on word → `<leader>rw` → enter replacement → `<leader>R`
3. **Replace in file:** `<leader>rf` → enter search/replace → `<leader>R`
4. **Selective replace:** Use `dd` to toggle off unwanted matches, then `<leader>R`

**Dependencies:**
- ripgrep (rg) - already installed
- sed - system default (macOS/Linux)
- plenary.nvim - already installed

**Commands:**
- `:Spectre` - Open Spectre UI manually
- `:h spectre` - Full documentation

## Custom Plugins

### diagnostics-copy.lua

**Purpose:** Copy LSP diagnostics to clipboard for AI assistants (especially Claude Code).

**Location:** `lua/custom/plugins/diagnostics-copy.lua`

**Functions:**
- `copy_errors_only()` - Copy only ERROR severity diagnostics
- `copy_all_diagnostics()` - Copy all diagnostics grouped by severity

**Keybindings (defined ~line 1253):**
- `<leader>ce` - Copy Errors only
- `<leader>cd` - Copy all Diagnostics

**Output format:**
```
=== Diagnostics for /path/to/file.ts ===

ERRORS:
Line 42: 'foo' is not defined
Line 58: Type 'string' is not assignable to type 'number'

WARNINGS:
Line 12: Unused variable 'bar'
```

**Implementation notes:**
- Uses `vim.diagnostic.get(bufnr)` to fetch diagnostics
- Filters by severity: `vim.diagnostic.severity.ERROR`, `.WARN`, etc.
- Copies to both `+` and `*` registers for cross-platform compatibility
- Groups output by severity for readability

### controlsave.lua

**Purpose:** Quick save functionality with industry-standard `Ctrl+S` keybinding.

**Location:** `lua/custom/plugins/controlsave.lua`

**Functions:**
- `save()` - Save current buffer with error handling
- `save_all()` - Save all modified buffers
- `format_and_save()` - Explicitly format then save

**Keybindings (defined ~line 1788):**
- `<C-s>` - Save file (normal, insert, visual mode)

**Features:**
- Error handling for read-only files
- Checks for special buffer types (terminal, help, etc.)
- Validates file has a name before saving
- Optional save notifications (disabled by default)
- Integration with conform.nvim format_on_save

**Implementation notes:**
- Uses `vim.cmd 'write'` for saving (same as `:w`)
- Triggers `BufWritePre` event → conform.nvim auto-formats
- Exits insert/visual mode before saving (standard Vim behavior)
- Module pattern: returns table `M` with functions
- Future-proof: `setup()` function for configuration

**Configuration (optional):**
```lua
local controlsave = require 'custom.plugins.controlsave'
controlsave.setup({
  notify_on_save = true, -- Enable save notifications
})
```

**Error handling:**
- Read-only files → Warning notification
- Special buffers (terminal, help) → Warning notification
- Unnamed buffers → Suggests using `:saveas`

**Why a custom plugin vs inline keybinding?**
- Reusable save logic
- Error handling in one place
- Extensible (can add features later)
- Consistent with diagnostics-copy pattern
- Self-documenting code

## Adding Custom Plugins

### Method 1: Add to init.lua

Add directly in the `require('lazy').setup({ ... })` block:

```lua
{
  'author/plugin-name',
  config = function()
    require('plugin-name').setup({
      -- options
    })
  end,
},
```

### Method 2: Create file in lua/custom/plugins/

Create `lua/custom/plugins/my-plugin.lua`:

```lua
return {
  'author/plugin-name',
  event = 'VimEnter',  -- lazy-load on VimEnter
  config = function()
    require('plugin-name').setup()
  end,
}
```

Then uncomment line 1224 in init.lua:
```lua
{ import = 'custom.plugins' },
```

## Key Integrations

### Git Workflow (lines 1138-1202)

**lazygit.nvim:**
- `<leader>gg` - Open lazygit TUI
- `<leader>gf` - Lazygit for current file

**octo.nvim (GitHub):**
- `<leader>gp` - List PRs
- `<leader>gi` - List issues
- Requires `gh` CLI authenticated

**diffview.nvim:**
- `<leader>gd` - Open diff view
- `<leader>gh` - File history
- `<leader>gH` - Branch history

**git-conflict.nvim:**
- `<leader>gco` - Choose ours
- `<leader>gct` - Choose theirs
- `<leader>gcb` - Choose both
- `<leader>gcn` - Next conflict

### Markdown & Obsidian (lines 1036-1136)

**obsidian.nvim:**
- **Dynamic workspace mode** - Auto-detects vault from file location
- Works with ANY vault without hardcoded paths
- `gf` - Follow markdown links
- `<leader>ch` - Toggle checkboxes

**render-markdown.nvim:**
- Beautiful in-buffer rendering
- Code blocks, headings, lists styled

**markdown-preview.nvim:**
- `<leader>mp` - Toggle browser preview

### vim-visual-multi (Multiple Cursors)

**Purpose:** VS Code-style multiple cursor editing.

**Key keybindings:**
- `<leader>m` - Start multi-cursor, select word (remapped from `<C-n>` to avoid blink.cmp conflict)
- `<C-Down>/<C-Up>` - Add cursor vertically
- `<C-LeftMouse>` - Add cursor at click

**Configuration location:** Lines ~1185-1217

**Important notes:**
- Vimscript-based plugin (not Lua-native)
- Default `<C-n>` remapped to `<leader>m` to avoid conflict with blink.cmp
- Theme set to 'iceblue' to match tokyonight colorscheme
- Lazy-loaded with 'VeryLazy' to minimize startup impact

**Common workflows:**
1. **Select all occurrences:** `<leader>m`, then `<leader>m` repeatedly, or use regex selection
2. **Column editing:** Visual block select (`<C-v>`), then `<leader>m`
3. **Vertical cursors:** `<C-Down>` or `<C-Up>` from normal mode
4. **Pattern-based:** `\\A` to select all with regex pattern

**Commands:**
- `:h visual-multi` - Full documentation
- `\\<Space>` - Show all VM commands (VM leader is \\)

### indent-blankline.nvim (Indentation Guides)

**Purpose:** Visual indentation guides with scope highlighting.

**Features:**
- Vertical lines showing indentation levels
- Current scope/block highlighting
- Works on blank lines
- Treesitter-aware for accurate scope detection

**Configuration location:** Lines ~1217-1252

**Important notes:**
- Uses `│` character for guides (can be customized)
- Scope highlighting uses `Function` and `Label` highlight groups (matches tokyonight)
- Automatically excluded from special buffers (neo-tree, lazy, mason, terminal, etc.)
- Lazy-loaded on file open for performance
- No user commands or keybindings - always active

**Customization options:**
- Change indent character: `char = '▏'` (options: `│`, `▏`, `┊`, `┆`)
- Disable scope highlighting: `scope.enabled = false`
- Show scope end underline: `scope.show_end = true`
- Add file types to exclude list in `exclude.filetypes`

**Commands:**
- `:IBLEnable` - Enable indent guides (if disabled)
- `:IBLDisable` - Disable indent guides
- `:IBLToggle` - Toggle indent guides
- `:IBLToggleScope` - Toggle scope highlighting
- `:h ibl` - Full documentation

## Important Settings

### Auto-reload files (lines 169-186)

Critical for Claude Code workflows:

```lua
vim.o.autoread = true

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  command = 'checktime',
})
```

This ensures Neovim automatically reloads files changed externally (e.g., by Claude Code).

### Neo-tree File Explorer (lines 252-284)

- **Auto-refresh:** `use_libuv_file_watcher = true`
- **Follow current file:** `follow_current_file.enabled = true`
- **Show hidden files:** `hide_dotfiles = false`

Keybindings:
- `\` or `<leader>e` - Toggle file tree

## Troubleshooting

### Plugin issues
```vim
:checkhealth        " Diagnose all issues
:Lazy sync          " Re-sync plugins
:Mason              " Check LSP/formatter installation
:LspInfo            " Check LSP client status
```

### Diagnostics not working
1. Check LSP attached: `:LspInfo`
2. Check diagnostics config: `:lua vim.print(vim.diagnostic.config())`
3. Check custom module loaded: `:lua print(vim.inspect(require('custom.plugins.diagnostics-copy')))`

### Completion not working
1. Check blink.cmp loaded: `:Lazy`
2. Check sources: `:lua vim.print(require('blink.cmp').get_config())`

## Version Consistency

`lazy-lock.json` is **committed to git**. This ensures:
- Identical plugin versions across machines
- No surprises from plugin updates
- Reproducible environment

**To update plugins:**
1. `:Lazy update` - Update plugins
2. Test thoroughly
3. Commit updated `lazy-lock.json`

**To restore locked versions:**
```vim
:Lazy restore
```

## Leader Key

`<space>` (spacebar) - defined at line 90

All custom keybindings use `<leader>` prefix for organization.
