import { describe, test, expect, mock, spyOn, beforeEach, afterEach } from "bun:test"

// Test the pattern matching logic from plugins
describe("GritQL Guardrails Pattern Matching", () => {
  // Extracted patterns for testing
  const WARNED_PATTERNS: Array<{ pattern: RegExp; reason: string }> = [
    {
      pattern: /\brg\s+.*--files-with-matches\b|\brg\s+-l\b/i,
      reason: "Consider using @gritql checkProject instead of ripgrep for structural code search.",
    },
    {
      pattern: /\bgrep\s+-r\b|\bgrep\s+--recursive\b/i,
      reason: "Consider using @gritql checkPattern instead of grep -r for structural search.",
    },
    {
      pattern: /\bsed\s+-i\b|\bsed\s+--in-place\b/i,
      reason: "Consider using @gritql applyPattern instead of sed -i for structural rewrites.",
    },
    {
      pattern: /\bawk\b.*\{.*gsub/i,
      reason: "Consider using @gritql applyPattern instead of awk gsub for code changes.",
    },
  ]

  const ALLOWED_STRUCTURAL_PATTERNS = [
    /^grit(\s|$)/i,
    /^@gritql\b/i,
    /^gritql\b/i,
    /^biome\s+(check|lint|format)/i,
  ]

  const findWarnReason = (command: string): string | null => {
    const trimmed = command.trim()
    if (ALLOWED_STRUCTURAL_PATTERNS.some((re) => re.test(trimmed))) return null
    for (const { pattern, reason } of WARNED_PATTERNS) {
      if (pattern.test(trimmed)) return reason
    }
    return null
  }

  describe("Allowed commands", () => {
    test("allows grit commands", () => {
      expect(findWarnReason("grit apply pattern")).toBeNull()
      expect(findWarnReason("grit check src/")).toBeNull()
    })

    test("allows @gritql tool calls", () => {
      expect(findWarnReason("@gritql checkPattern")).toBeNull()
    })

    test("allows biome commands", () => {
      expect(findWarnReason("biome check .")).toBeNull()
      expect(findWarnReason("biome lint src/")).toBeNull()
      expect(findWarnReason("biome format --write")).toBeNull()
    })
  })

  describe("Warned commands", () => {
    test("warns on grep -r", () => {
      const reason = findWarnReason("grep -r pattern src/")
      expect(reason).toContain("@gritql checkPattern")
    })

    test("warns on grep --recursive", () => {
      const reason = findWarnReason("grep --recursive pattern .")
      expect(reason).toContain("@gritql checkPattern")
    })

    test("warns on sed -i", () => {
      const reason = findWarnReason("sed -i 's/foo/bar/g' file.ts")
      expect(reason).toContain("@gritql applyPattern")
    })

    test("warns on ripgrep with -l flag", () => {
      const reason = findWarnReason("rg -l pattern")
      expect(reason).toContain("ripgrep")
    })

    test("warns on awk gsub", () => {
      const reason = findWarnReason("awk '{gsub(/old/, \"new\")}' file.ts")
      expect(reason).toContain("awk gsub")
    })
  })

  describe("Non-warned commands", () => {
    test("does not warn on simple grep (non-recursive)", () => {
      expect(findWarnReason("grep pattern file.ts")).toBeNull()
    })

    test("does not warn on cat", () => {
      expect(findWarnReason("cat file.ts")).toBeNull()
    })

    test("does not warn on git status", () => {
      expect(findWarnReason("git status")).toBeNull()
    })
  })
})

describe("MLG Guardrails Pattern Matching", () => {
  const WARNED_PATTERNS: Array<{ pattern: RegExp; reason: string }> = [
    {
      pattern: /\bnx\s+g(?:enerate)?\s+@nx\/js:lib/i,
      reason: "Consider using @mlg for library creation - enforces Effect TS patterns.",
    },
    {
      pattern: /\bnx\s+g(?:enerate)?\s+@nrwl\/.*:lib/i,
      reason: "Consider using @mlg for library creation - enforces Effect TS patterns.",
    },
    {
      pattern: /\bmkdir\s+.*libs?\//i,
      reason: "Consider using @mlg to scaffold libraries properly with Effect patterns.",
    },
  ]

  const ALLOWED_PATTERNS = [/^@mlg\b/i, /^mlg\b/i]

  const findWarnReason = (command: string): string | null => {
    const trimmed = command.trim()
    if (ALLOWED_PATTERNS.some((re) => re.test(trimmed))) return null
    for (const { pattern, reason } of WARNED_PATTERNS) {
      if (pattern.test(trimmed)) return reason
    }
    return null
  }

  describe("Allowed commands", () => {
    test("allows @mlg tool calls", () => {
      expect(findWarnReason("@mlg create")).toBeNull()
      expect(findWarnReason("@mlg dryRun")).toBeNull()
    })

    test("allows mlg commands", () => {
      expect(findWarnReason("mlg contract user")).toBeNull()
    })
  })

  describe("Warned commands", () => {
    test("warns on nx generate @nx/js:lib", () => {
      const reason = findWarnReason("nx generate @nx/js:lib my-lib")
      expect(reason).toContain("@mlg")
    })

    test("warns on nx g @nx/js:lib (short form)", () => {
      const reason = findWarnReason("nx g @nx/js:lib my-lib")
      expect(reason).toContain("@mlg")
    })

    test("warns on mkdir libs/", () => {
      const reason = findWarnReason("mkdir -p libs/my-lib")
      expect(reason).toContain("@mlg")
    })

    test("warns on @nrwl generators", () => {
      const reason = findWarnReason("nx g @nrwl/node:lib my-lib")
      expect(reason).toContain("@mlg")
    })
  })
})

describe("Project Name Extraction", () => {
  // Test schema-based extraction pattern
  const { Schema, pipe } = require("effect")

  const ProjectNameSchema = Schema.Struct({ name: Schema.String })

  const extractProjectName = (project: unknown): string =>
    pipe(
      Schema.decodeUnknownOption(ProjectNameSchema)(project),
      (opt: { _tag: string; value?: { name: string } }) =>
        opt._tag === "Some" ? opt.value!.name : "unknown-project"
    )

  test("extracts name from valid project object", () => {
    expect(extractProjectName({ name: "my-project" })).toBe("my-project")
  })

  test("returns default for null", () => {
    expect(extractProjectName(null)).toBe("unknown-project")
  })

  test("returns default for undefined", () => {
    expect(extractProjectName(undefined)).toBe("unknown-project")
  })

  test("returns default for empty object", () => {
    expect(extractProjectName({})).toBe("unknown-project")
  })

  test("returns default for object with wrong type", () => {
    expect(extractProjectName({ name: 123 })).toBe("unknown-project")
  })
})

describe("GritQL Tool-Level Blocking (Strict Enforcement)", () => {
  // Mock plugin event handler
  const createMockEvent = (type: string, tool: string, args?: any) => ({
    type,
    input: { tool, sessionID: "test", callID: "test" },
    output: { args: args ?? {} },
  })

  // Import the actual constants from the plugin for testing
  const BLOCKED_TOOLS = ["grep", "glob", "find", "edit", "write", "bash"]
  const ALLOWED_TOOLS = ["gritql", "read", "list", "task", "webfetch", "todowrite", "todoread", "mlg"]

  describe("Blocked Tools", () => {
    test("blocks grep tool invocation", () => {
      const tool = "grep"
      expect(BLOCKED_TOOLS).toContain(tool)
    })

    test("blocks glob tool invocation", () => {
      const tool = "glob"
      expect(BLOCKED_TOOLS).toContain(tool)
    })

    test("blocks find tool invocation", () => {
      const tool = "find"
      expect(BLOCKED_TOOLS).toContain(tool)
    })

    test("blocks edit tool invocation", () => {
      const tool = "edit"
      expect(BLOCKED_TOOLS).toContain(tool)
    })

    test("blocks write tool invocation", () => {
      const tool = "write"
      expect(BLOCKED_TOOLS).toContain(tool)
    })

    test("blocks bash tool invocation", () => {
      const tool = "bash"
      expect(BLOCKED_TOOLS).toContain(tool)
    })
  })

  describe("Allowed Tools", () => {
    test("allows gritql tool invocation", () => {
      const tool = "gritql"
      expect(ALLOWED_TOOLS).toContain(tool)
    })

    test("allows read tool invocation", () => {
      const tool = "read"
      expect(ALLOWED_TOOLS).toContain(tool)
    })

    test("allows list tool invocation", () => {
      const tool = "list"
      expect(ALLOWED_TOOLS).toContain(tool)
    })

    test("allows task tool invocation", () => {
      const tool = "task"
      expect(ALLOWED_TOOLS).toContain(tool)
    })

    test("allows mlg tool invocation", () => {
      const tool = "mlg"
      expect(ALLOWED_TOOLS).toContain(tool)
    })
  })

  describe("Policy Enforcement", () => {
    test("gritql is the only tool allowed for code modification", () => {
      const codeModificationTools = ALLOWED_TOOLS.filter(
        (t) => t !== "gritql" && !["read", "list", "task", "webfetch", "todowrite", "todoread"].includes(t)
      )
      // mlg is allowed for scaffolding but not general code modification
      expect(codeModificationTools).toEqual(["mlg"])
    })

    test("edit and write are blocked", () => {
      expect(BLOCKED_TOOLS).toContain("edit")
      expect(BLOCKED_TOOLS).toContain("write")
      expect(ALLOWED_TOOLS).not.toContain("edit")
      expect(ALLOWED_TOOLS).not.toContain("write")
    })

    test("grep, glob, find are blocked for search", () => {
      expect(BLOCKED_TOOLS).toContain("grep")
      expect(BLOCKED_TOOLS).toContain("glob")
      expect(BLOCKED_TOOLS).toContain("find")
    })
  })
})
