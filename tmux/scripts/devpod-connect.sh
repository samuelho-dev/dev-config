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

# --- Discover DevPods ---
DEVPODS=$("$TAILSCALE" status --json 2>/dev/null | jq -r '
  .Peer | to_entries[]
  | select(.value.HostName | startswith("devpod-"))
  | {
      hostname: .value.HostName,
      ip: .value.TailscaleIPs[0],
      online: .value.Online,
      os: .value.OS
    }
  | "\(.hostname)\t\(if .online then "online" else "offline" end)\t\(.ip)\t\(.os)"
')

if [ -z "$DEVPODS" ]; then
  echo "No DevPods found on Tailnet" >&2
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
SESSION_NAME="devpod:${PROJECT_NAME}"
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

# --- Create or switch to session ---
if tmux has-session -t "=$SESSION_NAME" 2>/dev/null; then
  # Session exists, switch to it
  tmux switch-client -t "=$SESSION_NAME"
else
  # Start mutagen sync for this project (runs in background)
  start_mutagen_sync

  # Create new session with default-command set to SSH
  # Every new pane/window in this session will auto-SSH to the DevPod
  tmux new-session -d -s "$SESSION_NAME" -e "DEVPOD_HOST=$HOSTNAME" "ssh $SSH_TARGET"
  tmux set-option -t "=$SESSION_NAME" default-command "ssh $SSH_TARGET"
  tmux switch-client -t "=$SESSION_NAME"
fi
