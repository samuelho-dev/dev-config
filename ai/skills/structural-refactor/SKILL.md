---
name: structural-refactor
description: Perform codebase-wide structural transformations using GritQL patterns. Use when regular regex find/replace is too risky or when targeting complex AST structures.
---

# Structural Refactor (GritQL)

## Instructions

1.  **Identify Target**: Clearly define the structural anti-pattern you want to fix (e.g., "nested Effect calls", "manual type assertions").
2.  **Pattern Discovery**:
    *   List existing repo patterns using `gritql listPatterns`.
    *   Check `biome/gritql-patterns/` for a matching `.grit` file.
3.  **Dry Run**:
    *   Execute a dry run using `grit check --dry-run` or the `gritql` tool with `command: "checkPattern"`.
    *   Review the unified diff to ensure the transformation logic is sound.
4.  **Execution**:
    *   Apply the transformation using `grit apply` or the `gritql` tool with `command: "applyPattern"`.
    *   Provide the `runId` from the dry run if the policy is `strict`.
5.  **Verification**:
    *   Run `nix develop --command grit check` to ensure no new violations were introduced.
    *   Run `bun test` to confirm functional parity.

## Example
"Refactor all nested Effect calls to use `pipe()` in `libs/feature-payments`."
1. Use `gritql` tool with `patternName: "enforce-effect-pipe"`.
2. Review dry-run diff.
3. Apply fixes.
