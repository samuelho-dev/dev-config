#!/usr/bin/env bash
# Hermetic: only mocked curl/Claude and local test tools reach the bootstrap.
set -euo pipefail
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
bash_bin=$(command -v bash)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/downloads" "$tmp/session/bin" "$tmp/activation/bin"
for tool in bash mktemp rm cat mkdir cp chmod ln find; do
  ln -s "$(command -v "$tool")" "$tmp/bin/$tool"
done
export HOME="$tmp/home" TMPDIR="$tmp/downloads"
export CLAUDE_TEST_CURL_LOG="$tmp/curl.log" CLAUDE_TEST_INSTALL_LOG="$tmp/install.log"
export CLAUDE_TEST_INSTALLER="$tmp/installer" CLAUDE_TEST_CLI="$tmp/claude"
: > "$CLAUDE_TEST_CURL_LOG"
: > "$CLAUDE_TEST_INSTALL_LOG"
cat > "$CLAUDE_TEST_CLI" <<'MOCK'
#!/usr/bin/env bash
echo 'Existing Claude must not be invoked' >&2
exit 90
MOCK
chmod +x "$CLAUDE_TEST_CLI"
cat > "$CLAUDE_TEST_INSTALLER" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 0 ]] # Default floating latest, not a version or channel pin.
printf '%s\n' "$0" >> "$CLAUDE_TEST_INSTALL_LOG"
[[ -z "${CLAUDE_TEST_INSTALL_FAIL:-}" ]] || exit 42
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/claude/versions"
cp "$CLAUDE_TEST_CLI" "$HOME/.local/share/claude/versions/mock-native"
# Only the mocked official installer creates the native launcher.
ln -s "$HOME/.local/share/claude/versions/mock-native" "$HOME/.local/bin/claude"
MOCK
cat > "$tmp/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 4 && "$1" == -fsSL && "$2" == https://claude.ai/install.sh && "$3" == -o ]]
[[ -f "$4" && ! -s "$4" && "$4" == "$TMPDIR"/claude-bootstrap.* ]]
[[ -z "$(find "$TMPDIR" -type f ! -perm 600)" ]]
printf '%s\n' "$4" >> "$CLAUDE_TEST_CURL_LOG"
cat "$CLAUDE_TEST_INSTALLER" > "$4"
[[ -z "${CLAUDE_TEST_CURL_FAIL:-}" ]] || exit 23
MOCK
chmod +x "$tmp/bin/curl"
bootstrap() { PATH="$tmp/bin:$tmp/activation/bin:$tmp/session/bin" "$bash_bin" "$root/ai/claude/bootstrap.sh"; }
assert_clean() { [[ -z "$(find "$TMPDIR" -mindepth 1 -print)" ]]; }

# Preserve the native launcher, versioned binary, and all user-owned resources.
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/claude/versions" "$HOME/.claude/plugins" "$HOME/.claude/skills" "$HOME/.claude/agents" "$HOME/.claude/commands" "$HOME/.agents/skills"
cp "$CLAUDE_TEST_CLI" "$HOME/.local/share/claude/versions/existing"
ln -s "$HOME/.local/share/claude/versions/existing" "$HOME/.local/bin/claude"
for file in .claude/settings.json .claude/.credentials.json .claude/plugins/keep .claude/skills/keep .claude/agents/keep .claude/commands/keep .agents/skills/keep .claude.json; do
  printf 'user-owned %s\n' "$file" > "$HOME/$file"
done
cp -R "$HOME" "$tmp/home-before"
bootstrap
diff -r "$tmp/home-before" "$HOME"
[[ $(readlink "$HOME/.local/bin/claude") == "$HOME/.local/share/claude/versions/existing" ]]
[[ ! -s "$CLAUDE_TEST_CURL_LOG" && ! -s "$CLAUDE_TEST_INSTALL_LOG" ]]
rm "$HOME/.local/bin/claude"

# Each bounded PATH segment can supply an existing CLI, without executing it.
for location in "$tmp/bin" "$tmp/activation/bin" "$tmp/session/bin"; do
  cp "$CLAUDE_TEST_CLI" "$location/claude"
  bootstrap
  rm "$location/claude"
done
[[ ! -s "$CLAUDE_TEST_CURL_LOG" && ! -s "$CLAUDE_TEST_INSTALL_LOG" ]]
assert_clean

# A dry run requires no tools and does not read or write user configuration.
mkdir "$tmp/no-tools"
DRY_RUN_CMD=echo PATH="$tmp/no-tools" "$bash_bin" "$root/ai/claude/bootstrap.sh"
[[ ! -s "$CLAUDE_TEST_CURL_LOG" && ! -s "$CLAUDE_TEST_INSTALL_LOG" && ! -e "$HOME/.local/bin/claude" ]]
assert_clean

# Even a partially downloaded executable installer must never run on fetch failure.
status=0
CLAUDE_TEST_CURL_FAIL=1 bootstrap > "$tmp/error" 2>&1 || status=$?
[[ $status -eq 23 && ! -s "$CLAUDE_TEST_INSTALL_LOG" && ! -e "$HOME/.local/bin/claude" ]]
assert_clean
: > "$CLAUDE_TEST_CURL_LOG"

status=0
CLAUDE_TEST_INSTALL_FAIL=1 bootstrap > "$tmp/error" 2>&1 || status=$?
[[ $status -eq 42 && ! -e "$HOME/.local/bin/claude" ]]
assert_clean
: > "$CLAUDE_TEST_CURL_LOG"
: > "$CLAUDE_TEST_INSTALL_LOG"

# Missing CLI uses the official floating installer once; temporary file is private
# even with a permissive caller umask, and is removed on success and both failures.
(umask 000; bootstrap)
[[ -x "$HOME/.local/bin/claude" && -L "$HOME/.local/bin/claude" ]]
[[ $(wc -l < "$CLAUDE_TEST_CURL_LOG") -eq 1 && $(wc -l < "$CLAUDE_TEST_INSTALL_LOG") -eq 1 ]]
cmp "$CLAUDE_TEST_CURL_LOG" "$CLAUDE_TEST_INSTALL_LOG"
assert_clean
cp "$CLAUDE_TEST_CURL_LOG" "$tmp/curl-before"
cp "$CLAUDE_TEST_INSTALL_LOG" "$tmp/install-before"
cp -R "$HOME" "$tmp/installed-before"
bootstrap
cmp "$CLAUDE_TEST_CURL_LOG" "$tmp/curl-before"
cmp "$CLAUDE_TEST_INSTALL_LOG" "$tmp/install-before"
diff -r "$tmp/installed-before" "$HOME"
assert_clean
printf 'Claude bootstrap regression checks passed\n'
