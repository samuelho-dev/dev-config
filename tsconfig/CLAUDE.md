---
scope: tsconfig/
updated: 2025-12-21
relates_to:
  - ../CLAUDE.md
  - ../biome/CLAUDE.md
  - ../modules/home-manager/programs/typescript-strict.nix
validation:
  max_days_stale: 30
---

# TypeScript Configurations

Architectural guidance for strict TypeScript configurations.

## Purpose

This directory provides opinionated TypeScript configurations that enforce maximum type safety and modern best practices. These configs serve as base configurations that projects extend, ensuring consistent TypeScript behavior across the dev-config ecosystem.

## Architecture Overview

Three configuration tiers target different use cases:
- **strict**: Maximum type safety for application code
- **monorepo**: Nx/Turborepo workspace root configuration
- **library**: npm-publishable library configuration

All configs follow the principle of "beyond strict" - enabling additional compiler options that catch more bugs than TypeScript's default `strict: true`.

## File Structure

```
tsconfig/
+-- tsconfig.strict.json     # Maximum strictness for app code
+-- tsconfig.monorepo.json   # Nx/Turborepo workspace root
+-- tsconfig.library.json    # npm publishing with declarations
```

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Beyond strict options | tsconfig.strict.json:15-22 | Additional safety beyond `strict: true` |
| Bundler resolution | tsconfig.strict.json:25-31 | Modern ESM with bundler support |
| Workspace paths | tsconfig.monorepo.json | `baseUrl` + `paths` for monorepo imports |
| Declaration output | tsconfig.library.json | `declaration: true` for npm publishing |

## Configuration Reference

### tsconfig.strict.json

**Use case:** Maximum type safety for application code.

**Key options beyond `strict: true`:**

| Option | Purpose |
|--------|---------|
| `noUncheckedIndexedAccess` | Array/object access returns `T \| undefined` |
| `exactOptionalPropertyTypes` | Distinguish `undefined` from missing property |
| `noPropertyAccessFromIndexSignature` | Force bracket notation for index signatures |
| `noImplicitOverride` | Require `override` keyword |
| `noImplicitReturns` | All code paths must return |
| `useUnknownInCatchVariables` | Catch variables are `unknown`, not `any` |
| `verbatimModuleSyntax` | Enforce `import type` for type-only imports |

### tsconfig.monorepo.json

**Use case:** Nx/Turborepo workspace root configuration.

Extends `tsconfig.strict.json` with:
- `baseUrl: "."` for workspace-relative imports
- `paths: {}` placeholder for library aliases
- `composite: true` for project references
- `references: []` for incremental builds

### tsconfig.library.json

**Use case:** npm-publishable libraries.

Extends `tsconfig.strict.json` with:
- `declaration: true` for .d.ts files
- `declarationMap: true` for source maps
- `outDir: "./dist"` for build output
- `rootDir: "./src"` for source structure

## Adding/Modifying

### Using in a Project

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

Or use `init-workspace` command:
```bash
init-workspace  # Creates tsconfig.base.json with extends
```

### Adding New Options

1. Research option in TypeScript documentation
2. Add to appropriate config file
3. Include comment explaining purpose:
   ```json
   "newOption": true  // Explanation of what this catches
   ```
4. Test with real codebase
5. Update this documentation

### Creating New Config Variant

1. Create `tsconfig.<variant>.json`
2. Extend `tsconfig.strict.json` for base options
3. Add variant-specific options
4. Document in this CLAUDE.md

## Home Manager Integration

**Module:** `modules/home-manager/programs/typescript-strict.nix`

The module:
1. Symlinks configs to `~/.config/tsconfig/`
2. Allows projects to extend via absolute paths
3. Provides consistent TypeScript behavior across machines

## Common Issues

### Type errors after enabling strict

Many existing codebases will have type errors when switching to strict configs.

**Strategy:**
1. Start with `strict: true` only
2. Add beyond-strict options one at a time
3. Fix errors progressively
4. Use `@ts-expect-error` sparingly for known issues

### Module resolution errors

If imports fail with bundler resolution:
1. Check `moduleResolution: "bundler"` is set
2. Ensure bundler (Vite, esbuild, webpack) handles resolution
3. For Node.js direct execution, use `moduleResolution: "NodeNext"`

### exactOptionalPropertyTypes issues

This strict option can cause issues with third-party types:
```typescript
// Error: undefined is not assignable to missing property
interface Config {
  optional?: string;
}
const config: Config = { optional: undefined };  // Error!
```

**Fix:** Remove `undefined` assignment or use correct pattern:
```typescript
const config: Config = {};  // Correct - property is absent
```

## For Future Claude Code Instances

- [ ] Always extend from one of these configs, don't duplicate options
- [ ] Use `tsconfig.strict.json` as the base for maximum safety
- [ ] Include comments explaining non-obvious options
- [ ] Test config changes against real codebases
- [ ] Update `init-workspace` if adding new config variants
- [ ] Document breaking changes when modifying existing configs
