---
name: effect-service-architect
description: Expertly scaffold and refactor Effect-based services and layers following v3 standards. Use when creating new backend logic or migrating from Promise-based code.
---

# Effect Service Architect (v3)

## Instructions

1.  **Service Tag**: Define the service using `Effect.Tag`.
    ```typescript
    export class MyService extends Effect.Tag("MyService")<MyService, {
      readonly getData: () => Effect.Effect<Data, MyError>
    }>() {}
    ```
2.  **Implementation**: Create the `Live` layer using `Layer.effect` or `Layer.succeed`.
    ```typescript
    export const MyServiceLive = Layer.effect(
      MyService,
      Effect.gen(function* () {
        // Implementation logic
        return {
          getData: () => Effect.succeed({ ... })
        }
      })
    )
    ```
3.  **Error Handling**: Use `Data.TaggedError` for all domain-specific errors.
    ```typescript
    export class MyError extends Data.TaggedError("MyError")<{
      readonly message: string
    }> {}
    ```
4.  **Composition**: Use `pipe` for simple flows and `Effect.gen` with `yield*` for complex sequential logic.
5.  **Verification**:
    *   Run `tsc --noEmit` to verify type inference.
    *   Ensure all `Effect.tryPromise` calls include a `catch` block for typed errors.

## Patterns to Enforce
- NO explicit return type annotations unless necessary (let inference work).
- NO `try/catch` blocks inside `Effect.gen` (use `Effect.catchAll` etc.).
- ALWAYS use `yield*` when calling an Effect inside `Effect.gen`.
