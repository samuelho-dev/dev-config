# CLAUDE.md - OpenCode Shared Libraries

```yaml
scope: .opencode/lib/
updated: 2025-12-21
relates_to:
  - .opencode/tool/gritql.ts
  - .opencode/tool/mlg.ts
  - .opencode/test/schemas.test.ts
  - biome/biome-base.json
```

## Purpose

This directory contains **shared Effect-TS schemas and utilities** used across OpenCode tools and plugins. Provides type-safe, reusable building blocks for the strict policy enforcement system.

**Key responsibility**: Centralize schema definitions and helper functions to ensure consistency between `gritql.ts` and `mlg.ts` tools.

---

## Architecture Overview

```
lib/
+-- shared-schemas.ts    # Effect Schema definitions + tagged errors + helpers
```

The library follows Effect-TS patterns:
- **Schema.Struct** for structured data validation
- **Schema.Literal** for union types (policy modes, severities, error codes)
- **Data.TaggedError** for typed error handling
- Helper functions for run IDs, timestamps, and violations

---

## File Reference

### shared-schemas.ts

**Purpose**: Reusable Effect schemas for OpenCode tool ecosystem.

| Export | Type | Description |
|--------|------|-------------|
| `PolicyModeSchema` | Schema.Literal | "strict", "standard", "off" |
| `SeveritySchema` | Schema.Literal | "info", "warn", "error" |
| `ErrorCodeSchema` | Schema.Literal | POLICY_VIOLATION, CONTEXT_STALE, etc. |
| `RetryStrategySchema` | Schema.Literal | fix_args, run_prerequisite, escalate, backoff |
| `ViolationSchema` | Schema.Struct | code, severity, message, remediation |
| `RecommendationSchema` | Schema.Struct | action, priority, confidence |
| `ContextVersionSchema` | Schema.Struct | version, timestamp, hash |
| `LibraryTypeSchema` | Schema.Literal | contract, data-access, feature, infra, provider |
| `EffectLayerSchema` | Schema.Literal | Domain, Service, Orchestration, Infrastructure, Integration |
| `PlatformSchema` | Schema.Literal | node, universal, edge |

**Tagged Errors**:

| Error Class | Tag | Fields |
|-------------|-----|--------|
| `ToolNotFoundError` | "ToolNotFoundError" | tool, message, recommendations |
| `ResourceNotFoundError` | "ResourceNotFoundError" | resource, message, recommendations |
| `ExecutionError` | "ExecutionError" | stage, message, output |
| `ContextStaleError` | "ContextStaleError" | resource, expectedVersion, actualVersion, message |

**Helper Functions**:

| Function | Purpose |
|----------|---------|
| `nowIso()` | Current timestamp in ISO format |
| `makeRunId(prefix)` | Generate unique run ID with prefix + timestamp + random |
| `makeContextVersion(source)` | Create version object with hash for staleness detection |
| `policyViolation(code, message, remediation?)` | Create Violation with "error" severity |

---

## Key Patterns

### 1. Schema-Based Extraction (Safe Unknown Parsing)

```typescript
import { Schema, pipe } from "effect"

const ArgsCommandSchema = Schema.Struct({ command: Schema.String })

const extractCommand = (args: unknown) =>
  pipe(
    Schema.decodeUnknownOption(ArgsCommandSchema)(args),
    (opt) => (opt._tag === "Some" ? opt.value.command : "defaultValue")
  )
```

**Why**: Safely extract values from unknown input without throwing. Returns default if validation fails.

### 2. Library Type to Effect Layer Mapping

```typescript
const LIBRARY_TYPE_TO_LAYER: Record<LibraryType, EffectLayer> = {
  contract: "Domain",
  "data-access": "Service",
  feature: "Orchestration",
  infra: "Infrastructure",
  provider: "Integration",
}
```

**Why**: Enforces architectural boundaries based on library classification.

### 3. Context Version for Staleness Detection

```typescript
const ctx = makeContextVersion("pattern content")
// { version: "v1_2025-...", timestamp: "2025-...", hash: "abc123..." }
```

**Why**: Tracks content hash to detect when cached results are stale.

---

## Adding New Schemas

### Step 1: Define the Schema

```typescript
export const NewFeatureSchema = Schema.Literal("option1", "option2", "option3")
export type NewFeature = Schema.Schema.Type<typeof NewFeatureSchema>
```

### Step 2: Export from shared-schemas.ts

Add to the appropriate section (Policy, Violations, Library Types, etc.).

### Step 3: Add Tests

```typescript
// test/schemas.test.ts
describe("NewFeatureSchema", () => {
  test("accepts valid values", () => {
    expect(Schema.decodeUnknownSync(NewFeatureSchema)("option1")).toBe("option1")
  })

  test("rejects invalid values", () => {
    expect(() => Schema.decodeUnknownSync(NewFeatureSchema)("invalid")).toThrow()
  })
})
```

### Step 4: Use in Tools

```typescript
import { NewFeatureSchema } from "../lib/shared-schemas"

const ArgsSchema = Schema.Struct({
  feature: Schema.optional(NewFeatureSchema),
})
```

---

## Adding New Tagged Errors

### Step 1: Define Error Class

```typescript
export class NewOperationError extends Data.TaggedError("NewOperationError")<{
  readonly operation: string
  readonly message: string
  readonly recommendations: readonly string[]
}> {}
```

### Step 2: Handle in Tool

```typescript
Effect.catchTags({
  NewOperationError: (e) =>
    Effect.succeed(
      new ToolFailure({
        _tag: "failure",
        error: e.message,
        recommendations: [...e.recommendations],
      })
    ),
})
```

---

## Testing

Run tests from `.opencode/` directory:

```bash
cd .opencode
bun test test/schemas.test.ts
```

Test coverage includes:
- Schema validation (valid/invalid inputs)
- Helper function behavior
- Hash consistency
- Default value extraction

---

## For Future Claude Code Instances

When working with this library:

- [ ] Check existing schemas before creating new ones
- [ ] Use `Schema.Schema.Type<typeof XSchema>` for type inference
- [ ] Prefer `Schema.decodeUnknownOption` over `Schema.decodeUnknown` for safe extraction
- [ ] Add tests for any new schemas or helpers
- [ ] Follow existing naming conventions (XSchema, XError, makeX)
- [ ] Keep schemas focused and composable
- [ ] Document any breaking changes in this file
