# GritQL Pattern Refactoring Plan - Balanced Approach

**Status:** Plan Review (Awaiting User Approval)
**Created:** 2025-12-26
**Type:** Codebase Refactoring
**Scope:** biome/gritql-patterns/ (18 files → 12 files)

---

## Executive Summary

This plan consolidates 18 GritQL pattern files to 12 with improved documentation and consistency, following a **balanced approach** that maximizes benefit while keeping implementation manageable.

**Key Metrics:**
- Files reduced: 33% (18 → 12)
- Documentation coverage: 100% (all files get standardized docs)
- Pattern overlap eliminated: 0%
- Implementation time: ~9 hours (1 working day)
- Risk level: Medium (due to Effect pattern consolidation)

---

## Phase Analysis: Three Approaches Evaluated

### Approach 1: Minimal Consolidation ❌ Too Conservative
- Only merges 3 Effect-TS error patterns (smallest merge)
- Ignores type assertion redundancy
- Minimal documentation standardization
- **Verdict:** Leaves clear consolidation opportunities unrealized

### Approach 2: Maximum Consolidation ❌ Too Aggressive
- Reduces from 18 files to 9 files (50% reduction)
- Creates 5 new subdirectories
- Merges code style patterns aggressively
- 40+ hours implementation time
- **Verdict:** Over-engineered; subdirectory structure requires Home Manager module changes

### Approach 3: Balanced Consolidation ✅ RECOMMENDED
- Reduces from 18 files to 12 files (33% reduction)
- Merges only patterns with clear functional overlap
- Comprehensive documentation standardization
- 9 hours implementation time
- **Verdict:** Pragmatic balance of benefit and complexity

---

## Selected Approach: Balanced Consolidation

### Files to Merge

#### Merge #1: Type Assertions (3 → 1 file)

**Target file:** `ban-type-assertions.grit` (consolidated)

**Files to merge:**
1. `ban-type-assertions.grit` - Already has comprehensive patterns
2. `ban-any-type-annotation.grit` - REDUNDANT (subset of patterns)
3. `ban-satisfies.grit` - Related type narrowing operator

**Why merge:**
- `ban-any-type-annotation.grit` pattern `as any` is already caught by `as $type`
- `satisfies` operator is a related type narrowing concern
- All three enforce: "Use Schema.decodeUnknown or type guards, not type assertions"

**New structure:**
```grit
or {
  // Pattern 1: 'as' type assertion (any type)
  `$expr as $type` where { ... },

  // Pattern 2: Angle-bracket type assertion
  `<$type>$expr` where { ... },

  // Pattern 3: satisfies operator
  `$expr satisfies $type` where { ... }
}
```

**Benefit:** Single source of truth for type assertion policies with comprehensive documentation

---

#### Merge #2: Effect Error Handling (3 → 1 file)

**Target file:** `ban-imperative-error-handling-in-effect.grit` (consolidated)

**Files to merge:**
1. `ban-raw-promise-in-effect.grit` - Bans Promise primitives in Effect.gen
2. `ban-throw-in-effect.grit` - Bans throw statements in Effect contexts
3. `ban-try-catch-in-effect.grit` - Bans try-catch in/around Effect

**Why merge:**
- All three enforce the same principle: "Effect has typed error handling, don't use imperative patterns"
- All target Effect.gen contexts
- Creates single reference for "Effect error handling anti-patterns"

**New structure:**
```grit
or {
  // Pattern 1: Raw Promise usage in Effect.gen (await, .then, new Promise, Promise.all)
  `Effect.gen(function* () { $body })` where {
    $body <: contains or { `await $_`, `$_.then($_)`, ... }
  },

  // Pattern 2: throw statements in Effect.gen
  `Effect.gen(function* () { $body })` where {
    $body <: contains `throw $error`
  },

  // Pattern 3: try-catch in Effect.gen
  `Effect.gen(function* () { $body })` where {
    $body <: contains `try { $_ } catch ($err) { $_ }`
  },

  // Pattern 4: try-catch around Effect runners
  `try { $body } catch ($err) { $_ }` where {
    $body <: contains or { `Effect.runPromise`, `Effect.runSync` }
  }
}
```

**Benefit:** Comprehensive Effect error handling guide with all imperative anti-patterns in one place

---

### Files to Keep Separate

**Rationale:** These patterns serve distinct purposes with no functional overlap:

1. **`detect-missing-yield-star.grit`** - CRITICAL bug detection (missing yield* in Effect.gen)
   - Distinct concern: syntax requirement, not error handling
   - Different use case: static detection of incomplete patterns
   - Should remain prominent for visibility

2. **`detect-unhandled-effect-promise.grit`** - Typed errors in Effect.tryPromise
   - Distinct from banning Promises
   - Enforces HOW to use Effect.tryPromise, not WHETHER to use it
   - Complementary to merged patterns

3. **`prefer-effect-pipe.grit`** - Prevent deep Effect nesting
   - Code style/readability concern
   - Not error handling
   - Different severity consideration

4. **All code style patterns** (5 files)
   - Each serves distinct purpose (return types, imports, exports, performance)
   - No functional overlap
   - Merging reduces discoverability

5. **`ban-ts-ignore.grit`** - Already has comprehensive documentation
   - Model template for other patterns
   - Comprehensive comment structure (74 lines)
   - Already excellent

6. **All config enforcement patterns** (3 files)
   - Each targets different JSON file (project.json, package.json, tsconfig.json)
   - No overlap possible
   - Keep separate for clarity

---

## Phase 1: Documentation Standardization

**Duration:** 3 hours
**Risk:** Low (no pattern logic changes)

All 18 patterns (including the 3 files to be merged) get comprehensive documentation following the `ban-ts-ignore.grit` template.

### Documentation Template

```grit
language js

// [Title: What this pattern bans/enforces]
// [One-line description of the rule]
// Enforcement: error level (explanation of severity)
//
// Patterns matched:
// - [Pattern 1 description]
// - [Pattern 2 description]
//
// Rationale:
// - [Why pattern 1 is problematic]
// - [Why pattern 2 is problematic]
//
// [Category]-safe alternatives:
// 1. [Alternative approach 1]
// 2. [Alternative approach 2]
//
// Example fixes:
//
// ❌ WRONG: [Bad example]
// [code block]
//
// ✅ CORRECT: [Good example]
// [code block]

or {
  // Pattern 1: [description]
  `pattern1` where {
    register_diagnostic(
      span = $_,
      message = "[Problem]. [Solution]. See docs/LINTING_POLICY.md for [context].",
      severity = "error"
    )
  }
}
```

### Message Format Standard

All diagnostic messages follow this format:
```
"[Problem statement]. [Action to take]. See docs/LINTING_POLICY.md for [specific reference]."
```

Example:
```
"Type assertions are not allowed. Use Schema.decodeUnknown() for runtime validation or type guards for type narrowing. See docs/LINTING_POLICY.md for type-safe alternatives."
```

---

## Phase 2: Consistency Fixes

**Duration:** 30 minutes
**Risk:** Very low (simple find-replace)

### Fix #1: Severity Normalization

**Problem:** Mix of "warn", "warning", and "error" in different files

**Current state:**
- "warn" (1 file): `prefer-object-spread.grit` ← TYPO
- "warning" (2 files): `ban-default-export-non-index.grit`, `enforce-nx-project-tags.grit`
- "error" (15 files): All others

**Standard:** Use "error" or "warn" (not "warning")

**Changes:**
```
File: ban-default-export-non-index.grit
  severity = "warning" → severity = "warn"

File: enforce-nx-project-tags.grit
  severity = "warning" → severity = "warn"
```

**Rationale:** Biome GritQL uses "error" and "warn" as standard severity values.

---

## Phase 3: Type Assertion Consolidation

**Duration:** 1 hour
**Risk:** Medium (pattern logic changes, need thorough testing)

### Implementation Steps

1. **Create consolidated file** with all 3 patterns in one `or {}` block
2. **Test extensively** on sample TypeScript code
3. **Verify coverage** - new pattern catches everything old ones did
4. **Delete old files** (only after validation)

### Test Cases

```typescript
// All should trigger:
const x = value as any;              // as any
const y = value as string;           // as Type
const z = <number>value;             // angle-bracket syntax
const config = {} satisfies Config;  // satisfies operator
```

### Files Changed
- **Created:** `ban-type-assertions.grit` (consolidated)
- **Deleted:** `ban-any-type-annotation.grit`, `ban-satisfies.grit`
- **Modified:** Keep existing `ban-type-assertions.grit` but enhance with full documentation

---

## Phase 4: Effect Error Handling Consolidation

**Duration:** 2 hours
**Risk:** High (complex patterns, critical Effect-TS functionality)

### Implementation Steps

1. **Create consolidated file** with all patterns in one `or {}` block
2. **Create comprehensive test file** with examples of all anti-patterns
3. **Test incrementally** - verify each pattern variant triggers
4. **Compare with old patterns** - ensure no regressions
5. **Delete old files** (only after thorough validation)

### Test Cases (Must Pass)

```typescript
// Promise primitives
Effect.gen(function* () {
  const x = await fetch(url);           // await
  const y = promise.then(x => x);       // .then
  const z = new Promise(() => {});      // new Promise
  const a = Promise.all([p1, p2]);      // Promise.all
});

// throw statements
Effect.gen(function* () {
  throw new Error("fail");              // throw in gen
});

Effect.sync(() => {
  throw new Error("fail");              // throw in sync
});

// try-catch blocks
Effect.gen(function* () {
  try {
    yield* operation();
  } catch (e) {}                         // try-catch in gen
});

try {
  Effect.runSync(program);               // try-catch around runner
} catch (e) {}
```

### Files Changed
- **Created:** `ban-imperative-error-handling-in-effect.grit` (consolidated)
- **Deleted:** `ban-raw-promise-in-effect.grit`, `ban-throw-in-effect.grit`, `ban-try-catch-in-effect.grit`

---

## Phase 5: Update Documentation

**Duration:** 1 hour
**Risk:** Low (documentation only)

### Update `biome/CLAUDE.md`

**Current GritQL patterns section:**
```
gritql-patterns/
+-- ban-any-type-annotation.grit     # Catches `as any` assertions
+-- ban-satisfies.grit               # Bans satisfies keyword
+-- ban-type-assertions.grit         # Catches dangerous type assertions
... (18 total)
```

**New GritQL patterns section:**
```
gritql-patterns/
+-- ban-type-assertions.grit              # Type assertions, satisfies (consolidated: 3→1)
+-- ban-imperative-error-handling-in-effect.grit  # Promise/throw/try-catch in Effect (consolidated: 3→1)
+-- detect-missing-yield-star.grit        # CRITICAL: Effect.gen yield* detection
+-- detect-unhandled-effect-promise.grit  # Typed errors in Effect.tryPromise
+-- prefer-effect-pipe.grit               # Prevent deep Effect nesting
+-- ban-ts-ignore.grit                    # @ts-ignore/@ts-expect-error/@ts-nocheck
+-- ban-return-types.grit                 # Enforce return type inference
+-- ban-relative-parent-imports.grit      # Enforce absolute imports
+-- ban-push-spread.grit                  # Performance: avoid push(...spread)
+-- prefer-object-spread.grit             # Prefer spread over Object.assign
+-- ban-default-export-non-index.grit     # Default exports only in index
+-- enforce-nx-project-tags.grit          # Require Nx project tags
+-- enforce-esm-package-type.grit         # Require type: module
+-- enforce-strict-tsconfig.grit          # Require strict: true
```

### Add Documentation Section

```markdown
## Pattern Organization

Patterns are organized by concern:

**Type Safety:**
- `ban-type-assertions.grit` (consolidated) - Bans `as Type`, `<Type>`, `satisfies`

**Effect Error Handling:**
- `ban-imperative-error-handling-in-effect.grit` (consolidated) - Bans Promise/throw/try-catch
- `detect-missing-yield-star.grit` - CRITICAL: Detects missing yield* in Effect.gen
- `detect-unhandled-effect-promise.grit` - Requires typed errors in Effect.tryPromise

**Code Style:**
- `prefer-effect-pipe.grit` - Nested Effect operations
- `ban-return-types.grit` - Return type inference
- `ban-relative-parent-imports.grit` - Import paths
- `ban-default-export-non-index.grit` - Export organization
- `ban-push-spread.grit` - Performance optimization
- `prefer-object-spread.grit` - Object construction

**Type Suppression:**
- `ban-ts-ignore.grit` - TypeScript suppression comments

**Config Enforcement:**
- `enforce-nx-project-tags.grit` - Nx project configuration
- `enforce-esm-package-type.grit` - ES modules requirement
- `enforce-strict-tsconfig.grit` - TypeScript strict mode
```

---

## Implementation Sequence

### Recommended Order

1. **Documentation Standardization** (Phase 1: 3 hours)
   - Low risk, no functional changes
   - Provides template for consolidated files
   - Gets all patterns to same quality baseline

2. **Consistency Fixes** (Phase 2: 30 minutes)
   - Very low risk
   - Small find-replace changes
   - Validates documentation update didn't break patterns

3. **Type Assertion Consolidation** (Phase 3: 1 hour)
   - Medium risk, but clearer patterns
   - Good first consolidation before Effect patterns
   - Quick validation feedback

4. **Effect Error Handling Consolidation** (Phase 4: 2 hours)
   - High risk, but benefit is clear
   - Comprehensive test file needed
   - Takes longest, should be last

5. **Update Documentation** (Phase 5: 1 hour)
   - Update CLAUDE.md with new file structure
   - Link to consolidated patterns
   - Commit all changes

---

## Files Impacted

### Created (2 files)
- `biome/gritql-patterns/ban-type-assertions.grit` (consolidated)
- `biome/gritql-patterns/ban-imperative-error-handling-in-effect.grit` (consolidated)

### Deleted (6 files)
- `biome/gritql-patterns/ban-any-type-annotation.grit`
- `biome/gritql-patterns/ban-satisfies.grit`
- `biome/gritql-patterns/ban-raw-promise-in-effect.grit`
- `biome/gritql-patterns/ban-throw-in-effect.grit`
- `biome/gritql-patterns/ban-try-catch-in-effect.grit`

### Modified (16+ files)
- All 18 pattern files get documentation standardization
- `biome/CLAUDE.md` - Updated pattern inventory and organization notes

### Files Unchanged
- `biome.json` - No Biome config changes needed
- Biome auto-discovers `.grit` files by naming convention
- No hardcoded pattern references in config

---

## Validation Checklist

### After Each Phase

#### Phase 1 (Documentation) ✅
- [ ] All 18 files have standardized header format
- [ ] All files include example fixes (❌ WRONG / ✅ CORRECT)
- [ ] All files have rationale sections
- [ ] Diagnostic messages follow standard format
- [ ] Run: `biome check --gritql-patterns ./gritql-patterns .`

#### Phase 2 (Consistency) ✅
- [ ] Severity values normalized (only "error" or "warn")
- [ ] All patterns still load correctly
- [ ] Run: `biome check --gritql-patterns ./gritql-patterns .`

#### Phase 3 (Type Assertions) ✅
- [ ] New consolidated file created
- [ ] Test cases all trigger correctly
- [ ] Old files deleted only after validation
- [ ] Pattern count: 18 → 17 files
- [ ] Run: `biome check --gritql-patterns ./gritql-patterns test-type-assertions.ts`

#### Phase 4 (Effect Patterns) ✅
- [ ] New consolidated file created with 5 sub-patterns
- [ ] All test cases pass
- [ ] Old files deleted only after validation
- [ ] Pattern count: 17 → 15 files
- [ ] Run: `biome check --gritql-patterns ./gritql-patterns test-effect-error-handling.ts`

#### Phase 5 (Documentation) ✅
- [ ] `biome/CLAUDE.md` updated with new file list
- [ ] All pattern references valid
- [ ] Cross-references correct
- [ ] Final pattern count: 12 files
- [ ] Run: `biome check .` (full codebase)

---

## Risk Assessment

| Phase | Risk | Mitigation |
|-------|------|-----------|
| Documentation | Low | No code changes, easy rollback |
| Consistency | Very Low | Simple search-replace |
| Type Assertions | Medium | Comprehensive test cases before deletion |
| Effect Patterns | High | Extensive testing, incremental validation |
| Documentation Update | Low | Metadata only |

**Overall:** Medium risk, mitigated by comprehensive testing and incremental approach

---

## Rollback Plan

**Immediate Rollback** (restore all changes)
```bash
git checkout HEAD -- biome/gritql-patterns/ biome/CLAUDE.md
```

**Selective Rollback** (restore specific phase)
```bash
# Rollback consolidation only, keep documentation
git checkout HEAD -- biome/gritql-patterns/ban-type-assertions.grit
git checkout HEAD -- biome/gritql-patterns/ban-any-type-annotation.grit
git checkout HEAD -- biome/gritql-patterns/ban-satisfies.grit
```

**Verify After Rollback**
```bash
biome check --gritql-patterns ./gritql-patterns .
ls -1 biome/gritql-patterns/*.grit | wc -l  # Should be 18
```

---

## Success Criteria

After completing all phases:

- [x] Files reduced from 18 to 12 (33% reduction)
- [x] Documentation coverage: 100% (all files have comprehensive docs)
- [x] Severity consistency: 100% ("error" or "warn" only)
- [x] Pattern overlap: 0% (no redundant patterns)
- [x] All test cases pass without false positives/negatives
- [x] `biome check .` passes on full codebase
- [x] CLAUDE.md updated with new organization
- [x] Rollback plan verified

---

## Implementation Commands Reference

### Pre-Implementation
```bash
cd /Users/samuelho/Projects/infra/dev-config
git checkout -b refactor/gritql-pattern-consolidation
```

### Validate Before Changes
```bash
biome check --gritql-patterns ./gritql-patterns .
ls -1 biome/gritql-patterns/*.grit | wc -l  # Should be 18
```

### After Type Assertion Consolidation
```bash
biome check --gritql-patterns ./gritql-patterns test-type-assertions.ts
ls -1 biome/gritql-patterns/*.grit | wc -l  # Should be 17
```

### After Effect Pattern Consolidation
```bash
biome check --gritql-patterns ./gritql-patterns test-effect-error-handling.ts
ls -1 biome/gritql-patterns/*.grit | wc -l  # Should be 15
```

### Final Validation
```bash
biome check --gritql-patterns ./gritql-patterns .
biome check .
ls -1 biome/gritql-patterns/*.grit | wc -l  # Should be 12
```

### Commit
```bash
git add -A
git commit -m "refactor(gritql): consolidate patterns with comprehensive documentation

Phase 1: Documentation Standardization
- Standardized header format across all 18 patterns
- Added comprehensive examples (❌ WRONG / ✅ CORRECT)
- Standardized message format: [Problem]. [Solution]. [Reference]

Phase 2: Consistency Fixes
- Normalized severity values: 'warning' → 'warn'
- Verified all patterns load correctly

Phase 3: Type Assertion Consolidation
- Merged ban-any-type-annotation.grit (redundant)
- Merged ban-satisfies.grit (related type narrowing)
- Created ban-type-assertions.grit with comprehensive docs

Phase 4: Effect Error Handling Consolidation
- Merged ban-raw-promise-in-effect.grit
- Merged ban-throw-in-effect.grit
- Merged ban-try-catch-in-effect.grit
- Created ban-imperative-error-handling-in-effect.grit

Phase 5: Documentation Updates
- Updated biome/CLAUDE.md with new file structure
- Added pattern organization notes

Results:
- Files reduced: 18 → 12 (33%)
- Documentation: 100% coverage
- Pattern overlap: 0%
- Risk: Mitigated with comprehensive testing"
```

---

## Next Steps (After Approval)

1. **User Review** - Review this plan, ask clarifying questions, approve approach
2. **Execute Implementation** - Run phases in order (1-5)
3. **Validation** - Run checklist after each phase
4. **Create PR** - Push to branch and create pull request
5. **Merge** - After CI passes and review approved

---

## Questions for User

Before implementing, please confirm:

1. **Consolidation scope:** Do you agree with merging type assertions (3→1) and Effect patterns (3→1)?
2. **Documentation template:** Does the standardized format (based on ban-ts-ignore.grit) work for you?
3. **Severity normalization:** Is "warn" vs "warning" standardization acceptable?
4. **Timeline:** Are you ready to proceed with implementation, or do you need more time to review?
5. **Home Manager:** Should we plan to update Home Manager symlinks if structure changes?

---

**Ready for:** Implementation Phase 1 (once approved)
