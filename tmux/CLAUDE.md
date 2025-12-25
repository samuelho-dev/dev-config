---
scope: tmux/
updated: 2025-12-24
relates_to:
  - ../CLAUDE.md
  - ../modules/home-manager/programs/tmux.nix
  - ../docs/KEYBINDINGS_TMUX.md
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with tmux configuration in this directory.

## Architecture Overview

Single-file tmux configuration (~200 lines) with extensive plugin ecosystem managed by TPM (Tmux Plugin Manager).

## File Structure

```
tmux/
+-- tmux.conf          # Complete tmux configuration
+-- gitmux.conf        # Git status formatting configuration
```

**Symlink locations:**
- `~/.tmux.conf` → `~/Projects/dev-config/tmux/tmux.conf`
- `~/.gitmux.conf` → `~/Projects/dev-config/tmux/gitmux.conf`

## Configuration Sections

The file is organized into logical sections:

### General Settings (lines 1-42)
- Terminal colors: `tmux-256color` with true color support
- Mouse support: Enabled
- Base index: 1 (windows and panes)
- Auto renumber windows
- Scrollback: 10,000 lines
- Escape time: 0 (no delay)
- Repeat time: 300ms
- Focus events: Enabled
- Aggressive resize: Enabled

### Key Bindings (lines 44-83)
**Prefix:** `C-a` (instead of default `C-b`)

**Core bindings:**
- `Prefix + r` - Reload configuration
- `Prefix + |` - Split horizontally
- `Prefix + -` - Split vertically
- `Prefix + H/J/K/L` - Resize panes (repeatable)
- `Prefix + t` - Rename pane title
- `Prefix + w` - Enhanced window tree
- `Prefix + W` - Full session/window/pane tree

**Note:** Pane navigation (`h/j/k/l`) is handled by vim-tmux-navigator plugin (lines 61-62).

### Copy Mode Settings (lines 85-104)
- Vi-style keybindings
- `v` - Begin selection
- `V` - Select line
- `C-v` - Rectangle toggle
- `y` - Copy to clipboard (macOS: pbcopy)
- Mouse drag also copies

### Claude Code + Git Worktree Workflow

**Purpose:** Run multiple isolated Claude Code instances in different tmux panes, each working on a separate git worktree/branch.

**The Problem:**
When running multiple Claude Code instances in different panes without proper isolation, directory changes in one instance can affect others, leading to commands being executed in the wrong worktree.

**The Solution:**
Use `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1` environment variable to lock each Claude instance to its starting directory.

**Configuration:**
Set in `zsh/.zshrc` (lines 137-139):
```bash
# Claude Code: Maintain working directory per pane (prevents directory switching)
# Critical for git worktree workflows with multiple Claude instances
export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1
```

**How it works:**
- Each tmux pane maintains its own working directory (tmux default behavior)
- Claude Code respects the environment variable and stays in its starting directory
- Git status shown in pane borders (via gitmux) so you always know which worktree/branch you're in
- No accidental directory switching between instances

**Usage example:**
```bash
# Pane 1: Main branch
cd ~/Projects/dev-config
claude  # Works on main branch

# Pane 2: Feature worktree (Prefix + |)
cd ~/Projects/dev-config-worktrees/feature-x
claude  # Works on feature-x branch, isolated from Pane 1

# Pane 3: Another feature worktree (Prefix + |)
cd ~/Projects/dev-config-worktrees/feature-y
claude  # Works on feature-y branch, isolated from Panes 1 and 2

# Each pane shows its git branch in the border:
# 1: main ⎇ main ✔
# 2: feature-x ⎇ feature-x ●2 ✚1
# 3: feature-y ⎇ feature-y ↑3
```

**Benefits:**
- ✅ Each Claude instance isolated to its own worktree
- ✅ No accidental cross-worktree command execution
- ✅ Git branch/status visible in each pane border
- ✅ Official Claude Code environment variable (documented)
- ✅ Works automatically - no manual setup per pane

### Status Bar Configuration (lines 106-137)
- Position: Bottom
- Update interval: 5 seconds + auto-refresh on pane switch
- Colors: Overridden by Catppuccin theme (see plugins)
- Left: `#S #I #P:#{pane_title}` (session, window, pane, title)
- Right: `#H %H:%M %d-%b-%y` (hostname, time, date)
- Pane borders: Titles shown on top + **git status** (via gitmux)
  - Format: `#P: #{pane_title} + git status`
  - Git status shows: branch, ahead/behind, staged, modified, conflicts
  - Auto-updates every 5 seconds + on pane switch
  - Example: `1: editor ⎇ feature-x ↑2 ●3 ✚1`
  - **Critical for git worktree workflows** - always shows which branch/worktree you're in

### Popup Windows (lines 139-156)
**Popups** are floating windows overlaid on current session.

- `Prefix + !` - Quick shell popup (60% × 75%)
- `Prefix + m` - New session prompt
- ``Prefix + ` `` - Session switcher (fzf) (60% × 50%)
- `Prefix + X` - Kill session (fzf)
- `Prefix + g` - Lazygit popup (80% × 80%)

All use `display-popup -E` for automatic closure on command exit.

### Plugin Manager Configuration (lines 158-199)

**Plugin list (lines 173-189):**
1. `tpm` - Plugin manager itself
2. `tmux-sensible` - Sensible defaults
3. `tmux-resurrect` - Save/restore sessions
4. `tmux-continuum` - Auto-save sessions
5. `tmux-battery` - Battery indicator
6. `tmux-cpu` - CPU usage indicator
7. `catppuccin/tmux` - Mocha theme
8. `vim-tmux-navigator` - Seamless Vim/tmux navigation
9. `tmux-yank` - Enhanced clipboard
10. `sainnhe/tmux-fzf` - Fuzzy finder integration

**Plugin settings (lines 191-196):**
- Resurrect: Capture pane contents
- Continuum: Auto-restore on start, save every 60 minutes
- Catppuccin: Mocha flavor

**TPM initialization (line 199):**
```bash
run '~/.tmux/plugins/tpm/tpm'
```
Must be at the **very bottom** of the file.

## Critical Plugins

### vim-tmux-navigator

**Purpose:** Seamless navigation between Neovim splits and tmux panes.

**Keybindings (no prefix needed):**
- `C-h` - Navigate left
- `C-j` - Navigate down
- `C-k` - Navigate up
- `C-l` - Navigate right

Works in both Neovim and tmux!

**Implementation:** Plugin overrides tmux pane navigation to check if current pane is running Vim. If so, sends keys to Vim; otherwise, navigates tmux panes.

**Neovim counterpart:** Neovim must have matching keybindings (already configured in `nvim/init.lua:197-200`).

### tmux-resurrect + tmux-continuum

**Purpose:** Persist sessions across reboots.

**Manual commands:**
- `Prefix + C-s` - Save session manually
- `Prefix + C-r` - Restore session manually

**Automatic:**
- Auto-save every 60 minutes (configurable)
- Auto-restore on tmux start

**What's saved:**
- Panes, windows, layouts
- Working directories
- Pane contents (with `capture-pane-contents`)
- Running programs

**Location:** `~/.tmux/resurrect/`

### tmux-fzf

**Purpose:** Fuzzy finder for tmux objects.

**Keybinding:** ``Prefix + ` ``

**Features:**
- Search sessions
- Search windows
- Search panes
- Search commands
- Manage keybindings

**Custom binding (line 150):**
```bash
bind ` display-popup -E -w 60% -h 50% "tmux list-sessions | fzf --reverse --header='Select session:' | cut -d: -f1 | xargs tmux switch-client -t"
```

Creates a popup session switcher.

### catppuccin/tmux

**Purpose:** Beautiful theme with Mocha flavor.

**Configuration:** `set -g @catppuccin_flavour 'mocha'`

**Other flavors:** frappe, macchiato, latte

**What it styles:**
- Status bar
- Window status
- Pane borders
- Message area
- Copy mode

## Adding Plugins

1. **Add to plugin list:**
   ```bash
   set -g @plugin 'author/plugin-name'
   ```

2. **Reload config:**
   ```
   Prefix + r
   ```

3. **Install plugin:**
   ```
   Prefix + I  (capital I)
   ```

4. **Commit changes:**
   ```bash
   git add tmux/tmux.conf
   git commit -m "Add tmux plugin: plugin-name"
   ```

## TPM Commands

| Command | Action |
|---------|--------|
| `Prefix + I` | Install new plugins |
| `Prefix + U` | Update all plugins |
| `Prefix + Alt+u` | Remove unlisted plugins |

## Customizing Configuration

### Changing Prefix Key

Edit line 48:
```bash
set-option -g prefix C-b  # Change to C-b or any other key
```

### Changing Theme

Edit line 196:
```bash
set -g @catppuccin_flavour 'latte'  # Light theme
```

Reload with `Prefix + r`.

### Adding Custom Keybindings

Add after line 83:
```bash
# Example: Create new window in current directory
bind c new-window -c "#{pane_current_path}"

# Example: Kill pane without confirmation
bind x kill-pane

# Example: Toggle synchronize panes
bind S set-window-option synchronize-panes
```

### Adjusting Status Bar

Edit lines 119-128:
```bash
set -g status-left-length 100
set -g status-left "#[fg=blue]Session: #S | Window: #I | Pane: #P"

set -g status-right "#[fg=green]%H:%M:%S #[fg=yellow]%d-%b-%Y"
```

### Changing Popup Sizes

Edit lines 143-161:
```bash
bind ! display-popup -E -w 80% -h 80%  # Larger shell popup
bind g display-popup -E -w 100% -h 100%  # Full-screen lazygit
```

## Platform-Specific Features

### macOS Clipboard Integration (lines 97-100)

```bash
if-shell "uname | grep -q Darwin" {
  bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"
  bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "pbcopy"
}
```

Uses `pbcopy` on macOS. On Linux, tmux-yank plugin handles clipboard automatically.

### Conditional Plugin Features (lines 149-161)

```bash
if-shell "command -v fzf" {
  bind ` display-popup ...
}
```

Only binds keybinding if `fzf` is installed. Graceful degradation.

## Reload Configuration

**Method 1:** Keybinding
```
Prefix + r
```

**Method 2:** Command line
```bash
tmux source-file ~/.tmux.conf
```

**Method 3:** From tmux command mode
```
: source-file ~/.tmux.conf
```

Changes take effect immediately!

## Troubleshooting

### Plugins not installing

1. Check TPM installed:
   ```bash
   ls ~/.tmux/plugins/tpm
   ```

2. If missing:
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

3. Reload and install:
   ```
   Prefix + r
   Prefix + I
   ```

### vim-tmux-navigator not working

1. Ensure plugin installed: `ls ~/.tmux/plugins/vim-tmux-navigator`
2. Check Neovim has matching keybindings (already configured)
3. Restart tmux: `tmux kill-server && tmux`

### Colors not working

Check terminal supports true color:
```bash
echo $TERM  # Should be tmux-256color or similar
```

Add to shell rc:
```bash
export TERM=tmux-256color
```

### Resurrect not restoring

Check saved sessions:
```bash
ls ~/.tmux/resurrect/
```

Manually restore:
```
Prefix + C-r
```

### Git status not showing

1. Check gitmux installed:
   ```bash
   which gitmux  # Should return a path
   brew install gitmux  # If missing
   ```

2. Check gitmux.conf symlink:
   ```bash
   ls -la ~/.gitmux.conf
   # Should point to ~/Projects/dev-config/tmux/gitmux.conf
   ```

3. Test gitmux manually:
   ```bash
   gitmux -cfg ~/.gitmux.conf $(pwd)
   ```

4. Reload tmux:
   ```
   Prefix + r
   ```

## Git Worktree Integration

**Critical for working with multiple git worktrees in separate panes!**

### gitmux Configuration

**Purpose:** Display git branch and status in each pane border, so you always know which worktree/branch you're working on.

**Configuration file:** `tmux/gitmux.conf` (symlinked to `~/.gitmux.conf`)

**Features:**
- **Per-pane git status:** Each pane shows its own git branch and changes
- **Catppuccin Mocha colors:** Matches tmux theme
- **Compact format:** Optimized for pane borders
- **Auto-refresh:** Updates every 5 seconds + on pane switch

**Symbols:**
- `⎇ branch-name` - Current git branch
- `↑2` - 2 commits ahead of remote
- `↓1` - 1 commit behind remote
- `●3` - 3 staged files
- `✖1` - 1 merge conflict
- `✚2` - 2 modified files
- `…4` - 4 untracked files
- `⚑1` - 1 stash
- `✔` - Clean working directory

**Example pane border:**
```
┌─ 1: editor ⎇ feature-x ↑2 ●3 ✚1 ─┐
│ $ nvim src/main.js                │
└────────────────────────────────────┘
```

Meaning: Pane 1, titled "editor", on branch "feature-x", 2 commits ahead, 3 staged files, 1 modified file.

**Customizing:**
Edit `tmux/gitmux.conf` to change:
- Colors (Catppuccin palette)
- Symbols (branch, staged, modified, etc.)
- Layout (order of elements)
- Options (branch max length, hide clean state)

**Implementation:**
```bash
# In tmux.conf
set -g pane-border-format "#P: #{pane_title} #(gitmux -cfg ~/.gitmux.conf '#{pane_current_path}')"
```

### Typical Git Worktree Workflow with Claude Code

**Scenario:** Working on 3 features simultaneously

```
Window 1: feature-x
  Pane 1: editor    ⎇ feature-x ●2 ✚1
  Pane 2: terminal  ⎇ feature-x
  Pane 3: lazygit   ⎇ feature-x

Window 2: feature-y
  Pane 1: editor    ⎇ feature-y ↑3
  Pane 2: terminal  ⎇ feature-y

Window 3: main
  Pane 1: editor    ⎇ main ✔
  Pane 2: tests     ⎇ main
```

**Benefits:**
- ✅ See branch/worktree at a glance in pane borders
- ✅ Each Claude Code instance isolated to its own worktree
- ✅ No accidentally running commands in wrong worktree
- ✅ Multiple features developed in parallel without conflicts
- ✅ Git status auto-updates to show current state

## Best Practices

1. **Always reload** after editing: `Prefix + r`
2. **Keep TPM line at bottom** of file (line 199)
3. **Use popup windows** for temporary tasks
4. **Leverage vim-tmux-navigator** for seamless navigation
5. **Save sessions manually** before risky operations: `Prefix + C-s`
6. **Test keybindings** before committing changes
7. **Check pane borders** for git branch before running commands in git worktrees
8. **Launch Claude from correct directory** - `cd` into worktree before running `claude`
9. **Use CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR** - Keeps Claude instances isolated

## Resources

- Full keybindings: `docs/KEYBINDINGS_TMUX.md` in repository root
- TPM: https://github.com/tmux-plugins/tpm
- vim-tmux-navigator: https://github.com/christoomey/vim-tmux-navigator
- Catppuccin: https://github.com/catppuccin/tmux
- tmux-resurrect: https://github.com/tmux-plugins/tmux-resurrect
- gitmux: https://github.com/arl/gitmux
