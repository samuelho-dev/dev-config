#!/usr/bin/env bash
# One owner for writable native CLIs. Startup installs missing tools; updates are explicit.
set -euo pipefail
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
usage='usage: bootstrap.sh install|update|check [omp|pi|claude|opencode|codex|vercel ...]'
[ "$#" -gt 0 ] || { echo "$usage" >&2; exit 2; }
action=$1
shift
case "$action" in install|update|check) ;; *) echo "$usage" >&2; exit 2 ;; esac
export PATH="$HOME/.local/bin:$PATH"
if [ "$#" -eq 0 ]; then
  if [ -f "$HOME/.config/dev-config/native-tools" ]; then
    tools=()
    while IFS= read -r tool || [ -n "$tool" ]; do tools+=("$tool"); done < "$HOME/.config/dev-config/native-tools"
  else
    tools=(omp pi claude opencode codex vercel)
  fi
else
  tools=("$@")
fi
for tool in "${tools[@]}"; do
  case "$tool" in ''|'#'*|omp|pi|claude|opencode|codex|vercel) ;; *)
    echo "native-tools: unknown tool: $tool" >&2; exit 2 ;;
  esac
done
for tool in "${tools[@]}"; do
  case "$tool" in ''|'#'*) continue ;; esac
  case "$tool" in claude) command=claude ;; *) command=$tool ;; esac
  if [ "$action" = check ] && [ "$tool" = omp ] && [ ! -x "$HOME/.local/bin/omp" ]; then
    echo 'native-tools: standalone omp missing from ~/.local/bin' >&2
    exit 1
  fi
  if [ "$action" = check ]; then
    if ! command -v "$command" >/dev/null || ! "$command" --version >/dev/null; then
      echo "native-tools: $tool missing or cannot execute" >&2; exit 1
    fi
    if [ "$tool" = vercel ]; then
      if ! command -v vc >/dev/null || ! vc --version >/dev/null; then
        echo "native-tools: vc alias missing or cannot execute" >&2; exit 1
      fi
    fi
    continue
  fi
  if [ "$action" = install ] && [ "$tool" = omp ]; then
    # A Bun shim is not the standalone OMP binary required by the broker.
    if [ -e "$HOME/.local/bin/omp" ] || [ -L "$HOME/.local/bin/omp" ]; then
      if [ -x "$HOME/.local/bin/omp" ] && "$HOME/.local/bin/omp" --version >/dev/null 2>&1; then continue; fi
      echo 'native-tools: existing standalone omp cannot execute; refusing to replace it' >&2
      exit 1
    fi
  elif [ "$action" = install ]; then
    if command -v "$command" >/dev/null; then
      if "$command" --version >/dev/null 2>&1; then
        [ "$tool" != pi ] || bash "$script_dir/pi/apply-plugins.sh"
        continue
      fi
      echo "native-tools: $tool exists but cannot execute; refusing to overwrite" >&2
      exit 1
    fi
    if [ -e "$HOME/.local/bin/$command" ] || [ -L "$HOME/.local/bin/$command" ]; then
      echo "native-tools: existing $tool launcher cannot execute; refusing to replace it" >&2
      exit 1
    fi
  fi
  case "$tool" in
    omp) bash "$script_dir/omp/install.sh" "$action" ;;
    pi) bash "$script_dir/pi/bootstrap.sh" "$action" ;;
    claude) bash "$script_dir/claude/bootstrap.sh" "$action" ;;
    opencode|codex|vercel)
      command -v npm >/dev/null || { echo "native-tools: npm is required for $tool" >&2; exit 1; }
      case "$tool" in opencode) package=opencode-ai ;; codex) package=@openai/codex ;; vercel) package=vercel ;; esac
      npm install --global --prefix "$HOME/.local" "$package@latest"
      ;;
  esac
  if ! command -v "$command" >/dev/null || ! "$command" --version >/dev/null; then
    echo "native-tools: $tool failed execution after $action" >&2; exit 1
  fi
done
# npm provides vc with a local Vercel install; preserve any existing launcher.
if [ "$action" != check ] && [[ " ${tools[*]} " == *' vercel '* ]] && ! command -v vc >/dev/null && [ ! -e "$HOME/.local/bin/vc" ] && [ ! -L "$HOME/.local/bin/vc" ]; then
  mkdir -p "$HOME/.local/bin"
  ln -s "$(command -v vercel)" "$HOME/.local/bin/vc"
fi
