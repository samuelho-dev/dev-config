---
name: effect-service-architect
description: This skill should be used when the user asks to "build an Effect v4 service", "refactor Effect v4 services", "migrate Effect v3 services to v4", "upgrade a project to Effect v4", or work with v4 Context.Service definitions, layers, schema-backed tagged errors, scoped service resources, and Promise interop.
---

# Effect Service Architect (v4)

Build and migrate Effect applications against the installed Effect v4 API. Treat v4 as beta while `effect@beta` remains the published channel: inspect the installed version and local type declarations before relying on remembered APIs.

## Establish the Version Boundary

1. Inspect `package.json` and the lockfile before editing.
2. Upgrade with `effect@beta` when v4 is requested.
3. Keep every remaining `@effect/*` package on the exact same v4 version as `effect`.
4. Import consolidated stable modules from `effect` or `effect/*`.
5. Import unstable modules from `effect/unstable/*`; expect breaking changes between beta releases.
6. Treat the installed declarations and source maps for the lockfile-resolved `effect` version as the primary API authority.
7. When consulting GitHub, use the tag or commit matching the resolved version; use `main` only for explicitly unreleased changes:
   - <https://github.com/Effect-TS/effect>
   - <https://github.com/Effect-TS/effect/blob/main/MIGRATION.md>

## Define Services with `Context.Service`

Replace every v3 `Effect.Tag`, `Effect.Service`, `Context.Tag`, and `Context.GenericTag` declaration with `Context.Service`.

```typescript
import { Context, Effect, Layer } from "effect"

class Logger extends Context.Service<Logger, {
  readonly log: (message: string) => Effect.Effect<void>
}>()("app/Logger") {}

const loggerLayer = Layer.succeed(Logger, {
  log: (message) => Effect.sync(() => console.log(message))
})

class Greeter extends Context.Service<Greeter>()("app/Greeter", {
  make: Effect.gen(function*() {
    const logger = yield* Logger

    return {
      greet: (name: string) =>
        Effect.gen(function*() {
          const message = `Hello, ${name}`
          yield* logger.log(message)
          return message
        })
    }
  })
}) {
  static readonly layer = Layer.effect(this, this.make)
}

const applicationLayer = Greeter.layer.pipe(
  Layer.provide(loggerLayer)
)
```

Prefer `yield* Service` inside `Effect.gen` so dependencies remain explicit. Use `Service.use` for a short effectful callback and `Service.useSync` for a short pure callback only when that improves clarity.

## Build Layers Explicitly

- Name the primary layer `layer`; use descriptive variants such as `layerTest`.
- Use `Layer.succeed` for an existing implementation.
- Use `Layer.sync` for lazy synchronous construction.
- Use `Layer.effect` for effectful construction and dependencies.
- Use `Layer.scoped` for acquired resources requiring finalization.
- Compose dependencies with `Layer.provide`; the v3 `dependencies` service option no longer exists.
- Define layers explicitly; v4 does not generate `.Default` or `.Live` layers from a service.
- Wire application-wide dependencies at the composition root unless a self-contained layer is intentional.

## Model Typed Errors

Use `Data.TaggedError` for in-process domain errors. Use `Schema.TaggedErrorClass` when an error must also be encoded, decoded, or exposed across a boundary.

```typescript
import { Data, Effect, Schema } from "effect"

class RequestError extends Data.TaggedError("RequestError")<{
  readonly cause: unknown
}> {}

class NotFound extends Schema.TaggedErrorClass<NotFound>()("NotFound", {
  id: Schema.String
}) {}
```

Do not use v3 `Schema.TaggedError`; v4 renamed it to `Schema.TaggedErrorClass`.

Map promise failures into the typed error channel and propagate interruption through the supplied `AbortSignal`.

```typescript
const fetchUser = (id: string) =>
  Effect.tryPromise({
    try: (signal) => fetch(`/users/${id}`, { signal }),
    catch: (cause) => new RequestError({ cause })
  })
```

Keep defects distinct from expected failures. Never throw from an `Effect.tryPromise` `catch` mapper.

## Compose Effects with v4 APIs

- Use `pipe` for short linear transformations.
- Use `Effect.gen` and `yield*` for sequential logic and service access.
- Let TypeScript infer effect and layer types unless a public contract needs an annotation.
- Avoid native `try`/`catch` inside `Effect.gen`; use typed Effect combinators.
- Use `Effect.catch` instead of v3 `Effect.catchAll`.
- Use `Effect.catchCause` instead of v3 `Effect.catchAllCause`.
- Use `Effect.catchFilter` instead of v3 `Effect.catchSome`.
- Keep `Effect.catchTag` and `Effect.catchTags` for tagged domain errors.
- Preserve resource safety with scoped Effect and Layer constructors rather than manual cleanup.

## Migrate Without Compatibility Shims

Perform a clean cutover:

| Effect v3 | Effect v4 |
| --- | --- |
| `Effect.Tag` / `Context.Tag` / `Context.GenericTag` | `Context.Service` |
| `Effect.Service(..., { effect })` | `Context.Service(..., { make })` |
| generated `.Default` / `.Live` | explicit lowercase `.layer` |
| service `dependencies` option | `Layer.provide` |
| static accessor proxies | `yield* Service` or `Service.use` |
| `Effect.catchAll` | `Effect.catch` |
| `Effect.catchAllCause` | `Effect.catchCause` |
| `Effect.catchSome` | `Effect.catchFilter` |
| `Schema.TaggedError` | `Schema.TaggedErrorClass` |

Update every callsite and remove obsolete aliases, re-exports, and v3 imports. For broader Schema work, open `migration/schema.md` in the Effect repository at the same tag or commit as the installed version instead of guessing mechanical replacements.

## Verify

1. Run the project's TypeScript check, preferably with the Effect language-service plugin enabled.
2. Run focused tests covering service construction, layer composition, typed failures, interruption, and finalizers changed by the migration.
3. Confirm no migrated file still uses `Effect.Tag`, `Effect.Service`, `Context.Tag`, `Context.GenericTag`, generated `.Default` or `.Live` layers, the service `dependencies` option, `Effect.catchAll`, `Effect.catchAllCause`, `Effect.catchSome`, or the bare `Schema.TaggedError` constructor.
4. Confirm all Effect ecosystem packages resolve to the same v4 version.
