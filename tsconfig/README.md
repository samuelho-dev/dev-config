# TypeScript Configurations

Strict TypeScript configurations for maximum type safety.

## Quick Start

Extend a config in your project's `tsconfig.json`:

```json
{
  "extends": "~/.config/tsconfig/tsconfig.strict.json",
  "compilerOptions": {
    "rootDir": "./src",
    "outDir": "./dist"
  },
  "include": ["src"]
}
```

Or use `init-workspace` to auto-generate:
```bash
init-workspace
```

## Available Configurations

| Config | Use Case | Description |
|--------|----------|-------------|
| `tsconfig.strict.json` | Application code | Maximum type safety with "beyond strict" options |
| `tsconfig.monorepo.json` | Workspace root | Nx/Turborepo with project references |
| `tsconfig.library.json` | npm packages | Declaration files for publishing |

## Beyond-Strict Options

These configs enable additional safety options beyond TypeScript's `strict: true`:

| Option | What It Catches |
|--------|-----------------|
| `noUncheckedIndexedAccess` | Unsafe array/object indexing |
| `exactOptionalPropertyTypes` | `undefined` vs missing property confusion |
| `noPropertyAccessFromIndexSignature` | Unsafe dot notation on index signatures |
| `noImplicitOverride` | Missing `override` keyword on subclass methods |
| `noImplicitReturns` | Functions without return statements |
| `useUnknownInCatchVariables` | `any` type in catch blocks |
| `verbatimModuleSyntax` | Missing `import type` for type-only imports |

## Configuration Details

### tsconfig.strict.json

For application code with maximum type safety:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitOverride": true,
    "noImplicitReturns": true,
    "useUnknownInCatchVariables": true,
    "verbatimModuleSyntax": true,
    "moduleResolution": "bundler",
    "module": "ESNext",
    "target": "ESNext"
  }
}
```

### tsconfig.monorepo.json

For Nx/Turborepo workspace roots:

```json
{
  "extends": "./tsconfig.strict.json",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {},
    "composite": true
  },
  "references": []
}
```

### tsconfig.library.json

For npm-publishable libraries:

```json
{
  "extends": "./tsconfig.strict.json",
  "compilerOptions": {
    "declaration": true,
    "declarationMap": true,
    "outDir": "./dist",
    "rootDir": "./src"
  }
}
```

## Usage Examples

### New Application

```json
{
  "extends": "~/.config/tsconfig/tsconfig.strict.json",
  "compilerOptions": {
    "rootDir": "./src",
    "outDir": "./dist",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

### Monorepo Workspace

```json
{
  "extends": "~/.config/tsconfig/tsconfig.monorepo.json",
  "compilerOptions": {
    "paths": {
      "@myorg/shared": ["libs/shared/src/index.ts"],
      "@myorg/api": ["apps/api/src/index.ts"]
    }
  },
  "references": [
    { "path": "libs/shared" },
    { "path": "apps/api" }
  ]
}
```

### npm Library

```json
{
  "extends": "~/.config/tsconfig/tsconfig.library.json",
  "compilerOptions": {
    "rootDir": "./src",
    "outDir": "./dist"
  },
  "include": ["src"],
  "exclude": ["**/*.test.ts"]
}
```

## Troubleshooting

### Type errors after enabling strict

**Strategy:** Enable options incrementally:
1. Start with just `strict: true`
2. Add `noUncheckedIndexedAccess`
3. Fix errors before adding more options
4. Use `@ts-expect-error` sparingly for known issues

### Module resolution errors

For bundler-based projects (Vite, esbuild):
```json
{
  "compilerOptions": {
    "moduleResolution": "bundler"
  }
}
```

For Node.js direct execution:
```json
{
  "compilerOptions": {
    "moduleResolution": "NodeNext",
    "module": "NodeNext"
  }
}
```

### exactOptionalPropertyTypes issues

```typescript
// This causes an error:
interface Config {
  optional?: string;
}
const config: Config = { optional: undefined }; // Error!

// Fix: omit the property instead
const config: Config = {}; // Correct
```

## File Structure

```
tsconfig/
+-- tsconfig.strict.json     # Maximum strictness for app code
+-- tsconfig.monorepo.json   # Nx/Turborepo workspace root
+-- tsconfig.library.json    # npm publishing with declarations
+-- CLAUDE.md                # Architecture documentation
+-- README.md                # This file
```

## Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Architecture details
- [Biome Configuration](../biome/README.md) - Companion linting
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/) - Official docs
