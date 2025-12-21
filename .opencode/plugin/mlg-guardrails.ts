import type { Plugin } from "@opencode-ai/plugin"
import { Schema, pipe } from "effect"

/**
 * MLG Guardrails Plugin
 *
 * Encourages library creation via the `mlg` tool instead of raw NX generators.
 * Throws helpful guidance when detecting library creation patterns that bypass MLG.
 */

// Type definitions for plugin hook parameters
type ToolExecuteInput = {
  readonly tool?: string
  readonly args?: {
    readonly command?: string
    readonly [key: string]: unknown
  }
  readonly command?: string
  readonly [key: string]: unknown
}

type ToolExecuteOutput = {
  readonly [key: string]: unknown
}

// Schema for extracting project name safely
const ProjectNameSchema = Schema.Struct({ name: Schema.String })

const extractProjectName = (project: unknown): string =>
  pipe(
    Schema.decodeUnknownOption(ProjectNameSchema)(project),
    (opt) => (opt._tag === "Some" ? opt.value.name : "unknown-project")
  )

// Warn patterns: library creation that bypasses MLG
const WARNED_PATTERNS: Array<{ pattern: RegExp; reason: string }> = [
  // NX library generators
  {
    pattern: /\bnx\s+g(?:enerate)?\s+@nx\/js:lib/i,
    reason: "Consider using @mlg for library creation - enforces Effect TS patterns.",
  },
  {
    pattern: /\bnx\s+g(?:enerate)?\s+@nx\/node:lib/i,
    reason: "Consider using @mlg for library creation - enforces Effect TS patterns.",
  },
  {
    pattern: /\bnx\s+g(?:enerate)?\s+@nrwl\/.*:lib/i,
    reason: "Consider using @mlg for library creation - enforces Effect TS patterns.",
  },
  {
    pattern: /\bnx\s+g(?:enerate)?\s+.*:library/i,
    reason: "Consider using @mlg for library creation - enforces Effect TS patterns.",
  },

  // Direct directory creation in libs/
  {
    pattern: /\bmkdir\s+.*libs?\//i,
    reason: "Consider using @mlg to scaffold libraries properly with Effect patterns.",
  },
  {
    pattern: /\bmkdir\s+-p\s+.*libs?\//i,
    reason: "Consider using @mlg to scaffold libraries properly with Effect patterns.",
  },

  // Manual project.json creation
  {
    pattern: /\btouch\s+.*libs?\/.*project\.json/i,
    reason: "Consider using @mlg to create libraries with proper NX configuration.",
  },
  {
    pattern: /\becho\s+.*>\s*.*libs?\/.*project\.json/i,
    reason: "Consider using @mlg to create libraries with proper NX configuration.",
  },
]

// Allowlist: MLG tool usage
const ALLOWED_PATTERNS = [
  /^@mlg\b/i,
  /^mlg\b/i,
  /\bopencode\s+run\s+mlg\b/i,
]

function isAllowedCommand(command: string): boolean {
  const trimmed = command.trim()
  if (!trimmed) return true

  // Explicit MLG allowlist
  if (ALLOWED_PATTERNS.some((re) => re.test(trimmed))) return true

  return false
}

function findWarnReason(command: string): string | null {
  const trimmed = command.trim()

  // Never warn for MLG allowlist
  if (ALLOWED_PATTERNS.some((re) => re.test(trimmed))) return null

  for (const { pattern, reason } of WARNED_PATTERNS) {
    if (pattern.test(trimmed)) return reason
  }

  return null
}

export const MlgGuardrails: Plugin = async ({ project, directory, worktree }) => {
  const projectName = extractProjectName(project)

  return {
    // Intercept bash tool execution to check for library creation patterns
    "tool.execute.before": async (input: ToolExecuteInput, output: ToolExecuteOutput) => {
      const toolName = (input?.tool ?? '').toLowerCase().trim()

      // Only check bash commands for library creation patterns
      if (toolName !== 'bash') return

      const command = input?.args?.command ?? input?.command ?? ''
      const commandStr = typeof command === "string" ? command : JSON.stringify(command)

      // Skip if allowed
      if (isAllowedCommand(commandStr)) return

      // Check for patterns that should use MLG
      const warnReason = findWarnReason(commandStr)
      if (warnReason) {
        throw new Error(
          `${warnReason}\n\n` +
            `Use @mlg for Effect TS library creation:\n` +
            `• @mlg command=listTypes - see available library types\n` +
            `• @mlg command=dryRun name=<lib-name> type=<type> - preview\n` +
            `• @mlg command=create name=<lib-name> type=<type> confirm=true\n\n` +
            `Types: contract, data-access, feature, infra, provider`
        )
      }
    },
  }
}

export default MlgGuardrails
