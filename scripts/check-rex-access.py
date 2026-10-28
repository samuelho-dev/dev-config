#!/usr/bin/env python3
"""Read-only, fresh-home access smoke; fails closed on missing required credentials."""
import json
import os
import select
import subprocess
import sys
import signal



def check(command, *, env=None):
    try:
        result = subprocess.run(command, env=env, text=True, capture_output=True, timeout=180 if command[0] == "node" else 40)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"{command[0]} timed out") from error
    if result.returncode:
        raise RuntimeError(f"{command[0]} failed (exit {result.returncode})")
    return result.stdout.strip()


def require(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"missing required {name}")
    return value


def has_vercel_team(result, expected):
    def matches(value):
        if isinstance(value, list):
            return any(map(matches, value))
        if isinstance(value, dict):
            return value.get("id") == expected or value.get("slug") == expected or any(map(matches, value.values()))
        return False

    payloads = [result.get("structuredContent")]
    for item in result.get("content", []):
        try:
            payloads.append(json.loads(item["text"]))
        except (KeyError, TypeError, ValueError):
            continue
    return any(map(matches, payloads))


HTTP_MCP_CHECK = r"""
const configs = [
  ["sentry", "https://mcp.sentry.dev/mcp/creativetoolkits", "Sentry-Bearer ", process.env.SENTRY_MCP_KEY, {}],
  ["posthog", "https://mcp.posthog.com/mcp", "Bearer ", process.env.POSTHOG_MCP_KEY, {"x-posthog-mcp-mode": "tools"}],
];
for (const [name, url, prefix, token, extra] of configs) {
  async function rpc(method, credential, session, args = {}) {
    const headers = {"Authorization": prefix + credential, "Content-Type": "application/json", "Accept": "application/json, text/event-stream", ...extra};
    if (session) headers["Mcp-Session-Id"] = session;
    const response = await fetch(url, {method: "POST", headers, body: JSON.stringify({
      jsonrpc: "2.0", id: 1, method, params: method === "initialize"
        ? {protocolVersion: "2025-03-26", capabilities: {}, clientInfo: {name: "rex-access-check", version: "1"}} : args
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
  const toolName = name === "sentry" ? "find_projects" : "project-get";
  if (!tools.result.tools.some(tool => tool.name === toolName)) throw Error(name + " read tool unavailable");
  const arguments_ = name === "sentry" ? {} : {
    context: "Verify the selected PostHog project identity with a read-only query",
    model: process.env.REX_POSTHOG_MODEL
  };
  const called = await rpc("tools/call", token, init.session, {name: toolName, arguments: arguments_});
  const expected = name === "sentry" ? process.env.REX_EXPECTED_SENTRY_PROJECT : process.env.REX_EXPECTED_POSTHOG_PROJECT_ID;
  function hasIdentity(value) {
    if (Array.isArray(value)) return value.some(hasIdentity);
    if (!value || typeof value !== "object") return false;
    if (["id", "slug", "name", "projectId"].some(key => String(value[key]) === expected)) return true;
    return Object.values(value).some(hasIdentity);
  }
  const payloads = [called.result?.structuredContent, ...(called.result?.content?.map(item => {
    try { return JSON.parse(item.text); } catch { return null; }
  }) || [])];
  // Older Sentry servers render project rows as Markdown rather than JSON.
  const markdownProject = name === "sentry" && called.result?.content?.some(item => {
    if (typeof item.text !== "string") return false;
    const slug = expected.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    return new RegExp("(?:^|\\n)\\s*(?:[-*]\\s*)?(?:(?:\\*\\*)?slug(?:\\*\\*)?\\s*:\\s*`?" + slug + "`?(?=\\s|$)|(?:\\*\\*|`)?" + slug + "(?:\\*\\*|`)?(?=\\s|\\(|$))", "im").test(item.text)
      || new RegExp("/projects/" + slug + "(?:/|[?#)]|$)").test(item.text);
  });
  if (!payloads.some(hasIdentity) && !markdownProject) throw Error(name + " did not return the expected project");
  if (![401, 403].includes(denied.status)) throw Error(name + " accepted a false credential");
  console.log(name + ": authenticated tools available; invalid credential denied");
}
"""


def main():
    expected = require("REX_EXPECTED_KUBE_IDENTITY")
    kube = require("KUBECONFIG")
    for name in (
        "REX_EXPECTED_AWS_ACCOUNT", "REX_EXPECTED_AWS_ARN", "REX_EXPECTED_POSTGRES_IDENTITY",
        "REX_EXPECTED_SUPABASE_PROJECT_ID", "REX_EXPECTED_SENTRY_PROJECT",
        "REX_EXPECTED_POSTHOG_PROJECT_ID", "REX_EXPECTED_VERCEL_TEAM",
        "REX_POSTHOG_MODEL", "SUPABASE_ACCESS_TOKEN", "SENTRY_MCP_KEY",
        "POSTHOG_MCP_KEY", "VERCEL_TOKEN",
    ):
        require(name)
    profile = os.environ.get("REX_AWS_PROFILE", "ctk-operator")
    env = {key: value for key, value in os.environ.items() if key not in (
        "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN",
        "AWS_SECURITY_TOKEN", "AWS_PROFILE", "AWS_REGION", "AWS_DEFAULT_REGION",
        "AWS_ENDPOINT_URL", "AWS_ENDPOINT_URL_STS",
    )}
    identity = check(["kubectl", "--kubeconfig", kube, "auth", "whoami", "-o", "json"])
    if json.loads(identity)["status"]["userInfo"]["username"] != expected:
        raise RuntimeError("unexpected Kubernetes identity")
    if check(["kubectl", "--kubeconfig", kube, "auth", "can-i", "get", "applications.argoproj.io", "-n", "argocd"]) != "yes":
        raise RuntimeError("Argo read permission denied")
    # The named owner cluster-admin profile legitimately has no namespace-level denial.
    try:
        denied = subprocess.run(
            ["kubectl", "--kubeconfig", kube, "auth", "can-i", "get", "secrets", "--as=system:anonymous", "-n", "argocd"],
            text=True, capture_output=True, timeout=40,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError("anonymous Kubernetes denial timed out") from error
    if denied.returncode not in (0, 1) or denied.stdout.strip() != "no":
        raise RuntimeError("anonymous Kubernetes secret denial not verified")
    check(["argocd-core.sh", "--in-cluster", "app", "list", "-o", "json"])
    aws = json.loads(check(["aws", "--profile", profile, "sts", "get-caller-identity", "--output", "json"], env=env))
    if aws.get("Account") != require("REX_EXPECTED_AWS_ACCOUNT") or aws.get("Arn") != require("REX_EXPECTED_AWS_ARN"):
        raise RuntimeError("unexpected AWS account or principal")
    projects = json.loads(check(["supabase", "projects", "list", "--output", "json"]))
    if not isinstance(projects, list) or not any(
        project.get("id") == require("REX_EXPECTED_SUPABASE_PROJECT_ID") for project in projects
    ):
        raise RuntimeError("expected Supabase project not accessible")
    pg = check(["psql", "-Atqc", "SELECT current_user || '|' || current_database()"])
    if pg != require("REX_EXPECTED_POSTGRES_IDENTITY"):
        raise RuntimeError("unexpected PostgreSQL identity")
    # MCP probes below perform provider reads and assert the expected project/team.
    print(check(["node", "--input-type=module", "-e", HTTP_MCP_CHECK]))
    # verify the real tool through an actual stdio initialize/list/call exchange.
    command = "cd /tmp && exec npx -y @robinson_ai_systems/vercel-mcp@1.0.1"
    proc = subprocess.Popen(["sh", "-c", command], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, start_new_session=True, env={**os.environ, "VERCEL_TOKEN": require("VERCEL_TOKEN")})
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
                    if method == "tools/call" and not has_vercel_team(response["result"], require("REX_EXPECTED_VERCEL_TEAM")):
                        raise RuntimeError("expected Vercel team ID/slug not accessible")
                    break
        print("vercel: authenticated list_teams succeeded")
    finally:
        if proc.poll() is None:
            os.killpg(proc.pid, signal.SIGTERM)
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGKILL)
                proc.wait(timeout=5)
    print("Kubernetes, Argo, AWS, Supabase, PostgreSQL: identities and permissions verified")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, RuntimeError) as error:
        print(f"access check failed: {error}", file=sys.stderr)
        sys.exit(1)
