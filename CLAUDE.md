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

### Architecture: Nix Flakes (Modern Package Management)

**As of January 2025, dev-config uses Nix flakes** for reproducible, declarative package management while preserving the battle-tested shared library system.

#### Why Nix Migration?

**Previous approach (shell scripts):**
- 372-line `install.sh` with imperative package installation
- Manual dependency management for each platform
- No version locking (packages updated whenever `brew`/`apt` runs)
- Difficult to reproduce identical environments

**New approach (Nix flakes):**
- 50-line `install.sh` that bootstraps Nix
- Declarative package definitions in `flake.nix`
- Version locking via `flake.lock` (committed to Git)
- Identical environments across all machines
- 86% code reduction (372 lines → 50 lines)

#### Hybrid Architecture

**Code reuse strategy:**
- Nix manages **package installation** (Neovim, tmux, zsh, Docker, OpenCode, 1Password CLI)
- Shared libraries handle **symlink creation** and **backups** (reuses existing `scripts/lib/common.sh`)
- Best of both worlds: Nix reproducibility + battle-tested logic

**Example from flake.nix:**
```nix
apps.activate = {
  type = "app";
  program = toString (pkgs.writeShellScript "activate" ''
    source ${./scripts/lib/common.sh}  # Reuse existing functions!
    source ${./scripts/lib/paths.sh}
    create_symlink "$REPO_NVIM" "$HOME_NVIM" "$TIMESTAMP"
    # ... uses all existing backup/symlink logic
  '');
};
```

#### Nix Components

**flake.nix (Main Configuration):**
- Defines all development packages
- Three Nix apps: `activate`, `set-shell`, `setup-opencode`
- Binary cache configuration (Cachix)
- DevShell with auto-loading AI credentials

**flake.lock (Version Pinning):**
- Exact package versions committed to Git
- Same `flake.lock` = identical environment on any machine
- Update with `nix flake update`

**scripts/install.sh (50-line Bootstrap):**
- Installs Nix via Determinate Systems installer
- Enables flakes
- Delegates to Nix apps for activation
- Preserves zero-touch installation UX

**scripts/load-ai-credentials.sh (1Password Integration):**
- Fetches API keys from 1Password "Dev" vault
- Uses `op read` with secret reference syntax (op://Vault/Item/Field)
- Exports: ANTHROPIC_API_KEY, OPENAI_API_KEY, GOOGLE_AI_API_KEY
- Graceful degradation if 1Password not authenticated

**.envrc (direnv Auto-Activation):**
- `use flake` - Auto-loads Nix environment
- Sources `load-ai-credentials.sh`
- Activates when entering dev-config directory

**Shared Libraries (Reused by Nix):**
- `scripts/lib/common.sh` (348 lines) - Utility functions used by Nix apps
- `scripts/lib/paths.sh` (96 lines) - Single source of truth for all paths

#### New Features with Nix

**OpenCode Integration:**
- AI coding agent (open-source Claude Code alternative)
- Installed via `nodePackages.opencode-ai`
- Authenticated with 1Password CLI credentials
- Supports both direct API access and LiteLLM proxy (team mode)
- Usage: `opencode ask "Explain this codebase"`
- Documentation: `docs/nix/04-opencode-integration.md`, `docs/nix/07-litellm-proxy-setup.md`

**1Password CLI:**
- Secure credential management
- No secrets on disk
- Automatic loading via direnv
- Team-wide secret sharing via vaults

**Binary Caching (Cachix):**
- First build: 5-10 minutes
- Cached builds: 10-30 seconds (20x faster!)
- Team-wide benefit
- Configured in `flake.nix`

**Environment Isolation:**
- Per-project Nix environments
- No global package pollution
- Multiple versions coexist peacefully

#### DevPod Integration (Remote Development)

**Remote development environments supported via:**
- `.devcontainer/devcontainer.json` for VS Code Remote Containers
- DevPod dotfiles integration for config management
- Nix feature-based approach (reuses existing `flake.nix`)
- Compatible with VS Code Remote, GitHub Codespaces, and DevPod

**How it works:**
1. Container starts with base Ubuntu image
2. Nix installed via devcontainer feature
3. DevPod automatically clones and installs dotfiles
4. `scripts/install.sh` detects container and adjusts behavior
5. All configs (Neovim, tmux, zsh) applied automatically

**1Password in containers:**
- Uses service account tokens (not biometric auth)
- Token passed via `OP_SERVICE_ACCOUNT_TOKEN` environment variable
- Configured in `.devcontainer/load-ai-credentials.sh`
- Falls back gracefully if token not provided

**Performance:**
- First build: 30-60 minutes (Nix evaluation + package download)
- Cached builds: 2-5 minutes (Nix cache hit)
- Subsequent starts: 10-30 seconds

**Files:**
- `.devcontainer/devcontainer.json` - Container configuration
- `.devcontainer/load-ai-credentials.sh` - 1Password loader for containers
- `scripts/install.sh` - Container detection and ownership fixes

**Documentation:** See `docs/README_DEVPOD.md` for comprehensive DevPod guide (4 documentation files, ~2,162 lines).

#### Nix-Specific Files

```
dev-config/
├── flake.nix                          # Main Nix configuration
├── flake.lock                         # Version lock file (committed)
├── .envrc                             # direnv auto-activation
├── .pre-commit-config.yaml            # Code quality hooks (Nix formatting, validation)
├── scripts/
│   ├── install.sh                     # Nix + Home Manager bootstrap (container-aware)
│   ├── load-ai-credentials.sh         # 1Password integration
│   └── lib/                           # Shared utilities (reused by Nix apps)
│       ├── common.sh                  # Logging, OS detection, backups, symlinks
│       └── paths.sh                   # Centralized path definitions
├── .devcontainer/
│   ├── devcontainer.json              # VS Code Remote Containers / DevPod config
│   └── load-ai-credentials.sh         # 1Password loader for containers
├── docs/nix/                          # Nix documentation
│   ├── 00-quickstart.md               # 5-minute installation guide
│   ├── 01-concepts.md                 # Nix mental model
│   ├── 02-daily-usage.md              # Common workflows
│   ├── 03-troubleshooting.md          # FAQ and issue resolution
│   ├── 04-opencode-integration.md     # OpenCode + 1Password setup
│   ├── 05-1password-setup.md          # Credential management
│   ├── 06-advanced.md                 # Customization guide
│   ├── 07-litellm-proxy-setup.md      # LiteLLM proxy integration (team AI management)
│   ├── 08-testing.md                  # Dry-run testing (3-tier strategy)
│   └── 09-1password-ssh.md            # SSH authentication + commit signing
├── .github/workflows/
│   └── nix-ci.yml                     # CI/CD pipeline (multi-platform builds)
└── NIX_MIGRATION_SUMMARY.md           # Implementation summary
```

#### Key Architectural Decisions

**1. Code Reuse Strategy**
- **Decision:** Wrap existing `scripts/lib/common.sh` functions in Nix instead of rewriting
- **Rationale:** 348 lines of battle-tested backup/symlink logic, already handles edge cases, 60% faster implementation
- **Implementation:** Nix apps source shell libraries and call existing functions

**2. 1Password CLI Integration**
- **Decision:** Use `op read` with secret references instead of JSON parsing
- **Rationale:** Recommended 2025 method, more secure (secrets never touch disk), simpler syntax
- **Implementation:** `export ANTHROPIC_API_KEY=$(op read "op://Dev/ai/ANTHROPIC_API_KEY")`

**2b. LiteLLM Proxy Integration (Team/Cluster AI Management)**
- **Decision:** Support LiteLLM proxy for team-based AI usage with centralized credential management
- **Rationale:**
  - Cost tracking and monitoring across team members
  - Unified API gateway for multiple LLM providers (Anthropic, OpenAI, Google)
  - Automatic fallback between providers for reliability
  - Rate limiting to prevent quota exhaustion
  - Centralized audit logs for compliance
- **Architecture:**
  ```
  OpenCode (localhost) → kubectl port-forward :4000
                       → LiteLLM Proxy (k8s cluster)
                       → Anthropic/OpenAI/Google APIs
  ```
- **Implementation:**
  - OpenCode configured to use `http://localhost:4000` (LiteLLM endpoint)
  - Requires `LITELLM_MASTER_KEY` environment variable
  - Loaded from 1Password: `op read "op://Dev/litellm/MASTER_KEY"`
  - Added to `scripts/load-ai-credentials.sh` (graceful degradation if not present)
  - Separate from direct API keys (different use case, rotation schedule)
- **Setup Requirements:**
  - LiteLLM deployed in ai-dev-env Kubernetes cluster
  - kubectl port-forward to expose service locally
  - 1Password "litellm" item with MASTER_KEY field
- **Benefits:**
  - Team collaboration: Shared cost tracking and budget management
  - Flexibility: Can switch between proxy (team mode) and direct API (solo mode)
  - Observability: Track token usage, costs, and model distribution
  - Reliability: Fallback support if one provider is down
- **Documentation:**
  - Complete setup guide: `docs/nix/07-litellm-proxy-setup.md`
  - Integration with OpenCode: `docs/nix/04-opencode-integration.md`
  - 1Password configuration: `docs/nix/05-1password-setup.md`

**3. Hybrid Activation**
- **Decision:** Shell scripts call Nix, not the reverse
- **Rationale:** Familiar entry point (`bash scripts/install.sh`), Nix handles packages, shell handles user interaction
- **Benefits:** Zero learning curve for users, gradual Nix adoption

**4. Binary Cache (Cachix)**
- **Decision:** Configure Cachix in flake.nix for team binary caching
- **Rationale:** First build ~10 minutes, cached builds ~30 seconds (20x faster!), team-wide benefit
- **Status:** Configured in flake.nix, requires Cachix account setup

**5. SSH Authentication with 1Password**
- **Decision:** Use 1Password SSH Agent for GitHub authentication and commit signing
- **Rationale:**
  - Private keys never touch disk (encrypted in 1Password vault)
  - Safe for public repositories (no secrets committed)
  - Works across all machines via 1Password cloud sync
  - Biometric unlock (Touch ID/Face ID)
  - Single setup for both authentication and signing
- **Implementation:**
  - `modules/home-manager/programs/ssh.nix` - SSH agent configuration
  - `modules/home-manager/programs/git.nix` - Git commit signing with `op-ssh-sign`
  - `secrets.nix` pattern for machine-specific data (gitignored)
  - Automatic HTTPS→SSH URL rewriting for GitHub
- **Security Model:**
  - Public repo: SSH config modules, Git signing config, template files
  - Gitignored: `secrets.nix` (Git user info + SSH public key)
  - 1Password only: SSH private keys (never exported)

**6. secrets.nix Pattern (Machine-Specific Configuration)**
- **Decision:** Use gitignored `secrets.nix` file for machine-specific configuration
- **Rationale:**
  - Keeps public repository safe (no user emails, SSH keys, or identifiers)
  - Each machine has its own `~/.config/home-manager/secrets.nix`
  - Template (`secrets.nix.example`) committed to guide users
  - Imported by Home Manager modules for configuration
- **Contents:**
  ```nix
  {
    gitUserName = "Your Name";
    gitUserEmail = "your-email@example.com";
    sshSigningKey = "ssh-ed25519 AAAAC3... your-email@example.com";
  }
  ```
- **Usage in modules:**
  ```nix
  # modules/home-manager/programs/git.nix
  let
    secrets = import ~/.config/home-manager/secrets.nix;
  in {
    programs.git = {
      userName = secrets.gitUserName;
      userEmail = secrets.gitUserEmail;
      signing.key = secrets.sshSigningKey;
    };
  }
  ```

**7. Dry-Run Testing Strategy**
- **Decision:** Implement 3-tier testing system for safe configuration validation
- **Rationale:** Allows testing Nix changes before applying them system-wide
- **Implementation:**
  - Tier 1: `nix flake show --json` - Syntax validation (fastest, no builds)
  - Tier 2: `home-manager build --flake .` - Build test without activation
  - Tier 3: `home-manager switch --dry-run` - Preview changes
  - Script: `scripts/test-config.sh` (automated 3-tier testing)
  - Pre-commit hook: `nix flake show --json` runs on every commit
- **Benefits:**
  - Catch syntax errors before committing
  - Test builds without system changes
  - Preview what will change on activation
  - Prevent broken configurations from being committed

#### Integration with ai-dev-env

**Planned (Phase 4):**
1. Export `nixosModules` and `homeManagerModules` from `flake.nix`
2. Import in ai-dev-env to eliminate duplicated Nix configuration
3. Single source of truth for developer tooling across all projects

**Example export (future):**
```nix
# flake.nix
{
  nixosModules.dev-config = { config, pkgs, ... }: {
    imports = [
      ./modules/neovim.nix
      ./modules/tmux.nix
      ./modules/zsh.nix
    ];
  };
}
```

**Example import in ai-dev-env (future):**
```nix
# ai-dev-env/flake.nix
{
  inputs.dev-config.url = "github:samuelho-dev/dev-config";

  nixosConfigurations.my-server = nixpkgs.lib.nixosSystem {
    modules = [
      dev-config.nixosModules.dev-config  # Import dev-config module
      ./configuration.nix
    ];
  };
}
```

## Setup and Management Scripts

### Initial Setup (New Machine) - Nix-Based

```bash
cd ~/Projects/dev-config
bash scripts/install.sh  # NEW: 50-line Nix bootstrap
```

**What install.sh does (Nix-Powered Zero-Touch Installation):**
1. **Installs Nix** via Determinate Systems installer (if not present)
2. **Enables flakes** in `~/.config/nix/nix.conf`
3. **Installs direnv** and configures shell hooks
4. **Runs `nix run .#activate`** which:
   - Sources `scripts/lib/common.sh` and `scripts/lib/paths.sh` (reuses existing functions)
   - Installs all packages from `flake.nix`: Neovim, tmux, zsh, Docker, OpenCode, 1Password CLI, etc.
   - Creates timestamped backups of existing configs
   - Creates symlinks from home directory to repo files
   - Installs Oh My Zsh, Powerlevel10k, zsh-autosuggestions
   - Installs Tmux Plugin Manager (TPM)
   - Auto-installs Neovim plugins (headless mode)
   - Auto-installs tmux plugins (via TPM script)
   - Creates `.zshrc.local` template for machine-specific config
5. **Sets zsh as default shell** (via `nix run .#set-shell`)
6. **Verifies** all installations

**After install:**
1. Restart terminal
2. `cd ~/Projects/dev-config` - direnv auto-activates Nix environment + AI credentials
3. All tools and plugins are ready!

**Legacy fallback:**
If Nix is not desired, use `bash scripts/install-legacy.sh` (original 372-line shell script).

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

### Claude Code + Git Worktrees (Parallel Development)

**Purpose:** Run multiple Claude Code instances simultaneously, each working on a different git worktree/branch in separate tmux panes.

**The Problem:**
Without proper isolation, multiple Claude Code instances can interfere with each other's working directories, causing commands to execute in the wrong worktree.

**The Solution:**
This configuration automatically isolates Claude Code instances using the official `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` environment variable.

**Configuration:**
Already set in `zsh/.zshrc` (lines 137-139):
```bash
# Claude Code: Maintain working directory per pane (prevents directory switching)
export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1
```

**Usage:**
```bash
# Create git worktrees for parallel development
git worktree add ../dev-config-feature-x -b feature-x
git worktree add ../dev-config-feature-y -b feature-y

# Tmux workflow:
# Pane 1: Main branch
cd ~/Projects/dev-config
claude  # Instance 1: works on main branch

# Pane 2: Feature X (Prefix + |)
cd ~/Projects/dev-config-feature-x
claude  # Instance 2: works on feature-x, isolated from Instance 1

# Pane 3: Feature Y (Prefix + |)
cd ~/Projects/dev-config-feature-y
claude  # Instance 3: works on feature-y, isolated from Instances 1 and 2
```

**Visual Indicators:**
Each pane border shows git branch and status via gitmux:
```
┌─ 1: main ⎇ main ✔ ─────────┐
│ $ claude                    │
└─────────────────────────────┘

┌─ 2: feature-x ⎇ feature-x ●2 ✚1 ─┐
│ $ claude                          │
└───────────────────────────────────┘

┌─ 3: feature-y ⎇ feature-y ↑3 ─┐
│ $ claude                       │
└────────────────────────────────┘
```

**Benefits:**
- ✅ Multiple features developed in parallel
- ✅ Each Claude instance isolated to its worktree
- ✅ No accidental cross-worktree command execution
- ✅ Git status visible in pane borders
- ✅ Official Claude Code configuration (documented)

**Documentation:**
- Full workflow: `tmux/CLAUDE.md` → "Claude Code + Git Worktree Workflow"
- Keybindings: `docs/KEYBINDINGS_TMUX.md` → "Git Worktree Workflow"

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

8. **SSH/1Password Authentication Pattern:**
   - **Never commit** `secrets.nix` (gitignored)
   - SSH private keys stored in 1Password vault only
   - SSH agent config in `modules/home-manager/programs/ssh.nix`
   - Git signing config in `modules/home-manager/programs/git.nix`
   - Template file `secrets.nix.example` documents required fields
   - Testing: `ssh -T git@github.com` and `git log --show-signature`
   - Troubleshooting guide: `docs/nix/08-1password-ssh.md`

9. **Testing Nix Configuration Changes:**
   - **Always test before committing** with `bash scripts/test-config.sh`
   - Tier 1: `nix flake show --json` (instant syntax check)
   - Tier 2: `home-manager build --flake .` (build without activation)
   - Tier 3: `home-manager switch --dry-run` (preview changes)
   - Pre-commit hook runs Tier 1 automatically
   - Fix syntax errors before they break user environments

**Common tasks:**
- Adding Neovim plugin: `nvim/CLAUDE.md` lines 260-300
- Adding tmux plugin: `tmux/CLAUDE.md` lines 172-193
- Adding LSP server: `nvim/CLAUDE.md` lines 210-235
- Adding zsh plugin: `zsh/CLAUDE.md` lines 205-224
- Adding script symlink: `scripts/CLAUDE.md` lines 220-250
- Cross-platform testing: `scripts/CLAUDE.md` lines 252-289
