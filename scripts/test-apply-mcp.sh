#!/usr/bin/env sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home/.omp/agent" "$tmp/home/.codex"
for command in bunx npx codex; do
  printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/$command"
  chmod +x "$tmp/bin/$command"
done
cat > "$tmp/bin/omp" <<'SH'
#!/bin/sh
printf "%s\n" "$@" >> "$OMP_ARG_LOG"
SH
cat > "$tmp/bin/op" <<'SH'
#!/bin/sh
touch "$OP_MARKER"
exit 1
SH
chmod +x "$tmp/bin/omp" "$tmp/bin/op"
printf '{"mcpServers":{"sentry":{"headers":{"Authorization":"old"}},"local":{"command":"local"}}}\n' > "$tmp/home/.omp/agent/mcp.json"
printf '{"mcpServers":{"custom":{"command":"local"}},"model":"keep"}\n' > "$tmp/home/.claude.json"
printf 'model = "keep"\n' > "$tmp/home/.codex/config.toml"
chmod 644 "$tmp/home/.omp/agent/mcp.json" "$tmp/home/.claude.json" "$tmp/home/.codex/config.toml"
export HOME="$tmp/home" PATH="$tmp/bin:$PATH" OP_MARKER="$tmp/op-called" OMP_ARG_LOG="$tmp/omp-argv"
export DEV_CONFIG_MCP_AUTH_SOURCE=env
export LINEAR_API_KEY=TEST_SECRET_LINEAR_987 SENTRY_MCP_KEY=TEST_SECRET_SENTRY_987
export POSTHOG_MCP_KEY=TEST_SECRET_POSTHOG_987 VERCEL_MCP_TOKEN=TEST_SECRET_VERCEL_987
export VERCEL_TOKEN=TEST_SECRET_LEGACY_VERCEL_987
sh "$root/ai/mcp/apply-mcp.sh" > "$tmp/output" 2> "$tmp/error"
test ! -e "$OP_MARKER"
python3 - "$tmp/home" "$tmp/output" "$tmp/error" "$tmp/omp-argv" <<'PY'
import json, pathlib, sys, tomllib
home = pathlib.Path(sys.argv[1])
claude = json.loads((home / '.claude.json').read_text())
omp = json.loads((home / '.omp/agent/mcp.json').read_text())
codex = tomllib.loads((home / '.codex/config.toml').read_text())
expected = {'linear-server', 'effect-docs', 'vercel', 'sentry', 'posthog'}
assert expected <= set(claude['mcpServers']) and expected <= set(omp['mcpServers'])
assert expected <= set(codex['mcp_servers'])
assert omp['mcpServers']['sentry']['headers']['Authorization'] == 'Sentry-Bearer TEST_SECRET_SENTRY_987'
assert omp['mcpServers']['posthog']['headers']['x-posthog-mcp-mode'] == 'tools'
assert claude['mcpServers']['vercel']['env']['VERCEL_TOKEN'] == 'TEST_SECRET_VERCEL_987'
assert omp['mcpServers']['vercel']['env']['VERCEL_TOKEN'] == 'TEST_SECRET_VERCEL_987'
assert codex['mcp_servers']['vercel']['env']['VERCEL_TOKEN'] == 'TEST_SECRET_VERCEL_987'
assert all('TEST_SECRET_LEGACY_VERCEL_987' not in json.dumps(config) for config in (claude, omp, codex))
assert claude['model'] == 'keep' and claude['mcpServers']['custom']['command'] == 'local'
assert omp['mcpServers']['local']['command'] == 'local'
assert all('TEST_SECRET_' not in pathlib.Path(path).read_text() for path in sys.argv[2:])
PY
cp "$tmp/home/.omp/agent/mcp.json" "$tmp/good-omp.json"
cp "$tmp/home/.claude.json" "$tmp/good-claude.json"
cp "$tmp/home/.codex/config.toml" "$tmp/good-codex.toml"
unset VERCEL_MCP_TOKEN
if sh "$root/ai/mcp/apply-mcp.sh" > "$tmp/output" 2> "$tmp/error"; then
  echo 'missing required MCP credential succeeded unexpectedly' >&2
  exit 1
fi
case "$(cat "$tmp/error")" in
  *"missing required MCP credential for vercel (env)"*) ;;
  *) echo 'required credential failure was not visible' >&2; exit 1 ;;
esac
case "$(cat "$tmp/error")" in
  *TEST_SECRET_*) echo 'credential leaked in renderer error' >&2; exit 1 ;;
esac
cmp "$tmp/good-omp.json" "$tmp/home/.omp/agent/mcp.json"
cmp "$tmp/good-claude.json" "$tmp/home/.claude.json"
cmp "$tmp/good-codex.toml" "$tmp/home/.codex/config.toml"
test ! -e "$OP_MARKER"
export VERCEL_MCP_TOKEN=TEST_SECRET_VERCEL_987 DEV_CONFIG_MCP_AUTH_SOURCE=op
if sh "$root/ai/mcp/apply-mcp.sh" > "$tmp/output" 2> "$tmp/error"; then
  echo 'op failure fell back to environment unexpectedly' >&2
  exit 1
fi
test -e "$OP_MARKER"
cmp "$tmp/good-omp.json" "$tmp/home/.omp/agent/mcp.json"
export DEV_CONFIG_MCP_AUTH_SOURCE=env
MCP_TARGET_CLAUDE=0 MCP_TARGET_OMP=0 MCP_TARGET_CODEX=0 \
  MCP_SERVERS_FILE="$tmp/absent.json" sh "$root/ai/mcp/apply-mcp.sh"
cmp "$tmp/good-omp.json" "$tmp/home/.omp/agent/mcp.json"
cmp "$tmp/good-claude.json" "$tmp/home/.claude.json"
cmp "$tmp/good-codex.toml" "$tmp/home/.codex/config.toml"
printf '{"mcpServers":{}}\n' > "$tmp/empty.json"
MCP_SERVERS_FILE="$tmp/empty.json" sh "$root/ai/mcp/apply-mcp.sh" > "$tmp/output" 2> "$tmp/error"
python3 - "$tmp/home" "$tmp/output" "$tmp/error" "$tmp/omp-argv" <<'PY'
import json, pathlib, sys, tomllib
home = pathlib.Path(sys.argv[1])
for path in (home / '.claude.json', home / '.omp/agent/mcp.json', home / '.codex/config.toml'):
    assert path.stat().st_mode & 0o777 == 0o600, path
assert all('TEST_SECRET_' not in pathlib.Path(path).read_text() for path in sys.argv[2:])
claude = json.loads((home / '.claude.json').read_text())
omp = json.loads((home / '.omp/agent/mcp.json').read_text())
codex = tomllib.loads((home / '.codex/config.toml').read_text())
assert claude['model'] == 'keep' and claude['mcpServers'] == {'custom': {'command': 'local'}}
assert omp['mcpServers'] == {'local': {'command': 'local'}}
assert codex['model'] == 'keep' and not codex.get('mcp_servers')
PY
