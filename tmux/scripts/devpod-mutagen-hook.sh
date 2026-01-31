#!/usr/bin/env bash
# Mutagen auto-sync hook for DevPod sessions
# Called by tmux session-created hook with session name as argument
# Starts mutagen project sync if session matches devpod:* pattern

SESSION_NAME="$1"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"

# Only process devpod: sessions
if [[ ! "$SESSION_NAME" =~ ^devpod: ]]; then
  exit 0
fi

# Extract project name from session (devpod:portfolio -> portfolio)
PROJECT_NAME="${SESSION_NAME#devpod:}"
PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"

# Check if project has mutagen.yml and mutagen is available
if [[ ! -f "$PROJECT_DIR/mutagen.yml" ]] || ! command -v mutagen &>/dev/null; then
  exit 0
fi

# Check if sync is already running for this project
if mutagen project list -f "$PROJECT_DIR/mutagen.yml" &>/dev/null 2>&1; then
  exit 0  # Already running
fi

# Start mutagen sync in background (fire and forget)
(cd "$PROJECT_DIR" && mutagen project start) &>/dev/null &
disown
