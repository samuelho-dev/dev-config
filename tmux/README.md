# Tmux Configuration

Terminal multiplexer configuration with plugin ecosystem and Vim integration.

## Overview

This tmux configuration provides:
- **Custom prefix:** `Ctrl+a` (easier to reach than `Ctrl+b`)
- **Vim-style navigation:** Seamless movement between tmux and Neovim
- **Session persistence:** Auto-save and restore sessions
- **Popup windows:** Quick shell, lazygit, session switcher
- **Beautiful theme:** Catppuccin Mocha
- **Enhanced clipboard:** Better copy/paste integration

## Quick Start

### Installation

Tmux plugins are automatically installed during `scripts/install.sh`.

Manual plugin installation:
```bash
# In tmux
Prefix + I  (capital I)
```

### Essential Keybindings

**Prefix:** `Ctrl+a`

| Keybinding | Action |
|------------|--------|
| `Prefix + ?` | Show all keybindings |
| `Prefix + r` | Reload configuration |
| `Prefix + d` | Detach from session |

## Core Features

### Window Management

**Creating:**
- `Prefix + c` - New window
- `Prefix + ,` - Rename window

**Navigating:**
- `Prefix + 0-9` - Go to window by number
- `Prefix + n` - Next window
- `Prefix + p` - Previous window
- `Prefix + l` - Last window

**Organizing:**
- `Prefix + w` - Window tree view (with pane counts)
- `Prefix + W` - Full tree (all sessions/windows/panes)

### Pane Management

**Splitting:**
- `Prefix + |` - Split horizontally (left/right)
- `Prefix + -` - Split vertically (top/bottom)

**Navigating (no prefix!):**
- `Ctrl+h` - Move left
- `Ctrl+j` - Move down
- `Ctrl+k` - Move up
- `Ctrl+l` - Move right

Works seamlessly with Neovim splits!

**Resizing:**
- `Prefix + H` - Resize left
- `Prefix + J` - Resize down
- `Prefix + K` - Resize up
- `Prefix + L` - Resize right

**Organizing:**
- `Prefix + t` - Rename pane title
- `Prefix + x` - Kill pane
- `Prefix + z` - Zoom pane (toggle fullscreen)

### Session Management

**Creating:**
- `tmux new -s name` - Create named session
- `Prefix + m` - New session prompt

**Switching:**
- ``Prefix + ` `` - Session switcher (fzf popup)
- `Prefix + s` - Built-in session tree

**Managing:**
- `Prefix + d` - Detach from session
- `Prefix + X` - Kill session (fzf selector)
- `tmux attach -t name` - Attach to session

**List sessions (from terminal):**
```bash
tmux ls
```

### Popup Windows

**Quick Access:**
- `Prefix + !` - Quick shell (60% × 75%)
- ``Prefix + ` `` - Session switcher with fzf
- `Prefix + g` - Lazygit (80% × 80%)

Popups overlay the current session and close when you exit.

### Copy Mode

**Enter copy mode:**
- `Prefix + [`

**Vi-style navigation:**
- `h/j/k/l` - Move cursor
- `v` - Begin selection
- `V` - Select line
- `Ctrl+v` - Rectangle selection
- `y` - Copy to clipboard
- `q` or `Esc` - Exit copy mode

**Search:**
- `/` - Search forward
- `?` - Search backward
- `n` - Next match
- `N` - Previous match

### Session Persistence

**Manual:**
- `Prefix + Ctrl+s` - Save session
- `Prefix + Ctrl+r` - Restore session

**Automatic:**
- Auto-save every 60 minutes
- Auto-restore on tmux start

Survives reboots! Sessions are saved to `~/.tmux/resurrect/`.

## Plugins

### vim-tmux-navigator

Seamless navigation between Neovim splits and tmux panes.

- `Ctrl+h/j/k/l` - Navigate (works in both Neovim and tmux!)
- No prefix needed
- Automatically detects if you're in Vim

### tmux-fzf

Fuzzy finder for tmux objects.

- ``Prefix + ` `` - Quick session switcher
- Fuzzy search sessions, windows, panes

### tmux-resurrect + tmux-continuum

Session persistence across reboots.

- **Resurrect:** Manual save/restore
- **Continuum:** Automatic save every 60 minutes
- **Auto-restore:** Sessions restored on tmux start

### Catppuccin Theme

Beautiful Mocha theme for status bar and panes.

Other flavors available: frappe, macchiato, latte

### tmux-yank

Enhanced clipboard integration.

- Better copy/paste across platforms
- Works with `y` in copy mode

## Configuration

### Changing Prefix Key

Edit `tmux.conf` line 48:
```bash
set-option -g prefix C-b  # Change back to C-b if preferred
```

Reload: `Prefix + r`

### Changing Theme

Edit `tmux.conf` line 196:
```bash
set -g @catppuccin_flavour 'latte'  # Light theme
```

Reload: `Prefix + r`

### Adding Custom Keybindings

Add to `tmux.conf`:
```bash
# Example: Toggle synchronize panes
bind S set-window-option synchronize-panes

# Example: New window in current directory
bind c new-window -c "#{pane_current_path}"
```

Reload: `Prefix + r`

### Adding Plugins

1. Add to `tmux.conf` after line 173:
   ```bash
   set -g @plugin 'author/plugin-name'
   ```

2. Reload: `Prefix + r`
3. Install: `Prefix + I` (capital I)

## Plugin Management (TPM)

| Command | Action |
|---------|--------|
| `Prefix + I` | Install new plugins |
| `Prefix + U` | Update all plugins |
| `Prefix + Alt+u` | Remove unlisted plugins |

## Reload Configuration

**After editing `tmux.conf`:**

```bash
# Method 1: Keybinding
Prefix + r

# Method 2: Command line
tmux source-file ~/.tmux.conf
```

Changes apply immediately!

## Troubleshooting

### Plugins not installing

```bash
# Check TPM installed
ls ~/.tmux/plugins/tpm

# If missing, reinstall
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Then in tmux
Prefix + r
Prefix + I
```

### vim-tmux-navigator not working

1. Ensure plugin installed: `ls ~/.tmux/plugins/vim-tmux-navigator`
2. Restart tmux: `tmux kill-server && tmux`
3. Ensure Neovim has matching keybindings (already configured)

### Colors look wrong

Check terminal supports true color:
```bash
echo $TERM  # Should be tmux-256color
```

### Session not restoring

Check saved sessions:
```bash
ls ~/.tmux/resurrect/
```

Manually restore: `Prefix + Ctrl+r`

## Tips & Tricks

### Rename Session

```bash
tmux rename-session new-name

# Or in tmux
Prefix + $
```

### Kill All Sessions Except Current

```bash
tmux kill-session -a
```

### Detach All Clients Except Current

```bash
tmux detach-client -a
```

### Synchronize Panes

Send commands to all panes simultaneously:
```
:setw synchronize-panes on
:setw synchronize-panes off
```

### Swap Windows

```bash
# Swap current window with window 1
:swap-window -t 1
```

## Resources

- Full keybindings: `docs/KEYBINDINGS_TMUX.md` in repository root
- TPM: https://github.com/tmux-plugins/tpm
- vim-tmux-navigator: https://github.com/christoomey/vim-tmux-navigator
- Catppuccin theme: https://github.com/catppuccin/tmux
- Official tmux manual: `man tmux`
