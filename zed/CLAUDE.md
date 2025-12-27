---
scope: zed/
updated: 2025-12-24
relates_to:
  - ../CLAUDE.md
  - ../biome.json
  - ../nvim/CLAUDE.md
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with Zed editor configuration in this directory.

## Purpose

This directory contains **Zed editor configuration** optimized for the dev-config workflow. The configuration mirrors Neovim keybindings and integrates with Biome for consistent formatting/linting.

## File Structure

```
zed/
+-- settings.json     # Editor settings, formatters, LSP config
+-- keymap.json       # Vim-style keybindings (LazyVim-inspired)
```

**Symlink location:**
- `~/.config/zed/settings.json`
- `~/.config/zed/keymap.json`

## Configuration Overview

### settings.json

#### Core Settings
```json
{
  "vim_mode": true,
  "relative_line_numbers": true,
  "cursor_blink": false,
  "format_on_save": "on",
  "buffer_font_family": "JetBrainsMono Nerd Font",
  "buffer_font_size": 14
}
```

#### Biome Integration

Biome is the primary formatter/linter for TypeScript, JavaScript, TSX, and JSON:

```json
{
  "lsp": {
    "biome": {
      "settings": {
        "config_path": "~/.config/biome/biome.json"
      }
    }
  }
}
```

**Auto-fix on save** enabled for:
- `source.fixAll.biome` - Apply all auto-fixable lint rules
- `source.organizeImports.biome` - Sort and organize imports

#### Language Formatters

| Language | Formatter | Notes |
|----------|-----------|-------|
| TypeScript | Biome | Auto-fix + organize imports |
| TSX | Biome | Auto-fix + organize imports |
| JavaScript | Biome | Auto-fix + organize imports |
| JSON | Biome | Auto-fix only |
| Lua | stylua | External formatter |
| Python | ruff | External formatter |
| YAML | prettier | External formatter |
| Markdown | prettier | External formatter |

### keymap.json

Keybindings designed to match LazyVim/Neovim muscle memory.

#### Space Leader Bindings (Normal/Visual Mode)

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Space s f` | file_finder::Toggle | Find files (like Telescope) |
| `Space s g` | pane::DeploySearch | Global search (grep) |
| `Space s d` | diagnostics::Deploy | Show diagnostics |
| `Space Space` | tab_switcher::Toggle | Switch buffers |
| `Space /` | buffer_search::Deploy | Search in buffer |
| `Space e` | project_panel::ToggleFocus | Toggle file explorer |
| `\` | project_panel::ToggleFocus | Alt toggle for explorer |
| `Space f` | editor::Format | Format document |
| `Space g g` | git_panel::ToggleFocus | Toggle git panel |
| `Space t` | terminal_panel::ToggleFocus | Toggle terminal |
| `Space q` | pane::CloseActiveItem | Close current tab |

#### Go-to Bindings (Normal Mode)

| Keybinding | Action | Description |
|------------|--------|-------------|
| `g r d` | editor::GoToDefinition | Go to definition |
| `g r r` | editor::FindAllReferences | Find all references |
| `g r i` | editor::GoToImplementation | Go to implementation |
| `g r n` | editor::Rename | Rename symbol |
| `g r a` | editor::ToggleCodeActions | Code actions menu |
| `g Shift-o` | outline::Toggle | Toggle outline view |
| `] d` | editor::GoToDiagnostic | Next diagnostic |
| `[ d` | editor::GoToPrevDiagnostic | Previous diagnostic |

#### Pane Navigation (Normal Mode)

| Keybinding | Action | Description |
|------------|--------|-------------|
| `Ctrl-h` | workspace::ActivatePaneLeft | Focus left pane |
| `Ctrl-j` | workspace::ActivatePaneDown | Focus down pane |
| `Ctrl-k` | workspace::ActivatePaneUp | Focus up pane |
| `Ctrl-l` | workspace::ActivatePaneRight | Focus right pane |

#### Project Panel Bindings

| Keybinding | Action | Description |
|------------|--------|-------------|
| `h` | CollapseSelectedEntry | Collapse folder |
| `j` | menu::SelectNext | Move down |
| `k` | menu::SelectPrev | Move up |
| `l` | ExpandSelectedEntry | Expand folder |
| `Enter` | project_panel::Open | Open file |
| `a` | project_panel::NewFile | Create file |
| `Shift-a` | project_panel::NewDirectory | Create directory |
| `r` | project_panel::Rename | Rename |
| `d` | project_panel::Delete | Delete |
| `q` | workspace::ToggleLeftDock | Close panel |

## Making Changes

### Edit Settings
```bash
nvim ~/Projects/dev-config/zed/settings.json
```

Changes take effect after restarting Zed.

### Add Language Formatter

```json
{
  "languages": {
    "NewLanguage": {
      "formatter": {
        "external": {
          "command": "formatter-name",
          "arguments": ["--stdin-filepath", "{buffer_path}", "-"]
        }
      }
    }
  }
}
```

### Add Keybinding

```json
{
  "context": "Editor && vim_mode == normal && !menu",
  "bindings": {
    "space n": "your::Action"
  }
}
```

## Relationship with Neovim

This Zed config mirrors the Neovim setup:

| Feature | Neovim | Zed |
|---------|--------|-----|
| Leader key | `Space` | `Space` |
| File finder | `Space s f` (Telescope) | `Space s f` |
| File explorer | `Space e` (neo-tree) | `Space e` |
| Format | `Space f` | `Space f` |
| Pane nav | `Ctrl-h/j/k/l` | `Ctrl-h/j/k/l` |

This allows switching between editors without relearning keybindings.

## For Future Claude Code Instances

When working with this configuration:

- [ ] Keep keybindings in sync with `nvim/lua/config/keymaps.lua`
- [ ] Use Biome config path `~/.config/biome/biome.json` for consistency
- [ ] Add new languages to `languages` section with external formatter
- [ ] Test keybindings after changes by restarting Zed
- [ ] Update this file when adding significant new configurations
