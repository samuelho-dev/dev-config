import { tool } from "@opencode-ai/plugin"
import { Effect, Schema, Data, pipe } from "effect"
import { existsSync, readFileSync, readdirSync } from "fs"
import { join } from "path"
import { execSync } from "child_process"

// ============================================================
// mlg - Monorepo Library Generator Tool (Effect TS)
// Scaffolds Effect-TS libraries in Nx monorepos with strict policy enforcement
// ============================================================

// ============================================================================
// EFFECT SCHEMA DEFINITIONS
// ============================================================================

const PolicyModeSchema = Schema.Literal("strict", "standard", "off")

const CommandSchema = Schema.Literal(
  "create",
  "dryRun",
  "listTypes",
  "explainUsage",
  "validateLayers"
)

const LibraryTypeSchema = Schema.Literal(
  "contract",
  "data-access",
  "feature",
  "infra",
  "provider"
)

const PlatformSchema = Schema.Literal("node", "universal", "edge")

const SeveritySchema = Schema.Literal("info", "warn", "error")

const ViolationSchema = Schema.Struct({
  code: Schema.String,
  severity: SeveritySchema,
  message: Schema.String,
  remediation: Schema.optional(Schema.Array(Schema.String)),
})

const EffectLayerSchema = Schema.Literal(
  "Domain",
  "Service",
  "Orchestration",
  "Infrastructure",
  "Integration"
)

const LayerValidationResultSchema = Schema.Struct({
  libraryName: Schema.String,
  libraryType: Schema.String,
  expectedLayer: EffectLayerSchema,
  violations: Schema.Array(ViolationSchema),
  passed: Schema.Boolean,
})

const MlgArgsSchema = Schema.Struct({
  command: Schema.optional(CommandSchema).annotations({
    description: "One of: create, dryRun, listTypes, explainUsage, validateLayers",
  }),
  libraryType: Schema.optional(LibraryTypeSchema).annotations({
    description: "Library type: contract, data-access, feature, infra, provider",
  }),
  name: Schema.optional(Schema.String).annotations({
    description: "Library name (e.g., 'user', 'payments', 'auth')",
  }),
  entities: Schema.optional(Schema.Array(Schema.String)).annotations({
    description: "Entity names for contract libraries (e.g., ['User', 'Account'])",
  }),
  includeCQRS: Schema.optional(Schema.Boolean).annotations({
    description: "Generate CQRS commands/queries (contract, feature)",
  }),
  includeRPC: Schema.optional(Schema.Boolean).annotations({
    description: "Create RPC endpoint definitions (contract, feature)",
  }),
  platform: Schema.optional(PlatformSchema).annotations({
    description: "Target runtime: node, universal, edge (feature, infra, provider)",
  }),
  externalService: Schema.optional(Schema.String).annotations({
    description: "Name of wrapped SDK service (provider only)",
  }),
  policy: Schema.optional(PolicyModeSchema).annotations({
    description: "Policy mode: strict (default), standard, off",
  }),
  confirm: Schema.optional(Schema.Boolean).annotations({
    description: "Explicit confirmation required for create in strict policy",
  }),
  runId: Schema.optional(Schema.String).annotations({
    description: "Run id returned by dryRun; required for create in strict policy",
  }),
  targetLibrary: Schema.optional(Schema.String).annotations({
    description: "Library path for validateLayers command (e.g., 'libs/user-contract')",
  }),
})

// ============================================================================
// ERROR TYPES (Data.TaggedError)
// ============================================================================

class MlgNotFoundError extends Data.TaggedError("MlgNotFoundError")<{
  readonly message: string
  readonly recommendations: readonly string[]
}> {}

class MlgExecutionError extends Data.TaggedError("MlgExecutionError")<{
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
  libraryType: Schema.optional(Schema.String),
  name: Schema.optional(Schema.String),
  dryRun: Schema.Boolean,
  runId: Schema.optional(Schema.String),
  confirm: Schema.optional(Schema.Boolean),
  output: Schema.optional(Schema.String),
  createdFiles: Schema.optional(Schema.Array(Schema.String)),
  recommendations: Schema.Array(Schema.String),
}) {}

class ToolFailure extends Schema.Class<ToolFailure>("ToolFailure")({
  _tag: Schema.Literal("failure"),
  command: Schema.String,
  policy: PolicyModeSchema,
  libraryType: Schema.optional(Schema.String),
  name: Schema.optional(Schema.String),
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

const DEFAULT_POLICY: Schema.Schema.Type<typeof PolicyModeSchema> = "strict"
const DEFAULT_COMMAND: Schema.Schema.Type<typeof CommandSchema> = "dryRun"

const LIBRARY_TYPE_INFO = {
  contract: {
    description: "Domain boundaries and interfaces with Effect Schema entities",
    flags: ["--entities", "--includeCQRS", "--includeRPC"],
  },
  "data-access": {
    description: "Repository pattern implementations with Kysely query builders",
    flags: [],
  },
  feature: {
    description: "Business logic orchestration with platform-specific exports",
    flags: ["--includeCQRS", "--includeRPC", "--platform"],
  },
  infra: {
    description: "Cross-cutting technical services (caching, logging)",
    flags: ["--platform"],
  },
  provider: {
    description: "External service integrations wrapping SDKs with Effect interfaces",
    flags: ["--platform", "--externalService"],
  },
} as const

const LIBRARY_TYPE_TO_LAYER: Record<Schema.Schema.Type<typeof LibraryTypeSchema>, Schema.Schema.Type<typeof EffectLayerSchema>> = {
  contract: "Domain",
  "data-access": "Service",
  feature: "Orchestration",
  infra: "Infrastructure",
  provider: "Integration",
}

const RULES_PATH = join(process.cwd(), ".opencode", "rules", "rules.json")
const GRIT_PATTERNS_DIR = join(process.cwd(), "biome", "gritql-patterns")

// Schemas for rules.json extraction
const LibraryTypeRulesSchema = Schema.Struct({
  requiredPatterns: Schema.optional(Schema.Array(Schema.String)),
})

const DependencyRuleSchema = Schema.Struct({
  forbiddenImports: Schema.optional(Schema.Array(Schema.String)),
})

const RulesLibraryTypesSchema = Schema.Record({
  key: Schema.String,
  value: LibraryTypeRulesSchema,
})

const RulesDependencyMatrixSchema = Schema.Record({
  key: Schema.String,
  value: DependencyRuleSchema,
})

const RulesSchema = Schema.Struct({
  libraryTypes: Schema.optional(RulesLibraryTypesSchema),
  dependencyMatrix: Schema.optional(RulesDependencyMatrixSchema),
})

const extractRules = (rules: unknown) =>
  pipe(
    Schema.decodeUnknownOption(RulesSchema)(rules),
    (opt) => (opt._tag === "Some" ? opt.value : undefined)
  )

// Schema for project.json tags
const ProjectJsonSchema = Schema.Struct({
  tags: Schema.optional(Schema.Array(Schema.String)),
})

const extractProjectTags = (projectJson: unknown): readonly string[] =>
  pipe(
    Schema.decodeUnknownOption(ProjectJsonSchema)(projectJson),
    (opt) => (opt._tag === "Some" ? opt.value.tags ?? [] : [])
  )

// Valid library types for validation (widened to string[] for includes check)
const VALID_LIBRARY_TYPES: readonly string[] = ["contract", "data-access", "feature", "infra", "provider"]

const isValidLibraryType = (type: string): type is Schema.Schema.Type<typeof LibraryTypeSchema> =>
  VALID_LIBRARY_TYPES.includes(type)

// ============================================================================
// EXTRACTION SCHEMAS (strict schema, no type guards)
// ============================================================================

const ErrorMessageSchema = Schema.Struct({ message: Schema.String })
const ErrorStderrSchema = Schema.Struct({ stderr: Schema.String })
const ArgsCommandSchema = Schema.Struct({ command: Schema.String })
const ArgsPolicySchema = Schema.Struct({ policy: PolicyModeSchema })
const ArgsLibraryTypeSchema = Schema.Struct({ libraryType: Schema.String })
const ArgsNameSchema = Schema.Struct({ name: Schema.String })

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
    (opt) => (opt._tag === "Some" ? opt.value.command : DEFAULT_COMMAND)
  )

const extractPolicy = (args: unknown) =>
  pipe(
    Schema.decodeUnknownOption(ArgsPolicySchema)(args),
    (opt) => (opt._tag === "Some" ? opt.value.policy : DEFAULT_POLICY)
  )

const extractLibraryType = (args: unknown) =>
  pipe(
    Schema.decodeUnknownOption(ArgsLibraryTypeSchema)(args),
    (opt) => (opt._tag === "Some" ? opt.value.libraryType : undefined)
  )

const extractName = (args: unknown) =>
  pipe(
    Schema.decodeUnknownOption(ArgsNameSchema)(args),
    (opt) => (opt._tag === "Some" ? opt.value.name : undefined)
  )

// ============================================================================
// HELPER FUNCTIONS (strict typing - no return type annotations)
// ============================================================================

const nowIso = () => new Date().toISOString()

const makeRunId = (prefix: string) =>
  `${prefix}_${nowIso()}_${Math.random().toString(16).slice(2)}`

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
  libraryType: string | undefined
  name: string | undefined
  confirm: boolean
  runId: string | undefined
}) => {
  const violations: Schema.Schema.Type<typeof ViolationSchema>[] = []
  const { policy, command, libraryType, name, confirm, runId } = args

  if (policy === "off") return violations

  // Require libraryType and name for create/dryRun commands
  if (command === "create" || command === "dryRun") {
    if (!libraryType || !libraryType.trim()) {
      violations.push(
        policyViolation(
          "mlg/missing-library-type",
          "libraryType is required for create/dryRun commands.",
          ["Use listTypes to see available library types."]
        )
      )
    }

    if (!name || !name.trim()) {
      violations.push(
        policyViolation(
          "mlg/missing-name",
          "name is required for create/dryRun commands.",
          ["Provide a library name (e.g., name='user', name='payments')."]
        )
      )
    }
  }

  if (policy === "strict") {
    if (command === "create") {
      if (!confirm) {
        violations.push(
          policyViolation(
            "mlg/create-requires-confirm",
            "create requires confirm=true under strict policy.",
            [
              "Run dryRun first to preview what will be created.",
              "Then call create with confirm=true and the runId from dryRun.",
            ]
          )
        )
      }

      if (!runId) {
        violations.push(
          policyViolation(
            "mlg/create-requires-runid",
            "create requires a runId from a prior dryRun under strict policy.",
            [
              "Run dryRun command first; it returns a runId.",
              "Call create with that runId to prove review intent.",
            ]
          )
        )
      }
    }
  }

  return violations
}

const ensureMlgAvailable = Effect.tryPromise({
  try: async () => {
    await Bun.$`mlg --help`.quiet()
    return true
  },
  catch: () =>
    new MlgNotFoundError({
      message: "mlg CLI not found in PATH.",
      recommendations: [
        "Enter the dev shell: `nix develop` (recommended)",
        "Or ensure Home Manager/dev-config is applied.",
        "The mlg command is provided by the monorepo-library-generator package.",
      ],
    }),
})

const buildFlags = (args: Schema.Schema.Type<typeof MlgArgsSchema>) => {
  const flags: string[] = []

  if (args.entities && args.entities.length > 0) {
    flags.push("--entities", args.entities.join(","))
  }

  if (args.includeCQRS) {
    flags.push("--includeCQRS")
  }

  if (args.includeRPC) {
    flags.push("--includeRPC")
  }

  if (args.platform) {
    flags.push("--platform", args.platform)
  }

  if (args.externalService) {
    flags.push("--externalService", args.externalService)
  }

  return flags
}

const runMlg = (params: {
  libraryType: string
  name: string
  flags: readonly string[]
  dryRun: boolean
}) =>
  Effect.tryPromise({
    try: async () => {
      const args = [params.libraryType, params.name, ...params.flags]
      if (params.dryRun) {
        args.push("--dry-run")
      }
      const result = await Bun.$`mlg ${args}`.text()
      return result
    },
    catch: (e) =>
      new MlgExecutionError({
        stage: params.dryRun ? "dry-run" : "create",
        message: extractMessage(e),
        output: extractStderr(e),
      }),
  })

const parseCreatedFiles = (output: string) => {
  const files: string[] = []
  const lines = output.split("\n")

  for (const line of lines) {
    // Look for lines that mention created files
    const createMatch = line.match(/(?:CREATE|Created|created|CREATED)\s+(.+)/u)
    if (createMatch) {
      files.push(createMatch[1].trim())
    }
  }

  return files
}

const loadRules = () =>
  Effect.try({
    try: () => {
      if (!existsSync(RULES_PATH)) {
        return null
      }
      return JSON.parse(readFileSync(RULES_PATH, "utf-8"))
    },
    catch: () => null,
  })

const detectLibraryType = (libraryPath: string): Schema.Schema.Type<typeof LibraryTypeSchema> | null => {
  const projectJsonPath = join(libraryPath, "project.json")
  if (!existsSync(projectJsonPath)) return null

  const projectJsonRaw = JSON.parse(readFileSync(projectJsonPath, "utf-8"))
  const tags = extractProjectTags(projectJsonRaw)

  for (const tag of tags) {
    if (tag.startsWith("type:")) {
      const type = tag.replace("type:", "")
      if (isValidLibraryType(type)) {
        return type
      }
    }
  }

  // Fallback: infer from name
  const name = libraryPath.split("/").pop() ?? ""
  if (name.endsWith("-contract") || name.includes("contract")) return "contract"
  if (name.endsWith("-data") || name.includes("data-access")) return "data-access"
  if (name.endsWith("-feature") || name.includes("feature")) return "feature"
  if (name.endsWith("-infra") || name.includes("infra")) return "infra"
  if (name.endsWith("-provider") || name.includes("provider")) return "provider"

  return null
}

const runGritCheck = (patternName: string, target: string) =>
  Effect.try({
    try: () => {
      const patternPath = join(GRIT_PATTERNS_DIR, `${patternName}.grit`)
      if (!existsSync(patternPath)) {
        return { found: false, matches: 0, output: "" }
      }
      const patternText = readFileSync(patternPath, "utf-8")
      const output = execSync(
        `grit apply '${patternText.replace(/'/g, "'\\''")}' ${target} --dry-run`,
        { encoding: "utf-8", maxBuffer: 10 * 1024 * 1024 }
      )
      const matches = (output.match(/:\d+:/g) ?? []).length
      return { found: true, matches, output }
    },
    catch: (e) => ({ found: true, matches: 0, output: extractMessage(e) }),
  })

const validateLibraryLayers = (
  libraryPath: string,
  libraryType: Schema.Schema.Type<typeof LibraryTypeSchema>,
  rulesRaw: unknown
) =>
  Effect.gen(function* () {
    const violations: Schema.Schema.Type<typeof ViolationSchema>[] = []
    const expectedLayer = LIBRARY_TYPE_TO_LAYER[libraryType]

    // Extract rules using schema
    const rules = extractRules(rulesRaw)

    // Get required patterns from rules
    const libraryTypeRules = rules?.libraryTypes?.[libraryType]
    const requiredPatterns = libraryTypeRules?.requiredPatterns ?? []

    // Run each required pattern
    for (const patternName of requiredPatterns) {
      const result = yield* runGritCheck(patternName, libraryPath)
      if (result.found && result.matches > 0) {
        violations.push(
          policyViolation(
            `mlg/layer-violation-${patternName}`,
            `Pattern '${patternName}' found ${result.matches} violation(s) in ${libraryPath}`,
            [
              `Run: gritql checkPattern patternName="${patternName}" target="${libraryPath}"`,
              "Review matches and apply fixes.",
            ]
          )
        )
      }
    }

    // Check for forbidden imports based on dependency matrix
    const dependencyRule = rules?.dependencyMatrix?.[libraryType]
    const forbidden = dependencyRule?.forbiddenImports ?? []

    if (forbidden.length > 0) {
      // Check tsconfig paths for forbidden imports
      const tsconfigPath = join(libraryPath, "tsconfig.json")
      if (existsSync(tsconfigPath)) {
        const tsconfig = readFileSync(tsconfigPath, "utf-8")
        for (const forbiddenType of forbidden) {
          if (tsconfig.includes(`-${forbiddenType}`) || tsconfig.includes(`/${forbiddenType}/`)) {
            violations.push(
              policyViolation(
                `mlg/forbidden-import-${forbiddenType}`,
                `Library type '${libraryType}' should not import from '${forbiddenType}' libraries`,
                [
                  `${libraryType} libraries can only depend on: ${LIBRARY_TYPE_INFO[libraryType]?.flags?.join(", ") ?? "none"}`,
                  "Remove the forbidden import or reconsider the library architecture.",
                ]
              )
            )
          }
        }
      }
    }

    return {
      libraryName: libraryPath.split("/").pop() ?? libraryPath,
      libraryType,
      expectedLayer,
      violations: [...violations],
      passed: violations.length === 0,
    }
  })

const usageText = () =>
  [
    "mlg - Monorepo Library Generator (LLM-optimized)",
    "",
    "STRICT POLICY (default):",
    "- All library creation must go through this tool.",
    "- create requires confirm=true and a runId from a prior dryRun.",
    "- Always preview with dryRun before creating.",
    "",
    "Commands:",
    "1) listTypes - Show available library types",
    "2) dryRun - Preview what will be created (returns runId)",
    "3) create - Generate the library (requires confirm + runId in strict mode)",
    "4) validateLayers - Validate library follows Effect Layer patterns",
    "5) explainUsage - Show this help text",
    "",
    "Library Types & Effect Layers:",
    "- contract (Domain): Domain boundaries, Effect Schema entities",
    "- data-access (Service): Repository pattern with Kysely",
    "- feature (Orchestration): Business logic orchestration",
    "- infra (Infrastructure): Cross-cutting services (caching, logging)",
    "- provider (Integration): External SDK integrations",
    "",
    "Examples:",
    "- Preview creating a contract library:",
    '  dryRun: libraryType="contract" name="user" entities=["User","Account"]',
    "",
    "- Create after preview:",
    '  create: libraryType="contract" name="user" entities=["User","Account"] runId=<from dryRun> confirm=true',
    "",
    "- Validate a library follows Effect Layer patterns:",
    '  validateLayers: targetLibrary="libs/user-contract"',
    "",
    "- Create a feature library with CQRS:",
    '  dryRun: libraryType="feature" name="payments" includeCQRS=true platform="node"',
    '  create: libraryType="feature" name="payments" includeCQRS=true platform="node" runId=<from dryRun> confirm=true',
  ].join("\n")

const listTypesText = () => {
  const lines = ["Available Library Types:", ""]

  for (const [type, info] of Object.entries(LIBRARY_TYPE_INFO)) {
    lines.push(`${type}:`)
    lines.push(`  ${info.description}`)
    if (info.flags.length > 0) {
      lines.push(`  Flags: ${info.flags.join(", ")}`)
    }
    lines.push("")
  }

  return lines.join("\n")
}

// ============================================================================
// BUSINESS LOGIC (Effect.gen)
// ============================================================================

const executeMlg = (args: Schema.Schema.Type<typeof MlgArgsSchema>) =>
  Effect.gen(function* () {
    const command = args.command ?? DEFAULT_COMMAND
    const policy = args.policy ?? DEFAULT_POLICY
    const libraryType = args.libraryType
    const name = args.name
    const confirm = args.confirm ?? false
    const runId = args.runId

    // explainUsage
    if (command === "explainUsage") {
      return new ToolSuccess({
        _tag: "success",
        command,
        policy,
        dryRun: true,
        output: usageText(),
        recommendations: [
          "Use dryRun first to preview library creation.",
          "Under strict policy, create requires confirm=true and runId from dryRun.",
          "Use listTypes to see available library types.",
        ],
      })
    }

    // listTypes
    if (command === "listTypes") {
      return new ToolSuccess({
        _tag: "success",
        command,
        policy,
        dryRun: true,
        output: listTypesText(),
        recommendations: [
          "Use dryRun with libraryType and name to preview library creation.",
          "Each library type has specific flags - see explainUsage for details.",
        ],
      })
    }

    // validateLayers
    if (command === "validateLayers") {
      const targetLibrary = args.targetLibrary?.trim()

      if (!targetLibrary) {
        return new ToolFailure({
          _tag: "failure",
          command,
          policy,
          dryRun: true,
          error: "targetLibrary is required for validateLayers command.",
          recommendations: [
            'Provide a library path: validateLayers targetLibrary="libs/user-contract"',
            "The library must have a project.json with type tags or follow naming conventions.",
          ],
        })
      }

      if (!existsSync(targetLibrary)) {
        return new ToolFailure({
          _tag: "failure",
          command,
          policy,
          dryRun: true,
          error: `Library path not found: ${targetLibrary}`,
          recommendations: [
            "Verify the library path exists.",
            "Use a relative path from the monorepo root (e.g., libs/user-contract).",
          ],
        })
      }

      const detectedType = detectLibraryType(targetLibrary)
      if (!detectedType) {
        return new ToolFailure({
          _tag: "failure",
          command,
          policy,
          dryRun: true,
          error: `Could not detect library type for: ${targetLibrary}`,
          recommendations: [
            "Add a type:xxx tag to project.json (e.g., type:contract, type:feature).",
            "Or use naming conventions: -contract, -data-access, -feature, -infra, -provider.",
          ],
        })
      }

      const rules = yield* loadRules()
      const validationResult = yield* validateLibraryLayers(targetLibrary, detectedType, rules)

      if (validationResult.passed) {
        return new ToolSuccess({
          _tag: "success",
          command,
          policy,
          libraryType: detectedType,
          name: validationResult.libraryName,
          dryRun: true,
          output: [
            `Library validation PASSED for ${validationResult.libraryName}`,
            `Type: ${validationResult.libraryType}`,
            `Expected Effect Layer: ${validationResult.expectedLayer}`,
            `Violations: 0`,
          ].join("\n"),
          recommendations: [
            "Library follows Effect Layer patterns correctly.",
            "Continue with development or run tests.",
          ],
        })
      }

      return new ToolFailure({
        _tag: "failure",
        command,
        policy,
        libraryType: detectedType,
        name: validationResult.libraryName,
        dryRun: true,
        violations: validationResult.violations,
        error: `Library validation FAILED for ${validationResult.libraryName}`,
        output: [
          `Type: ${validationResult.libraryType}`,
          `Expected Effect Layer: ${validationResult.expectedLayer}`,
          `Violations: ${validationResult.violations.length}`,
        ].join("\n"),
        recommendations: [
          "Fix the violations listed above.",
          "Use @gritql checkPattern to inspect specific violations.",
          "Re-run validateLayers after fixes.",
        ],
      })
    }

    // Policy enforcement for create/dryRun
    const violations = enforcePolicy({
      policy,
      command,
      libraryType,
      name,
      confirm,
      runId,
    })

    if (violations.length > 0) {
      return new ToolFailure({
        _tag: "failure",
        command,
        policy,
        libraryType: libraryType?.trim() ? libraryType.trim() : undefined,
        name: name?.trim() ? name.trim() : undefined,
        dryRun: command === "dryRun",
        confirm,
        runId,
        violations: [...violations],
        error: "Policy violation: request rejected.",
        recommendations: ["Fix violations and retry.", "Use explainUsage for the required workflow."],
      })
    }

    // Ensure mlg is available
    yield* ensureMlgAvailable

    const safeLibraryType = libraryType!.trim()
    const safeName = name!.trim()
    const flags = buildFlags(args)

    // dryRun command
    if (command === "dryRun") {
      const thisRunId = makeRunId("mlg_dryrun")
      const output = yield* runMlg({
        libraryType: safeLibraryType,
        name: safeName,
        flags,
        dryRun: true,
      })

      return new ToolSuccess({
        _tag: "success",
        command,
        policy,
        libraryType: safeLibraryType,
        name: safeName,
        dryRun: true,
        runId: thisRunId,
        output: output.trim().length ? output : "Dry run complete. No issues detected.",
        createdFiles: parseCreatedFiles(output),
        recommendations: [
          "Review the files that would be created.",
          policy === "strict"
            ? `To create the library, call create with confirm=true and runId="${thisRunId}".`
            : "To create the library, call create with confirm=true.",
          "After creation, run `nx build ${safeName}` to verify the library builds correctly.",
        ],
      })
    }

    // create command
    if (command === "create") {
      const thisRunId = makeRunId("mlg_create")
      const output = yield* runMlg({
        libraryType: safeLibraryType,
        name: safeName,
        flags,
        dryRun: false,
      })

      const createdFiles = parseCreatedFiles(output)

      return new ToolSuccess({
        _tag: "success",
        command,
        policy,
        libraryType: safeLibraryType,
        name: safeName,
        dryRun: false,
        runId: thisRunId,
        confirm,
        output: output.trim().length ? output : "Library created successfully.",
        createdFiles,
        recommendations: [
          `Run \`nx build ${safeName}\` to verify the library builds.`,
          `Run \`nx test ${safeName}\` to run any generated tests.`,
          "Review the generated CLAUDE.md file for AI agent reference.",
          "Commit the new library with a descriptive message.",
        ],
      })
    }

    // Unknown command
    return new ToolFailure({
      _tag: "failure",
      command,
      policy,
      libraryType: libraryType?.trim() ? libraryType.trim() : undefined,
      name: name?.trim() ? name.trim() : undefined,
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
    "Scaffolds Effect-TS libraries in Nx monorepos. Enforces strict policy with dry-run preview and confirmation workflow for safe AI-assisted library generation.",
  args: {
    command: tool.schema
      .string()
      .describe("One of: create, dryRun, listTypes, explainUsage, validateLayers")
      .default("dryRun"),
    libraryType: tool.schema
      .string()
      .optional()
      .describe("Library type: contract, data-access, feature, infra, provider"),
    name: tool.schema
      .string()
      .optional()
      .describe("Library name (e.g., 'user', 'payments', 'auth')"),
    entities: tool.schema
      .array(tool.schema.string())
      .optional()
      .describe("Entity names for contract libraries (e.g., ['User', 'Account'])"),
    includeCQRS: tool.schema
      .boolean()
      .optional()
      .describe("Generate CQRS commands/queries (contract, feature)")
      .default(false),
    includeRPC: tool.schema
      .boolean()
      .optional()
      .describe("Create RPC endpoint definitions (contract, feature)")
      .default(false),
    platform: tool.schema
      .string()
      .optional()
      .describe("Target runtime: node, universal, edge (feature, infra, provider)"),
    externalService: tool.schema
      .string()
      .optional()
      .describe("Name of wrapped SDK service (provider only)"),
    policy: tool.schema
      .string()
      .optional()
      .describe("Policy mode: strict (default), standard, off"),
    confirm: tool.schema
      .boolean()
      .optional()
      .describe("Explicit confirmation required for create in strict policy")
      .default(false),
    runId: tool.schema
      .string()
      .optional()
      .describe("Run id returned by dryRun; required for create in strict policy"),
    targetLibrary: tool.schema
      .string()
      .optional()
      .describe("Library path for validateLayers command (e.g., 'libs/user-contract')"),
  },
  async execute(args) {
    const program = pipe(
      Schema.decodeUnknown(MlgArgsSchema)(args),
      Effect.flatMap(executeMlg),
      Effect.catchTags({
        MlgNotFoundError: (e) =>
          Effect.succeed(
            new ToolFailure({
              _tag: "failure",
              command: extractCommand(args),
              policy: extractPolicy(args),
              libraryType: extractLibraryType(args),
              name: extractName(args),
              dryRun: true,
              error: e.message,
              recommendations: [...e.recommendations],
            })
          ),
        MlgExecutionError: (e) =>
          Effect.succeed(
            new ToolFailure({
              _tag: "failure",
              command: extractCommand(args),
              policy: extractPolicy(args),
              libraryType: extractLibraryType(args),
              name: extractName(args),
              dryRun: e.stage === "dry-run",
              error: `mlg execution failed: ${e.message}`,
              output: e.output,
              recommendations: [
                "Ensure you are in an Nx monorepo workspace.",
                "Check that the library name doesn't conflict with existing libraries.",
                "Try running `mlg --help` directly to diagnose issues.",
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
            libraryType: extractLibraryType(args),
            name: extractName(args),
            dryRun: true,
            error: defect instanceof Error ? defect.message : String(defect),
            recommendations: ["An unexpected error occurred. Check the library type and name."],
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
          libraryType: extractLibraryType(args),
          name: extractName(args),
          dryRun: true,
          error: e instanceof Error ? e.message : String(e),
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
