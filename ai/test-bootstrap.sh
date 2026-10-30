#!/usr/bin/env bash
# Run in an isolated HOME; the native installer and npm are mocked.
set -euo pipefail
source_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/home/.config/dev-config" "$fixture/bin"
printf 'omp' > "$fixture/home/.config/dev-config/native-tools"
cat > "$fixture/bin/omp" <<'SH'
#!/bin/sh
[ "$1" = --version ]
SH
cat > "$fixture/bin/npm" <<'SH'
#!/bin/sh
printf 'npm invoked\n' >> "$HOME/npm-invocations"
exit 1
SH
cat > "$fixture/bin/curl" <<'SH'
#!/bin/sh
printf 'native installer invoked\n' >> "$HOME/curl-invocations"
while [ "$#" -gt 0 ]; do
  if [ "$1" = -o ]; then shift; output=$1; fi
  shift
done
if [ "${OMP_FAKE_PARTIAL:-}" = 1 ]; then
  printf 'touch "$HOME/partial-executed"\n' > "$output"
  exit 22
fi
printf 'test "$PI_INSTALL_DIR" = "$HOME/.local/bin" || exit 1\nmkdir -p "$PI_INSTALL_DIR"\ncp "$OMP_FAKE_BINARY" "$PI_INSTALL_DIR/omp"\n' > "$output"
SH
chmod +x "$fixture/bin/omp" "$fixture/bin/npm" "$fixture/bin/curl"
export HOME="$fixture/home" PATH="$fixture/bin:/usr/bin:/bin" OMP_FAKE_BINARY="$fixture/bin/omp"
if /bin/bash "$source_dir/bootstrap.sh" check omp >/dev/null 2>&1; then
  echo 'non-native omp passed standalone check' >&2; exit 1
fi
mkdir -p "$HOME/.local/bin"
ln -s "$HOME/missing-omp" "$HOME/.local/bin/omp"
if /bin/bash "$source_dir/bootstrap.sh" check omp >/dev/null 2>&1; then
  echo 'broken standalone omp passed check' >&2; exit 1
fi
rm "$HOME/.local/bin/omp"
/bin/bash "$source_dir/bootstrap.sh" install
/bin/bash "$source_dir/bootstrap.sh" check
/bin/bash "$source_dir/bootstrap.sh" install omp
[ "$(wc -l < "$HOME/curl-invocations")" -eq 1 ]
[ ! -e "$HOME/npm-invocations" ]
if bash "$source_dir/bootstrap.sh" install omp unknown-tool >/dev/null 2>&1; then
  echo 'unknown tool was accepted' >&2; exit 1
fi
[ ! -e "$HOME/npm-invocations" ]
[ -x "$HOME/.local/bin/omp" ]
mkdir -p "$HOME/.local/bin"
ln -s "$HOME/missing-codex" "$HOME/.local/bin/codex"
if bash "$source_dir/bootstrap.sh" install codex >/dev/null 2>&1; then
  echo 'broken launcher was replaced' >&2; exit 1
fi
[ ! -e "$HOME/npm-invocations" ] && [ -L "$HOME/.local/bin/codex" ]
mkdir -p "$HOME/.claude/skills/research"
printf 'my edits\n' > "$HOME/.claude/skills/research/SKILL.md"
mkdir -p "$HOME/.agents/skills"
ln -s /nix/store/legacy/ai/skills/research "$HOME/.agents/skills/research"
bash "$source_dir/sync-skills.sh"
[ "$(cat "$HOME/.claude/skills/research/SKILL.md")" = 'my edits' ]
[ ! -e "$HOME/.claude/skills/research/agents" ]
[ -L "$HOME/.claude/skills/domain-modeling" ]
[ "$(readlink "$HOME/.agents/skills/research")" = /nix/store/legacy/ai/skills/research ]
[ -L "$HOME/.agents/skills/domain-modeling" ]
old=$(readlink "$HOME/.agents/skills/domain-modeling")
mkdir -p "$fixture/next/skills"
cp "$source_dir/sync-skills.sh" "$fixture/next/sync-skills.sh"
cp -R "$source_dir/skills/domain-modeling" "$fixture/next/skills/"
bash "$fixture/next/sync-skills.sh"
[ "$(readlink "$HOME/.agents/skills/domain-modeling")" = "$fixture/next/skills/domain-modeling" ]
[ "$(readlink "$HOME/.agents/skills/research")" = /nix/store/legacy/ai/skills/research ]
ln -sfn "$old" "$HOME/.agents/skills/domain-modeling"
bash "$fixture/next/sync-skills.sh"
[ "$(readlink "$HOME/.agents/skills/domain-modeling")" = "$old" ]
export HOME="$fixture/failed-home" OMP_FAKE_PARTIAL=1
mkdir -p "$HOME"
if bash "$source_dir/omp/install.sh" install >/dev/null 2>&1; then
  echo 'incomplete OMP fetch succeeded' >&2; exit 1
fi
[ ! -e "$HOME/partial-executed" ] && [ ! -e "$HOME/.local/bin/omp" ]
