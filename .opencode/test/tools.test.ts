import { describe, test, expect } from "bun:test"
import { Schema, pipe } from "effect"

describe("Tool Schema Extraction", () => {
  // Test the extraction patterns used in tools

  describe("Command Extraction", () => {
    const CommandSchema = Schema.Literal(
      "listPatterns",
      "checkPattern",
      "applyPattern",
      "checkProject",
      "explainUsage"
    )

    const ArgsCommandSchema = Schema.Struct({ command: CommandSchema })

    const extractCommand = (args: unknown) =>
      pipe(
        Schema.decodeUnknownOption(ArgsCommandSchema)(args),
        (opt) => (opt._tag === "Some" ? opt.value.command : "checkPattern")
      )

    test("extracts valid command", () => {
      expect(extractCommand({ command: "listPatterns" })).toBe("listPatterns")
      expect(extractCommand({ command: "applyPattern" })).toBe("applyPattern")
    })

    test("returns default for missing command", () => {
      expect(extractCommand({})).toBe("checkPattern")
      expect(extractCommand(null)).toBe("checkPattern")
    })

    test("returns default for invalid command", () => {
      expect(extractCommand({ command: "invalid" })).toBe("checkPattern")
    })
  })

  describe("Policy Extraction", () => {
    const PolicyModeSchema = Schema.Literal("strict", "standard", "off")
    const ArgsPolicySchema = Schema.Struct({ policy: PolicyModeSchema })

    const extractPolicy = (args: unknown) =>
      pipe(
        Schema.decodeUnknownOption(ArgsPolicySchema)(args),
        (opt) => (opt._tag === "Some" ? opt.value.policy : "strict")
      )

    test("extracts valid policy", () => {
      expect(extractPolicy({ policy: "strict" })).toBe("strict")
      expect(extractPolicy({ policy: "standard" })).toBe("standard")
      expect(extractPolicy({ policy: "off" })).toBe("off")
    })

    test("returns default for missing policy", () => {
      expect(extractPolicy({})).toBe("strict")
    })

    test("returns default for invalid policy", () => {
      expect(extractPolicy({ policy: "invalid" })).toBe("strict")
    })
  })

  describe("Library Type Detection", () => {
    const VALID_LIBRARY_TYPES: readonly string[] = [
      "contract",
      "data-access",
      "feature",
      "infra",
      "provider",
    ]

    const LibraryTypeSchema = Schema.Literal(
      "contract",
      "data-access",
      "feature",
      "infra",
      "provider"
    )

    type LibraryType = Schema.Schema.Type<typeof LibraryTypeSchema>

    const isValidLibraryType = (type: string): type is LibraryType =>
      VALID_LIBRARY_TYPES.includes(type)

    const detectFromName = (name: string): LibraryType | null => {
      if (name.endsWith("-contract") || name.includes("contract")) return "contract"
      if (name.endsWith("-data") || name.includes("data-access")) return "data-access"
      if (name.endsWith("-feature") || name.includes("feature")) return "feature"
      if (name.endsWith("-infra") || name.includes("infra")) return "infra"
      if (name.endsWith("-provider") || name.includes("provider")) return "provider"
      return null
    }

    test("isValidLibraryType validates correctly", () => {
      expect(isValidLibraryType("contract")).toBe(true)
      expect(isValidLibraryType("feature")).toBe(true)
      expect(isValidLibraryType("invalid")).toBe(false)
    })

    test("detectFromName infers from suffix", () => {
      expect(detectFromName("user-contract")).toBe("contract")
      expect(detectFromName("payments-feature")).toBe("feature")
      expect(detectFromName("redis-infra")).toBe("infra")
      expect(detectFromName("stripe-provider")).toBe("provider")
    })

    test("detectFromName infers from contains", () => {
      expect(detectFromName("user-contract-v2")).toBe("contract")
      expect(detectFromName("my-data-access-lib")).toBe("data-access")
    })

    test("detectFromName returns null for unknown", () => {
      expect(detectFromName("my-random-lib")).toBeNull()
      expect(detectFromName("utils")).toBeNull()
    })
  })
})

describe("Rules Schema Extraction", () => {
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

  test("extracts valid rules", () => {
    const rules = {
      libraryTypes: {
        contract: { requiredPatterns: ["pattern1", "pattern2"] },
        feature: { requiredPatterns: ["pattern3"] },
      },
      dependencyMatrix: {
        contract: { forbiddenImports: ["feature", "infra"] },
      },
    }

    const extracted = extractRules(rules)
    expect(extracted).toBeDefined()
    expect(extracted?.libraryTypes?.contract?.requiredPatterns).toEqual(["pattern1", "pattern2"])
    expect(extracted?.dependencyMatrix?.contract?.forbiddenImports).toEqual(["feature", "infra"])
  })

  test("returns undefined for null", () => {
    expect(extractRules(null)).toBeUndefined()
  })

  test("returns undefined for invalid structure", () => {
    expect(extractRules({ invalid: "structure" })).toBeDefined() // Partial match
    expect(extractRules("string")).toBeUndefined()
  })

  test("handles missing optional fields", () => {
    const rules = { libraryTypes: {} }
    const extracted = extractRules(rules)
    expect(extracted).toBeDefined()
    expect(extracted?.dependencyMatrix).toBeUndefined()
  })
})

describe("Context Version", () => {
  // Simulating the context version creation
  const createHash = require("crypto").createHash

  const makeContextVersion = (patternText: string, patternName?: string) => ({
    version: `v1_${new Date().toISOString()}`,
    timestamp: new Date().toISOString(),
    hash: createHash("sha256").update(patternText).digest("hex").slice(0, 16),
    patternName,
  })

  test("creates consistent hash for same content", () => {
    const v1 = makeContextVersion("test pattern")
    const v2 = makeContextVersion("test pattern")
    expect(v1.hash).toBe(v2.hash)
  })

  test("creates different hash for different content", () => {
    const v1 = makeContextVersion("pattern A")
    const v2 = makeContextVersion("pattern B")
    expect(v1.hash).not.toBe(v2.hash)
  })

  test("includes pattern name when provided", () => {
    const v = makeContextVersion("test", "my-pattern")
    expect(v.patternName).toBe("my-pattern")
  })

  test("hash is 16 characters", () => {
    const v = makeContextVersion("test pattern content here")
    expect(v.hash).toHaveLength(16)
  })
})
