---
scope: docs/
title: Linting Policy for AI Assistants & Developers
updated: 2025-12-26
relates_to:
  - ../CLAUDE.md
  - ../biome/CLAUDE.md
  - ../biome/biome-base.json
  - ../.pre-commit-config.yaml
---

# Linting and Type Safety Policy

This document is the **single source of truth** for linting configuration rules and type safety guardrails in this repository. It applies to both human developers and AI assistants.

## Table of Contents

1. [Overview](#overview)
2. [3-Layer Defense Architecture](#3-layer-defense-architecture)
3. [Policy Tiers](#policy-tiers)
4. [Enforcement Mechanisms](#enforcement-mechanisms)
5. [Type Safety Patterns (Prohibited)](#type-safety-patterns-prohibited)
6. [Rule Modification Guidelines](#rule-modification-guidelines)
7. [Decision Trees](#decision-trees)
8. [Common Issues & Resolution](#common-issues--resolution)

## Overview

### Purpose

This policy prevents AI assistants from introducing:
- **Type safety violations** (e.g., `as any`, `@ts-ignore`, non-null assertions)
- **Linting rule weakening** (e.g., changing `error` → `warn` severity)
- **Code quality degradation** through configuration bypasses

### Scope

Applies to:
- All AI agents (Claude Code, OpenCode, ChatGPT, etc.)
- All configuration modifications:
  - `biome.json` and `biome-base.json`
  - `tsconfig.json` and `tsconfig.*.json`
  - `.pre-commit-config.yaml`
  - `biome/gritql-patterns/*.grit`
- All TypeScript code changes involving type safety

### Enforcement

Three layers working together:
1. **Documentation** (CLAUDE.md files) - Proactive guidance
2. **Validation** (pre-commit hooks) - Reactive blocking
3. **Runtime** (Biome rules + GritQL patterns) - Automatic detection

## 3-Layer Defense Architecture

### Layer 1: Documentation (Proactive Guidance)

**Files:** CLAUDE.md files across the repository

**Purpose:** Educate and guide AI assistants BEFORE violations occur

**What it contains:**
- Decision trees for type-related requests
- Type-safe alternatives with examples
- Rationale for why patterns are prohibited
- Quick reference guides

**Coverage:**
- Root CLAUDE.md: General type safety guardrails and rule modification overview
- biome/CLAUDE.md: Detailed patterns (4 prohibited type safety patterns)
- This document: Complete policy reference

**Effectiveness:** 80-90% - Most AI violations caught at documentation level

### Layer 2: Validation (Reactive Blocking)

**Files:** `scripts/validate-linting-config.sh` (pre-commit hook)

**Purpose:** Automatically detect and block violations at commit time

**What it detects:**
- Rule severity downgrades (error → warn, warn → off)
- TypeScript strict mode being disabled
- New suppression comments being added
- Configuration files being modified without approval

**Effectiveness:** 95%+ - Catches attempts to bypass Layer 1

**How to bypass:** `git commit --no-verify` (requires developer attention)

### Layer 3: Runtime (Automatic Detection)

**Files:** Biome rules, GritQL patterns

**Purpose:** Detect violations in already-committed code

**What it detects:**
- `as any` type assertions → `noExplicitAny: "error"`
- `@ts-ignore` comments → `ban-ts-ignore.grit`
- Non-null assertions `!` → `noNonNullAssertion: "error"`
- `satisfies` operator → `ban-satisfies.grit`

**Effectiveness:** 100% - Can detect violations in any code

**Trigger:** `biome check` or CI/CD pipeline

## Policy Tiers

### Tier 1: HARD BLOCKED ❌ (Pre-commit Fails)

These modifications are **immediately blocked** by pre-commit hooks. Cannot be committed without explicit `git commit --no-verify` (which adds developer attention).

| Modification | Why Blocked | Detection | Example |
|--------------|------------|-----------|---------|
| Rule weakening (error → warn) | Lowers code quality standards | validate-linting-config.sh | `"noExplicitAny": "warn"` |
| Rule disabling (error → off) | Removes validation entirely | validate-linting-config.sh | `"noExplicitAny": "off"` |
| TypeScript strict mode disabled | Disables type safety | validate-linting-config.sh | `"strict": false` |
| New `@ts-ignore` comments | Suppresses type errors | ban-ts-ignore.grit | `// @ts-ignore` |

**Decision tree for Tier 1 requests:**

```
AI receives request to modify linting config?
├─ Change rule from error → warn/off? → HARD ERROR: Blocked by pre-commit
├─ Set strict: false? → HARD ERROR: Blocked by pre-commit
├─ Add @ts-ignore/@ts-expect-error? → HARD ERROR: Blocked by GritQL pattern
├─ Create bypass mechanism? → HARD ERROR: Blocked by validate-linting-config.sh
└─ Use as any type assertion? → HARD ERROR: Blocked by Biome noExplicitAny
```

### Tier 2: SOFT WARNING ⚠️ (Requires Confirmation)

These modifications are **allowed but dangerous**. AI must:
1. Show explicit warning with full change details
2. Wait for human approval with "APPROVE [description]"
3. Document approval in commit message

| Modification | Why Warned | Requirement | Example |
|--------------|-----------|-------------|---------|
| Modify rule configuration (same severity) | May affect many files | User approval | Changing rule options |
| Add new Biome rule | Could impact existing code | User approval | `"newRule": "error"` |
| Modify GritQL pattern | Pattern could be overly broad | User approval | Editing `.grit` files |

**Warning template (required):**

```
⚠️  WARNING: Linting Configuration Modification Requested

This change affects linting/type checking rules that apply to the entire codebase.
Rule modifications can have downstream effects on hundreds of files.

Change Summary:
[Specific change being made]

Files Affected:
[Which files, how many lines]

Rationale:
[Why this change is necessary]

Impact Analysis:
[What behavior changes, what rules are affected]

Requires human approval. To approve, reply: APPROVE [change description]
```

**Decision tree for Tier 2 requests:**

```
AI receives request to modify linting config (not weakening)?
├─ Adding new stricter rule? → ALLOW: This improves code quality
├─ Modifying rule options (same severity)? → SOFT WARNING: Show template, wait for APPROVE
├─ Changing rule configuration slightly? → SOFT WARNING: Show template, wait for APPROVE
└─ Unsure if it's Tier 1 or Tier 2? → SOFT WARNING: Better to warn than miss
```

### Tier 3: ALLOWED ✅ (No Restrictions)

These modifications are **allowed without restrictions**. AI can proceed without warnings or approval.

| Modification | Why Allowed | Example |
|--------------|------------|---------|
| Adding stricter rules | Improves code quality | `"newRule": "error"` |
| Fixing rule bugs | Maintains correctness | Correcting pattern logic |
| Disabling rules for test files | Legitimate exception | Adding override for `*.test.ts` |
| Documentation updates | Non-functional change | Updating comments in .grit files |

**Examples that are Tier 3:**
- Adding new GritQL patterns to catch bugs
- Enabling stricter TypeScript compiler options
- Adding test file exceptions to rules
- Improving pattern documentation

## Enforcement Mechanisms

### Pre-commit Hook: `scripts/validate-linting-config.sh`

**When it runs:** Every commit (via `.pre-commit-config.yaml`)

**What it checks:**
```bash
# Pattern 1: Rule severity downgrade
- git diff shows "error" being changed to "warn"
- git diff shows "warn" being changed to "off"
- Blocks commit with colored error message

# Pattern 2: Rule disabling
- git diff shows any rule being set to "off"
- Blocks commit with colored error message

# Pattern 3: TypeScript strict mode disabled
- git diff in tsconfig.json shows "strict": false
- Blocks commit with colored error message
```

**Output on violation:**
```
❌ Rule weakening detected in biome.json: error → warn

Linting config validation FAILED: 1 violation(s)

Rule weakening is not allowed. See docs/LINTING_POLICY.md

To override (requires approval):
  git commit --no-verify -m "Approved: [justification]"
```

**How to bypass:** (For developers only, with explicit approval)
```bash
git commit --no-verify -m "fix: weaken rule X due to [EXPLICIT JUSTIFICATION]"
```
This requires:
1. Explicit developer attention (typing `--no-verify`)
2. Clear justification in commit message
3. Code review approval before merge

### Biome Linting Rules

**Files:** `biome/biome-base.json` and Biome config

**Key rules blocking type workarounds:**
```json
{
  "linter": {
    "rules": {
      "suspicious": {
        "noExplicitAny": "error",           // Blocks: as any
        "noNonNullAssertion": "error"       // Blocks: !
      }
    }
  }
}
```

**Trigger:** `biome check` or CI/CD linting phase

### GritQL Patterns

**Directory:** `biome/gritql-patterns/`

**Critical patterns:**
- `ban-ts-ignore.grit` - Detects `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`
- `ban-satisfies.grit` - Detects `satisfies` operator usage
- `ban-any-type-annotation.grit` - Detects `as any` patterns
- `ban-non-null-assertions.grit` - Detects `!` operators

**Trigger:** `biome check` or CI/CD linting phase

## Type Safety Patterns (Prohibited)

All of these patterns are **strictly prohibited** and must never be used.

### Pattern 1: `value as any` Assertions

**Why prohibited:**
- Defeats ALL type checking for that value
- Makes type system completely useless for that variable
- Hides bugs that would be caught by proper types

**Detection:**
- Biome rule `noExplicitAny: "error"` catches at lint time
- GritQL pattern `ban-any-type-annotation.grit` catches custom AST
- Pre-commit hook validates no new patterns introduced

**Type-safe alternatives:**

```typescript
// ❌ WRONG: Defeats type checking
const result = someValue as any;

// ✅ CORRECT: Option 1 - Schema validation (Effect-TS)
import { Schema } from "effect";
const result = Schema.decodeUnknownSync(MySchema)(someValue);

// ✅ CORRECT: Option 2 - Proper type annotation
const result: ExpectedType = someValue;

// ✅ CORRECT: Option 3 - Type guard
const result = someValue as unknown;
if (typeof result === 'object' && result !== null && 'prop' in result) {
  // result is now properly narrowed
}
```

**When user requests this:**
1. Identify they're asking for `as any` pattern
2. REFUSE the request
3. Ask clarifying questions: "What types does someValue have? What are you trying to achieve?"
4. Suggest proper type annotation, Schema validation, or type guard instead
5. Provide working code example

### Pattern 2: TypeScript Suppression Comments

**Why prohibited:**
- `@ts-ignore` suppresses errors without fixing them
- Creates silent bugs that will crash at runtime
- Hides real type errors that need fixing

**Patterns blocked:**
- `// @ts-ignore` - Suppresses next line error
- `// @ts-expect-error` - Acknowledges error exists but ignores it
- `// @ts-nocheck` - Disables all type checking for entire file

**Detection:**
- GritQL pattern `ban-ts-ignore.grit` detects all three variants
- Pre-commit hook validates no new suppression comments

**Type-safe alternatives:**

```typescript
// ❌ WRONG: Suppresses type error without fixing
// @ts-ignore
const x = functionWithWrongReturn();

// ✅ CORRECT: Option 1 - Fix the function's return type
function functionWithWrongReturn(): ProperReturnType {
  // Implementation that returns the correct type
  return { ... };
}

// ✅ CORRECT: Option 2 - Use Schema for unknown data
const x = Schema.decodeUnknownSync(MySchema)(unknownData);

// ✅ CORRECT: Option 3 - Use type guard before accessing
if (isProperType(value)) {
  const x = value;  // x is now properly typed
}
```

**When user requests this:**
1. Identify they're asking to add suppression comment
2. REFUSE the request
3. Ask: "What's the underlying type error?"
4. Help fix the root cause instead
5. Provide refactored code with proper types

### Pattern 3: Non-null Assertions (`!`)

**Why prohibited:**
- Asserts null/undefined won't happen without runtime verification
- Causes runtime crashes when assertion is wrong
- Hides real null-safety bugs

**Detection:**
- Biome rule `noNonNullAssertion: "error"` catches at lint time
- Pre-commit hook validates no new `!` assertions

**Type-safe alternatives:**

```typescript
// ❌ WRONG: Asserts without verification
const value = maybeValue!;

// ✅ CORRECT: Option 1 - Optional chaining
const value = maybeValue?.toString();

// ✅ CORRECT: Option 2 - Explicit null check
if (maybeValue !== null) {
  const value = maybeValue;  // value is now non-null
}

// ✅ CORRECT: Option 3 - Nullish coalescing
const value = maybeValue ?? defaultValue;

// ✅ CORRECT: Option 4 - Type guard
if (isProperType(maybeValue)) {
  const value = maybeValue;  // value is now typed and non-null
}

// ✅ CORRECT: Option 5 - Schema validation
const value = Schema.decodeUnknownSync(MySchema)(maybeValue);
// Schema ensures non-null per definition
```

**When user requests this:**
1. Identify they're asking for `!` operator
2. REFUSE the request
3. Ask: "When would this value be null? How should we handle that case?"
4. Suggest optional chaining, null check, or type guard
5. Provide refactored code with proper null handling

### Pattern 4: `satisfies` Operator

**Why prohibited:**
- Allows type widening without explicit type assignment
- Doesn't catch errors at assignment time (errors caught later)
- Anti-pattern that reduces type safety vs explicit annotation

**Detection:**
- GritQL pattern `ban-satisfies.grit` detects usage
- Pre-commit hook validates no new satisfies introduced

**Type-safe alternatives:**

```typescript
// ❌ WRONG: satisfies allows type widening
const config = { port: 3000 } satisfies Config;

// ✅ CORRECT: Option 1 - const assertion for literals
const config = { port: 3000 } as const;
// Now config.port is type 3000 (literal), not number

// ✅ CORRECT: Option 2 - Explicit type annotation
const config: Config = { port: 3000 };
// Errors caught immediately at assignment

// ✅ CORRECT: Option 3 - Schema-based validation
const config = Schema.decodeUnknownSync(ConfigSchema)({ port: 3000 });
// Both type checking AND runtime validation
```

**When user requests this:**
1. Identify they're asking for `satisfies` operator
2. REFUSE the request
3. Ask clarifying question about intent
4. Suggest `as const` (for literal preservation) or explicit type annotation
5. Offer Schema validation if runtime validation needed

## Rule Modification Guidelines

### Tier 1: Adding Stricter Rules (ALLOWED) ✅

**Examples:**
- Adding `noConsoleLog: "error"` to prevent debug logs in production
- Adding `noDebugger: "error"` to prevent breakpoints
- Adding new GritQL pattern to catch common mistakes

**Process:**
1. Propose the new rule with rationale
2. Show impact analysis (how many files affected)
3. Provide auto-fix command if available
4. Commit with clear message explaining rule addition

**Commit message template:**
```
feat(linting): add noConsoleLog rule to prevent debug logs

Added new rule to catch console statements in production code.
Auto-fixed 3 files with existing console.log calls.

Files modified: 3
Rule added: linter.rules.nursery.noConsoleLog = "error"
```

### Tier 2: Modifying Rule Configuration (SOFT WARNING) ⚠️

**Examples:**
- Changing rule options: `noExcessiveCognitiveComplexity` threshold
- Updating rule format options
- Changing GritQL pattern options

**Process:**
1. Show SOFT WARNING with full change details
2. Wait for explicit human approval ("APPROVE [description]")
3. Document approval in commit message
4. Explain impact of configuration change

**Warning template (use in code/UI):**
```
⚠️  WARNING: Linting Rule Configuration Change

You're about to modify linting rule configuration. This affects:
- All code checked by this rule
- CI/CD pipeline validation
- Developer workflow (local linting)

Change: Modifying noExcessiveCognitiveComplexity complexity threshold from 15 to 20

Impact:
- ~12 files will need refactoring if stricter (15→X)
- ~0 files affected if looser (this case: 20 is looser)
- CI will enforce the new threshold on all commits

Requires approval: APPROVE Increasing complexity threshold to 20
```

**Commit message template:**
```
fix(linting): increase cognitive complexity threshold to 20

Approved: Increasing threshold to allow larger utility functions.
Rationale: Large data transformation utilities need more complexity.

Rule modified: noExcessiveCognitiveComplexity complexity = 20
Files affected: 0 (looser configuration)
```

### Tier 3: Weakening Rules (HARD ERROR) ❌

**Examples:**
- Changing `noExplicitAny` from `error` to `warn`
- Changing `noNonNullAssertion` from `error` to `off`
- Disabling type checking in tsconfig

**Process:**
1. PRE-COMMIT HOOK BLOCKS automatically
2. Cannot commit without `git commit --no-verify`
3. If forced: Requires explicit developer approval in commit message
4. Code review should question the bypass

**What happens:**
```bash
$ git commit
❌ Rule weakening detected: noExplicitAny error → warn

Linting config validation FAILED: 1 violation(s)

Rule weakening is not allowed. See docs/LINTING_POLICY.md

To override (requires approval):
  git commit --no-verify -m "Approved: [justification]"

$ git commit --no-verify
# ✅ Allows commit, but requires explicit developer attention
```

**Required commit message format:**
```
fix(linting): weaken noExplicitAny from error to warn

APPROVED BY: [Developer name] [Date]
JUSTIFICATION: [Explicit reason why weakening is needed]

Warning: This reduces code quality standards. Changes:
- Rule: noExplicitAny
- Old: error
- New: warn
- Impact: [What does this allow that was previously forbidden?]
- Compensation: [How are we maintaining type safety otherwise?]
```

**Code review criteria for rule weakening:**
- [ ] Explicit approval from project maintainer documented
- [ ] Clear justification in commit message
- [ ] Impact analysis included
- [ ] Compensation mechanism in place (e.g., "We're adding Schema validation instead")
- [ ] NOT a permanent workaround (temporary bypass with plan to fix)

## Decision Trees

### For AI: Type Safety Request Decision Tree

```
User requests a type-safety related change?
│
├─ Request involves "as any" or "as unknown"?
│  ├─ "Just use as any" → REFUSE
│  ├─ "Types don't match" → SUGGEST: Refactor types or use Schema.decodeUnknown
│  └─ "Value could be anything" → SUGGEST: Use Schema.decodeUnknown() instead
│
├─ Request involves @ts-ignore or @ts-nocheck?
│  ├─ "Add suppression comment" → REFUSE
│  ├─ "Types are wrong" → SUGGEST: Fix the type definition
│  └─ "This is temporary" → REFUSE: Use proper types from start
│
├─ Request involves ! (non-null assertion)?
│  ├─ "Value might be null" → SUGGEST: Optional chaining (?.) or null check
│  ├─ "Use ! to assert" → REFUSE: Add runtime verification
│  └─ "For performance" → REFUSE: Correctness > performance
│
├─ Request involves satisfies operator?
│  ├─ "Preserve literal types" → SUGGEST: Use as const instead
│  ├─ "Want type checking" → SUGGEST: Use explicit : Type annotation
│  └─ "Just use satisfies" → REFUSE: Use as const or explicit type
│
└─ In any doubt?
   → Consult biome/CLAUDE.md Type Safety section
   → Consult CLAUDE.md AI Guardrails section
   → Ask for human clarification before proceeding
```

### For AI: Rule Modification Decision Tree

```
User requests linting config modification?
│
├─ Weakening rule (error → warn/off)?
│  → HARD ERROR: Pre-commit blocks automatically
│  → If user insists: Explain policy, suggest alternatives
│
├─ Disabling TypeScript strict mode?
│  → HARD ERROR: Pre-commit blocks automatically
│  → Show LINTING_POLICY.md
│
├─ Adding stricter rule (new error-level constraint)?
│  → ALLOW: Improves code quality
│  → Commit with explanation of benefit
│
├─ Modifying rule config (same severity, different options)?
│  → SOFT WARNING: Show warning template with full details
│  → Wait for explicit "APPROVE [description]" confirmation
│  → Document approval in commit message
│
├─ Adding override for specific file pattern?
│  → EVALUATE: Is this legitimate exception?
│  → ALLOW if: test files, config files, generated code
│  → REFUSE if: Bypassing rules for regular code
│
└─ Unsure if Tier 1, 2, or 3?
   → Assume Tier 2: Show warning, wait for approval
   → Better to over-warn than miss a violation
```

## Common Issues & Resolution

### Issue: "But this one time we need to use `as any`"

**Root cause:** Type system is too strict, workaround looks easier than proper fix

**Proper resolution:**
1. Understand why types don't match
2. Fix the underlying type definition
3. If external library has bad types: Add proper `.d.ts` or use Schema validation
4. Never accept "just this once" workarounds - they become permanent

**Example scenario:**
```typescript
// ❌ WRONG: "Just use as any to get it working"
const data = JSON.parse(json) as any;

// ✅ CORRECT: Use Schema for runtime validation
const data = Schema.decodeUnknownSync(DataSchema)(JSON.parse(json));
```

### Issue: "Rule is blocking legitimate code"

**Root cause:** Either rule is too strict, or code has legitimate exception

**Proper resolution:**
1. **If exception is legitimate:** Add override for specific file pattern
2. **If rule is truly problematic:** Propose rule modification with impact analysis
3. **Never weaken rule globally** - weaken only for legitimate exceptions

**Example:**
```json
// ❌ WRONG: Weaken rule globally
{
  "linter": {
    "rules": {
      "suspicious": {
        "noExplicitAny": "warn"  // Weakens for entire codebase
      }
    }
  }
}

// ✅ CORRECT: Override for specific files
{
  "overrides": [
    {
      "include": ["**/generated/**"],
      "linter": {
        "rules": {
          "suspicious": {
            "noExplicitAny": "off"  // Only for generated code
          }
        }
      }
    }
  ]
}
```

### Issue: "Pre-commit hook is blocking my commit"

**Symptoms:**
```
❌ Rule weakening detected in biome.json: error → warn
```

**Diagnosis:**
1. Run `git diff --cached` to see what changed
2. Identify which rule was weakened
3. Determine if this was intentional

**Resolution:**

If **intentional** (and approved):
```bash
git commit --no-verify -m "fix(linting): approved change - [explicit reason]"
```

If **accidental**:
```bash
git restore --staged biome.json
git restore biome.json
# Or manually revert the rule weakening
```

### Issue: "GritQL pattern is too aggressive"

**Symptoms:** Pattern triggers on legitimate code that shouldn't be flagged

**Resolution:**

1. **Add conditions to pattern** to be more specific:
```grit
// BEFORE: Too broad
`$value as any`

// AFTER: Only in test files
`$value as any` where {
  $file_path <: r"\.test\.(ts|tsx)$"
}
```

2. **Create override in Biome config:**
```json
{
  "overrides": [
    {
      "include": ["**/*.test.ts"],
      "linter": {
        "enabled": false  // Disable this GritQL pattern for tests
      }
    }
  ]
}
```

## References

- [Biome Documentation](https://biomejs.dev/)
- [GritQL Language Guide](https://docs.grit.io/language/overview)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Effect-TS Documentation](https://effect.website/)
- Root CLAUDE.md - General guardrails
- biome/CLAUDE.md - Type safety patterns with examples
