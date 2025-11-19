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

    if [ "$DRY_RUN" -eq 1 ]; then
      log_dry_run "Would backup: $(basename "$file_path") → ${backup_path}"
      return 0
    fi

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

  if [ "$DRY_RUN" -eq 1 ]; then
    log_dry_run "Would link: $(basename "$target") → $source"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      log_dry_run "  └─ Would backup existing file first"
    fi
    return 0
  fi

  # Ensure target parent directory exists
  local target_dir
  target_dir=$(dirname "$target")
  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
    log_verbose "Created directory: $target_dir"
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

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -L "$target" ]; then
      log_dry_run "Would remove symlink: $(basename "$target")"
      local latest_backup
      latest_backup=$(ls -t "${target}.backup_"* 2>/dev/null | head -1)
      if [ -n "$latest_backup" ]; then
        log_dry_run "  └─ Would restore backup: $(basename "$latest_backup")"
      fi
    else
      log_dry_run "No symlink at: $target (skip)"
    fi
    return 0
  fi

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
  local force_install=${2:-false}
  local pm
  pm=$(detect_package_manager)

  if [ "$force_install" != "true" ] && command_exists "$package_name"; then
    log_success "$package_name already installed"
    return 0
  fi

  if [ "$pm" = "none" ]; then
    log_error "No supported package manager detected. Install $package_name manually."
    return 1
  fi

  log_info "Installing $package_name via $pm..."

  case $pm in
    brew)
      if brew list --versions "$package_name" >/dev/null 2>&1; then
        if [ "$force_install" = "true" ]; then
          brew upgrade "$package_name" || brew install "$package_name"
        else
          log_success "$package_name already installed"
          return 0
        fi
      else
        brew install "$package_name"
      fi
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
    *)
      log_warn "Package manager $pm not explicitly handled; attempting generic install"
      $pm install "$package_name"
      ;;
  esac

  local install_status=$?
  if [ $install_status -ne 0 ]; then
    log_error "Failed to install $package_name with $pm (exit code $install_status)"
    if [ "$pm" = "brew" ]; then
      log_warn "Ensure Homebrew is healthy: brew update && brew doctor"
    fi
    if command_exists sudo && [ "$pm" != "brew" ]; then
      log_warn "You may need sudo privileges to install $package_name manually."
    fi
    return 1
  fi

  refresh_package_manager_env "$pm"
  log_success "$package_name installed successfully"
  return 0
}

refresh_package_manager_env() {
  local pm=$1
  case $pm in
    brew)
      if command_exists brew; then
        eval "$(brew shellenv)" || true
        hash -r
      fi
      ;;
  esac
}

# Check if running with sudo unnecessarily
check_sudo() {
  if [ "$EUID" -eq 0 ]; then
    log_error "Please rerun without sudo/root; dev-config must be installed as your normal user."
    exit 1
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

# =============================================================================
# Global Flags for Dry-Run and Verbose Mode
# =============================================================================

# Set these to 1 in scripts via command-line flags
DRY_RUN=${DRY_RUN:-0}
VERBOSE=${VERBOSE:-0}

log_verbose() {
  if [ "$VERBOSE" -eq 1 ]; then
    echo -e "${COLOR_CYAN}[VERBOSE] $1${COLOR_RESET}" >&2
  fi
}

log_dry_run() {
  echo -e "${COLOR_YELLOW}[DRY-RUN] $1${COLOR_RESET}" >&2
}

# =============================================================================
# Enhanced Tool Verification
# =============================================================================

# Verify tool is installed and meets minimum version requirement
# Arguments:
#   $1 - tool: Command name (e.g., "nvim", "tmux", "docker")
#   $2 - min_version: Minimum required version (e.g., "0.9.0")
#   $3 - version_flag: Flag to get version (optional, default: --version)
# Returns:
#   0 - Tool installed and version >= min_version
#   1 - Tool not installed or version < min_version
# Example:
#   verify_tool_version "nvim" "0.9.0" "-v"
verify_tool_version() {
  local tool=$1
  local min_version=$2
  local version_flag=${3:---version}

  if ! command_exists "$tool"; then
    log_warn "$tool not installed"
    return 1
  fi

  local version
  version=$(get_command_version "$tool" "$version_flag")

  if [ -z "$version" ]; then
    log_warn "$tool version could not be determined"
    return 1
  fi

  if version_gte "$version" "$min_version"; then
    log_success "$tool $version (✓ >= $min_version)"
    return 0
  else
    log_warn "$tool $version (< $min_version - may have issues)"
    return 1
  fi
}

# =============================================================================
# Docker Helpers
# =============================================================================

# Check Docker daemon status
# Returns:
#   0 - Docker running
#   1 - Docker not running (but installed)
#   2 - Docker not installed
check_docker_daemon() {
  if ! command_exists docker; then
    return 2
  fi

  if docker info >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# =============================================================================
# Network Helpers
# =============================================================================

# Check network connectivity
# Returns:
#   0 - Network available
#   1 - No network connectivity
check_network() {
  log_verbose "Checking network connectivity..."

  if curl -s --max-time 5 https://github.com >/dev/null 2>&1; then
    log_verbose "Network connectivity verified"
    return 0
  else
    log_error "No network connectivity detected. Please check your internet connection."
    return 1
  fi
}

# =============================================================================
# Shell Detection
# =============================================================================

# Get current user's default login shell
# Returns: Shell path (e.g., /bin/zsh)
get_current_shell() {
  local shell=""

  # Try getent (Linux)
  if command_exists getent; then
    shell=$(getent passwd "$USER" | cut -d: -f7)
  # Try dscl (macOS)
  elif command_exists dscl; then
    shell=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
  fi

  # Fallback to $SHELL environment variable
  [ -z "$shell" ] && shell="${SHELL:-}"

  echo "$shell"
}

# =============================================================================
# Homebrew Helpers
# =============================================================================

# Get Homebrew binary path
# Returns: Path to brew binary, or empty string if not found
get_brew_path() {
  if [ -f /opt/homebrew/bin/brew ]; then
    echo "/opt/homebrew/bin/brew"
  elif [ -f /usr/local/bin/brew ]; then
    echo "/usr/local/bin/brew"
  elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    echo "/home/linuxbrew/.linuxbrew/bin/brew"
  else
    echo ""
  fi
}

# Initialize Homebrew environment
init_brew() {
  local brew_path
  brew_path=$(get_brew_path)

  if [ -n "$brew_path" ]; then
    log_verbose "Initializing Homebrew from $brew_path"
    eval "$($brew_path shellenv)"
  fi
}

# =============================================================================
# Git Repository Helpers
# =============================================================================

# Clone a git repository with error handling
# Arguments:
#   $1 - repo_url: Git repository URL
#   $2 - dest_dir: Destination directory
#   $3 - depth: Clone depth (optional, default: full clone)
# Returns:
#   0 - Success
#   1 - Failure
# Example:
#   install_git_repo "https://github.com/user/repo.git" "$HOME/.repo" 1
install_git_repo() {
  local repo_url=$1
  local dest_dir=$2
  local depth=${3:-}

  if [ "$DRY_RUN" -eq 1 ]; then
    log_dry_run "Would clone: $repo_url → $dest_dir"
    return 0
  fi

  local clone_args=()
  if [ -n "$depth" ]; then
    clone_args+=("--depth=$depth")
  fi

  log_verbose "Cloning $repo_url to $dest_dir (depth: ${depth:-full})"

  if git clone "${clone_args[@]}" "$repo_url" "$dest_dir" 2>&1; then
    log_success "Cloned: $(basename "$dest_dir")"
    return 0
  else
    log_error "Failed to clone $repo_url"
    log_info "Check network connection and repository URL"
    return 1
  fi
}

# =============================================================================
# Progress Indicators
# =============================================================================

# Wait for a condition with spinner animation
# Arguments:
#   $1 - message: Display message
#   $2 - check_command: Command to run (returns 0 when ready)
#   $3 - max_seconds: Timeout in seconds (default: 60)
#   $4 - interval: Check interval in seconds (default: 2)
# Returns:
#   0 - Condition met within timeout
#   1 - Timeout exceeded
# Example:
#   wait_with_spinner "Starting service" "curl -s localhost:8080" 30 1
wait_with_spinner() {
  local message=$1
  local check_command=$2
  local max_seconds=${3:-60}
  local interval=${4:-2}

  local elapsed=0
  local spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
  local i=0

  if [ "$DRY_RUN" -eq 1 ]; then
    log_dry_run "$message (would wait max ${max_seconds}s)"
    return 0
  fi

  while [ $elapsed -lt $max_seconds ]; do
    if eval "$check_command" >/dev/null 2>&1; then
      echo -e "\r${COLOR_GREEN}✅ $message (${elapsed}s)${COLOR_RESET}" >&2
      return 0
    fi

    # Spinner animation
    local frame="${spinner:i++%${#spinner}:1}"
    echo -ne "\r${COLOR_CYAN}${frame} $message (${elapsed}s/${max_seconds}s)${COLOR_RESET}" >&2

    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  echo -e "\r${COLOR_RED}❌ $message (timeout after ${max_seconds}s)${COLOR_RESET}" >&2
  return 1
}
