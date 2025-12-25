---
scope: .opencode/plugin/
updated: 2025-12-24
relates_to:
  - ../tool/gritql.ts
  - ../tool/mlg.ts
  - ../opencode.json
  - ../test/plugins.test.ts
  - ../../AGENTS.md
---

# CLAUDE.md - OpenCode Guardrail Plugins

## Purpose

This directory contains **guardrail plugins** that enforce strict policy for AI-assisted code operations. These plugins intercept tool invocations and file edits to guide agents toward structured, safe code modifications.

**Key responsibility**: Prevent direct file edits and shell-based code modifications, redirecting to `@gritql` and `@mlg` tools instead.

---

## Architecture Overview

```
plugin/
+-- gritql-guardrails.ts    # Intercepts file edits for GritQL-supported types
+-- mlg-guardrails.ts       # Intercepts library creation bypassing MLG
+-- nx-guardrails.ts        # Extended NX workspace guardrails
```

All plugins implement the OpenCode Plugin interface:

```typescript
import type { Plugin } from "@opencode-ai/plugin"

export const PluginName: Plugin = async () => {
  return {
    "event.name": async (event) => {
      // Validation logic
      // throw Error("...") to block with guidance
      // return undefined to allow
    },
  }
}
```

---

## Plugin Reference

### gritql-guardrails.ts

**Purpose**: Encourage structural code modification via `@gritql` tool for supported file types.

**Hook**: `file.edited`

**Supported File Extensions**:

| Extension                    | Language   |
| ---------------------------- | ---------- |
| `.js`, `.jsx`, `.mjs`, `.cjs` | JavaScript |
| `.ts`, `.tsx`                 | TypeScript |
| `.json`                       | JSON       |
| `.py`                         | Python     |
| `.css`, `.scss`               | CSS        |
| `.rs`                         | Rust       |
| `.rb`                         | Ruby (Beta)|
| `.php`                        | PHP (Beta) |

**Behavior**:
- If file extension is NOT in supported list: **Silent bypass** (allows edit)
- If file extension IS supported: **Throws error** with GritQL guidance

---

### mlg-guardrails.ts

**Purpose**: Encourage library creation via `@mlg` tool instead of raw NX generators or manual scaffolding.

**Hook**: `tool.execute.before`

**Warned Patterns** (triggers guidance):

| Pattern              | Matches                          |
| -------------------- | -------------------------------- |
| `nx g @nx/js:lib`    | NX JavaScript library generator  |
| `nx generate @nx/node:lib` | NX Node library generator  |
| `nx g @nrwl/*:lib`   | Legacy NRWL generators           |
| `mkdir libs/`        | Manual library directory creation|

**Allowed Patterns** (bypass): `@mlg`, `mlg`, `opencode run mlg`

---

## Key Patterns

### 1. Silent Bypass for Unsupported Files

```typescript
const ext = extname(filePath).toLowerCase()
if (!GRITQL_SUPPORTED.has(ext)) return  // Silent bypass
throw new Error(`For structural code changes to ${ext} files, prefer @gritql...`)
```

### 2. Allowlist Before Warnlist

```typescript
function findWarnReason(command: string): string | null {
  if (ALLOWED_PATTERNS.some((re) => re.test(command))) return null
  for (const { pattern, reason } of WARNED_PATTERNS) {
    if (pattern.test(command)) return reason
  }
  return null
}
```

---

## Testing

```bash
cd .opencode
bun test test/plugins.test.ts
```

---

## For Future Claude Code Instances

- [ ] Check if file type is in GRITQL_SUPPORTED before suggesting direct edits
- [ ] Use `@gritql` for TypeScript/JavaScript/Python/CSS/Rust code changes
- [ ] Use `@mlg` for library scaffolding in Nx monorepos
- [ ] Plugins throw errors to GUIDE, not permanently block
- [ ] Keep ALLOWED_PATTERNS synchronized with AGENTS.md
