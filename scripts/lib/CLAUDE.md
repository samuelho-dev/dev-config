# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with shared script libraries.

## Directory Purpose

The `lib/` directory contains **shared Bash libraries** that eliminate code duplication across all scripts. This follows DRY (Don't Repeat Yourself) principles.

## Architecture Philosophy

### Before: Code Duplication

```bash
# install.sh (350 lines)
log_info() { echo -e "${BLUE}$1${NC}"; }
create_backup() { ... }
create_symlink() { ... }
# ... 200 lines of functions ...

# update.sh (120 lines)
log_info() { echo -e "${BLUE}$1${NC}"; }  # DUPLICATED
create_backup() { ... }  # DUPLICATED
# ... functions duplicated ...

# uninstall.sh (80 lines)
log_info() { echo -e "${BLUE}$1${NC}"; }  # DUPLICATED AGAIN
# ... more duplication ...
```

**Problems:**
- Fix a bug → Must update 3+ files
- Add feature → Copy/paste to all scripts
- Inconsistent implementations
- Hard to maintain

### After: Shared Libraries

```bash
# lib/common.sh (250 lines)
log_info() { echo -e "${BLUE}$1${NC}"; }
create_backup() { ... }
create_symlink() { ... }
# ... all functions in one place ...

# install.sh (150 lines)
source "$SCRIPT_DIR/lib/common.sh"
log_info "Using shared function"  # No duplication!

# update.sh (60 lines)
source "$SCRIPT_DIR/lib/common.sh"
log_info "Same function"  # No duplication!
```

**Benefits:**
- Fix a bug → Update one file
- Add feature → Write once
- Consistent behavior
- Easy to maintain
- 90% code reduction in main scripts

## File Responsibilities

### common.sh

**Purpose:** Reusable utility functions for all scripts

**Categories:**

**1. Logging (lines 10-35)**
- Color constants (`COLOR_RED`, `COLOR_GREEN`, etc.)
- Logging functions (`log_info`, `log_success`, `log_warn`, `log_error`, `log_section`)
- Why separate: Consistent output formatting across all scripts

**2. OS Detection (lines 37-60)**
- `detect_os()` - Returns OS name
- `is_macos()`, `is_linux()` - Boolean checks
- Why separate: Cross-platform compatibility logic centralized

**3. Package Manager Detection (lines 62-90)**
- `detect_package_manager()` - Auto-detect package manager
- `install_package()` - Platform-agnostic package installation
- Why separate: Supports multiple Linux distributions

**4. Version Management (lines 92-120)**
- `version_gte()` - Semantic version comparison
- `get_command_version()` - Extract version from command output
- Why separate: Dependency version checking

**5. Backup & Restore (lines 122-160)**
- `create_backup()` - Timestamped file backups
- `restore_latest_backup()` - Restore most recent backup
- Why separate: Atomic backup operations

**6. Symlink Management (lines 162-210)**
- `create_symlink()` - Create symlink with auto-backup
- `remove_symlink()` - Remove symlink and restore backup
- Why separate: Complex symlink logic with validation

**7. Helpers (lines 212-250)**
- `command_exists()` - Check command availability
- `check_sudo()` - Warn if running as root
- `get_repo_root()` - Auto-detect repository root
- `confirm()` - Y/N prompt with default
- Why separate: Frequently used utilities

### paths.sh

**Purpose:** Single source of truth for all file paths

**Why critical:**
- **Before:** Hardcoded paths in every script → breaks if structure changes
- **After:** Change path once in paths.sh → all scripts updated

**Structure:**

**1. Auto-Detection (lines 5-7)**
```bash
REPO_ROOT=$(get_repo_root)  # Uses common.sh function
```

**2. Repository Paths (lines 9-20)**
```bash
readonly REPO_NVIM="$REPO_ROOT/nvim"
readonly REPO_TMUX_CONF="$REPO_ROOT/tmux/tmux.conf"
# ... all source paths ...
```

**3. Home Paths (lines 22-50)**
```bash
readonly HOME_NVIM="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
readonly HOME_TMUX_CONF="$HOME/.tmux.conf"
# ... all target paths ...
```

**4. Platform-Specific Paths (lines 52-60)**
```bash
if is_macos; then
  readonly HOME_GHOSTTY_CONFIG="$HOME/Library/Application Support/..."
else
  readonly HOME_GHOSTTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
fi
```

**5. Symlink Arrays (lines 62-85)**
```bash
SYMLINK_SOURCES=(
  "$REPO_NVIM"
  "$REPO_TMUX_CONF"
  # ...
)

SYMLINK_TARGETS=(
  "$HOME_NVIM"
  "$HOME_TMUX_CONF"
  # ...
)
```

**6. Helper Functions (lines 87-96)**
- `print_paths()` - Debug output
- `verify_repo_files()` - Check sources exist

## Loading Order (CRITICAL)

### Correct Order

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# MUST load common.sh first
source "$SCRIPT_DIR/lib/common.sh"

# THEN load paths.sh (depends on get_repo_root from common.sh)
source "$SCRIPT_DIR/lib/paths.sh"
```

### Why This Order

**paths.sh depends on common.sh:**
```bash
# paths.sh:5-7
REPO_ROOT=$(get_repo_root)  # Calls function from common.sh!
```

**If loaded in wrong order:**
```bash
source "$SCRIPT_DIR/lib/paths.sh"   # FAILS
# Error: get_repo_root: command not found

source "$SCRIPT_DIR/lib/common.sh"  # Too late
```

## Common Modification Patterns

### Adding a Logging Function

**Add to common.sh logging section:**
```bash
# Around line 30
log_debug() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    echo -e "${COLOR_CYAN}[DEBUG] $1${COLOR_RESET}"
  fi
}
```

**Use in scripts:**
```bash
DEBUG=1 bash scripts/install.sh  # Enable debug mode
```

### Adding an OS Detection Function

**Add to common.sh OS detection section:**
```bash
# Around line 55
is_arch() {
  [[ -f /etc/arch-release ]]
}

is_ubuntu() {
  [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release
}
```

**Use in scripts:**
```bash
if is_arch; then
  log_info "Running on Arch Linux"
  # Arch-specific logic
fi
```

### Adding a New Path

**1. Add to paths.sh:**
```bash
# Repository path (around line 20)
readonly REPO_NEW_CONFIG="$REPO_ROOT/newconfig"

# Home path (around line 40)
readonly HOME_NEW_CONFIG="$HOME/.config/newconfig"

# Add to symlink arrays (around line 70)
SYMLINK_SOURCES+=(
  "$REPO_NEW_CONFIG"
)

SYMLINK_TARGETS+=(
  "$HOME_NEW_CONFIG"
)
```

**2. Use in scripts:**
```bash
source "$SCRIPT_DIR/lib/paths.sh"

create_symlink "$REPO_NEW_CONFIG" "$HOME_NEW_CONFIG" "$TIMESTAMP"
```

**Benefits:**
- No hardcoded paths in scripts
- Change path once, affects all scripts
- Easy to refactor directory structure

### Adding a Helper Function

**Add to common.sh helpers section:**
```bash
# Around line 240
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

**Use in scripts:**
```bash
download_file "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
```

## Function Design Patterns

### Boolean Check Pattern

```bash
is_something() {
  # Return 0 for true, 1 for false
  if [[ condition ]]; then
    return 0
  else
    return 1
  fi
}

# Simplified
is_something() {
  [[ condition ]]
}

# Usage
if is_something; then
  echo "True"
fi
```

### Value Return Pattern

```bash
get_something() {
  local result="computed_value"
  echo "$result"  # Return via stdout
}

# Usage
VALUE=$(get_something)
```

### Error Handling Pattern

```bash
safe_function() {
  local required_param="$1"

  # Validate input
  if [[ -z "$required_param" ]]; then
    log_error "Missing required parameter"
    return 1
  fi

  # Do work
  if some_command; then
    log_success "Success"
    return 0
  else
    log_error "Failed"
    return 1
  fi
}

# Usage
if safe_function "param"; then
  echo "Succeeded"
else
  echo "Failed"
fi
```

### Platform-Specific Pattern

```bash
platform_specific_action() {
  if is_macos; then
    # macOS-specific code
    brew install package
  elif is_linux; then
    # Linux-specific code
    PKG_MGR=$(detect_package_manager)
    install_package "package"
  else
    log_warn "Unsupported platform"
    return 1
  fi
}
```

## Integration with Scripts

### install.sh Integration

**Uses from common.sh:**
- Logging (all functions)
- OS detection
- Package manager detection
- Package installation
- Backup/symlink creation
- Version comparison
- Repo root detection

**Uses from paths.sh:**
- All repository paths
- All home paths
- Symlink arrays for iteration
- Path verification

### update.sh Integration

**Uses from common.sh:**
- Logging
- Repo root detection

**Uses from paths.sh:**
- Repository paths
- Minimal (mostly uses git commands)

### uninstall.sh Integration

**Uses from common.sh:**
- Logging
- Symlink removal
- Backup restoration
- Confirmation prompt

**Uses from paths.sh:**
- Symlink targets for iteration
- Home paths

## Testing Shared Functions

### Test Individual Function

```bash
# Source libraries
source scripts/lib/common.sh
source scripts/lib/paths.sh

# Test function
detect_os
# Output: macos

version_gte "2.0.0" "1.9.0"
echo $?  # 0 (true)

print_paths  # Show all paths
```

### Test Script with Debug

```bash
# Add debug output to script
#!/bin/bash
set -x  # Enable debug mode

source "$SCRIPT_DIR/lib/common.sh"
# ... rest of script ...
```

### Verify Paths

```bash
# Source and print
source scripts/lib/common.sh
source scripts/lib/paths.sh

print_paths
verify_repo_files
```

## Best Practices

### Function Documentation

```bash
# Brief description of function
# Arguments:
#   $1 - First parameter description
#   $2 - Second parameter description
# Returns:
#   0 - Success
#   1 - Failure
# Example:
#   my_function "arg1" "arg2"
my_function() {
  local param1="$1"
  local param2="$2"
  # Implementation
}
```

### Error Messages

```bash
# Good: Actionable error
log_error "Git is required. Install with: brew install git"

# Bad: Vague error
log_error "Missing dependency"
```

### Readonly Variables

```bash
# Use readonly for paths that shouldn't change
readonly REPO_ROOT=$(get_repo_root)
readonly HOME_NVIM="$HOME/.config/nvim"

# Attempting to change will fail
REPO_ROOT="/other/path"  # Error: readonly variable
```

### Exit Codes

```bash
# Return meaningful exit codes
function process_file() {
  if [[ ! -f "$1" ]]; then
    log_error "File not found"
    return 2  # File not found
  fi

  if ! validate_file "$1"; then
    log_error "File invalid"
    return 3  # Validation failed
  fi

  # Process file
  return 0  # Success
}
```

## For Future Claude Code Instances

**When modifying shared libraries:**

1. **Add to correct file:**
   - Utility function → common.sh
   - Path definition → paths.sh

2. **Add to correct section:**
   - Logging → logging section
   - OS detection → OS section
   - Package management → package section

3. **Respect loading order:**
   - common.sh loads first
   - paths.sh loads second
   - Don't create circular dependencies

4. **Test thoroughly:**
   - Test on macOS and Linux
   - Verify all scripts still work
   - Check edge cases

5. **Update documentation:**
   - Add function to lib/README.md (user-facing)
   - Update this file (architectural)
   - Update scripts/CLAUDE.md if workflow changes

6. **Common tasks:**
   - Add logging function → common.sh logging section
   - Add OS check → common.sh OS detection section
   - Add path → paths.sh + add to symlink arrays
   - Add helper → common.sh helpers section
