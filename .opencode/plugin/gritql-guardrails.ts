import type { Plugin } from "@opencode-ai/plugin"

/**
 * GritQL Guardrails Plugin
 *
 * Enforces strict policy: ONLY @gritql tool for code search/modification.
 * Blocks: grep, glob, find, edit, write, bash
 * Allows: gritql, read, list, task, webfetch, todowrite, todoread, mlg
 *
 * @see AGENTS.md for policy documentation
 */

// Type definitions matching mlg-guardrails pattern
type ToolExecuteInput = {
  readonly tool?: string
  readonly args?: Record<string, unknown>
  readonly [key: string]: unknown
}

type ToolExecuteOutput = {
  readonly [key: string]: unknown
}

// Blocked tools (strict enforcement)
const BLOCKED_TOOLS = new Set(["grep", "glob", "find", "edit", "write", "bash"])

// Allowed tools (read-only + gritql + mlg)
const ALLOWED_TOOLS = new Set([
  "gritql",
  "read",
  "list",
  "task",
  "webfetch",
  "todowrite",
  "todoread",
  "mlg",
])

export const GritqlGuardrails: Plugin = async () => {
  return {
    "tool.execute.before": async (input: ToolExecuteInput, _output: ToolExecuteOutput) => {
      const toolName = (input?.tool ?? "").toLowerCase().trim()

      if (!toolName) return

      if (BLOCKED_TOOLS.has(toolName)) {
        throw new Error(
          `🚨 Tool '${toolName}' is blocked by GritQL policy.\n\n` +
            `For code search and modification, use @gritql:\n\n` +
            `• @gritql command=listPatterns - see available patterns\n` +
            `• @gritql command=checkPattern patternName=<name> target=<path>\n` +
            `• @gritql command=applyPattern patternName=<name> target=<path> confirm=true\n\n` +
            `Blocked tools: ${Array.from(BLOCKED_TOOLS).join(", ")}\n` +
            `Allowed tools: ${Array.from(ALLOWED_TOOLS).join(", ")}\n\n` +
            `See AGENTS.md for policy details.`
        )
      }
    },
  }
}

export default GritqlGuardrails
