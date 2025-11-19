# Tmux Keybindings Reference

Complete reference for all tmux keybindings in this configuration.

**Prefix Key:** `Ctrl+a` (instead of default `Ctrl+b`)

---

## Quick Reference

### Essential Commands
| Keybinding | Action |
|------------|--------|
| `Ctrl+a` | Prefix key (press before any tmux command) |
| `Prefix + ?` | Show all keybindings |
| `Prefix + r` | Reload tmux configuration |
| `Prefix + d` | Detach from session |

---

## Session Management

| Keybinding | Action | Description |
|------------|--------|-------------|
| `tmux` | Start tmux | Create new session |
| `tmux new -s name` | Create named session | Start session with specific name |
| `tmux ls` | List sessions | Show all active sessions |
| `tmux attach -t name` | Attach to session | Connect to specific session |
| `Prefix + d` | Detach | Leave session running in background |
| `Prefix + m` | New session prompt | Create new session (custom binding) |
| ``Prefix + ` `` | Session switcher | fzf-based session selector |
| `Prefix + X` | Kill session | fzf-based session deletion |
| `Prefix + s` | Choose session | Built-in session tree view |

---

## Window Management

### Creating and Navigating Windows
| Keybinding | Action | Description |
|------------|--------|-------------|
| `Prefix + c` | Create window | New window in current session |
| `Prefix + ,` | Rename window | Give window a meaningful name |
| `Prefix + &` | Kill window | Close current window (with confirmation) |
| `Prefix + n` | Next window | Move to next window |
| `Prefix + p` | Previous window | Move to previous window |
| `Prefix + 0-9` | Select window | Jump to window by number |
| `Prefix + l` | Last window | Toggle between two recent windows |
| `Prefix + w` | Window tree view | Enhanced tree with pane counts and titles |
| `Prefix + W` | Full tree view | All sessions, windows, and panes |

**Note:** Windows are numbered starting from 1 (not 0) in this config.

---

## Pane Management

### Creating Panes
| Keybinding | Action | Description |
|------------|--------|-------------|
| `Prefix + \|` | Split horizontal | Create pane to the right |
| `Prefix + -` | Split vertical | Create pane below |
| `Prefix + x` | Kill pane | Close current pane (with confirmation) |

### Navigating Panes (vim-tmux-navigator)
| Keybinding | Action | Description |
|------------|--------|-------------|
| `Ctrl+h` | Move left | Navigate to left pane (or Vim split) |
| `Ctrl+j` | Move down | Navigate to lower pane (or Vim split) |
| `Ctrl+k` | Move up | Navigate to upper pane (or Vim split) |
| `Ctrl+l` | Move right | Navigate to right pane (or Vim split) |

**Seamless Vim Integration:** These keybindings work across both tmux panes and Neovim splits without needing the prefix key!

### Resizing Panes
| Keybinding | Action | Description |
|------------|--------|-------------|
| `Prefix + H` | Resize left | Make pane wider (left) by 5 columns |
| `Prefix + J` | Resize down | Make pane taller (down) by 5 rows |
| `Prefix + K` | Resize up | Make pane taller (up) by 5 rows |
| `Prefix + L` | Resize right | Make pane wider (right) by 5 columns |

**Note:** These bindings are repeatable - hold prefix and press multiple times.

### Pane Utilities
| Keybinding | Action | Description |
|------------|--------|-------------|
| `Prefix + t` | Set pane title | Give pane a descriptive title |
| `Prefix + z` | Zoom pane | Toggle full-screen for current pane |
| `Prefix + q` | Show pane numbers | Display pane numbers briefly |

---

## Copy Mode (Vi-style)

### Entering Copy Mode
| Keybinding | Action |
|------------|--------|
| `Prefix + [` | Enter copy mode |
| `Prefix + Enter` | Enter copy mode (custom) |
| `q` | Exit copy mode |

### Navigation in Copy Mode
| Keybinding | Action | Description |
|------------|--------|-------------|
| `h/j/k/l` | Move cursor | Vim-style navigation |
| `w/b` | Word forward/back | Jump by word |
| `0/$` | Line start/end | Beginning/end of line |
| `g/G` | Buffer start/end | Top/bottom of scrollback |
| `Ctrl+u/d` | Scroll half page | Up/down |
| `/` | Search forward | Search in scrollback |
| `?` | Search backward | Reverse search |
| `n/N` | Next/previous match | Cycle through search results |

### Selecting and Copying
| Keybinding | Action | Description |
|------------|--------|-------------|
| `v` | Begin selection | Start visual selection |
| `V` | Line selection | Select entire lines |
| `Ctrl+v` | Rectangle selection | Block visual selection |
| `y` | Copy (yank) | Copy selection to clipboard |
| `Enter` | Copy and exit | Copy and leave copy mode |

**macOS Clipboard:** Copies automatically integrate with system clipboard via `pbcopy`.

---

## Popup Windows

### Quick Popups
| Keybinding | Action | Description |
|------------|--------|-------------|
| `Prefix + !` | Shell popup | Quick shell (60% width, 75% height) |
| ``Prefix + ` `` | Session switcher | fzf session selector popup |
| `Prefix + g` | Lazygit popup | Full git TUI (80% width/height) |

**Note:** Lazygit popup requires `lazygit` to be installed.

---

## Plugins (TPM - Tmux Plugin Manager)

### Plugin Management
| Keybinding | Action | Description |
|------------|--------|-------------|
| `Prefix + I` | Install plugins | Install new plugins from config |
| `Prefix + U` | Update plugins | Update all installed plugins |
| `Prefix + Alt+u` | Uninstall plugins | Remove plugins not in config |

### Installed Plugins

**vim-tmux-navigator**
- Seamless navigation between vim and tmux panes
- `Ctrl+h/j/k/l` to navigate

**tmux-resurrect**
- `Prefix + Ctrl+s` - Save tmux environment
- `Prefix + Ctrl+r` - Restore tmux environment

**tmux-continuum**
- Automatic saving every 60 minutes
- Auto-restore on tmux start (configured)

**tmux-yank**
- Enhanced clipboard integration
- Works with tmux copy mode

**tmux-fzf**
- Provides fzf-based pickers for various tmux commands
- Session switcher popup (`` Prefix + ` ``)

**catppuccin/tmux**
- Mocha flavor theme
- Provides beautiful status bar

---

## Configuration Details

### Settings
- **Base index:** Windows and panes start at 1 (not 0)
- **Mouse support:** Enabled
- **History limit:** 10,000 lines
- **Escape time:** 0ms (no delay)
- **Repeat time:** 300ms for repeatable commands

### Status Bar
- **Position:** Bottom
- **Update interval:** 5 seconds (+ auto-refresh on pane switch)
- **Left side:** Session name, window index, pane index, pane title
- **Right side:** Hostname, time, date

### Pane Border
- **Status:** Top (shows pane title, number, and git status)
- **Active border:** Cyan
- **Inactive border:** Gray
- **Git status:** Shows branch, ahead/behind, staged, modified files
  - Example: `1: editor ⎇ feature-x ↑2 ●3 ✚1`
  - Symbols: ⎇ (branch), ↑ (ahead), ↓ (behind), ● (staged), ✖ (conflict), ✚ (modified), … (untracked), ⚑ (stash)
  - Only shows when in a git repository

---

## Common Workflows

### Start New Project
```bash
tmux new -s project-name
Prefix + |          # Split pane for editor
Ctrl+h              # Navigate to left pane
Prefix + -          # Split for logs
```

### Git Workflow with Lazygit
```bash
Prefix + g          # Open lazygit popup
# Use lazygit to stage, commit, push
Esc                 # Close popup
```

### Session Switching
```bash
Prefix + `          # Opens fzf session switcher
# Type to filter, Enter to switch
```

### Save and Restore Sessions
```bash
Prefix + Ctrl+s     # Save current session
# Kill tmux server or reboot
tmux                # Start tmux
Prefix + Ctrl+r     # Restore session
```

### Git Worktree Workflow (Multiple Branches)
```bash
# Window 1: feature-x
Prefix + |          # Split pane
# Pane borders show: "⎇ feature-x ●2 ✚1"
nvim src/main.js    # Edit in feature-x branch

# Window 2: feature-y (different worktree)
Prefix + c          # New window
cd ~/worktrees/feature-y
# Pane border shows: "⎇ feature-y ↑3"
nvim src/other.js   # Edit in feature-y branch

# Each pane knows which branch it's in via pane border
# Claude Code instances are isolated per pane automatically
```

**Note:** Set `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1` in your shell config to keep Claude Code instances isolated to their starting directory. This prevents directory changes in one pane from affecting Claude instances in other panes.

---

## Troubleshooting

### Plugins Not Installing
1. Ensure TPM is installed: `ls ~/.tmux/plugins/tpm`
2. Install if missing: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
3. Reload config: `Prefix + r`
4. Install plugins: `Prefix + I`

### vim-tmux-navigator Not Working
1. Ensure plugin is installed in both Neovim and tmux
2. Restart both tmux and Neovim
3. Check Neovim has the plugin configured

### Config Changes Not Applied
```bash
Prefix + r                     # Reload config
# Or restart tmux server:
tmux kill-server
```

### Pane Border Titles Not Showing
Set pane title manually: `Prefix + t` and enter a title

### Git Status Not Showing in Pane Borders
1. Check if gitmux is installed:
   ```bash
   which gitmux
   # Should return: /usr/local/bin/gitmux or /opt/homebrew/bin/gitmux
   ```

2. Install if missing:
   ```bash
   brew install gitmux  # macOS
   ```

3. Check gitmux config symlink:
   ```bash
   ls -la ~/.gitmux.conf
   # Should point to ~/Projects/dev-config/tmux/gitmux.conf
   ```

4. Test gitmux manually:
   ```bash
   cd ~/your-git-repo
   gitmux -cfg ~/.gitmux.conf $(pwd)
   # Should output: ⎇ branch-name ...
   ```

5. Reload tmux: `Prefix + r`

**Note:** Git status only shows when the pane's current directory is inside a git repository.

---

## Customization

### Add New Plugin
Edit `~/Projects/dev-config/tmux/tmux.conf`:
```tmux
set -g @plugin 'author/plugin-name'
```
Then: `Prefix + r` to reload, `Prefix + I` to install

### Change Prefix Key
Edit `tmux.conf`:
```tmux
unbind C-a
set-option -g prefix C-<your-key>
bind-key C-<your-key> send-prefix
```

### Customize Split Keys
Edit `tmux.conf`:
```tmux
bind <key> split-window -h -c "#{pane_current_path}"
bind <key> split-window -v -c "#{pane_current_path}"
```

---

## Resources

- [Tmux GitHub](https://github.com/tmux/tmux)
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [TPM (Plugin Manager)](https://github.com/tmux-plugins/tpm)
- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)

---

## Tips

1. **Learn the prefix key:** Everything in tmux requires `Ctrl+a` first
2. **Use vim-tmux-navigator:** Seamless navigation without prefix
3. **Name your sessions:** `tmux new -s meaningful-name`
4. **Set pane titles:** `Prefix + t` for better organization
5. **Lazygit integration:** `Prefix + g` for quick git operations
6. **Save your work:** `Prefix + Ctrl+s` before logging out
7. **Check pane borders:** Shows git branch and status - know which worktree you're in!
8. **Git worktrees:** Each pane shows its own branch - prevents accidents
9. **Claude Code isolation:** Set `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1` to keep instances isolated
10. **Launch from correct directory:** `cd` into the worktree before running `claude`
