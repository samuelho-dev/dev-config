#!/usr/bin/env python3
"""Read-only, fresh-home access smoke; fails closed on missing required credentials."""
import json
import os
import select
import subprocess
import sys
import urllib.error
import urllib.request


def check(command, *, env=None):
    result = subprocess.run(command, env=env, text=True, capture_output=True, timeout=40)
    if result.returncode:
        raise RuntimeError(f"{command[0]} failed (exit {result.returncode})")
    return result.stdout.strip()


def require(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"missing required {name}")
    return value


def rpc(url, token, prefix, method, params, session=None, extra=None):
    headers = {"Authorization": prefix + token, "Content-Type": "application/json", "Accept": "application/json, text/event-stream"}
    headers.update(extra or {})
    if session:
        headers["Mcp-Session-Id"] = session
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    request = urllib.request.Request(url, data=payload, headers=headers)
    with urllib.request.urlopen(request, timeout=20) as response:
        body = response.read(2_000_000).decode()
        session = response.headers.get("Mcp-Session-Id", session)
    if "data: " in body:
        body = next(line[6:] for line in body.splitlines() if line.startswith("data: "))
    result = json.loads(body)
    if "error" in result or result.get("result", {}).get("isError"):
        raise RuntimeError(f"{method} returned an MCP error")
    return result["result"], session


def main():
    expected = require("REX_EXPECTED_KUBE_IDENTITY")
    kube = require("KUBECONFIG")
    profile = os.environ.get("REX_AWS_PROFILE", "ctk-operator")
    env = {**os.environ, "AWS_PROFILE": profile}
    identity = check(["kubectl", "--kubeconfig", kube, "auth", "whoami", "-o", "json"])
    if json.loads(identity)["status"]["userInfo"]["username"] != expected:
        raise RuntimeError("unexpected Kubernetes identity")
    if check(["kubectl", "--kubeconfig", kube, "auth", "can-i", "get", "applications.argoproj.io", "-n", "argocd"]) != "yes":
        raise RuntimeError("Argo read permission denied")
    # The named owner cluster-admin profile legitimately has no namespace-level denial.
    denied = check(["kubectl", "--kubeconfig", kube, "auth", "can-i", "get", "secrets", "--as=system:anonymous", "-n", "argocd"])
    if denied != "no":
        raise RuntimeError("anonymous Kubernetes secret access unexpectedly allowed")
    check(["argocd-core.sh", "--in-cluster", "app", "list", "-o", "json"])
    aws = json.loads(check(["aws", "sts", "get-caller-identity", "--output", "json"], env=env))
    if aws.get("Account") != require("REX_EXPECTED_AWS_ACCOUNT"):
        raise RuntimeError("unexpected AWS account")
    check(["supabase", "projects", "list", "--output", "json"])
    pg = check(["psql", "-Atqc", "SELECT current_user || '|' || current_database()"])
    if pg != require("REX_EXPECTED_POSTGRES_IDENTITY"):
        raise RuntimeError("unexpected PostgreSQL identity")
    for name, url, prefix, token, headers in (
        ("sentry", "https://mcp.sentry.dev/mcp/creativetoolkits", "Sentry-Bearer ", require("SENTRY_MCP_KEY"), {}),
        ("posthog", "https://mcp.posthog.com/mcp", "Bearer ", require("POSTHOG_MCP_KEY"), {"x-posthog-mcp-mode": "tools"}),
    ):
        init, session = rpc(url, token, prefix, "initialize", {"protocolVersion": "2025-03-26", "capabilities": {}, "clientInfo": {"name": "rex-access-check", "version": "1"}}, extra=headers)
        if not init.get("serverInfo"):
            raise RuntimeError(f"{name} did not initialize")
        tools, _ = rpc(url, token, prefix, "tools/list", {}, session, headers)
        if not tools.get("tools"):
            raise RuntimeError(f"{name} has no authorized tools")
        try:
            rpc(url, "nonsecret-invalid-auth-probe", prefix, "tools/list", {}, None, headers)
        except urllib.error.HTTPError as error:
            if error.code not in (401, 403):
                raise
        else:
            raise RuntimeError(f"{name} accepted a false credential")
        print(f"{name}: authenticated tools available; invalid credential denied")
    # verify the real tool through an actual stdio initialize/list/call exchange.
    command = "cd /tmp && exec npx -y @robinson_ai_systems/vercel-mcp@1.0.1"
    proc = subprocess.Popen(["sh", "-c", command], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, env={**os.environ, "VERCEL_TOKEN": require("VERCEL_TOKEN")})
    try:
        for index, (method, params) in enumerate((("initialize", {"protocolVersion": "2025-03-26", "capabilities": {}, "clientInfo": {"name": "rex-access-check", "version": "1"}}), ("tools/list", {}), ("tools/call", {"name": "vercel_list_teams", "arguments": {}})), 1):
            proc.stdin.write(json.dumps({"jsonrpc": "2.0", "id": index, "method": method, "params": params}) + "\n")
            proc.stdin.flush()
            while True:
                ready, _, _ = select.select([proc.stdout], [], [], 30)
                if not ready:
                    raise RuntimeError("Vercel MCP response timed out")
                line = proc.stdout.readline()
                if not line:
                    raise RuntimeError("Vercel MCP ended before response")
                response = json.loads(line)
                if response.get("id") == index:
                    if "error" in response or response.get("result", {}).get("isError") or not response.get("result"):
                        raise RuntimeError(f"Vercel MCP {method} failed")
                    break
        print("vercel: authenticated list_teams succeeded")
    finally:
        proc.terminate()
        proc.wait(timeout=5)
    print("Kubernetes, Argo, AWS, Supabase, PostgreSQL: identities and permissions verified")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, RuntimeError, urllib.error.URLError) as error:
        print(f"access check failed: {error}", file=sys.stderr)
        sys.exit(1)
