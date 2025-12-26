# Biome Configuration

Enterprise-grade linting and formatting for TypeScript monorepos.

## Quick Start

```bash
# Check all files
biome check .

# Auto-fix issues
biome check --write .

# Format only
biome format --write .
```

## Features

| Feature | Description |
|---------|-------------|
| **80+ strict rules** | Comprehensive TypeScript/JavaScript linting |
| **GritQL patterns** | Custom lint rules for Effect-TS and anti-patterns |
| **Zero config** | Works out of the box with sensible defaults |
| **Fast** | Written in Rust, 10-100x faster than ESLint |
| **Unified** | Replaces ESLint + Prettier with single tool |

## Configuration

### Project Setup

Reference the base config in your project's `biome.json`:

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.6/schema.json",
  "extends": ["~/.config/biome/biome.json"],
  "files": {
    "include": ["./src/**/*.ts", "./src/**/*.tsx"]
  }
}
```

With `lib.devShellHook` in your flake, `biome.json` is auto-created on `nix develop`.

### Key Rules

**Type Safety:**
- `noExplicitAny` - No `any` type
- `useImportType` - Use `import type` for type-only imports
- `useConsistentArrayType` - Use `T[]` over `Array<T>`

**Performance:**
- `noBarrelFile` - No barrel exports (improves tree-shaking)
- `noAccumulatingSpread` - Avoid spread in loops

**Style:**
- Single quotes, semicolons always
- 2-space indent, 100 char line width
- Trailing commas in multi-line

## GritQL Custom Patterns

Beyond built-in rules, custom GritQL patterns catch:

| Pattern | File | Issue |
|---------|------|-------|
| Missing `yield*` | `detect-missing-yield-star.grit` | Silent Effect.gen failures |
| `as any` | `ban-any-type-annotation.grit` | Type safety bypass |
| `satisfies` | `ban-satisfies.grit` | Type widening anti-pattern |
| Deep nesting | `enforce-effect-pipe.grit` | Should use pipe() |

## Usage Examples

### Migrate from ESLint

```bash
biome migrate eslint --write
```

### Migrate from Prettier

```bash
biome migrate prettier --write
```

### Check Specific Files

```bash
biome check src/index.ts
```

### Format Only

```bash
biome format --write src/
```

## Directory Structure

```
biome/
+-- biome-base.json       # Core configuration (80+ rules)
+-- gritql-patterns/      # Custom GritQL patterns
|   +-- ban-any-type-annotation.grit
|   +-- ban-satisfies.grit
|   +-- detect-missing-yield-star.grit
|   +-- enforce-effect-pipe.grit
|   +-- ... (12 patterns total)
+-- nx-plugin-template/   # Template for Nx integration
```

## Troubleshooting

### Rule not triggering

```bash
# Check rule configuration
biome explain <ruleName>
```

### Performance issues

Add to `files.ignore`:
```json
{
  "files": {
    "ignore": ["node_modules", "dist", ".nx"]
  }
}
```

### Override for test files

Test files allow `any`:
```json
{
  "overrides": [{
    "includes": ["**/*.test.ts"],
    "linter": {
      "rules": {
        "suspicious": { "noExplicitAny": "off" }
      }
    }
  }]
}
```

## Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Architecture details and rule reference
- [Biome Docs](https://biomejs.dev/) - Official documentation
- [GritQL Docs](https://docs.grit.io/) - Custom pattern syntax
