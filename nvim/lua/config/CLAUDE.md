# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with core Neovim configuration modules.

## Directory Purpose

The `config/` directory contains **core Neovim settings that don't depend on plugins**. These modules are loaded immediately on startup, before lazy.nvim and any plugins.

## Loading Order and Dependencies

### Critical Loading Sequence

```
nvim/init.lua
  ↓
require 'config'  →  lua/config/init.lua
  ↓
require 'config.options'   (FIRST - sets leader key)
  ↓
require 'config.autocmds'  (SECOND - sets up automation)
  ↓
require 'config.keymaps'   (LAST - uses leader key)
```

**Why this order matters:**

1. **options.lua must load first** because it sets `vim.g.mapleader`
   - Plugins and keymaps reference `<leader>`
   - Leader key must be set before plugins load
   - Changing leader after plugins load won't affect plugin keybindings

2. **autocmds.lua loads second** for automation setup
   - No dependencies on keymaps
   - Autocmds can reference options

3. **keymaps.lua loads last** because it uses leader key
   - References `<leader>` set in options.lua
   - May require custom utilities from plugins/custom/

## File Responsibilities

### init.lua

**Purpose:** Sequential module loader

**Content:**
```lua
require 'config.options'
require 'config.autocmds'
require 'config.keymaps'
```

**When to modify:**
- Adding new config module (rare)
- Changing load order (very rare, carefully consider dependencies)

**Pattern:**
```lua
-- Add new module
require 'config.new_module'
```

**Important:** Don't add conditional loading here. If a module is optional, handle the condition inside the module itself.

### options.lua

**Purpose:** All `vim.opt`, `vim.g`, `vim.o` settings

**Architecture:**

**Section 1: Critical Pre-Plugin Settings**
```lua
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
```
**Why:** Must be set before plugins load. Plugins cache the leader key value during initialization.

**Section 2: Provider Disabling**
```lua
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
```
**Why:** Reduces startup time, removes health check warnings. No plugins in this config use Perl/Ruby remote plugin API.

**Section 3: Python Virtual Environment Detection**
```lua
local function set_project_python()
  -- Find .venv/bin/python in parent dirs
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged' }, {
  callback = set_project_python,
})
```
**Why:** LSP servers (pyright) need to use the project's Python interpreter, not system Python. This auto-detects `.venv/` in parent directories.

**Section 4-7: Display, Editing, File Handling, Clipboard**
Standard vim options grouped by function.

**When to modify:**

**Adding display option:**
```lua
-- Add to display section (around line 30-50)
vim.opt.colorcolumn = '80'  -- Highlight column 80
```

**Adding editing behavior:**
```lua
-- Add to editing section (around line 54-68)
vim.opt.textwidth = 80      -- Wrap at 80 characters
```

**Adding file handling:**
```lua
-- Add to file handling section (around line 70-90)
vim.opt.backup = false      -- Disable backup files
```

**Pattern for conditional options:**
```lua
-- Platform-specific
if vim.fn.has('mac') == 1 then
  vim.opt.option = value
end

-- Feature detection
if vim.fn.exists('+termguicolors') == 1 then
  vim.opt.termguicolors = true
end
```

### autocmds.lua

**Purpose:** Event-driven automation via `vim.api.nvim_create_autocmd`

**Current autocmds:**

**1. File Auto-Reload (lines 4-17)**
```lua
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  command = 'checktime',
})

vim.api.nvim_create_autocmd('FileChangedShellPost', {
  command = 'echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None',
})
```

**Why critical:** Claude Code modifies files externally. Without this, Neovim won't reload changes.

**Events:**
- `FocusGained` - User returns to Neovim
- `BufEnter` - User switches buffers
- `CursorHold` - Cursor idle for `updatetime` ms (250ms)
- `CursorHoldI` - Cursor idle in insert mode

**2. CSV/TSV Filetype Detection (lines 19-29)**
```lua
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  desc = 'Set filetype for CSV/TSV files',
  pattern = { '*.csv', '*.tsv' },
  callback = function()
    vim.bo.filetype = 'csv'
    vim.cmd 'doautocmd FileType csv'  -- CRITICAL: Triggers lazy loading
  end,
})
```

**Why critical:** Neovim doesn't auto-detect CSV filetype. Without this, csvview.nvim won't lazy-load.

**The `doautocmd FileType csv` line is essential:**
- Setting `vim.bo.filetype = 'csv'` doesn't fire FileType event
- Lazy.nvim listens for FileType events to load plugins
- Without `doautocmd`, plugin won't load even though filetype is set

**3. Highlight on Yank (lines 31-35)**
```lua
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  callback = function()
    vim.highlight.on_yank()
  end,
})
```

**Why useful:** Visual feedback for copy operations. Users know what they yanked.

**4. Auto-Create Directories (lines 37-49)**
```lua
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Automatically create parent directories when saving',
  callback = function(event)
    -- Create missing directories
  end,
})
```

**Why useful:** Prevents `:w` failure when parent directories don't exist.

**When to modify:**

**Adding file type detection:**
```lua
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  desc = 'Set filetype for .conf files',
  pattern = '*.conf',
  callback = function()
    vim.bo.filetype = 'conf'
    vim.cmd 'doautocmd FileType conf'  -- Trigger lazy loading
  end,
})
```

**Adding buffer-local settings:**
```lua
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Markdown-specific settings',
  pattern = 'markdown',
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 80
  end,
})
```

**Adding save automation:**
```lua
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Auto-format on save',
  pattern = '*.lua',
  callback = function()
    vim.lsp.buf.format()
  end,
})
```

**Pattern:** Use `callback` for Lua code, `command` for simple Vim commands.

```lua
-- Lua callback (complex logic)
callback = function(event)
  if condition then
    -- Lua code
  end
end,

-- Vim command (simple)
command = 'setlocal spell',
```

### keymaps.lua

**Purpose:** Core keybindings via `vim.keymap.set` and user commands

**Categories:**

**1. Escape Alternatives (lines 7-17)**
- Clear search highlighting in normal mode
- Exit terminal mode

**2. Save Shortcuts (lines 19-59)**
- `<C-s>` in all modes
- Integrates with controlsave.lua custom utility
- Integrates with TypeScript return type stripper

**3. Diagnostic Navigation (lines 61-67)**
- LSP diagnostic jumping and viewing

**4. Custom Utility Keybindings (lines 40-43, 82-104)**
- Diagnostic copy for Claude Code
- TypeScript stripper debug commands

**5. Reload Config (lines 76-80)**
- Quick config reload for testing

**When to modify:**

**Adding core keybinding:**
```lua
-- Non-plugin functionality
vim.keymap.set('n', '<leader>x', function()
  print('Example')
end, { desc = 'Example keybinding' })
```

**Adding keybinding for custom utility:**
```lua
-- Require custom utility
local myutil = require 'plugins.custom.myutil'

-- Create keybinding
vim.keymap.set('n', '<leader>x', myutil.function_name, { desc = 'Description' })
```

**Adding user command:**
```lua
vim.api.nvim_create_user_command('CommandName', function(opts)
  -- Implementation
  -- opts.args - command arguments
  -- opts.bang - ! was used
end, {
  desc = 'Description for :help',
  nargs = '*',  -- Optional: accept arguments
  bang = true,  -- Optional: accept !
})
```

**Pattern for multi-mode keybindings:**
```lua
-- Same keybinding in multiple modes
vim.keymap.set({ 'n', 'v' }, '<leader>x', function()
  -- Works in normal and visual mode
end, { desc = 'Description' })

-- Different behavior per mode
vim.keymap.set('n', '<C-s>', function()
  -- Normal mode: just save
  require('plugins.custom.controlsave').save()
end)

vim.keymap.set('v', '<C-s>', function()
  -- Visual mode: exit visual first, then save
  vim.cmd 'normal! <Esc>'
  require('plugins.custom.controlsave').save()
end)
```

## Common Modification Patterns

### Adding a Keybinding

**Decision tree:**

1. **Does it require a plugin?**
   - Yes → Add to plugin spec in `plugins/*.lua`
   - No → Continue to step 2

2. **Does it use a custom utility?**
   - Yes → Add to `keymaps.lua` with `require 'plugins.custom.utility'`
   - No → Continue to step 3

3. **Is it core editing functionality?**
   - Yes → Add to `keymaps.lua`
   - No → Consider if it should be a plugin instead

**Example: Core keybinding**
```lua
-- keymaps.lua
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Save file' })
```

**Example: Custom utility keybinding**
```lua
-- keymaps.lua
local diagnostics = require 'plugins.custom.diagnostics-copy'
vim.keymap.set('n', '<leader>ce', diagnostics.copy_errors_only, { desc = 'Copy Errors' })
```

**Example: Plugin keybinding (WRONG place)**
```lua
-- keymaps.lua - DON'T DO THIS
vim.keymap.set('n', '<leader>gg', ':LazyGit<CR>')  -- Plugin might not be loaded!
```

**Example: Plugin keybinding (CORRECT place)**
```lua
-- plugins/git.lua
{
  'kdheepak/lazygit.nvim',
  cmd = 'LazyGit',
  keys = {
    { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
  },
}
```

### Adding an Autocmd

**Decision tree:**

1. **Is it file type detection?**
   - Yes → Add to `autocmds.lua` with `doautocmd FileType` pattern

2. **Is it buffer-local settings for a file type?**
   - Yes → Add to `autocmds.lua` with `FileType` event

3. **Is it save automation?**
   - Yes → Consider if it belongs in conform.nvim config instead
   - If LSP formatting → Use conform.nvim in `plugins/lsp.lua`
   - If custom processing → Add to `autocmds.lua` with `BufWritePre`

4. **Is it file change detection?**
   - Already handled by auto-reload autocmd

**Example: File type detection**
```lua
-- autocmds.lua
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  desc = 'Set filetype for .env files',
  pattern = { '.env*', '*.env' },
  callback = function()
    vim.bo.filetype = 'sh'
    vim.cmd 'doautocmd FileType sh'
  end,
})
```

**Example: File type settings**
```lua
-- autocmds.lua
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Python-specific settings',
  pattern = 'python',
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})
```

### Adding a Vim Option

**Decision tree:**

1. **Must it be set before plugins load?**
   - Leader key → Yes, add to top of `options.lua`
   - Provider disabling → Yes, add to provider section
   - Everything else → No, add to appropriate section

2. **Is it display-related?**
   - Yes → Add to display section (~line 28-52)

3. **Is it editing behavior?**
   - Yes → Add to editing section (~line 54-68)

4. **Is it file handling?**
   - Yes → Add to file handling section (~line 70-90)

5. **Is it clipboard?**
   - Yes → Add to clipboard section (~line 92-93)

**Example: Display option**
```lua
-- options.lua - Display section
vim.opt.conceallevel = 2  -- Hide markdown formatting characters
```

**Example: Editing option**
```lua
-- options.lua - Editing section
vim.opt.textwidth = 100  -- Wrap at 100 characters
```

## Integration Points

### Config → Custom Utilities

**Config can require custom utilities:**

```lua
-- keymaps.lua
local myutil = require 'plugins.custom.myutil'
vim.keymap.set('n', '<leader>x', myutil.function)
```

**This works because:**
- Custom utilities are pure Lua modules
- They don't depend on plugins
- They're just functions to call

### Config → Plugins (NOT ALLOWED)

**Config CANNOT require plugins:**

```lua
-- keymaps.lua - WILL FAIL
local telescope = require 'telescope.builtin'  -- Plugin not loaded yet!
vim.keymap.set('n', '<leader>ff', telescope.find_files)
```

**Why this fails:**
- Config loads before lazy.nvim
- Plugins aren't installed/loaded yet
- `require 'telescope.builtin'` will error

**Solution:** Add keybindings to plugin specs instead:
```lua
-- plugins/editor.lua
{
  'nvim-telescope/telescope.nvim',
  keys = {
    { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find Files' },
  },
}
```

### Plugins → Config Settings

**Plugins CAN use config settings:**

```lua
-- plugins/editor.lua
config = function()
  -- Leader key already set in config/options.lua
  require('telescope').setup {
    -- Config here
  }
end,
```

**This works because:**
- Plugins load after config
- Config settings are global (`vim.g`, `vim.opt`)
- Available to all subsequent code

## Troubleshooting Patterns

### Leader Key Not Working

**Symptom:** `<leader>x` does nothing, even after setting leader

**Causes:**
1. Leader set after plugins loaded
2. Leader set in wrong file
3. Config not reloaded properly

**Fix:**
1. Verify leader is in `config/options.lua:7-8`
2. Restart Neovim (`:source $MYVIMRC` won't fix plugins that already loaded)
3. Check leader value: `:lua print(vim.g.mapleader)`

### Autocmd Not Firing

**Symptom:** Autocmd callback never runs

**Diagnostic:**
```vim
:autocmd Event              " List all autocmds for Event
:au Event * pattern         " Check pattern matching
:set filetype?              " Verify filetype is what you expect
```

**Common causes:**
1. Wrong event name
2. Pattern doesn't match
3. Event doesn't fire (e.g., FileType on CSV without `doautocmd`)

### Keybinding Not Working

**Symptom:** Keypress does nothing

**Diagnostic:**
```vim
:verbose map <leader>x      " See if keybinding exists and where it's defined
:nmap <leader>x             " Check normal mode specifically
:WhichKey <leader>          " See all leader keybindings (if which-key installed)
```

**Common causes:**
1. Plugin not loaded (move keybinding to plugin spec)
2. Wrong mode ('n' vs 'v' vs 'i')
3. Keybinding overwritten by plugin

### Custom Utility Not Found

**Symptom:** `module 'plugins.custom.myutil' not found`

**Diagnostic:**
```vim
:lua print(package.path)                              " Check Lua path
:lua print(vim.inspect(require('plugins.custom.myutil')))  " Try requiring
:e lua/plugins/custom/myutil.lua                      " Verify file exists
:luafile %                                            " Check for syntax errors
```

**Common causes:**
1. Wrong require path
2. File doesn't exist
3. Syntax error in module

## For Future Claude Code Instances

**When modifying config/ files:**

1. **Respect loading order:**
   - Leader key must be in options.lua
   - Don't require plugins in config/
   - Can require custom utilities in keymaps.lua

2. **Add to correct file:**
   - Vim options → `options.lua`
   - Autocommands → `autocmds.lua`
   - Keybindings → `keymaps.lua`
   - User commands → `keymaps.lua`

3. **Follow section organization:**
   - Group related options together
   - Add comments for complex logic
   - Use descriptive names for autocmd callbacks

4. **File type detection pattern:**
   ```lua
   vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
     pattern = '*.ext',
     callback = function()
       vim.bo.filetype = 'type'
       vim.cmd 'doautocmd FileType type'  -- Don't forget this!
     end,
   })
   ```

5. **Update documentation:**
   - Add keybinding to `docs/KEYBINDINGS_NEOVIM.md`
   - Update this CLAUDE.md if architectural
   - Update `config/README.md` if user-facing

6. **Test changes:**
   ```vim
   :source $MYVIMRC          " Reload config
   :lua print('test')        " Verify Lua works
   :messages                 " Check for errors
   ```
