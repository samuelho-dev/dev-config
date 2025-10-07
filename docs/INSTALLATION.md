# Installation Guide

Complete installation guide for dev-config across different platforms.

## Prerequisites

### Required
- **Git** - Version control
- **Zsh** - Shell (or willingness to switch from bash)

### Auto-Installed by `install.sh`
The following will be installed automatically if missing:
- **Homebrew** (macOS only)
- **Neovim** (0.9.0+)
- **tmux** (1.9+)
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep
- **lazygit** - Git TUI
- **Oh My Zsh** - Zsh framework
- **Powerlevel10k** - Zsh theme
- **zsh-autosuggestions** - Zsh plugin
- **TPM** - Tmux Plugin Manager

### Optional (Install Manually)
- **GitHub CLI (`gh`)** - For PR/issue management in Neovim
  ```bash
  # macOS
  brew install gh

  # Linux (Debian/Ubuntu)
  sudo apt install gh

  # Authenticate after installing
  gh auth login
  ```

---

## Fresh Installation

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/dev-config ~/Projects/dev-config
cd ~/Projects/dev-config
```

### 2. Run Installer
```bash
bash scripts/install.sh
```

**What the installer does:**
1. ✅ Checks for sudo (script should run as normal user)
2. ✅ Verifies repository structure
3. ✅ Installs Homebrew (macOS) if missing
4. ✅ Installs core dependencies (git, zsh, neovim, tmux, fzf, ripgrep, lazygit)
5. ✅ Checks tool versions (Neovim ≥ 0.9.0, tmux ≥ 1.9)
6. ✅ Installs Oh My Zsh + Powerlevel10k + zsh-autosuggestions
7. ✅ Installs TPM (Tmux Plugin Manager)
8. ✅ Creates backups of existing configs (timestamped)
9. ✅ Creates symlinks from home directory → repository
10. ✅ Creates `~/.zshrc.local` for machine-specific config
11. ✅ Auto-installs Neovim plugins (via Lazy.nvim)
12. ✅ Auto-installs tmux plugins (via TPM)
13. ✅ Verifies installation

**Zero manual intervention required!**

### 3. Restart Terminal
```bash
exec zsh
```

### 4. Done!
Open Neovim and tmux - everything should work automatically.

---

## Installing on Additional Machines

On any other machine:

```bash
git clone https://github.com/yourusername/dev-config ~/Projects/dev-config
cd ~/Projects/dev-config
bash scripts/install.sh
```

All configs and plugins will be set up identically.

---

## Platform-Specific Notes

### macOS
- Homebrew will be installed automatically
- Ghostty config path: `~/Library/Application Support/com.mitchellh.ghostty/config`
- Python paths in `.zprofile` are macOS Framework Python installations

### Linux
- Uses system package manager (apt/dnf/pacman/zypper)
- Ghostty config path: `~/.config/ghostty/config`
- Homebrew detection includes Linuxbrew paths

### Windows/WSL
- Not officially supported yet
- WSL users: treat as Linux installation

---

## Validation

After installation, verify everything is working:

```bash
bash scripts/validate.sh
```

This will check:
- ✅ Repository structure
- ✅ Symlinks pointing to correct locations
- ✅ All dependencies installed
- ✅ Tool versions meet requirements
- ✅ Oh My Zsh, Powerlevel10k, TPM installed

---

## Updating

Pull latest changes from repository:

```bash
bash scripts/update.sh
```

This will:
1. Stash uncommitted changes (with prompt)
2. Pull latest from Git
3. Reload tmux config (if running)
4. Remind you to restart Neovim and shell

---

## Uninstalling

Remove all symlinks and restore backups:

```bash
bash scripts/uninstall.sh
```

**Note:** This removes symlinks but keeps the repository intact at `~/Projects/dev-config`.

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

---

## What Gets Symlinked?

| Source (Repository) | Target (Home Directory) |
|---------------------|-------------------------|
| `nvim/` | `~/.config/nvim` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS) or `~/.config/ghostty/config` (Linux) |
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/.zprofile` | `~/.zprofile` |
| `zsh/.p10k.zsh` | `~/.p10k.zsh` |

**Backups:** Original files are backed up with timestamp: `~/.config/nvim.backup_20251006_120000`
