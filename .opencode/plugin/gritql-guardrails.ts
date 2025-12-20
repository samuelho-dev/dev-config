import type { Plugin } from "@opencode-ai/plugin";

/**
 * Strict enforcement plugin:
 * - Requires structural search/modification via the `gritql` tool (or `grit` CLI wrapper).
 * - Blocks common non-structural search & rewrite tools (ripgrep/grep/sed/perl/python codemods).
 * - Blocks direct VCS mass-edit operations that bypass gritql (git apply, git checkout --, etc).
 *
 * NOTE:
 * OpenCode’s plugin event payloads can vary by version/config. This plugin is defensive:
 * it inspects the event shape at runtime and blocks when it can determine a violation.
 *
 * If OpenCode supports hard-blocking by throwing in a hook, this plugin will enforce strictly.
 * If not, OpenCode will still receive a structured warning with remediation steps.
 */

// Allowlist: commands that are always ok
const SAFE_COMMAND_PREFIXES = [
  "ls",
  "cd",
  "pwd",
  "cat",
  "less",
  "more",
  "bat",
  "tree",
  "which",
  "whereis",
  "echo",
  "env",
  "printenv",
  "uname",
  "date",
  "whoami",
  "id",
  "git status",
  "git diff",
  "git log",
  "git show",
  "git rev-parse",
  "git branch",
  "git remote",
  "git fetch",
  "git pull",
  "git push",
  "nix flake show",
  "nix flake check",
  "home-manager build",
  "home-manager switch --dry-run",
  "biome check",
  "biome lint",
  "biome format",
  "biome ci",
];

// Hard-block: non-structural search / codemod / mutation primitives
const BLOCKED_COMMAND_PATTERNS: Array<{ pattern: RegExp; reason: string }> = [
  // Non-structural search
  { pattern: /\brg\b|\bripgrep\b/i, reason: "Use structural search via `gritql` instead of ripgrep." },
  { pattern: /\bgrep\b/i, reason: "Use structural search via `gritql` instead of grep." },
  { pattern: /\back\b/i, reason: "Use structural search via `gritql` instead of ack." },
  { pattern: /\bag\b/i, reason: "Use structural search via `gritql` instead of ag." },

  // Non-structural rewrite tools
  { pattern: /\bsed\b/i, reason: "Use structural rewrites via `gritql` instead of sed." },
  { pattern: /\bperl\b.*\b-?pi\b/i, reason: "Use structural rewrites via `gritql` instead of perl -pi." },
  { pattern: /\bpython\b.*-c\b/i, reason: "Avoid ad-hoc python -c rewrites; use `gritql`." },
  { pattern: /\bnode\b.*-e\b/i, reason: "Avoid ad-hoc node -e rewrites; use `gritql`." },
  { pattern: /\bjscodeshift\b/i, reason: "Use `gritql` for codemods in this repo." },

  // Patch application that can mass-modify without guardrails
  { pattern: /\bgit\s+apply\b/i, reason: "Use `gritql` for modifications; avoid applying patches directly." },
  { pattern: /\bpatch\b\s+-p/i, reason: "Use `gritql` for modifications; avoid applying patches directly." },

  // Direct checkout/reset of working tree can hide changes outside review loops
  { pattern: /\bgit\s+checkout\s+--\b/i, reason: "Avoid bypassing change review; use `git restore` deliberately if needed." },
  { pattern: /\bgit\s+restore\b/i, reason: "Avoid bypassing change review; use deliberately and explain why." },
  { pattern: /\bgit\s+reset\b/i, reason: "Avoid reset in automated workflows; use carefully and explain why." },
];

// Allowlist: structural tooling
const ALLOWED_STRUCTURAL_PATTERNS = [
  /^grit(\s|$)/i,
  /^bunx\s+@getgrit\/cli(\s|$)/i,
  /^opencode\s+run\s+gritql(\s|$)/i,
  /^gritql(\s|$)/i,
];

// If a tool is invoked, only allow known structural tools for code search/modification.
// We also allow validation tools (biome/nix) via SAFE_COMMAND_PREFIXES.
function isAllowedCommand(command: string): boolean {
  const trimmed = command.trim();

  if (!trimmed) return true;

  // Explicit structural allowlist
  if (ALLOWED_STRUCTURAL_PATTERNS.some((re) => re.test(trimmed))) return true;

  // Safe prefixes allowlist
  if (SAFE_COMMAND_PREFIXES.some((p) => trimmed === p || trimmed.startsWith(`${p} `))) return true;

  return false;
}

function findBlockedReason(command: string): string | null {
  const trimmed = command.trim();

  // Never block the structural allowlist
  if (ALLOWED_STRUCTURAL_PATTERNS.some((re) => re.test(trimmed))) return null;

  for (const { pattern, reason } of BLOCKED_COMMAND_PATTERNS) {
    if (pattern.test(trimmed)) return reason;
  }

  return null;
}

function makeError(message: string, details?: Record<string, unknown>) {
  const error = new Error(message) as Error & { details?: Record<string, unknown> };
  error.details = details;
  return error;
}

/**
 * Heuristic detection for "search intent" and "mutation intent" when commands are unknown.
 * In strict mode, we block unknown tools that appear to be doing search/replace.
 */
function looksLikeSearchOrMutationCommand(command: string): boolean {
  const c = command.trim();

  // If it references common search flags or pipelines that indicate searching code.
  if (/\b(--glob|--files|--type|--include|--exclude|--hidden)\b/i.test(c)) return true;
  if (/\b(-R|-r|--recursive)\b/i.test(c)) return true;
  if (/\|\s*(head|tail|less|more|bat)\b/i.test(c)) return true;

  // If it references in-place edits or rewrites.
  if (/\b(-i|--in-place)\b/i.test(c)) return true;
  if (/\b(replace|rewrite|codemod|refactor)\b/i.test(c)) return true;

  return false;
}

export const GritqlGuardrails: Plugin = async ({ project, directory, worktree }) => {
  // Basic banner for debugging (kept minimal; avoid noisy logs in strict mode)
  const projectName = (project as any)?.name ?? "unknown-project";

  return {
    event: async ({ event }: any) => {
      const type: string | undefined = event?.type;

      // We enforce on tool execution and command execution events.
      // OpenCode supports both plugin events and tool events; we handle the common ones.
      if (
        type === "tool.execute.before" ||
        type === "command.executed" ||
        type === "tui.command.execute"
      ) {
        const data = event?.data ?? {};
        const raw =
          data?.command ??
          data?.args?.command ??
          data?.input ??
          data?.text ??
          data?.value ??
          "";

        const command = typeof raw === "string" ? raw : JSON.stringify(raw);

        // 1) Explicit blocks
        const blockedReason = findBlockedReason(command);
        if (blockedReason) {
          throw makeError(
            `Blocked by strict GritQL guardrails: ${blockedReason}`,
            {
              project: projectName,
              directory,
              worktree,
              command,
              remediation: [
                "Use structural search via: opencode run gritql --command check --pattern '...'",
                "Or named pattern via: opencode run gritql --patternName <name> --target <path>",
                "For modifications, run check/dry-run first, then apply with explicit confirm.",
              ],
            },
          );
        }

        // 2) Allowlist
        if (isAllowedCommand(command)) return;

        // 3) Strict heuristic: block unknown commands that look like search/mutation.
        if (looksLikeSearchOrMutationCommand(command)) {
          throw makeError(
            "Blocked by strict GritQL guardrails: non-structural search/mutation detected.",
            {
              project: projectName,
              directory,
              worktree,
              command,
              remediation: [
                "Replace ad-hoc searches with GritQL structural search via the `gritql` tool.",
                "Replace ad-hoc rewrites with `gritql --command apply` after reviewing dry-run output.",
              ],
            },
          );
        }

        // For other unknown commands, allow by default (strict but not unusable).
        // If you want absolute lockdown, uncomment the next block.
        /*
        throw makeError(
          "Blocked by strict GritQL guardrails: only approved tools are allowed.",
          { project: projectName, directory, worktree, command },
        );
        */
      }

      // Optional: detect direct file edits if event payload provides it.
      // In strict enforcement, we can warn/block edits not preceded by gritql.
      // Actual enforcement here depends on OpenCode’s ability to link edits to tool runs.
      if (type === "file.edited") {
        const data = event?.data ?? {};
        const path = data?.path ?? data?.file ?? data?.filename;

        // If the file.edited event includes an origin tool, allow if gritql.
        const origin = data?.origin ?? data?.source ?? data?.tool;
        const originStr = typeof origin === "string" ? origin : "";

        if (originStr && /gritql|grit/i.test(originStr)) return;

        // If OpenCode is editing files directly (LLM writes), we block and require gritql workflow.
        // This is intentionally strict: you asked for strict enforcement.
        throw makeError(
          "Blocked by strict GritQL guardrails: direct file edits are not allowed. Use `gritql`.",
          {
            project: projectName,
            directory,
            worktree,
            file: path,
            remediation: [
              "Use `opencode run gritql --command check` to locate targets structurally.",
              "Then use `opencode run gritql --command apply` to perform the change.",
              "Re-run `biome check` after applying modifications.",
            ],
          },
        );
      }
    },
  };
};

export default GritqlGuardrails;
