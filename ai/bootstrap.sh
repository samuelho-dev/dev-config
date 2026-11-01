#!/usr/bin/env bash
# One owner for writable native CLIs. Startup installs missing tools; updates are explicit.
set -euo pipefail
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
usage='usage: bootstrap.sh install|update|check [omp|pi|claude|opencode|codex|vercel|rex-worktrees ...]'
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
  case "$tool" in ''|'#'*|omp|pi|claude|opencode|codex|vercel|rex-worktrees) ;; *)
    echo "native-tools: unknown tool: $tool" >&2; exit 2 ;;
  esac
done
install_rex_worktrees() {
  local asset checksum filename expected actual entry stage target="$HOME/.local/share/dev-config/rex-worktrees"
  local launcher="$HOME/.local/bin/rex-worktrees"
  case "$(uname -s):$(uname -m)" in
    Darwin:arm64) asset=rex-worktrees-macos-arm64.tar.gz ;;
    Linux:x86_64) asset=rex-worktrees-linux-x64.tar.gz ;;
    *) echo 'native-tools: rex-worktrees has no release for this platform' >&2; return 1 ;;
  esac
  if [ -e "$launcher" ] || [ -L "$launcher" ]; then
    if [ ! -L "$launcher" ] || [ "$(readlink "$launcher")" != "$target/rex-worktrees" ]; then
      echo "native-tools: refusing to replace unmanaged launcher: $launcher" >&2; return 1
    fi
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ] || [ ! -d "$target" ] || [ ! -f "$target/.dev-config-owned" ] || [ -L "$target/.dev-config-owned" ]; then
      echo "native-tools: refusing to replace unmanaged installation: $target" >&2; return 1
    fi
  fi
  mkdir -p "$(dirname "$target")" "$(dirname "$launcher")"
  stage=$(mktemp -d "$(dirname "$target")/.rex-worktrees.XXXXXXXX")
  # ponytail: a sibling staging directory keeps failed downloads from touching the installed CLI.
  (
    trap 'if [ "$?" -ne 0 ] && [ -d "$stage/previous" ]; then rm -rf -- "$target"; mv "$stage/previous" "$target"; fi; rm -rf -- "$stage"' EXIT
    curl -fLsS "https://github.com/samuelho-dev/rex-worktrees/releases/latest/download/$asset" -o "$stage/$asset"
    curl -fLsS 'https://github.com/samuelho-dev/rex-worktrees/releases/latest/download/SHA256SUMS' -o "$stage/SHA256SUMS"
    expected=
    while read -r checksum filename; do
      if [ "$filename" = "$asset" ]; then
        [ -z "$expected" ] || exit 1
        expected=$checksum
      fi
    done < "$stage/SHA256SUMS"
    [[ "$expected" =~ ^[[:xdigit:]]{64}$ ]] || { echo "native-tools: missing valid checksum for $asset" >&2; exit 1; }
    if command -v sha256sum >/dev/null; then actual=$(sha256sum "$stage/$asset"); else actual=$(shasum -a 256 "$stage/$asset"); fi
    [ "${actual%% *}" = "$expected" ] || { echo "native-tools: $asset checksum mismatch" >&2; exit 1; }
    mkdir "$stage/release"
    while IFS= read -r entry; do
      case "$entry" in
        rex-worktrees|rex-worktrees.js|README.md|LICENSE|licenses/|licenses/THIRD-PARTY-NOTICES) ;;
        *) echo "native-tools: unexpected archive entry: $entry" >&2; exit 1 ;;
      esac
    done < <(tar -tzf "$stage/$asset")
    tar -xzf "$stage/$asset" -C "$stage/release"
    for entry in rex-worktrees rex-worktrees.js README.md LICENSE licenses/THIRD-PARTY-NOTICES; do
      [ -f "$stage/release/$entry" ] && [ ! -L "$stage/release/$entry" ] || { echo "native-tools: missing regular archive file: $entry" >&2; exit 1; }
    done
    [ -x "$stage/release/rex-worktrees" ] && "$stage/release/rex-worktrees" help >/dev/null || exit 1
    : > "$stage/release/.dev-config-owned"
    if [ -d "$target" ]; then
      mv "$target" "$stage/previous"
    fi
    mv "$stage/release" "$target"
    if [ ! -L "$launcher" ]; then ln -s "$target/rex-worktrees" "$launcher"; fi
    rm -rf -- "$stage/previous"
  )
}
for tool in "${tools[@]}"; do
  case "$tool" in ''|'#'*) continue ;; esac
  if [ "$tool" = rex-worktrees ]; then
    launcher="$HOME/.local/bin/rex-worktrees"
    target="$HOME/.local/share/dev-config/rex-worktrees"
    if [ -L "$launcher" ] && [ "$(readlink "$launcher")" = "$target/rex-worktrees" ] &&
       [ -f "$target/.dev-config-owned" ] && [ ! -L "$target" ] && [ ! -L "$target/.dev-config-owned" ] &&
       [ -x "$launcher" ] && "$launcher" help >/dev/null 2>&1; then
      [ "$action" != update ] && continue
    elif [ "$action" = check ]; then
      echo 'native-tools: managed rex-worktrees missing or cannot execute' >&2; exit 1
    elif [ "$action" = install ] && { [ -e "$launcher" ] || [ -L "$launcher" ] || [ -e "$target" ] || [ -L "$target" ]; }; then
      echo 'native-tools: existing rex-worktrees installation cannot execute; refusing to replace it' >&2; exit 1
    fi
    install_rex_worktrees
    if ! { [ -x "$launcher" ] && "$launcher" help >/dev/null; }; then
      echo 'native-tools: rex-worktrees failed execution after install' >&2; exit 1
    fi
    continue
  fi
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
