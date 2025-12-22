import { tool } from "@opencode-ai/plugin"
import { Effect, Schema, Data, pipe } from "effect"
import { existsSync, readdirSync, readFileSync } from "fs"
import { execSync } from "child_process"
import { join } from "path"
import { createHash } from "crypto"

// ============================================================
// gritql - Refactored with Effect TS (Strict Typing)
// STRICT pseudo-API for structural search, linting, and refactoring
// ============================================================

// ============================================================================
// EFFECT SCHEMA DEFINITIONS
// ============================================================================

const PolicyModeSchema = Schema.Literal("strict", "standard", "off")

const CommandSchema = Schema.Literal(
  "listPatterns",
  "checkPattern",
  "applyPattern",
  "checkProject",
  "explainUsage"
)

const SeveritySchema = Schema.Literal("info", "warn", "error")

const MatchSchema = Schema.Struct({
  file: Schema.String,
  startLine: Schema.optional(Schema.Number),
  endLine: Schema.optional(Schema.Number),
  startColumn: Schema.optional(Schema.Number),
  endColumn: Schema.optional(Schema.Number),
  snippet: Schema.optional(Schema.String),
})

const SummarySchema = Schema.Struct({
  target: Schema.String,
  dryRun: Schema.Boolean,
  patternsRun: Schema.Number,
  matches: Schema.Number,
  filesWithMatches: Schema.Number,
  filesScanned: Schema.optional(Schema.Number),
})

const DiffSchema = Schema.Struct({
  available: Schema.Boolean,
  unified: Schema.optional(Schema.String),
})

const ViolationSchema = Schema.Struct({
  code: Schema.String,
  severity: SeveritySchema,
  message: Schema.String,
  remediation: Schema.optional(Schema.Array(Schema.String)),
})

const ContextVersionSchema = Schema.Struct({
  version: Schema.String,
  timestamp: Schema.String,
  hash: Schema.String,
  patternName: Schema.optional(Schema.String),
})

const GritArgsSchema = Schema.Struct({
  command: Schema.optional(CommandSchema).annotations({
    description: "One of: listPatterns, checkPattern, applyPattern, checkProject, explainUsage",
  }),
  policy: Schema.optional(PolicyModeSchema).annotations({
    description: "Policy mode: strict (default), standard, off",
  }),
  target: Schema.optional(Schema.String).annotations({
    description: "Target file or directory (default: '.')",
  }),
  patternName: Schema.optional(Schema.String).annotations({
    description: "Name of repo pattern in biome/gritql-patterns (no extension)",
  }),
  pattern: Schema.optional(Schema.String).annotations({
    description: "Inline GritQL pattern text (discouraged in strict mode)",
  }),
  allowInline: Schema.optional(Schema.Boolean).annotations({
    description: "Allow inline pattern under strict policy (discouraged). Default false.",
  }),
  runId: Schema.optional(Schema.String).annotations({
    description: "Run id returned by checkPattern; required for applyPattern in strict policy.",
  }),
  confirm: Schema.optional(Schema.Boolean).annotations({
    description: "Explicit confirmation required for applyPattern in strict policy.",
  }),
  patternNames: Schema.optional(Schema.Array(Schema.String)).annotations({
    description: "List of repo patterns to run for checkProject (defaults to curated ruleset).",
  }),
  includeDiff: Schema.optional(Schema.Boolean).annotations({
    description: "Include unified diff output when available (default true).",
  }),
  force: Schema.optional(Schema.Boolean).annotations({
    description: "Bypass git safety checks for uncommitted changes (use with caution). Default false.",
  }),
})

// ============================================================================
// ERROR TYPES (Data.TaggedError)
// ============================================================================

class GritNotFoundError extends Data.TaggedError("GritNotFoundError")<{
  readonly message: string
  readonly recommendations: readonly string[]
}> {}

class PatternNotFoundError extends Data.TaggedError("PatternNotFoundError")<{
  readonly patternName: string
  readonly message: string
}> {}

class PolicyViolationError extends Data.TaggedError("PolicyViolationError")<{
  readonly violations: readonly Schema.Schema.Type<typeof ViolationSchema>[]
}> {}

class GritExecutionError extends Data.TaggedError("GritExecutionError")<{
  readonly stage: string
  readonly message: string
  readonly output: string | undefined
}> {}

// ============================================================================
// RESPONSE TYPES (Schema.Class for Tagged Unions)
// ============================================================================

class ToolSuccess extends Schema.Class<ToolSuccess>("ToolSuccess")({
  _tag: Schema.Literal("success"),
  command: Schema.String,
  policy: PolicyModeSchema,
  target: Schema.String,
  patternName: Schema.optional(Schema.String),
  patternSource: Schema.optional(Schema.Literal("repo", "inline")),
  dryRun: Schema.Boolean,
  runId: Schema.optional(Schema.String),
  confirm: Schema.optional(Schema.Boolean),
  contextVersion: Schema.optional(ContextVersionSchema),
  summary: Schema.optional(SummarySchema),
  matches: Schema.optional(Schema.Array(MatchSchema)),
  diff: Schema.optional(DiffSchema),
  output: Schema.optional(Schema.String),
  recommendations: Schema.Array(Schema.String),
}) {}

class ToolFailure extends Schema.Class<ToolFailure>("ToolFailure")({
  _tag: Schema.Literal("failure"),
  command: Schema.String,
  policy: PolicyModeSchema,
  target: Schema.String,
  patternName: Schema.optional(Schema.String),
  patternSource: Schema.optional(Schema.Literal("repo", "inline")),
  dryRun: Schema.Boolean,
  runId: Schema.optional(Schema.String),
  confirm: Schema.optional(Schema.Boolean),
  violations: Schema.optional(Schema.Array(ViolationSchema)),
  error: Schema.String,
  output: Schema.optional(Schema.String),
  recommendations: Schema.optional(Schema.Array(Schema.String)),
}) {}

// ============================================================================
// CONSTANTS
// ============================================================================

const REPO_PATTERNS_DIR = join(process.cwd(), "biome", "gritql-patterns")

const DEFAULT_RULESET: readonly string[] = [
  "detect-missing-yield-star",
  "ban-any-type-annotation",
  "ban-type-assertions",
  "ban-satisfies",
  "ban-relative-parent-imports",
  "prefer-object-spread",
  "ban-default-export-non-index",
  "ban-push-spread",
  "ban-return-types",
  "enforce-effect-pipe",
  "enforce-esm-package-type",
  "enforce-nx-project-tags",
  "enforce-strict-tsconfig",
]

// ============================================================================
// HELPER FUNCTIONS (strict typing - no return type annotations)
// ============================================================================

const nowIso = () => new Date().toISOString()

const makeRunId = (prefix: string) =>
  `${prefix}_${nowIso()}_${Math.random().toString(16).slice(2)}`

const makeContextVersion = (patternText: string, patternName?: string): Schema.Schema.Type<typeof ContextVersionSchema> => ({
  version: `v1_${nowIso()}`,
  timestamp: nowIso(),
  hash: createHash("sha256").update(patternText).digest("hex").slice(0, 16),
  patternName,
})

const normalizeTarget = (input: string | undefined) => {
  const t = (input ?? "").trim()
  return t.length === 0 ? "." : t
}

const listRepoPatterns = () => {
  if (!existsSync(REPO_PATTERNS_DIR)) return []
  return readdirSync(REPO_PATTERNS_DIR)
    .filter((f) => f.endsWith(".grit"))
    .map((f) => f.replace(/\.grit$/u, ""))
    .sort()
}

// Schemas for extracting error/args info (strict schema, no type guards)
const ErrorMessageSchema = Schema.Struct({ message: Schema.String })
const ErrorStderrSchema = Schema.Struct({ stderr: Schema.String })
const ArgsCommandSchema = Schema.Struct({ command: Schema.String })
const ArgsTargetSchema = Schema.Struct({ target: Schema.String })
const ArgsPolicySchema = Schema.Struct({ policy: PolicyModeSchema })

const extractMessage = (e: unknown) =>
  pipe(
    Schema.decodeUnknownOption(ErrorMessageSchema)(e),
    (opt) => (opt._tag === "Some" ? opt.value.message : String(e))
  )

const extractStderr = (e: unknown) =>
  pipe(
    Schema.decodeUnknownOption(ErrorStderrSchema)(e),
    (opt) => (opt._tag === "Some" ? opt.value.stderr : undefined)
  )

const extractCommand = (args: unknown) =>
  pipe(
    Schema.decodeUnknownOption(ArgsCommandSchema)(args),
    (opt) => (opt._tag === "Some" ? opt.value.command : "checkPattern")
  )

const extractTarget = (args: unknown) =>
  pipe(
    Schema.decodeUnknownOption(ArgsTargetSchema)(args),
    (opt) => (opt._tag === "Some" ? opt.value.target : ".")
  )

const DEFAULT_POLICY: Schema.Schema.Type<typeof PolicyModeSchema> = "strict"

const extractPolicy = (args: unknown) =>
  pipe(
    Schema.decodeUnknownOption(ArgsPolicySchema)(args),
    (opt) => (opt._tag === "Some" ? opt.value.policy : DEFAULT_POLICY)
  )

const readRepoPattern = (patternName: string) =>
  Effect.gen(function* () {
    const safeName = (patternName ?? "").trim()
    if (!safeName) {
      return yield* Effect.fail(
        new PatternNotFoundError({
          patternName: "",
          message: "patternName is required.",
        })
      )
    }

    const pPath = join(REPO_PATTERNS_DIR, `${safeName}.grit`)
    if (!existsSync(pPath)) {
      return yield* Effect.fail(
        new PatternNotFoundError({
          patternName: safeName,
          message: `Pattern '${safeName}' not found. Expected file: biome/gritql-patterns/${safeName}.grit`,
        })
      )
    }

    const text = yield* Effect.try({
      try: () => readFileSync(pPath, "utf-8"),
      catch: (e) =>
        new PatternNotFoundError({
          patternName: safeName,
          message: `Failed to read pattern file: ${extractMessage(e)}`,
        }),
    })

    return text
  })

const ensureGritAvailable = Effect.try({
  try: () => {
    execSync("grit --version", { stdio: "ignore" })
    return true
  },
  catch: () =>
    new GritNotFoundError({
      message: "Grit CLI not found in PATH.",
      recommendations: [
        "Enter the dev shell: `nix develop` (recommended), or ensure Home Manager/dev-config is applied.",
        "If you are not using Nix, install Grit CLI: https://docs.grit.io/cli/quickstart",
      ],
    }),
})

const policyViolation = (
  code: string,
  message: string,
  remediation?: readonly string[]
): Schema.Schema.Type<typeof ViolationSchema> => ({
  code,
  severity: "error",
  message,
  remediation: remediation ? [...remediation] : undefined,
})

const enforcePolicy = (args: {
  policy: Schema.Schema.Type<typeof PolicyModeSchema>
  command: Schema.Schema.Type<typeof CommandSchema>
  patternName: string | undefined
  pattern: string | undefined
  allowInline: boolean
  confirm: boolean
  runId: string | undefined
}) => {
  const violations: Schema.Schema.Type<typeof ViolationSchema>[] = []
  const { policy, command, patternName, pattern, allowInline, confirm, runId } = args

  if (policy === "off") return violations

  const hasName = Boolean(patternName && patternName.trim().length > 0)
  const hasInline = Boolean(pattern && pattern.trim().length > 0)

  if (!hasName && !hasInline && command !== "listPatterns" && command !== "explainUsage") {
    violations.push(
      policyViolation("gritql/missing-pattern", "Either patternName or pattern must be provided.", [
        "Prefer `patternName` pointing to biome/gritql-patterns/<name>.grit.",
        "Use `listPatterns` to discover available rules.",
      ])
    )
  }

  if (policy === "strict") {
    if (hasInline && !hasName && !allowInline) {
      violations.push(
        policyViolation(
          "gritql/inline-pattern-disallowed",
          "Inline patterns are disallowed under strict policy. Use a named repo pattern.",
          [
            "Create or reuse a pattern in `biome/gritql-patterns/` and reference it via patternName.",
            "If you must run inline temporarily, set allowInline=true (discouraged) and justify in your prompt.",
          ]
        )
      )
    }

    if (command === "applyPattern") {
      if (!confirm) {
        violations.push(
          policyViolation(
            "gritql/apply-requires-confirm",
            "applyPattern requires confirm=true under strict policy.",
            [
              "Run checkPattern first to produce a dry-run diff, review it, then re-run applyPattern with confirm=true.",
            ]
          )
        )
      }

      if (!runId) {
        violations.push(
          policyViolation(
            "gritql/apply-requires-runid",
            "applyPattern requires a runId from a prior checkPattern under strict policy.",
            [
              "Run checkPattern (dryRun=true) first; it returns runId.",
              "Call applyPattern with that runId to prove review intent.",
            ]
          )
        )
      }
    }
  }

  return violations
}

const runGritApply = (params: { patternText: string; target: string; dryRun: boolean; force: boolean }) =>
  Effect.try({
    try: () => {
      const { patternText, target, dryRun, force } = params
      const escapedPattern = patternText.replace(/'/g, "'\\''")
      const forceFlag = force ? " --force" : ""
      const dryRunFlag = dryRun ? " --dry-run" : ""
      const cmd = `grit apply '${escapedPattern}' ${target}${dryRunFlag}${forceFlag}`
      return execSync(cmd, { encoding: "utf-8", maxBuffer: 10 * 1024 * 1024 })
    },
    catch: (e) =>
      new GritExecutionError({
        stage: params.dryRun ? "dry-run" : "apply",
        message: extractMessage(e),
        output: extractStderr(e),
      }),
  })

const parseMatchesBestEffort = (raw: string) => {
  const matches: Schema.Schema.Type<typeof MatchSchema>[] = []
  const lines = raw.split("\n")

  const re1 = /^(.+?):(\d+):(\d+):\s*(.*)$/u
  const re2 = /^(.+?):(\d+):\s*(.*)$/u

  for (const line of lines) {
    const m1 = line.match(re1)
    if (m1) {
      matches.push({
        file: m1[1],
        startLine: Number(m1[2]),
        startColumn: Number(m1[3]),
        snippet: m1[4] || undefined,
      })
      continue
    }

    const m2 = line.match(re2)
    if (m2) {
      matches.push({
        file: m2[1],
        startLine: Number(m2[2]),
        snippet: m2[3] || undefined,
      })
    }
  }

  return matches
}

const summarize = (
  target: string,
  dryRun: boolean,
  patternsRun: number,
  matches: readonly Schema.Schema.Type<typeof MatchSchema>[]
): Schema.Schema.Type<typeof SummarySchema> => {
  const filesWithMatches = new Set(matches.map((m) => m.file)).size
  return {
    target,
    dryRun,
    patternsRun,
    matches: matches.length,
    filesWithMatches,
  }
}

const usageText = () =>
  [
    "gritql pseudo-API (LLM-optimized)",
    "",
    "STRICT POLICY (default):",
    "- All search/lint/modify must go through this tool.",
    "- applyPattern requires confirm=true and a runId from a prior checkPattern.",
    "- Inline patterns are discouraged; prefer repo patterns in biome/gritql-patterns/.",
    "",
    "Commands:",
    "1) listPatterns",
    "2) checkPattern (dry-run structural search + diff)",
    "3) applyPattern (structural rewrite; requires confirm + runId in strict mode)",
    "4) checkProject (run a ruleset of repo patterns across a target)",
    "",
    "Examples:",
    "- Find console.log:",
    '  checkPattern: pattern="`console.log($_)`" target="src/" allowInline=true',
    "",
    "- Apply a named pattern:",
    '  checkPattern: patternName="detect-missing-yield-star" target="."',
    '  applyPattern: patternName="detect-missing-yield-star" target="." runId=<from check> confirm=true',
    "",
    "- Run repo ruleset:",
    '  checkProject: patternNames=[...] target="."',
  ].join("\n")

// ============================================================================
// BUSINESS LOGIC (Effect.gen)
// ============================================================================

const executeGrit = (args: Schema.Schema.Type<typeof GritArgsSchema>) =>
  Effect.gen(function* () {
    const command = args.command ?? "checkPattern"
    const policy = args.policy ?? DEFAULT_POLICY
    const target = normalizeTarget(args.target)
    const patternName = args.patternName
    const pattern = args.pattern
    const allowInline = args.allowInline ?? false
    const includeDiff = args.includeDiff ?? true
    const confirm = args.confirm ?? false
    const runId = args.runId
    const force = args.force ?? false

    // explainUsage
    if (command === "explainUsage") {
      return new ToolSuccess({
        _tag: "success",
        command,
        policy,
        target,
        dryRun: true,
        output: usageText(),
        recommendations: [
          "Use checkPattern first (dry-run).",
          "Under strict policy, applyPattern requires confirm=true and runId from checkPattern.",
          "Prefer repo patterns in biome/gritql-patterns/.",
        ],
      })
    }

    // listPatterns
    if (command === "listPatterns") {
      const patterns = listRepoPatterns()
      return new ToolSuccess({
        _tag: "success",
        command,
        policy,
        target,
        dryRun: true,
        output: patterns.length
          ? `Available repo patterns:\n- ${patterns.join("\n- ")}`
          : "No repo patterns found.",
        recommendations: patterns.length
          ? ["Use checkPattern with patternName=<one of the listed patterns>."]
          : ["Add patterns to biome/gritql-patterns/*.grit", "Then use listPatterns to confirm discovery."],
      })
    }

    // Ensure grit is available
    yield* ensureGritAvailable

    // Policy enforcement
    const violations = enforcePolicy({
      policy,
      command,
      patternName,
      pattern,
      allowInline,
      confirm,
      runId,
    })

    if (violations.length > 0) {
      return new ToolFailure({
        _tag: "failure",
        command,
        policy,
        target,
        patternName: patternName?.trim() ? patternName.trim() : undefined,
        patternSource: patternName ? "repo" : pattern ? "inline" : undefined,
        dryRun: command !== "applyPattern",
        confirm,
        runId,
        violations: [...violations],
        error: "Policy violation: request rejected.",
        recommendations: ["Fix violations and retry.", "Use explainUsage for the required workflow."],
      })
    }

    // Resolve pattern text
    let patternText = ""
    let patternSource: "repo" | "inline" | undefined

    if (patternName && patternName.trim().length > 0) {
      patternText = yield* readRepoPattern(patternName)
      patternSource = "repo"
    } else if (pattern && pattern.trim().length > 0) {
      patternText = pattern
      patternSource = "inline"
    }

    // checkPattern
    if (command === "checkPattern") {
      const thisRunId = makeRunId("gritql_check")
      const raw = yield* runGritApply({ patternText, target, dryRun: true, force })
      const matches = parseMatchesBestEffort(raw)
      const ctxVersion = makeContextVersion(patternText, patternName?.trim())

      return new ToolSuccess({
        _tag: "success",
        command,
        policy,
        target,
        patternName: patternName?.trim() ? patternName.trim() : undefined,
        patternSource,
        dryRun: true,
        runId: thisRunId,
        contextVersion: ctxVersion,
        summary: summarize(target, true, 1, matches),
        matches: [...matches],
        diff: includeDiff ? { available: raw.trim().length > 0, unified: raw } : { available: false },
        output: raw.trim().length ? raw : "No matches found or no changes required.",
        recommendations: [
          "Review matches/diff.",
          policy === "strict"
            ? `If you want to modify code, call applyPattern with confirm=true, runId="${thisRunId}", and verify contextVersion hash matches.`
            : "If you want to modify code, call applyPattern.",
          "After applying changes, run `biome check .` (and any relevant project checks).",
        ],
      })
    }

    // applyPattern
    if (command === "applyPattern") {
      const thisRunId = makeRunId("gritql_apply")
      const ctxVersion = makeContextVersion(patternText, patternName?.trim())
      const dry = yield* runGritApply({ patternText, target, dryRun: true, force })
      const applied = yield* runGritApply({ patternText, target, dryRun: false, force })
      const matches = parseMatchesBestEffort(dry)

      return new ToolSuccess({
        _tag: "success",
        command,
        policy,
        target,
        patternName: patternName?.trim() ? patternName.trim() : undefined,
        patternSource,
        dryRun: false,
        runId: thisRunId,
        confirm,
        contextVersion: ctxVersion,
        summary: summarize(target, false, 1, matches),
        matches: [...matches],
        diff: includeDiff ? { available: dry.trim().length > 0, unified: dry } : { available: false },
        output: applied.trim().length ? applied : "Applied. (No additional output.)",
        recommendations: [
          ...(force ? ["⚠️ Applied with --force flag (git safety checks bypassed). Review changes carefully."] : []),
          "Run `biome check .` to validate formatting/linting.",
          "If this touched Nix files, run `nix flake show` / `home-manager build` as applicable.",
          "Review `git diff` and commit with a clear message.",
        ],
      })
    }

    // checkProject
    if (command === "checkProject") {
      const thisRunId = makeRunId("gritql_project")
      const names = args.patternNames ?? [...DEFAULT_RULESET]

      const available = new Set(listRepoPatterns())
      const missing = names.filter((n) => !available.has(n))

      if (missing.length > 0) {
        return new ToolFailure({
          _tag: "failure",
          command,
          policy,
          target,
          dryRun: true,
          runId: thisRunId,
          violations: [
            policyViolation(
              "gritql/missing-patterns",
              `Some patterns were not found in biome/gritql-patterns/: ${missing.join(", ")}`,
              ["Run listPatterns to see available patterns.", "Fix the rule list or add missing .grit files."]
            ),
          ],
          error: "Ruleset contains missing patterns.",
        })
      }

      const allMatches: Schema.Schema.Type<typeof MatchSchema>[] = []
      const perRule: { patternName: string; output: string; matches: Schema.Schema.Type<typeof MatchSchema>[] }[] = []

      for (const name of names) {
        const text = yield* readRepoPattern(name)
        const raw = yield* runGritApply({ patternText: text, target, dryRun: true, force })
        const matches = parseMatchesBestEffort(raw)
        allMatches.push(...matches)
        perRule.push({ patternName: name, output: raw, matches: [...matches] })
      }

      const summary = summarize(target, true, names.length, allMatches)

      const output = [
        `checkProject complete (dry-run):`,
        `- patternsRun: ${summary.patternsRun}`,
        `- matches: ${summary.matches}`,
        `- filesWithMatches: ${summary.filesWithMatches}`,
        "",
        ...perRule.map((r) => {
          const count = r.matches.length
          return `- ${r.patternName}: ${count} match${count === 1 ? "" : "es"}`
        }),
      ].join("\n")

      return new ToolSuccess({
        _tag: "success",
        command,
        policy,
        target,
        dryRun: true,
        runId: thisRunId,
        summary,
        matches: [...allMatches],
        output,
        recommendations: [
          "Use checkPattern with a specific patternName to inspect diffs more closely.",
          policy === "strict"
            ? "Apply fixes via applyPattern per pattern with confirm=true and runId from the relevant checkPattern."
            : "Apply fixes via applyPattern per pattern.",
        ],
      })
    }

    // Unknown command
    return new ToolFailure({
      _tag: "failure",
      command,
      policy,
      target,
      dryRun: true,
      error: `Unknown command: ${command}`,
      recommendations: ["Use explainUsage to see valid commands and workflows."],
    })
  })

// ============================================================================
// OPENCODE PLUGIN EXPORT (Bridge to Effect)
// ============================================================================

export default tool({
  description:
    "STRICT pseudo-API for structural search, linting, and refactoring via GritQL. Safe-by-default and policy-enforcing for LLM workflows.",
  args: {
    command: tool.schema
      .string()
      .describe("One of: listPatterns, checkPattern, applyPattern, checkProject, explainUsage")
      .default("checkPattern"),
    policy: tool.schema.string().optional().describe("Policy mode: strict (default), standard, off"),
    target: tool.schema.string().optional().describe("Target file or directory (default: '.')"),
    patternName: tool.schema
      .string()
      .optional()
      .describe("Name of repo pattern in biome/gritql-patterns (no extension)"),
    pattern: tool.schema.string().optional().describe("Inline GritQL pattern text (discouraged in strict mode)"),
    allowInline: tool.schema
      .boolean()
      .optional()
      .describe("Allow inline pattern under strict policy (discouraged). Default false.")
      .default(false),
    runId: tool.schema
      .string()
      .optional()
      .describe("Run id returned by checkPattern; required for applyPattern in strict policy."),
    confirm: tool.schema
      .boolean()
      .optional()
      .describe("Explicit confirmation required for applyPattern in strict policy.")
      .default(false),
    patternNames: tool.schema
      .array(tool.schema.string())
      .optional()
      .describe("List of repo patterns to run for checkProject (defaults to curated ruleset)."),
    includeDiff: tool.schema
      .boolean()
      .optional()
      .describe("Include unified diff output when available (default true).")
      .default(true),
    force: tool.schema
      .boolean()
      .optional()
      .describe("Bypass git safety checks for uncommitted changes (use with caution). Default false.")
      .default(false),
  },
  async execute(args) {
    const program = pipe(
      Schema.decodeUnknown(GritArgsSchema)(args),
      Effect.flatMap(executeGrit),
      Effect.catchTags({
        GritNotFoundError: (e) =>
          Effect.succeed(
            new ToolFailure({
              _tag: "failure",
              command: extractCommand(args),
              policy: extractPolicy(args),
              target: extractTarget(args),
              dryRun: true,
              error: e.message,
              recommendations: [...e.recommendations],
            })
          ),
        PatternNotFoundError: (e) =>
          Effect.succeed(
            new ToolFailure({
              _tag: "failure",
              command: extractCommand(args),
              policy: extractPolicy(args),
              target: extractTarget(args),
              patternName: e.patternName,
              dryRun: true,
              error: e.message,
              recommendations: [
                "Run listPatterns to see valid pattern names.",
                "Ensure the pattern file exists under biome/gritql-patterns/.",
              ],
            })
          ),
        GritExecutionError: (e) =>
          Effect.succeed(
            new ToolFailure({
              _tag: "failure",
              command: extractCommand(args),
              policy: extractPolicy(args),
              target: extractTarget(args),
              dryRun: e.stage === "dry-run",
              error: `Grit execution failed: ${e.message}`,
              output: e.output,
              recommendations: [
                "Ensure the GritQL pattern is valid.",
                "Try narrowing the target.",
                "If this is a repo pattern, validate the .grit file syntax.",
              ],
            })
          ),
      }),
      Effect.catchAllDefect((defect) =>
        Effect.succeed(
          new ToolFailure({
            _tag: "failure",
            command: extractCommand(args),
            policy: extractPolicy(args),
            target: extractTarget(args),
            dryRun: true,
            error: extractMessage(defect),
            recommendations: ["An unexpected error occurred. Check the pattern and target."],
          })
        )
      )
    )

    const result = await Effect.runPromise(program).catch(
      (e) =>
        new ToolFailure({
          _tag: "failure",
          command: extractCommand(args),
          policy: extractPolicy(args),
          target: extractTarget(args),
          dryRun: true,
          error: extractMessage(e),
          recommendations: ["An unexpected error occurred."],
        })
    )

    return JSON.stringify(
      result._tag === "success" ? { success: true, ...result } : { success: false, ...result },
      null,
      2
    )
  },
})
