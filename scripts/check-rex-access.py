#!/usr/bin/env python3
"""Read-only, fresh-home access smoke; fails closed on missing required credentials."""
import json
import os
import select
import subprocess
import sys



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


HTTP_MCP_CHECK = r"""
const configs = [
  ["sentry", "https://mcp.sentry.dev/mcp/creativetoolkits", "Sentry-Bearer ", process.env.SENTRY_MCP_KEY, {}],
  ["posthog", "https://mcp.posthog.com/mcp", "Bearer ", process.env.POSTHOG_MCP_KEY, {"x-posthog-mcp-mode": "tools"}],
];
for (const [name, url, prefix, token, extra] of configs) {
  async function rpc(method, credential, session) {
    const headers = {"Authorization": prefix + credential, "Content-Type": "application/json", "Accept": "application/json, text/event-stream", ...extra};
    if (session) headers["Mcp-Session-Id"] = session;
    const response = await fetch(url, {method: "POST", headers, body: JSON.stringify({
      jsonrpc: "2.0", id: 1, method, params: method === "initialize"
        ? {protocolVersion: "2025-03-26", capabilities: {}, clientInfo: {name: "rex-access-check", version: "1"}} : {}
    }), signal: AbortSignal.timeout(20000)});
    if (!response.ok) return {status: response.status};
    const body = await response.text();
    const data = response.headers.get("content-type")?.includes("text/event-stream")
      ? body.split("\n").find(line => line.startsWith("data: "))?.slice(6) : body;
    const message = JSON.parse(data);
    if (message.error || message.result?.isError) throw Error(name + " " + method + " failed");
    return {result: message.result, session: response.headers.get("mcp-session-id") || session};
  }
  const init = await rpc("initialize", token);
  if (!init.result?.serverInfo) throw Error(name + " did not initialize");
  const notification = await fetch(url, {method: "POST", headers: {"Authorization": prefix + token, "Content-Type": "application/json", "Accept": "application/json, text/event-stream", ...(init.session ? {"Mcp-Session-Id": init.session} : {}), ...extra}, body: JSON.stringify({jsonrpc: "2.0", method: "notifications/initialized"}), signal: AbortSignal.timeout(20000)});
  if (!notification.ok) throw Error(name + " initialization acknowledgement failed");
  const tools = await rpc("tools/list", token, init.session);
  if (!tools.result?.tools?.length) throw Error(name + " has no authorized tools");
  const denied = await rpc("tools/list", "nonsecret-invalid-auth-probe");
  if (![401, 403].includes(denied.status)) throw Error(name + " accepted a false credential");
  console.log(name + ": authenticated tools available; invalid credential denied");
}
"""


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
    require("SENTRY_MCP_KEY")
    require("POSTHOG_MCP_KEY")
    print(check(["node", "--input-type=module", "-e", HTTP_MCP_CHECK]))
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
    except (OSError, ValueError, KeyError, RuntimeError) as error:
        print(f"access check failed: {error}", file=sys.stderr)
        sys.exit(1)
