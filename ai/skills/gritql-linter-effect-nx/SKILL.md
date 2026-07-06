---
name: gritql-linter-effect-nx
description: GritQL lint patterns for Effect-TS and strict TypeScript, run as Biome plugins. Use to check type-safety, Effect error-handling, and code-style violations.
---

# GritQL Lint Patterns (Biome plugins)

This repo ships GritQL patterns as **Biome plugins**, not as a standalone `grit`
CLI. They live in `biome/gritql-patterns/*.grit` and are registered in the root
`biome.json` `plugins` array, so `biome check` runs them alongside Biome's own
rules.

## Running

```bash
biome check .            # report all violations (Biome rules + GritQL plugins)
biome check --write .    # apply Biome's safe autofixes
```

The pre-commit hook and `ai/hooks/biome-validate.sh` run `biome check` on changed
files; violations block the commit (see `docs/LINTING_POLICY.md`).

## Patterns

Nine patterns, all in `biome/gritql-patterns/` and listed in `biome.json`:

**Type safety & style**
- `ban-type-assertions` — `as T` / `as any` / `satisfies` casts
- `ban-return-types` — explicit return-type annotations (prefer inference)
- `prefer-object-spread` — object spread over `Object.assign`

**Effect-TS**
- `ban-imperative-error-handling-in-effect` — `throw` / try-catch / Promise primitives inside Effect
- `detect-missing-yield-star` — missing `yield*` in `Effect.gen`
- `detect-unhandled-effect-promise` — `Effect.tryPromise` without a typed `catch`
- `enforce-effect-pipe` — deeply nested Effect calls (prefer `pipe`)

**General**
- `ban-default-export-non-index` — default exports outside index files
- `ban-push-spread` — `arr.push(...spread)` (stack-overflow risk on large arrays)

Read the individual `.grit` files for the exact matcher and rationale.

## Remediation

- **Type assertions** → validate external data with `Schema.decodeUnknown` (Effect); narrow with type guards; fix the underlying type instead of casting. See the `type-safety-enforcer` skill.
- **Effect error handling** → `Effect.tryPromise({ try, catch })`, always `yield*` inside `Effect.gen`, compose with `pipe`. See the `effect-service-architect` skill.
- **Style** → apply the mechanical fix the pattern names.

Biome GritQL plugins are **diagnostic only** — they report, they do not rewrite.
Apply fixes by hand, with `biome check --write` for Biome's own safe fixes, or
with `ast-grep` for structural codemods.

## Verification

- [ ] `biome check .` clean
- [ ] `tsc --noEmit` passes
- [ ] tests pass (`bun test` or the project's command)

## Related skills

- `type-safety-enforcer` — eliminate `as any` / `!` / `@ts-ignore`
- `effect-service-architect` — scaffold and refactor Effect services
