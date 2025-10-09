# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with Neovim plugin specifications.

## Directory Purpose

The `plugins/` directory contains plugin specifications that lazy.nvim loads. Each file returns a table of plugin specs organized by category (editor, lsp, git, etc.).

## Plugin Spec Architecture

### File Structure Pattern

```lua
-- File: lua/plugins/category.lua
return {
  -- Plugin 1
  {
    'author/plugin-name',
    event = 'VimEnter',
    dependencies = { 'dep/plugin' },
    config = function()
      require('plugin').setup {
        option = value,
      }
    end,
  },

  -- Plugin 2
  {
    'author/another-plugin',
    cmd = 'Command',
  },
}
```

### Lazy Loading Strategy

**Why lazy loading matters:**
- Faster startup (only load what's needed)
- Better performance (plugins load on demand)
- Cleaner architecture (explicit dependencies)

**Loading triggers:**

**event - Load on Neovim event**
```lua
event = 'VimEnter'        -- After Neovim starts
event = 'BufRead'         -- When reading buffer
event = 'InsertEnter'     -- Entering insert mode
event = { 'Event1', 'Event2' }  -- Multiple events
```

**cmd - Load when command is run**
```lua
cmd = 'LazyGit'           -- Single command
cmd = { 'Cmd1', 'Cmd2' }  -- Multiple commands
```

**ft - Load for file type**
```lua
ft = 'python'             -- Single filetype
ft = { 'lua', 'vim' }     -- Multiple filetypes
```

**keys - Load when keybinding pressed**
```lua
keys = {
  { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
}
```

**dependencies - Load with dependency**
```lua
dependencies = {
  'nvim-lua/plenary.nvim',  -- Loads before this plugin
}
```

**cond - Conditional loading**
```lua
cond = function()
  return vim.env.API_KEY ~= nil  -- Only load if API key exists
end,
```

### Config vs Opts

**config function - Full control**
```lua
config = function()
  require('plugin').setup {
    option = value,
  }
  -- Additional setup code
end,
```

**opts table - Shorthand for setup**
```lua
opts = {
  option = value,
}
-- Equivalent to:
-- config = function()
--   require('plugin').setup { option = value }
-- end
```

**opts function - Dynamic configuration**
```lua
opts = function()
  local config = {}
  if condition then
    config.feature = true
  end
  return config
end,
```

## Category Organization

### When to Create New Category

**Create new category file when:**
- Adding 3+ plugins for a specific purpose
- Existing categories don't fit
- Logically distinct functionality

**Add to existing category when:**
- 1-2 plugins for existing purpose
- Closely related to existing plugins
- Extends current category

### Category Descriptions

**editor.lua** - File management and navigation
- File explorers
- Fuzzy finders
- Search/replace tools
- Indentation detection

**lsp.lua** - Language servers and formatting
- LSP client (nvim-lspconfig)
- LSP installer (mason.nvim)
- Formatters (conform.nvim)
- LSP UI enhancements

**completion.lua** - Autocompletion
- Completion engines
- Snippet engines
- Completion sources

**ai.lua** - AI-powered tools
- AI completion
- AI chat assistants
- REPL integration
- Requires API keys (conditional loading)

**git.lua** - Git integration
- Git TUIs
- GitHub/GitLab integration
- Diff viewers
- Merge conflict resolution
- Git signs/gutters

**markdown.lua** - Markdown and note-taking
- Markdown renderers
- Obsidian integration
- Preview tools
- Outline viewers

**ui.lua** - Interface enhancements
- Colorschemes
- Statuslines
- Keybinding hints
- Visual improvements

**treesitter.lua** - Syntax and parsing
- Treesitter framework
- Parser installations

**tools.lua** - Utility plugins
- File viewers (CSV, images)
- Miscellaneous utilities

**custom/** - Custom Lua modules (not plugin specs)

## Common Modification Patterns

### Adding a Plugin

**1. Choose category:**
```lua
-- If adding file explorer → editor.lua
-- If adding LSP server → lsp.lua
-- If adding git tool → git.lua
```

**2. Add plugin spec:**
```lua
{
  'author/plugin-name',
  -- Choose lazy loading trigger
  event = 'VimEnter',  -- or cmd, ft, keys

  -- Add dependencies if needed
  dependencies = {
    'dependency/plugin',
  },

  -- Configure plugin
  config = function()
    require('plugin-name').setup {
      option = value,
    }
  end,
},
```

**3. Add keybindings:**
```lua
-- In plugin spec (lazy-loaded)
keys = {
  { '<leader>x', '<cmd>Command<cr>', desc = 'Description' },
},

-- OR in plugin config (after setup)
config = function()
  require('plugin').setup {}
  vim.keymap.set('n', '<leader>x', '<cmd>Command<cr>', { desc = 'Description' })
end,
```

### Modifying Plugin Configuration

**Simple change:**
```lua
-- Before
opts = {
  option = value,
}

-- After
opts = {
  option = new_value,
  new_option = value,
}
```

**Complex change:**
```lua
-- Before
opts = { ... }

-- After (use config function for more control)
config = function()
  local config = {
    option = value,
  }

  if condition then
    config.conditional_option = value
  end

  require('plugin').setup(config)

  -- Additional setup
  vim.cmd 'command'
end,
```

### Adding LSP Server

**Edit lsp.lua:**
```lua
-- Find servers table (around line 149)
local servers = {
  ts_ls = {},
  pyright = {},
  lua_ls = { ... },

  -- Add new server
  rust_analyzer = {},
  gopls = {
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
        },
      },
    },
  },
}
```

**Mason will auto-install:**
- Listed in mason-tool-installer.nvim config
- Available via `:Mason` command

### Adding Formatter

**Edit lsp.lua (conform.nvim section):**
```lua
-- Around line 192
formatters_by_ft = {
  lua = { 'stylua' },
  python = { 'ruff_format' },

  -- Add new formatter
  rust = { 'rustfmt' },
  go = { 'gofmt' },
}

-- Add to auto-install list (around line 170)
'stylua',
'prettier',
'ruff',
'rustfmt',  -- Add here
'gofmt',    -- Add here
```

### Conditional Plugin Loading

**Based on environment variable:**
```lua
{
  'ai-plugin/name',
  cond = function()
    return vim.env.API_KEY ~= nil
  end,
  config = function()
    -- Only runs if API_KEY is set
  end,
}
```

**Based on file existence:**
```lua
{
  'project-plugin/name',
  cond = function()
    return vim.fn.filereadable('.project-config') == 1
  end,
}
```

**Based on Neovim version:**
```lua
{
  'modern-plugin/name',
  cond = function()
    return vim.fn.has('nvim-0.10') == 1
  end,
}
```

## LSP Configuration Patterns

### LspAttach Autocmd

**Pattern in lsp.lua (line 38-68):**
```lua
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    -- event.buf - Buffer number
    -- event.data.client_id - LSP client ID

    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, {
        buffer = event.buf,  -- Buffer-local keybinding
        desc = 'LSP: ' .. desc,
      })
    end

    map('grd', require('telescope.builtin').lsp_definitions, 'Go to definition')
    -- More keybindings...
  end,
})
```

**Why buffer-local keybindings:**
- Only active in buffers with LSP attached
- Don't interfere with non-LSP buffers
- Automatically removed when buffer closes

### Server Capabilities

**Pattern for capability-based keybindings:**
```lua
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    if client and client.supports_method('textDocument/rename') then
      vim.keymap.set('n', 'grn', vim.lsp.buf.rename, { buffer = event.buf })
    end

    if client and client.supports_method('textDocument/formatting') then
      -- Enable formatting for this buffer
    end
  end,
})
```

## Plugin Integration Patterns

### Plugin A Extends Plugin B

**Example: nvim-lsp-file-operations extends neo-tree**
```lua
-- editor.lua
{
  'antosha417/nvim-lsp-file-operations',
  dependencies = {
    'nvim-neo-tree/neo-tree.nvim',  -- Loads neo-tree first
  },
  config = function()
    require('lsp-file-operations').setup()
  end,
}
```

### Plugin Uses Telescope for UI

**Example: lazygit.nvim + telescope integration**
```lua
{
  'kdheepak/lazygit.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',  -- For UI integration
  },
  config = function()
    require('telescope').load_extension('lazygit')
  end,
}
```

### Plugin Requires External Tool

**Example: markdown-preview.nvim needs Node.js**
```lua
{
  'iamcco/markdown-preview.nvim',
  build = function()
    vim.fn['mkdp#util#install']()  -- Installs Node.js dependencies
  end,
  ft = 'markdown',
}
```

## Troubleshooting Patterns

### Plugin Not Loading

**Diagnostic steps:**
```vim
:Lazy                      " Check plugin status
:Lazy reload plugin-name   " Force reload
:Lazy restore              " Restore to locked versions
:messages                  " Check for errors
```

**Common causes:**
1. **Lazy loading trigger not met**
   - Check `event`, `cmd`, `ft`, `keys` configuration
   - Try `event = 'VimEnter'` to force early loading

2. **Condition not satisfied**
   - Check `cond` function return value
   - Verify environment variables set

3. **Missing dependency**
   - Check `dependencies` list
   - Ensure dependencies are also in lazy.nvim spec

4. **Configuration error**
   - Check `:messages` for errors
   - Try reloading with `:Lazy reload`

### Keybinding Not Working

**Common causes:**
1. **Plugin not loaded yet**
   - Use `keys` in plugin spec for lazy loading
   - Or add keybinding inside `config` function

2. **Keybinding overwritten**
   - Check `:verbose map <leader>x`
   - Last plugin wins if multiple set same key

3. **Wrong mode**
   - Verify mode: 'n' (normal), 'v' (visual), 'i' (insert)

### LSP Not Attaching

**Diagnostic steps:**
```vim
:LspInfo                   " Check LSP status
:Mason                     " Verify server installed
:checkhealth lsp           " Check LSP health
```

**Common causes:**
1. **Server not installed**
   - Check `:Mason` for server
   - Verify server in `servers` table

2. **File type not recognized**
   - Check `:set filetype?`
   - Add filetype detection in `config/autocmds.lua`

3. **Server configuration error**
   - Check `:messages` for errors
   - Verify server settings in `servers` table

## For Future Claude Code Instances

**When modifying plugins:**

1. **Choose correct category file:**
   - File management → editor.lua
   - LSP/formatting → lsp.lua
   - Git tools → git.lua
   - AI tools → ai.lua

2. **Use appropriate lazy loading:**
   - General plugins → `event = 'VimEnter'`
   - Commands → `cmd = 'Command'`
   - File type → `ft = 'filetype'`
   - Keybindings → `keys = { ... }`

3. **Add keybindings:**
   - Plugin-specific → In plugin spec `keys` or `config`
   - Core editing → `config/keymaps.lua`

4. **Update documentation:**
   - Keybindings → `docs/KEYBINDINGS_NEOVIM.md`
   - Features → `nvim/README.md`
   - Architecture → This file

5. **Test changes:**
   ```vim
   :Lazy sync
   :Lazy reload plugin-name
   :checkhealth
   ```

6. **Common file locations:**
   - Add LSP server → `lsp.lua:149` (servers table)
   - Add formatter → `lsp.lua:192` (formatters_by_ft)
   - Add autocmd → `config/autocmds.lua`
   - Add keybinding → `config/keymaps.lua` or plugin spec
