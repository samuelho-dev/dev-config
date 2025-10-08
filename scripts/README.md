# Installation Scripts

Automated installation, update, and management scripts for dev-config.

## Scripts Overview

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `install.sh` | Zero-touch installation | Fresh machine, first-time setup |
| `update.sh` | Pull latest changes | Sync configs from Git |
| `uninstall.sh` | Remove symlinks | Rollback installation |
| `validate.sh` | Verify installation | Troubleshooting, diagnostics |

## install.sh

**Fully automated installation** - no manual steps required!

```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

### What It Does

1. ✅ Installs Homebrew (macOS if missing)
2. ✅ Installs dependencies (Neovim, tmux, docker, fzf, ripgrep, lazygit)
3. ✅ Installs build tools (make, node, npm, imagemagick)
4. ✅ Checks versions (Neovim ≥ 0.9.0, tmux ≥ 1.9, Docker ≥ 20.10)
5. ✅ Installs Oh My Zsh + Powerlevel10k + zsh-autosuggestions
6. ✅ Installs TPM (Tmux Plugin Manager)
7. ✅ Creates backups of existing configs
8. ✅ Creates symlinks to repository
9. ✅ Creates `.zshrc.local` for machine-specific config
10. ✅ **Auto-installs Neovim plugins**
11. ✅ **Auto-installs tmux plugins**
12. ✅ Verifies everything is working
13. ✅ Installs Mermaid CLI + ImageMagick for inline diagrams (if possible)

### After Installation

```bash
# Restart terminal
exec zsh

# Everything should work automatically!
nvim  # Plugins already installed
tmux  # Plugins already installed
docker run hello-world  # Test Docker installation
```

### Environment Variables

- `ZHIPUAI_API_KEY` – required for GLM-backed completions in Minuet and CodeCompanion. Export it in your shell profile (e.g. `~/.zshrc.local`) before launching Neovim.
- `CLAUDE_AGENT_ROOT` (optional) – override the default path (`~/Projects/claude-code-agent`) that the yarepl presets use for Claude CLI, aider, and observability commands.

### Platform Support

- ✅ macOS (Intel + Apple Silicon)
- ✅ Linux (Debian, Ubuntu, Fedora, Arch)

## update.sh

**Pull latest changes** from Git and reload configs.

```bash
bash scripts/update.sh
```

### What It Does

1. Checks for uncommitted changes
2. Prompts to stash changes if needed
3. Pulls latest from Git
4. Reloads tmux config (if running)
5. Reminds you to restart Neovim and shell

### Safe for Uncommitted Changes

If you have local modifications:
- Script will detect them
- Prompt to stash before updating
- Your changes are safely preserved

## uninstall.sh

**Remove all symlinks** and restore backups.

```bash
bash scripts/uninstall.sh
```

### What It Does

1. Prompts for confirmation
2. Removes all symlinks
3. Restores most recent backups
4. Leaves repository intact

### Safety

- Confirmation required before proceeding
- Backups are automatically restored
- Repository remains at `~/Projects/dev-config`

### Reinstalling

```bash
bash scripts/install.sh
```

## Docker Integration

### Installation
Docker is installed as a **core dependency** with platform-specific setup:

**macOS:**
- Installs Docker Desktop via Homebrew cask
- Auto-starts Docker Desktop
- Waits for daemon to be ready

**Linux:**
- Supports multiple package managers (apt, dnf, pacman, zypper)
- Adds user to docker group
- Starts and enables Docker service

### Aliases
Docker aliases are available in `~/.zshrc.local` (commented out by default):

```bash
# Uncomment aliases you want to use:
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dps='docker ps'
alias di='docker images'
# ... and more
```

### Testing
After installation, test Docker:
```bash
docker run hello-world
```

## Neovim Dependencies

### Mason-Installed Tools
Neovim uses Mason to manage LSP servers and formatters:

**LSP Servers:**
- `ts_ls` - TypeScript/JavaScript
- `pyright` - Python
- `lua_ls` - Lua (for Neovim config)

**Formatters:**
- `stylua` - Lua formatting
- `prettier` - JS/TS/JSON/YAML/Markdown
- `ruff` - Python formatting and linting

### Build Tools
**Required for optimal performance:**
- `make` - Builds telescope-fzf-native native binaries
- `pkg-config` - Enables blink.cmp Rust optimization

**External tools:**
- `node`/`npm` - Mermaid CLI for diagram rendering
- `imagemagick` - Image processing for image.nvim

### Validation
Run validation to check all dependencies:
```bash
bash scripts/validate.sh
```

This checks:
- System dependencies (git, zsh, tmux, docker)
- Build tools (make, node, npm, pkg-config)
- External tools (imagemagick, mmdc)
- Mason-installed tools
- Neovim and tmux plugins

## validate.sh

**Diagnose installation** issues.

```bash
bash scripts/validate.sh
```

### What It Checks

✅ Repository structure (all files present)
✅ Symlinks (pointing to correct locations)
✅ Dependencies (git, zsh, neovim, tmux, ImageMagick, Mermaid CLI)
✅ Tool versions (Neovim ≥ 0.9.0, tmux ≥ 1.9)
✅ External tools (Oh My Zsh, Powerlevel10k, TPM)

### Sample Output

```
🔍 Validating dev-config installation...

📁 Checking repository structure...
   ✅ All repository files present

🔗 Checking symlinks...
   ✅ nvim → symlinked correctly
   ✅ tmux.conf → symlinked correctly
   ✅ .zshrc → symlinked correctly

📦 Checking dependencies...
   ✅ git installed
   ✅ nvim 0.10.0 (✓ >= 0.9.0)
   ✅ tmux 3.3 (✓ >= 1.9)

✅ Validation passed! No issues found.
```

## Shared Library System

Scripts use a **DRY architecture** with shared utilities:

```
scripts/
└── lib/
    ├── common.sh      # Logging, OS detection, symlink management
    └── paths.sh       # Centralized path definitions
```

**Benefits:**
- No code duplication
- Consistent behavior across scripts
- Easy to maintain and extend

## Troubleshooting

### "Permission denied" Error

```bash
chmod +x scripts/*.sh
bash scripts/install.sh
```

### Installation Fails

Run validation to diagnose:
```bash
bash scripts/validate.sh
```

Check for specific errors in output.

### Symlinks Not Created

Ensure you're in the repository:
```bash
cd ~/Projects/dev-config
pwd  # Should show .../dev-config
bash scripts/install.sh
```

### Dependencies Not Installing

**macOS:** Ensure Homebrew can install:
```bash
brew doctor
```

**Linux:** Check package manager:
```bash
sudo apt update  # Debian/Ubuntu
sudo dnf check-update  # Fedora
```

## Advanced Usage

### Custom Script Location

If repository is NOT at `~/Projects/dev-config`:

```bash
# Scripts auto-detect location via git
cd /your/custom/path/dev-config
bash scripts/install.sh
```

No hardcoded paths!

### Machine-Specific Configuration

Edit `~/.zshrc.local` for machine-specific settings:

```bash
# Custom PATH
export PATH="$HOME/custom-bin:$PATH"

# Aliases
alias work-vpn="sudo openvpn /path/to/work.ovpn"

# Environment variables
export DATABASE_URL="postgresql://localhost:5432/dev"
```

This file is **gitignored** - perfect for secrets and local customization.

## For Developers

See `scripts/CLAUDE.md` for:
- Detailed architecture documentation
- Adding new scripts
- Adding new symlinks
- Adding new dependencies
- Testing procedures
- Best practices

## Resources

- Installation guide: `docs/INSTALLATION.md`
- Configuration guide: `docs/CONFIGURATION.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`
