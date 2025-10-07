#!/bin/bash
# Centralized path definitions for dev-config
# Source this file after common.sh

# Auto-detect repository root
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT=$(get_repo_root)
fi

readonly REPO_ROOT

# =============================================================================
# Repository Paths (Source)
# =============================================================================

readonly REPO_NVIM="$REPO_ROOT/nvim"
readonly REPO_TMUX_CONF="$REPO_ROOT/tmux/tmux.conf"
readonly REPO_GHOSTTY_CONFIG="$REPO_ROOT/ghostty/config"
readonly REPO_ZSHRC="$REPO_ROOT/zsh/.zshrc"
readonly REPO_ZPROFILE="$REPO_ROOT/zsh/.zprofile"
readonly REPO_P10K="$REPO_ROOT/zsh/.p10k.zsh"

# =============================================================================
# Home Directory Paths (Targets)
# =============================================================================

HOME_NVIM="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
HOME_TMUX_CONF="$HOME/.tmux.conf"
HOME_ZSHRC="$HOME/.zshrc"
HOME_ZSHRC_LOCAL="$HOME/.zshrc.local"
HOME_ZPROFILE="$HOME/.zprofile"
HOME_P10K="$HOME/.p10k.zsh"

# Ghostty config path (platform-specific)
if is_macos; then
  HOME_GHOSTTY_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
else
  # Linux XDG path
  HOME_GHOSTTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
fi

# =============================================================================
# External Tool Paths
# =============================================================================

OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"
P10K_THEME_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
ZSH_AUTOSUGGESTIONS_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
TPM_DIR="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins/tpm}"

# =============================================================================
# Path Arrays for Iteration
# =============================================================================

# Parallel arrays for source→target symlink pairs
# (Compatible with Bash 3.2 - associative arrays require Bash 4.0+)
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

# =============================================================================
# Helper Functions
# =============================================================================

# Print all paths for debugging
print_paths() {
  log_section "Repository Paths"
  echo "REPO_ROOT: $REPO_ROOT"
  echo "REPO_NVIM: $REPO_NVIM"
  echo "REPO_TMUX_CONF: $REPO_TMUX_CONF"
  echo "REPO_GHOSTTY_CONFIG: $REPO_GHOSTTY_CONFIG"
  echo "REPO_ZSHRC: $REPO_ZSHRC"
  echo "REPO_ZPROFILE: $REPO_ZPROFILE"
  echo "REPO_P10K: $REPO_P10K"

  log_section "Target Paths"
  echo "HOME_NVIM: $HOME_NVIM"
  echo "HOME_TMUX_CONF: $HOME_TMUX_CONF"
  echo "HOME_GHOSTTY_CONFIG: $HOME_GHOSTTY_CONFIG"
  echo "HOME_ZSHRC: $HOME_ZSHRC"
  echo "HOME_ZPROFILE: $HOME_ZPROFILE"
  echo "HOME_P10K: $HOME_P10K"

  log_section "External Tools"
  echo "OH_MY_ZSH_DIR: $OH_MY_ZSH_DIR"
  echo "P10K_THEME_DIR: $P10K_THEME_DIR"
  echo "ZSH_AUTOSUGGESTIONS_DIR: $ZSH_AUTOSUGGESTIONS_DIR"
  echo "TPM_DIR: $TPM_DIR"
}

# Verify all repository source files exist
verify_repo_files() {
  local missing_files=()

  [ ! -d "$REPO_NVIM" ] && missing_files+=("$REPO_NVIM")
  [ ! -f "$REPO_TMUX_CONF" ] && missing_files+=("$REPO_TMUX_CONF")
  [ ! -f "$REPO_GHOSTTY_CONFIG" ] && missing_files+=("$REPO_GHOSTTY_CONFIG")
  [ ! -f "$REPO_ZSHRC" ] && missing_files+=("$REPO_ZSHRC")
  [ ! -f "$REPO_ZPROFILE" ] && missing_files+=("$REPO_ZPROFILE")
  [ ! -f "$REPO_P10K" ] && missing_files+=("$REPO_P10K")

  if [ ${#missing_files[@]} -gt 0 ]; then
    log_error "Missing repository files:"
    for file in "${missing_files[@]}"; do
      echo "  - $file"
    done
    return 1
  fi

  return 0
}
