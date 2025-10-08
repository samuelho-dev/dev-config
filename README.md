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

### System Requirements
- **Operating System:** macOS (Intel/ARM), Linux (Debian, Ubuntu, Fedora, Arch, openSUSE)
- **Shell:** Bash or Zsh (will auto-switch to Zsh during installation)
- **Build Tools:** C compiler (for Treesitter parsers and blink.cmp)
  - macOS: Xcode Command Line Tools (`xcode-select --install`)
  - Linux: `build-essential` (Debian/Ubuntu) or equivalent

### Required (Minimum)
These are the bare minimum to run the installer:
- **Git** - Version control (for cloning repository)
- **curl** - For downloading Homebrew and Oh My Zsh installers

### Auto-Installed by `install.sh`

The installer automatically installs all required dependencies with zero manual intervention:

**Core Tools:**
- **Neovim** (≥ 0.9.0) - Text editor
- **tmux** (≥ 1.9) - Terminal multiplexer
- **Zsh** - Shell (sets as default login shell)
- **fzf** - Fuzzy finder (Telescope, tmux-fzf)
- **ripgrep** (rg) - Fast grep (Telescope live_grep)
- **lazygit** - Git TUI

**Shell Framework:**
- **Oh My Zsh** - Zsh plugin framework
- **Powerlevel10k** - Modern Zsh theme
- **zsh-autosuggestions** - Fish-like autosuggestions

**Plugin Managers:**
- **Lazy.nvim** - Neovim plugin manager (auto-configured)
- **TPM** - Tmux Plugin Manager (auto-installed to `~/.tmux/plugins/tpm`)

**Neovim Plugins (60+ plugins via Lazy.nvim):**
All Neovim plugins are auto-installed on first run, including:
- LSP support (Mason, nvim-lspconfig)
- Completion (blink.cmp with 2ms latency)
- Telescope (fuzzy finder)
- Treesitter (syntax highlighting)
- Git integration (Gitsigns, Lazygit, Octo, Diffview, Git-conflict)
- Markdown tools (Obsidian, render-markdown, markdown-preview)
- File explorer (Neo-tree)
- Many more...

See [nvim/README.md](nvim/README.md) for complete plugin list.

**Tmux Plugins (9 plugins via TPM):**
All tmux plugins are auto-installed, including:
- `tmux-resurrect` + `tmux-continuum` - Session persistence
- `vim-tmux-navigator` - Seamless Vim/tmux navigation
- `tmux-fzf` - Fuzzy finder for sessions/windows/panes
- `catppuccin/tmux` - Beautiful theme
- `tmux-yank` - Enhanced clipboard integration
- `tmux-battery` + `tmux-cpu` - Status bar info

**LSP Servers (via Mason):**
Auto-installed language servers:
- `ts_ls` - TypeScript/JavaScript
- `pyright` - Python
- `lua_ls` - Lua (for Neovim config editing)

Install additional LSP servers with `:Mason` in Neovim.

**Formatters/Linters (via Mason):**
Auto-installed formatters:
- `stylua` - Lua formatter
- `prettier` - JavaScript/TypeScript/JSON/YAML/Markdown
- `ruff` - Python formatter + linter

**Treesitter Parsers:**
Auto-installed syntax parsers for:
- bash, c, lua, vim, markdown, python, javascript, typescript, tsx, json, yaml, html, css, and more

Install additional parsers with `:TSInstall <language>` in Neovim.

**Platform-Specific:**
- **Homebrew** (macOS only, if not already installed)

### Optional Dependencies

These provide enhanced features but are not required:

**For GitHub Integration (Octo.nvim):**
- **GitHub CLI (`gh`)** - PR/issue management from Neovim
  ```bash
  # macOS
  brew install gh

  # Linux (Debian/Ubuntu)
  sudo apt install gh

  # Authenticate after installing
  gh auth login
  ```

**For Image Rendering (image.nvim):**
- **ImageMagick** - Image processing library
  ```bash
  # macOS
  brew install imagemagick

  # Linux (Debian/Ubuntu)
  sudo apt install imagemagick
  ```
  Auto-installed by `install.sh` if package manager supports it.

**For Mermaid Diagrams (render-markdown.nvim):**
- **npm** - Node.js package manager
- **Mermaid CLI** - Diagram rendering
  ```bash
  npm install -g @mermaid-js/mermaid-cli
  ```
  Auto-installed by `install.sh` if npm is available.

**For AI Features (Optional):**
- **ZHIPUAI_API_KEY** environment variable
  - Powers GLM-based features (Minuet completion, CodeCompanion)
  - Add to `~/.zshrc.local`: `export ZHIPUAI_API_KEY="your-api-key"`
  - Features remain offline until configured

**For blink.cmp Rust Optimization (Optional):**
- **pkg-config** - Build configuration tool
  ```bash
  # macOS
  brew install pkg-config

  # Linux (Debian/Ubuntu)
  sudo apt install pkg-config
  ```
  Without this, blink.cmp uses Lua fuzzy matcher (still fast, just not Rust-optimized).

### Manual Installation (if auto-install fails)

If `install.sh` fails to install a package, install manually:

**macOS:**
```bash
brew install git zsh neovim tmux fzf ripgrep lazygit imagemagick
brew install gh  # Optional: GitHub CLI
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt update
sudo apt install git zsh neovim tmux fzf ripgrep imagemagick build-essential
sudo apt install gh  # Optional: GitHub CLI

# lazygit (may need manual install)
# See: https://github.com/jesseduffield/lazygit#installation
```

**Linux (Fedora):**
```bash
sudo dnf install git zsh neovim tmux fzf ripgrep lazygit ImageMagick
sudo dnf install gh  # Optional: GitHub CLI
```

**Linux (Arch):**
```bash
sudo pacman -S git zsh neovim tmux fzf ripgrep lazygit imagemagick
sudo pacman -S github-cli  # Optional: GitHub CLI
```

Then re-run `bash scripts/install.sh`.

### Verification

After installation, verify dependencies:

```bash
# Check versions
nvim --version    # Should be ≥ 0.9.0
tmux -V           # Should be ≥ 1.9
git --version
zsh --version
fzf --version
rg --version
lazygit --version

# Check optional tools
gh --version      # Optional: GitHub CLI
mmdc --version    # Optional: Mermaid CLI
convert --version # Optional: ImageMagick
```

Or run the validation script:
```bash
cd ~/Projects/dev-config
bash scripts/validate.sh
```

---

## Dependency Reference

Quick reference for all dependencies and their purposes:

| Tool | Auto-Installed? | Purpose | Used By |
|------|-----------------|---------|---------|
| **git** | ✅ Yes | Version control | Repository cloning, plugin management |
| **zsh** | ✅ Yes | Shell | Login shell, Oh My Zsh |
| **neovim** (≥0.9.0) | ✅ Yes | Text editor | Core application |
| **tmux** (≥1.9) | ✅ Yes | Terminal multiplexer | Core application |
| **fzf** | ✅ Yes | Fuzzy finder | Telescope, tmux-fzf, shell fuzzy search |
| **ripgrep** (rg) | ✅ Yes | Fast grep | Telescope live_grep, code search |
| **lazygit** | ✅ Yes | Git TUI | Neovim git integration |
| **imagemagick** | ✅ Best effort | Image processing | image.nvim (Neovim image rendering) |
| **npm** | ⚠️ Optional | Package manager | Mermaid CLI installation |
| **mmdc** | ⚠️ Optional | Mermaid renderer | render-markdown.nvim diagrams |
| **gh** | ⚠️ Optional | GitHub CLI | Octo.nvim (PR/issue management) |
| **pkg-config** | ⚠️ Optional | Build tool | blink.cmp Rust optimization |
| **C compiler** | ⚠️ Required* | Code compilation | Treesitter parsers, blink.cmp |
| **Oh My Zsh** | ✅ Yes | Zsh framework | Shell plugin system |
| **Powerlevel10k** | ✅ Yes | Zsh theme | Shell prompt |
| **zsh-autosuggestions** | ✅ Yes | Zsh plugin | Shell autosuggestions |
| **TPM** | ✅ Yes | Tmux plugin manager | Tmux plugin installation |
| **Lazy.nvim** | ✅ Yes | Neovim plugin manager | Neovim plugin management |
| **Mason** | ✅ Yes | LSP/tool installer | LSP servers, formatters, linters |

\* C compiler required for Treesitter. On macOS: `xcode-select --install`. On Linux: `build-essential` package.

**Legend:**
- ✅ **Yes** - Automatically installed by `install.sh`
- ⚠️ **Optional** - Enhances features but not required
- ⚠️ **Required*** - Must be present on system (not auto-installed)

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

## What Gets Installed

### Automatic Installation Summary

When you run `bash scripts/install.sh`, here's what happens:

**Phase 1: Core Dependencies (5-10 minutes)**
- Homebrew (macOS only, if missing)
- git, zsh, tmux, neovim
- fzf, ripgrep, lazygit
- imagemagick (best effort)
- Version checks (Neovim ≥ 0.9.0, tmux ≥ 1.9)

**Phase 2: Shell Setup**
- Oh My Zsh framework
- Powerlevel10k theme
- zsh-autosuggestions plugin
- Sets zsh as default login shell
- Creates `~/.zshrc.local` for machine-specific config

**Phase 3: Tmux Setup**
- TPM (Tmux Plugin Manager) to `~/.tmux/plugins/tpm`
- 9 tmux plugins auto-installed via TPM

**Phase 4: Symlinks**
- Backs up existing configs (timestamped: `~/.config/nvim.backup.20241008_120000`)
- Creates symlinks from home directory → repository
- Configs: nvim, tmux, ghostty, zsh (.zshrc, .zprofile, .p10k.zsh)

**Phase 5: Neovim Setup (2-5 minutes)**
- 60+ Neovim plugins installed via Lazy.nvim (headless)
- 3 LSP servers: ts_ls, pyright, lua_ls
- 3 formatters: stylua, prettier, ruff
- 15+ Treesitter parsers compiled (requires C compiler)
- Optional: Mermaid CLI via npm (if available)

**Phase 6: Verification**
- Symlinks verified
- Oh My Zsh verified
- TPM verified
- Default shell verified (zsh)
- Reports any issues with actionable fixes

**Total time:** 10-15 minutes on first install (varies by platform and internet speed).

**Bandwidth usage:** ~500MB (Neovim plugins, Treesitter parsers, LSP servers).

**Disk space:** ~2GB after installation (Neovim plugins, Mason tools, Treesitter parsers).

### What Requires Internet

- Initial `git clone` of this repository
- Homebrew installation (macOS)
- Package installation (apt/dnf/pacman/brew)
- Oh My Zsh, Powerlevel10k, zsh-autosuggestions (git clone)
- TPM and tmux plugins (git clone)
- Neovim plugins (60+ via Lazy.nvim)
- Mason LSP servers/formatters
- Treesitter parsers (git clone)
- Optional: Mermaid CLI (npm)

**Offline mode:** Once installed, everything works offline except:
- Plugin updates (`:Lazy update`, `Prefix + U` in tmux)
- New LSP server installations (`:Mason`)
- GitHub integration (requires `gh auth login` and internet)

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

### Missing dependencies after installation?

Run the validation script to diagnose:
```bash
cd ~/Projects/dev-config
bash scripts/validate.sh
```

This checks:
- Repository structure
- Symlinks
- Core dependencies (git, zsh, neovim, tmux, fzf, ripgrep, lazygit)
- Tool versions (Neovim ≥ 0.9.0, tmux ≥ 1.9)
- Oh My Zsh, TPM, Powerlevel10k
- Provides actionable fix suggestions

### Neovim LSP not working?

Check LSP server status:
```vim
:LspInfo          " Show connected LSP servers
:Mason            " Install/manage LSP servers
:checkhealth      " Full diagnostic check
```

Common issues:
- **LSP server missing:** Open `:Mason` and install the server
- **Node.js required:** Some LSP servers need Node.js (install with `brew install node` or `apt install nodejs`)
- **Python required:** `pyright` needs Python (usually pre-installed)

### Treesitter errors?

Ensure C compiler is installed:
```bash
# macOS
xcode-select --install

# Linux (Debian/Ubuntu)
sudo apt install build-essential

# Then reinstall parsers
nvim --headless "+TSInstall all" +qa
```

### Neovim images not rendering?

ImageMagick required:
```bash
# macOS
brew install imagemagick

# Linux
sudo apt install imagemagick
```

### Mermaid diagrams not rendering?

Install Mermaid CLI:
```bash
npm install -g @mermaid-js/mermaid-cli

# Verify
mmdc --version
```

### GitHub PR/issue management not working?

Install and authenticate GitHub CLI:
```bash
# macOS
brew install gh

# Linux (Debian/Ubuntu)
sudo apt install gh

# Authenticate
gh auth login
```

Then in Neovim:
- `<leader>gp` - List PRs
- `<leader>gi` - List issues

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
