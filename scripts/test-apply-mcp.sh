#!/usr/bin/env sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home/.omp/agent" "$tmp/home/.codex"
real_jq=$(command -v jq)
printf '#!/bin/sh\nprintf "%%s\\n" "$@" >> "$ARG_LOG"\nexec "$REAL_JQ" "$@"\n' > "$tmp/bin/jq"
chmod +x "$tmp/bin/jq"
printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/op"
chmod +x "$tmp/bin/op"
printf '{"mcpServers":{"sentry":{"headers":{"Authorization":"old"}},"local":{"command":"local"}}}\n' > "$tmp/home/.omp/agent/mcp.json"
printf '{"mcpServers":{"custom":{"command":"local"}},"model":"keep"}\n' > "$tmp/home/.claude.json"
printf 'model = "keep"\n' > "$tmp/home/.codex/config.toml"
chmod 644 "$tmp/home/.omp/agent/mcp.json" "$tmp/home/.claude.json" "$tmp/home/.codex/config.toml"
HOME="$tmp/home" PATH="$tmp/bin:$PATH" REAL_JQ="$real_jq" ARG_LOG="$tmp/jq-argv" LINEAR_API_KEY=TEST_SECRET_LINEAR_987 SENTRY_MCP_KEY=TEST_SECRET_SENTRY_987 POSTHOG_MCP_KEY=TEST_SECRET_POSTHOG_987 VERCEL_TOKEN=TEST_SECRET_VERCEL_987 sh "$root/ai/mcp/apply-mcp.sh"
"$real_jq" -e '.mcpServers.sentry.headers.Authorization == "Sentry-Bearer TEST_SECRET_SENTRY_987" and .mcpServers.posthog.headers.Authorization == "Bearer TEST_SECRET_POSTHOG_987" and .mcpServers.posthog.headers."x-posthog-mcp-mode" == "tools" and .mcpServers.local.command == "local"' "$tmp/home/.omp/agent/mcp.json" >/dev/null
HOME="$tmp/home" PATH="$tmp/bin:$PATH" REAL_JQ="$real_jq" ARG_LOG="$tmp/jq-argv" LINEAR_API_KEY=TEST_SECRET_LINEAR_987 VERCEL_TOKEN=TEST_SECRET_VERCEL_987 sh "$root/ai/mcp/apply-mcp.sh"
"$real_jq" -e '(.mcpServers | has("sentry") | not) and (.mcpServers | has("posthog") | not) and .mcpServers.local.command == "local"' "$tmp/home/.omp/agent/mcp.json" >/dev/null
python3 - "$tmp/home" "$tmp/jq-argv" <<'PY'
import json, os, pathlib, sys, tomllib
home = pathlib.Path(sys.argv[1])
for path in (home / '.claude.json', home / '.omp/agent/mcp.json', home / '.codex/config.toml'):
    assert path.stat().st_mode & 0o777 == 0o600, path
assert 'TEST_SECRET_' not in pathlib.Path(sys.argv[2]).read_text()
assert json.loads((home / '.claude.json').read_text())['model'] == 'keep'
assert json.loads((home / '.claude.json').read_text())['mcpServers']['custom']['command'] == 'local'
servers = tomllib.loads((home / '.codex/config.toml').read_text())
assert servers['model'] == 'keep'
assert 'sentry' not in servers['mcp_servers'] and 'posthog' not in servers['mcp_servers']
assert servers['mcp_servers']['vercel']['env']['VERCEL_TOKEN'] == 'TEST_SECRET_VERCEL_987'
PY
