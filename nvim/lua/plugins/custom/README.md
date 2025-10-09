# Custom Utility Modules

This directory contains custom Lua modules that provide functionality for keybindings and plugins. These are NOT plugin specifications - they're utility modules that are required directly.

## Modules

| File | Lines | Purpose |
|------|-------|---------|
| `diagnostics-copy.lua` | ~70 | Copy LSP diagnostics to clipboard |
| `controlsave.lua` | ~110 | Ctrl+S save functionality |
| `typescript-return-stripper.lua` | ~300 | Auto-remove TypeScript return types |
| `mermaid.lua` | ~170 | Render Mermaid diagrams inline |

## Module Descriptions

### diagnostics-copy.lua

**Purpose:** Copy LSP errors/diagnostics to clipboard for Claude Code workflows

**Functions:**
- `copy_errors_only()` - Copy only ERROR severity diagnostics
- `copy_all_diagnostics()` - Copy all diagnostics grouped by severity

**Keybindings:**
- `<leader>ce` - Copy Errors
- `<leader>cd` - Copy all Diagnostics

**Output format:**
```
=== ERRORS ===

Line 42: 'foo' is not defined
Line 58: Type 'string' is not assignable to type 'number'

=== WARNINGS ===

Line 12: Unused variable 'bar'
```

**Usage:**
```lua
local diagnostics = require 'plugins.custom.diagnostics-copy'
diagnostics.copy_errors_only()
```

### controlsave.lua

**Purpose:** Quick save with Ctrl+S, integrates with TypeScript stripper

**Functions:**
- `save()` - Save current buffer with validation
- `save_all()` - Save all modified buffers
- `format_and_save()` - Explicitly format then save

**Keybindings:**
- `<C-s>` - Save file (normal, insert, visual mode)

**Features:**
- Validates buffer is modifiable
- Checks for special buffer types
- Integrates with TypeScript return type stripper
- Exits insert/visual mode before saving

**Usage:**
```lua
local controlsave = require 'plugins.custom.controlsave'
controlsave.save()
```

### typescript-return-stripper.lua

**Purpose:** Automatically remove TypeScript function return type annotations on save

**Functions:**
- `find_return_types(bufnr)` - Find annotations via tree-sitter
- `strip_return_types(bufnr)` - Remove annotations from buffer
- `on_save(bufnr)` - Hook called before save
- `preview_changes(bufnr)` - Preview what would be removed
- `test_query(bufnr)` - Test tree-sitter parser availability

**Debug Commands:**
- `:TSStripPreview` - Show what would be removed
- `:TSStripTest` - Test parser availability
- `:TSStripNow` - Strip immediately without saving
- `:TSStripDebug` - Toggle debug logging

**Supported file types:**
- `typescript` (.ts)
- `typescriptreact` (.tsx)
- `javascript` (.js)
- `javascriptreact` (.jsx)

**What gets removed:**
```typescript
// Before save:
function foo(): string { return 'test'; }
const bar = (): number => 42;

// After save:
function foo() { return 'test'; }
const bar = () => 42;
```

**Configuration:**
```lua
local stripper = require 'plugins.custom.typescript-return-stripper'
stripper.setup({
  enabled = true,
  filetypes = { 'typescript', 'typescriptreact' },
  notify_on_strip = true,  -- Show notification
  debug = true,  -- Enable debug logging
})
```

### mermaid.lua

**Purpose:** Render Mermaid diagrams inline in markdown files

**Integration:** Custom handler for render-markdown.nvim

**Requirements:**
- `@mermaid-js/mermaid-cli` (`mmdc` command)
- ImageMagick
- `image.nvim` plugin

**How it works:**
1. Detects Mermaid code blocks via treesitter
2. Generates PNG images using `mmdc` CLI
3. Caches images in `~/.cache/nvim/mermaid-diagrams/`
4. Renders inline using image.nvim
5. Updates only when content changes

**Cache management:**
- Hash-based caching (only re-renders on changes)
- Per-buffer state tracking
- Automatic cleanup on buffer wipeout

## Creating a New Custom Utility

### 1. Create Module File

Create `myutil.lua` in this directory:

```lua
local M = {}

-- Configuration (optional)
M.config = {
  enabled = true,
  option = 'default',
}

-- Main function
function M.do_something()
  if not M.config.enabled then
    return
  end

  -- Implementation
  vim.notify('Example utility', vim.log.levels.INFO)
end

-- Setup function (optional)
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

return M
```

### 2. Add Keybinding

Edit `lua/config/keymaps.lua`:

```lua
-- Require the utility
local myutil = require 'plugins.custom.myutil'

-- Create keybinding
vim.keymap.set('n', '<leader>x', myutil.do_something, {
  desc = 'Description for which-key'
})
```

### 3. Add User Command (Optional)

Edit `lua/config/keymaps.lua`:

```lua
vim.api.nvim_create_user_command('MyUtil', function()
  require('plugins.custom.myutil').do_something()
end, { desc = 'Run my utility' })
```

## Module Patterns

### Basic Module Structure

```lua
local M = {}

function M.function_name()
  -- Implementation
end

return M
```

### Module with Configuration

```lua
local M = {}

M.config = {
  option1 = default1,
  option2 = default2,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M
```

### Module with Private Functions

```lua
local M = {}

-- Private function (not exported)
local function helper()
  -- Internal implementation
end

-- Public function (exported)
function M.public_function()
  helper()  -- Call private function
end

return M
```

### Module with Conditional Features

```lua
local M = {}

M.config = {
  enabled = true,
}

function M.feature()
  if not M.config.enabled then
    vim.notify('Feature disabled', vim.log.levels.WARN)
    return
  end

  -- Implementation
end

return M
```

## Integration Patterns

### Used in Keymaps

```lua
-- lua/config/keymaps.lua
local myutil = require 'plugins.custom.myutil'
vim.keymap.set('n', '<leader>x', myutil.function_name)
```

### Used in Plugin Config

```lua
-- lua/plugins/editor.lua
{
  'author/plugin',
  config = function()
    local myutil = require 'plugins.custom.myutil'

    require('plugin').setup {
      on_event = myutil.handler,
    }
  end,
}
```

### Used in Autocmd

```lua
-- lua/config/autocmds.lua
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    require('plugins.custom.myutil').on_save()
  end,
})
```

## Best Practices

### Naming Conventions

- **Modules:** `descriptive-name.lua` (kebab-case)
- **Functions:** `function_name()` (snake_case)
- **Config:** `M.config` table
- **Setup:** `M.setup(opts)` function

### Error Handling

```lua
function M.safe_function()
  local ok, result = pcall(function()
    -- Code that might error
  end)

  if not ok then
    vim.notify('Error: ' .. result, vim.log.levels.ERROR)
    return nil
  end

  return result
end
```

### User Notifications

```lua
-- Info
vim.notify('Success!', vim.log.levels.INFO)

-- Warning
vim.notify('Warning', vim.log.levels.WARN)

-- Error
vim.notify('Error', vim.log.levels.ERROR)
```

### Configuration Validation

```lua
function M.setup(opts)
  opts = opts or {}

  -- Validate options
  if opts.required_option == nil then
    vim.notify('Missing required option', vim.log.levels.ERROR)
    return
  end

  -- Merge with defaults
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end
```

## Related Documentation

- **[lua/CLAUDE.md](../CLAUDE.md)** - Lua module architecture
- **[lua/config/README.md](../../config/README.md)** - Core configuration
- **[docs/KEYBINDINGS_NEOVIM.md](../../../../docs/KEYBINDINGS_NEOVIM.md)** - Keybinding reference
- **[nvim/CLAUDE.md](../../../CLAUDE.md)** - Neovim architecture

## Testing Utilities

### Test in Neovim

```vim
:lua require('plugins.custom.myutil').function_name()
```

### Check Module Loads

```vim
:lua print(vim.inspect(require('plugins.custom.myutil')))
```

### Reload Module

```vim
:lua package.loaded['plugins.custom.myutil'] = nil
:lua require('plugins.custom.myutil')
```

### Debug Print

```lua
function M.debug()
  print(vim.inspect(M.config))
end
```
