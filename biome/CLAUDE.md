---
scope: biome/
updated: 2025-12-21
relates_to:
  - ../CLAUDE.md
  - ../modules/home-manager/programs/biome.nix
  - ../tsconfig/CLAUDE.md
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with Biome configuration in this directory.

## Architecture Overview

This directory contains **enterprise-grade Biome linting configuration** with 80+ strict rules and custom GritQL patterns for large TypeScript monorepos.

## File Structure

```
biome/
+-- biome-base.json                                   # Core configuration (80+ strict rules)
+-- gritql-patterns/                                  # Custom lint patterns using GritQL (14 patterns)
|   +-- ban-type-assertions.grit                      # Ban as Type, <Type>, satisfies (consolidated 3→1)
|   +-- ban-imperative-error-handling-in-effect.grit  # Ban Promise/throw/try-catch in Effect (consolidated 3→1)
|   +-- detect-missing-yield-star.grit                # CRITICAL: Effect.gen yield* detection
|   +-- detect-unhandled-effect-promise.grit          # Typed errors in Effect.tryPromise
|   +-- enforce-effect-pipe.grit                      # Prevent deep Effect nesting
|   +-- ban-ts-ignore.grit                            # Ban @ts-ignore/@ts-expect-error/@ts-nocheck
|   +-- ban-return-types.grit                         # Enforce return type inference
|   +-- ban-relative-parent-imports.grit              # Enforce absolute imports
|   +-- ban-push-spread.grit                          # Performance: avoid push(...spread)
|   +-- prefer-object-spread.grit                     # Prefer spread over Object.assign
|   +-- ban-default-export-non-index.grit             # Default exports only in index
|   +-- enforce-nx-project-tags.grit                  # Require Nx project tags
|   +-- enforce-esm-package-type.grit                 # Require type: module
|   +-- enforce-strict-tsconfig.grit                  # Require strict: true
+-- nx-plugin-template/                               # Template for Nx plugin scaffolding
```

## Philosophy: Direct Equality

This configuration follows the **Direct Equality** linting philosophy:

1. **Prefer `use*` rules over `no*` rules** - Tell what TO do, not what NOT to do
2. **Error severity for anti-patterns** - Fail fast, not warnings that get ignored
3. **GritQL for custom patterns** - Beyond what built-in rules can express

## biome-base.json Configuration

### Key Sections

#### Formatter Settings
```json
{
  "formatter": {
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100,
    "lineEnding": "lf"
  }
}
```

#### JavaScript/TypeScript Settings
```json
{
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "jsxQuoteStyle": "double",
      "semicolons": "always",
      "trailingCommas": "all"
    }
  }
}
```

### Rule Categories

#### Correctness (Catch Bugs)
| Rule | Level | Purpose |
|------|-------|---------|
| `noUnusedImports` | error | Remove dead imports |
| `noUnusedVariables` | error | Remove dead code |
| `noUnusedPrivateClassMembers` | error | Remove unused private members |

#### Style (Consistency)
| Rule | Level | Purpose |
|------|-------|---------|
| `noCommonJs` | error | Enforce ESM only |
| `noNamespace` | error | Use ES modules instead |
| `useImportType` | error | `import type` for type-only |
| `useExportType` | error | `export type` for type-only |
| `useNodejsImportProtocol` | error | `node:fs` not `fs` |
| `noNonNullAssertion` | error | Avoid `!` operator |
| `useConsistentArrayType` | error | Use `T[]` not `Array<T>` |
| `useAsConstAssertion` | error | Use `as const` |
| `useEnumInitializers` | error | Explicit enum values |
| `noDefaultExport` | warn | Prefer named exports |

#### Suspicious (Potential Bugs)
| Rule | Level | Purpose |
|------|-------|---------|
| `noExplicitAny` | error | No `any` type |
| `noConfusingVoidType` | error | Proper void usage |
| `noConstEnum` | error | Regular enums only |
| `noExtraNonNullAssertion` | error | No `!!` patterns |
| `noUnsafeDeclarationMerging` | error | Prevent interface/class merge |
| `useAwait` | error | Async functions must await |

#### Complexity (Maintainability)
| Rule | Level | Purpose |
|------|-------|---------|
| `noExcessiveCognitiveComplexity` | error (15) | Keep functions simple |
| `noUselessTypeConstraint` | error | Remove `extends any` |
| `noStaticOnlyClass` | error | Use modules instead |
| `useOptionalChain` | error | `?.` over `&&` chains |

#### Performance (Speed)
| Rule | Level | Purpose |
|------|-------|---------|
| `noAccumulatingSpread` | error | Avoid spread in loops |
| `noBarrelFile` | error | No barrel exports |
| `noReExportAll` | error | No `export * from` |

### Overrides

Test files allow `any`:
```json
{
  "includes": ["**/*.test.ts", "**/*.spec.ts"],
  "linter": {
    "rules": {
      "suspicious": { "noExplicitAny": "off" }
    }
  }
}
```

Index files allow default exports and barrels:
```json
{
  "includes": ["**/index.ts", "**/index.tsx"],
  "linter": {
    "rules": {
      "style": { "noDefaultExport": "off" },
      "performance": { "noBarrelFile": "off" }
    }
  }
}
```

Config files allow default exports:
```json
{
  "includes": ["**/*.config.ts", "**/*.config.js"],
  "linter": {
    "rules": {
      "style": { "noDefaultExport": "off" }
    }
  }
}
```

## GritQL Custom Patterns

### Critical: Effect.gen yield* Detection

**File:** `detect-missing-yield-star.grit`

This pattern catches a **critical bug** in Effect-TS code:

```typescript
// BUG: Missing yield* causes silent failures!
Effect.gen(function* () {
  const result = Effect.succeed(42)  // ERROR: Should be yield*
  return result
})

// CORRECT
Effect.gen(function* () {
  const result = yield* Effect.succeed(42)
  return result
})
```

Without `yield*`, the Effect is never executed, causing hard-to-debug issues.

### Anti-Pattern: satisfies Keyword

**File:** `ban-satisfies.grit`

The `satisfies` keyword is an anti-pattern that bypasses proper type inference:

```typescript
// WRONG: satisfies allows type widening
const config = { port: 3000 } satisfies Config;

// CORRECT: const assertion for literal types
const config = { port: 3000 } as const;
// Or: properly typed variable
const config: Config = { port: 3000 };
```

### Anti-Pattern: as any Assertions

**File:** `ban-any-type-annotation.grit` (merged into `ban-type-assertions.grit`)

Catches `as any` type assertions that defeat type safety:

```typescript
// WRONG
const result = someValue as any;

// CORRECT
const result: ProperType = someValue;
// Or use unknown + type guard
const result = someValue as unknown;
if (isProperType(result)) { ... }
```

## GritQL Pattern Organization

Patterns are organized by concern for discoverability and maintainability:

### Type Safety (1 consolidated file)
- `ban-type-assertions.grit` - Bans `as Type`, `<Type>`, and `satisfies` operators
  - Consolidated from 3 separate patterns (ban-any-type-annotation, ban-type-assertions, ban-satisfies)
  - All enforce: Use Schema.decodeUnknown() or type guards instead

### Effect Error Handling (2 consolidated file + 2 detection patterns)
- `ban-imperative-error-handling-in-effect.grit` - Bans Promise/throw/try-catch in Effect contexts
  - Consolidated from 3 separate patterns (ban-raw-promise, ban-throw, ban-try-catch)
  - All enforce: Use Effect's typed error handling API instead
- `detect-missing-yield-star.grit` - **CRITICAL** detection of missing yield* in Effect.gen
- `detect-unhandled-effect-promise.grit` - Ensures typed errors in Effect.tryPromise
- `enforce-effect-pipe.grit` - Code style: prevent deep Effect nesting

### Code Style (5 patterns)
- `ban-return-types.grit` - Enforce return type inference
- `ban-relative-parent-imports.grit` - Enforce absolute imports
- `ban-default-export-non-index.grit` - Default exports only in index files
- `ban-push-spread.grit` - Performance: avoid push(...spread)
- `prefer-object-spread.grit` - Prefer spread over Object.assign

### Type Suppression (1 pattern)
- `ban-ts-ignore.grit` - Bans @ts-ignore, @ts-expect-error, @ts-nocheck comments

### Configuration Enforcement (3 patterns)
- `enforce-nx-project-tags.grit` - Require Nx project tags in project.json
- `enforce-esm-package-type.grit` - Require type: module in package.json
- `enforce-strict-tsconfig.grit` - Require strict: true in tsconfig.json

## Pattern Refactoring History

### December 2025: Consolidation of Overlapping Patterns
- **Type Assertions**: Consolidated 3 separate patterns into 1 comprehensive pattern
  - `ban-any-type-annotation.grit` (was separate)
  - `ban-satisfies.grit` (was separate)
  - `ban-type-assertions.grit` (enhanced with satisfies)
  - **Rationale**: Pattern `$expr as $type` already catches `as any`, and `satisfies` is a related type narrowing concern
  - **Result**: Single source of truth for type assertion policies with comprehensive documentation

- **Effect Error Handling**: Consolidated 3 patterns into 1 comprehensive pattern
  - `ban-raw-promise-in-effect.grit` (was separate)
  - `ban-throw-in-effect.grit` (was separate)
  - `ban-try-catch-in-effect.grit` (was separate)
  - **Rationale**: All three enforce the same principle: "Use Effect's typed error handling, not imperative patterns"
  - **Result**: Single reference for "Effect error handling anti-patterns"

- **Documentation Standardization**: All 18 patterns enhanced with comprehensive headers, rationale, examples
- **Severity Normalization**: Fixed inconsistent severity values ("warning" → "warn")
- **File Count**: 18 → 14 files (22% reduction, -6 files + 2 consolidated = -4 net)

### Performance Metrics
- **Lines of documentation added**: ~500 lines
- **Patterns consolidated**: 6 files → 2 files
- **Documentation coverage**: 100% (all files have standardized header template)
- **Severity consistency**: 100% ("error" or "warn" only, no "warning")

### Performance: Spread in Push

**File:** `ban-push-spread.grit`

Catches O(n²) performance issues:

```typescript
// WRONG: O(n²) when in loop
array.push(...otherArray);

// CORRECT
array.push.apply(array, otherArray);
// Or
for (const item of otherArray) {
  array.push(item);
}
```

### Effect-TS: Pipe Composition

**File:** `enforce-effect-pipe.grit`

Detects 3+ level deep nesting that should use pipe:

```typescript
// WRONG: Hard to read
Effect.flatMap(Effect.map(Effect.succeed(1), x => x + 1), x => Effect.succeed(x * 2))

// CORRECT: Use pipe
pipe(
  Effect.succeed(1),
  Effect.map(x => x + 1),
  Effect.flatMap(x => Effect.succeed(x * 2))
)
```

## Home Manager Integration

**Module:** `modules/home-manager/programs/biome.nix`

The Home Manager module:
1. Installs Biome package
2. Symlinks `biome-base.json` to `~/.config/biome/biome-base.json`
3. Symlinks `gritql-patterns/` directory
4. Provides configurable rule overrides

### Usage in Projects

Reference the base config in your project:

```json
{
  "$schema": "https://biomejs.dev/schemas/2.3.8/schema.json",
  "extends": ["~/.config/biome/biome-base.json"],
  "files": {
    "include": ["./src/**/*.ts", "./src/**/*.tsx"]
  }
}
```

## Commands

### Check All Files
```bash
biome check .
```

### Auto-fix Issues
```bash
biome check --write .
```

### Format Only
```bash
biome format --write .
```

### Lint Only
```bash
biome lint .
```

### With Specific Config
```bash
biome check --config-path ./biome.json .
```

## Adding New Rules

### Adding Built-in Rule

1. Find rule in [Biome Rules Reference](https://biomejs.dev/linter/rules/)
2. Add to appropriate category in `biome-base.json`:
   ```json
   {
     "linter": {
       "rules": {
         "category": {
           "newRuleName": "error"
         }
       }
     }
   }
   ```
3. Test: `biome check .`
4. Update this documentation

### Adding GritQL Pattern

1. Create new file in `gritql-patterns/`:
   ```grit
   language js

   `pattern_to_match` where {
     register_diagnostic(
       span = $_,
       message = "Explanation of the issue",
       severity = "error"
     )
   }
   ```

2. Test pattern:
   ```bash
   biome check --gritql-patterns ./gritql-patterns .
   ```

3. Update pattern table in this document

### Pattern Syntax Guide

GritQL patterns match AST nodes:

```grit
// Match function calls
`Effect.$method($args)`

// Match nested patterns
`Effect.$m1(Effect.$m2($inner))`

// Match specific structures
`const $name = Effect.$method($args)`

// With conditions
`$pattern` where {
  $name <: "specificName"
}
```

## Type Safety Guardrails for AI Assistants ⚠️

This section defines hard-blocked type safety patterns that AI assistants must never implement. These patterns are enforced at three levels: documentation (proactive), Biome rules (reactive), and pre-commit hooks (blocking).

### Prohibited Pattern 1: `value as any` Type Assertions

**Why prohibited:** Defeats ALL type checking for the value, making the type system useless.

**Enforcement:**
- **Biome rule**: `noExplicitAny: "error"` - Automatically blocks in linter
- **GritQL pattern**: `ban-any-type-annotation.grit` - Custom AST-based detection
- **Pre-commit hook**: Validates no new `as any` patterns introduced

**Type-safe alternative:**
```typescript
// WRONG ❌
const result = someValue as any;
const parsed = JSON.parse(json) as any;

// CORRECT ✅
// Option 1: Use Schema.decodeUnknown (Effect-TS)
import { Schema } from "effect";
const parsed = Schema.decodeUnknownSync(MySchema)(json);

// Option 2: Proper type annotation
const result: ExpectedType = someValue;

// Option 3: Use unknown + type guard
const result = someValue as unknown;
if (typeof result === 'object' && result !== null && 'prop' in result) {
  // Now result is properly narrowed
}
```

**Decision tree for `any` requests:**
```
Request involves "any" type?
├─ "Just use as any to get it working" → REFUSE
├─ "This value could be anything" → SUGGEST: Use Schema.decodeUnknown()
├─ "The types don't match" → SUGGEST: Refactor types or add proper guards
└─ "Just for now/testing" → REFUSE: Use unknown + type guard instead
```

### Prohibited Pattern 2: TypeScript Suppression Comments

**Why prohibited:** Suppresses type errors without fixing the root cause. Creates silent bugs.

**Patterns blocked:**
- `@ts-ignore` - Suppresses next line error
- `@ts-expect-error` - Acknowledges error exists but ignores it
- `@ts-nocheck` - Disables all type checking for entire file

**Enforcement:**
- **GritQL pattern**: `ban-ts-ignore.grit` - Detects all suppression comment variants
- **Pre-commit hook**: Blocks commits with new suppression comments

**Type-safe alternative:**
```typescript
// WRONG ❌
// @ts-ignore
const x = functionWithWrongReturn();

// @ts-expect-error
const y = incompatibleValue as OtherType;

// @ts-nocheck
// Entire file disabled

// CORRECT ✅
// Fix the underlying issue
import { Schema } from "effect";

// Option 1: Add proper types
function functionWithWrongReturn(): ExpectedType {
  // Implementation that actually returns the right type
}

// Option 2: Use Schema for unknown data
const validated = Schema.decodeUnknownSync(MySchema)(unknownValue);

// Option 3: Use type guards
if (isExpectedType(value)) {
  // value is now properly typed
  const x = value;
}
```

**Decision tree for suppression comment requests:**
```
Request involves @ts-ignore or similar?
├─ "The types are wrong" → SUGGEST: Correct the type definition
├─ "Add @ts-ignore to this line" → REFUSE: Fix the underlying type error
├─ "This is temporary" → REFUSE: Use proper types from the start
└─ "The library has bad types" → SUGGEST: Add proper .d.ts or use Schema validation
```

### Prohibited Pattern 3: Non-null Assertions (`!`)

**Why prohibited:** Asserts null/undefined won't happen without runtime verification, causing crashes.

**Enforcement:**
- **Biome rule**: `noNonNullAssertion: "error"` - Blocks non-null assertions
- **Pre-commit hook**: Validates no new `!` assertions introduced

**Type-safe alternative:**
```typescript
// WRONG ❌
const value = maybeValue!;  // Asserts it's not null
const prop = obj.prop!;      // Asserts prop exists

// CORRECT ✅
// Option 1: Optional chaining
const value = maybeValue?.toString();
const prop = obj.prop?.subprop;

// Option 2: Null checking
if (maybeValue !== null) {
  const value = maybeValue;  // value is now non-null
}

// Option 3: Nullish coalescing
const value = maybeValue ?? defaultValue;

// Option 4: Type guards
if (obj.prop) {
  const prop = obj.prop;  // prop is now non-null
}

// Option 5: Schema validation
const validated = Schema.decodeUnknownSync(MySchema)(obj);
// Now validated.prop is guaranteed non-null per schema
```

**Decision tree for non-null assertion requests:**
```
Request involves ! operator or non-null assertion?
├─ "Value might be null" → SUGGEST: Add optional chaining (?.) or null check
├─ "Use ! to assert it's safe" → REFUSE: Add runtime check instead
├─ "For performance, skip the check" → REFUSE: Correctness > performance
└─ "The type system can't tell it's safe" → SUGGEST: Add type guard or Schema
```

### Prohibited Pattern 4: `satisfies` Operator

**Why prohibited:** Allows type widening without explicit type assignment. Anti-pattern that reduces type safety.

**Enforcement:**
- **GritQL pattern**: `ban-satisfies.grit` - Detects satisfies operator usage
- **Pre-commit hook**: Blocks commits introducing satisfies

**Type-safe alternative:**
```typescript
// WRONG ❌
const config = { port: 3000 } satisfies Config;
const response = apiCall() satisfies ApiResponse;

// CORRECT ✅
// Option 1: const assertion for literal types
const config = { port: 3000 } as const;
// Now config.port is type 3000, not number

// Option 2: Explicit type annotation
const config: Config = { port: 3000 };
// Errors caught at assignment time, not later

// Option 3: Schema-based validation
const config = Schema.decodeUnknownSync(ConfigSchema)({ port: 3000 });
// Both type checking AND runtime validation
```

**Decision tree for satisfies requests:**
```
Request involves satisfies operator?
├─ "Need to preserve literal types" → SUGGEST: Use as const instead
├─ "Want type checking without assignment" → SUGGEST: Use explicit : Type
├─ "Want both type safety and validation" → SUGGEST: Use Schema.decodeUnknown
└─ "Just use satisfies" → REFUSE: Use as const or explicit type annotation
```

### Linting Rule Modification Guidelines

**Adding stricter rules:** ALLOWED
```
"newRule": "error"  // Adding new constraints is good
```
This improves code quality and is encouraged.

**Modifying rule configuration (same severity):** SOFT WARNING
```
Before: "rule": { "level": "error", "options": {...} }
After:  "rule": { "level": "error", "options": {...different...} }
```
Show warning template, request "APPROVE [description]" confirmation.

**Weakening rule severity:** HARD ERROR (BLOCKED BY PRE-COMMIT)
```
Before: "rule": "error"
After:  "rule": "warn"  // ❌ BLOCKED by validate-linting-config.sh
```
Cannot be bypassed except with `git commit --no-verify` (requires developer attention).

**Disabling rules:** HARD ERROR (BLOCKED BY PRE-COMMIT)
```
Before: "rule": "error"
After:  "rule": "off"  // ❌ BLOCKED by validate-linting-config.sh
```
Same as weakening - requires explicit developer override.

### For AI Assistants: Quick Reference

**When the user asks for type workarounds:**
1. Identify the type safety pattern being requested
2. Check the decision tree for that pattern above
3. **REFUSE the request** - suggest type-safe alternative instead
4. Provide at least one working example of the proper approach
5. Explain why the workaround is harmful

**When modifying linting configs:**
1. Check if you're changing rule severity or disabling rules
2. If yes: Show SOFT WARNING with required approval template
3. If rule weakening: PRE-COMMIT will block it automatically
4. If adding stricter rules: Go ahead, this improves quality

**When in doubt:**
- Consult the decision trees above
- Reference `docs/LINTING_POLICY.md` for full policy
- Ask the human for explicit approval
- Never assume "just this once" is acceptable

## Troubleshooting

### Rule Not Triggering

1. Check rule is enabled: `biome explain ruleName`
2. Check file is included (not in `ignore`)
3. Check override isn't disabling it
4. Verify syntax matches rule requirements

### GritQL Pattern Not Working

1. Test pattern in isolation
2. Check language declaration: `language js`
3. Verify AST structure matches pattern
4. Use `biome check --verbose` for details

### Performance Issues

1. Add files to `ignore` in config
2. Exclude `node_modules`, `dist`, etc.
3. Use `files.include` for specific paths
4. Consider splitting large monorepo checks

## Resources

- [Biome Documentation](https://biomejs.dev/)
- [Biome Rules Reference](https://biomejs.dev/linter/rules/)
- [GritQL Language](https://docs.grit.io/language/overview)
- [Effect-TS Documentation](https://effect.website/)

## For Future Claude Code Instances

When modifying Biome configuration:

- [ ] **Test rule changes** with: `biome check .`
- [ ] **Verify GritQL patterns** work on sample code before committing
- [ ] **Update rule tables** in this document when adding rules to biome-base.json
- [ ] **Add override sections** for files that legitimately need exceptions
- [ ] **Document pattern rationale** in comments within .grit files
- [ ] **Check Home Manager module** at `modules/home-manager/programs/biome.nix` for integration
- [ ] **Validate effect patterns** - detect-missing-yield-star.grit is critical for Effect-TS
- [ ] **Run biome check --write** to auto-fix before committing
- [ ] **Keep tsconfig/ aligned** - strict linting works best with strict TypeScript
