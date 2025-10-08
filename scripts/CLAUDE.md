# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with installation scripts in this directory.

## Architecture Overview

This directory contains the installation, update, and validation scripts for the dev-config repository. The scripts follow **DRY principles** with a shared library system to eliminate code duplication.

## File Structure

```
scripts/
├── install.sh          # Zero-touch installation script
├── update.sh           # Update from Git and reload configs
├── uninstall.sh        # Remove symlinks and restore backups
├── validate.sh         # Verify installation integrity
└── lib/
    ├── common.sh       # Shared utility functions (348 lines)
    └── paths.sh        # Centralized path definitions (96 lines)
```

## Shared Library System

### lib/common.sh

**Purpose:** Reusable utility functions for all scripts

**Key functions:**

#### Logging
- `log_info(message)` - Cyan informational messages
- `log_success(message)` - Green success messages
- `log_warn(message)` - Yellow warnings
- `log_error(message)` - Red errors (to stderr)
- `log_section(message)` - Blue section headers

#### OS Detection
- `detect_os()` - Returns: "macos", "linux", "windows", "unknown"
- `is_macos()` - Boolean check
- `is_linux()` - Boolean check

#### Package Manager Detection
- `detect_package_manager()` - Returns: "brew", "apt", "dnf", "pacman", "zypper", "none"
- `install_package(name)` - Install package via detected package manager

#### Version Management
- `version_gte(v1, v2)` - Compare semantic versions
- `get_command_version(cmd, flag)` - Extract version from command output

#### Backup & Restore
- `create_backup(file_path, timestamp)` - Backup file with timestamp suffix
- `restore_latest_backup(file_path)` - Restore most recent backup

#### Symlink Management
- `create_symlink(source, target, timestamp)` - Create symlink with auto-backup
- `remove_symlink(target)` - Remove symlink and restore backup

#### Helpers
- `command_exists(cmd)` - Check if command is available
- `check_sudo()` - Warn if running as root
- `get_repo_root()` - Auto-detect repository root via git
- `confirm(prompt, default)` - Y/N prompt with default

**Color constants:**
```bash
COLOR_RED, COLOR_GREEN, COLOR_YELLOW, COLOR_BLUE, COLOR_CYAN, COLOR_RESET
```

### lib/paths.sh

**Purpose:** Single source of truth for all file paths. No hardcoded paths in main scripts!

**Key variables:**

#### Auto-detected
- `REPO_ROOT` - Repository root (auto-detected via `get_repo_root()`)

#### Repository Paths (Source)
- `REPO_NVIM`
- `REPO_TMUX_CONF`
- `REPO_GHOSTTY_CONFIG`
- `REPO_ZSHRC`, `REPO_ZPROFILE`, `REPO_P10K`

#### Home Directory Paths (Targets)
- `HOME_NVIM` - Respects `$XDG_CONFIG_HOME`
- `HOME_TMUX_CONF`
- `HOME_GHOSTTY_CONFIG` - Platform-specific (macOS vs Linux, respects `$XDG_CONFIG_HOME` on Linux)
- `HOME_ZSHRC`, `HOME_ZSHRC_LOCAL`, `HOME_ZPROFILE`, `HOME_P10K`

#### External Tool Paths
- `OH_MY_ZSH_DIR` - Respects `$ZSH` environment variable
- `ZSH_CUSTOM` - Respects `$ZSH_CUSTOM`
- `P10K_THEME_DIR`, `ZSH_AUTOSUGGESTIONS_DIR`
- `TPM_DIR` - Respects `$TMUX_PLUGIN_MANAGER_PATH`

#### Environment Variable Overrides

All paths respect standard environment variables for flexibility:

```bash
# XDG Base Directory (Linux/Unix standard)
export XDG_CONFIG_HOME="$HOME/.config"      # Default: ~/.config
# Affects: HOME_NVIM, HOME_GHOSTTY_CONFIG (Linux)

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"               # Default: ~/.oh-my-zsh
# Affects: OH_MY_ZSH_DIR

export ZSH_CUSTOM="$ZSH/custom"             # Default: $ZSH/custom
# Affects: P10K_THEME_DIR, ZSH_AUTOSUGGESTIONS_DIR

# Tmux Plugin Manager
export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/tpm"  # Default: ~/.tmux/plugins/tpm
# Affects: TPM_DIR
```

**Example custom setup:**
```bash
# Use different config location
export XDG_CONFIG_HOME="$HOME/dotfiles/.config"
export ZSH="$HOME/dotfiles/oh-my-zsh"
export TMUX_PLUGIN_MANAGER_PATH="$HOME/dotfiles/.tmux/plugins/tpm"

# Run install script - will use custom paths
bash scripts/install.sh
```

#### Arrays for Iteration
- `SYMLINK_SOURCES` - Array of repository source paths (parallel to SYMLINK_TARGETS)
- `SYMLINK_TARGETS` - Array of symlink target paths
- **Note:** Uses parallel indexed arrays for Bash 3.2 compatibility (macOS default)

**Key functions:**
- `print_paths()` - Debug helper to print all paths
- `verify_repo_files()` - Check all source files exist

## Script Descriptions

### install.sh

**Purpose:** Zero-touch installation on fresh machine

**Workflow:**
1. Source shared libraries
2. Safety check (don't run as root)
3. Verify repository structure
4. **Install core dependencies:**
   - Homebrew (macOS if missing)
   - Git, zsh, tmux, docker (required)
   - Neovim, fzf, ripgrep, lazygit, docker-compose (optional)
   - Build tools: make, node, npm, imagemagick (optional)
   - Version checks (Neovim ≥ 0.9.0, tmux ≥ 1.9, Docker ≥ 20.10)
5. **Install zsh components:**
   - Oh My Zsh
   - Powerlevel10k theme
   - zsh-autosuggestions plugin
6. **Install TPM** (Tmux Plugin Manager)
7. **Create symlinks** with timestamp backups
8. **Create `.zshrc.local`** template for machine-specific config
9. **Auto-install Neovim plugins:** `nvim --headless "+Lazy! sync" +qa`
10. **Auto-install tmux plugins:** Run TPM install script
11. **Verify installation:** Check symlinks, dependencies, tools
12. Display completion message

**Usage:**
```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

**Key features:**
- Fully automated (no manual steps)
- Idempotent (safe to run multiple times)
- Cross-platform (macOS + Linux)
- Creates backups before overwriting
- Handles missing dependencies gracefully

#### Docker Installation Details

**Platform-specific installation:**

**macOS:**
- Uses Homebrew cask: `brew install --cask docker`
- Auto-starts Docker Desktop after installation
- Waits for daemon to be ready (30 attempts, 2s intervals)
- Fallback to manual installation instructions if Homebrew fails

**Linux:**
- Supports multiple package managers (apt, dnf, pacman, zypper)
- Uses official Docker repositories for apt (Ubuntu/Debian)
- Falls back to official Docker installation script
- Adds user to docker group automatically
- Starts and enables Docker service via systemctl

**Version validation:**
- Checks for Docker ≥ 20.10
- Verifies Docker daemon is running
- Validates Docker Compose availability (standalone or plugin)

**Error handling:**
- Graceful fallback to manual installation instructions
- Clear error messages with next steps
- Continues installation even if Docker fails

### update.sh

**Purpose:** Pull latest changes and reload configs

**Workflow:**
1. Source shared libraries
2. Change to repository root
3. **Handle uncommitted changes:**
   - Check `git status --porcelain`
   - If dirty, prompt to stash
   - Auto-stash with timestamp message
4. **Pull latest changes:**
   - Detect current branch: `git rev-parse --abbrev-ref HEAD`
   - Pull from origin
5. **Reload configs:**
   - Tmux: `tmux source-file ~/.tmux.conf` (if running)
   - Neovim: Reminder to restart
   - Shell: Reminder to `exec zsh`
6. Display completion message

**Usage:**
```bash
bash scripts/update.sh
```

### uninstall.sh

**Purpose:** Remove all symlinks and restore backups

**Workflow:**
1. Source shared libraries
2. Confirm with user (Y/N prompt)
3. **Remove symlinks:** Iterate through `SYMLINK_TARGETS` array
4. **Restore backups:** For each symlink, restore most recent `.backup_*`
5. Display completion message with reinstall instructions

**Usage:**
```bash
bash scripts/uninstall.sh
```

**Safety:**
- Confirmation prompt before proceeding
- Repository remains intact
- Backups remain in home directory

### validate.sh

**Purpose:** Diagnose installation issues

**Workflow:**
1. Source shared libraries
2. **Check repository structure:** `verify_repo_files()`
3. **Check symlinks:**
   - Verify each target is a symlink
   - Check symlink points to dev-config directory
4. **Check dependencies:**
   - Required: git, zsh, tmux, docker
   - Optional: nvim, fzf, rg, lazygit, gh, docker-compose
   - Build tools: make, node, npm, pkg-config
   - External tools: imagemagick, mmdc (Mermaid CLI)
   - Version checks (Neovim ≥ 0.9.0, Docker ≥ 20.10)
   - Docker daemon status verification
   - Mason-installed tools validation
5. **Check external tools:**
   - Oh My Zsh, Powerlevel10k, zsh-autosuggestions
   - TPM
   - `.zshrc.local`
6. **Print summary:** Count issues, provide remediation

**Usage:**
```bash
bash scripts/validate.sh
```

**Exit codes:**
- `0` - All checks passed
- `1` - Issues found

## Common Patterns

### Sourcing Libraries

Every script must source the libraries:

```bash
#!/bin/bash
set -e

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"
```

**Important:** `common.sh` must be sourced before `paths.sh` (paths.sh depends on `get_repo_root()`)

### Error Handling

All scripts use `set -e` for fail-fast behavior. For graceful error handling:

```bash
if some_command; then
  log_success "Command succeeded"
else
  log_error "Command failed"
  return 1
fi
```

### Platform-Specific Logic

```bash
if is_macos; then
  # macOS-specific code
elif is_linux; then
  # Linux-specific code
fi
```

### Logging Best Practices

```bash
log_section "🚀 Major Step"
log_info "Starting process..."
log_success "Process completed"
log_warn "Optional component not found"
log_error "Critical error occurred"
```

## Adding New Functionality

### Adding a New Script

1. Create script in `scripts/`
2. Start with standard header:
   ```bash
   #!/bin/bash
   set -e
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/lib/common.sh"
   source "$SCRIPT_DIR/lib/paths.sh"
   ```
3. Use shared functions instead of duplicating code
4. Make executable: `chmod +x scripts/your-script.sh`

### Adding a New Symlink

1. Add source path to `lib/paths.sh`:
   ```bash
   readonly REPO_NEW_CONFIG="$REPO_ROOT/new-tool/config"
   ```
2. Add target path:
   ```bash
   readonly HOME_NEW_CONFIG="$HOME/.config/new-tool/config"
   ```
3. Add to `SYMLINK_PAIRS` array:
   ```bash
   ["$REPO_NEW_CONFIG"]="$HOME_NEW_CONFIG"
   ```
4. Add to `SYMLINK_TARGETS` array:
   ```bash
   "$HOME_NEW_CONFIG"
   ```
5. Scripts will automatically handle it!

### Adding a New Dependency

Add to `install.sh` in the `install_core_dependencies()` function:

```bash
local optional_packages=(neovim tmux fzf ripgrep lazygit your-new-tool)
```

## Testing

### Dry-Run Testing (Recommended)

Test scripts in a VM or container:
```bash
docker run -it ubuntu:latest bash
# Install git, clone repo, run install.sh
```

### Manual Testing Checklist

- [ ] Fresh install on macOS
- [ ] Fresh install on Linux (Debian/Fedora/Arch)
- [ ] Update with uncommitted changes (should prompt to stash)
- [ ] Update with clean repo
- [ ] Uninstall and verify backups restored
- [ ] Validate on broken installation
- [ ] Validate on working installation

## Cross-Platform Considerations

### Homebrew Paths
- macOS (Apple Silicon): `/opt/homebrew/bin/brew`
- macOS (Intel): `/usr/local/bin/brew`
- Linux: `/home/linuxbrew/.linuxbrew/bin/brew`

Handled by `lib/paths.sh` and `install.sh`.

### Ghostty Config Path
- macOS: `~/Library/Application Support/com.mitchellh.ghostty/config`
- Linux: `~/.config/ghostty/config`

Automatically detected by `lib/paths.sh`.

### Package Managers
- macOS: brew
- Debian/Ubuntu: apt
- Fedora/RHEL: dnf
- Arch: pacman
- openSUSE: zypper

All handled by `detect_package_manager()` and `install_package()`.

## Best Practices

1. **Never hardcode paths** - Always use variables from `lib/paths.sh`
2. **Always source libraries** - Don't duplicate functions
3. **Use consistent logging** - Use `log_*` functions for all output
4. **Handle errors gracefully** - Check return codes, provide helpful messages
5. **Make scripts idempotent** - Safe to run multiple times
6. **Test cross-platform** - Verify on macOS and Linux before committing
7. **Document new functions** - Add comments for complex logic
