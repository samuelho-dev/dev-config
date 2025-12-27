# Claude Code Hooks

Custom hooks for enforcing Biome linting, GritQL patterns, and type safety in Claude Code.

## Overview

Hooks are automated shell commands that execute at specific points in Claude Code's lifecycle. They enable enforcement of team standards without relying on LLM decision-making.

**Directory:** `ai/hooks/`

**Configuration:** `.claude/settings.json` (project-level, committed to git)

**Symlinked to:** `~/.config/claude-code/hooks/` (via Home Manager)

## Hook Scripts

### 1. biome-validate.sh

**Purpose:** Validates Biome linting rules + custom GritQL patterns on code generation

**Triggers:** PostToolUse (Write, Edit)

**What it checks:**
- Biome built-in rules (80+ strict rules)
- Custom GritQL patterns (14 patterns)
- Type safety violations
- Effect-TS patterns

**Exit behavior:**
- ✅ Exit 0: All checks passed, code generation continues
- ❌ Exit 2: Violations found, feedback shown to Claude, operation blocked

**Example output:**
```
❌ Biome validation failed for: src/services/api.ts

Violations found:
  error[style/noCommonJs]: CommonJS require should be replaced with ESM import
  error[style/noExplicitAny]: Avoid using `any` type

💡 Fix: Run 'biome check --write src/services/api.ts' to auto-fix issues
📚 See biome/CLAUDE.md for linting policy
```

**Timeout:** 120 seconds

### 2. enforce-type-safety.sh

**Purpose:** Blocks code generation that violates type safety rules

**Triggers:** PostToolUse (Write, Edit)

**Blocked patterns:**
- `as any` / `as unknown` / `as Type` → Use Schema.decodeUnknown() instead
- `@ts-ignore` / `@ts-expect-error` / `@ts-nocheck` → Fix the type error
- `!` (non-null assertions) → Use `?.` or type guards
- `satisfies` → Use `as const` or explicit type annotation

**Exit behavior:**
- ✅ Exit 0: No type safety violations
- ❌ Exit 2: Violations detected, feedback shown, Claude is blocked from proceeding

**Example output:**
```
❌ Type safety violations detected in: src/components/Form.tsx

Violations found:
  12: const data = apiResponse as any;
  45: // @ts-ignore missing property
  67: const value = obj.prop!;

💡 Type-safe alternatives (see biome/CLAUDE.md for details):
   - Instead of 'as any': Use Schema.decodeUnknown() or type guards
   - Instead of '@ts-ignore': Fix the underlying type error
   - Instead of '!': Use optional chaining (?.) or null checks
   - Instead of 'satisfies': Use 'as const' or explicit type annotation

📚 Reference: biome/CLAUDE.md - Type Safety Guardrails section
```

**Timeout:** 30 seconds

### 3. check-type-safety-request.sh

**Purpose:** Analyzes user prompts for type safety workaround requests

**Triggers:** UserPromptSubmit (all prompts)

**What it detects:**
- Explicit requests for `as any`
- Requests for TypeScript suppression comments
- Requests to bypass type checking
- "just make it work" + type-related context

**Exit behavior:**
- ℹ️ Exit 0 (always): Prompt is allowed to proceed
- ⚠️ Warning message sent to Claude if type safety workaround detected

**Example output:**
```
⚠️  Type Safety Alert

Your request appears to involve type safety workarounds.
This project enforces strict type safety via Biome + GritQL patterns.

Instead of workarounds, try:
  • Schema.decodeUnknown() for runtime validation
  • Type guards for safe type narrowing
  • Explicit type annotations with validation
  • Optional chaining (?.) instead of ! assertions

📚 See biome/CLAUDE.md for type-safe alternatives
```

**Timeout:** 10 seconds

## Configuration

### .claude/settings.json

```json
{
  "hooks": {
    "enabled": true,
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "type": "command",
        "command": "bash ai/hooks/biome-validate.sh",
        "timeout": 120,
        "description": "Validate Biome linting + GritQL patterns"
      },
      {
        "matcher": "Write|Edit",
        "type": "command",
        "command": "bash ai/hooks/enforce-type-safety.sh",
        "timeout": 30,
        "description": "Block type safety violations"
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "type": "command",
        "command": "bash ai/hooks/check-type-safety-request.sh",
        "timeout": 10,
        "description": "Warn if requesting type-safe workarounds"
      }
    ]
  }
}
```

**How it works:**
1. Each hook has a `matcher` (which tool/event to trigger on)
2. `type: "command"` means run a shell script
3. `command` path is relative to project root
4. `timeout` is maximum time the hook can run
5. Exit code 0 = success, exit code 2 = blocking error

## Hook Execution Flow

```
User asks Claude Code to write code
    ↓
Claude Code calls Write/Edit tool
    ↓
File is written to disk
    ↓
PostToolUse hooks trigger:
    1. biome-validate.sh checks Biome + GritQL patterns
    2. enforce-type-safety.sh checks for type safety violations
    ↓
If any hook exits with code 2:
    ❌ Feedback sent to Claude
    ❌ Operation is blocked
    ❌ Claude must fix the code
    ↓
If all hooks exit 0:
    ✅ Code generation continues
    ✅ Claude sees success and can proceed
```

## Testing Hooks Locally

### Test biome-validate.sh

```bash
# Create a test file with violations
cat > /tmp/test-violation.ts << 'EOF'
const x = require('module');  // CommonJS - violates noCommonJs
const data = apiResponse as any;  // Type assertion
EOF

# Run the hook
bash ai/hooks/biome-validate.sh /tmp/test-violation.ts

# Check exit code
echo "Exit code: $?"  # Should be 2 (blocking error)
```

### Test enforce-type-safety.sh

```bash
# Create a test file with type safety violations
cat > /tmp/type-violation.ts << 'EOF'
const x = obj.prop!;  // Non-null assertion
const y = response as any;  // Type assertion
// @ts-ignore missing property
EOF

# Run the hook
bash ai/hooks/enforce-type-safety.sh /tmp/type-violation.ts

# Check exit code
echo "Exit code: $?"  # Should be 2 (blocking error)
```

### Test check-type-safety-request.sh

```bash
# Test with type safety workaround request
bash ai/hooks/check-type-safety-request.sh "Please use as any to make this work"

# Should show warning and exit 0
echo "Exit code: $?"  # Should be 0 (warning only, request allowed)
```

## Integration with Home Manager

The Home Manager module (`modules/home-manager/programs/claude-code.nix`) automatically:

1. Symlinks `ai/hooks/` to `~/.config/claude-code/hooks/`
2. Symlinks `ai/agents/` to `~/.config/claude-code/agents/`
3. Symlinks `ai/commands/` to `~/.config/claude-code/commands/`
4. Copies `.claude/settings.json` to project-level configuration

**Apply changes:**
```bash
home-manager switch --flake .
```

## How Claude Code Uses These Hooks

1. **Projects import dev-config flake:**
   ```nix
   inputs.dev-config.url = "github:samuelho-dev/dev-config";
   ```

2. **Home Manager symlinks hooks:**
   ```
   ~/.config/claude-code/hooks/ → ai/hooks/
   ```

3. **`.claude/settings.json` references hooks:**
   ```json
   "command": "bash ai/hooks/biome-validate.sh"
   ```

4. **Claude Code loads hooks and executes them:**
   - When Write/Edit tool is used
   - When user submits a prompt
   - Hook scripts run in project directory with full access to config

## Customization

### Add a New Hook

1. Create script in `ai/hooks/<name>.sh`
2. Make it executable: `chmod +x ai/hooks/<name>.sh`
3. Add to `.claude/settings.json` in appropriate event section
4. Test locally: `bash ai/hooks/<name>.sh <test-file>`
5. Commit both script and settings.json

### Modify Existing Hook

1. Edit the script in `ai/hooks/`
2. Test with: `bash ai/hooks/<name>.sh <test-file>`
3. Verify exit codes (0 for success, 2 for blocking)
4. Commit changes

### Disable a Hook

In `.claude/settings.json`, remove or comment out the hook configuration:

```json
// "PostToolUse": [ ... ]  // Commented out - hook disabled
```

## Troubleshooting

### Hook not running

**Check:**
1. Is `hooks.enabled: true` in `.claude/settings.json`?
2. Is the script path correct (relative to project root)?
3. Run `home-manager switch --flake .` to update symlinks
4. Verify script is executable: `ls -la ai/hooks/*.sh`

### Hook timing out

**Solution:**
1. Increase `timeout` in `.claude/settings.json`
2. Check if Biome/hooks are slow: `time bash ai/hooks/biome-validate.sh <file>`
3. Optimize hook logic if slow

### False positives

**Type safety hook finding 'as const':**
- Expected - `as const` is safe for literal types
- Hook intentionally skips `as const` but you can verify

**Biome finding errors that don't matter:**
- Override in `biome.json` overrides section
- See `biome/CLAUDE.md` for override patterns

## Files

| File | Purpose |
|------|---------|
| `ai/hooks/biome-validate.sh` | Validates Biome linting + GritQL patterns |
| `ai/hooks/enforce-type-safety.sh` | Blocks type safety violations |
| `ai/hooks/check-type-safety-request.sh` | Warns about workaround requests |
| `ai/hooks/lib/` | Shared hook utilities (future) |
| `.claude/settings.json` | Hook configuration (project-level) |

## References

- **Claude Code Hooks:** https://code.claude.com/docs/en/hooks-guide.md
- **Biome Configuration:** `biome/CLAUDE.md`
- **GritQL Patterns:** `biome/gritql-patterns/`
- **Type Safety Policy:** `biome/CLAUDE.md` - Type Safety Guardrails section

## For Future Claude Code Instances

When working with these hooks:

- [ ] Understand exit codes: 0 = success, 2 = blocking error
- [ ] Test hooks locally before relying on them: `bash ai/hooks/<name>.sh <file>`
- [ ] Keep hook logic simple and fast (timeout constraints)
- [ ] Update `.claude/settings.json` when adding/removing hooks
- [ ] Verify symlinks are created: `ls -la ~/.config/claude-code/hooks/`
- [ ] Check hook output: Claude Code shows stderr when hook exits 2
- [ ] Commit both `.claude/settings.json` and hook scripts
- [ ] Reference documentation in hook output messages
