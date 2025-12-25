---
scope: .opencode/tool/
updated: 2025-12-24
relates_to:
  - ../lib/shared-schemas.ts
  - ../plugin/gritql-guardrails.ts
  - ../plugin/mlg-guardrails.ts
  - ../test/tools.test.ts
  - ../../biome/gritql-patterns/
  - ../../AGENTS.md
---

# CLAUDE.md - OpenCode Custom Tools

## Purpose

This directory contains **custom OpenCode tools** that provide structured, policy-enforced interfaces for code operations. These tools are the ONLY approved methods for code search, linting, refactoring, and library scaffolding.

**Key responsibility**: Enforce dry-run → review → apply workflow for safe AI-assisted code modifications.

---

## Architecture Overview

```
tool/
+-- gritql.ts    # Structural search, linting, and refactoring via GritQL
+-- mlg.ts       # Effect-TS library scaffolding in Nx monorepos
```

Both tools follow Effect-TS patterns:
- **Schema-based input validation** with `Schema.Struct`
- **Tagged errors** with `Data.TaggedError`
- **Effect.gen** for composable async operations
- **Typed responses** with `Schema.Class` (ToolSuccess/ToolFailure)

---

## Tool Reference

### gritql.ts (842 lines)

**Purpose**: STRICT pseudo-API for structural code search, linting, and refactoring using GritQL patterns.

**Commands**:

| Command | Purpose | Returns |
|---------|---------|---------|
| `listPatterns` | List available repo patterns | Pattern names |
| `checkPattern` | Dry-run structural search | Matches, diff, runId |
| `applyPattern` | Apply structural rewrite | Applied changes |
| `checkProject` | Run ruleset across target | Aggregated matches |
| `explainUsage` | Show help text | Usage documentation |

**Arguments**:

| Argument | Type | Description |
|----------|------|-------------|
| `command` | Literal | One of the commands above |
| `policy` | "strict" / "standard" / "off" | Enforcement level (default: strict) |
| `target` | string | File or directory (default: ".") |
| `patternName` | string | Repo pattern name (no .grit extension) |
| `pattern` | string | Inline GritQL (discouraged in strict) |
| `allowInline` | boolean | Allow inline under strict (default: false) |
| `runId` | string | Required for applyPattern in strict |
| `confirm` | boolean | Required for applyPattern in strict |
| `patternNames` | string[] | Patterns for checkProject |
| `includeDiff` | boolean | Include unified diff (default: true) |

**Strict Policy Enforcement**:
1. `patternName` preferred over inline `pattern`
2. `applyPattern` requires `confirm=true`
3. `applyPattern` requires `runId` from prior `checkPattern`
4. Violations return structured error with remediation steps

**Default Ruleset** (for checkProject):
- detect-missing-yield-star
- ban-any-type-annotation
- ban-type-assertions
- ban-satisfies
- ban-relative-parent-imports
- prefer-object-spread
- ban-default-export-non-index
- ban-push-spread
- ban-return-types
- enforce-effect-pipe
- enforce-esm-package-type
- enforce-nx-project-tags
- enforce-strict-tsconfig

---

### mlg.ts (1008 lines)

**Purpose**: Scaffolds Effect-TS libraries in Nx monorepos with strict policy enforcement.

**Commands**:

| Command | Purpose | Returns |
|---------|---------|---------|
| `listTypes` | Show available library types | Type descriptions |
| `dryRun` | Preview library creation | Files to create, runId |
| `create` | Generate the library | Created files |
| `validateLayers` | Check Effect Layer patterns | Violations or pass |
| `explainUsage` | Show help text | Usage documentation |

**Arguments**:

| Argument | Type | Description |
|----------|------|-------------|
| `command` | Literal | One of the commands above |
| `libraryType` | Literal | contract, data-access, feature, infra, provider |
| `name` | string | Library name (e.g., "user", "payments") |
| `entities` | string[] | Entity names for contracts |
| `includeCQRS` | boolean | Generate CQRS commands/queries |
| `includeRPC` | boolean | Create RPC endpoint definitions |
| `platform` | "node" / "universal" / "edge" | Target runtime |
| `externalService` | string | SDK name for providers |
| `policy` | "strict" / "standard" / "off" | Enforcement level |
| `confirm` | boolean | Required for create in strict |
| `runId` | string | Required for create in strict |
| `targetLibrary` | string | Path for validateLayers |

**Library Type to Effect Layer Mapping**:

| Library Type | Effect Layer | Purpose |
|--------------|--------------|---------|
| contract | Domain | Boundaries and interfaces with Effect Schema |
| data-access | Service | Repository pattern with Kysely |
| feature | Orchestration | Business logic orchestration |
| infra | Infrastructure | Cross-cutting services (cache, logging) |
| provider | Integration | External SDK integrations |

---

## Key Patterns

### 1. Dry-Run → Review → Apply Workflow

```typescript
// Step 1: Preview (returns runId)
@gritql command=checkPattern patternName="ban-any-type-annotation" target="src/"

// Step 2: Review the diff output
// (User examines matches and unified diff)

// Step 3: Apply with confirmation
@gritql command=applyPattern patternName="ban-any-type-annotation" target="src/" runId="gritql_check_..." confirm=true
```

**Why**: Prevents accidental code modifications. Forces review before changes.

### 2. Effect.gen for Composable Logic

```typescript
const executeGrit = (args: Args) =>
  Effect.gen(function* () {
    // Step 1: Validate policy
    const violations = enforcePolicy(args)
    if (violations.length > 0) {
      return new ToolFailure({ violations, error: "Policy violation" })
    }

    // Step 2: Ensure CLI available
    yield* ensureGritAvailable

    // Step 3: Read pattern
    const patternText = yield* readRepoPattern(args.patternName)

    // Step 4: Execute and parse
    const raw = yield* runGritApply({ patternText, target, dryRun: true })
    const matches = parseMatchesBestEffort(raw)

    return new ToolSuccess({ matches, runId, ... })
  })
```

**Why**: Clean separation of concerns, composable error handling, explicit effect tracking.

### 3. Tagged Union Responses

```typescript
class ToolSuccess extends Schema.Class<ToolSuccess>("ToolSuccess")({
  _tag: Schema.Literal("success"),
  command: Schema.String,
  // ... success fields
}) {}

class ToolFailure extends Schema.Class<ToolFailure>("ToolFailure")({
  _tag: Schema.Literal("failure"),
  error: Schema.String,
  violations: Schema.optional(Schema.Array(ViolationSchema)),
  // ... failure fields
}) {}
```

**Why**: Type-safe discrimination between success and failure. AI can parse structured responses.

### 4. Context Version for Staleness Detection

```typescript
const makeContextVersion = (patternText: string, patternName?: string) => ({
  version: `v1_${nowIso()}`,
  timestamp: nowIso(),
  hash: createHash("sha256").update(patternText).digest("hex").slice(0, 16),
  patternName,
})
```

**Why**: Detect if pattern content changed between check and apply.

---

## Adding a New Tool

### Step 1: Create Tool File

```typescript
// tool/new-tool.ts
import { tool } from "@opencode-ai/plugin"
import { Effect, Schema, Data, pipe } from "effect"

// Define schemas...
// Define tagged errors...
// Define response classes...

export default tool({
  description: "Tool description for AI context",
  args: {
    command: tool.schema.string().describe("...").default("default"),
    // ... more args
  },
  async execute(args) {
    const program = pipe(
      Schema.decodeUnknown(ArgsSchema)(args),
      Effect.flatMap(executeLogic),
      Effect.catchTags({ /* error handlers */ }),
    )

    const result = await Effect.runPromise(program)
    return JSON.stringify(result, null, 2)
  },
})
```

### Step 2: Add Tests

```typescript
// test/tools.test.ts
describe("New Tool Schema Extraction", () => {
  test("extracts valid command", () => {
    expect(extractCommand({ command: "action" })).toBe("action")
  })
})
```

### Step 3: Document in opencode.json

```json
{
  "instructions": [
    "Use @new-tool for specific operations..."
  ]
}
```

---

## Tool Invocation Examples

### GritQL: Find Console Logs

```bash
@gritql command=checkPattern pattern="`console.log($_)`" target="src/" allowInline=true
```

### GritQL: Apply Named Pattern

```bash
# Step 1: Check
@gritql command=checkPattern patternName="detect-missing-yield-star" target="."

# Step 2: Apply (with runId from step 1)
@gritql command=applyPattern patternName="detect-missing-yield-star" target="." runId="gritql_check_2025-..." confirm=true
```

### GritQL: Run Project Ruleset

```bash
@gritql command=checkProject target="libs/"
```

### MLG: Create Contract Library

```bash
# Step 1: Preview
@mlg command=dryRun libraryType="contract" name="user" entities=["User","Account"]

# Step 2: Create (with runId from step 1)
@mlg command=create libraryType="contract" name="user" entities=["User","Account"] runId="mlg_dryrun_2025-..." confirm=true
```

### MLG: Validate Library

```bash
@mlg command=validateLayers targetLibrary="libs/user-contract"
```

---

## Testing

Run tool tests from `.opencode/` directory:

```bash
cd .opencode
bun test test/tools.test.ts
```

Test coverage includes:
- Command extraction with defaults
- Policy extraction with defaults
- Library type detection
- Rules schema extraction
- Context version hashing

---

## For Future Claude Code Instances

When working with these tools:

- [ ] ALWAYS use dry-run first, then apply with confirm
- [ ] Prefer `patternName` over inline `pattern` for reproducibility
- [ ] Check `listPatterns` to discover available GritQL patterns
- [ ] Use `validateLayers` after creating libraries with MLG
- [ ] Run `biome check .` after GritQL modifications
- [ ] Parse structured JSON responses, not raw output
- [ ] Keep tools in sync with guardrail plugins
- [ ] Test schema changes with `bun test test/tools.test.ts`
