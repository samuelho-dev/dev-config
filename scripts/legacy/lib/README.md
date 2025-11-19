# Shared Script Libraries

This directory contains shared Bash libraries used by all scripts in the `scripts/` directory. This eliminates code duplication and provides consistent interfaces for common operations.

## Files

| File | Lines | Purpose |
|------|-------|---------|
| `common.sh` | ~250 | Utility functions (logging, OS detection, backups, package management) |
| `paths.sh` | ~100 | Centralized path definitions (single source of truth) |

## Architecture

### DRY Principles

**Before (duplicated code):**
```bash
# install.sh
log_info() { echo -e "${BLUE}$1${NC}"; }
# ... 50 lines of functions ...

# update.sh
log_info() { echo -e "${BLUE}$1${NC}"; }  # Duplicated!
# ... 50 lines of functions ...
```

**After (shared libraries):**
```bash
# install.sh
source "$(dirname "$0")/lib/common.sh"
log_info "Using shared function"

# update.sh
source "$(dirname "$0")/lib/common.sh"
log_info "Same function, no duplication"
```

### Loading Order

**Critical:** `common.sh` must be sourced before `paths.sh`

```bash
#!/bin/bash
set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load libraries in order
source "$SCRIPT_DIR/lib/common.sh"  # FIRST - provides get_repo_root()
source "$SCRIPT_DIR/lib/paths.sh"   # SECOND - uses get_repo_root()
```

**Why this order:**
- `paths.sh` calls `get_repo_root()` from `common.sh`
- Loading paths.sh first will fail with "command not found"

## common.sh

### Logging Functions

**Color-coded output for clarity:**

```bash
log_info "Informational message"     # Cyan
log_success "Operation succeeded"    # Green
log_warn "Warning message"           # Yellow
log_error "Error occurred"           # Red (to stderr)
log_section "=== Major Step ==="     # Blue header
```

**Usage in scripts:**
```bash
source "$SCRIPT_DIR/lib/common.sh"

log_section "🚀 Starting Installation"
log_info "Checking dependencies..."
log_success "All dependencies found ✓"
log_warn "Optional package not found"
log_error "Critical error occurred"
```

### OS Detection

**Detect operating system:**

```bash
OS=$(detect_os)  # Returns: "macos", "linux", "windows", or "unknown"

# Boolean checks
if is_macos; then
  echo "Running on macOS"
fi

if is_linux; then
  echo "Running on Linux"
fi
```

### Package Manager Detection

**Auto-detect package manager:**

```bash
PKG_MGR=$(detect_package_manager)
# Returns: "brew", "apt", "dnf", "pacman", "zypper", or "none"

# Install package using detected manager
install_package "git"
install_package "neovim"
```

**Supported package managers:**
- **brew** - macOS (Homebrew)
- **apt** - Debian/Ubuntu
- **dnf** - Fedora/RHEL/CentOS
- **pacman** - Arch/Manjaro
- **zypper** - openSUSE

### Version Comparison

**Compare semantic versions:**

```bash
if version_gte "2.0.0" "1.9.0"; then
  echo "Version is >= 1.9.0"
fi

# Get version from command
NVIM_VERSION=$(get_command_version "nvim" "--version")
if version_gte "$NVIM_VERSION" "0.9.0"; then
  echo "Neovim is up to date"
fi
```

### Backup & Restore

**Create timestamped backups:**

```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Backup file before overwriting
create_backup "$HOME/.zshrc" "$TIMESTAMP"
# Creates: ~/.zshrc.backup_20251008_143022

# Restore most recent backup
restore_latest_backup "$HOME/.zshrc"
# Restores: ~/.zshrc.backup_YYYYMMDD_HHMMSS → ~/.zshrc
```

### Symlink Management

**Create symlinks with automatic backup:**

```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create symlink (backs up existing file automatically)
create_symlink "/source/path" "/target/path" "$TIMESTAMP"

# Remove symlink and restore backup
remove_symlink "/target/path"
```

**Features:**
- Auto-creates parent directories
- Backs up existing files before symlinking
- Atomic operations (fail-safe)
- Verifies symlink points to correct source

### Repository Detection

**Auto-detect repository root:**

```bash
REPO_ROOT=$(get_repo_root)
# Uses: git rev-parse --show-toplevel
# Returns: /Users/user/Projects/dev-config
```

**Why important:**
- No hardcoded paths
- Works from any subdirectory
- Cross-machine compatible

### Helper Functions

```bash
# Check if command exists
if command_exists "nvim"; then
  echo "Neovim is installed"
fi

# Warn if running as root
check_sudo  # Prints warning if running as root

# User confirmation prompt
if confirm "Proceed with installation?" "y"; then
  echo "User confirmed"
fi
```

## paths.sh

### Purpose

**Single source of truth for all file paths.** No hardcoded paths in main scripts!

### Auto-Detected Paths

```bash
REPO_ROOT=$(get_repo_root)  # Repository root via git
```

### Repository Paths (Sources)

```bash
REPO_NVIM="$REPO_ROOT/nvim"
REPO_TMUX_CONF="$REPO_ROOT/tmux/tmux.conf"
REPO_GHOSTTY_CONFIG="$REPO_ROOT/ghostty/config"
REPO_ZSHRC="$REPO_ROOT/zsh/.zshrc"
REPO_ZPROFILE="$REPO_ROOT/zsh/.zprofile"
REPO_P10K="$REPO_ROOT/zsh/.p10k.zsh"
```

### Home Directory Paths (Targets)

```bash
HOME_NVIM="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
HOME_TMUX_CONF="$HOME/.tmux.conf"
HOME_ZSHRC="$HOME/.zshrc"
HOME_ZPROFILE="$HOME/.zprofile"
HOME_P10K="$HOME/.p10k.zsh"

# Platform-specific
if is_macos; then
  HOME_GHOSTTY_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
else
  HOME_GHOSTTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
fi
```

### External Tool Paths

```bash
# Oh My Zsh
OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"
P10K_THEME_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

# Tmux Plugin Manager
TPM_DIR="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins/tpm}"
```

### Symlink Arrays

**For iteration in scripts:**

```bash
# Parallel arrays (Bash 3.2 compatible)
SYMLINK_SOURCES=(
  "$REPO_NVIM"
  "$REPO_TMUX_CONF"
  "$REPO_GHOSTTY_CONFIG"
  "$REPO_ZSHRC"
  "$REPO_ZPROFILE"
  "$REPO_P10K"
)

SYMLINK_TARGETS=(
  "$HOME_NVIM"
  "$HOME_TMUX_CONF"
  "$HOME_GHOSTTY_CONFIG"
  "$HOME_ZSHRC"
  "$HOME_ZPROFILE"
  "$HOME_P10K"
)

# Usage in scripts
for i in "${!SYMLINK_SOURCES[@]}"; do
  source="${SYMLINK_SOURCES[$i]}"
  target="${SYMLINK_TARGETS[$i]}"
  create_symlink "$source" "$target" "$TIMESTAMP"
done
```

### Helper Functions

```bash
# Debug: Print all paths
print_paths

# Verify all source files exist
verify_repo_files
```

## Using Shared Libraries

### Basic Script Template

```bash
#!/bin/bash
set -e  # Exit on error

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"

# Use shared functions
log_section "🚀 My Script"

if ! command_exists "git"; then
  log_error "Git is required"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
create_symlink "$REPO_ZSHRC" "$HOME_ZSHRC" "$TIMESTAMP"

log_success "Script completed ✓"
```

### Common Patterns

**Check prerequisites:**
```bash
source "$SCRIPT_DIR/lib/common.sh"

log_info "Checking prerequisites..."

if ! command_exists "git"; then
  log_error "Git is required"
  exit 1
fi

OS=$(detect_os)
if [[ "$OS" == "unknown" ]]; then
  log_error "Unsupported operating system"
  exit 1
fi

log_success "All prerequisites met ✓"
```

**Install packages:**
```bash
source "$SCRIPT_DIR/lib/common.sh"

log_info "Installing dependencies..."

PKG_MGR=$(detect_package_manager)
if [[ "$PKG_MGR" == "none" ]]; then
  log_error "No supported package manager found"
  exit 1
fi

install_package "git"
install_package "zsh"
install_package "tmux"

log_success "Dependencies installed ✓"
```

**Create symlinks:**
```bash
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"

log_section "🔗 Creating Symlinks"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

for i in "${!SYMLINK_SOURCES[@]}"; do
  source="${SYMLINK_SOURCES[$i]}"
  target="${SYMLINK_TARGETS[$i]}"

  log_info "Linking $target → $source"
  create_symlink "$source" "$target" "$TIMESTAMP"
done

log_success "All symlinks created ✓"
```

## Adding New Functionality

### Adding a Function to common.sh

```bash
# Add to appropriate section in common.sh

# Example: Add download function
download_file() {
  local url="$1"
  local dest="$2"

  if command_exists "curl"; then
    curl -fsSL "$url" -o "$dest"
  elif command_exists "wget"; then
    wget -q "$url" -O "$dest"
  else
    log_error "Neither curl nor wget available"
    return 1
  fi
}
```

### Adding a Path to paths.sh

```bash
# Add to appropriate section in paths.sh

# Repository path
readonly REPO_NEW_CONFIG="$REPO_ROOT/newconfig"

# Home path
readonly HOME_NEW_CONFIG="$HOME/.config/newconfig"

# Add to symlink arrays
SYMLINK_SOURCES+=(
  "$REPO_NEW_CONFIG"
)

SYMLINK_TARGETS+=(
  "$HOME_NEW_CONFIG"
)
```

## Related Documentation

- **[scripts/README.md](../README.md)** - Scripts overview
- **[scripts/CLAUDE.md](../CLAUDE.md)** - Script architecture
- **[docs/INSTALLATION.md](../../docs/INSTALLATION.md)** - Installation guide
- **[CLAUDE.md](../../CLAUDE.md)** - Repository architecture
