# Installation Guide

Complete installation guide for dev-config across different platforms.

## Prerequisites

### Required
- **Git** - Version control
- **Zsh** - Shell (or willingness to switch from bash)

### Auto-Installed by `install.sh`
The following will be installed automatically if missing:
- **Homebrew** (macOS only)
- **Docker** (20.10+) - Container platform
- **Neovim** (0.9.0+)
- **tmux** (1.9+)
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep
- **lazygit** - Git TUI
- **make** - Build tools (telescope-fzf-native)
- **node** - Node.js runtime
- **npm** - Node package manager
- **imagemagick** - Image processing
- **Docker Compose** - Container orchestration (optional)
- **Oh My Zsh** - Zsh framework
- **Powerlevel10k** - Zsh theme
- **zsh-autosuggestions** - Zsh plugin
- **TPM** - Tmux Plugin Manager

### Mason-Installed Tools (via Neovim)
These are automatically installed when you first open Neovim:

**LSP Servers:**
- **ts_ls** - TypeScript/JavaScript language server
- **pyright** - Python language server  
- **lua_ls** - Lua language server (for Neovim config)

**Formatters:**
- **stylua** - Lua code formatter
- **prettier** - JavaScript/TypeScript/JSON/YAML/Markdown formatter
- **ruff** - Python formatter and linter

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

- **pkg-config** - For blink.cmp Rust optimization (optional)
  ```bash
  # macOS
  brew install pkg-config

  # Linux (Debian/Ubuntu)
  sudo apt install pkg-config
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

## Docker Setup

### Platform-Specific Installation

**macOS:**
- Docker Desktop installed via Homebrew cask
- Auto-starts after installation
- May require manual start: `open -a Docker`

**Linux:**
- Installed via package manager (apt, dnf, pacman, zypper)
- User added to docker group automatically
- Service started and enabled
- **Important:** Log out and back in for group changes to take effect

### Testing Docker Installation

After installation, verify Docker is working:

```bash
# Test Docker daemon
docker --version

# Test Docker functionality
docker run hello-world

# Check Docker Compose (if installed)
docker-compose --version
# or
docker compose version
```

### Docker Aliases

Docker aliases are available in `~/.zshrc.local` (commented out by default):

```bash
# Edit ~/.zshrc.local and uncomment aliases you want:
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dcb='docker-compose build'
alias dps='docker ps'
alias di='docker images'
# ... and more
```

### Common Issues

**Docker daemon not running:**
```bash
# macOS
open -a Docker

# Linux
sudo systemctl start docker
```

**Permission denied on Linux:**
```bash
# Add user to docker group (if not done automatically)
sudo usermod -aG docker $USER

# Log out and back in
```

**Docker Desktop not starting on macOS:**
- Check if Docker Desktop is installed: `brew list --cask docker`
- Reinstall if needed: `brew reinstall --cask docker`

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
