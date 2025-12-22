import type { Plugin } from "@opencode-ai/plugin"

/**
 * GritQL Guardrails Plugin
 *
 * Provides guidance for using @gritql tool for structural code operations.
 * All standard tools are allowed (no blocking).
 *
 * Available tools: grep, glob, find, read, edit, write, bash, list, task,
 *                  webfetch, websearch, todowrite, todoread, notebookedit,
 *                  askuserquestion, gritql, mlg
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

// Blocked tools (disabled - all tools allowed)
// Previously blocked: grep, glob, find, edit, write, bash
const BLOCKED_TOOLS = new Set<string>([])

// Allowed tools (all standard tools + custom tools)
const ALLOWED_TOOLS = new Set([
  // Standard tools
  "grep",
  "glob",
  "find",
  "read",
  "edit",
  "write",
  "bash",
  "list",
  "task",
  "webfetch",
  "websearch",
  "todowrite",
  "todoread",
  "notebookedit",
  "askuserquestion",
  // Custom tools
  "gritql",
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
