# Neovim Keybindings Reference

Complete reference for all Neovim keybindings in this configuration.

**Leader Key:** `<Space>`

---

## Custom Features

### Diagnostic Copy (NEW)
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
| `<leader>q` | Quickfix List | Open diagnostic quickfix list |
| `<leader>ce` | Copy Errors | **NEW:** Copy errors to clipboard |
| `<leader>cd` | Copy Diagnostics | **NEW:** Copy all diagnostics to clipboard |

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

## Formatting

| Keybinding | Action | Mode |
|------------|--------|------|
| `<leader>f` | Format Buffer | Normal, Visual |

**Auto-format on save** is enabled for most file types (except C/C++).

**Formatters:**
- **Lua:** stylua
- **Python:** ruff
- **JavaScript/TypeScript:** prettier
- **JSON/YAML/Markdown:** prettier

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
| `gf` | Follow Link | Follow wikilink or markdown link |
| `<leader>ch` | Toggle Checkbox | Toggle markdown checkbox |

**Dynamic Workspace:** Auto-detects Obsidian vault from file location. No configuration needed!

### Markdown Preview
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>mp` | Markdown Preview | Toggle browser preview with live updates |

### Document Outline
| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>o` | Toggle Outline | Show/hide document structure outline |

**Works for:** Markdown headings, code symbols (functions, classes, etc.)

---

## Which-key Groups

When you press `<leader>`, which-key will show you available key groups:
- `<leader>s` - **[S]earch** (Telescope)
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
- **Python:** `pyright`
- **Lua:** `lua_ls`

Additional servers can be added in `init.lua` under the `servers` table.

---

## Useful Commands

### LSP
- `:LspInfo` - Show LSP client info
- `:LspRestart` - Restart LSP server
- `:Mason` - Open Mason (LSP installer) UI

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

To add your own keybindings, edit:
```lua
~/Projects/dev-config/nvim/init.lua
```

Or create a new module in:
```lua
~/Projects/dev-config/nvim/lua/custom/plugins/
```

And require it in `init.lua`.
