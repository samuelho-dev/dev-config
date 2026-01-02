---
name: type-safety-enforcer
description: Systematically eliminate type holes (as any, !, @ts-ignore) from the codebase. Use during audits or when hard guardrails are violated.
---

# Type-Safety Enforcer

## Instructions

1.  **Detection**:
    *   Run `grit check patternName="ban-type-assertions"` to find `as Type`, `as any`, and `!`.
    *   Run `grit check patternName="ban-ts-ignore"` to find suppression comments.
2.  **Context Analysis**: For each violation, analyze the surrounding code to determine the best remediation strategy.
3.  **Remediation**:
    *   **External Data**: Use `Schema.decodeUnknown` (Effect) to validate at the boundary.
    *   **Null Checks**: Replace `!` with proper `if (value != null)` guards or optional chaining `?.`.
    *   **Type Widening**: Replace `as any` with `unknown` and proper type narrowing.
    *   **Logic Errors**: If a cast is used to hide a bug, refactor the underlying logic.
4.  **Verification**:
    *   Run `tsc --noEmit` to ensure the codebase is clean.
    *   Verify that no new linting violations are introduced in `biome check`.

## Guardrails (CRITICAL)
- NEVER replace `as any` with another unsafe cast.
- ALWAYS prioritize runtime validation for external data.
