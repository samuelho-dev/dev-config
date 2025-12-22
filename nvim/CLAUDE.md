---
id: CLAUDE
aliases: []
tags: []
---
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with Neovim configuration in this directory.

## Architecture Overview

This Neovim configuration uses a **modular architecture** - splitting configuration into logical, maintainable modules organized by function.

**Design Philosophy:**

- Modular structure with separate concerns (config vs plugins)
- Plugin categorization by purpose (editor, lsp, git, ai, etc.)
- Custom utilities in dedicated subdirectory
- Version-locked plugins via `lazy-lock.json` (committed to git)
- Minimal abstractions - every module is understandable

## File Structure

```
nvim/
+-- init.lua                          # Main entry point (81 lines)
+-- lazy-lock.json                    # Plugin version lock (committed)
+-- .stylua.toml                      # Lua formatter config
+-- CLAUDE.md                         # This file (AI assistant guidance)
+-- README.md                         # User documentation
+-- lua/
    +-- config/                       # Core Neovim configuration
    |   +-- init.lua                  # Loads all config modules
    |   +-- options.lua               # Vim options (leader key, clipboard, etc.)
    |   +-- autocmds.lua              # Autocommands (file detection, auto-reload)
    |   +-- keymaps.lua               # Core keybindings
    +-- plugins/                      # Plugin specifications by category
        +-- editor.lua                # File explorer, fuzzy finder, search/replace
        +-- lsp.lua                   # LSP configuration and formatting
        +-- completion.lua            # Autocompletion (blink.cmp, LuaSnip)
        +-- ai.lua                    # AI assistance (avante, minuet, codecompanion, yarepl)
        +-- git.lua                   # Git integration
        +-- markdown.lua              # Markdown and Obsidian
        +-- ui.lua                    # UI enhancements
        +-- treesitter.lua            # Syntax highlighting
        +-- tools.lua                 # Utility tools (CSV viewer)
        +-- custom/                   # Custom plugin utilities
            +-- diagnostics-copy.lua  # Claude Code integration
            +-- controlsave.lua       # Ctrl+S save functionality
            +-- mermaid.lua           # Mermaid diagram rendering
```

## Core Architecture

### Plugin Manager: lazy.nvim

**Location:** Auto-bootstrapped in `init.lua:17-28`

Lazy.nvim automatically installs itself on first launch and manages all plugins.

**Important commands:**

- `:Lazy` - Open plugin manager UI
- `:Lazy sync` - Install/update/remove plugins
- `:Lazy restore` - Restore to lazy-lock.json versions
- `:Lazy update` - Update all plugins

**Plugin imports (init.lua:46-56):**

```lua
require('lazy').setup({
  { import = 'plugins.editor' },      -- File explorer, fuzzy finder, search
  { import = 'plugins.lsp' },         -- LSP + formatting
  { import = 'plugins.completion' },  -- Autocompletion
  { import = 'plugins.ai' },          -- AI tools
  { import = 'plugins.git' },         -- Git integration
  { import = 'plugins.markdown' },    -- Markdown + Obsidian
  { import = 'plugins.ui' },          -- UI enhancements
  { import = 'plugins.treesitter' },  -- Syntax highlighting
  { import = 'plugins.tools' },       -- Utility tools
}, { ... })
```

Each import loads a category file from `lua/plugins/`, which returns a table of plugin specifications.

### Configuration Loading (init.lua:32)

```lua
require 'config'  -- Loads lua/config/init.lua
```

This loads `lua/config/init.lua`, which in turn loads:

- `config.options` - All vim options
- `config.autocmds` - Autocommands
- `config.keymaps` - Core keybindings

### LSP Configuration

**Location:** `lua/plugins/lsp.lua`

**LSP Servers (lsp.lua:149-166):**

```lua
local servers = {
  ts_ls = {},      -- TypeScript/JavaScript
  pyright = {},    -- Python
  lua_ls = {       -- Lua (with Neovim-specific settings)
    settings = {
      Lua = {
        completion = { callSnippet = 'Replace' },
      },
    },
  },
}
```

**Adding a new LSP:**

1. Edit `lua/plugins/lsp.lua:149`
2. Add to `servers` table:
   ```lua
   rust_analyzer = {},
   gopls = {},
   ```
3. Restart Neovim
4. Run `:Mason` to install the server

**LSP Keybindings (defined in LspAttach autocommand, lsp.lua:38-68):**

- `grd` - Go to definition
- `grr` - Find references
- `gri` - Go to implementation
- `grt` - Go to type definition
- `grn` - Rename symbol
- `gra` - Code actions
- `gO` - Document symbols
- `gW` - Workspace symbols
- `grD` - Go to declaration

**Dependencies:**

- `mason.nvim` - LSP server installer
- `mason-lspconfig.nvim` - Bridge between Mason and lspconfig
- `mason-tool-installer.nvim` - Auto-install configured tools
- `fidget.nvim` - LSP progress notifications

### Formatters & Linters

**Location:** `lua/plugins/lsp.lua:192-233`

**Managed by Conform.nvim + Mason:**

```lua
formatters_by_ft = {
  lua = { 'stylua' },
  python = { 'ruff_format' },
  javascript = { 'prettier', stop_after_first = true },
  typescript = { 'prettier', stop_after_first = true },
  json = { 'prettier', stop_after_first = true },
  yaml = { 'prettier', stop_after_first = true },
  markdown = { 'prettier', stop_after_first = true },
}
```

**Auto-installed formatters (lsp.lua:170-174):**

- `stylua` - Lua formatter
- `prettier` - JavaScript/TypeScript/JSON/YAML/Markdown
- `ruff` - Python formatter and linter

**Auto-format on save:** Enabled (except C/C++)
**Manual format:** `<leader>f`

**Format on save configuration (lsp.lua:208-220):**

```lua
format_on_save = function(bufnr)
  -- Disable for C/C++
  local disable_filetypes = { c = true, cpp = true }
  if disable_filetypes[vim.bo[bufnr].filetype] then
    return nil
  else
    return { timeout_ms = 500, lsp_format = 'fallback' }
  end
end,
```

### Autocompletion

**Location:** `lua/plugins/completion.lua`

**Components:**

- `blink.cmp` - Modern completion engine (fast, Lua-native)
- `LuaSnip` - Snippet engine
- `lazydev.nvim` - Neovim Lua API completion

**Configuration highlights:**

- Preset: `super-tab` (Tab to accept, Ctrl+N/P to cycle)
- Documentation: Manual with `<c-space>` (auto_show = false)
- Sources: LSP, path, snippets, lazydev
- Fuzzy matcher: Lua implementation (no pkg-config needed)

**Why Lua fuzzy matcher?**

```lua
fuzzy = {
  implementation = 'lua',
  prebuilt_binaries = { download = false },
},
```

This avoids native build steps requiring pkg-config, making installation more reliable across platforms.

**Signature help:** Enabled (shows function signatures while typing)

### AI Integration

**Location:** `lua/plugins/ai.lua`

All AI plugins consolidated in one file for easy management.

**Components:**

**1. avante.nvim (Cursor-like AI coding assistant)**

- Chat-based AI coding assistant with inline code editing
- Powered by LiteLLM proxy for team AI management and cost tracking
- OpenAI-compatible endpoint integration
- **Conditional loading:** Only loads if `LITELLM_MASTER_KEY` environment variable is set

```lua
cond = function()
  return vim.env.LITELLM_MASTER_KEY ~= nil
end,
```

**Configuration:**

```lua
opts = {
  provider = 'litellm',
  providers = {
    litellm = {
      __inherited_from = 'openai',
      endpoint = 'http://localhost:4000/v1',
      model = 'claude-sonnet-4', -- Configure in LiteLLM config
      api_key_name = 'LITELLM_MASTER_KEY',
      timeout = 30000,
      extra_request_body = {
        temperature = 0.7,
        max_tokens = 4096,
      },
    },
  },
},
```

**Commands:**
- `:AvanteAsk` - Ask AI about code (opens chat interface)
- `:AvanteEdit` - Request AI code edits (applies changes directly to buffer)
- `:AvanteToggle` - Toggle Avante chat window

**Dependencies:**
- `nvim-treesitter/nvim-treesitter` - Syntax parsing
- `stevearc/dressing.nvim` - Enhanced UI for inputs
- `nvim-lua/plenary.nvim` - Utility functions
- `MunifTanjim/nui.nvim` - UI components
- `nvim-tree/nvim-web-devicons` - File icons
- `render-markdown.nvim` (optional) - Markdown rendering in chat
- `img-clip.nvim` (optional) - Image pasting support

**Prerequisites:**
- LiteLLM proxy running in Kubernetes cluster
- `kubectl port-forward -n litellm svc/litellm 4000:4000` (expose proxy to localhost)
- `LITELLM_MASTER_KEY` environment variable loaded (via direnv or manual export)

**Architecture:**
```
Neovim (avante.nvim) -> http://localhost:4000/v1 (kubectl port-forward)
                     -> LiteLLM Proxy (k8s cluster)
                     -> Anthropic/OpenAI/Google APIs
```

**Build requirements:**
- `make` command (for building native components during plugin installation)
- Automatically handled by lazy.nvim with `build = 'make'`

**2. minuet-ai (AI-powered completion)**

- OpenAI-compatible API using GLM 4.5 model
- Integrates with blink.cmp
- Auto-triggers inline completions
- **Conditional loading:** Only loads if `ZHIPUAI_API_KEY` environment variable is set

```lua
cond = function()
  return vim.env.ZHIPUAI_API_KEY ~= nil and vim.env.ZHIPUAI_API_KEY ~= ''
end,
```

**3. codecompanion (AI chat assistant)**

- Chat interface for code assistance
- GLM 4.5 adapter configured
- Commands: `:CodeCompanionChat`, `:CodeCompanion`
- **Conditional loading:** Same as minuet-ai

**4. yarepl (REPL integration)**

- Connect to AI assistants (aichat, claude, aider)
- Also supports language REPLs (python, R, bash, etc.)
- Commands: `:REPLStart <type>`, `:REPLFocus`, `:REPLSendLine`, `:REPLSendVisual`
- Configured REPLs:
  - `aichat` - AI chat CLI
  - `claude` - Claude Code agent
  - `aider` - Aider AI coding assistant
  - `observability` - System monitoring scripts
  - `ipython`, `python`, `radian`, `R`, `bash`, `zsh` - Language REPLs

**Agent root configuration:**

```lua
local agent_root = vim.env.CLAUDE_AGENT_ROOT or vim.fn.expand '~/Projects/claude-code-agent'
```

## Plugin Categories

### editor.lua (5 plugins)

**neo-tree.nvim** - File explorer

- Keybindings: `\` or `<leader>e` to toggle
- Auto-refresh on external changes (`use_libuv_file_watcher = true`)
- Follows current file
- Shows hidden files and gitignored files

**nvim-lsp-file-operations** - LSP-aware file operations

- Updates imports when files are moved/renamed in neo-tree
- Automatic integration

**telescope.nvim** - Fuzzy finder

- `<leader>sf` - Find files
- `<leader>sg` - Live grep
- `<leader>sh` - Search help
- `<leader>sk` - Search keymaps
- `<leader><leader>` - Switch buffers
- Includes fzf-native for faster searching

**nvim-spectre** - Search and replace

- `<leader>rr` - Open Spectre (project-wide)
- `<leader>rw` - Replace word under cursor
- `<leader>rf` - Replace in current file
- Visual interface with preview before replace
- Uses ripgrep + sed

**guess-indent.nvim** - Auto-detect indentation

- Automatically detects tabstop and shiftwidth
- Works on file open

### lsp.lua (7 plugins)

See "LSP Configuration" and "Formatters & Linters" sections above.

**Key plugins:**

- `nvim-lspconfig` - LSP client configurations
- `mason.nvim` - LSP/formatter installer
- `mason-lspconfig.nvim` - Mason + lspconfig bridge
- `mason-tool-installer.nvim` - Auto-install tools
- `fidget.nvim` - LSP progress UI
- `conform.nvim` - Formatter runner
- `lazydev.nvim` - Neovim Lua API completion

### completion.lua (2 plugins)

See "Autocompletion" section above.

- `blink.cmp` - Completion engine
- `LuaSnip` - Snippet engine

### ai.lua (4 plugins)

See "AI Integration" section above.

- `avante.nvim` - Cursor-like AI coding assistant (LiteLLM proxy integration)
- `minuet-ai.nvim` - AI-powered completions
- `codecompanion.nvim` - AI chat assistant
- `yarepl.nvim` - REPL integration

### git.lua (5 plugins)

**gitsigns.nvim** - Git gutter signs

- Shows added/changed/deleted lines in sign column
- No specific keybindings (integrated with statusline)

**lazygit.nvim** - Lazygit TUI integration

- `<leader>gg` - Open lazygit
- `<leader>gf` - Lazygit for current file
- Best git workflow tool

**octo.nvim** - GitHub PR/issue management

- `<leader>gp` - List Pull Requests
- `<leader>gi` - List Issues
- Requires `gh` CLI authenticated

**diffview.nvim** - Better diff viewing

- `<leader>gd` - Open diff view
- `<leader>gh` - File history
- `<leader>gH` - Branch history

**git-conflict.nvim** - Visual merge conflict resolution

- `<leader>gco` - Choose ours
- `<leader>gct` - Choose theirs
- `<leader>gcb` - Choose both
- `<leader>gc0` - Choose none
- `<leader>gcn` - Next conflict
- `<leader>gcp` - Previous conflict
- `<leader>gcl` - List conflicts in quickfix

### markdown.lua (6 plugins)

**obsidian.nvim** - Obsidian vault integration

- **Dynamic vault detection** - Automatically searches upward for `.obsidian` directory
- Zero hardcoded paths - works on any machine, any directory structure
- Opens from any location - auto-detects vault root or uses current directory
- Handles symlinked vaults properly (vim.fs normalizes paths)
- `<CR>` (Enter) - Smart action: follow links, toggle checkboxes, cycle headings
- `<leader>ch` - Toggle checkboxes (buffer-local in notes)
- `[o` / `]o` - Navigate to previous/next link
- Daily notes in `daily/` folder
- **Note:** Uses maintained fork `obsidian-nvim/obsidian.nvim`
- **Keybindings:** Set via `callbacks.enter_note` (modern pattern, not deprecated `mappings`)
- **Cross-machine compatible:** Single dynamic workspace adapts to any system

**render-markdown.nvim** - Beautiful in-buffer markdown rendering

- Code blocks, headings, lists styled visually
- Custom Mermaid diagram handler (see custom/mermaid.lua)
- Requires treesitter for parsing

**image.nvim** - Image rendering (for Mermaid diagrams)

- Kitty protocol backend
- Works in Ghostty terminal
- Integrates with render-markdown

**markdown-preview.nvim** - Browser preview

- `<leader>mp` - Toggle browser preview
- Live updates as you type

**bullets.vim** - Better bullet/task management

- Auto-formatting for lists and checkboxes

**outline.nvim** - Document outline

- `<leader>o` - Toggle outline sidebar
- Navigate document structure

### ui.lua (6 plugins)

**which-key.nvim** - Keybinding hints

- Shows pending keybindings after leader key
- Documents key groups:
  - `<leader>s` - [S]earch
  - `<leader>r` - [R]eplace
  - `<leader>t` - [T]oggle
  - `<leader>h` - Git [H]unk

**tokyonight.nvim** - Colorscheme

- Variant: tokyonight-night
- Italics disabled in comments
- Loaded with high priority

**todo-comments.nvim** - Highlight TODOs in comments

- Highlights TODO, FIXME, NOTE, etc.
- No signs in gutter

**mini.nvim** - Collection of small plugins

- `mini.ai` - Better text objects
- `mini.surround` - Add/delete/change surroundings
- `mini.statusline` - Simple statusline

**vim-visual-multi** - Multiple cursors

- `<leader>m` - Start multi-cursor, select word
- `<C-Down>` / `<C-Up>` - Add cursor vertically
- **Note:** Remapped from `<C-n>` to avoid blink.cmp conflict

**indent-blankline.nvim** - Indentation guides

- Shows vertical lines for indentation
- Scope highlighting for current block
- Excluded from special buffers (terminal, help, etc.)

### treesitter.lua (1 plugin)

**nvim-treesitter** - Syntax highlighting and code understanding

**Installed parsers:**

- Core: bash, c, diff, html, lua, luadoc, markdown, query, vim, vimdoc
- Web: javascript, typescript, tsx, jsdoc, json, yaml, toml, css
- Languages: python

**Features:**

- `auto_install = true` - Installs missing parsers automatically
- Highlight enabled
- Indent enabled (except Ruby)
- Additional vim regex highlighting for Ruby

### tools.lua (1 plugin)

**csvview.nvim** - Modern CSV viewer

- Filetype trigger: `csv`
- Display mode: `border` (shows column separators)
- Uses virtual text (doesn't modify file)
- Automatically activates on CSV file open

**Important:** Requires CSV filetype detection autocmd in `lua/config/autocmds.lua:19-29`

## Custom Plugin Utilities

Located in `lua/plugins/custom/` - these are not lazy.nvim plugin specs, but utility modules.

### diagnostics-copy.lua

**Purpose:** Copy LSP diagnostics to clipboard for AI assistants (especially Claude Code).

**Location:** `lua/plugins/custom/diagnostics-copy.lua`

**Functions:**

- `copy_errors_only()` - Copy only ERROR severity diagnostics
- `copy_all_diagnostics()` - Copy all diagnostics grouped by severity

**Keybindings (defined in config/keymaps.lua:41-43):**

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
- Filters by severity: `vim.diagnostic.severity.ERROR`, `.WARN`, `.INFO`, `.HINT`
- Copies to both `+` and `*` registers for cross-platform compatibility
- Groups output by severity for readability

**Used by:** Claude Code workflows for quick error reporting

### controlsave.lua

**Purpose:** Quick save functionality with industry-standard `Ctrl+S` keybinding. Integrates with TypeScript return type stripper.

**Location:** `lua/plugins/custom/controlsave.lua`

**Functions:**

- `save()` - Save current buffer with error handling (integrates TypeScript stripper)
- `save_all()` - Save all modified buffers
- `format_and_save()` - Explicitly format then save
- `setup(opts)` - Optional configuration

**Keybindings (defined in config/keymaps.lua:46-59):**

- `<C-s>` - Save file (normal, insert, visual mode)

**Features:**

- Error handling for read-only files
- Checks for special buffer types (terminal, help, etc.)
- Validates file has a name before saving
- **TypeScript integration:** Automatically strips return type annotations before saving (if enabled)
- Optional save notifications (disabled by default)
- Integration with conform.nvim format_on_save
- Exits insert/visual mode before saving

**Configuration (optional):**

```lua
local controlsave = require 'plugins.custom.controlsave'
controlsave.setup({
  notify_on_save = true, -- Enable save notifications
})
```

### typescript-return-stripper.lua

**Purpose:** Automatically removes TypeScript function return type annotations when saving files. Uses tree-sitter for precise AST-based removal.

**Location:** `lua/plugins/custom/typescript-return-stripper.lua`

**How it works:**

1. Triggered automatically by controlsave.lua when saving TypeScript/JavaScript files
2. Parses buffer AST using Neovim's tree-sitter API
3. Queries for return type annotations on functions, arrow functions, methods, and interface methods
4. Removes `: Type` annotations (including the colon) in reverse order to preserve positions
5. Saves the modified buffer

**Supported file types:**

- `typescript` (.ts)
- `typescriptreact` (.tsx)
- `javascript` (.js - if using JSDoc types)
- `javascriptreact` (.jsx)

**What gets removed:**

```typescript
// Before save:
function foo(): string {
  return "test";
}
const bar = (): number => 42;
class X {
  method(): void {}
}

// After save (Ctrl+S):
function foo() {
  return "test";
}
const bar = () => 42;
class X {
  method() {}
}

// Parameter types are PRESERVED:
function withParams(a: string, b: number): string {}
// After save:
function withParams(a: string, b: number) {}
```

**Functions:**

- `find_return_types(bufnr)` - Find all return type annotations via tree-sitter query
- `strip_return_types(bufnr)` - Remove return type annotations from buffer
- `on_save(bufnr)` - Hook called before save (checks filetype and enabled status)
- `preview_changes(bufnr)` - Preview what would be removed (debug command)
- `test_query(bufnr)` - Test tree-sitter parser availability (debug command)
- `has_parser(lang)` - Check if tree-sitter parser is installed
- `setup(opts)` - Configuration

**Debug Commands (defined in config/keymaps.lua:82-97):**

- `:TSStripPreview` - Preview return types that would be removed (doesn't modify buffer)
- `:TSStripTest` - Test tree-sitter query and parser availability
- `:TSStripNow` - Immediately strip return types without saving

**Configuration:**

```lua
local stripper = require 'plugins.custom.typescript-return-stripper'
stripper.setup({
  enabled = true,  -- Enable/disable feature
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  dry_run = false,  -- Set true for testing (shows count but doesn't modify)
  notify_on_strip = false,  -- Show notification when types are removed
})
```

**Tree-sitter Query:**

```lua
(function_declaration
  return_type: (type_annotation) @return_type)

(arrow_function
  return_type: (type_annotation) @return_type)

(method_definition
  return_type: (type_annotation) @return_type)

(method_signature
  return_type: (type_annotation) @return_type)
```

**Implementation details:**

- Uses `vim.treesitter.get_parser()` and `vim.treesitter.query.parse()`
- Iterates matches with `:iter_matches()` and captures node ranges
- Deletes in reverse order (bottom-to-top) to preserve positions during multi-deletion
- Includes the colon before the type annotation in deletion range
- Safe: Only modifies TypeScript/JavaScript files with valid tree-sitter parsers

**Integration:** Automatically integrated with controlsave.lua - runs before every save for supported file types.

### mermaid.lua

**Purpose:** Render Mermaid diagrams inline in markdown files.

**Location:** `lua/plugins/custom/mermaid.lua`

**Integration:** Custom handler for render-markdown.nvim (markdown.lua:73-80)

**Requirements:**

- `@mermaid-js/mermaid-cli` (`mmdc` command)
- ImageMagick
- `image.nvim` plugin

**How it works:**

1. Detects Mermaid code blocks via treesitter
2. Generates PNG images using `mmdc` CLI
3. Caches images in `~/.cache/nvim/mermaid-diagrams/`
4. Renders inline using image.nvim (Kitty protocol)
5. Updates only when content changes (hash-based caching)

**State management:**

- Per-buffer state tracking
- Cleanup on buffer wipeout
- Scheduled rendering (batch processing)

**Error handling:**

- Checks for `mmdc` executable
- One-time notification if CLI missing
- Graceful failure if image rendering not available

## Important Settings

### Auto-reload files (config/options.lua:88-90, config/autocmds.lua:4-17)

Critical for Claude Code workflows:

**options.lua:88-90:**

```lua
vim.o.autoread = true
```

**autocmds.lua:4-17:**

```lua
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  command = 'checktime',
})

vim.api.nvim_create_autocmd('FileChangedShellPost', {
  command = 'echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None',
})
```

This ensures Neovim automatically reloads files changed externally (e.g., by Claude Code, git operations, etc.).

### CSV filetype detection (config/autocmds.lua:19-29)

**Critical fix** for csvview.nvim lazy loading:

```lua
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  desc = 'Set filetype for CSV/TSV files',
  pattern = { '*.csv', '*.tsv' },
  callback = function()
    vim.bo.filetype = 'csv'
    vim.cmd 'doautocmd FileType csv'  -- Critical: triggers lazy loading
  end,
})
```

The `doautocmd FileType csv` line is essential - without it, the FileType event doesn't fire and csvview.nvim won't load.

### Neo-tree File Explorer Settings (editor.lua:17-33)

- `close_if_last_window = true` - Auto-close when last window
- `use_libuv_file_watcher = true` - OS-level file watching for auto-refresh
- `follow_current_file.enabled = true` - Focus follows active file
- `hide_dotfiles = false` - Show hidden files
- `hide_gitignored = false` - Show gitignored files

Keybindings:

- `\` or `<leader>e` - Toggle Neo-tree

### Python Virtual Environment Detection (config/options.lua:11-21)

Automatically detects `.venv/bin/python` in parent directories:

```lua
local function set_project_python()
  local cwd = vim.fn.expand '%:p:h'
  local venv_python = vim.fn.findfile('.venv/bin/python', cwd .. ';')
  if venv_python ~= '' then
    vim.g.python3_host_prog = vim.fn.fnamemodify(venv_python, ':p')
  end
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged' }, {
  callback = set_project_python,
})
```

This ensures LSP uses the correct Python interpreter for each project.

## Adding Custom Plugins

### Method 1: Add to existing category file

Edit the appropriate file in `lua/plugins/`:

```lua
-- lua/plugins/editor.lua
return {
  -- Existing plugins...

  -- New plugin
  {
    'author/plugin-name',
    event = 'VimEnter',
    config = function()
      require('plugin-name').setup()
    end,
  },
}
```

### Method 2: Create new category file

Create `lua/plugins/mycategory.lua`:

```lua
-- My custom plugins
return {
  {
    'author/plugin-name',
    cmd = 'MyCommand',
    config = function()
      require('plugin-name').setup()
    end,
  },
}
```

Then add import in `init.lua:56`:

```lua
{ import = 'plugins.mycategory' },
```

### Method 3: Create utility module

For non-plugin utilities (like diagnostics-copy.lua), create in `lua/plugins/custom/`:

```lua
-- lua/plugins/custom/myutil.lua
local M = {}

function M.do_something()
  -- Implementation
end

return M
```

Then require in keymaps or other files:

```lua
local myutil = require 'plugins.custom.myutil'
vim.keymap.set('n', '<leader>x', myutil.do_something)
```

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
3. Check custom module loaded: `:lua print(vim.inspect(require('plugins.custom.diagnostics-copy')))`

### Completion not working

1. Check blink.cmp loaded: `:Lazy`
2. Check sources: `:lua vim.print(require('blink.cmp').get_config())`

### AI plugins not loading

1. Check environment variable: `:lua print(vim.env.ZHIPUAI_API_KEY)`
2. If missing, set in shell before launching Neovim:
   ```bash
   export ZHIPUAI_API_KEY="your-key-here"
   nvim
   ```

### CSV plugin not loading

1. Open CSV file
2. Check filetype: `:set filetype?` (should be `csv`)
3. Check plugin loaded: `:Lazy` → search for csvview
4. If not triggered, manually: `:set filetype=csv` then `:doautocmd FileType csv`

### Modular structure issues

**Symptom:** "module not found" errors

**Check require paths:**

```vim
:lua print(package.path)
```

Should include Neovim config directory.

**Verify module exists:**

```vim
:lua print(vim.inspect(require('config.options')))
:lua print(vim.inspect(require('plugins.editor')))
```

**Common mistakes:**

- Wrong require path: `require 'custom.diagnostics-copy'` should be `require 'plugins.custom.diagnostics-copy'`
- Missing `return` statement in plugin files
- Syntax errors in Lua files (check with `:luafile %`)

## Version Consistency

`lazy-lock.json` is **committed to git**. This ensures:

- Identical plugin versions across machines
- No surprises from plugin updates
- Reproducible environment

**To update plugins:**

1. `:Lazy update` - Update plugins
2. Test thoroughly
3. Commit updated `lazy-lock.json`:
   ```bash
   git add nvim/lazy-lock.json
   git commit -m "chore(nvim): update plugin versions"
   ```

**To restore locked versions:**

```vim
:Lazy restore
```

## Leader Key

`<space>` (spacebar) - defined in `config/options.lua:7-8`

All custom keybindings use `<leader>` prefix for organization.

## Architectural Decisions

### Why modular structure?

**Before (Kickstart.nvim monolithic):**

- Single 1823-line `init.lua` file
- Hard to navigate and find specific features
- Custom plugins mixed with core config
- Difficult to disable/modify categories

**After (Modular architecture):**

- 81-line `init.lua` entry point
- Clear separation: config/ vs plugins/
- Plugin categories: editor, lsp, ai, git, etc.
- Custom utilities in plugins/custom/
- 94% reduction in main file size

### Why plugins/custom/ instead of lua/custom/plugins/?

**Consistency with modular structure:**

- All plugins under `lua/plugins/`
- Custom utilities are plugin-related
- Shorter require paths: `plugins.custom.diagnostics-copy` vs `custom.plugins.diagnostics-copy`

### Why consolidate AI plugins in ai.lua?

**Before:**

- minuet-ai in completion.lua
- codecompanion scattered
- yarepl in tools.lua

**After (consolidated):**

- All AI tools in one file
- Easy to disable all AI features
- Consistent environment variable checking
- Clear separation from core completion

### Why Lua fuzzy matcher for blink.cmp?

**Reason:** Avoid native build dependencies

**Impact:**

- No pkg-config required
- No C compiler required
- More reliable cross-platform installation
- Slightly slower than native, but acceptable for most workflows

**Can be changed** in `completion.lua:68-71` if you prefer native performance.

## Health Check Warnings Explained

### Expected Warnings (Intentional Configuration)

Run `:checkhealth` to diagnose your setup. Some warnings are **intentional** and safe to ignore:

#### blink.cmp fuzzy lib warning ✅ EXPECTED

```
⚠️ WARNING blink_cmp_fuzzy lib is not downloaded/built
```

**Why this exists:**

- We use `implementation = 'lua'` in `completion.lua:82-85`
- Intentionally disabled native Rust binary to avoid build dependencies
- Avoids requiring `pkg-config`, `cargo`, and C compiler

**Trade-off:**

- Lua matcher is slightly slower than Rust
- But: More reliable cross-platform installation
- Acceptable performance for most workflows

**Fix (if you want native performance):**

```bash
brew install pkg-config
# Then remove lines 83-84 from completion.lua
```

#### Mason language warnings ✅ SAFE TO IGNORE

```
⚠️ WARNING Go: not available
⚠️ WARNING cargo: not available
⚠️ WARNING PHP: not available
⚠️ WARNING Java: not available
⚠️ WARNING julia: not available
```

**Why these exist:**

- Mason checks for all possible language tools
- Only needed if you develop in those specific languages

**When to fix:**

- Only install if you actually develop in that language
- Examples:
  ```bash
  brew install go        # For Go development
  brew install rustup    # For Rust development
  brew install openjdk   # For Java development
  ```

#### which-key overlapping keymaps ✅ INFORMATIONAL ONLY

```
⚠️ WARNING In mode `n`, <\> overlaps with <\\/>, <\\gS>
⚠️ WARNING In mode `n`, <sd> overlaps with <sdn>, <sdl>
```

**Why these exist:**

- Normal behavior for plugins with prefix keys
- `<\>` is a prefix, Neovim waits for the full sequence
- `<sd>`, `<sf>`, `<sr>` are mini.surround prefixes

**From which-key docs:**

> Overlapping keymaps are only reported for informational purposes.
> This doesn't necessarily mean there is a problem with your config.

**Action:** Ignore completely (working as designed)

#### tree-sitter CLI warning ✅ OPTIONAL

```
⚠️ WARNING `tree-sitter` executable not found
```

**Why this exists:**

- Only needed for `:TSInstallFromGrammar` (parser development)
- `:TSInstall` (normal usage) works fine without it
- All parsers are pre-installed

**When to fix:**

```bash
npm add -g tree-sitter-cli  # Only if developing grammars
```

### Fixed Warnings (No Longer Appear)

#### Disabled providers ✅ FIXED

**Previously showed:**

```
⚠️ WARNING Perl provider not found
⚠️ WARNING Ruby provider not found
```

**Fixed in:** `lua/config/options.lua:10-13`

```lua
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
```

**Why disabled:**

- No plugins use Perl/Ruby remote plugin support
- Legacy Vim plugin compatibility (not needed in Neovim)
- Reduces startup time

### Warnings That Need Investigation

#### luarocks PATH issue ⚠️ TEST NEEDED

**Conflicting info:**

- Mason: `luarocks: not available`
- lazy.nvim: `luarocks 3.12.2` (via hererocks)

**How to test:**

1. Open markdown file with Mermaid diagram
2. Check if diagram renders (uses image.nvim → needs luarocks)
3. If broken: Add hererocks to PATH in `~/.zshrc.local`:
   ```bash
   export PATH="$HOME/.local/share/nvim/lazy-rocks/hererocks/bin:$PATH"
   ```

**Action:** Test Mermaid rendering, only fix if broken

### Summary Table

| Warning                          | Status         | Action                             |
| -------------------------------- | -------------- | ---------------------------------- |
| blink.cmp fuzzy lib              | ✅ Expected    | Ignore (intentional Lua matcher)   |
| Missing languages (Go/Rust/Java) | ✅ Optional    | Install only if needed             |
| which-key overlaps               | ✅ Info only   | Ignore (working as designed)       |
| tree-sitter CLI                  | ✅ Optional    | Ignore (unless developing parsers) |
| Perl/Ruby providers              | ✅ Fixed       | Already disabled                   |
| luarocks PATH                    | ⚠️ Investigate | Test Mermaid, fix if broken        |

### Diagnostic Commands

```vim
:checkhealth              " Full health check
:checkhealth vim.lsp      " LSP-specific check
:checkhealth vim.provider " Provider check
:checkhealth lazy         " Plugin manager check
:checkhealth mason        " LSP/formatter installer check
```

## For Future Claude Code Instances

**When modifying this configuration:**

1. **Understand the module structure first:**
   - `config/` - Core Neovim settings (non-plugin)
   - `plugins/` - Plugin specifications by category
   - `plugins/custom/` - Custom utility modules

2. **Adding new plugins:**
   - Determine category (editor, lsp, git, etc.)
   - Add to appropriate file in `lua/plugins/`
   - Use lazy loading when possible (event, cmd, ft, keys)
   - Test with `:Lazy` UI

3. **Modifying LSP:**
   - Edit `lua/plugins/lsp.lua:149` for servers
   - Edit `lua/plugins/lsp.lua:221` for formatters
   - Don't edit `init.lua` (no LSP config there anymore)

4. **Modifying keybindings:**
   - Core keybindings: `lua/config/keymaps.lua`
   - Plugin-specific: In the plugin's config function

5. **Creating custom utilities:**
   - Create file in `lua/plugins/custom/`
   - Return module table `M`
   - Require with `require 'plugins.custom.filename'`
   - Add keybindings in `config/keymaps.lua`

6. **Testing changes:**

   ```vim
   :source $MYVIMRC          " Reload config
   :Lazy reload <plugin>     " Reload specific plugin
   :checkhealth              " Diagnose issues
   ```

7. **Common tasks:**
   - Add LSP server: `lua/plugins/lsp.lua:149`
   - Add formatter: `lua/plugins/lsp.lua:221`
   - Add git integration: `lua/plugins/git.lua`
   - Add custom utility: `lua/plugins/custom/myutil.lua`
   - Modify options: `lua/config/options.lua`
   - Add autocmds: `lua/config/autocmds.lua`

8. **Documentation updates:**
   - Update this file (CLAUDE.md) for architecture changes
   - Update README.md for user-facing features
   - Update lazy-lock.json after plugin updates
   - Keep file structure diagrams in sync

9. **Health check maintenance:**
   - Check "Health Check Warnings Explained" section above
   - Update if new intentional warnings are added
   - Document any new configuration trade-offs
