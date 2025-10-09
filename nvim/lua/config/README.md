# Neovim Core Configuration

This directory contains core Neovim configuration modules that don't depend on plugins. These settings are loaded immediately on startup, before any plugins.

## Files

| File | Lines | Purpose |
|------|-------|---------|
| `init.lua` | 4 | Loads config modules in order |
| `options.lua` | ~100 | Vim options and settings |
| `autocmds.lua` | ~30 | Autocommands for automation |
| `keymaps.lua` | ~100 | Core keybindings |

## File Descriptions

### init.lua

**Purpose:** Sequential loader for all config modules

**Content:**
```lua
require 'config.options'
require 'config.autocmds'
require 'config.keymaps'
```

**Loading order matters:**
- options.lua first (sets leader key, needed for keymaps)
- autocmds.lua second (sets up autocommands)
- keymaps.lua last (uses leader key from options)

### options.lua

**Purpose:** All Neovim options (`vim.opt`, `vim.g`, `vim.o`)

**Key sections:**

**1. Leader Key** (lines 7-8)
```lua
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
```
Must be set before plugins load!

**2. Provider Configuration** (lines 12-13)
```lua
vim.g.loaded_perl_provider = 0  -- Disable Perl provider
vim.g.loaded_ruby_provider = 0  -- Disable Ruby provider
```
Reduces startup time and removes health check warnings.

**3. Python Virtual Environment** (lines 16-26)
Automatically detects `.venv/bin/python` in parent directories.
Ensures LSP uses the correct Python interpreter per project.

**4. Display Options** (lines 28-52)
- Nerd Font support
- Line numbers (relative + absolute)
- Sign column (always show)
- Cursor line highlighting
- Color column at 120 characters
- Scroll offset (keep 10 lines visible)

**5. Editing Behavior** (lines 54-68)
- Tab width (2 spaces)
- Smart indentation
- Break indent
- Case-insensitive search (smart case)
- Decrease update time (250ms)

**6. File Handling** (lines 70-90)
- Undo file persistence
- Auto-read files when changed externally
- No swap files
- Split behavior (right, below)

**7. Clipboard** (lines 92-93)
System clipboard integration (works with `y`, `p`, `d`).

### autocmds.lua

**Purpose:** Event-driven automation

**Autocommands:**

**1. File Auto-Reload** (lines 4-17)
- Triggers: `FocusGained`, `BufEnter`, `CursorHold`, `CursorHoldI`
- Checks for external file changes
- Shows notification when file reloaded
- Critical for Claude Code workflows!

**2. CSV/TSV Filetype Detection** (lines 19-29)
- Triggers: `BufRead`, `BufNewFile`
- Patterns: `*.csv`, `*.tsv`
- Sets filetype to `csv`
- **Critical:** Fires FileType event for csvview.nvim lazy loading

**3. Highlight on Yank** (lines 31-35)
- Triggers: `TextYankPost`
- Briefly highlights yanked text
- Visual feedback for copy operations

**4. Auto-Create Directories** (lines 37-49)
- Triggers: `BufWritePre`
- Creates missing parent directories when saving
- Prevents "directory does not exist" errors

### keymaps.lua

**Purpose:** Core keybindings using `vim.keymap.set`

**Key sections:**

**1. Escape Alternatives** (lines 7-17)
- `<Esc>` in normal mode → Clear search highlighting
- `<Esc>` in terminal mode → Exit terminal mode

**2. Save Shortcuts** (lines 19-59)
- `<C-s>` in normal/insert/visual → Save file via controlsave.lua
- Integrates with TypeScript return type stripper
- Works across all modes

**3. Diagnostic Navigation** (lines 61-67)
- `[d` → Previous diagnostic
- `]d` → Next diagnostic
- `<leader>e` → Show diagnostic in floating window
- `<leader>q` → Open diagnostic quickfix list

**4. Custom Utilities** (lines 40-43)
- `<leader>ce` → Copy LSP errors to clipboard
- `<leader>cd` → Copy all diagnostics to clipboard
- For Claude Code workflows

**5. TypeScript Stripper Debug** (lines 82-104)
- `:TSStripPreview` → Show what would be removed
- `:TSStripTest` → Test tree-sitter parser
- `:TSStripNow` → Strip types immediately
- `:TSStripDebug` → Toggle debug logging

**6. Reload Config** (lines 76-80)
- `<leader>Rc` → Reload Neovim configuration
- Useful for testing config changes

## Common Modifications

### Change Leader Key

Edit `options.lua:7-8`:
```lua
vim.g.mapleader = ','  -- Change from space to comma
vim.g.maplocalleader = ','
```

**Important:** Must restart Neovim for this to take effect (reloading config won't work).

### Add New Keybinding

Edit `keymaps.lua`:
```lua
-- Add to appropriate section
vim.keymap.set('n', '<leader>x', function()
  -- Your code here
  print("Example keybinding")
end, { desc = 'Description for which-key' })
```

**Keybinding pattern:**
```lua
vim.keymap.set(
  mode,              -- 'n' (normal), 'i' (insert), 'v' (visual), etc.
  keys,              -- '<leader>x', '<C-s>', etc.
  action,            -- Function or command string
  opts               -- { desc = '...' } for which-key hints
)
```

### Add New Autocmd

Edit `autocmds.lua`:
```lua
-- Event-based autocmd
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Run before saving',
  pattern = '*.lua',
  callback = function()
    -- Lua code here
  end,
})

-- Or with Vim command
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Settings for markdown',
  pattern = 'markdown',
  command = 'setlocal spell',
})
```

### Add New Vim Option

Edit `options.lua`:
```lua
-- Add to appropriate section
vim.opt.new_option = value

-- Examples:
vim.opt.textwidth = 80           -- Wrap at 80 characters
vim.opt.conceallevel = 2         -- Conceal formatting in markdown
vim.g.netrw_banner = 0           -- Disable netrw banner
```

## Integration with Plugins

### Config Loads Before Plugins

**This works:**
```lua
-- options.lua
vim.g.mapleader = ' '  -- Set leader

-- Later, in plugins/editor.lua
keys = {
  { '<leader>ff', ... },  -- Uses space as leader
}
```

**This doesn't work:**
```lua
-- keymaps.lua
local telescope = require 'telescope.builtin'  -- ERROR: Plugin not loaded yet!
```

### Plugin Keybindings

**Core keybindings go in `keymaps.lua`:**
- Non-plugin functionality
- Custom utility integration
- General editing commands

**Plugin keybindings go in plugin specs:**
- Plugin-specific commands
- Features that require plugin loaded
- Lazy-loading triggers

## Related Documentation

- **[lua/README.md](../README.md)** - Lua directory overview
- **[lua/CLAUDE.md](../CLAUDE.md)** - AI guidance for Lua modules
- **[lua/plugins/README.md](../plugins/README.md)** - Plugin architecture
- **[nvim/CLAUDE.md](../../CLAUDE.md)** - Neovim architecture guide
- **[docs/KEYBINDINGS_NEOVIM.md](../../../docs/KEYBINDINGS_NEOVIM.md)** - Complete keybinding reference

## Quick Reference

### Reload Config
```vim
:source $MYVIMRC
" Or use keybinding:
<leader>Rc
```

### Check Current Settings
```vim
:set option?              " Check single option value
:verbose set option?      " See where option was last set
:lua print(vim.inspect(vim.opt.option:get()))  " Lua way
```

### List Autocommands
```vim
:autocmd                  " All autocommands
:autocmd Event            " Autocommands for specific event
:autocmd * pattern        " Autocommands for pattern
```

### List Keybindings
```vim
:nmap                     " Normal mode mappings
:imap                     " Insert mode mappings
:vmap                     " Visual mode mappings
:verbose nmap <leader>x   " See where mapping was defined
```
