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

# --- Create or switch to session ---
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  # Session exists, switch to it
  tmux switch-client -t "$SESSION_NAME"
else
  # Start mutagen sync for this project (runs in background)
  start_mutagen_sync

  # Create new session with default-command set to SSH
  # Every new pane/window in this session will auto-SSH to the DevPod
  # -t forces PTY allocation (required for Tailscale SSH interactive sessions)
  # cd to workspace: /home/devpod (standard) or /home/coder (fallback)
  # bash -i (not login) avoids tty chown failure in containers (exit code 1)
  SSH_CMD="ssh -t $SSH_TARGET 'cd /home/devpod 2>/dev/null || cd /home/coder; exec bash -i'"
  tmux new-session -d -s "$SESSION_NAME" -e "DEVPOD_HOST=$HOSTNAME" "$SSH_CMD"
  tmux set-option -t "$SESSION_NAME" default-command "$SSH_CMD"
  tmux switch-client -t "$SESSION_NAME"
fi
