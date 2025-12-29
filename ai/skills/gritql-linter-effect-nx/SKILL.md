---
name: gritql-linter-effect-nx
description: Stack-specific GritQL linting for Nx monorepos with EffectTS and strict typing. Performs type safety checks, Effect pattern enforcement, and monorepo boundary violation detection.
---

# GritQL Linter for Nx + Effect TypeScript

## Instructions

This skill provides GritQL-based linting and refactoring capabilities for TypeScript monorepo codebases, specifically optimized for Nx monorepos with Effect-TS and strict typing practices.

### Available Commands

#### `/lint-type-safety` - Type Safety Checks

Run all type safety related GritQL patterns.

**Patterns executed:**
- `ban-type-assertions` - Detects `as any`, `as T`, `satisfies` operators
- `ban-return-types` - Detects explicit return types on functions
- `ban-ts-ignore` - Detects `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`

**Usage:**
```bash
grit check \
  --pattern ban-type-assertions \
  --pattern ban-return-types \
  --pattern ban-ts-ignore \
  .
```

**Context:**
- Detects type assertions that bypass TypeScript's type inference
- Identifies suppression comments that hide bugs
- Violations reference `docs/LINTING_POLICY.md` for remediation

**Remediation:**
- Use `Schema.decodeUnknown()` for external data (Effect-TS)
- Add proper type guards to narrow types
- Fix underlying type errors instead of suppressing them

#### `/lint-effect` - Effect-TS Pattern Enforcement

Run all Effect-specific GritQL patterns.

**Patterns executed:**
- `ban-imperative-error-handling-in-effect` - Detects Promise primitives, throw, try-catch in Effect
- `detect-missing-yield-star` - Detects missing `yield*` in Effect.gen
- `detect-unhandled-effect-promise` - Detects Effect.tryPromise without typed errors
- `enforce-effect-pipe` - Detects deeply nested Effect calls (3+ levels)

**Usage:**
```bash
grit check \
  --pattern ban-imperative-error-handling-in-effect \
  --pattern detect-missing-yield-star \
  --pattern detect-unhandled-effect-promise \
  --pattern enforce-effect-pipe \
  .
```

**Context:**
- Effect tracks errors in the type system (Effect<A, E, R>)
- Imperative patterns break Effect's typed error tracking
- Missing `yield*` causes silent bugs (assigns Effect<T> instead of T)

**Remediation:**
- Use `Effect.tryPromise()` with `{ try, catch }` for async operations
- Always use `yield*` when calling Effects in `Effect.gen`
- Use `Effect.pipe()` for composition instead of nesting
- Reference `ai/skills/effect-service-architect/SKILL.md` for remediation patterns

#### `/lint-monorepo` - Monorepo Boundary Checks

Run Nx/monorepo boundary violation patterns.

**Patterns executed:**
- `ban-relative-parent-imports` - Detects `../../` imports
- `enforce-nx-project-tags` - Ensures project.json has tags

**Usage:**
```bash
grit check \
  --pattern ban-relative-parent-imports \
  --pattern enforce-nx-project-tags \
  .
```

**Context:**
- Monorepo structure enforced via workspace aliases (@org/lib)
- Nx project tags enable module boundary enforcement
- Relative parent imports cross library boundaries incorrectly

**Stack Detection:**
- Scans for `nx.json` and `project.json` files
- Checks for `pnpm-workspace.yaml` or workspace configuration
- Adjusts enforcement based on detected infrastructure

**Remediation:**
- Replace `../../lib` imports with workspace alias `@org/lib`
- Add tags to `project.json` (e.g., `["type:lib", "scope:shared"]`)

#### `/lint-all` - Full Analysis (Default)

Run all 14 GritQL patterns and generate categorized report.

**Usage:**
```bash
grit check .
```

**Stack Detection:**
- Nx: Check for `nx.json`, `project.json` files
- Effect: Scan for imports from `"@effect/*"`
- TypeScript: Verify `tsconfig.json` exists

**Report Format:**
```markdown
## GritQL Lint Report

### Type Safety (4 patterns)
- ban-type-assertions: 5 violations (error)
- ban-return-types: 2 violations (error)
- ban-ts-ignore: 0 violations
- prefer-object-spread: 1 violation (warn)

### Effect-TS (4 patterns)
- ban-imperative-error-handling: 3 violations (error)
- detect-missing-yield-star: 1 violation (error)
- detect-unhandled-effect-promise: 0 violations
- enforce-effect-pipe: 2 violations (error)

### Monorepo (2 patterns)
- ban-relative-parent-imports: 4 violations (error)
- enforce-nx-project-tags: 2 violations (warn)

### General (4 patterns)
- ban-default-export-non-index: 0 violations
- ban-push-spread: 1 violation (error)
- enforce-esm-package-type: 0 violations
- enforce-strict-tsconfig: 0 violations

Total: 21 violations (17 error, 4 warn)
```

#### `/fix-pattern PATTERN_NAME` - Apply Pattern Fix

Apply a specific GritQL pattern with dry-run preview and verification.

**Workflow:**
1. **Dry-run**: Preview changes before applying
   ```bash
   grit apply --pattern PATTERN_NAME --dry-run .
   ```
2. **Review**: Examine the unified diff output
3. **Apply**: Apply the changes
   ```bash
   grit apply --pattern PATTERN_NAME .
   ```
4. **Verify**: Run Biome to verify no new violations
   ```bash
   biome check .
   ```

**Safety Mode:**
- Requires confirmation for each file modification
- Shows diff before applying changes
- Reverts on failure if verification fails

**Note:** Only available for patterns with auto-fix capabilities. Check pattern documentation for fixability.

#### `/analyze-violations` - Deep Analysis

Perform comprehensive analysis of violations with contextual information.

**For each violation:**
- Show surrounding code context (5 lines before/after)
- Identify why pattern triggered
- Suggest refactoring strategy
- Link to pattern file: `biome/gritql-patterns/PATTERN_NAME.grit`
- Reference documentation:
  - Type safety: `docs/LINTING_POLICY.md`
  - Effect patterns: `ai/skills/effect-service-architect/SKILL.md`
  - Type safety cleanup: `ai/skills/type-safety-enforcer/SKILL.md`

## Pattern Categories

| Category | Patterns | Source Files |
|----------|----------|--------------|
| **Type Safety** | 4 | `ban-type-assertions.grit`, `ban-return-types.grit`, `ban-ts-ignore.grit`, `prefer-object-spread.grit` |
| **Effect-TS** | 4 | `ban-imperative-error-handling-in-effect.grit`, `detect-missing-yield-star.grit`, `detect-unhandled-effect-promise.grit`, `enforce-effect-pipe.grit` |
| **Monorepo** | 2 | `ban-relative-parent-imports.grit`, `enforce-nx-project-tags.grit` |
| **General** | 4 | `ban-default-export-non-index.grit`, `ban-push-spread.grit`, `enforce-esm-package-type.grit`, `enforce-strict-tsconfig.grit` |

## Integration Points

### With `.grit/grit.yaml`

Pattern files are referenced via glob pattern:
```yaml
# .grit/grit.yaml
version: 0.0.1
patterns:
  - biome/gritql-patterns/*.grit
```

### With `gritql.nix` Module

The existing Home Manager module (`modules/home-manager/programs/gritql.nix`) automatically:
- Symlinks patterns to `~/.config/grit/patterns` (for global grit access)
- Symlinks patterns to `~/.config/biome/gritql-patterns` (for biome integration)
- Patterns are available in any workspace via these symlinked paths

### With Biome

Patterns are executed via Biome's GritQL integration:
```bash
biome check --gritql-patterns ~/.config/biome/gritql-patterns .
```

## Context Awareness

The skill adapts enforcement based on detected stack components:

1. **Nx Detection**:
   - Checks for `nx.json` in project root
   - Scans for `project.json` files in subdirectories
   - Enables monorepo patterns only if Nx detected

2. **Effect Detection**:
   - Scans for imports from `"@effect/*"` package
   - Checks for Effect-specific constructs (Effect.gen, yield*, etc.)
   - Enables Effect-specific patterns only if Effect detected

3. **Monorepo Detection**:
   - Checks for `pnpm-workspace.yaml`
   - Checks for `package.json` with `workspaces` property
   - Enables boundary patterns only if monorepo detected

4. **Workspace Alias Suggestions**:
   - When detecting `../../` imports in monorepo context
   - Suggests workspace alias based on library location
   - Example: `../../libs/auth` → `@my-org/auth` or similar

## Common Workflows

### Run All Checks on Nx Monorepo
```bash
# Detect stack, run all applicable patterns
grit check .
```

### Fix Type Safety Violations
```bash
# 1. First, see what needs fixing
grit check --pattern ban-type-assertions .

# 2. Preview changes
grit apply --pattern ban-type-assertions --dry-run .

# 3. Apply changes
grit apply --pattern ban-type-assertions .

# 4. Refine with type-safety-enforcer skill for complex cases
# Use /skills type-safety-enforcer for systematic cleanup
```

### Enforce Effect-TS Patterns
```bash
# Check for Effect violations
grit check --pattern detect-missing-yield-star .

# Analyze violations in context
# Use /analyze-violations for detailed remediation suggestions

# For complex Effect refactoring:
# Use /skills effect-service-architect for full service scaffolding
```

### Monorepo Boundary Enforcement
```bash
# Find all relative parent imports
grit check --pattern ban-relative-parent-imports .

# Review violations - each will suggest workspace alias
# Manually update imports based on alias suggestions

# Ensure all projects have tags
grit check --pattern enforce-nx-project-tags .
```

## Documentation References

All violations reference relevant documentation:

- **Type Safety**: `docs/LINTING_POLICY.md` - Complete policy on type safety guardrails
- **Pattern Details**: `biome/gritql-patterns/*.grit` - Individual pattern rationale and examples
- **Effect Remediation**: `ai/skills/effect-service-architect/SKILL.md` - Effect service patterns
- **Type Safety Cleanup**: `ai/skills/type-safety-enforcer/SKILL.md` - Systematic type safety elimination
- **Structural Refactoring**: `ai/skills/structural-refactor/SKILL.md` - GritQL-based transformations

## Verification Checklist

After running fixes:

- [ ] TypeScript compilation passes: `tsc --noEmit`
- [ ] Biome validation passes: `biome check`
- [ ] No new GritQL violations introduced
- [ ] Tests still pass: `bun test` (or project-specific test command)
- [ ] No broken imports after refactoring
- [ ] Workspace aliases correctly configured (if monorepo)

## Related Skills

- **type-safety-enforcer**: Systematically eliminate type holes (`as any`, `!`, `@ts-ignore`)
- **effect-service-architect**: Scaffold and refactor Effect-based services
- **structural-refactor**: Perform codebase-wide transformations using GritQL
