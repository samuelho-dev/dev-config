#!/bin/bash
# ai/hooks/enforce-type-safety.sh
# Blocks code generation that violates type safety rules
#
# Claude Code Hook: PostToolUse (Write|Edit)
# Timeout: 30 seconds
# Enforces type-safe patterns from biome/CLAUDE.md
#
# Blocked patterns:
# - as any / as Type (use Schema.decodeUnknown() instead)
# - @ts-ignore, @ts-expect-error, @ts-nocheck (fix types, don't suppress)
# - ! (non-null assertions) (use optional chaining or type guards)
# - satisfies (use as const or explicit type annotation)

set -euo pipefail

FILE_PATH="${1:-.}"

# Skip if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Only validate TypeScript/JavaScript files
case "$FILE_PATH" in
  *.ts | *.tsx | *.js | *.jsx)
    ;;
  *)
    exit 0
    ;;
esac

# Type-safety violation patterns to block
declare -a VIOLATIONS=(
  # Type assertions
  "as any"
  "as unknown"
  "as const"
  "satisfies"
  # TypeScript suppression comments
  "@ts-ignore"
  "@ts-expect-error"
  "@ts-nocheck"
)

violation_found=0
violation_details=""

for pattern in "${VIOLATIONS[@]}"; do
  # Use grep to find violations (case-sensitive)
  # Skip 'as const' in certain contexts (it's safe for literals)
  if [ "$pattern" = "as const" ]; then
    # Allow 'as const' for literal types - don't block it
    continue
  fi

  if grep -n "$pattern" "$FILE_PATH" 2>/dev/null | grep -qv "^[[:space:]]*//"; then
    violation_found=1
    violation_details+=$(grep -n "$pattern" "$FILE_PATH" 2>/dev/null | grep -v "^[[:space:]]*//" | head -3)
    violation_details+=$'\n'
  fi
done

if [ $violation_found -eq 1 ]; then
  {
    echo "❌ Type safety violations detected in: $FILE_PATH"
    echo ""
    echo "Violations found:"
    echo "$violation_details"
    echo ""
    echo "💡 Type-safe alternatives (see biome/CLAUDE.md for details):"
    echo "   - Instead of 'as any': Use Schema.decodeUnknown() or type guards"
    echo "   - Instead of '@ts-ignore': Fix the underlying type error"
    echo "   - Instead of '!': Use optional chaining (?.) or null checks"
    echo "   - Instead of 'satisfies': Use 'as const' or explicit type annotation"
    echo ""
    echo "📚 Reference: biome/CLAUDE.md - Type Safety Guardrails section"
  } >&2
  exit 2  # Blocking error
fi

exit 0  # All checks passed
