#!/usr/bin/env bash
# DevPod Bootstrap - Auto-create tmux sessions for online DevPods
# Called from tmux.conf via run-shell on server start.
# Creates devpod_{project} sessions with session-scoped SSH.

# No sleep - run-shell blocks tmux until complete, so this runs synchronously

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
  # Remove any trailing -N suffix from project name (StatefulSet pod naming)
  PROJECT_NAME="${PROJECT_NAME%-[0-9]}"
  # tmux converts colons to underscores, so use underscore directly
  SESSION_NAME="devpod_${PROJECT_NAME}"
  SSH_TARGET="coder@${HOSTNAME}"

  # Skip if session already exists (e.g., restored by continuum)
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    continue
  fi

  # Create session and SSH with explicit shell to bypass login process
  # Container login shells fail with "mesg: cannot change mode" due to missing
  # CAP_FOWNER capability. Using 'exec zsh' skips the login.defs TTY chown.
  # Start in workspace directory - check for .git to find the actual repo location
  # Priority: /home/devpod > /workspace > ~ (but only if they contain a git repo)
  SSH_CMD="ssh -t $SSH_TARGET 'if [ -d /home/devpod/.git ]; then cd /home/devpod; elif [ -d /workspace/.git ]; then cd /workspace; elif [ -d ~/.git ] || [ -f ~/CLAUDE.md ]; then cd ~; else cd /home/devpod 2>/dev/null || cd /workspace 2>/dev/null || cd ~; fi; exec zsh'"
  tmux new-session -d -s "$SESSION_NAME" -e "DEVPOD_HOST=$HOSTNAME"
  tmux set-option -t "$SESSION_NAME" remain-on-exit on
  tmux send-keys -t "$SESSION_NAME" "$SSH_CMD" Enter
  tmux set-option -t "$SESSION_NAME" default-command "$SSH_CMD"

  # Start Mutagen sync if project has mutagen.yml
  PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"
  if [ -f "$PROJECT_DIR/mutagen.yml" ] && command -v mutagen &>/dev/null; then
    if ! mutagen project list -f "$PROJECT_DIR/mutagen.yml" &>/dev/null 2>&1; then
      (cd "$PROJECT_DIR" && mutagen project start) &>/dev/null &
      disown
    fi
  fi
done
