#!/usr/bin/env bash
set -euo pipefail

# Debug logging
exec 2>/tmp/devpod-connect.log
echo "=== $(date) ===" >&2
echo "TMUX=${TMUX:-unset}" >&2

# DevPod Connect - Discover and connect to DevPods via Tailscale
# Creates tmux sessions with session-scoped SSH (all panes auto-SSH)
# Mutagen file sync is started by the session-created hook (devpod-mutagen-hook.sh)

# --- Tailscale CLI detection (macOS app vs PATH, with socket support) ---
TS_CMD=()
if command -v tailscale &>/dev/null; then
  TS_CMD=(tailscale)
elif [ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
  TS_CMD=("/Applications/Tailscale.app/Contents/MacOS/Tailscale")
else
  echo "Error: tailscale CLI not found" >&2
  exit 1
fi
# In-container Tailscale uses a custom socket path
if [ -n "${TS_SOCKET:-}" ] && [ -S "$TS_SOCKET" ]; then
  TS_CMD+=("--socket=$TS_SOCKET")
fi

# --- Discover DevPods (online only, deduplicated by hostname) ---
DEVPODS=$("${TS_CMD[@]}" status --json 2>/dev/null | jq -r '
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

# Filter out self when running from inside a devpod
if [ -n "${TS_HOSTNAME:-}" ]; then
  DEVPODS=$(echo "$DEVPODS" | grep -v "^${TS_HOSTNAME}	" || true)
fi

if [ -z "$DEVPODS" ]; then
  echo "No online DevPods found on Tailnet" >&2
  read -r -p "Press Enter to close..."
  exit 1
fi

# --- fzf picker (use fzf-tmux -p for popup) ---
# fzf-tmux -p creates popup overlay, script continues after popup closes
echo "DEVPODS found: $(echo "$DEVPODS" | wc -l)" >&2
echo "fzf-tmux path: $(which fzf-tmux 2>/dev/null || echo 'not found')" >&2

FZF_CMD="fzf"
if command -v fzf-tmux &>/dev/null && [ -n "${TMUX:-}" ]; then
  FZF_CMD="fzf-tmux -p -w 70% -h 60%"
fi
echo "FZF_CMD: $FZF_CMD" >&2

SELECTED=$(echo "$DEVPODS" | column -t -s$'\t' | \
  $FZF_CMD --reverse \
      --header="Select DevPod (Ctrl-C to cancel):" \
      --preview-window=hidden \
      --ansi)
echo "SELECTED: '$SELECTED'" >&2

if [ -z "$SELECTED" ]; then
  exit 0 # User cancelled
fi

# Extract hostname from selection (first column)
HOSTNAME=$(echo "$SELECTED" | awk '{print $1}')
# Strip "devpod-" prefix for project name (e.g., devpod-portfolio -> portfolio)
PROJECT_NAME="${HOSTNAME#devpod-}"
# tmux converts colons to underscores, so use underscore directly
SESSION_NAME="devpod_${PROJECT_NAME}"
# Resolve the Tailnet MagicDNS suffix dynamically (do not hardcode it).
# Falls back to the bare hostname (MagicDNS resolves it) if lookup fails.
DNS_SUFFIX=$("${TS_CMD[@]}" status --json 2>/dev/null | jq -r '.MagicDNSSuffix // empty')
if [ -n "$DNS_SUFFIX" ]; then
  SSH_HOST="${HOSTNAME}.${DNS_SUFFIX}"
else
  SSH_HOST="$HOSTNAME"
fi
SSH_TARGET="coder@${SSH_HOST}"

# --- Create session if needed ---
# NOTE: tmux new-session inside display-popup can crash tmux (Issue #3748)
# The -d flag creates detached session which is safe
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  # Create session and SSH into devpod.
  # Use the same SSH form as devpod-bootstrap.sh: explicit TTY + `exec zsh`
  # bypasses the container login shell, which fails with "mesg: cannot change
  # mode" due to missing CAP_FOWNER. Start in ~ (not the workspace) to avoid
  # triggering local direnv/nix on connect.
  SSH_CMD="ssh -t $SSH_TARGET 'cd ~ && exec zsh'"

  # Using -d (detached) is safe inside popup per tmux issue #3748
  tmux new-session -d -s "$SESSION_NAME" -c "$HOME" -e "DEVPOD_HOST=$HOSTNAME"
  tmux set-option -t "$SESSION_NAME" remain-on-exit on
  tmux send-keys -t "$SESSION_NAME" "$SSH_CMD" Enter
  tmux set-option -t "$SESSION_NAME" default-command "$SSH_CMD"
  # Mutagen sync is started by the session-created hook (devpod-mutagen-hook.sh)
fi

# Switch to session
# This runs AFTER fzf-tmux popup closes, so switch-client works correctly
echo "Switching to session: $SESSION_NAME" >&2
tmux switch-client -t "$SESSION_NAME"
echo "Switch exit code: $?" >&2
