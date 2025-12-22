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
+-- biome-base.json           # Core configuration (80+ strict rules)
+-- gritql-patterns/          # Custom lint patterns using GritQL
|   +-- ban-any-type-annotation.grit     # Catches `as any` assertions
|   +-- ban-satisfies.grit               # Bans satisfies keyword (anti-pattern)
|   +-- ban-return-types.grit            # Enforces return type inference
|   +-- ban-type-assertions.grit         # Catches dangerous type assertions
|   +-- ban-push-spread.grit             # Performance: avoid push(...spread)
|   +-- prefer-object-spread.grit        # Prefer spread over Object.assign
|   +-- ban-relative-parent-imports.grit # Enforce absolute imports
|   +-- ban-default-export-non-index.grit # Default exports only in index
|   +-- enforce-effect-pipe.grit         # Prevent deep Effect nesting
|   +-- detect-missing-yield-star.grit   # CRITICAL: Effect.gen yield* detection
|   +-- enforce-nx-project-tags.grit     # Require Nx project tags
|   +-- enforce-esm-package-type.grit    # Require type: module
|   +-- enforce-strict-tsconfig.grit     # Require strict: true
+-- nx-plugin-template/       # Template for Nx plugin scaffolding
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

**File:** `ban-any-type-annotation.grit`

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
