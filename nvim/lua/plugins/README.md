# Neovim Plugins

This directory contains plugin specifications organized by category. Each file returns a table of plugin specs that lazy.nvim loads.

## Plugin Categories

| File | Plugins | Purpose |
|------|---------|---------|
| `editor.lua` | 6 | File explorer, fuzzy finder, search/replace, quick nav |
| `lsp.lua` | 7 | LSP servers, formatters, linters |
| `completion.lua` | 2 | Autocompletion engine and snippets |
| `ai.lua` | 3 | AI-powered coding assistance |
| `git.lua` | 5 | Git integration and workflow |
| `markdown.lua` | 6 | Markdown editing and Obsidian |
| `ui.lua` | 7 | Interface enhancements, buffer navigation |
| `treesitter.lua` | 1 | Syntax highlighting |
| `tools.lua` | 1 | Utility tools (CSV viewer) |
| `custom/` | 4 | Custom utility modules |

## Quick Reference

### Adding a Plugin

1. Choose category file (or create new one)
2. Add plugin spec:
   ```lua
   {
     'author/plugin-name',
     event = 'VimEnter',  -- Lazy loading trigger
     config = function()
       require('plugin-name').setup {}
     end,
   },
   ```
3. Run `:Lazy sync`

### Lazy Loading Triggers

| Trigger | When Plugin Loads | Use For |
|---------|-------------------|---------|
| `event = 'VimEnter'` | After Neovim starts | General-purpose plugins |
| `event = 'BufRead'` | When reading a buffer | Buffer-related features |
| `cmd = 'Command'` | When command is run | Infrequent commands |
| `ft = 'filetype'` | For specific file type | Language-specific plugins |
| `keys = { ... }` | When keybinding pressed | Keybinding-driven features |
| `dependencies = { ... }` | When dependency loads | Dependent plugins |

## Plugin Files

### editor.lua - File Management

**neo-tree.nvim** - File explorer
- Toggle: `\` or `<leader>e`
- Auto-refresh on external changes
- Shows hidden and gitignored files

**telescope.nvim** - Fuzzy finder
- `<leader>sf` - Find files
- `<leader>sg` - Live grep
- `<leader>sh` - Search help

**nvim-spectre** - Search and replace
- `<leader>rr` - Open Spectre
- `<leader>rw` - Replace word under cursor
- Project-wide find/replace with preview

**harpoon** - Quick file navigation
- `<leader>ha` - Add file to Harpoon
- `<leader>hm` - Toggle Harpoon menu
- `<leader>h1-4` - Jump to files 1-4
- Mark frequently used files for instant access

**guess-indent.nvim** - Auto-detect indentation

### lsp.lua - Language Servers

**LSP Servers Configured:**
- `ts_ls` - TypeScript/JavaScript
- `pyright` - Python
- `lua_ls` - Lua

**Formatters:**
- `stylua` - Lua
- `prettier` - JS/TS/JSON/YAML/Markdown
- `ruff` - Python

**Keybindings:** See [KEYBINDINGS_NEOVIM.md](../../../docs/KEYBINDINGS_NEOVIM.md)

### completion.lua - Autocompletion

**blink.cmp** - Completion engine
- Super-tab preset (Tab to accept)
- LSP, path, snippets sources
- Lua fuzzy matcher (no build dependencies)

**LuaSnip** - Snippet engine

### ai.lua - AI Tools

**minuet-ai** - AI completion
- OpenAI-compatible API
- Integrates with blink.cmp
- Conditional loading (requires API key)

**codecompanion** - AI chat assistant
- `:CodeCompanionChat` - Open chat
- Multi-provider support

**yarepl** - REPL integration
- `:REPLStart <type>` - Start REPL
- AI assistants (aichat, claude, aider)
- Language REPLs (python, R, bash)

### git.lua - Git Integration

**lazygit.nvim** - Git TUI
- `<leader>gg` - Open lazygit
- Full git workflow in Neovim

**octo.nvim** - GitHub integration
- `<leader>gp` - Pull requests
- `<leader>gi` - Issues

**diffview.nvim** - Diff viewer
- `<leader>gd` - Open diff view
- `<leader>gh` - File history

**git-conflict.nvim** - Merge conflicts
- `<leader>gco/gct/gcb` - Choose ours/theirs/both
- Visual conflict resolution

**gitsigns.nvim** - Git signs in gutter

### markdown.lua - Markdown & Notes

**obsidian.nvim** - Obsidian integration
- Dynamic vault detection
- `<CR>` - Follow links, toggle checkboxes
- `gf` - Follow markdown links

**render-markdown.nvim** - In-buffer rendering
- Beautiful markdown display
- Mermaid diagram support

**markdown-preview.nvim** - Browser preview
- `<leader>mp` - Toggle preview

**outline.nvim** - Document outline
- `<leader>o` - Toggle outline

### ui.lua - Interface

**which-key.nvim** - Keybinding hints

**tokyonight.nvim** - Colorscheme

**todo-comments.nvim** - Highlight TODOs

**mini.nvim** - Mini plugins
- mini.ai - Better text objects
- mini.surround - Surround operations
- mini.statusline - Simple statusline

**vim-visual-multi** - Multiple cursors
- `<leader>m` - Start multi-cursor mode
- VS Code-style multi-cursor editing

**indent-blankline.nvim** - Indentation guides

**barbar.nvim** - Tabline with buffer navigation
- `<M-1>` to `<M-9>` - Jump to buffer 1-9
- `<M-,>` / `<M-.>` - Previous/next buffer
- `<M-c>` - Close buffer
- `<leader>bp` - Buffer picker mode (shows letters)
- Numbered buffer tabs like browser tabs

### treesitter.lua - Syntax

**nvim-treesitter** - Parser framework
- Auto-install parsers
- Syntax highlighting
- Code understanding

### tools.lua - Utilities

**csvview.nvim** - CSV viewer
- Automatic for .csv files
- Border display mode

### custom/ - Custom Utilities

See [custom/README.md](custom/README.md) for details.

## Plugin Management

### Commands

| Command | Purpose |
|---------|---------|
| `:Lazy` | Open plugin manager UI |
| `:Lazy sync` | Install/update/clean plugins |
| `:Lazy restore` | Restore to lazy-lock.json versions |
| `:Lazy update` | Update all plugins |
| `:Lazy reload <plugin>` | Reload specific plugin |

### Version Locking

**lazy-lock.json** (committed to git):
- Ensures identical plugin versions across machines
- Use `:Lazy restore` on new machine
- Update lock file after `:Lazy update`

## Related Documentation

- **[lua/README.md](../README.md)** - Lua directory overview
- **[lua/CLAUDE.md](../CLAUDE.md)** - Lua module architecture
- **[plugins/custom/README.md](custom/README.md)** - Custom utilities
- **[nvim/CLAUDE.md](../../CLAUDE.md)** - Neovim architecture
- **[docs/KEYBINDINGS_NEOVIM.md](../../../docs/KEYBINDINGS_NEOVIM.md)** - Complete keybinding reference
