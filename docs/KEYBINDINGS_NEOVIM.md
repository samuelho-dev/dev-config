# Neovim Keybindings Reference

> **Generated reference — source of truth is `nvim/lua/config/keymaps.lua` + the
> per-plugin `keys = {}` specs in `nvim/lua/plugins/*.lua`; keep in sync.**

Complete reference for all Neovim keybindings in this configuration.

**Leader Key:** `<Space>`

---

## Custom Features

### Quick Save (controlsave.nvim)

Custom plugin for quick file saving.

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<C-s>` | Save File | Save current file (works in all modes) |

**Features:**
- 🚀 Fast: 1 chord vs 3 keystrokes (`:w<Enter>`)
- 🛡️ Safe: Error handling for read-only/special buffers
- 🔄 Smart: Auto-formats via conform.nvim
- 🌍 Standard: Matches VS Code, IntelliJ, Sublime

**Traditional Vim alternatives:**
- `:w` - Save current file
- `:wa` - Save all files
- `:wq` - Save and quit
- `ZZ` - Save and quit (Vim built-in)

---

### Diagnostic Copy

Copy LSP diagnostics to clipboard for Claude Code workflows.

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>ce` | Copy Errors | Copy only errors to clipboard (grouped with line numbers) |
| `<leader>cd` | Copy Diagnostics | Copy all diagnostics to clipboard (errors, warnings, info grouped by severity) |

**Output Format:**
```
=== Diagnostics for /path/to/file.ts ===

ERRORS:
Line 42: 'foo' is not defined
Line 58: Type 'string' is not assignable to type 'number'

WARNINGS:
Line 12: Unused variable 'bar'
```

---

### Multiple Cursors (vim-visual-multi)
Multiple cursor editing similar to VS Code.

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>m` | Start Multi-Cursor | Select word under cursor, press again for next occurrence |
| `<C-Down>` | Add Cursor Down | Create cursor on line below |
| `<C-Up>` | Add Cursor Up | Create cursor on line above |
| `<C-LeftMouse>` | Add Cursor at Click | Create cursor at mouse position |

**In Multi-Cursor Mode:**
| Keybinding | Action | Description |
|------------|--------|-------------|
| `n` | Next Occurrence | Find and select next occurrence |
| `N` | Previous Occurrence | Find and select previous occurrence |
| `[` | Previous Cursor | Jump to previous cursor |
| `]` | Next Cursor | Jump to next cursor |
| `q` | Skip Current | Skip current and get next occurrence |
| `Q` | Remove Cursor | Remove current cursor/selection |
| `Tab` | Toggle Mode | Switch between cursor and extend mode |
| `<Esc>` | Exit | Exit multi-cursor mode |
| `\\<Space>` | Show Commands | Show all VM commands menu |

**Advanced:**
| Keybinding | Action | Description |
|------------|--------|-------------|
| `\\A` | Select All with Regex | Select all matches using regex pattern |
| `\\\\` | Add Cursor at Position | Add single cursor at current position |
| `\\/` | Start Regex Search | Start regex search for multi-cursor selection |

### Indentation Guides (indent-blankline.nvim)

Visual indentation guides are **always active** - no keybindings needed.

**Commands (if you want to toggle manually):**
| Command | Action | Description |
|---------|--------|-------------|
| `:IBLToggle` | Toggle Guides | Enable/disable indentation guides |
| `:IBLToggleScope` | Toggle Scope | Enable/disable scope highlighting |
| `:IBLEnable` | Enable | Turn on indentation guides |
| `:IBLDisable` | Disable | Turn off indentation guides |

**Features:**
- 🟦 Vertical lines show each indentation level
- 🟨 Current scope/block is highlighted
- ✨ Works on blank lines
- 🎯 Treesitter-aware for accurate scope detection

---

### AI Assistance (avante.nvim)

Cursor-like AI coding assistant powered by LiteLLM proxy for team AI management.

**Commands:**
| Command | Description |
|---------|-------------|
| `:AvanteAsk` | Open chat interface to ask AI about code |
| `:AvanteEdit` | Request AI code edits (applies changes directly to buffer) |
| `:AvanteToggle` | Toggle Avante chat window |

**Keybindings (avante.nvim defaults):**
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>aa` | Quick Ask | Open `:AvanteAsk` with selected text or current line |
| `<leader>ae` | Quick Edit | Open `:AvanteEdit` for AI code modifications |
| `<leader>at` | Toggle Chat | Toggle the Avante sidebar |

**Prerequisites:**
- Plugin loads only when `LITELLM_MASTER_KEY` is set (`nvim/lua/plugins/ai.lua`)
- Points at the LiteLLM proxy endpoint `http://localhost:4000/v1`

**Example Workflow:**
1. Open file to modify: `:e src/components/UserProfile.tsx`
2. Ask AI: `:AvanteAsk What does this component do?`
3. Request edits: `:AvanteEdit Add error handling for API failures`
4. Review and accept/reject changes in diff view

**Cost Tracking:**
All requests go through LiteLLM proxy and are tracked in the dashboard alongside Claude Code usage.

**Documentation:**
See [LiteLLM Proxy Setup](nix/07-litellm-proxy-setup.md) for full configuration details.

---

## Navigation

### Buffer Navigation
| Keybinding | Action |
|------------|--------|
| `<leader><leader>` | Find existing buffers (Telescope) |

### Window Navigation
| Keybinding | Action |
|------------|--------|
| `<C-h>` | Move focus to left window |
| `<C-l>` | Move focus to right window |
| `<C-j>` | Move focus to lower window |
| `<C-k>` | Move focus to upper window |

---

## Telescope (Fuzzy Finder)

### Search
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>sh` | Search Help | Search help documentation |
| `<leader>sk` | Search Keymaps | Search all keybindings |
| `<leader>sf` | Search Files | Find files by name |
| `<leader>ss` | Search Select | Browse all Telescope pickers |
| `<leader>sw` | Search Word | Search current word under cursor |
| `<leader>sg` | Search Grep | Live grep search |
| `<leader>sd` | Search Diagnostics | Search LSP diagnostics |
| `<leader>sr` | Search Resume | Resume last Telescope search |
| `<leader>s.` | Search Recent | Search recently opened files |
| `<leader>sn` | Search Neovim | Search Neovim config files |
| `<leader>/` | Search Buffer | Fuzzy search in current buffer |
| `<leader>s/` | Search Open Files | Live grep in open files only |

**Telescope Navigation (while in picker):**
- `<C-n>` / `<Down>` - Next item
- `<C-p>` / `<Up>` - Previous item
- `<C-c>` / `<Esc>` - Close picker
- `<CR>` - Select item
- `<C-/>` (insert mode) or `?` (normal mode) - Show keymaps help

---

## Search and Replace (Spectre)

Project-wide search and replace with visual preview.

### Opening Spectre
| Keybinding | Mode | Action | Description |
|------------|------|--------|-------------|
| `<leader>rr` | Normal | Replace in Files | Open Spectre for project-wide search/replace |
| `<leader>rw` | Normal | Replace Word | Replace word under cursor across project |
| `<leader>rf` | Normal | Replace in File | Search and replace in current file only |
| `<leader>rw` | Visual | Replace Selection | Replace selected text |

### In Spectre UI (buffer-local)
These mappings are active only inside the Spectre results buffer.

| Keybinding | Action | Description |
|------------|--------|-------------|
| `dd` | Toggle Match | Exclude/include current match |
| `<CR>` | Open File | Open file at match location |
| `<leader>R` | Replace All | Replace all enabled matches |
| `<leader>rc` | Replace Current | Replace current line only |
| `<leader>c` | Replace Command | Input a replace command |
| `<leader>v` | Change View | Toggle Spectre view mode |
| `<leader>o` | Options Menu | Show all options |
| `<leader>q` | To Quickfix | Send matches to quickfix list |
| `<leader>l` | Resume Search | Resume last search |

### Toggle Options (in Spectre UI)
| Keybinding | Action | Description |
|------------|--------|-------------|
| `ti` | Toggle Case | Ignore case on/off |
| `th` | Toggle Hidden | Search hidden files on/off |
| `trs` | Use sed | Switch to sed replace engine |
| `tro` | Use oxi | Switch to oxi replace engine |

**Workflow:**
1. Press `<leader>rr` to open Spectre
2. Enter search pattern (supports regex)
3. Enter replacement text
4. Review matches (use `dd` to toggle off unwanted ones)
5. Press `<leader>R` to replace all

**Features:**
- 🔍 Powered by ripgrep (respects .gitignore)
- 👁️ Preview before replacing
- ⚡ Fast search across entire project
- 🎯 Selective replace (toggle individual matches)
- 📝 Regex support

---

## LSP (Language Server Protocol)

### Code Navigation
| Keybinding | Action | Description |
|------------|--------|-------------|
| `grd` | Goto Definition | Jump to definition of symbol |
| `grr` | Goto References | Find all references |
| `gri` | Goto Implementation | Jump to implementation |
| `grt` | Goto Type Definition | Jump to type definition |
| `grD` | Goto Declaration | Jump to declaration (e.g., header in C) |
| `<C-t>` | Jump Back | Return to previous location (built-in Vim) |

### Code Actions
| Keybinding | Action | Description |
|------------|--------|-------------|
| `grn` | Rename | Rename symbol under cursor |
| `gra` | Code Action | Execute code action (normal & visual mode) |

### Document Navigation
| Keybinding | Action | Description |
|------------|--------|-------------|
| `gO` | Document Symbols | Browse symbols in current file |
| `gW` | Workspace Symbols | Browse symbols in entire project |

### Diagnostics
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>q` | Diagnostic Loclist | Open diagnostic location list (`vim.diagnostic.setloclist`) |
| `<leader>ce` | Copy Errors | Copy errors to clipboard |
| `<leader>cd` | Copy Diagnostics | Copy all diagnostics to clipboard |

### Inlay Hints
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>th` | Toggle Hints | Toggle inlay hints (if LSP supports) |

---

## File Explorer (Neo-tree)

| Keybinding | Action |
|------------|--------|
| `\` | Toggle file tree |
| `<leader>e` | Toggle file tree (alternative) |

**Neo-tree Navigation (when focused):**
- `<CR>` - Open file/folder
- `a` - Add file/directory
- `d` - Delete
- `r` - Rename
- `c` - Copy
- `x` - Cut
- `p` - Paste
- `q` - Close Neo-tree

---

## Harpoon (Quick File Navigation)

Mark and navigate between frequently used files with minimal keystrokes.

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>ha` | Add File | Add current file to Harpoon list |
| `<leader>hm` | Toggle Menu | Open Harpoon quick menu |
| `<leader>h1` | Jump to File 1 | Jump to first marked file |
| `<leader>h2` | Jump to File 2 | Jump to second marked file |
| `<leader>h3` | Jump to File 3 | Jump to third marked file |
| `<leader>h4` | Jump to File 4 | Jump to fourth marked file |
| `<leader>hp` | Previous File | Navigate to previous file in Harpoon list |
| `<leader>hn` | Next File | Navigate to next file in Harpoon list |

**Workflow:**
1. Open a frequently used file
2. Press `<leader>ha` to add it to Harpoon
3. Repeat for other files (up to 4 for quick access via `<leader>h1-4`)
4. Use `<leader>h1/2/3/4` to jump instantly between marked files
5. Use `<leader>hm` to view/edit Harpoon list in menu
6. Use `<leader>hp/hn` to cycle through all marked files

**Use Case:** Perfect for quickly switching between 4-5 files you're actively working on (e.g., component file, test file, types file, config file, documentation).

---

## Formatting

| Keybinding | Action | Mode |
|------------|--------|------|
| `<leader>f` | Format Buffer | Normal, Visual |

**Auto-format on save** is enabled for most file types (except C/C++).

**Formatters (conform.nvim, `nvim/lua/plugins/lsp.lua`):**
- **Lua:** stylua
- **Python:** ruff_format
- **JavaScript/TypeScript/JSON:** biome (`check --fix --unsafe`)
- **YAML/Markdown:** prettier
- **Nix:** alejandra

---

## Completion (Blink.cmp)

### In Insert Mode
| Keybinding | Action |
|------------|--------|
| `<C-y>` | Accept completion |
| `<C-space>` | Open menu or docs |
| `<C-n>` / `<Down>` | Next item |
| `<C-p>` / `<Up>` | Previous item |
| `<C-e>` | Hide menu |
| `<C-k>` | Toggle signature help |
| `<Tab>` | Move to next snippet field |
| `<S-Tab>` | Move to previous snippet field |

---

## Editing

### Surround (mini.surround)
| Keybinding | Action | Example |
|------------|--------|---------|
| `saiw)` | Add surround | Surround word with `()` |
| `sd'` | Delete surround | Remove surrounding `'` quotes |
| `sr)'` | Replace surround | Change `()` to `''` |

### Text Objects (mini.ai)
Enhanced text objects for better selection:
- `va)` - Select around parentheses
- `vi"` - Select inside quotes
- `yinq` - Yank inside next quote

---

## Terminal

| Keybinding | Action |
|------------|--------|
| `<Esc><Esc>` | Exit terminal mode (in terminal buffer) |

---

## General

### Utility
| Keybinding | Action |
|------------|--------|
| `<Esc>` | Clear search highlight |

### Copy Mode
| Keybinding | Action |
|------------|--------|
| `yap` | Yank around paragraph (triggers highlight animation) |

---

## Git Workflow

### Lazygit Integration
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>gg` | LazyGit | Open lazygit TUI (full git workflow) |
| `<leader>gf` | LazyGit Current File | Lazygit filtered to current file |

**Lazygit TUI Features:** Stage, unstage, commit, push, pull, stash, branch management, merge, rebase, cherry-pick.

### GitHub Integration (Octo.nvim)
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>gp` | GitHub PRs | List and manage Pull Requests |
| `<leader>gi` | GitHub Issues | List and manage Issues |

**Requires:** GitHub CLI (`gh`) authenticated.

**In PR/Issue View:** Review code, add comments, approve, request changes, merge - all from Neovim.

### Diff & History (Diffview.nvim)
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>gd` | Diffview Open | Open diff view for changes |
| `<leader>gh` | File History | Show git history for current file |
| `<leader>gH` | Branch History | Show full branch history |

### Merge Conflicts (Git-conflict.nvim)
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>gco` | Choose Ours | Accept "ours" side of conflict |
| `<leader>gct` | Choose Theirs | Accept "theirs" side of conflict |
| `<leader>gcb` | Choose Both | Keep both sides |
| `<leader>gc0` | Choose None | Delete both sides |
| `<leader>gcn` | Next Conflict | Jump to next conflict |
| `<leader>gcp` | Prev Conflict | Jump to previous conflict |
| `<leader>gcl` | List Conflicts | Show all conflicts in quickfix |

---

## Markdown & Note-Taking

### Obsidian Integration
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>ch` | Toggle Checkbox | Toggle markdown checkbox (buffer-local, set when entering a vault note) |

**Dynamic Workspace:** Auto-detects Obsidian vault from file location. No configuration needed!

### Markdown Preview
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>mp` | Markdown Preview | Toggle browser preview with live updates |

### Document Outline (outline.nvim)
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>o` | Toggle Outline | Show/hide document structure outline (global) |

**Works for:** Markdown headings, code symbols (functions, classes, etc.)

> Note: `<leader>o` is the global outline toggle. Inside the Spectre results
> buffer, `<leader>o` is remapped buffer-locally to the Spectre options menu.

---

## Which-key Groups

When you press `<leader>`, which-key will show you available key groups:
- `<leader>s` - **[S]earch** (Telescope)
- `<leader>r` - **[R]eplace** (Spectre - project-wide search & replace)
- `<leader>t` - **[T]oggle** (various toggles)
- `<leader>h` - **Git [H]unk** (Gitsigns - normal & visual)
- `<leader>c` - **[C]opy** (diagnostics - custom)
- `<leader>g` - **[G]it** (lazygit, GitHub, diffview, conflicts)

---

## Plugin Management (Lazy.nvim)

### Commands
| Command | Action |
|---------|--------|
| `:Lazy` | Open plugin manager UI |
| `:Lazy update` | Update all plugins |
| `:Lazy sync` | Install missing + update + clean |
| `:Lazy clean` | Remove unused plugins |

**In Lazy UI:**
- `?` - Show help
- `u` - Update plugins
- `c` - Check for updates
- `x` - Clean (remove unused)

---

## LSP Servers Configured

This configuration includes LSP support for:
- **TypeScript/JavaScript:** `ts_ls`
- **JS/TS/JSON lint + format:** `biome`
- **Python:** `pyright`
- **Lua:** `lua_ls`
- **Nix:** `nixd`

Servers are configured in `nvim/lua/plugins/lsp.lua` (the `servers` table). On
Nix machines the binaries come from `~/.nix-profile/bin` and Mason auto-enable is
off; Mason only installs servers on the non-Nix fallback path.

---

## Useful Commands

### LSP
- `:LspInfo` - Show LSP client info
- `:LspRestart` - Restart LSP server
- `:Mason` - Open Mason UI (only relevant on the non-Nix fallback path; LSP binaries are Nix-managed)

### Diagnostics
- `:checkhealth` - Check Neovim health
- `:messages` - View recent messages (useful for debugging)

### Formatting
- `:ConformInfo` - Show formatting info for current buffer

---

## Tips

1. **Learn which-key:** Press `<leader>` and wait - which-key will show you available keybindings
2. **Explore Telescope:** Press `<leader>ss` to see all available Telescope pickers
3. **LSP Help:** Use `:help lsp` for detailed LSP documentation
4. **Custom Diagnostics:** Use `<leader>ce` to quickly copy errors for pasting into Claude Code

---

## Customization

The Neovim config is modular (`init.lua` is ~81 lines and just bootstraps
lazy.nvim and imports the modules). Add keybindings in the right place:

- **Core (non-plugin) keybindings** → `nvim/lua/config/keymaps.lua`
- **Plugin keybindings** → the plugin's `keys = {}` spec in
  `nvim/lua/plugins/*.lua` (never in `config/keymaps.lua`)
- **LSP buffer-local keybindings** → the `LspAttach` autocmd in
  `nvim/lua/plugins/lsp.lua`
- **A new plugin category** → create `nvim/lua/plugins/<name>.lua` and import it
  in `init.lua`

This file is a generated reference; whenever you change a binding in those
sources, update the matching table here.
