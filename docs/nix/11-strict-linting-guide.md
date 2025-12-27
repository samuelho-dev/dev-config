# Strict Linting Guide

Comprehensive guide to the enhanced strict linting rules in dev-config, covering TypeScript type safety, Effect-TS patterns, infrastructure validation, and code quality enforcement.

## Overview

This configuration provides:

- **80+ Biome rules** for strict TypeScript/JavaScript linting
- **GritQL custom patterns** for Effect-TS and async safety
- **TypeScript strict configs** beyond `strict: true`
- **IaC validation** for Kubernetes, Terraform, Dockerfiles, GitHub Actions
- **Pre-commit hooks** for automated enforcement

## Quick Start

```bash
# Apply all linting configurations
home-manager switch --flake ~/Projects/dev-config

# Verify tools are available
biome --version
hadolint --version
actionlint --version
```

## Philosophy: Direct Equality

We prioritize **enforcing correct patterns** (`use*` rules) over **banning wrong patterns** (`no*` rules):

| Approach | Example | Why |
|----------|---------|-----|
| ✅ Direct Equality | `useImportType: error` | Enforces `import type { X }` |
| ⚠️ Backstop | `noCommonJs: error` | Bans `require()` as safety net |

This reduces cognitive load - developers learn what TO do, not what NOT to do.

## TypeScript Configuration

TypeScript strict settings should be configured in each project's `tsconfig.base.json`. Recommended strict options:

```json
{
  "noUncheckedIndexedAccess": true,    // arr[0] returns T | undefined
  "exactOptionalPropertyTypes": true,   // Optional props can't be undefined
  "noPropertyAccessFromIndexSignature": true,
  "noImplicitOverride": true,           // Explicit override keyword
  "useUnknownInCatchVariables": true    // catch(e: unknown) not any
}
```

**Trade-offs:**

- `noUncheckedIndexedAccess` - Requires null checks for all array access
- `exactOptionalPropertyTypes` - May break existing `{ prop?: T }` patterns

## Biome Configuration

### Key Rules by Category

#### Performance (75% Build Improvement)

```json
{
  "noBarrelFile": "error",     // Ban index.ts re-exports
  "noReExportAll": "error",    // Ban export * from
  "noAccumulatingSpread": "error"  // Ban spreading in loops
}
```

**Why barrel files are banned:** Atlassian achieved 75% faster builds by eliminating barrel files. They cause unnecessary module loading and break tree-shaking.

#### ESM Enforcement

```json
{
  "useImportType": "error",        // import type { X }
  "useExportType": "error",        // export type { X }
  "useNodejsImportProtocol": "error",  // import 'node:fs'
  "noCommonJs": "error"            // Ban require()
}
```

#### Complexity Control

```json
{
  "noExcessiveCognitiveComplexity": {
    "level": "error",
    "options": { "maxAllowedComplexity": 15 }
  }
}
```

Cognitive complexity > cyclomatic complexity because it accounts for nesting depth.

### Extending Biome Config

```json
{
  "$schema": "https://biomejs.dev/schemas/2.3.8/schema.json",
  "extends": ["~/.config/biome/biome.json"],
  "linter": {
    "rules": {
      "suspicious": {
        "noConsole": "off"  // Override for development
      }
    }
  }
}
```

### Overrides for Specific Files

```json
{
  "overrides": [
    {
      "includes": ["**/*.test.ts"],
      "linter": {
        "rules": {
          "suspicious": {
            "noExplicitAny": "off"
          }
        }
      }
    }
  ]
}
```

## GritQL Custom Patterns

### Effect-TS Patterns

#### Deep Nesting Detection

```grit
`Effect.$m1(Effect.$m2(Effect.$m3($args)))` where {
  register_diagnostic(
    message = "Use Effect.pipe() for composition",
    severity = "error"
  )
}
```

**Example:**

```typescript
// ❌ Bad - flagged
const result = Effect.map(Effect.flatMap(Effect.succeed(x), f), g);

// ✅ Good
const result = Effect.pipe(
  Effect.succeed(x),
  Effect.flatMap(f),
  Effect.map(g)
);
```

#### Missing yield* Detection (CRITICAL)

This pattern prevents one of the most common Effect-TS bugs:

```typescript
// ❌ Bad - x is Effect<number>, not number!
Effect.gen(function* () {
  const x = Effect.succeed(42);
  //    ^ x is Effect, not the value
});

// ✅ Good - x is number
Effect.gen(function* () {
  const x = yield* Effect.succeed(42);
});
```

### GritQL Limitations

> ⚠️ **Expert Validated:** GritQL provides ~60-70% coverage for Effect-TS patterns. It cannot access TypeScript type information, so type-aware rules like "Effect not awaited" are not possible. For production codebases, consider adding `@effect/eslint-plugin`.

## Infrastructure Linting

### Kubernetes (kube-linter)

```bash
# Run manually
kube-linter lint --config iac-linting/.kube-linter.yaml deploy/

# What it checks:
# - Resource limits required
# - No :latest tags
# - No privileged containers
# - Run as non-root (warning)
```

### Dockerfiles (Hadolint)

```bash
# Run manually
hadolint --config iac-linting/.hadolint.yaml Dockerfile

# What it checks:
# - Image version pinning (DL3006, DL3007)
# - Package version pinning (DL3008, DL3018)
# - No :latest tag
# - COPY instead of ADD
```

### Terraform (TFLint)

```bash
# Run manually
tflint --config iac-linting/.tflint.hcl

# What it checks:
# - snake_case naming convention
# - Documented variables and outputs
# - Module source pinning
# - Deprecated syntax
```

### GitHub Actions (actionlint)

```bash
# Run manually
actionlint .github/workflows/*.yaml

# What it checks:
# - Syntax errors
# - Invalid action references
# - Shellcheck for run: blocks
# - Expression validation
```

## Pre-commit Hooks

### Automatic Enforcement

All hooks run automatically on `git commit`:

```yaml
repos:
  - repo: local
    hooks:
      - id: biome-check        # JS/TS/JSON
      - id: kube-linter        # Kubernetes
      - id: hadolint           # Dockerfiles
      - id: tflint             # Terraform
      - id: actionlint         # GitHub Actions
      - id: gitleaks           # Secret detection
```

### Running Manually

```bash
# All hooks
pre-commit run --all-files

# Specific hook
pre-commit run biome-check --all-files
pre-commit run kube-linter --all-files
```

## Migration Guide

### From ESLint

1. Remove ESLint config files (`.eslintrc.*`)
2. Remove ESLint dependencies from `package.json`
3. Update scripts:
   ```json
   {
     "scripts": {
       "lint": "biome check .",
       "lint:fix": "biome check --write ."
     }
   }
   ```
4. Extend from dev-config Biome config:
   ```json
   {
     "extends": ["~/.config/biome/biome.json"]
   }
   ```

### Handling Barrel Files

If your codebase uses barrel files:

1. **Option 1:** Disable temporarily:
   ```json
   {
     "overrides": [
       {
         "includes": ["**/index.ts"],
         "linter": {
           "rules": {
             "performance": { "noBarrelFile": "off" }
           }
         }
       }
     ]
   }
   ```

2. **Option 2:** Migrate incrementally:
   - Replace `export * from` with explicit exports
   - Move exports directly to consumer modules
   - Run `biome check --write` to fix import paths

### Handling strictNullChecks

If enabling `noUncheckedIndexedAccess`:

```typescript
// Before
const first = arr[0];  // T

// After - requires null check
const first = arr[0];  // T | undefined
if (first !== undefined) {
  // first is T
}

// Or use optional chaining
const value = arr[0]?.property;
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Lint
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - run: nix develop -c pre-commit run --all-files
```

### Pre-merge Checks

```yaml
# Required checks
- biome-check
- kube-linter
- hadolint
- tflint
- actionlint
- gitleaks
```

## Troubleshooting

### Biome Rule Errors

**"Rule X does not exist":**

Check Biome version matches schema:
```json
{
  "$schema": "https://biomejs.dev/schemas/2.3.8/schema.json"
}
```

**Performance issues:**

Use `--diagnostic-level=error` to skip warnings during development.

### Pre-commit Hook Failures

**"command not found":**

Ensure Nix devShell is active:
```bash
nix develop
pre-commit run --all-files
```

**Hook taking too long:**

Skip specific hooks for quick commits:
```bash
SKIP=kube-linter git commit -m "WIP"
```

### GritQL Pattern Errors

**Pattern not matching:**

GritQL uses JavaScript AST, not TypeScript. Some TS-specific syntax may not match. Test patterns at https://grit.io/playground.

## Reference

### Rule Severity Guide

| Severity | Meaning | Auto-fixable |
|----------|---------|--------------|
| `error` | Must fix before commit | Most |
| `warn` | Should fix, not blocking | Some |
| `info` | Informational | No |

### Key Files

| File | Purpose |
|------|---------|
| `biome.json` | Biome rule configuration (source of truth) |
| `biome/gritql-patterns/*.grit` | Custom GritQL rules |
| `iac-linting/*` | Infrastructure linting configs |
| `.pre-commit-config.yaml` | Pre-commit hooks |
| `pkgs/default.nix` | Linting tool packages |

### External Resources

- [Biome Documentation](https://biomejs.dev/)
- [GritQL Playground](https://grit.io/playground)
- [Effect-TS Guidelines](https://effect.website/)
- [KubeLinter Checks](https://docs.kubelinter.io/)
- [Hadolint Rules](https://github.com/hadolint/hadolint#rules)
- [TFLint Rules](https://github.com/terraform-linters/tflint/tree/master/docs/rules)
