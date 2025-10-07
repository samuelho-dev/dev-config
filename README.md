# Dev Config

Centralized development tool configurations for Neovim, tmux, and Ghostty terminal, managed via Git and symlinks.

## Overview

This repository contains the **actual configuration files** for Neovim, tmux, and Ghostty. Your home directory contains **symlinks** that point to these files, allowing you to:

- ✅ Version control your configs
- ✅ Share configs across multiple machines
- ✅ Backup and restore easily
- ✅ Track changes over time
- ✅ Experiment safely with branches

**Architecture:**
```
~/.config/nvim/                                              → symlink to ~/Projects/dev-config/nvim/
~/.tmux.conf                                                 → symlink to ~/Projects/dev-config/tmux/tmux.conf
~/Library/Application Support/com.mitchellh.ghostty/config   → symlink to ~/Projects/dev-config/ghostty/config
~/.zshrc                                                     → symlink to ~/Projects/dev-config/zsh/.zshrc
~/.zprofile                                                  → symlink to ~/Projects/dev-config/zsh/.zprofile
~/.p10k.zsh                                                  → symlink to ~/Projects/dev-config/zsh/.p10k.zsh

~/Projects/dev-config/    (Git repo - source of truth)
├── nvim/                 (actual files, version controlled)
├── tmux/tmux.conf        (actual file, version controlled)
├── ghostty/config        (actual file, version controlled)
└── zsh/                  (shell configuration, version controlled)
    ├── .zshrc            (main zsh config)
    ├── .zprofile         (login shell config)
    └── .p10k.zsh         (Powerlevel10k theme config)
```

---

## Prerequisites

### Required
- Git
- Neovim (0.9.0+)
- A terminal emulator (iTerm2, Ghostty, etc.)

### Auto-installed by install.sh
- **lazygit** - Beautiful git TUI (auto-installed on macOS/Linux)
- **Oh My Zsh** - Zsh framework (auto-installed)
- **Powerlevel10k** - Zsh theme (auto-installed)
- **zsh-autosuggestions** - Fish-like suggestions (auto-installed)

### Optional (Recommended)
- **GitHub CLI (`gh`)** - For PR/issue management in Neovim
  ```bash
  # macOS
  brew install gh

  # Linux (Debian/Ubuntu)
  sudo apt install gh
  ```

### Manual Installation (if auto-install fails)
```bash
# lazygit
# macOS
brew install lazygit

# Linux (Debian/Ubuntu)
sudo apt install lazygit

# Arch
sudo pacman -S lazygit
```

---

## Quick Start

### First Time Setup (This Machine)

Since you've just created this repo, run the installer to create symlinks:

```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

Then restart tmux and Neovim to apply changes.

### Setup on Other Machines

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dev-config ~/Projects/dev-config
   ```

2. Run the installer:
   ```bash
   cd ~/Projects/dev-config
   bash scripts/install.sh
   ```

3. Restart tmux and Neovim

---

## Features

### Neovim

**NEW Diagnostic Copy Feature (for Claude Code workflows):**
- `<leader>ce` - **C**opy **E**rrors only to clipboard
- `<leader>cd` - **C**opy all **D**iagnostics to clipboard

Formatted output includes file path, line numbers, and severity grouping. Perfect for pasting into Claude Code or other AI assistants.

**Other Key Features:**
- Kickstart.nvim base configuration
- LSP support (TypeScript, Python, Lua)
- Telescope fuzzy finder
- Auto-formatting with Conform
- Git integration with Gitsigns
- Neo-tree file explorer
- Blink.cmp completion

**Markdown & Obsidian Support:**
- Full Obsidian vault integration (wikilinks, daily notes, tags)
- In-buffer markdown rendering with `render-markdown.nvim`
- Browser preview with `<leader>mp`
- Task management with auto-formatting bullets
- Document outline with `<leader>o`

See [docs/NEOVIM.md](docs/NEOVIM.md) for complete keybinding reference.

### Git & GitHub Integration

**Your leader key is `<space>` (spacebar)**

**Staging & Commits (lazygit):**
- `<leader>gg` - Open lazygit TUI (staging, commits, push, pull, stash, branches)
- `<leader>gf` - Lazygit for current file only
- `prefix + g` (in tmux) - Lazygit popup

**GitHub PRs & Issues (octo.nvim):**
- `<leader>gp` - List and review Pull Requests
- `<leader>gi` - Manage Issues
- Review PRs, add comments, approve/request changes - all from Neovim
- Uses GitHub CLI (`gh`)

**Diff & History (diffview.nvim):**
- `<leader>gd` - Open diff view
- `<leader>gh` - File history for current file
- `<leader>gH` - Full branch history

**Merge Conflicts (git-conflict.nvim):**
- `<leader>gco` - Choose Ours
- `<leader>gct` - Choose Theirs
- `<leader>gcb` - Choose Both
- `<leader>gc0` - Choose None
- `<leader>gcn` / `<leader>gcp` - Next/Previous conflict
- `<leader>gcl` - List all conflicts

**Git Hunks (gitsigns):**
- Git changes shown in gutter
- Stage/unstage hunks
- Git blame
- Hunk preview

### Tmux

**Configuration Highlights:**
- **Prefix:** `C-a` (instead of `C-b`)
- **Split panes:** `|` (horizontal), `-` (vertical)
- **Navigation:** Vim-style with `h/j/k/l` via vim-tmux-navigator
- **Popups:** `!` (shell), `` ` `` (session switcher), `g` (lazygit)
- **Theme:** Catppuccin Mocha
- **Plugins:** Resurrect, Continuum, tmux-fzf

See [docs/TMUX.md](docs/TMUX.md) for complete keybinding reference.

### Ghostty

**Configuration Highlights:**
- **Theme:** Cursor Dark
- **Custom Keybinds:** `cmd+shift+r` - Prompt surface title
- Modern GPU-accelerated terminal emulator
- Written in Zig for performance

Configuration file: `ghostty/config`

### Shell (Zsh)

**Configuration Highlights:**
- **Framework:** Oh My Zsh with Powerlevel10k theme
- **EDITOR/VISUAL:** Set to `nvim` (git commits, crontab, etc. use Neovim)
- **Plugins:** git, zsh-autosuggestions
- **Features:**
  - Instant prompt for fast shell startup
  - Fish-like autosuggestions
  - Customized PATH (includes bun, pnpm, Python, Homebrew)
  - Claude Code work profile alias: `claude-work`

**Configuration files:**
- `.zshrc` - Main shell configuration
- `.zprofile` - Login shell PATH setup
- `.p10k.zsh` - Powerlevel10k theme customization

All shell configurations are version controlled and sync across machines!

---

## Making Changes

### Edit Configs

Simply edit files in `~/Projects/dev-config/`:

```bash
# Edit Neovim config
nvim ~/Projects/dev-config/nvim/init.lua

# Edit tmux config
nvim ~/Projects/dev-config/tmux/tmux.conf

# Edit Ghostty config
nvim ~/Projects/dev-config/ghostty/config

# Edit shell configs
nvim ~/Projects/dev-config/zsh/.zshrc        # Main shell config
nvim ~/Projects/dev-config/zsh/.zprofile     # Login shell config
nvim ~/Projects/dev-config/zsh/.p10k.zsh     # Powerlevel10k theme
```

Changes take effect immediately (Neovim requires restart, shell requires `source ~/.zshrc`).

### Commit and Push

```bash
cd ~/Projects/dev-config
git add .
git commit -m "Add custom keybinding"
git push origin main
```

### Update Other Machines

On any machine with this repo installed:

```bash
cd ~/Projects/dev-config
bash scripts/update.sh
```

This will:
1. Pull latest changes from Git
2. Reload tmux config (if running)
3. Prompt you to restart Neovim

---

## Scripts

All scripts are located in `scripts/` directory:

### `install.sh`
Creates symlinks from home directory to repository files. Backs up existing configs with timestamp.

```bash
bash scripts/install.sh
```

### `uninstall.sh`
Removes symlinks and restores most recent backups (if any).

```bash
bash scripts/uninstall.sh
```

### `update.sh`
Pulls latest changes from Git and reloads configs. Stashes uncommitted changes if necessary.

```bash
bash scripts/update.sh
```

---

## Directory Structure

```
dev-config/
├── README.md                 # This file
├── .gitignore                # Ignore swap files, .DS_Store
├── nvim/                     # Neovim configuration
│   ├── init.lua              # Main config file
│   ├── lua/
│   │   ├── custom/
│   │   │   └── plugins/
│   │   │       └── diagnostics-copy.lua  # Diagnostic clipboard feature
│   │   └── kickstart/        # Kickstart.nvim modules
│   ├── lazy-lock.json        # Plugin versions (committed)
│   └── .stylua.toml          # Lua formatter config
├── tmux/
│   └── tmux.conf             # Tmux configuration
├── ghostty/
│   └── config                # Ghostty terminal configuration
├── zsh/                      # Shell configuration
│   ├── .zshrc                # Main zsh config (Oh My Zsh, plugins, aliases)
│   ├── .zprofile             # Login shell config (PATH settings)
│   └── .p10k.zsh             # Powerlevel10k theme configuration
├── scripts/
│   ├── install.sh            # Create symlinks
│   ├── uninstall.sh          # Remove symlinks
│   └── update.sh             # Pull and reload
└── docs/
    ├── NEOVIM.md             # Complete Neovim keybinding reference
    └── TMUX.md               # Complete tmux keybinding reference
```

---

## Troubleshooting

### Symlinks not working?

Verify symlinks:
```bash
ls -la ~/.config/nvim
ls -la ~/.tmux.conf
ls -la ~/Library/Application\ Support/com.mitchellh.ghostty/config
ls -la ~/.zshrc
ls -la ~/.zprofile
ls -la ~/.p10k.zsh
```

All should show `->` pointing to `~/Projects/dev-config/`.

### Neovim not loading plugins?

1. Ensure symlink is correct
2. Restart Neovim completely
3. Run `:Lazy sync` to reinstall plugins

### Tmux config not applying?

Reload tmux config:
```bash
tmux source-file ~/.tmux.conf
```

Or restart tmux:
```bash
tmux kill-server
```

### Diagnostic copy not working?

1. Ensure you're in a file with LSP diagnostics
2. Check that custom module exists: `ls ~/Projects/dev-config/nvim/lua/custom/plugins/diagnostics-copy.lua`
3. Check for Lua errors: `:messages` in Neovim

---

## Contributing

This is a personal configuration repository, but feel free to fork and adapt for your own use!

If you find a bug or have a suggestion:
1. Open an issue
2. Submit a pull request
3. Or just fork and customize for yourself

---

## License

MIT License - See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) - Neovim base config
- [Catppuccin](https://github.com/catppuccin/catppuccin) - Color scheme
- [tmux-plugins](https://github.com/tmux-plugins) - Tmux plugin ecosystem
