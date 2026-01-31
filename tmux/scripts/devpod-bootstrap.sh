#!/usr/bin/env bash
# DevPod Bootstrap - Auto-create tmux sessions for online DevPods
# Called from tmux.conf via run-shell on server start.
# Creates devpod:{project} sessions with session-scoped SSH.

# Wait briefly for continuum restore to complete first
sleep 2

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"

# --- Tailscale CLI detection ---
TAILSCALE=""
if command -v tailscale &>/dev/null; then
  TAILSCALE="tailscale"
elif [ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
  TAILSCALE="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
else
  exit 0 # No tailscale, nothing to do
fi

# --- Get unique online DevPods ---
ONLINE_PODS=$("$TAILSCALE" status --json 2>/dev/null | jq -r '
  [.Peer | to_entries[]
  | select(.value.HostName | startswith("devpod-"))
  | select(.value.Online == true)
  | .value.HostName]
  | unique[]
') 2>/dev/null

if [ -z "$ONLINE_PODS" ]; then
  exit 0
fi

for HOSTNAME in $ONLINE_PODS; do
  PROJECT_NAME="${HOSTNAME#devpod-}"
  SESSION_NAME="devpod:${PROJECT_NAME}"
  SSH_TARGET="coder@${HOSTNAME}"

  # Skip if session already exists (e.g., restored by continuum)
  if tmux has-session -t "=${SESSION_NAME}" 2>/dev/null; then
    continue
  fi

  # Create session with SSH default command
  tmux new-session -d -s "$SESSION_NAME" -e "DEVPOD_HOST=$HOSTNAME" "ssh $SSH_TARGET"
  tmux set-option -t "=$SESSION_NAME" default-command "ssh $SSH_TARGET"

  # Start Mutagen sync if project has mutagen.yml
  PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"
  if [ -f "$PROJECT_DIR/mutagen.yml" ] && command -v mutagen &>/dev/null; then
    if ! mutagen project list -f "$PROJECT_DIR/mutagen.yml" &>/dev/null 2>&1; then
      (cd "$PROJECT_DIR" && mutagen project start) &>/dev/null &
      disown
    fi
  fi
done
