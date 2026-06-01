#!/usr/bin/env bash
# AI Guardrails: Linting Configuration Validation
# Purpose: Detect and block rule weakening, TypeScript strict mode disabling
# Triggers: Pre-commit hook on any linting config file changes
# Exit codes: 0 = success, 1 = validation failed
# shellcheck disable=SC2317

set -euo pipefail

# ============================================================================
# Color Output Functions
# ============================================================================

log_error() {
  echo -e "\033[0;31m❌ $1\033[0m" >&2
}

log_success() {
  echo -e "\033[0;32m✅ $1\033[0m"
}

log_info() {
  echo -e "\033[0;34mℹ️  $1\033[0m"
}

# ============================================================================
# Configuration
# ============================================================================

# Track violations
VIOLATIONS=0
VIOLATION_DETAILS=""

# ============================================================================
# Core Validation Logic
# ============================================================================

validate_file() {
  local file="$1"

  # Skip if file doesn't exist
  if [ ! -f "$file" ]; then
    return 0
  fi

  log_info "Checking $file..."

  local diff=""

  # Get staged diff for this file
  if git diff --cached --exit-code "$file" &>/dev/null; then
    # No changes in this file
    return 0
  fi

  diff=$(git diff --cached "$file" || true)

  # Check for rule severity downgrades
  validate_rule_weakening "$file" "$diff"

  # Check for TypeScript strict mode being disabled
  if [[ "$file" == "tsconfig"* ]]; then
    validate_typescript_strict "$file" "$diff"
  fi
}

validate_rule_weakening() {
  local file="$1"
  local diff="$2"

  # Pattern: "error" → "warn"
  # Looking for lines removed with "error" and added with "warn"
  if echo "$diff" | grep -E '^\-.*"(error)"' >/dev/null 2>&1; then
    if echo "$diff" | grep -E '^\+.*"(warn)"' >/dev/null 2>&1; then
      local violation="Rule weakening: error → warn"
      log_error "$violation in $file"
      VIOLATION_DETAILS="${VIOLATION_DETAILS}${violation} (file: $file)\n"
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi

  # Pattern: "error" → "off"
  if echo "$diff" | grep -E '^\-.*"(error)"' >/dev/null 2>&1; then
    if echo "$diff" | grep -E '^\+.*"(off)"' >/dev/null 2>&1; then
      local violation="Rule disabling: error → off"
      log_error "$violation in $file"
      VIOLATION_DETAILS="${VIOLATION_DETAILS}${violation} (file: $file)\n"
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi

  # Pattern: "warn" → "off"
  if echo "$diff" | grep -E '^\-.*"(warn)"' >/dev/null 2>&1; then
    if echo "$diff" | grep -E '^\+.*"(off)"' >/dev/null 2>&1; then
      local violation="Rule disabling: warn → off"
      log_error "$violation in $file"
      VIOLATION_DETAILS="${VIOLATION_DETAILS}${violation} (file: $file)\n"
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi
}

validate_typescript_strict() {
  local file="$1"
  local diff="$2"

  # Check for strict: true → false
  if echo "$diff" | grep -E '^\-.*"strict"\s*:\s*true' >/dev/null 2>&1; then
    if echo "$diff" | grep -E '^\+.*"strict"\s*:\s*false' >/dev/null 2>&1; then
      local violation="TypeScript strict mode disabled: true → false"
      log_error "$violation in $file"
      VIOLATION_DETAILS="${VIOLATION_DETAILS}${violation} (file: $file)\n"
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi
}

# Scan staged TS/JS source files for newly-introduced TypeScript suppression
# comments. Biome itself does not ban these, so this hook is the only enforcement.
validate_source_suppressions() {
  local file="$1"

  # Only scan staged additions to TS/JS source files
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx|*.mts|*.cts|*.mjs|*.cjs) ;;
    *) return 0 ;;
  esac

  local added
  # `--diff-filter=ACM` already applied at file-list time. Inspect added lines only.
  added=$(git diff --cached --unified=0 -- "$file" | grep -E '^\+[^+]' || true)

  if [ -z "$added" ]; then
    return 0
  fi

  if echo "$added" | grep -E '@ts-(ignore|expect-error|nocheck)' >/dev/null 2>&1; then
    local violation="TypeScript suppression comment introduced (@ts-ignore/@ts-expect-error/@ts-nocheck)"
    log_error "$violation in $file"
    VIOLATION_DETAILS="${VIOLATION_DETAILS}${violation} (file: $file)\n"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  log_info "Validating linting configuration changes..."
  echo ""

  # Get all staged files that could be linting configs
  local staged_files
  staged_files=$(git diff --cached --name-only --diff-filter=ACM || true)

  if [ -z "$staged_files" ]; then
    log_success "No linting config changes detected"
    return 0
  fi

  # Check each staged file
  while IFS= read -r file; do
    # Check if it's a linting config file
    if [[ "$file" == "biome.json" || "$file" == "biome-base.json" || \
          "$file" == "tsconfig.json" || "$file" =~ tsconfig\..+\.json || \
          "$file" == ".pre-commit-config.yaml" || "$file" =~ .*biome.*\.json ]]; then
      validate_file "$file"
    fi

    # Source-file scan: TypeScript suppression comments
    validate_source_suppressions "$file"
  done <<< "$staged_files"

  # Report results
  echo ""

  if [ $VIOLATIONS -eq 0 ]; then
    log_success "Linting config validation passed"
    return 0
  fi

  # Violations detected
  log_error "Linting config validation FAILED: $VIOLATIONS violation(s)"
  echo ""
  echo "Violation details:"
  echo -e "$VIOLATION_DETAILS"
  echo ""
  echo "Rule weakening and TypeScript strict mode disabling are not allowed."
  echo "See docs/LINTING_POLICY.md for complete policy."
  echo ""
  echo "Common violations:"
  echo "  ❌ Changing rule level from error → warn or off"
  echo "  ❌ Disabling TypeScript strict mode"
  echo "  ❌ Weakening any linting rule"
  echo "  ❌ Adding @ts-ignore / @ts-expect-error / @ts-nocheck comments"
  echo ""
  echo "To override (requires explicit developer approval):"
  echo "  git commit --no-verify -m \"Approved: [explicit justification]\""
  echo ""
  echo "To revert changes:"
  echo "  git restore --staged [filename]"
  echo "  git restore [filename]"
  echo ""

  return 1
}

# Run validation
main
exit $?
