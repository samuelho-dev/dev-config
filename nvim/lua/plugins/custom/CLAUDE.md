# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with custom utility modules.

## Directory Purpose

The `custom/` directory contains **custom Lua utility modules** that are NOT plugin specifications. These modules provide functionality for keybindings, autocmds, and plugin integrations.

## Module Architecture

### Not Plugin Specs

**Important distinction:**
```lua
-- plugins/editor.lua - Plugin specification
return {
  {
    'author/plugin-name',  -- lazy.nvim loads this
    config = function() ... end,
  },
}

-- plugins/custom/myutil.lua - Utility module
local M = {}
function M.do_something() ... end
return M  -- Directly required by code
```

**Custom modules are required directly:**
```lua
local myutil = require 'plugins.custom.myutil'
myutil.do_something()
```

### Module Pattern

**Standard structure:**
```lua
local M = {}

-- Configuration table (optional)
M.config = {
  enabled = true,
  option = default_value,
}

-- Public functions
function M.public_function()
  -- Implementation
end

-- Private functions (local, not exported)
local function private_helper()
  -- Internal use only
end

-- Setup function (optional but recommended)
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

return M
```

## Current Modules

### diagnostics-copy.lua

**Purpose:** Copy LSP diagnostics to clipboard for AI assistant workflows

**Key patterns:**
- Uses `vim.diagnostic.get()` API
- Groups by severity (ERROR, WARN, INFO, HINT)
- Copies to both `+` and `*` registers (cross-platform)
- Format optimized for Claude Code

**Integration:**
```lua
-- config/keymaps.lua
local diagnostics = require 'plugins.custom.diagnostics-copy'
vim.keymap.set('n', '<leader>ce', diagnostics.copy_errors_only)
vim.keymap.set('n', '<leader>cd', diagnostics.copy_all_diagnostics)
```

**Why separate module:**
- Reusable across keybindings
- Clear function names
- Testable in isolation
- Easy to disable/modify

### controlsave.lua

**Purpose:** Save functionality with validation and integrations

**Key patterns:**
- Validates buffer state before saving
- Integrates with other utilities (TypeScript stripper)
- Works across multiple modes
- Handles edge cases (read-only, no filename, special buffers)

**Integration:**
```lua
-- config/keymaps.lua
local controlsave = require 'plugins.custom.controlsave'

vim.keymap.set('n', '<C-s>', controlsave.save)
vim.keymap.set('i', '<C-s>', controlsave.save)
vim.keymap.set('v', '<C-s>', function()
  vim.cmd 'normal! <Esc>'
  controlsave.save()
end)
```

**Integration with TypeScript stripper:**
```lua
-- controlsave.lua:41-44
local stripper_ok, stripper = pcall(require, 'plugins.custom.typescript-return-stripper')
if stripper_ok then
  stripper.on_save(0)
end
```

**Why separate module:**
- Complex save logic isolated
- Multiple entry points (normal, insert, visual)
- Integration point for pre-save hooks
- Reusable by other modules

### typescript-return-stripper.lua

**Purpose:** Auto-remove TypeScript return type annotations using tree-sitter

**Key patterns:**
- Tree-sitter AST parsing
- Query-based node matching
- Reverse-order modification (bottom-to-top)
- Debug mode with comprehensive logging

**Tree-sitter query:**
```lua
local query_string = [[
  (function_declaration
    return_type: (type_annotation) @return_type)

  (arrow_function
    return_type: (type_annotation) @return_type)

  (method_definition
    return_type: (type_annotation) @return_type)

  (method_signature
    return_type: (type_annotation) @return_type)
]]
```

**Integration:**
```lua
-- Automatic via controlsave.lua
-- Manual via keymaps.lua
vim.api.nvim_create_user_command('TSStripNow', function()
  local stripper = require 'plugins.custom.typescript-return-stripper'
  local count = stripper.strip_return_types(0)
  vim.notify(string.format('Removed %d annotations', count))
end)
```

**Why separate module:**
- Complex tree-sitter logic
- Language-specific functionality
- Debug commands and testing
- Optional feature (can be disabled)

### mermaid.lua

**Purpose:** Render Mermaid diagrams inline in markdown

**Key patterns:**
- External tool integration (`mmdc` CLI)
- Hash-based caching
- Per-buffer state management
- Scheduled rendering (batch processing)

**Integration:**
```lua
-- plugins/markdown.lua
{
  'MeanderingProgrammer/render-markdown.nvim',
  opts = {
    code = {
      language_name = false,
    },
  },
  config = function(_, opts)
    local mermaid = require 'plugins.custom.mermaid'
    opts.custom_handlers = {
      mermaid = mermaid.handler,
    }
    require('render-markdown').setup(opts)
  end,
}
```

**Why separate module:**
- Complex external tool integration
- State management (cache, buffers)
- Error handling for missing tools
- Reusable handler pattern

## Creating a New Module

### When to Create a Module

**Create a module when:**
- Functionality spans multiple keybindings
- Complex logic that needs isolation
- Reusable across different contexts
- Requires configuration or state
- Needs testing in isolation

**Don't create a module when:**
- Simple one-liner keybinding
- Plugin-specific config (put in plugin spec instead)
- Core Neovim option (put in config/options.lua)

### Module Template

```lua
-- lua/plugins/custom/myutil.lua
local M = {}

-- Configuration with sensible defaults
M.config = {
  enabled = true,
  debug = false,
}

-- Debug logging helper
local function log(msg)
  if M.config.debug then
    print('[MyUtil] ' .. msg)
  end
end

-- Main functionality
function M.do_something()
  log('do_something() called')

  if not M.config.enabled then
    vim.notify('MyUtil is disabled', vim.log.levels.WARN)
    return
  end

  -- Implementation
  local result = do_work()

  if result then
    vim.notify('Success!', vim.log.levels.INFO)
  end
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  log('MyUtil setup complete')
end

return M
```

### Adding Keybindings

**In config/keymaps.lua:**
```lua
-- Require the module
local myutil = require 'plugins.custom.myutil'

-- Basic keybinding
vim.keymap.set('n', '<leader>x', myutil.do_something, {
  desc = 'Do something useful'
})

-- User command
vim.api.nvim_create_user_command('MyUtil', function()
  myutil.do_something()
end, { desc = 'Run my utility' })
```

### Adding Debug Commands

**Pattern from TypeScript stripper:**
```lua
-- config/keymaps.lua
vim.api.nvim_create_user_command('MyUtilDebug', function()
  local myutil = require 'plugins.custom.myutil'
  myutil.config.debug = not myutil.config.debug
  local status = myutil.config.debug and 'ENABLED' or 'DISABLED'
  vim.notify('MyUtil Debug: ' .. status, vim.log.levels.INFO)
end, { desc = 'Toggle MyUtil debug mode' })

vim.api.nvim_create_user_command('MyUtilTest', function()
  local myutil = require 'plugins.custom.myutil'
  myutil.test()  -- Run test/diagnostic function
end, { desc = 'Test MyUtil functionality' })
```

## Integration Patterns

### Module → Keybinding

**Most common integration:**
```lua
-- custom/myutil.lua
function M.action()
  -- Implementation
end

-- config/keymaps.lua
local myutil = require 'plugins.custom.myutil'
vim.keymap.set('n', '<leader>x', myutil.action)
```

### Module → Autocmd

**Event-driven integration:**
```lua
-- custom/myutil.lua
function M.on_save(bufnr)
  -- Run before save
end

-- config/autocmds.lua
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(event)
    require('plugins.custom.myutil').on_save(event.buf)
  end,
})
```

### Module → Plugin

**Plugin integration:**
```lua
-- custom/myutil.lua
function M.handler(...)
  -- Handle plugin event
end

-- plugins/editor.lua
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

### Module → Module

**Module dependency:**
```lua
-- custom/util-b.lua
local util_a = require 'plugins.custom.util-a'

function M.action()
  util_a.helper()  -- Use another module
  -- Additional logic
end
```

## Common Patterns

### Configuration Pattern

```lua
M.config = {
  enabled = true,
  option1 = 'default',
  option2 = 42,
}

function M.setup(opts)
  opts = opts or {}

  -- Validate required options
  if opts.required and not opts.required_value then
    vim.notify('Missing required option', vim.log.levels.ERROR)
    return false
  end

  -- Merge with defaults
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  return true
end
```

### Error Handling Pattern

```lua
function M.safe_action()
  local ok, result = pcall(function()
    -- Code that might error
    return do_work()
  end)

  if not ok then
    vim.notify('Error: ' .. result, vim.log.levels.ERROR)
    return nil
  end

  return result
end
```

### Conditional Execution Pattern

```lua
function M.conditional_action()
  -- Check prerequisites
  if not M.config.enabled then
    return
  end

  if vim.bo.readonly then
    vim.notify('Buffer is read-only', vim.log.levels.WARN)
    return
  end

  -- Proceed with action
  do_work()
end
```

### State Management Pattern

```lua
-- Module-level state
local state = {
  cache = {},
  last_run = nil,
}

function M.stateful_action()
  -- Update state
  state.last_run = os.time()

  -- Use cached data
  if state.cache[key] then
    return state.cache[key]
  end

  -- Compute and cache
  local result = expensive_operation()
  state.cache[key] = result
  return result
end

-- Cleanup function
function M.cleanup()
  state.cache = {}
end
```

### Debug Logging Pattern

```lua
local function log(level, msg)
  if M.config.debug then
    local prefix = string.format('[%s] ', M.name or 'Module')
    if level == 'error' then
      vim.notify(prefix .. msg, vim.log.levels.ERROR)
    else
      print(prefix .. msg)
    end
  end
end

function M.action()
  log('info', 'Starting action')
  -- Implementation
  log('info', 'Action complete')
end
```

## Best Practices

### Naming

- **Module files:** `descriptive-name.lua` (kebab-case)
- **Functions:** `function_name()` (snake_case)
- **Constants:** `CONSTANT_NAME` (SCREAMING_SNAKE_CASE)
- **Private functions:** `local function helper()` (not exported)

### Documentation

```lua
--- Brief function description
--- @param bufnr number Buffer number (0 for current)
--- @param opts table|nil Optional configuration
--- @return boolean success True if successful
function M.documented_function(bufnr, opts)
  -- Implementation
end
```

### Error Messages

```lua
-- Good: Actionable error
vim.notify('Tree-sitter parser not found. Install with :TSInstall typescript', vim.log.levels.ERROR)

-- Bad: Vague error
vim.notify('Error', vim.log.levels.ERROR)
```

### Testing

```lua
-- Add test function for debugging
function M.test()
  print('Config:', vim.inspect(M.config))
  print('Testing functionality...')

  local result = M.action()
  print('Result:', vim.inspect(result))
end
```

## For Future Claude Code Instances

**When creating/modifying custom modules:**

1. **Decide if module is needed:**
   - Complex logic → Yes, create module
   - Simple keybinding → No, add to keymaps.lua

2. **Use standard module pattern:**
   - `local M = {}`
   - `M.config = { ... }`
   - `function M.setup(opts) ... end`
   - `return M`

3. **Add integration points:**
   - Keybindings in config/keymaps.lua
   - Autocmds in config/autocmds.lua
   - Plugin hooks in plugins/*.lua

4. **Include debugging:**
   - Debug mode toggle
   - Test function
   - Verbose logging

5. **Document:**
   - Add to custom/README.md (user-facing)
   - Update this file (architectural)
   - Add keybindings to docs/KEYBINDINGS_NEOVIM.md

6. **Test:**
   ```vim
   :lua require('plugins.custom.myutil').test()
   :lua package.loaded['plugins.custom.myutil'] = nil  " Reload
   ```
