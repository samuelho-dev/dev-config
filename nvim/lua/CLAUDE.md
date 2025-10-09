# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with Neovim Lua configuration modules.

## Directory Purpose

The `lua/` directory contains all Lua-based Neovim configuration, split into **config/** (core settings) and **plugins/** (plugin specifications and custom utilities).

## Architecture Philosophy

### Separation of Concerns

**config/ - Core Neovim Settings**
- No plugin dependencies
- Loaded immediately on startup
- Essential settings (leader key, options, autocmds, keymaps)
- Changes don't require plugin reinstallation

**plugins/ - Plugin Management**
- Lazy-loaded plugin specifications
- Plugin-specific configurations
- Custom utility modules in `plugins/custom/`
- Managed by lazy.nvim plugin manager

### Why This Structure?

**Before (Kickstart.nvim monolithic):**
- Single 1823-line `init.lua` file
- Hard to find specific settings
- Custom plugins mixed with core config
- Difficult to modify or disable features

**After (Modular architecture):**
- 81-line `init.lua` entry point
- Clear separation: config/ vs plugins/
- Easy to locate and modify features
- 94% reduction in main file complexity

## Module Loading Flow

```
1. nvim/init.lua (entry point)
   ↓
2. require 'config' → loads lua/config/init.lua
   ↓
3. lua/config/init.lua sequentially loads:
   - require 'config.options'   (leader key, vim options)
   - require 'config.autocmds'  (autocommands)
   - require 'config.keymaps'   (core keybindings)
   ↓
4. lazy.nvim bootstrap (auto-installs plugin manager)
   ↓
5. require('lazy').setup({ imports }) → loads plugin specs
   - { import = 'plugins.editor' }
   - { import = 'plugins.lsp' }
   - { import = 'plugins.completion' }
   - etc.
   ↓
6. Plugins lazy-load based on events, commands, file types
```

## Require Path Patterns

### Config Modules

```lua
-- Load all config
require 'config'

-- Load specific config module
require 'config.options'
require 'config.autocmds'
require 'config.keymaps'
```

**Path resolution:**
- `require 'config'` → `lua/config/init.lua` (directory init)
- `require 'config.options'` → `lua/config/options.lua`

### Plugin Specifications

```lua
-- In init.lua, lazy.nvim setup
require('lazy').setup({
  { import = 'plugins.editor' },    -- lua/plugins/editor.lua
  { import = 'plugins.lsp' },       -- lua/plugins/lsp.lua
  { import = 'plugins.completion' }, -- lua/plugins/completion.lua
  -- etc.
})
```

**Important:** Plugin files return a table, they're not required directly.

### Custom Utilities

```lua
-- In keymaps or plugin configs
local diagnostics = require 'plugins.custom.diagnostics-copy'
local controlsave = require 'plugins.custom.controlsave'
local stripper = require 'plugins.custom.typescript-return-stripper'
```

**Path resolution:**
- `require 'plugins.custom.diagnostics-copy'` → `lua/plugins/custom/diagnostics-copy.lua`

## File Responsibilities

### config/init.lua

**Purpose:** Sequential loader for config modules

**Structure:**
```lua
require 'config.options'
require 'config.autocmds'
require 'config.keymaps'
```

**When to modify:**
- Adding new config module (rare)
- Changing load order (very rare)

### config/options.lua

**Purpose:** All vim.o, vim.opt, vim.g settings

**Categories:**
1. Leader key configuration (`vim.g.mapleader`)
2. Provider disabling (Perl, Ruby)
3. Python virtual environment detection
4. Display options (numbers, signs, cursor)
5. Editing behavior (tabs, indentation, case)
6. Search settings (ignore case, incremental)
7. File handling (autoread, undo, backup)
8. Clipboard integration

**When to modify:**
- Changing leader key
- Adding new display options
- Modifying editing behavior
- Adding new autocommands for file detection

**Pattern:**
```lua
-- Set option
vim.opt.option_name = value

-- Set global
vim.g.variable_name = value

-- Conditional setting
if condition then
  vim.opt.option = value
end
```

### config/autocmds.lua

**Purpose:** All vim.api.nvim_create_autocmd definitions

**Current autocmds:**
1. File auto-reload (`FocusGained`, `BufEnter`, `CursorHold`)
2. File changed notification (`FileChangedShellPost`)
3. CSV/TSV filetype detection
4. Highlight on yank
5. Auto-create directories on save

**When to modify:**
- Adding file type detection
- Adding auto-formatting on save (prefer conform.nvim)
- Adding buffer-local settings for specific filetypes
- Adding event-triggered actions

**Pattern:**
```lua
vim.api.nvim_create_autocmd({ 'Event1', 'Event2' }, {
  desc = 'Description for :autocmd list',
  pattern = '*.ext',  -- or callback for complex logic
  command = 'VimCommand',
  -- OR
  callback = function()
    -- Lua code
  end,
})
```

### config/keymaps.lua

**Purpose:** Core keybindings using vim.keymap.set

**Categories:**
1. Escape remaps (clear search, exit terminal)
2. Save shortcuts (`<C-s>`)
3. Diagnostic navigation (`[d`, `]d`)
4. Diagnostic quickfix
5. Window navigation (`<C-h/j/k/l>`)
6. Custom utility bindings (diagnostic copy, TypeScript stripper)
7. Reload config command

**When to modify:**
- Adding core keybindings (non-plugin)
- Adding keybindings for custom utilities
- Changing existing keybindings
- Adding user commands

**Pattern:**
```lua
-- Basic keybinding
vim.keymap.set('n', '<leader>x', ':Command<CR>', { desc = 'Description' })

-- Keybinding with Lua function
vim.keymap.set('n', '<leader>x', function()
  -- Lua code
end, { desc = 'Description' })

-- Multi-mode keybinding
vim.keymap.set({ 'n', 'v' }, '<leader>x', function()
  -- Lua code
end, { desc = 'Description' })

-- User command
vim.api.nvim_create_user_command('CommandName', function()
  -- Lua code
end, { desc = 'Description' })
```

### plugins/*.lua Files

**Purpose:** Return table of plugin specifications for lazy.nvim

**Structure:**
```lua
-- File: lua/plugins/category.lua
return {
  -- Plugin specification 1
  {
    'author/plugin-name',
    event = 'VimEnter',
    dependencies = { 'dependency/plugin' },
    config = function()
      require('plugin').setup {
        option = value,
      }
    end,
  },

  -- Plugin specification 2
  {
    'author/another-plugin',
    cmd = 'PluginCommand',
    keys = {
      { '<leader>x', '<cmd>PluginCommand<cr>', desc = 'Description' },
    },
  },
}
```

**When to modify:**
- Adding new plugin
- Changing plugin configuration
- Updating lazy loading triggers
- Changing keybindings

**Lazy loading triggers:**
- `event = 'VimEnter'` - Load after Neovim starts
- `event = 'BufRead'` - Load when reading a buffer
- `cmd = 'Command'` - Load when command is run
- `ft = 'filetype'` - Load for specific file type
- `keys = { ... }` - Load when keybinding is pressed
- `dependencies = { ... }` - Load when dependency loads

### plugins/custom/*.lua Files

**Purpose:** Custom utility modules (not plugin specifications)

**Structure:**
```lua
local M = {}

-- Configuration (optional)
M.config = {
  option = default_value,
}

-- Functions
function M.function_name()
  -- Implementation
end

-- Setup function (optional)
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

return M
```

**When to create:**
- Custom functionality not provided by plugins
- Utilities for keybindings
- Integration helpers (diagnostics-copy for Claude Code)
- Workflow automation (controlsave, TypeScript stripper)

**Integration pattern:**
```lua
-- In config/keymaps.lua
local myutil = require 'plugins.custom.myutil'
vim.keymap.set('n', '<leader>x', myutil.function_name, { desc = 'Description' })
```

## Common Modification Patterns

### Adding a New Keybinding

**For core functionality (no plugins):**

Edit `config/keymaps.lua`:
```lua
-- Add to appropriate section
vim.keymap.set('n', '<leader>new', function()
  -- Implementation
end, { desc = '[N]ew [E]xample [W]ork' })
```

**For plugin functionality:**

Edit the plugin's config function in `plugins/*.lua`:
```lua
{
  'author/plugin',
  keys = {
    { '<leader>new', '<cmd>PluginCommand<cr>', desc = 'Description' },
  },
  config = function()
    require('plugin').setup {
      mappings = {
        new_action = '<leader>new',
      },
    }
  end,
}
```

**For custom utility:**

Create utility in `plugins/custom/newutil.lua`, then add keybinding in `config/keymaps.lua`:
```lua
local newutil = require 'plugins.custom.newutil'
vim.keymap.set('n', '<leader>new', newutil.action, { desc = 'Description' })
```

### Adding a New Plugin

**1. Choose category file:**
- Editor tools → `plugins/editor.lua`
- LSP/formatters → `plugins/lsp.lua`
- Completion → `plugins/completion.lua`
- AI tools → `plugins/ai.lua`
- Git tools → `plugins/git.lua`
- Markdown → `plugins/markdown.lua`
- UI enhancements → `plugins/ui.lua`
- Syntax → `plugins/treesitter.lua`
- Utilities → `plugins/tools.lua`

**2. Add plugin specification:**
```lua
{
  'author/plugin-name',
  event = 'VimEnter',  -- Choose appropriate lazy loading trigger
  dependencies = {
    'dependency/plugin',
  },
  config = function()
    require('plugin-name').setup {
      -- Configuration
    }
  end,
},
```

**3. Consider lazy loading:**
- Load on event if general-purpose
- Load on command if infrequently used
- Load on filetype if language-specific
- Load on keys if keybinding-driven

**4. Test:**
```vim
:Lazy reload category
```

### Adding a New Configuration Option

**For vim options:**

Edit `config/options.lua`:
```lua
-- Add to appropriate section
vim.opt.new_option = value
```

**For autocmd:**

Edit `config/autocmds.lua`:
```lua
vim.api.nvim_create_autocmd('Event', {
  desc = 'Description',
  pattern = '*',
  callback = function()
    -- Implementation
  end,
})
```

### Creating a New Custom Utility

**1. Create file** `plugins/custom/newutil.lua`:
```lua
local M = {}

M.config = {
  enabled = true,
}

function M.do_something()
  if not M.config.enabled then return end
  -- Implementation
end

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

return M
```

**2. Add keybinding** in `config/keymaps.lua`:
```lua
local newutil = require 'plugins.custom.newutil'
vim.keymap.set('n', '<leader>x', newutil.do_something, { desc = 'Description' })
```

**3. Optional: Add user command**:
```lua
vim.api.nvim_create_user_command('NewUtilCommand', function()
  newutil.do_something()
end, { desc = 'Description' })
```

## Plugin Configuration Patterns

### Basic Setup

```lua
{
  'author/plugin',
  config = function()
    require('plugin').setup {
      option = value,
    }
  end,
}
```

### Conditional Loading

```lua
{
  'author/plugin',
  cond = function()
    return vim.env.API_KEY ~= nil
  end,
  config = function()
    -- Only loaded if API_KEY is set
  end,
}
```

### Dynamic Configuration

```lua
{
  'author/plugin',
  opts = function()
    local config = {}

    if condition then
      config.feature = true
    end

    return config
  end,
}
```

### LSP Integration

```lua
{
  'neovim/nvim-lspconfig',
  config = function()
    -- Keybindings on LSP attach
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('grd', require('telescope.builtin').lsp_definitions, 'Go to definition')
        -- etc.
      end,
    })
  end,
}
```

## Troubleshooting Patterns

### Module Not Found

**Symptom:** `module 'config.options' not found`

**Causes:**
1. Wrong require path
2. File doesn't exist
3. Syntax error in module

**Fix:**
```lua
-- Check file exists
:e lua/config/options.lua

-- Verify syntax
:luafile %

-- Check require path
:lua print(vim.inspect(package.path))
```

### Plugin Not Loading

**Symptom:** Plugin features not available

**Diagnostic:**
```vim
:Lazy
" Check if plugin is loaded

:Lazy reload plugin-name
" Force reload

:checkhealth lazy
" Check for issues
```

**Common causes:**
1. Wrong lazy loading trigger
2. Missing dependency
3. Condition not met (cond = function())
4. Configuration error

### Keybinding Not Working

**Symptom:** `<leader>x` does nothing

**Diagnostic:**
```vim
:verbose map <leader>x
" Shows what the keybinding does

:WhichKey <leader>
" Shows all leader keybindings (if which-key installed)
```

**Common causes:**
1. Plugin not loaded yet (use `keys` in plugin spec)
2. Keybinding overwritten by another plugin
3. Wrong mode ('n' vs 'v' vs 'i')

## Integration Points

### Config → Plugins

**Config modules can't depend on plugins:**
```lua
-- BAD: config/keymaps.lua
local telescope = require 'telescope.builtin'  -- Plugin not loaded yet!
vim.keymap.set('n', '<leader>ff', telescope.find_files)
```

**Plugins can use config settings:**
```lua
-- GOOD: plugins/editor.lua
config = function()
  require('telescope').setup {
    defaults = {
      -- Uses leader key set in config/options.lua
    }
  }
end,
```

### Custom Utilities → Config

**Custom utilities can be required in config/keymaps.lua:**
```lua
-- config/keymaps.lua
local diagnostics = require 'plugins.custom.diagnostics-copy'
vim.keymap.set('n', '<leader>ce', diagnostics.copy_errors_only)
```

### Custom Utilities → Plugins

**Custom utilities can be used in plugin configs:**
```lua
-- plugins/lsp.lua
config = function()
  local stripper = require 'plugins.custom.typescript-return-stripper'

  -- Use in autocmd
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.ts',
    callback = function()
      stripper.on_save(0)
    end,
  })
end,
```

## For Future Claude Code Instances

**When modifying Lua configuration:**

1. **Identify module type:**
   - Core setting → Edit `config/*.lua`
   - Plugin addition → Edit `plugins/*.lua`
   - Custom utility → Create/edit `plugins/custom/*.lua`

2. **Use correct require pattern:**
   - Config modules: `require 'config.modulename'`
   - Plugin imports: `{ import = 'plugins.category' }`
   - Custom utilities: `require 'plugins.custom.utilname'`

3. **Respect loading order:**
   - Config loads before plugins
   - Don't require plugins in config/
   - Custom utilities can be required anywhere

4. **Follow lazy loading patterns:**
   - `event` for general-purpose plugins
   - `cmd` for infrequent commands
   - `ft` for file type-specific
   - `keys` for keybinding-triggered

5. **Document changes:**
   - Add keybinding to `docs/KEYBINDINGS_NEOVIM.md`
   - Update `nvim/README.md` for user-facing features
   - Update this file for architectural changes

6. **Test changes:**
   ```vim
   :source $MYVIMRC          " Reload config
   :Lazy reload <plugin>     " Reload specific plugin
   :checkhealth              " Verify health
   ```
