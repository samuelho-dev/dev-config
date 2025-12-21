---
scope: gritql-patterns/
updated: 2025-12-21
relates_to:
  - ../CLAUDE.md
  - ../biome/CLAUDE.md
  - ../.grit/grit.yaml
validation:
  max_days_stale: 30
---

# GritQL Pattern Library

Architectural guidance for the 246+ GritQL patterns across 17 language directories.

## Purpose

This directory contains a comprehensive library of GritQL patterns for code search, linting, and automated refactoring. Patterns range from simple lint rules to complex migration scripts (e.g., OpenAI SDK v0→v1). The library serves as both a reference implementation and a practical toolset for codebase transformations.

## Architecture Overview

Patterns are organized by target language, with each pattern in a markdown file containing:
1. **YAML frontmatter** - Title, tags, and metadata
2. **GritQL code block** - The pattern implementation
3. **Test cases** - Before/after code pairs

The library follows GritQL's "pattern as documentation" philosophy where examples serve as both tests and usage guides.

Key design principles:
- **Language-specific directories**: Patterns grouped by target language
- **Self-documenting**: Each pattern includes examples
- **Composable**: Patterns can reference each other via `pattern` declarations
- **Testable**: Before/after blocks are automatically verified

## File Structure

```
gritql-patterns/
+-- css/                    # 2 patterns (aspect ratio, shadows)
+-- go/                     # 9 patterns (goroutines, imports, security)
+-- java/                   # 13 patterns (comparisons, exceptions, imports)
+-- js/                     # 100+ patterns (migrations, ESM, React)
+-- json/                   # 6 patterns (security, tsconfig)
+-- lint/                   # 2 patterns (unused imports, CSS modules)
+-- markdown/               # 1 pattern (delinkify)
+-- python/                 # 35+ patterns (OpenAI, Django, migrations)
+-- rust/                   # 9 patterns (idioms, security)
+-- solidity/               # 5 patterns (security, gas optimization)
+-- sql/                    # 6 patterns (Oracle→PostgreSQL)
+-- terraform/              # 2 patterns (module editing)
+-- typescript/             # 3 patterns (PropTypes, Flow→TS)
+-- universal/              # 7 patterns (core utilities)
+-- workflows/              # 1 file (styled-components)
+-- yaml/                   # 2 patterns (GitHub Actions)
+-- grit_snake_case.md      # Naming convention pattern
```

## Key Patterns

### High-Impact Migrations

| Pattern | Language | Purpose |
|---------|----------|---------|
| `openai.md` | Python | OpenAI SDK v0→v1 migration |
| `langfuse_v2.md` | Python | Langfuse v1→v2 migration |
| `cloudflare_go_v2.md` | Go | Cloudflare SDK v1→v2 |
| `FlowToTypeScript.md` | TypeScript | Flow→TypeScript conversion |
| `oracle_to_pg.md` | SQL | Oracle→PostgreSQL migration |

### Security Patterns

| Pattern | Language | Purpose |
|---------|----------|---------|
| `jwt_go_none_algorithm.md` | Go | Detect JWT none algorithm vulnerability |
| `jwt_python_none_algorithm.md` | Python | Detect JWT none algorithm vulnerability |
| `use_secure_hashes.md` | Rust | Enforce secure hash algorithms |
| `public_s3_bucket.md` | JSON | Detect public S3 bucket configs |
| `wildcard_assume_role.md` | JSON | Detect overly permissive IAM |

### Code Quality

| Pattern | Language | Purpose |
|---------|----------|---------|
| `_convert_default_exports.md` | JS | Convert default→named exports |
| `no_unthrown_exceptions.md` | Java | Detect created but not thrown exceptions |
| `hidden_goroutine.md` | Go | Detect goroutines in loops |
| `collection_to_bool.md` | Python | Simplify `len(x) > 0` → `x` |
| `collapsible_if.md` | Rust | Merge nested if statements |

## Pattern Anatomy

### Standard Pattern Structure

```markdown
---
title: Pattern Title
tags: [language, category, migration]
---

Description of what the pattern does.

\`\`\`grit
engine marzano(0.1)
language python

pattern my_pattern() {
  `old_code($arg)` => `new_code($arg)`
}

my_pattern()
\`\`\`

## Example 1

\`\`\`python
# Before
old_code(value)
\`\`\`

\`\`\`python
# After
new_code(value)
\`\`\`
```

### Pattern Building Blocks

| Element | Syntax | Purpose |
|---------|--------|---------|
| Match literal | `` `code` `` | Match exact code |
| Metavariable | `$name` | Capture any node |
| Multiple nodes | `$$$args` | Capture multiple nodes |
| Rewrite | `=>` | Transform matched code |
| Condition | `where { }` | Add constraints |
| Or | `or { a, b }` | Match alternatives |
| Contains | `contains $x` | Check for nested match |
| Regex | `r"pattern"` | Match with regex |

## Usage

### Run Pattern on Codebase

```bash
# Apply pattern
grit apply gritql-patterns/python/openai.md

# Dry-run (show changes without applying)
grit apply gritql-patterns/python/openai.md --dry-run

# Apply to specific directory
grit apply gritql-patterns/js/_convert_default_exports.md src/
```

### Test Pattern

```bash
# Test all patterns
grit test gritql-patterns/

# Test specific pattern
grit test gritql-patterns/python/openai.md
```

### Search with Pattern

```bash
# Find matches without transforming
grit check gritql-patterns/go/hidden_goroutine.md
```

### With Biome Integration

Patterns in `biome/gritql-patterns/` are automatically used by Biome:

```bash
biome check --gritql-patterns biome/gritql-patterns/ src/
```

## Adding/Modifying

### Creating a New Pattern

1. **Choose the right directory** based on target language

2. **Create pattern file** `language/pattern_name.md`:
   ```markdown
   ---
   title: Descriptive Title
   tags: [language, category]
   ---

   Brief description of what this pattern catches or transforms.

   \`\`\`grit
   engine marzano(0.1)
   language <target_language>

   `pattern_to_match` => `replacement`
   \`\`\`

   ## Example

   \`\`\`<language>
   // Before
   \`\`\`

   \`\`\`<language>
   // After
   \`\`\`
   ```

3. **Test the pattern**:
   ```bash
   grit test gritql-patterns/language/pattern_name.md
   ```

4. **Apply to real codebase** for validation

### Pattern Development Tips

**Start simple:**
```grit
`console.log($msg)` => `logger.info($msg)`
```

**Add conditions:**
```grit
`console.log($msg)` => `logger.info($msg)` where {
  $msg <: not `"debug: $_"`
}
```

**Handle multiple cases:**
```grit
or {
  `console.log($msg)` => `logger.info($msg)`,
  `console.error($msg)` => `logger.error($msg)`,
  `console.warn($msg)` => `logger.warn($msg)`
}
```

**Compose patterns:**
```grit
pattern fix_logging() {
  or {
    `console.log($msg)` => `logger.info($msg)`,
    `console.error($msg)` => `logger.error($msg)`
  }
}

file($body) where {
  $body <: contains fix_logging()
}
```

### Naming Conventions

| Convention | Example | Use Case |
|------------|---------|----------|
| `verb_noun.md` | `ban_any_type.md` | Lint rules |
| `framework_version.md` | `openai_v1.md` | Migrations |
| `_helper.md` | `_imports.grit` | Shared utilities |
| `noun_to_noun.md` | `flow_to_typescript.md` | Conversions |

## Language-Specific Notes

### JavaScript/TypeScript (`js/`)

Largest collection with 100+ patterns covering:
- ESM conversions (default→named exports)
- React patterns (class→hooks, PropTypes→TS)
- Framework migrations (Next.js, Express)
- Import organization

### Python (`python/`)

35+ patterns focused on:
- SDK migrations (OpenAI, Langfuse, Mux)
- Django/Flask patterns
- Security (JWT, file handling)
- Pythonic idioms

### Go (`go/`)

9 patterns for:
- Goroutine safety
- Import management
- SDK migrations (Cloudflare)
- Security patterns

## Common Issues

### Pattern not matching

1. Check language declaration matches target
2. Verify AST structure (use `grit parse` to inspect)
3. Try simplifying pattern to isolate issue
4. Check for whitespace/formatting differences

### Rewrite produces invalid code

1. Ensure metavariables are properly captured
2. Check for missing semicolons/commas
3. Verify import statements are added if needed
4. Test with multiple input variations

### Pattern too slow

1. Add file-level constraints: `file($body) where { ... }`
2. Limit scope with `contains` before expensive checks
3. Avoid deeply nested `or` patterns
4. Consider splitting into multiple patterns

## Resources

- [GritQL Documentation](https://docs.grit.io/)
- [GritQL Language Reference](https://docs.grit.io/language/overview)
- [Marzano Engine](https://github.com/getgrit/gritql)
- [Pattern Gallery](https://github.com/getgrit/stdlib)

## For Future Claude Code Instances

- [ ] Check existing patterns before creating new ones (avoid duplication)
- [ ] Include at least 2-3 test cases per pattern
- [ ] Use `_prefix.grit` for shared utilities that shouldn't run standalone
- [ ] Test patterns against real codebases, not just example snippets
- [ ] Consider edge cases (empty files, comments, multiline)
- [ ] Add tags for discoverability
- [ ] Follow existing naming conventions in each language directory
- [ ] Update this CLAUDE.md when adding new categories
