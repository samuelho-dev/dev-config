# Biome Integration Guide

## Overview

dev-config provides a shareable Biome configuration that standardizes linting and formatting across all consuming projects. The project root `biome.json` is the **source of truth**, and Nix syncs it to `~/.config/biome/biome.json` for editor use.

## What is Biome?

[Biome](https://biomejs.dev/) is a fast formatter and linter for JavaScript, TypeScript, JSON, and more. It's written in Rust and provides:

- **10-20x faster** performance than ESLint/Prettier
- **Multi-language support**: JS, TS, JSX, TSX, JSON, JSONC, CSS, GraphQL
- **Type-aware linting** without TypeScript compiler overhead
- **GritQL custom patterns** for project-specific rules
- **Native VCS integration** (respects `.gitignore`)

## How It Works

1. **Project Root Config** (`biome.json`)
    - Source of truth for all Biome rules
    - Contains complete linting and formatting configuration
    - Project-based, portable, and editor-agnostic

2. **Nix Sync** (`modules/home-manager/programs/biome.nix`)
    - Symlinks `biome.json` to `~/.config/biome/biome.json`
    - Symlinks GritQL patterns to `~/.config/biome/gritql-patterns/`
    - Installs `biome` package to user environment

3. **Editor Integration**
    - All editors reference the root `biome.json` file directly
    - No extends needed - configuration is self-contained

4. **Pre-commit Hook** runs Biome on staged JS/TS/JSON files

## Installation

### Already Using dev-config

If you have dev-config activated via Home Manager, Biome is already installed and configured:

```bash
# Verify installation
biome --version

# Check exported config
cat ~/.config/biome/biome.json

# List GritQL patterns
ls ~/.config/biome/gritql-patterns/
```

### Enable/Customize in home.nix

```nix
dev-config = {
  enable = true;

  biome = {
    enable = true;

    # Customize formatter
    formatter = {
      lineWidth = 120;
      indentWidth = 4;
    };

    # Customize JavaScript settings
    javascript.formatter = {
      quoteStyle = "double";
      semicolons = "asNeeded";
    };

    # Enable GritQL patterns
    gritql.enable = true;

    # Add extra configuration
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

## Consumer Project Setup

### Nx Monorepo (e.g., ai-dev-env)

**1. Create root `biome.json`:**

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "extends": ["~/.config/biome/biome.json"],
  "plugins": [
    "~/.config/biome/gritql-patterns/ban-satisfies.grit",
    "~/.config/biome/gritql-patterns/ban-type-assertions.grit"
  ],
  "files": {
    "include": ["packages/**", "apps/**", "libs/**"]
  }
}
```

**2. Copy Nx plugin template:**

```bash
cp ~/.config/biome/nx-plugin-template/biome-plugin.ts ./tools/biome-plugin.ts
```

**3. Register in `nx.json`:**

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

**4. Create package-level configs (optional):**

```json
{
  "extends": "//",
  "linter": {
    "rules": {
      "suspicious": { "noConsoleLog": "off" }
    }
  }
}
```

### Simple Project

```json
{
  "extends": ["~/.config/biome/biome.json"]
}
```

## Available GritQL Patterns

Custom lint rules using [GritQL](https://biomejs.dev/reference/gritql/):

| Pattern | Severity | Description |
|---------|----------|-------------|
| `ban-satisfies.grit` | error | Prevents TypeScript `satisfies` operator |
| `ban-return-types.grit` | error | Enforces type inference (except type guards) |
| `ban-type-assertions.grit` | error | Prevents `as` and angle-bracket assertions |
| `ban-push-spread.grit` | error | Prevents `array.push(...items)` pattern |
| `prefer-object-spread.grit` | warn | Recommends spread over `Object.assign()` |

### Using GritQL Patterns

Add to your project's `biome.json`:

```json
{
  "plugins": [
    "~/.config/biome/gritql-patterns/ban-satisfies.grit",
    "~/.config/biome/gritql-patterns/ban-type-assertions.grit"
  ]
}
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
  "[javascript]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
  "[typescript]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
  "[json]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
  "[jsonc]": {
    "editor.defaultFormatter": "biomejs.biome"
  },
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

## CLI Usage

```bash
# Check without writing
biome check .

# Format and lint with fixes
biome check --write .

# Lint only
biome lint .

# Format only
biome format --write .

# CI mode (strict, no writes)
biome ci .

# Check only changed files (VCS integration)
biome check --changed

# Check only staged files
biome check --staged
```

## Module Options Reference

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

## Troubleshooting

### Biome not found

```bash
# Rebuild Home Manager
home-manager switch --flake ~/Projects/dev-config

# Or enter devShell
nix develop
```

### Config not updated

```bash
# Force regenerate
home-manager switch --flake ~/Projects/dev-config

# Verify
cat ~/.config/biome/biome.json
```

### GritQL patterns not loading

```bash
# Check symlink
ls -la ~/.config/biome/gritql-patterns/

# Verify patterns exist in dev-config
ls ~/Projects/dev-config/biome/gritql-patterns/
```

### Performance issues

- Add large directories to `files.ignore`
- Use `--changed` or `--staged` flags for incremental checks
- Ensure VCS integration is enabled (`vcs.enable = true`)

## Migration from ESLint/Prettier

1. **Run Biome migration tool:**
   ```bash
   npx @biomejs/biome migrate eslint --write
   ```

2. **Keep ESLint for Nx module boundaries only:**
   ```javascript
   // eslint.config.mjs (minimal)
   export default [
     {
       plugins: { "@nx": nxEslintPlugin },
       rules: {
         "@nx/enforce-module-boundaries": ["error", { /* ... */ }]
       }
     }
   ];
   ```

3. **Remove ESLint plugins replaced by Biome:**
   - `@typescript-eslint/*`
   - `eslint-plugin-import`
   - `eslint-plugin-simple-import-sort`
   - `prettier`

## References

- [Biome Official Documentation](https://biomejs.dev/)
- [Biome Big Projects Guide](https://biomejs.dev/guides/big-projects/)
- [Biome VCS Integration](https://biomejs.dev/guides/integrate-in-vcs/)
- [GritQL Documentation](https://biomejs.dev/reference/gritql/)
- [Biome Configuration Reference](https://biomejs.dev/reference/configuration/)
