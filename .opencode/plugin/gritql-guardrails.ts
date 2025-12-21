import type { Plugin } from "@opencode-ai/plugin"
import { extname } from "node:path"

const GRITQL_SUPPORTED = new Set([
  ".js",
  ".jsx",
  ".ts",
  ".tsx",
  ".mjs",
  ".cjs",
  ".json",
  ".py",
  ".css",
  ".scss",
  ".rs",
  ".rb",
  ".php",
])

export const GritqlGuardrails: Plugin = async () => {
  return {
    event: async ({ event }: { event: { type?: string; path?: string; filePath?: string } }) => {
      if (event?.type !== "file.edited") return

      const filePath = event?.path ?? event?.filePath ?? ""

      if (!filePath) return

      const ext = extname(filePath).toLowerCase()

      if (!GRITQL_SUPPORTED.has(ext)) return

      throw new Error(
        `For structural code changes to ${ext} files, prefer @gritql:\n\n` +
          `• @gritql command=listPatterns - see available patterns\n` +
          `• @gritql command=checkPattern patternName=<name> target=${filePath}\n` +
          `• @gritql command=applyPattern patternName=<name> target=${filePath}\n\n` +
          `If no pattern matches your use case, proceed with direct editing.`
      )
    },
  }
}

export default GritqlGuardrails
