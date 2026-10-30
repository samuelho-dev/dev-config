# Dev Config

Centralized development tool configurations for Neovim, tmux and Ghostty, with Nix/Home Manager for shared system packages and dotfiles and one writable native owner for coding CLIs.

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
- **Shell:** Bash (stock macOS Bash supports native bootstrap) or Zsh; changing the login shell is opt-in
- **Build Tools:** C compiler (for Treesitter parsers and blink.cmp)
  - macOS: Xcode Command Line Tools (`xcode-select --install`)
  - Linux: `build-essential` (Debian/Ubuntu) or equivalent

### Required (Minimum)
These are the bare minimum to run the installer:
- **Git** - Version control (for cloning repository)
- **curl** - For the Nix installer and missing native CLIs

### Provisioned by Nix and Home Manager

Shared Darwin/Linux system tools come from `pkgs/default.nix`; their executable
checks are enumerated in `pkgs/tool-checks.json`. Nix source revisions are
locked by `flake.lock`; Mac host extras in `pkgs/Brewfile` are opt-in, not part
of automatic activation. Held third-party sources need an explicit trust
decision before installation. An existing `helm@3` is preserved, not the
fresh-host Helm pin.

**Core Tools:**
- **Docker** (≥ 20.10) - Container platform
- **Neovim** (≥ 0.9.0) - Text editor
- **tmux** (≥ 1.9) - Terminal multiplexer
- **Zsh** - Shell (sets as default login shell)
- **fzf** - Fuzzy finder (Telescope, tmux-fzf)
- **ripgrep** (rg) - Fast grep (Telescope live_grep)
- **lazygit** - Git TUI
- **make** - Build tools (telescope-fzf-native)
- **node** - Node.js runtime (Mermaid CLI)
- **npm** - Node package manager
- **imagemagick** - Image processing

**Shell Framework:**
- **Oh My Zsh** - Zsh plugin framework
- **Powerlevel10k** - Modern Zsh theme
- **zsh-autosuggestions** - Fish-like autosuggestions

**Neovim editor tools (via Nix/Home Manager):**
- **LSP servers:** TypeScript (`ts_ls`), Python (`pyright`), Lua (`lua_ls`), Biome and Nix (`nixd`)
- **Formatters:** stylua, prettier, ruff, Biome and alejandra

**Plugin Managers:**
- **Lazy.nvim** - Neovim plugin manager (auto-configured)
- **tmux plugins** - installed from the Nix store by Home Manager (no TPM)

**Neovim Plugins (60+ plugins via Lazy.nvim):**
All Neovim plugins are auto-installed on first run, including:
- LSP support (nvim-lspconfig)
- Completion (blink.cmp with 2ms latency)
- Telescope (fuzzy finder)
- Treesitter (syntax highlighting)
- Git integration (Gitsigns, Lazygit, Octo, Diffview, Git-conflict)
- Markdown tools (Obsidian, render-markdown, markdown-preview)
- File explorer (Neo-tree)
- Many more...

See [nvim/README.md](nvim/README.md) for complete plugin list.

**Tmux Plugins (9 plugins via Home Manager / Nix store):**
All tmux plugins are installed declaratively (no TPM), including:
- `tmux-resurrect` + `tmux-continuum` - Session persistence
- `vim-tmux-navigator` - Seamless Vim/tmux navigation
- `tmux-fzf` - Fuzzy finder for sessions/windows/panes
- `catppuccin/tmux` - Beautiful theme
- `tmux-yank` - Enhanced clipboard integration
- `tmux-battery` + `tmux-cpu` - Status bar info

**LSP servers and formatters:**
Home Manager declares editor executables once and supplies them through Neovim's
wrapper, independently of the launching shell's PATH. The same tools remain
available to the user's shell. Neovim enables configured LSP servers directly;
Conform runs the declared formatters. Lazy.nvim manages plugins, not tool binaries.
The shared flake supplies these tools on Mac, headless Linux and Rex profiles.
Standalone Neovim users must provide the executables themselves.

**Treesitter Parsers:**
Auto-installed syntax parsers for:
- bash, c, lua, vim, markdown, python, javascript, typescript, tsx, json, yaml, html, css, and more

Install additional parsers with `:TSInstall <language>` in Neovim.

**Platform-specific extras:** Homebrew and `pkgs/Brewfile` are opt-in on macOS;
they are not run by `scripts/install.sh`.

### Optional Dependencies

These provide enhanced features but are not required:

**For Container Development:**
- **Docker Compose** (standalone) - If not bundled with Docker Desktop

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
  Use the shared Nix package set when available; these commands are manual alternatives.

**For Mermaid Diagrams (render-markdown.nvim):**
- **npm** - Node.js package manager
- **Mermaid CLI** - Diagram rendering
  ```bash
  npm add -g @mermaid-js/mermaid-cli
  ```
  This npm command is optional and is not run by `scripts/install.sh`.

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
| **make** | ✅ Yes | Build tools | telescope-fzf-native compilation |
| **node** | ✅ Yes | Node.js runtime | Mermaid CLI, npm ecosystem |
| **npm** | ✅ Yes | Package manager | Mermaid CLI installation |
| **imagemagick** | ✅ Best effort | Image processing | image.nvim (Neovim image rendering) |
| **mmdc** | ⚠️ Optional | Mermaid renderer | render-markdown.nvim diagrams |
| **gh** | ⚠️ Optional | GitHub CLI | Octo.nvim (PR/issue management) |
| **pkg-config** | ⚠️ Optional | Build tool | blink.cmp Rust optimization |
| **C compiler** | ⚠️ Required* | Code compilation | Treesitter parsers, blink.cmp |
| **Oh My Zsh** | ✅ Yes | Zsh framework | Shell plugin system |
| **Powerlevel10k** | ✅ Yes | Zsh theme | Shell prompt |
| **zsh-autosuggestions** | ✅ Yes | Zsh plugin | Shell autosuggestions |
| **tmux plugins** | ✅ Yes | via Home Manager (Nix store) | Tmux plugins (no TPM) |
| **Lazy.nvim** | ✅ Yes | Neovim plugin manager | Neovim plugin management |
| **Home Manager** | ✅ Yes | Editor tool binaries | LSP servers, formatters, build tools |

\* C compiler required for Treesitter. On macOS: `xcode-select --install`. On Linux: `build-essential` package.

**Legend:**
- ✅ **Yes** - Provisioned by the selected Home Manager profile, where enabled
- ⚠️ **Optional** - Enhances features but not required
- ⚠️ **Required*** - Must be present on system (not auto-installed)

---

## Quick Start

### First Time Setup (This Machine)

**Recommended:** Use Nix for reproducible, declarative package management:

```bash
cd ~/Projects/dev-config
bash scripts/install.sh  # Nix + selected Home Manager profile
```

Then restart your terminal. Home Manager installs missing enabled native CLIs,
not provider OAuth or upgrades to working CLIs.

**See:** [Nix Quick Start Guide](docs/nix/00-quickstart.md) for detailed instructions.

### Setup on Other Machines

1. Clone this repository:
   ```bash
   git clone https://github.com/samuelho-dev/dev-config ~/Projects/dev-config
   ```

2. Run the Nix installer:
   ```bash
   cd ~/Projects/dev-config
   bash scripts/install.sh  # Nix + selected Home Manager profile
   ```

3. Restart your terminal

Nix package source revisions follow `flake.lock`; writable native CLIs and MCP
stdio packages are not pinned by that file or guaranteed to be latest.

---

## Installation

**Modern, reproducible package management** with automatic dependency installation via Nix Flakes:

```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

**What this does:**
1. Installs Nix (if absent) and enables flakes
2. Runs this flake's selected Home Manager app (`nix run .#home-manager -- switch --flake .`)
3. Provisions shared system packages and dotfiles; the selected profile writes
   `~/.config/dev-config/native-tools` and installs missing writable OMP, Pi,
   Claude, OpenCode, Codex and Vercel CLIs through `ai/bootstrap.sh`
4. Links missing curated skills without replacing physical user directories,
   edits or unmanaged symlinks; tracked links advance only while still owned

**Benefits:**
- ✅ **Reproducible Nix sources**: `flake.lock` locks flake inputs, not native CLI releases
- ✅ **Declarative selection**: Profile enables system packages, native tools and MCP targets
- ✅ **Nix rollback**: Previous Home Manager generations do not roll back writable native CLIs
- ✅ **Isolated**: Per-project environments with zero conflicts
- ✅ **Cross-platform**: Works on macOS (Intel/ARM) and Linux
- ✅ **Binary cache**: 20x faster builds with Cachix (10 minutes → 30 seconds)
- ✅ **AI integration**: Writable native coding CLIs, separately configured MCP and existing account credentials

**After installation:**
```bash
cd ~/Projects/dev-config  # direnv auto-activates Nix environment
claude "What should I work on today?"  # Terminal: Existing Claude configuration is preserved
nvim  # Editor: `:AvanteAsk` for Cursor-like AI coding assistant
# Claude proxy routing is explicit opt-in, not configured by Home Manager
```

**Documentation:**
- [Native tool provisioning and auth](docs/CONFIGURATION.md#native-tools-versions-and-skills)
- [Quick Start Guide](docs/nix/00-quickstart.md) - Setup and non-activating checks
- [Nix Concepts](docs/nix/01-concepts.md) - Understanding Nix
- [Daily Usage](docs/nix/02-daily-usage.md) - Common workflows
- [Troubleshooting](docs/nix/03-troubleshooting.md) - Fix issues
- [1Password + Secrets](docs/nix/09-1password-ssh.md) - 1Password CLI, secrets, SSH agent
- [Advanced Guide](docs/nix/06-advanced.md) - Customization
- [LiteLLM Proxy Setup](docs/nix/07-litellm-proxy-setup.md) - Team AI management with cost tracking

**Time to install:** 10-15 minutes (first time), 30 seconds (subsequent machines with cache)

---

## Remote Development with DevPod

This repository supports remote development environments via [DevPod](https://devpod.sh/) and VS Code Remote Containers.

**Quick Start:**
```bash
# Install DevPod
brew install devpod

# Create workspace
devpod up . --ide vscode
```

**What happens:**
1. Container starts with Nix environment
2. Dotfiles installed automatically via DevPod dotfiles feature
3. All configs (Neovim, tmux, zsh) available immediately
4. AI credentials available via sops-nix encrypted secrets

**First run:** 30-60 minutes (Nix evaluation + packages)
**Cached runs:** 2-5 minutes (Nix cache hit)
**Subsequent starts:** 10-30 seconds

**Compatibility:**
- ✅ DevPod (docker, SSH, Kubernetes backends)
- ✅ VS Code Remote Containers
- ✅ GitHub Codespaces

DevPod connect/bootstrap scripts live in `tmux/scripts/`; the tmux integration is configured in `modules/home-manager/programs/tmux.nix` (`dev-config.tmux.devpodConnect`).

---

## SSH Authentication with 1Password

Secure GitHub authentication and Git commit signing using **1Password SSH Agent**. This approach stores SSH private keys in your encrypted 1Password vault instead of on disk.

### Why 1Password SSH Agent?

**Security Benefits:**
- ✅ Private keys **never** touch disk (encrypted in 1Password vault)
- ✅ Biometric unlock (Touch ID/Face ID/Windows Hello)
- ✅ No secrets committed to Git (safe for public repositories)
- ✅ Keys sync across devices via 1Password cloud
- ✅ Automatic key rotation and management

**Developer Experience:**
- ✅ Single setup for both SSH authentication and commit signing
- ✅ No manual SSH key management or backup
- ✅ Works seamlessly with Git, GitHub, and SSH connections
- ✅ Integrates with existing 1Password workflow

### Architecture

```
1Password Vault (Encrypted Cloud Storage)
  ├── SSH Private Key (never exported to disk)
  └── SSH Public Key
        ↓
1Password SSH Agent (Local Socket)
        ↓
SSH Client / Git Signing
        ↓
GitHub (Authentication + Commit Signing)

Configuration Files:
  ✅ modules/home-manager/programs/ssh.nix (SSH agent integration)
  ✅ modules/home-manager/programs/git.nix (commit signing config)
  ✅ ~/.config/home-manager/secrets.nix (machine-specific, gitignored)

Public Repository (Safe to commit):
  ✅ SSH configuration modules
  ✅ Git signing configuration
  ❌ Private keys (stored in 1Password only)
```

### Quick Setup

**Prerequisites:**
- 1Password account (free for personal use)
- 1Password desktop app installed

**Setup Steps:**
1. **Enable 1Password SSH Agent** (Settings → Developer)
2. **Create SSH key in 1Password** (New Item → SSH Key)
3. **Add public key to GitHub** (Settings → SSH and GPG keys)
   - Add as **Authentication key** (required)
   - Add same key as **Signing key** (recommended)
4. **Create secrets.nix** with your Git identity and public key
5. **Test authentication**: `ssh -T git@github.com`

**Total time:** 5-10 minutes

### Workflow

**Clone repositories (auto-converts HTTPS to SSH):**
```bash
# Even with HTTPS URL, Git uses SSH automatically
git clone https://github.com/username/repo.git

# Behind the scenes: Rewritten to ssh://git@github.com/username/repo.git
```

**Commit with automatic signing:**
```bash
git commit -m "Your commit message"
# No -S flag needed - commits automatically signed with your SSH key
# 1Password prompts for biometric authentication on first use
```

**Push to GitHub:**
```bash
git push origin main
# Uses SSH authentication via 1Password agent
# Biometric unlock if session expired
```

**Verify commit signatures:**
```bash
git log --show-signature
# Shows "Good signature" with your SSH key
```

### Security Model

**What's stored where:**

| Data | Location | Committed to Git? |
|------|----------|-------------------|
| SSH Private Key | 1Password vault (encrypted) | ❌ Never |
| SSH Public Key | GitHub + secrets.nix | ⚠️ secrets.nix only (gitignored) |
| SSH Agent Config | modules/home-manager/programs/ssh.nix | ✅ Yes (safe - no secrets) |
| Git Signing Config | modules/home-manager/programs/git.nix | ✅ Yes (safe - no secrets) |
| Git User Info | secrets.nix | ❌ No (gitignored) |

**secrets.nix example** (machine-specific, not committed):
```nix
{
  gitUserName = "Your Name";
  gitUserEmail = "your-email@example.com";
  sshSigningKey = "ssh-ed25519 AAAAC3... your-email@example.com";
}
```

### Multi-Machine Setup

Same SSH key works across all your devices via 1Password sync:

**First machine:**
1. Generate SSH key in 1Password
2. Add to GitHub
3. Create secrets.nix

**Additional machines:**
1. Install 1Password desktop app
2. Sign in (SSH keys auto-sync)
3. Enable SSH agent
4. Create secrets.nix (same public key)
5. Done!

No manual key copying or transfer needed.

### Documentation

**Complete guides:**
- **[1Password SSH Setup Guide](docs/nix/09-1password-ssh.md)** - Comprehensive step-by-step instructions, `op` CLI auth, and CI service accounts
- **[Installation Guide](docs/INSTALLATION.md#1password-ssh-setup-recommended)** - Setup during installation

**Troubleshooting:**
- "Could not open a connection to your authentication agent" → Check 1Password SSH agent enabled
- "Permission denied (publickey)" → Verify SSH key added to GitHub as Authentication key
- "Bad signature" → Ensure SSH key added as Signing key (not just Authentication)

See [docs/nix/09-1password-ssh.md](docs/nix/09-1password-ssh.md) for detailed troubleshooting.

---

## Features

### Docker
- **Cross-platform installation** (macOS, Linux)
- **Docker Desktop** for macOS via Homebrew
- **Docker Engine** for Linux with multiple package manager support
- **Docker Compose** support (standalone and plugin versions)
- **Machine-specific aliases** in `~/.zshrc.local`
- **Version validation** (Docker ≥ 20.10)
- **Daemon status checking** and auto-start

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

See [docs/KEYBINDINGS_NEOVIM.md](docs/KEYBINDINGS_NEOVIM.md) for complete keybinding reference.

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

See [docs/KEYBINDINGS_TMUX.md](docs/KEYBINDINGS_TMUX.md) for complete keybinding reference.

### Ghostty

**Configuration Highlights:**
- **Theme:** Cursor Dark
- **Custom Keybinds:** `cmd+shift+r` - Prompt surface title
- Modern GPU-accelerated terminal emulator
- Written in Zig for performance

Configuration file: `ghostty/config`

### Strict Linting & Type Safety

This repository provides **enterprise-grade linting configurations** for TypeScript monorepos:

**Biome Configuration (80+ rules):**
- `biome.json` - Strict TypeScript/JavaScript linting (source of truth)
- Enforce `import type`, no barrel files, cognitive complexity limits
- GritQL custom patterns for Effect-TS and anti-patterns

**Infrastructure-as-Code Linting:**
- `.kube-linter.yaml` - Kubernetes manifests (resource limits, no :latest)
- `.hadolint.yaml` - Dockerfiles (version pinning, non-root)
- `.tflint.hcl` - Terraform (snake_case, documented variables)
- `.github/actionlint.yaml` - GitHub Actions workflows

**Pre-commit Integration:**
```bash
pre-commit install  # Enable hooks
pre-commit run --all-files  # Run manually
```

See [docs/nix/11-strict-linting-guide.md](docs/nix/11-strict-linting-guide.md) for comprehensive guide.

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

`bash scripts/install.sh` installs Nix if absent, enables flakes, and invokes
the Home Manager app selected by this flake. The profile provisions shared
Darwin/Linux system commands (see `pkgs/tool-checks.json`), dotfiles and
Nix-managed tmux plugins. It writes `~/.config/dev-config/native-tools` and
calls `ai/bootstrap.sh install` for enabled OMP, Pi, Claude, OpenCode, Codex
and Vercel only when missing. The native launchers remain writable in
`~/.local`; stock macOS Bash suffices. Existing installs and their native
settings/OAuth are preserved. Skill sync fills individual links while
preserving entire physical user skill directories, edited skills and unmanaged
links; only recorded owned links still pointing at their previous target can
advance.

```bash
bash ai/bootstrap.sh check    # selected executables, not provider authorization
bash ai/bootstrap.sh update   # deliberate native upgrades, not a startup hook
```

With no local enabled-tools manifest the bootstrap selects all six; explicit
tool names override that selection. Native OAuth enrollment and MCP child
credentials are separate steps. `flake.lock` governs Nix source revisions;
it does not version-pin native CLIs or MCP stdio packages. Plugin source
updates and system flake updates are deliberate, distinct changes.

Mac host extras are opt-in via `pkgs/Brewfile`, not installed by Nix
activation. Existing `helm@3` is left in place, not a fresh-host version pin.
Held third-party package sources are not automatically trusted or installed.
The installer does not silently switch the default shell, install Homebrew,
or overwrite existing conflicting dotfiles. Do not treat package presence
as proof of authorization; verify the intended account/team/project
separately. See [Configuration](docs/CONFIGURATION.md) for explicit MCP
credential sources and native Vercel versus MCP identities.

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

On a machine with this repo installed, pull reviewed source changes, then
deliberately activate the selected profile:

```bash
cd ~/Projects/dev-config
git pull
nix run .#home-manager -- switch --flake .
```

Upgrade native CLIs separately with `bash ai/bootstrap.sh update`. Neither
command supplies provider OAuth or MCP child credentials.

---

## Scripts

`scripts/install.sh` bootstraps Nix and activates the flake-selected Home
Manager profile; it is not a standalone symlink/backup installer.

```bash
bash scripts/install.sh
```

`ai/bootstrap.sh install|update|check [tool ...]` owns writable native CLI
provisioning. `scripts/README.md` documents the installer and safe
non-activating verification commands. Do not run old symlink
`uninstall.sh`/`update.sh` procedures for Home Manager profiles.

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
├── biome/                    # Biome linting configuration
│   ├── biome.json            # Strict rules (80+ enabled) - source of truth
│   └── gritql-patterns/      # Custom GritQL lint patterns
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
- Oh My Zsh, Powerlevel10k, tmux plugins (Nix store)
- Provides actionable fix suggestions

### Neovim LSP not working?

Check LSP server status:
```vim
:LspInfo          " Show connected LSP servers
:checkhealth      " Full diagnostic check
```

Common issues:
- **LSP server missing:** Check the Home Manager Neovim wrapper's PATH and the package declaration in `modules/home-manager/programs/neovim.nix`; standalone users must install the executable themselves.
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
npm add -g @mermaid-js/mermaid-cli

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
