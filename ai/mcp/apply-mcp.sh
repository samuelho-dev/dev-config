#!/usr/bin/env sh
# Render the shared MCP definitions into enabled agent CLI configurations.
set -eu
umask 077

if ! command -v python3 >/dev/null 2>&1; then
  echo 'mcp: python3 is required' >&2
  exit 1
fi
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
export MCP_SERVERS_FILE="${MCP_SERVERS_FILE:-$SCRIPT_DIR/servers.json}"
export MCP_CANONICAL_SERVERS_FILE="$SCRIPT_DIR/servers.json"
exec python3 - <<'PY'
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def fail(message):
    raise RuntimeError(message)


def enabled(name):
    value = os.environ.get("MCP_TARGET_" + name, "1")
    if value not in ("0", "1"):
        fail("MCP_TARGET_" + name + " must be 0 or 1")
    return value == "1"


def toml_string(value):
    return json.dumps(str(value), ensure_ascii=False)


def toml_block(servers):
    lines = []
    for name, server in servers.items():
        # Quoted TOML keys support server names containing punctuation.
        key = toml_string(name)
        lines.append(f"[mcp_servers.{key}]")
        if "command" in server:
            lines.append("command = " + toml_string(server["command"]))
            if server.get("args"):
                lines.append("args = [" + ", ".join(map(toml_string, server["args"])) + "]")
            if server.get("env"):
                lines.append(f"[mcp_servers.{key}.env]")
                lines.extend(toml_string(k) + " = " + toml_string(v) for k, v in server["env"].items())
        else:
            lines.append("url = " + toml_string(server["url"]))
            if server.get("headers"):
                lines.append(f"[mcp_servers.{key}.http_headers]")
                lines.extend(toml_string(k) + " = " + toml_string(v) for k, v in server["headers"].items())
        lines.append("")
    return "\n".join(lines).rstrip()


def read_text(path):
    return path.read_text(encoding="utf-8") if path.exists() else ""


def merge_json(path, servers, managed, project=None):
    original = json.loads(read_text(path) or "{}")
    if not isinstance(original, dict) or not isinstance(original.get("mcpServers", {}), dict):
        fail("invalid existing MCP JSON: " + str(path))
    original["mcpServers"] = {**{k: v for k, v in original.get("mcpServers", {}).items() if k not in managed}, **servers}
    if project is not None:
        original["enableAllProjectMcpServers"] = project
    else:
        original.setdefault("$schema", "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json")
    return json.dumps(original, indent=2, ensure_ascii=False) + "\n"


def merge_codex(path, servers):
    begin = "# >>> dev-config managed mcp servers >>>"
    end = "# <<< dev-config managed mcp servers <<<"
    original = read_text(path)
    if original.count(begin) != original.count(end) or original.count(begin) > 1:
        fail("invalid existing Codex managed block: " + str(path))
    block = begin + "\n" + toml_block(servers) + "\n" + end + "\n"
    if begin in original:
        start = original.index(begin)
        finish = original.index(end, start) + len(end)
        if finish < len(original) and original[finish] == "\n":
            finish += 1
        updated = original[:start] + block + original[finish:]
    else:
        updated = original + ("" if not original or original.endswith("\n") else "\n") + ("\n" if original.strip() else "") + block
    try:
        import tomllib
        tomllib.loads(updated)
    except ImportError:
        fail("Python 3.11 or newer is required for the Codex MCP target")
    except ValueError:
        fail("invalid or conflicting existing Codex TOML: " + str(path))
    return updated


def main():
    targets = {name: enabled(name) for name in ("CLAUDE", "OMP", "CODEX")}
    if not any(targets.values()):
        return
    source = os.environ.get("DEV_CONFIG_MCP_AUTH_SOURCE")
    if source not in ("env", "op"):
        fail("DEV_CONFIG_MCP_AUTH_SOURCE must be env or op")
    project = os.environ.get("MCP_ENABLE_PROJECT", "true")
    if project not in ("true", "false"):
        fail("MCP_ENABLE_PROJECT must be true or false")
    path = Path(os.environ["MCP_SERVERS_FILE"])
    try:
        servers = json.loads(path.read_text(encoding="utf-8"))["mcpServers"]
    except (OSError, ValueError, KeyError) as error:
        fail("invalid or missing MCP server list: " + str(path))
    if not isinstance(servers, dict):
        fail("MCP server list must be an object")
    # The canonical names remain owned even when a profile intentionally disables
    # every server, so stale managed entries cannot survive that cutover.
    managed = set(servers) | set(json.loads(Path(os.environ["MCP_CANONICAL_SERVERS_FILE"]).read_text(encoding="utf-8"))["mcpServers"])
    resolved = {}
    for name, value in servers.items():
        if not isinstance(value, dict):
            fail("invalid MCP server: " + name)
        server = value.copy()
        auth = server.pop("auth", None)
        if auth is not None:
            if not isinstance(auth, dict) or not isinstance(auth.get(source), str) or not auth[source]:
                fail("missing " + source + " credential source for " + name)
            if source == "op":
                if shutil.which("op") is None:
                    fail("op is required for MCP authentication")
                result = subprocess.run(["op", "read", auth["op"]], capture_output=True, text=True)
                secret = result.stdout.rstrip("\n") if result.returncode == 0 else ""
            else:
                secret = os.environ.get(auth["env"], "")
            if not secret:
                fail("missing required MCP credential for " + name + " (" + source + ")")
            if auth.get("envKey"):
                server["env"] = {**server.get("env", {}), auth["envKey"]: secret}
            else:
                if not auth.get("header"):
                    fail("missing MCP auth header for " + name)
                server["headers"] = {**server.get("headers", {}), auth["header"]: auth.get("prefix", "") + secret}
        if server.get("command"):
            if shutil.which(server["command"]) is None:
                fail("missing MCP launcher for " + name + ": " + server["command"])
            # The community Vercel MCP launches npx through sh; check the actual child dependency too.
            if name == "vercel" and shutil.which("npx") is None:
                fail("missing MCP launcher for vercel: npx")
        elif not server.get("url"):
            fail("missing MCP transport for " + name)
        resolved[name] = server

    home = Path.home()
    outputs = {}
    if targets["CLAUDE"]:
        outputs[home / ".claude.json"] = merge_json(home / ".claude.json", resolved, managed, project == "true")
    if targets["OMP"]:
        if shutil.which("omp") is None:
            fail("omp is required for the enabled MCP target")
        outputs[home / ".omp/agent/mcp.json"] = merge_json(home / ".omp/agent/mcp.json", resolved, managed)
    if targets["CODEX"]:
        if shutil.which("codex") is None:
            fail("codex is required for the enabled MCP target")
        outputs[home / ".codex/config.toml"] = merge_codex(home / ".codex/config.toml", resolved)

    # Stage every file before publishing any change; missing auth/dependencies or invalid
    # existing config leave all previously valid configurations untouched.
    staged = []
    try:
        for destination, content in outputs.items():
            destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            fd, temporary = tempfile.mkstemp(prefix=".mcp-", dir=destination.parent)
            staged.append((temporary, destination))
            with os.fdopen(fd, "w", encoding="utf-8") as stream:
                stream.write(content)
            os.chmod(temporary, 0o600)
        if targets["OMP"]:
            subprocess.run(["omp", "config", "set", "mcp.enableProjectConfig", project], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        for temporary, destination in staged:
            os.replace(temporary, destination)
            print("mcp: wrote " + str(destination))
    finally:
        for temporary, _ in staged:
            if os.path.exists(temporary):
                os.unlink(temporary)


try:
    main()
except (OSError, ValueError, TypeError, KeyError, RuntimeError, subprocess.CalledProcessError) as error:
    # Do not print provider errors or config payloads: they may contain credentials.
    print("mcp: " + ("OMP project configuration failed" if isinstance(error, subprocess.CalledProcessError) else str(error)), file=sys.stderr)
    sys.exit(1)
PY
