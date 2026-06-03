# Biome & Strict Linting Guide

Comprehensive guide to Biome integration and the strict linting rules in dev-config,
covering setup, TypeScript type safety, Effect-TS patterns, infrastructure validation,
and code quality enforcement.

> For the AI guardrails and rule-modification policy (what may/may not be weakened,
> the `APPROVE` workflow), see [docs/LINTING_POLICY.md](../LINTING_POLICY.md).

## Overview

This configuration provides:

- **80+ Biome rules** for strict TypeScript/JavaScript linting
- **GritQL custom patterns** for Effect-TS and async safety
- **TypeScript strict configs** beyond `strict: true`
- **IaC validation** for Kubernetes, Terraform, Dockerfiles, GitHub Actions
- **Pre-commit hooks** for automated enforcement

[Biome](https://biomejs.dev/) is a fast (Rust-based) formatter and linter for
JavaScript, TypeScript, JSX/TSX, JSON/JSONC, CSS, and GraphQL. It provides type-aware
linting without the TypeScript compiler, custom GritQL patterns, and native VCS
integration (respects `.gitignore`).

## How It Works

1. **Project root `biome.json`** is the **source of truth** for all Biome rules —
   self-contained, portable, and editor-agnostic.
2. **Nix sync** (`modules/home-manager/programs/biome.nix`) symlinks `biome.json` to
   `~/.config/biome/biome.json`, symlinks GritQL patterns to
   `~/.config/biome/gritql-patterns/`, and installs the `biome` package.
3. **Editor integration** references the root `biome.json` directly (no `extends` needed).
4. **Pre-commit hooks** run Biome on staged JS/TS/JSON files.

## Quick Start

```bash
# Apply all linting configurations
home-manager switch --flake ~/Projects/dev-config

# Verify tools are available
biome --version
hadolint --version
actionlint --version

# Inspect the exported config and patterns
cat ~/.config/biome/biome.json
ls ~/.config/biome/gritql-patterns/
```

### Enable / Customize in home.nix

```nix
dev-config = {
  enable = true;

  biome = {
    enable = true;

    formatter = {
      lineWidth = 120;
      indentWidth = 4;
    };

    javascript.formatter = {
      quoteStyle = "double";
      semicolons = "asNeeded";
    };

    gritql.enable = true;

    extraConfig = {
      overrides = [
        {
          include = ["**/*.test.ts"];
          linter.rules.suspicious.noExplicitAny = "off";
        }
      ];
    };
  };
};
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

### Biome Module Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | true | Enable Biome module |
| `package` | package | pkgs.biome | Biome package |
| `exportConfig` | bool | true | Export to ~/.config/biome/ |
| `vcs.enable` | bool | true | Enable VCS integration |
| `vcs.useIgnoreFile` | bool | true | Respect .gitignore |
| `formatter.enable` | bool | true | Enable formatter |
| `formatter.indentStyle` | enum | "space" | Tab or space |
| `formatter.indentWidth` | int | 2 | Indent width |
| `formatter.lineWidth` | int | 100 | Max line width |
| `linter.enable` | bool | true | Enable linter |
| `linter.rules` | attrs | recommended | Linter rules |
| `javascript.formatter.quoteStyle` | enum | "single" | Quote style |
| `javascript.formatter.semicolons` | enum | "always" | Semicolons |
| `javascript.formatter.trailingCommas` | enum | "all" | Trailing commas |
| `json.parser.allowComments` | bool | true | JSONC support |
| `gritql.enable` | bool | true | Enable GritQL patterns |
| `extraConfig` | attrs | {} | Additional Biome config |

## Consumer Project Setup

### Nx Monorepo

**1. Create a root `biome.json`** by copying dev-config's `biome.json` as a starting
point (it is self-contained — no `extends` required).

**2. Copy the Nx plugin template:**

```bash
cp ~/.config/biome/nx-plugin-template/biome-plugin.ts ./tools/biome-plugin.ts
```

**3. Register it in `nx.json`:**

```json
{
  "plugins": [
    {
      "plugin": "./tools/biome-plugin",
      "options": {
        "checkTargetName": "biome-check",
        "lintTargetName": "biome-lint",
        "formatTargetName": "biome-format",
        "ciTargetName": "biome-ci"
      }
    }
  ]
}
```

**4. Optionally add package-level overrides** in a nested `biome.json`:

```json
{
  "linter": {
    "rules": {
      "suspicious": { "noConsole": "off" }
    }
  }
}
```

### Simple Project

Copy the full config from dev-config's `biome.json` to the project root and customize
as needed. Configuration is self-contained — no `extends` required.

## CLI Usage

```bash
biome check .              # Check without writing
biome check --write .      # Format + lint with fixes
biome lint .               # Lint only
biome format --write .     # Format only
biome ci .                 # CI mode (strict, no writes)
biome check --changed      # Only changed files (VCS integration)
biome check --staged       # Only staged files
```

## VS Code Integration

**`.vscode/settings.json`:**

```json
{
  "editor.defaultFormatter": "biomejs.biome",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "quickfix.biome": "explicit",
    "source.organizeImports.biome": "explicit"
  },
  "[javascript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[typescript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[json]": { "editor.defaultFormatter": "biomejs.biome" },
  "[jsonc]": { "editor.defaultFormatter": "biomejs.biome" },
  "biome.lspBin": "./node_modules/@biomejs/biome/bin/biome"
}
```

**`.vscode/extensions.json`:**

```json
{
  "recommendations": ["biomejs.biome"],
  "unwantedRecommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode"
  ]
}
```

## GritQL Custom Patterns

Custom lint rules using [GritQL](https://biomejs.dev/reference/gritql/), shipped in
`biome/gritql-patterns/` and synced to `~/.config/biome/gritql-patterns/`:

| Pattern | Severity | Description |
|---------|----------|-------------|
| `ban-type-assertions.grit` | error | Prevents `as T`, `<T>expr`, and `satisfies T` |
| `ban-return-types.grit` | error | Enforces type inference (except type guards) |
| `ban-push-spread.grit` | error | Prevents `array.push(...items)` pattern |
| `ban-default-export-non-index.grit` | warn | Discourages default exports outside index files |
| `ban-imperative-error-handling-in-effect.grit` | error | Forces Effect-style error handling |
| `detect-missing-yield-star.grit` | error | Catches missing `yield*` in Effect generators |
| `detect-unhandled-effect-promise.grit` | error | Catches unhandled Effect promises |
| `enforce-effect-pipe.grit` | error | Enforces `pipe()` for Effect chains |
| `prefer-object-spread.grit` | warn | Recommends spread over `Object.assign()` |

> Note: `ban-type-assertions.grit` is a single file containing three patterns
> (`as T`, `<T>expr`, `satisfies T`). Older docs that referenced separate
> `ban-satisfies.grit` / `ban-ts-ignore.grit` / `ban-non-null-assertions.grit` files
> were stale — those patterns were either consolidated here or replaced by Biome's
> native rules (`noNonNullAssertion`) or the pre-commit source scan in
> `scripts/validate-linting-config.sh` (`@ts-ignore` family).

### Using GritQL Patterns

Add to your project's `biome.json`:

```json
{
  "plugins": [
    "~/.config/biome/gritql-patterns/ban-type-assertions.grit",
    "~/.config/biome/gritql-patterns/ban-return-types.grit"
  ]
}
```

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

## Pre-commit Hooks

### Automatic Enforcement

All hooks run automatically on `git commit`:

```yaml
repos:
  - repo: local
    hooks:
      - id: biome-check        # JS/TS/JSON
      - id: nix-fmt             # Nix formatting
      - id: nix-flake-check     # Nix validation
      - id: validate-linting-config  # AI guardrails
```

### Running Manually

```bash
# All hooks
pre-commit run --all-files

# Specific hook
pre-commit run biome-check --all-files
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

**Patterns not loading:**

```bash
# Check the symlink and that source patterns exist
ls -la ~/.config/biome/gritql-patterns/
ls ~/Projects/dev-config/biome/gritql-patterns/
```

### Biome Not Found or Config Out of Date

```bash
# Re-apply Home Manager (installs biome, re-syncs ~/.config/biome/biome.json)
home-manager switch --flake ~/Projects/dev-config

# Or enter the devShell
nix develop

# Verify
biome --version
cat ~/.config/biome/biome.json
```

For performance on large repos, add big directories to `files.ignore`, use `--changed`
/ `--staged` for incremental checks, and keep VCS integration enabled (`vcs.enable = true`).

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
| `.pre-commit-config.yaml` | Pre-commit hooks |
| `pkgs/default.nix` | Linting tool packages |

### External Resources

- [Biome Documentation](https://biomejs.dev/)
- [GritQL Playground](https://grit.io/playground)
- [Effect-TS Guidelines](https://effect.website/)
- [Hadolint Rules](https://github.com/hadolint/hadolint#rules)
- [TFLint Rules](https://github.com/terraform-linters/tflint/tree/master/docs/rules)
