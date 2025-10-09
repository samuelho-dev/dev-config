# Neovim Lua Configuration

This directory contains all Lua-based configuration for Neovim, organized into logical, maintainable modules.

## Directory Structure

```
lua/
├── README.md                # This file
├── CLAUDE.md                # AI guidance for Lua module organization
├── config/                  # Core Neovim configuration
│   ├── init.lua             # Loads all config modules
│   ├── options.lua          # Vim options (leader key, clipboard, etc.)
│   ├── autocmds.lua         # Autocommands (file detection, auto-reload)
│   └── keymaps.lua          # Core keybindings
└── plugins/                 # Plugin specifications by category
    ├── editor.lua           # File explorer, fuzzy finder, search/replace
    ├── lsp.lua              # LSP configuration and formatting
    ├── completion.lua       # Autocompletion (blink.cmp, LuaSnip)
    ├── ai.lua               # AI assistance (minuet, codecompanion, yarepl)
    ├── git.lua              # Git integration
    ├── markdown.lua         # Markdown and Obsidian
    ├── ui.lua               # UI enhancements
    ├── treesitter.lua       # Syntax highlighting
    ├── tools.lua            # Utility tools (CSV viewer)
    └── custom/              # Custom plugin utilities
        ├── diagnostics-copy.lua       # Claude Code integration
        ├── controlsave.lua            # Ctrl+S save functionality
        ├── typescript-return-stripper.lua  # TypeScript type stripper
        └── mermaid.lua                # Mermaid diagram rendering
```

## Architecture Overview

### Module Organization

**config/ - Core Configuration**
- Neovim settings that don't depend on plugins
- Loaded before plugins via `require 'config'` in `init.lua`
- Changes take effect immediately (no plugin manager involved)

**plugins/ - Plugin Specifications**
- Each file returns a table of plugin specifications
- Loaded by lazy.nvim via `{ import = 'plugins.category' }`
- Plugins are lazy-loaded based on events, commands, or file types

**plugins/custom/ - Custom Utilities**
- Not plugin specifications, but Lua modules
- Provide functionality for keybindings and plugins
- Required directly: `require 'plugins.custom.modulename'`

### Config vs Plugins Separation

| Aspect | config/ | plugins/ |
|--------|---------|----------|
| **Purpose** | Core Neovim settings | Plugin installations & configs |
| **Loading** | Immediate on startup | Lazy-loaded by lazy.nvim |
| **Dependencies** | No plugins | Requires plugins installed |
| **Examples** | Leader key, clipboard, line numbers | LSP servers, file explorer, git |

## Quick Reference

### Common Tasks

**Change leader key:**
Edit `config/options.lua:7`

**Add new keybinding:**
Edit `config/keymaps.lua`

**Add new plugin:**
Edit appropriate `plugins/*.lua` file

**Modify LSP servers:**
Edit `plugins/lsp.lua`

**Change formatter:**
Edit `plugins/lsp.lua` (conform.nvim section)

**Add custom utility:**
Create file in `plugins/custom/` and require it in keymaps or plugins

### Module Loading Order

1. **`init.lua`** (repository root) - Entry point
2. **`config/` modules** - Loaded via `require 'config'`
   - `config/init.lua` loads `options`, `autocmds`, `keymaps`
3. **lazy.nvim bootstrap** - Plugin manager auto-installs itself
4. **`plugins/` specifications** - Loaded via lazy.nvim imports
   - Each category file is imported
   - Plugins are lazy-loaded based on their configuration

## File Descriptions

### config/

**init.lua** (4 lines)
- Loads all config modules in order
- `require 'config.options'` → `require 'config.autocmds'` → `require 'config.keymaps'`

**options.lua** (~100 lines)
- Leader key configuration
- Python virtual environment detection
- Display options (line numbers, sign column, etc.)
- Editing behavior (tabs, indentation, case sensitivity)
- Search settings
- Clipboard integration
- File auto-reload

**autocmds.lua** (~30 lines)
- File auto-reload on external changes
- CSV/TSV filetype detection
- Highlight on yank
- Auto-create directories on save

**keymaps.lua** (~100 lines)
- Core editing keybindings (Escape, save, diagnostics)
- Navigation and window management
- Custom utility keybindings (diagnostic copy, TypeScript stripper)
- Reload config command

### plugins/

Each plugin file follows this pattern:
```lua
return {
  {
    'author/plugin-name',
    event = 'VimEnter',  -- or cmd, ft, keys, etc.
    dependencies = { ... },
    config = function()
      require('plugin').setup { ... }
    end,
  },
}
```

**editor.lua** - File management and navigation
- neo-tree (file explorer)
- telescope (fuzzy finder)
- nvim-spectre (search/replace)
- guess-indent

**lsp.lua** - Language servers and formatting
- nvim-lspconfig (LSP client)
- mason.nvim (LSP installer)
- conform.nvim (formatters)
- fidget.nvim (LSP progress)

**completion.lua** - Autocompletion
- blink.cmp (completion engine)
- LuaSnip (snippets)
- lazydev.nvim (Lua API completion)

**ai.lua** - AI-powered tools
- minuet-ai (AI completion)
- codecompanion (AI chat)
- yarepl (REPL integration)

**git.lua** - Git integration
- lazygit.nvim (git TUI)
- octo.nvim (GitHub PRs/issues)
- diffview.nvim (diff viewer)
- git-conflict.nvim (merge conflicts)
- gitsigns.nvim (git signs)

**markdown.lua** - Markdown and note-taking
- obsidian.nvim (Obsidian integration)
- render-markdown.nvim (in-buffer rendering)
- markdown-preview.nvim (browser preview)
- bullets.vim
- outline.nvim

**ui.lua** - Interface enhancements
- which-key.nvim (keybinding hints)
- tokyonight.nvim (colorscheme)
- todo-comments.nvim
- mini.nvim (statusline, surround, text objects)
- indent-blankline.nvim

**treesitter.lua** - Syntax highlighting
- nvim-treesitter (parser framework)

**tools.lua** - Utility plugins
- csvview.nvim (CSV viewer)

### plugins/custom/

**diagnostics-copy.lua**
- Copy LSP errors/diagnostics to clipboard
- Used with `<leader>ce` (errors) and `<leader>cd` (all diagnostics)
- Output formatted for Claude Code workflows

**controlsave.lua**
- Quick save with `Ctrl+S`
- Integrates with TypeScript return type stripper
- Works in normal, insert, and visual mode

**typescript-return-stripper.lua**
- Automatically removes TypeScript function return type annotations on save
- Tree-sitter-based AST parsing
- Debug commands: `:TSStripPreview`, `:TSStripTest`, `:TSStripNow`
- Preserves parameter types, only removes return types

**mermaid.lua**
- Renders Mermaid diagrams inline in markdown
- Integrates with render-markdown.nvim
- Uses `mmdc` CLI to generate PNG images
- Cached in `~/.cache/nvim/mermaid-diagrams/`

## Require Paths

### Correct Patterns

```lua
-- Config modules
require 'config'
require 'config.options'
require 'config.autocmds'
require 'config.keymaps'

-- Plugin specifications (lazy.nvim imports these)
{ import = 'plugins.editor' }
{ import = 'plugins.lsp' }

-- Custom utilities
local diagnostics = require 'plugins.custom.diagnostics-copy'
local controlsave = require 'plugins.custom.controlsave'
local stripper = require 'plugins.custom.typescript-return-stripper'
```

### Common Mistakes

```lua
-- WRONG: Missing 'plugins' prefix
require 'custom.diagnostics-copy'

-- WRONG: Can't require plugin specs directly
require 'plugins.editor'

-- CORRECT: Import in lazy.nvim setup
require('lazy').setup({
  { import = 'plugins.editor' },
})
```

## Modifying Configuration

### Adding a Keybinding

**Core keybinding (no plugins):**
Edit `config/keymaps.lua`:
```lua
vim.keymap.set('n', '<leader>x', function()
  -- Your code here
end, { desc = 'Description' })
```

**Plugin-specific keybinding:**
Edit the plugin's config function in `plugins/*.lua`:
```lua
config = function()
  require('plugin').setup {
    mappings = {
      ['<leader>x'] = 'action',
    },
  }
end,
```

### Adding a Plugin

1. **Choose category file** (`plugins/editor.lua`, `plugins/lsp.lua`, etc.)
2. **Add plugin specification:**
   ```lua
   {
     'author/plugin-name',
     event = 'VimEnter',  -- Lazy loading trigger
     config = function()
       require('plugin-name').setup()
     end,
   },
   ```
3. **Restart Neovim** or run `:Lazy sync`

### Creating a Custom Utility

1. **Create file** in `plugins/custom/myutil.lua`:
   ```lua
   local M = {}

   function M.do_something()
     -- Implementation
   end

   return M
   ```

2. **Require in keymaps** (`config/keymaps.lua`):
   ```lua
   local myutil = require 'plugins.custom.myutil'
   vim.keymap.set('n', '<leader>x', myutil.do_something)
   ```

## Related Documentation

- **[nvim/README.md](../README.md)** - Neovim overview and features
- **[nvim/CLAUDE.md](../CLAUDE.md)** - AI guidance for Neovim configuration
- **[config/README.md](config/README.md)** - Core configuration details
- **[plugins/README.md](plugins/README.md)** - Plugin architecture
- **[plugins/custom/README.md](plugins/custom/README.md)** - Custom utilities guide
- **[docs/KEYBINDINGS_NEOVIM.md](../../docs/KEYBINDINGS_NEOVIM.md)** - Complete keybinding reference
