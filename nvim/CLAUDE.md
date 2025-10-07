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
