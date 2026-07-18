#!/usr/bin/env sh
# Fan out the canonical MCP server list to every agent CLI that speaks .mcp.json:
#   - Claude Code : ~/.claude.json          (.mcpServers, .enableAllProjectMcpServers)
#   - OMP         : ~/.omp/agent/mcp.json    (.mcpServers)   + `omp config set mcp.enableProjectConfig`
#   - Codex       : ~/.codex/config.toml     ([mcp_servers.*] managed block)
#
# Single source of truth: ai/mcp/servers.json (this dir). Called from BOTH the
# home-manager activation (real nix machines) and the devpod/orca container
# entrypoints, so all environments render the SAME servers with no drift.
#
# Secret resolution per environment: 1Password (auth.op) when `op` is on PATH,
# otherwise the env var named by auth.env (K8s-injected in containers).
#
# Env knobs (all optional):
#   MCP_SERVERS_FILE   path to servers.json         (default: alongside this script)
#   MCP_ENABLE_PROJECT true|false                   (default: true)
#   MCP_TARGET_CLAUDE  1|0                           (default: 1)
#   MCP_TARGET_OMP     1|0                           (default: 1)
#   MCP_TARGET_CODEX   1|0                           (default: 1)
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SERVERS_FILE="${MCP_SERVERS_FILE:-$SCRIPT_DIR/servers.json}"
ENABLE_PROJECT="${MCP_ENABLE_PROJECT:-true}"
DO_CLAUDE="${MCP_TARGET_CLAUDE:-1}"
DO_OMP="${MCP_TARGET_OMP:-1}"
DO_CODEX="${MCP_TARGET_CODEX:-1}"

if ! command -v jq >/dev/null 2>&1; then
  echo "mcp: jq not found; skipping MCP config" >&2
  exit 0
fi
if [ ! -f "$SERVERS_FILE" ]; then
  echo "mcp: no servers file at $SERVERS_FILE; skipping" >&2
  exit 0
fi

# Resolve every server's `auth` hint into a concrete header, then drop the hint
# so the output is a clean .mcp.json shape the CLIs understand.
RESOLVED=$(jq -c '.mcpServers // {}' "$SERVERS_FILE")
for name in $(printf '%s' "$RESOLVED" | jq -r 'keys[]'); do
  auth=$(printf '%s' "$RESOLVED" | jq -c --arg n "$name" '.[$n].auth // empty')
  [ -n "$auth" ] || continue
  header=$(printf '%s' "$auth" | jq -r '.header')
  prefix=$(printf '%s' "$auth" | jq -r '.prefix // ""')
  opref=$(printf '%s' "$auth" | jq -r '.op // ""')
  envname=$(printf '%s' "$auth" | jq -r '.env // ""')
  envkey=$(printf '%s' "$auth" | jq -r '.envKey // ""')

  secret=""
  if [ -n "$opref" ] && command -v op >/dev/null 2>&1; then
    secret=$(op read "$opref" 2>/dev/null || echo "")
  fi
  if [ -z "$secret" ] && [ -n "$envname" ]; then
    secret=$(printenv "$envname" 2>/dev/null || echo "")
  fi

  if [ -n "$secret" ]; then
    if [ -n "$envkey" ]; then
      # stdio server: inject the resolved secret into the child process env
      # (envKey) instead of an HTTP header — the CLIs pass .env to the subprocess.
      RESOLVED=$(printf '%s' "$RESOLVED" | jq -c \
        --arg n "$name" --arg k "$envkey" --arg v "$secret" \
        '.[$n].env[$k] = $v | del(.[$n].auth)')
    else
      RESOLVED=$(printf '%s' "$RESOLVED" | jq -c \
        --arg n "$name" --arg h "$header" --arg v "$prefix$secret" \
        '.[$n].headers[$h] = $v | del(.[$n].auth)')
    fi
  else
    echo "mcp: WARN no secret for '$name' (op:$opref env:$envname); server listed without auth" >&2
    RESOLVED=$(printf '%s' "$RESOLVED" | jq -c --arg n "$name" 'del(.[$n].auth)')
  fi
done

# ── Claude Code ────────────────────────────────────────────────────────────
if [ "$DO_CLAUDE" = "1" ]; then
  CJSON="$HOME/.claude.json"
  [ -f "$CJSON" ] || printf '{}\n' > "$CJSON"
  tmp=$(mktemp)
  jq --argjson servers "$RESOLVED" --argjson proj "$ENABLE_PROJECT" \
    '.mcpServers = ((.mcpServers // {}) + $servers) | .enableAllProjectMcpServers = $proj' \
    "$CJSON" > "$tmp" && mv "$tmp" "$CJSON"
  echo "mcp: wrote $CJSON"
fi

# ── OMP ────────────────────────────────────────────────────────────────────
if [ "$DO_OMP" = "1" ]; then
  OMP_DIR="$HOME/.omp/agent"
  mkdir -p "$OMP_DIR"
  OJSON="$OMP_DIR/mcp.json"
  [ -f "$OJSON" ] || printf '{}\n' > "$OJSON"
  tmp=$(mktemp)
  jq --argjson servers "$RESOLVED" \
    '.["$schema"] = (.["$schema"] // "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json")
     | .mcpServers = ((.mcpServers // {}) + $servers)' \
    "$OJSON" > "$tmp" && mv "$tmp" "$OJSON"
  echo "mcp: wrote $OJSON"
  if command -v omp >/dev/null 2>&1; then
    omp config set mcp.enableProjectConfig "$ENABLE_PROJECT" >/dev/null 2>&1 || true
  fi
fi

# ── Codex ──────────────────────────────────────────────────────────────────
# Codex config.toml is hand/tool-maintained, so only rewrite our marked block
# and preserve everything else (model, profiles, etc.).
if [ "$DO_CODEX" = "1" ] && command -v python3 >/dev/null 2>&1; then
  CODEX_DIR="$HOME/.codex"
  mkdir -p "$CODEX_DIR"
  CODEX_TOML="$CODEX_DIR/config.toml"
  [ -f "$CODEX_TOML" ] || : > "$CODEX_TOML"
  RESOLVED="$RESOLVED" CODEX_TOML="$CODEX_TOML" python3 - <<'PY'
import json, os, re

BEGIN = "# >>> dev-config managed mcp servers >>>"
END = "# <<< dev-config managed mcp servers <<<"

servers = json.loads(os.environ["RESOLVED"])
path = os.environ["CODEX_TOML"]


def toml_str(value):
    # JSON string escapes are a valid subset of TOML basic-string escapes.
    return json.dumps(str(value))


def toml_arr(values):
    return "[" + ", ".join(toml_str(v) for v in values) + "]"


lines = []
for name, cfg in servers.items():
    lines.append(f"[mcp_servers.{name}]")
    if cfg.get("command"):
        lines.append(f"command = {toml_str(cfg['command'])}")
        if cfg.get("args"):
            lines.append(f"args = {toml_arr(cfg['args'])}")
        env = cfg.get("env") or {}
        if env:
            lines.append(f"[mcp_servers.{name}.env]")
            for k, v in env.items():
                lines.append(f"{k} = {toml_str(v)}")
    elif cfg.get("url"):
        lines.append(f"url = {toml_str(cfg['url'])}")
        headers = cfg.get("headers") or {}
        if headers:
            lines.append(f"[mcp_servers.{name}.http_headers]")
            for k, v in headers.items():
                lines.append(f"{k} = {toml_str(v)}")
    lines.append("")

block = BEGIN + "\n" + "\n".join(lines).rstrip("\n") + "\n" + END + "\n"

existing = ""
if os.path.exists(path):
    with open(path) as f:
        existing = f.read()

pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", re.DOTALL)
if pattern.search(existing):
    updated = pattern.sub(block, existing)
else:
    sep = "" if existing == "" or existing.endswith("\n") else "\n"
    updated = existing + sep + ("\n" if existing.strip() else "") + block

with open(path, "w") as f:
    f.write(updated)
print(f"mcp: wrote {path}")
PY
fi
