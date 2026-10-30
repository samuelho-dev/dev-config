#!/usr/bin/env bash
# Fill missing skills without replacing physical user directories, edits or auth.
set -euo pipefail
source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/skills" && pwd)
umask 077
state_dir=$HOME/.local/state/dev-config
manifest=$state_dir/skill-links
record_link() {
  mkdir -p "$state_dir"
  chmod 700 "$state_dir"
  local pending
  pending=$(mktemp "$state_dir/.skill-links.XXXXXXXX")
  if [ -f "$manifest" ]; then
    while IFS=$'\t' read -r path previous || [ -n "$path" ]; do
      [ "$path" = "$1" ] || printf '%s\t%s\n' "$path" "$previous" >> "$pending"
    done < "$manifest"
  fi
  printf '%s\t%s\n' "$1" "$2" >> "$pending"
  mv -f "$pending" "$manifest"
}
for destination in "$HOME/.agents/skills" "$HOME/.omp/skills" "$HOME/.pi/agent/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills"; do
  [ ! -L "$destination" ] || continue
  mkdir -p "$destination"
  for source in "$source_dir"/*; do
    [ -d "$source" ] || continue
    name=${source##*/}
    target=$destination/$name
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
      ln -s "$source" "$target"
      record_link "$target" "$source"
    elif [ -L "$target" ] && [ -f "$manifest" ]; then
      old=$(readlink "$target")
      recorded=''
      while IFS=$'\t' read -r path previous || [ -n "$path" ]; do
        [ "$path" != "$target" ] || recorded=$previous
      done < "$manifest"
      if [ -n "$recorded" ] && [ "$old" = "$recorded" ] && [ "$old" != "$source" ]; then
        ln -sfn "$source" "$target"
        record_link "$target" "$source"
      fi
    fi
  done
done
