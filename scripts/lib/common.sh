#!/bin/bash
# Common utilities for dev-config scripts
# Source this file in other scripts: source "$(dirname "$0")/lib/common.sh"

# =============================================================================
# Color Codes for Output
# =============================================================================
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
  echo -e "${COLOR_CYAN}ℹ️  $1${COLOR_RESET}" >&2
}

log_success() {
  echo -e "${COLOR_GREEN}✅ $1${COLOR_RESET}" >&2
}

log_warn() {
  echo -e "${COLOR_YELLOW}⚠️  $1${COLOR_RESET}" >&2
}

log_error() {
  echo -e "${COLOR_RED}❌ $1${COLOR_RESET}" >&2
}

log_section() {
  echo "" >&2
  echo -e "${COLOR_BLUE}$1${COLOR_RESET}" >&2
  echo "" >&2
}

# =============================================================================
# OS Detection
# =============================================================================

detect_os() {
  case "$OSTYPE" in
    darwin*)  echo "macos" ;;
    linux*)   echo "linux" ;;
    msys*|cygwin*|win32) echo "windows" ;;
    *)        echo "unknown" ;;
  esac
}

is_macos() {
  [[ "$(detect_os)" == "macos" ]]
}

is_linux() {
  [[ "$(detect_os)" == "linux" ]]
}

# =============================================================================
# Package Manager Detection
# =============================================================================

detect_package_manager() {
  if command -v brew &> /dev/null; then
    echo "brew"
  elif command -v apt &> /dev/null; then
    echo "apt"
  elif command -v dnf &> /dev/null; then
    echo "dnf"
  elif command -v pacman &> /dev/null; then
    echo "pacman"
  elif command -v zypper &> /dev/null; then
    echo "zypper"
  else
    echo "none"
  fi
}

# =============================================================================
# Version Comparison
# =============================================================================

# Compare two semantic versions
# Returns: 0 if v1 >= v2, 1 otherwise
version_gte() {
  local v1=$1
  local v2=$2

  # Use sort -V for version comparison
  printf '%s\n%s\n' "$v2" "$v1" | sort -V -C
  return $?
}

# Get version of a command
get_command_version() {
  local cmd=$1
  local version_flag=${2:---version}

  if ! command -v "$cmd" &> /dev/null; then
    echo ""
    return 1
  fi

  $cmd $version_flag 2>&1 | head -n 1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?'
}

# =============================================================================
# Backup Management
# =============================================================================

create_backup() {
  local file_path=$1
  local timestamp=${2:-$(date +%Y%m%d_%H%M%S)}

  if [ -e "$file_path" ] && [ ! -L "$file_path" ]; then
    local backup_path="${file_path}.backup_${timestamp}"
    mv "$file_path" "$backup_path"
    log_success "Backed up $(basename "$file_path") → ${backup_path}"
    return 0
  fi
  return 1
}

restore_latest_backup() {
  local file_path=$1

  # Find most recent backup
  local latest_backup=$(ls -t "${file_path}.backup_"* 2>/dev/null | head -1)

  if [ -n "$latest_backup" ]; then
    mv "$latest_backup" "$file_path"
    log_success "Restored from backup: $(basename "$latest_backup")"
    return 0
  fi
  return 1
}

# =============================================================================
# Symlink Management
# =============================================================================

create_symlink() {
  local source=$1
  local target=$2
  local timestamp=${3:-$(date +%Y%m%d_%H%M%S)}

  # Ensure source exists
  if [ ! -e "$source" ]; then
    log_error "Source does not exist: $source"
    return 1
  fi

  # Ensure target parent directory exists
  local target_dir=$(dirname "$target")
  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
    log_info "Created directory: $target_dir"
  fi

  # Backup existing file/directory if not a symlink
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    create_backup "$target" "$timestamp"
  fi

  # Remove existing symlink if present
  if [ -L "$target" ]; then
    rm "$target"
  fi

  # Create symlink
  ln -sf "$source" "$target"

  # Verify symlink
  if [ -L "$target" ]; then
    log_success "Linked $(basename "$target") → $source"
    return 0
  else
    log_error "Failed to create symlink: $target → $source"
    return 1
  fi
}

remove_symlink() {
  local target=$1

  if [ -L "$target" ]; then
    rm "$target"
    log_success "Removed symlink: $(basename "$target")"

    # Attempt to restore backup
    restore_latest_backup "$target" || true
    return 0
  else
    log_warn "No symlink found at: $target"
    return 1
  fi
}

# =============================================================================
# Installation Helpers
# =============================================================================

command_exists() {
  command -v "$1" &> /dev/null
}

install_package() {
  local package_name=$1
  local pm=$(detect_package_manager)

  if command_exists "$package_name"; then
    log_success "$package_name already installed"
    return 0
  fi

  log_info "Installing $package_name via $pm..."

  case $pm in
    brew)
      brew install "$package_name"
      ;;
    apt)
      sudo apt update && sudo apt install -y "$package_name"
      ;;
    dnf)
      sudo dnf install -y "$package_name"
      ;;
    pacman)
      sudo pacman -S --noconfirm "$package_name"
      ;;
    zypper)
      sudo zypper install -y "$package_name"
      ;;
    none)
      log_error "No package manager found. Please install $package_name manually."
      return 1
      ;;
  esac

  if [ $? -eq 0 ]; then
    log_success "$package_name installed successfully"
    return 0
  else
    log_error "Failed to install $package_name"
    return 1
  fi
}

# Check if running with sudo unnecessarily
check_sudo() {
  if [ "$EUID" -eq 0 ]; then
    log_warn "Running as root/sudo. This script should be run as a normal user."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
}

# =============================================================================
# Git Helpers
# =============================================================================

get_repo_root() {
  if git rev-parse --show-toplevel &> /dev/null; then
    git rev-parse --show-toplevel
  else
    # Fallback to script location
    cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
  fi
}

# =============================================================================
# Confirmation Prompts
# =============================================================================

confirm() {
  local prompt=${1:-"Continue?"}
  local default=${2:-"N"}

  if [[ $default =~ ^[Yy]$ ]]; then
    read -p "$prompt (Y/n) " -n 1 -r
  else
    read -p "$prompt (y/N) " -n 1 -r
  fi

  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}
