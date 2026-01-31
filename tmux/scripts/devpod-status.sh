#!/usr/bin/env bash
# DevPod status for tmux status bar
# Outputs icon + count of active devpod: sessions (nothing if zero)

COUNT=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -c '^devpod:' || true)

if [ "$COUNT" -gt 0 ]; then
  printf '#[fg=#89b4fa]⚙ %d#[fg=default] ' "$COUNT"
fi
