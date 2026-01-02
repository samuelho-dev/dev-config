#!/bin/bash
# ai/hooks/biome-validate.sh
# Validates Biome linting rules + custom GritQL patterns on code generation
#
# Claude Code Hook: PostToolUse (Write|Edit)
# Timeout: 120 seconds
# Exit codes:
#   0 = All checks passed
#   2 = Blocking error (feedback sent to Claude)

set -euo pipefail

# Get project root - Claude Code provides CLAUDE_PROJECT_DIR
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
BIOME_CONFIG="${PROJECT_DIR}/biome.json"

# Early exit if Biome not configured for this project
if [ ! -f "$BIOME_CONFIG" ]; then
  exit 0
fi

# Get the file path from the first argument (provided by Claude Code)
FILE_PATH="${1:-.}"

# Skip if file doesn't exist or is not TypeScript/JavaScript
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Only validate TypeScript/JavaScript/JSON files
case "$FILE_PATH" in
  *.ts | *.tsx | *.js | *.jsx | *.json)
    ;;
  *)
    exit 0
    ;;
esac

# Run Biome check (uses biome.json from project root)
if ! biome check "$FILE_PATH" 2>&1; then
  {
    echo "❌ Biome validation failed for: $FILE_PATH"
    echo ""
    echo "Violations found:"
    biome check "$FILE_PATH" 2>&1 | head -30
    echo ""
    echo "💡 Fix: Run 'biome check --write $FILE_PATH' to auto-fix issues"
    echo "📚 See biome/CLAUDE.md for linting policy"
  } >&2
  exit 2  # Blocking error - send feedback to Claude
fi

exit 0  # All checks passed
