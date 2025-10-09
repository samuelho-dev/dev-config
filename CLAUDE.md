# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Component-Specific Documentation

**Each directory has detailed CLAUDE.md and README.md files for AI and user guidance:**

### Configuration Components
- **[nvim/CLAUDE.md](nvim/CLAUDE.md)** - Neovim architecture, plugin system, LSP configuration
- **[nvim/lua/CLAUDE.md](nvim/lua/CLAUDE.md)** - Lua module organization and require paths
- **[nvim/lua/config/CLAUDE.md](nvim/lua/config/CLAUDE.md)** - Core configuration (options, autocmds, keymaps)
- **[nvim/lua/plugins/CLAUDE.md](nvim/lua/plugins/CLAUDE.md)** - Plugin specifications and lazy loading
- **[nvim/lua/plugins/custom/CLAUDE.md](nvim/lua/plugins/custom/CLAUDE.md)** - Custom utility modules
- **[tmux/CLAUDE.md](tmux/CLAUDE.md)** - Tmux configuration and TPM plugins
- **[zsh/CLAUDE.md](zsh/CLAUDE.md)** - Zsh configuration, Oh My Zsh, Powerlevel10k
- **[ghostty/CLAUDE.md](ghostty/CLAUDE.md)** - Ghostty terminal configuration

### Scripts & Utilities
- **[scripts/CLAUDE.md](scripts/CLAUDE.md)** - Installation script architecture and shared libraries
- **[scripts/lib/CLAUDE.md](scripts/lib/CLAUDE.md)** - Shared Bash functions (common.sh, paths.sh)

### Documentation
- **[docs/CLAUDE.md](docs/CLAUDE.md)** - Documentation maintenance and standards

**When working on a specific component, read the component's CLAUDE.md first for detailed guidance.**

## Repository Overview

This is a **centralized development configuration repository** managing configs for:
- **Neovim** - Text editor with LSP, completion, git integration
- **Tmux** - Terminal multiplexer with plugin ecosystem
- **Ghostty** - GPU-accelerated terminal emulator
- **Zsh** - Shell with Oh My Zsh framework + Powerlevel10k theme
- **Docker** - Container platform with cross-platform installation

### Architecture: Symlink-Based Version Control

**Real config files** live in `~/Projects/dev-config/` (this Git repo).
**Symlinks** from standard locations point to these files:

```
~/.config/nvim/         → ~/Projects/dev-config/nvim/
~/.tmux.conf            → ~/Projects/dev-config/tmux/tmux.conf
~/.zshrc                → ~/Projects/dev-config/zsh/.zshrc
~/.zprofile             → ~/Projects/dev-config/zsh/.zprofile
~/.p10k.zsh             → ~/Projects/dev-config/zsh/.p10k.zsh
~/Library/.../ghostty/config → ~/Projects/dev-config/ghostty/config (macOS)
~/.config/ghostty/config → ~/Projects/dev-config/ghostty/config (Linux)
```

This enables:
- ✅ Version control for all configs
- ✅ Sync configs across multiple machines
- ✅ Easy backup/restore
- ✅ Safe experimentation with git branches

### Architecture: Shared Library System

**Scripts use a DRY (Don't Repeat Yourself) architecture** with shared libraries:

```
scripts/
├── lib/
│   ├── common.sh    # Shared utilities (logging, OS detection, backups, symlinks)
│   └── paths.sh     # Centralized path definitions (single source of truth)
├── install.sh       # Uses shared libraries (90% code reduction)
├── update.sh        # Uses shared libraries
├── uninstall.sh     # Uses shared libraries
└── validate.sh      # Diagnostic tool for troubleshooting
```

**Key shared functions:**
- `log_info()`, `log_success()`, `log_warn()`, `log_error()` - Color-coded logging
- `detect_os()` - Returns "macos", "linux", "windows", "unknown"
- `detect_package_manager()` - Returns brew/apt/dnf/pacman/zypper/none
- `create_backup()`, `create_symlink()`, `remove_symlink()` - Atomic operations
- `install_package()` - Platform-agnostic package installation
- `get_repo_root()` - Auto-detect via `git rev-parse` (no hardcoded paths!)

**Benefits:**
- ✅ Zero code duplication across scripts
- ✅ Consistent error handling and logging
- ✅ Platform detection abstraction
- ✅ Easier maintenance and testing

## Setup and Management Scripts

### Initial Setup (New Machine)
```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

**What install.sh does (Zero-Touch Installation):**
1. **Detects platform:** macOS (Intel/ARM), Linux (Debian, Fedora, Arch)
2. **Auto-installs Homebrew** (macOS if missing)
3. **Auto-installs core dependencies:**
   - git, zsh, neovim (≥ 0.9.0), tmux (≥ 1.9)
   - fzf, ripgrep, fd-find (fuzzy finding)
   - lazygit (git TUI)
   - GitHub CLI (`gh`) - optional but recommended
4. **Installs shell framework:**
   - Oh My Zsh (if not present)
   - Powerlevel10k theme
   - zsh-autosuggestions plugin
5. **Installs Tmux Plugin Manager (TPM)** - required for tmux plugins
6. **Creates timestamped backups** of existing configs
7. **Creates symlinks** from home directory to repo files
8. **Auto-installs Neovim plugins** (headless mode)
9. **Auto-installs tmux plugins** (via TPM script)
10. **Creates `.zshrc.local`** template for machine-specific config
11. **Verifies** all symlinks and installations

**After install:** Restart terminal. All plugins are already installed!

### Update Configuration (Pull Latest Changes)
```bash
cd ~/Projects/dev-config
bash scripts/update.sh
```

Pulls latest changes, stashes uncommitted changes if needed, reloads tmux config automatically.

### Uninstall (Remove Symlinks)
```bash
cd ~/Projects/dev-config
bash scripts/uninstall.sh
```

Removes all symlinks and restores most recent backups.

### Validate Installation (Troubleshooting)
```bash
cd ~/Projects/dev-config
bash scripts/validate.sh
```

**What validate.sh checks:**
- Repository structure integrity
- Symlinks pointing correctly
- Dependencies installed (git, zsh, neovim, tmux, fzf, ripgrep, lazygit)
- Tool versions (Neovim ≥ 0.9.0, tmux ≥ 1.9)
- External tools (Oh My Zsh, TPM, Powerlevel10k)
- Provides actionable fix suggestions

Use this if something breaks or after updating system packages.

## Neovim Configuration

### Base & Architecture
- **Base:** Kickstart.nvim (~1200 line single-file config at `nvim/init.lua`)
- **Plugin Manager:** lazy.nvim
- **Plugin Lock:** `nvim/lazy-lock.json` committed to git for version consistency
- **Custom Plugins:** `nvim/lua/custom/plugins/`

### LSP Servers
Configured in `init.lua` around line 705:
- `ts_ls` - TypeScript/JavaScript
- `pyright` - Python
- `lua_ls` - Lua (for Neovim config editing)

**Adding new LSP:** Add to `servers` table, run `:Mason` in Neovim.

### Formatters & Linters
Managed by Conform.nvim + Mason:
- **Lua:** stylua
- **Python:** ruff (format + lint)
- **JS/TS/JSON/YAML/Markdown:** prettier

Auto-format on save enabled (except C/C++). Manual format: `<leader>f`.

### Key Custom Features

#### 1. Diagnostic Copy for Claude Code (nvim/lua/custom/plugins/diagnostics-copy.lua)
**Purpose:** Quickly copy LSP errors/warnings to clipboard for pasting into AI assistants.

- `<leader>ce` - Copy **Errors** only
- `<leader>cd` - Copy all **Diagnostics** (errors, warnings, info)

**Output format:** Groups by severity with file paths and line numbers.

**Implementation:** Uses `vim.diagnostic.get()` API, copies to both `+` and `*` registers.

#### 2. Git Workflow Integration

**Lazygit.nvim:**
- `<leader>gg` - Open lazygit TUI (stage, commit, push, stash, branches)
- `<leader>gf` - Lazygit for current file only
- Full git operations without leaving Neovim

**Octo.nvim - GitHub Integration:**
- `<leader>gp` - List/review Pull Requests
- `<leader>gi` - Manage Issues
- Review PRs, add comments, approve/request changes in Neovim
- **Requires:** GitHub CLI (`gh`) authenticated

**Diffview.nvim:**
- `<leader>gd` - Open diff view
- `<leader>gh` - File history for current file
- `<leader>gH` - Full branch history

**Git-conflict.nvim - Merge Conflicts:**
- `<leader>gco` - Choose Ours
- `<leader>gct` - Choose Theirs
- `<leader>gcb` - Choose Both
- `<leader>gc0` - Choose None
- `<leader>gcn` / `<leader>gcp` - Next/Previous conflict

**Gitsigns - Gutter Integration:**
- Git changes in sign column
- Stage/unstage hunks
- Git blame inline

#### 3. Markdown & Note-Taking

**Obsidian.nvim:**
- Full Obsidian vault integration (using maintained `obsidian-nvim/obsidian.nvim` fork)
- **Auto-vault detection:** Scans common locations for `.obsidian` directories
  - Searches: `~/Documents`, `~/Library/Mobile Documents/iCloud~md~obsidian`, `~/Dropbox`, `~/vaults`, `~`
  - Automatically configures workspaces for all detected vaults
- **Smart activation:** Only loads for markdown files inside detected vaults
- Regular markdown files outside vaults work normally (no Obsidian features applied)
- Wikilinks, daily notes, tag support
- `gf` - Follow markdown links
- `<leader>ch` - Toggle checkboxes
- Zero configuration required - works across machines automatically

**Render-markdown.nvim:**
- Beautiful in-buffer markdown rendering
- Code blocks, headings, lists rendered visually
- No browser needed for preview

**Markdown-preview.nvim:**
- `<leader>mp` - Toggle browser preview
- Live updates as you type

**Bullets.vim:**
- Auto-formatting for bullet lists and tasks

**Outline.nvim:**
- `<leader>o` - Toggle document outline
- Navigate code/markdown structure

#### 4. File Explorer & Navigation
- **Neo-tree:** Toggle with `\` or `<leader>e`
- **Telescope:** Fuzzy finder - `<leader>sf` (files), `<leader>sg` (grep)

#### 5. Auto-Reload for External Changes (Claude Code Optimized)
**Critical for AI-assisted development workflows.**

**File Buffer Auto-Reload:**
- `autoread` enabled - automatically reloads files when changed externally
- Triggers on: FocusGained, BufEnter, CursorHold, CursorHoldI events
- Notification shown when file reloaded from disk
- Works seamlessly when Claude Code modifies files

**Neo-tree Auto-Refresh:**
- `use_libuv_file_watcher` enabled - uses OS-level file watching
- Detects all filesystem changes (add/delete/move/rename)
- Works from: terminal, other Neovim instances, git operations
- No manual refresh (`R`) needed

**Why this matters:**
- Claude Code can modify files → You see changes instantly
- Git branch switches → Files auto-reload
- Terminal operations → Reflected immediately
- Zero manual intervention required

### Plugin Management
- `:Lazy` - Open plugin manager
- `:Lazy update` - Update plugins
- `:Lazy restore` - Restore to lazy-lock.json versions (for cross-machine consistency)
- `:Mason` - Manage LSP servers/formatters

## Tmux Configuration

### Core Settings
- **Prefix:** `Ctrl+a` (not default `Ctrl+b`)
- **Split panes:** `|` horizontal, `-` vertical
- **Base index:** 1 (windows and panes start at 1, not 0)
- **Copy mode:** Vi-style keybindings
- **Mouse:** Enabled
- **History:** 10,000 lines

### Essential Plugins (Managed by TPM)

**vim-tmux-navigator:**
- **Critical:** Seamless navigation between Vim and tmux panes
- `Ctrl+h/j/k/l` - Navigate without prefix key
- Works across both Neovim splits and tmux panes

**tmux-resurrect + tmux-continuum:**
- `Prefix + Ctrl+s` - Save session
- `Prefix + Ctrl+r` - Restore session
- Auto-save every 60 minutes
- Survives reboots

**tmux-fzf:**
- `` Prefix + ` `` - Session switcher popup
- Fuzzy search for sessions/windows/panes

**catppuccin/tmux:**
- Mocha flavor theme
- Styled status bar

**tmux-yank:**
- Enhanced clipboard integration

### Popup Features
- `Prefix + !` - Quick shell popup (60% × 75%)
- `` Prefix + ` `` - fzf session switcher
- `Prefix + g` - Lazygit popup (80% × 80%)

### TPM Plugin Management
After modifying `tmux.conf` plugins:
- `Prefix + I` - Install new plugins
- `Prefix + U` - Update all plugins
- `Prefix + Alt+u` - Remove unlisted plugins

**TPM Location:** `~/.tmux/plugins/tpm` (installed by install.sh)

## Zsh & Shell Configuration

### Framework: Oh My Zsh
Installed to `~/.oh-my-zsh/` by install.sh.

### Theme: Powerlevel10k
- Modern, fast, customizable prompt
- Configuration: `zsh/.p10k.zsh` (1739 lines, fully customized)
- Reconfigure: `p10k configure`

### Plugins
- **zsh-autosuggestions:** Fish-like auto-suggestions from history

### Config Files
- **`.zshrc`** - Main shell config (Oh My Zsh, plugins, aliases, functions)
- **`.zprofile`** - Login shell config (PATH settings, environment variables)
- **`.p10k.zsh`** - Powerlevel10k theme configuration
- **`.zshrc.local`** - Machine-specific config (gitignored, created by install.sh)

### Machine-Specific Configuration Pattern

**Purpose:** Separate shared config (in Git) from machine-specific config (not in Git).

**Location:** `~/.zshrc.local` (in home directory, NOT in repo)

**Created by:** `install.sh` with template

**Sourced by:** `.zshrc` at the very end (line 136)

**Use cases:**
```bash
# Edit machine-specific config
nvim ~/.zshrc.local

# Examples:
export PATH="$HOME/work-tools/bin:$PATH"    # Work-specific tools
alias vpn="sudo openvpn /work/vpn.ovpn"     # Work VPN
export DATABASE_URL="postgresql://..."      # Local database
export API_KEY="secret-key"                 # API keys (never commit!)

# Language-specific setups:
export GOPATH="$HOME/go"                    # Go workspace
export NVM_DIR="$HOME/.nvm"                 # Node Version Manager
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Reload:
source ~/.zshrc
```

**Benefits:**
- ✅ Secrets stay out of Git
- ✅ Different config on work vs personal machines
- ✅ Survives updates to shared `.zshrc`
- ✅ No merge conflicts when syncing

**Platform-Agnostic PATH Configuration:**

All PATH additions use existence checks:
```bash
# Example from .zshrc (lines 113-136)
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  [ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"
  [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
fi
```

This ensures configs work on any machine, regardless of what's installed.

## Ghostty Terminal Configuration

Minimal config in `ghostty/config`:
- **Theme:** Cursor Dark
- **Keybind:** `cmd+shift+r` - Prompt surface title

Leverages Ghostty's sensible defaults. GPU-accelerated, written in Zig for performance.

## Docker Configuration

### Installation & Setup
Docker is installed as a **core dependency** with platform-specific installation:

**macOS:**
- Docker Desktop via Homebrew cask (`brew install --cask docker`)
- Auto-starts Docker Desktop after installation
- Waits for daemon to be ready before continuing

**Linux:**
- Supports multiple package managers (apt, dnf, pacman, zypper)
- Falls back to official Docker installation script
- Adds user to docker group automatically
- Starts and enables Docker service

### Version Requirements
- **Minimum Docker version:** 20.10+
- **Docker Compose:** Optional, supports both standalone and plugin versions
- **Validation:** Checks daemon status and version compatibility

### Machine-Specific Aliases
Docker aliases are available in `~/.zshrc.local` (commented out by default):

```bash
# Uncomment aliases you want to use:
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dcb='docker-compose build'
alias dcr='docker-compose run'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop'
alias dstart='docker start'
alias dexec='docker exec -it'
alias dlogs='docker logs'
alias dprune='docker system prune'
```

### Post-Installation
After installation, test Docker with:
```bash
docker run hello-world
```

### Troubleshooting
- **macOS:** If Docker Desktop doesn't start, run `open -a Docker`
- **Linux:** If permission denied, log out/in after group changes
- **Validation:** Run `bash scripts/validate.sh` to check Docker status

## Development Workflow

### Making Config Changes

**Edit configs:**
```bash
nvim ~/Projects/dev-config/nvim/init.lua         # Neovim
nvim ~/Projects/dev-config/tmux/tmux.conf        # Tmux
nvim ~/Projects/dev-config/zsh/.zshrc            # Zsh main config
nvim ~/Projects/dev-config/ghostty/config        # Ghostty
```

**Apply changes:**
- **Neovim:** Restart Neovim
- **Tmux:** `Prefix + r` to reload config
- **Zsh:** `source ~/.zshrc` or restart terminal
- **Ghostty:** Immediate (no restart needed)

**Commit and push:**
```bash
cd ~/Projects/dev-config
git add .
git commit -m "Description of changes"
git push origin main
```

### Syncing to Other Machines

On target machine:
```bash
cd ~/Projects/dev-config
bash scripts/update.sh
```

Then restart applications as needed.

### Diagnostic Copy Workflow (Neovim + Claude Code)

When encountering LSP errors:
1. In Neovim: `<leader>ce` (errors only) or `<leader>cd` (all diagnostics)
2. Paste into Claude Code chat
3. Output includes file paths, line numbers, severity grouping

Perfect for troubleshooting with AI assistance.

## File Structure

```
dev-config/
├── nvim/                           # Neovim config (Kickstart.nvim base)
│   ├── init.lua                    # Main config (~1200 lines)
│   ├── lazy-lock.json              # Plugin versions (committed for consistency)
│   ├── lua/custom/plugins/
│   │   ├── diagnostics-copy.lua    # Claude Code integration
│   │   └── init.lua                # Custom plugin loader
│   ├── .stylua.toml                # Lua formatter config
│   ├── CLAUDE.md                   # AI guidance for Neovim config
│   └── README.md                   # User documentation
├── tmux/
│   ├── tmux.conf                   # Tmux config (~200 lines)
│   ├── CLAUDE.md                   # AI guidance for tmux config
│   └── README.md                   # User documentation
├── ghostty/
│   ├── config                      # Ghostty terminal config (minimal)
│   ├── CLAUDE.md                   # AI guidance for Ghostty config
│   └── README.md                   # User documentation
├── zsh/
│   ├── .zshrc                      # Main shell config
│   ├── .zprofile                   # Login shell (PATH)
│   ├── .p10k.zsh                   # Powerlevel10k theme (1739 lines)
│   ├── CLAUDE.md                   # AI guidance for Zsh config
│   └── README.md                   # User documentation
├── scripts/
│   ├── lib/
│   │   ├── common.sh               # Shared utilities (348 lines)
│   │   └── paths.sh                # Centralized path definitions (96 lines)
│   ├── install.sh                  # Zero-touch installation (372 lines)
│   ├── update.sh                   # Pull changes, reload configs (111 lines)
│   ├── uninstall.sh                # Remove symlinks, restore backups (75 lines)
│   ├── validate.sh                 # Diagnostic tool (185 lines)
│   ├── CLAUDE.md                   # AI guidance for scripts (most detailed)
│   └── README.md                   # User documentation
├── docs/
│   ├── INSTALLATION.md             # Complete installation guide
│   ├── CONFIGURATION.md            # Customization guide
│   ├── TROUBLESHOOTING.md          # Common issues and solutions
│   ├── KEYBINDINGS_NEOVIM.md       # Complete Neovim keybinding reference
│   └── KEYBINDINGS_TMUX.md         # Complete tmux keybinding reference
├── .gitignore                      # Excludes runtime files, .zshrc.local
├── .editorconfig                   # Editor consistency
├── LICENSE                         # MIT License
├── CLAUDE.md                       # This file (high-level AI guidance)
├── README.md                       # User-facing documentation
└── REFACTORING_SUMMARY.md          # Refactoring change log
```

**Component-Specific Documentation:**
- Each directory has its own `CLAUDE.md` for detailed AI guidance
- Each directory has its own `README.md` for user documentation
- Root `CLAUDE.md` provides high-level architecture overview
- Root `README.md` provides user-friendly introduction

## Important Commands

### Neovim
- `:checkhealth` - Diagnose setup issues
- `:LspInfo` - Show LSP client status
- `:Mason` - Install/manage LSP servers
- `:Lazy` - Manage plugins
- `:Lazy restore` - Restore plugins to lazy-lock.json versions

### Tmux
- `Prefix + r` - Reload config
- `Prefix + I` - Install plugins (TPM)
- `Prefix + U` - Update plugins (TPM)
- `Prefix + ?` - Show all keybindings

### Shell
- `source ~/.zshrc` - Reload shell config
- `p10k configure` - Reconfigure Powerlevel10k theme

### Git (in this repo)
```bash
cd ~/Projects/dev-config
git status                    # Check changes
git add .                     # Stage all
git commit -m "message"       # Commit
git push origin main          # Push to remote
```

## Cross-Machine Compatibility & Platform Support

### Supported Platforms

**macOS:**
- ✅ Apple Silicon (M1/M2/M3) - Homebrew at `/opt/homebrew`
- ✅ Intel - Homebrew at `/usr/local`
- Platform detection via `uname -m` (arm64 vs x86_64)

**Linux:**
- ✅ Debian/Ubuntu (apt)
- ✅ Fedora/RHEL/CentOS (dnf)
- ✅ Arch/Manjaro (pacman)
- ✅ openSUSE (zypper)
- Homebrew for Linux at `/home/linuxbrew/.linuxbrew`

### Cross-Platform Features

**Auto-Detection:**
- OS detection via `uname -s`
- Package manager detection (checks for brew/apt/dnf/pacman/zypper)
- Homebrew path detection (3 locations)
- Ghostty config path (macOS vs Linux)

**Platform-Agnostic Paths:**
- All configs use `$HOME` and environment variables
- No hardcoded usernames or paths
- Auto-detection via `git rev-parse` for repo root
- Existence checks before PATH additions

**Example from `.zprofile` (lines 12-20):**
```bash
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"  # macOS Apple Silicon
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"     # macOS Intel
elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"  # Linux
fi
```

### Version Consistency

**lazy-lock.json:**
- **Critical:** Committed to git per lazy.nvim best practices
- Ensures identical Neovim plugin versions across machines
- Use `:Lazy restore` on new machine to match versions
- Use `:Lazy sync` to update lock file with current versions

**TPM Installation:**
- Auto-installed by `install.sh` to `~/.tmux/plugins/tpm`
- Plugins auto-installed during initial setup
- Use `Prefix + U` to update all tmux plugins

**Oh My Zsh & Powerlevel10k:**
- Auto-installed if not present
- Safe to run `install.sh` multiple times (checks for existing installations)

**lazygit:**
- Auto-installed by `install.sh` via detected package manager
- macOS: Homebrew (`brew install lazygit`)
- Linux: apt/pacman/dnf/zypper

**GitHub CLI (Optional):**
- Required for Octo.nvim (PR/issue management)
- Install manually:
```bash
brew install gh           # macOS/Linux (Homebrew)
sudo apt install gh       # Debian/Ubuntu
sudo dnf install gh       # Fedora
gh auth login             # Authenticate
```

### Machine-Specific Differences

Use `~/.zshrc.local` for machine-specific configuration:
- Work vs personal machine aliases
- Machine-specific PATH additions
- Local development environment variables
- Secrets and API keys
- Language-specific tools (NVM, Go, Rust, etc.)

See "Machine-Specific Configuration Pattern" section above.

## Troubleshooting

### Symlinks Not Working
Verify with `ls -la`:
```bash
ls -la ~/.config/nvim
ls -la ~/.tmux.conf
ls -la ~/.zshrc
```
All should show `->` pointing to `~/Projects/dev-config/`.

### Tmux Plugins Not Installing
1. Check TPM: `ls ~/.tmux/plugins/tpm`
2. If missing: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
3. Reload: `Prefix + r`
4. Install: `Prefix + I`

### Neovim Plugins Out of Sync
```vim
:Lazy restore     " Restore to lazy-lock.json versions
:Lazy sync        " Update lazy-lock.json with current versions
```

### Git Plugins Not Working
- **lazygit:** Check `which lazygit` (should return path)
- **Octo.nvim:** Run `gh auth status` (should show authenticated)

### Shell Config Not Loading
```bash
echo $ZSH               # Should show ~/.oh-my-zsh
echo $ZSH_THEME         # Should show powerlevel10k/powerlevel10k
source ~/.zshrc         # Force reload
```

## Dependencies Summary

### Auto-Installed by install.sh
**Core tools:**
- Homebrew (macOS only, if not present)
- git
- zsh
- neovim (≥ 0.9.0)
- tmux (≥ 1.9)
- docker (≥ 20.10)
- fzf, ripgrep, lazygit
- make (build tools)
- node, npm (Node.js ecosystem)
- imagemagick (image processing)

**Shell framework:**
- Oh My Zsh
- Powerlevel10k theme
- zsh-autosuggestions plugin

**Plugin managers:**
- Tmux Plugin Manager (TPM)
- Neovim plugins (via lazy.nvim headless install)
- tmux plugins (via TPM script)

**Machine-specific config:**
- `.zshrc.local` template

### Optional (Install Manually)
- GitHub CLI (`gh`) - for Octo.nvim PR/issue management
- Docker Compose (standalone) - if not bundled with Docker Desktop
- Claude Code workstation config (for AI-assisted development)

### Managed by Neovim (Mason)
- **LSP servers:** ts_ls (TypeScript/JavaScript), pyright (Python), lua_ls (Lua)
- **Formatters:** stylua (Lua), prettier (JS/TS/JSON/YAML/Markdown), ruff (Python)
- **Build tools:** make (telescope-fzf-native), pkg-config (blink.cmp optimization)
- **External tools:** Node.js/npm (Mermaid CLI), ImageMagick (image.nvim)

### Managed by Tmux (TPM)
- vim-tmux-navigator
- tmux-resurrect + tmux-continuum
- tmux-fzf
- catppuccin/tmux
- tmux-yank
- tmux-battery, tmux-cpu

## Architecture Deep Dive

### Shared Library System (`scripts/lib/`)

**Purpose:** Eliminate code duplication, provide consistent interfaces.

**`scripts/lib/common.sh` (348 lines):**

Key functions:
```bash
# Logging with colors
log_info "message"     # Blue
log_success "message"  # Green
log_warn "message"     # Yellow
log_error "message"    # Red

# Platform detection
detect_os()              # Returns: macos, linux, windows, unknown
is_macos()               # Boolean check
is_linux()               # Boolean check
detect_package_manager() # Returns: brew, apt, dnf, pacman, zypper, none

# Version comparison
version_gte "2.0.0" "1.9.0"  # Returns 0 (true) or 1 (false)

# File operations (atomic with backups)
create_backup "/path/to/file" "timestamp"
create_symlink "/source" "/target" "timestamp"
remove_symlink "/target"  # Restores most recent backup

# Package management
install_package "package-name"  # Uses detected package manager

# Repository detection
get_repo_root  # Uses git rev-parse (no hardcoded paths!)
```

**`scripts/lib/paths.sh` (96 lines):**

Single source of truth for all paths:
```bash
# Auto-detected repo root
REPO_ROOT=$(get_repo_root)

# Component directories
REPO_NVIM="$REPO_ROOT/nvim"
REPO_TMUX="$REPO_ROOT/tmux"
REPO_GHOSTTY="$REPO_ROOT/ghostty"
REPO_ZSH="$REPO_ROOT/zsh"

# Home directories (platform-aware)
HOME_NVIM="$HOME/.config/nvim"
HOME_TMUX_CONF="$HOME/.tmux.conf"
HOME_ZSHRC="$HOME/.zshrc"
HOME_ZPROFILE="$HOME/.zprofile"
HOME_P10K="$HOME/.p10k.zsh"

# Platform-specific Ghostty path
if is_macos; then
  HOME_GHOSTTY_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
else
  HOME_GHOSTTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
fi

# Arrays for iteration
SYMLINK_PAIRS=(
  "$REPO_NVIM:$HOME_NVIM"
  "$REPO_TMUX_CONF:$HOME_TMUX_CONF"
  # ... etc
)
```

**Benefits:**
- Change a path once, affects all scripts
- No path duplication
- Platform differences handled centrally
- Easy to add new symlinks

### Script Workflows

**`scripts/install.sh` workflow:**
1. Source shared libraries
2. Detect OS and package manager
3. Install/update Homebrew (macOS)
4. Install core dependencies with version checks
5. Install Oh My Zsh + Powerlevel10k + plugins
6. Install TPM
7. Create timestamped backups of existing configs
8. Create symlinks using shared functions
9. Auto-install Neovim plugins (headless)
10. Auto-install tmux plugins (TPM script)
11. Create `.zshrc.local` template
12. Verify all symlinks and installations
13. Print success message with next steps

**`scripts/update.sh` workflow:**
1. Source shared libraries
2. Check if repo is clean or has uncommitted changes
3. Prompt to stash if dirty
4. Auto-detect current branch
5. Pull latest changes
6. Reload tmux config automatically
7. Remind to restart Neovim and shell
8. Verify symlinks still intact

**`scripts/uninstall.sh` workflow:**
1. Source shared libraries
2. Confirm with user (destructive operation)
3. Remove all symlinks using shared function
4. Restore most recent backups
5. Optionally remove Oh My Zsh, TPM
6. Print success message

**`scripts/validate.sh` workflow:**
1. Source shared libraries
2. Check repository structure integrity
3. Verify all symlinks point correctly
4. Check core dependencies installed
5. Verify tool versions (Neovim ≥ 0.9.0, tmux ≥ 1.9)
6. Check Oh My Zsh, TPM, Powerlevel10k installed
7. Print detailed report with fix suggestions

### Adding New Components

**To add a new symlink:**

1. Add to `scripts/lib/paths.sh`:
```bash
REPO_NEW_TOOL="$REPO_ROOT/newtool"
HOME_NEW_TOOL="$HOME/.config/newtool"
```

2. Add to `SYMLINK_PAIRS` array:
```bash
SYMLINK_PAIRS=(
  # ... existing pairs ...
  "$REPO_NEW_TOOL:$HOME_NEW_TOOL"
)

SYMLINK_TARGETS=(
  # ... existing targets ...
  "$HOME_NEW_TOOL"
)
```

3. All scripts automatically pick up the change!

**To add a new dependency:**

Add to `install.sh` dependencies section:
```bash
DEPENDENCIES=(
  # ... existing deps ...
  "newtool"
)
```

`install_package()` function handles platform-specific installation automatically.

## For Future Claude Code Instances

**When modifying this repository:**

1. **Read component-specific CLAUDE.md first:**
   - `nvim/CLAUDE.md` for Neovim changes
   - `tmux/CLAUDE.md` for tmux changes
   - `zsh/CLAUDE.md` for shell changes
   - `scripts/CLAUDE.md` for script architecture (most detailed!)

2. **Use shared libraries when modifying scripts:**
   - Source `lib/common.sh` and `lib/paths.sh`
   - Use provided logging functions
   - Use platform detection functions
   - Add paths to `paths.sh` (don't hardcode!)

3. **Test cross-platform:**
   - Verify existence checks (`[ -d "$HOME/tool" ]`)
   - No hardcoded paths or usernames
   - Use `$HOME`, `$REPO_ROOT`, environment variables

4. **Machine-specific config pattern:**
   - Never commit `.zshrc.local` to Git
   - Use it for secrets, machine-specific PATH, aliases
   - Document in `zsh/CLAUDE.md` or `zsh/README.md`

5. **Version consistency:**
   - Commit `nvim/lazy-lock.json` after plugin updates
   - Test with `:Lazy restore` on different machine
   - Document breaking changes in commit messages

6. **Auto-reload features:**
   - Neovim auto-reloads files when changed externally
   - Neo-tree auto-refreshes on filesystem changes
   - tmux config reloads with `Prefix + r`
   - Zsh config reloads with `source ~/.zshrc`

7. **Documentation:**
   - Update component-specific CLAUDE.md for architecture changes
   - Update README.md for user-facing feature changes
   - Keep `docs/` directory guides in sync

**Common tasks:**
- Adding Neovim plugin: `nvim/CLAUDE.md` lines 260-300
- Adding tmux plugin: `tmux/CLAUDE.md` lines 172-193
- Adding LSP server: `nvim/CLAUDE.md` lines 210-235
- Adding zsh plugin: `zsh/CLAUDE.md` lines 205-224
- Adding script symlink: `scripts/CLAUDE.md` lines 220-250
- Cross-platform testing: `scripts/CLAUDE.md` lines 252-289
