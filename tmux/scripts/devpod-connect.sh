#!/usr/bin/env bash
set -euo pipefail

# DevPod Connect - Discover and connect to DevPods via Tailscale
# Creates tmux sessions with session-scoped SSH (all panes auto-SSH)
# Also starts Mutagen file sync if project has mutagen.yml

# --- Configuration ---
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"

# --- Tailscale CLI detection (macOS app vs PATH) ---
TAILSCALE=""
if command -v tailscale &>/dev/null; then
  TAILSCALE="tailscale"
elif [ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
  TAILSCALE="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
else
  echo "Error: tailscale CLI not found" >&2
  exit 1
fi

# --- Discover DevPods (online only, deduplicated by hostname) ---
DEVPODS=$("$TAILSCALE" status --json 2>/dev/null | jq -r '
  [.Peer | to_entries[]
  | select(.value.HostName | startswith("devpod-"))
  | {
      hostname: .value.HostName,
      ip: .value.TailscaleIPs[0],
      online: .value.Online,
      os: .value.OS
    }]
  | group_by(.hostname)
  | map(
      # Prefer online entry; if multiple, take first online
      (map(select(.online)) | first) // first
    )
  | map(select(.online))
  | sort_by(.hostname)[]
  | "\(.hostname)\t\(.ip)\t\(.os)"
')

if [ -z "$DEVPODS" ]; then
  echo "No online DevPods found on Tailnet" >&2
  read -r -p "Press Enter to close..."
  exit 1
fi

# --- fzf picker ---
SELECTED=$(echo "$DEVPODS" | column -t -s$'\t' | \
  fzf --reverse \
      --header="Select DevPod (Ctrl-C to cancel):" \
      --preview-window=hidden \
      --ansi)

if [ -z "$SELECTED" ]; then
  exit 0 # User cancelled
fi

# Extract hostname from selection (first column)
HOSTNAME=$(echo "$SELECTED" | awk '{print $1}')
# Strip "devpod-" prefix for project name (e.g., devpod-portfolio -> portfolio)
PROJECT_NAME="${HOSTNAME#devpod-}"
# tmux converts colons to underscores, so use underscore directly
SESSION_NAME="devpod_${PROJECT_NAME}"
SSH_TARGET="coder@${HOSTNAME}"

# --- Start Mutagen sync if project has mutagen.yml ---
start_mutagen_sync() {
  local project_dir="$PROJECTS_DIR/$PROJECT_NAME"

  if [[ -f "$project_dir/mutagen.yml" ]] && command -v mutagen &>/dev/null; then
    # Check if sync is already running for this project
    if ! mutagen project list -f "$project_dir/mutagen.yml" &>/dev/null; then
      # Start mutagen sync in background
      (cd "$project_dir" && mutagen project start) &
    fi
  fi
}

# --- Create session if needed ---
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  # Session doesn't exist, create it
  start_mutagen_sync

  # Create session and SSH with explicit shell to bypass login process
  # Container login shells fail with "mesg: cannot change mode" due to missing
  # CAP_FOWNER capability. Using 'exec zsh' skips the login.defs TTY chown.
  # Use send-keys approach (not running SSH as session command) so remain-on-exit works
  SSH_CMD="ssh -t $SSH_TARGET 'cd ~ && exec zsh'"

  # Start session in $HOME to avoid local direnv activation
  tmux new-session -d -s "$SESSION_NAME" -c "$HOME" -e "DEVPOD_HOST=$HOSTNAME"
  tmux set-option -t "$SESSION_NAME" remain-on-exit on
  tmux send-keys -t "$SESSION_NAME" "$SSH_CMD" Enter
  tmux set-option -t "$SESSION_NAME" default-command "$SSH_CMD"
fi

# Switch to session
# When called via 'run-shell' (not inside display-popup), switch-client is safe
tmux switch-client -t "$SESSION_NAME"
