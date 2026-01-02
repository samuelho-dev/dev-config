#!/bin/bash
# ai/hooks/check-type-safety-request.sh
# Analyzes user prompts for type safety workaround requests
#
# Claude Code Hook: UserPromptSubmit
# Timeout: 10 seconds
# Warns if user is asking for type-safe shortcuts
#
# Patterns checked:
# - "use as any"
# - "add @ts-ignore"
# - "add !"
# - "just make it work" + type-related context
# - "ignore the type error"

set -euo pipefail

# Read the user prompt from stdin (provided by Claude Code)
# If not available, skip validation
PROMPT="${1:-.}"

if [ -z "$PROMPT" ]; then
  exit 0
fi

# Convert to lowercase for pattern matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Patterns that indicate type safety workaround requests
declare -a TYPE_SAFETY_KEYWORDS=(
  "as any"
  "as unknown"
  "@ts-ignore"
  "@ts-expect-error"
  "@ts-nocheck"
  "non-null assertion"
  "! operator"
  "ignore the type"
  "suppress the error"
  "just make it work"
  "bypass the type"
  "workaround"
)

warning_issued=0

for keyword in "${TYPE_SAFETY_KEYWORDS[@]}"; do
  keyword_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
  if echo "$PROMPT_LOWER" | grep -qi "$keyword_lower"; then
    warning_issued=1
    break
  fi
done

if [ $warning_issued -eq 1 ]; then
  {
    echo "⚠️  Type Safety Alert"
    echo ""
    echo "Your request appears to involve type safety workarounds."
    echo "This project enforces strict type safety via Biome + GritQL patterns."
    echo ""
    echo "Instead of workarounds, try:"
    echo "  • Schema.decodeUnknown() for runtime validation"
    echo "  • Type guards for safe type narrowing"
    echo "  • Explicit type annotations with validation"
    echo "  • Optional chaining (?.) instead of ! assertions"
    echo ""
    echo "📚 See biome/CLAUDE.md for type-safe alternatives"
  } >&2
  # Exit 0 to allow the prompt to proceed (just a warning)
  # Claude Code will see the stderr message
fi

exit 0
