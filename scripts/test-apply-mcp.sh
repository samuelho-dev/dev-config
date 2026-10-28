#!/usr/bin/env sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home/.omp/agent" "$tmp/home/.codex"
printf '#!/bin/sh\nexit 1\n' > "$tmp/bin/op"
chmod +x "$tmp/bin/op"
printf '{"mcpServers":{"sentry":{"headers":{"Authorization":"old"}},"local":{"command":"local"}}}\n' > "$tmp/home/.omp/agent/mcp.json"
HOME="$tmp/home" PATH="$tmp/bin:$PATH" LINEAR_API_KEY=linear SENTRY_MCP_KEY=sentry POSTHOG_MCP_KEY=posthog VERCEL_TOKEN=vercel sh "$root/ai/mcp/apply-mcp.sh"
jq -e '.mcpServers.sentry.headers.Authorization == "Sentry-Bearer sentry" and .mcpServers.posthog.headers.Authorization == "Bearer posthog" and .mcpServers.posthog.headers."x-posthog-mcp-mode" == "tools" and .mcpServers.local.command == "local"' "$tmp/home/.omp/agent/mcp.json" >/dev/null
HOME="$tmp/home" PATH="$tmp/bin:$PATH" LINEAR_API_KEY=linear VERCEL_TOKEN=vercel sh "$root/ai/mcp/apply-mcp.sh"
jq -e '(.mcpServers | has("sentry") | not) and (.mcpServers | has("posthog") | not) and .mcpServers.local.command == "local"' "$tmp/home/.omp/agent/mcp.json" >/dev/null
python3 - "$tmp/home/.codex/config.toml" <<'PY'
import sys, tomllib
servers = tomllib.load(open(sys.argv[1], 'rb'))['mcp_servers']
assert 'sentry' not in servers and 'posthog' not in servers
assert servers['vercel']['env']['VERCEL_TOKEN'] == 'vercel'
PY
