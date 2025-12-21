# AGENTS.md - Coding Agent Guidelines

## Commands
- `nix flake check` - Validate flake syntax
- `nix flake show --json` - Verify flake structure
- `nix fmt` - Format Nix files (alejandra)
- `home-manager build --flake .` - Test config without applying
- `home-manager switch --flake .` - Apply configuration
- `biome check .` - Lint/format TypeScript/JSON in biome/ directory
- `biome check --write .` - Auto-fix linting issues
- `bun test` - Run all tests in `.opencode/test/` (from .opencode/ directory)
- `bun test <file>` - Run single test (e.g., `bun test test/schemas.test.ts`)
- `bunx tsc --noEmit` - TypeScript type checking (from .opencode/ directory)

## Code Search & Refactoring Policy (STRICT - PROGRAMMATICALLY ENFORCED)
- **ONLY use GritQL tool** for code search, linting, and refactoring via `gritql` tool
- **Workflow:** `gritql check` (dry-run) → review diff → `gritql apply confirm=true`
- **BLOCKED TOOLS** (enforced by plugin): `grep`, `glob`, `find`, `edit`, `write`, `bash`
- **BLOCKED COMMANDS** (enforced by plugin): rg, grep -r, sed -i, perl -pi, awk gsub, jscodeshift, patch
- **ALLOWED TOOLS** (read-only/safe): `gritql`, `read`, `list`, `task`, `webfetch`, `todowrite`, `todoread`, `mlg`
- **Policy Enforcement:** The `gritql-guardrails` plugin will throw errors if you attempt to use blocked tools
- **Library creation:** Use `@mlg` tool (`@mlg dryRun` → review → `@mlg create confirm=true`)

## Code Style

### Nix (.nix files)
- ALWAYS use explicit `lib.` prefixes (NEVER `with lib;`)
- Alphabetical parameters: `{ config, lib, pkgs, inputs, ... }`
- Use `lib.mkEnableOption` for optional features
- Use `lib.mkIf` for conditional config
- Format with `alejandra` (2-space indent)
- Use `inputs ? dev-config` pattern for flake composition

### TypeScript/JavaScript (biome.json)
- Single quotes, semicolons always, trailing commas
- 2-space indent, 100 char line width
- `import type` for type-only imports
- NO `any` type, NO `as any` assertions, NO `satisfies` keyword
- Prefer `T[]` over `Array<T>`
- Use `node:` protocol for Node.js imports (e.g., `node:fs`)
- Named exports only (except index.ts and *.config.ts)
- Test files: Use `bun:test` (describe/test/expect) - `any` allowed in tests only

### Effect-TS Patterns
- CRITICAL: Use `yield*` in `Effect.gen` (missing `yield*` causes silent failures)
- Deep nesting (3+ levels): Use `pipe()` for composition
- Example: `pipe(Effect.succeed(1), Effect.map(x => x + 1))`

### Naming & Error Handling
- camelCase for variables/functions, PascalCase for types/classes
- Descriptive names: `getUserById` not `getUser`
- Effect-TS error handling: Use typed errors, avoid throwing exceptions
