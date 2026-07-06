---
name: type-safety-enforcer
description: Systematically eliminate type holes (as any, !, @ts-ignore, satisfies) from a codebase. Use during audits or when the type-safety guardrails are violated.
---

# Type-Safety Enforcer

## Detection

- `biome check .` — runs Biome's `noExplicitAny` / `noNonNullAssertion` rules and the `ban-type-assertions` / `ban-return-types` GritQL plugins (`biome/gritql-patterns/`).
- `ai/hooks/enforce-type-safety.sh` (PostToolUse hook) blocks `as any`, `as T`, `!`, `@ts-ignore` / `@ts-expect-error` / `@ts-nocheck`, and bare `satisfies` at write time.
- Full rule table and policy: `docs/LINTING_POLICY.md`.

## Remediation

For each violation, read the surrounding code and pick the right fix:

- **External data** → validate at the boundary with `Schema.decodeUnknown` (Effect), not a cast.
- **Null checks** → replace `!` with an explicit `if (value != null)` guard or optional chaining `?.`.
- **Type widening** → replace `as any` with `unknown` plus proper narrowing.
- **Hidden bug** → if a cast masks a real type error, fix the underlying logic.

## Verification

- [ ] `biome check .` clean
- [ ] `tsc --noEmit` passes

## Guardrails (CRITICAL)

- NEVER replace one unsafe cast with another.
- ALWAYS prefer runtime validation for external data.
