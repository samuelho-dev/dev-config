import type { Plugin } from "@opencode-ai/plugin"
import { existsSync, readFileSync } from "node:fs"
import { join, dirname } from "node:path"

/**
 * Nx Guardrails Plugin
 *
 * Comprehensive enforcement of Nx monorepo standards:
 * - Dynamic Nx workspace detection
 * - Naming conventions (kebab-case, scope-type-identifier)
 * - Directory structure enforcement
 * - Project.json schema validation (required fields, tags, executors)
 * - ESM-only enforcement (package.json + tsconfig.json)
 * - Dependency rules (tag-based constraints)
 * - Nx command usage (block raw tsc/jest/webpack bypasses)
 *
 * Based on official Nx documentation and 2025 best practices.
 * @see https://nx.dev/concepts/decisions
 * @see https://nx.dev/features/enforce-module-boundaries
 */

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface NxWorkspaceInfo {
  readonly isNxWorkspace: boolean
  readonly rootPath: string
  readonly nxVersion: string
  readonly workspaceLayout: {
    readonly appsDir: string
    readonly libsDir: string
  }
}

interface ValidationResult {
  readonly valid: boolean
  readonly errors: readonly string[]
  readonly warnings: readonly string[]
}

interface ViolationPattern {
  readonly pattern: RegExp
  readonly reason: string
  readonly example?: string
  readonly remediation: readonly string[]
}

// ============================================================================
// CONSTANTS: NAMING CONVENTIONS
// ============================================================================

/**
 * Valid library type suffixes (Official Nx pattern)
 * @see https://nx.dev/concepts/decisions/project-dependency-rules
 */
const VALID_LIBRARY_TYPES = [
  "feature", // Container components with business logic
  "ui", // Presentational components only
  "data-access", // API delegates, state management
  "util", // Pure functions, utilities
  "shell", // Application shell (routing, layout)
] as const

/**
 * Valid tag prefixes for module boundary enforcement
 * @see https://nx.dev/features/enforce-module-boundaries
 */
const VALID_TAG_PREFIXES = {
  type: VALID_LIBRARY_TYPES,
  scope: ["shared", "platform"], // Plus any custom scope
  platform: ["web", "mobile", "node", "server"],
} as const

/**
 * Naming convention violations (command interception)
 */
const NAMING_VIOLATIONS: readonly ViolationPattern[] = [
  {
    pattern: /nx\s+g(?:enerate)?\s+@nx\/\w+:\w+\s+[A-Z]/,
    reason: "Library names must be kebab-case (Official Nx convention)",
    example: "Use 'my-lib', not 'MyLib' or 'myLib'",
    remediation: [
      "Convert to kebab-case: my-feature-name",
      "Example: nx generate @nx/js:lib my-lib --directory=shared",
      "See: https://nx.dev/blog/virtuous-cycle-of-workspace-structure",
    ],
  },
  {
    pattern: /nx\s+g(?:enerate)?\s+@nx\/\w+:\w+\s+\S*_/,
    reason: "Library names cannot contain underscores (Nx standard)",
    example: "Use 'my-lib', not 'my_lib'",
    remediation: [
      "Replace underscores with hyphens: my-feature-name",
      "Nx uses kebab-case for all library and app names",
    ],
  },
  {
    pattern: /nx\s+g(?:enerate)?\s+@nx\/\w+:lib(?:rary)?\s+\S+(?!\s+--directory)/,
    reason: "Libraries should specify --directory for proper scope organization",
    example: "nx generate @nx/js:lib my-lib --directory=shared",
    remediation: [
      "Add --directory flag: nx generate @nx/js:lib my-lib --directory=shared",
      "This ensures proper scope-based organization (libs/shared/my-lib)",
      "Follow the scope-type-identifier pattern",
    ],
  },
  {
    pattern: /nx\s+g(?:enerate)?\s+@nx\/\w+:lib(?:rary)?\s+\S+(?!\s+--tags)/,
    reason: "Libraries must specify --tags for module boundary enforcement",
    example: 'nx generate @nx/js:lib my-lib --tags="type:util,scope:shared"',
    remediation: [
      'Add --tags flag: --tags="type:util,scope:shared"',
      "Required tags: type:* (feature|ui|data-access|util) and scope:* (shared|app-name)",
      "This enables @nx/enforce-module-boundaries ESLint rule",
    ],
  },
]

// ============================================================================
// CONSTANTS: NX COMMAND BYPASS PATTERNS
// ============================================================================

/**
 * Commands that bypass Nx and should be blocked
 * @see https://www.infoq.com/presentations/monorepo-mistakes/
 */
const BLOCKED_NX_BYPASSES: readonly ViolationPattern[] = [
  {
    pattern: /\btsc\b(?!.*--noEmit)(?!.*--version)/,
    reason: "Use 'nx build' instead of raw tsc for computation caching",
    example: "nx build my-lib (instead of tsc)",
    remediation: [
      "Use: nx build <project-name>",
      "Benefits: Computation caching, affected detection, task orchestration",
      "tsc --noEmit is allowed for type checking",
    ],
  },
  {
    pattern: /\bnpm\s+run\s+build\b/,
    reason: "Use 'nx build' for Nx workspace benefits",
    example: "nx build my-lib (instead of npm run build)",
    remediation: [
      "Use: nx build <project-name>",
      "Benefits: Dependency graph awareness, smart rebuilds",
      "npm run scripts bypass Nx caching and affected detection",
    ],
  },
  {
    pattern: /\byarn\s+build\b/,
    reason: "Use 'nx build' for Nx workspace benefits",
    remediation: [
      "Use: nx build <project-name>",
      "Benefits: Dependency graph awareness, smart rebuilds",
    ],
  },
  {
    pattern: /\bpnpm\s+run\s+build\b/,
    reason: "Use 'nx build' for Nx workspace benefits",
    remediation: [
      "Use: nx build <project-name>",
      "Benefits: Dependency graph awareness, smart rebuilds",
    ],
  },
  {
    pattern: /\bjest\b(?!.*--config)(?!.*--version)/,
    reason: "Use 'nx test' instead of raw jest for test caching",
    example: "nx test my-lib (instead of jest)",
    remediation: [
      "Use: nx test <project-name>",
      "Benefits: Test result caching, affected testing",
      "jest with --config is allowed for custom configurations",
    ],
  },
  {
    pattern: /\bvitest\b(?!.*--config)(?!.*--version)/,
    reason: "Use 'nx test' instead of raw vitest for test caching",
    remediation: [
      "Use: nx test <project-name>",
      "Benefits: Test result caching, affected testing",
    ],
  },
  {
    pattern: /\bwebpack\b(?!.*--config)(?!.*--version)/,
    reason: "Use Nx executors instead of raw webpack",
    remediation: [
      "Configure build target in project.json:",
      '  "executor": "@nx/webpack:webpack"',
      "This enables Nx caching and task orchestration",
    ],
  },
  {
    pattern: /\besbuild\b(?!.*--version)/,
    reason: "Use Nx executors instead of raw esbuild",
    remediation: [
      "Configure build target in project.json:",
      '  "executor": "@nx/esbuild:esbuild"',
      "This enables Nx caching and task orchestration",
    ],
  },
  {
    pattern: /\bmkdir\s+(-p\s+)?.*\blibs?\//i,
    reason: "Use 'nx generate' to create libraries with proper configuration",
    example: "nx generate @nx/js:lib my-lib --directory=shared",
    remediation: [
      "Use: nx generate @nx/js:lib <name> --directory=<scope>",
      "This creates project.json, tsconfig.json, and proper structure",
      "Manual directory creation bypasses Nx workspace configuration",
    ],
  },
  {
    pattern: /\btouch\s+.*\blibs?\/.*project\.json/i,
    reason: "Use 'nx generate' to create libraries with proper configuration",
    remediation: [
      "Use: nx generate @nx/js:lib <name> --directory=<scope>",
      "Nx generators create valid project.json with all required fields",
    ],
  },
]

// ============================================================================
// CONSTANTS: APPROVED EXECUTORS
// ============================================================================

/**
 * Approved Nx executors for build targets
 */
const APPROVED_EXECUTORS = new Set([
  // Build executors
  "@nx/js:tsc",
  "@nx/js:swc",
  "@nx/vite:build",
  "@nx/webpack:webpack",
  "@nx/esbuild:esbuild",
  "@nx/rollup:rollup",
  "@nx/node:build",
  // Test executors
  "@nx/jest:jest",
  "@nx/vite:test",
  // Lint executors
  "@nx/linter:eslint",
  "@nx/eslint:lint",
  // Serve executors
  "@nx/vite:dev-server",
  "@nx/webpack:dev-server",
  "@nx/node:serve",
  // Other common executors
  "@nx/js:release-publish",
  "nx:run-commands",
])

// ============================================================================
// CONSTANTS: ESM REQUIREMENTS
// ============================================================================

/**
 * Valid ESM module settings for tsconfig.json
 */
const VALID_ESM_MODULES = new Set(["ESNext", "NodeNext", "ES2022", "ES2020"])

/**
 * Valid ESM moduleResolution settings for tsconfig.json
 */
const VALID_ESM_MODULE_RESOLUTIONS = new Set(["bundler", "NodeNext", "node16", "Node16"])

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Safe JSON parsing with error handling
 */
function safeReadJson(filePath: string): unknown | null {
  if (!existsSync(filePath)) return null
  try {
    return JSON.parse(readFileSync(filePath, "utf-8"))
  } catch (error) {
    console.warn(`[nx-guardrails] Failed to parse ${filePath}:`, error)
    return null
  }
}

/**
 * Create a formatted error with details for OpenCode plugin system
 */
function makeError(message: string, details?: Record<string, unknown>): Error {
  const error = new Error(message) as Error & { details?: Record<string, unknown> }
  error.details = details
  return error
}

/**
 * Format a violation pattern into a user-friendly error message
 */
function formatViolationError(
  violation: ViolationPattern,
  context: { command?: string; file?: string; project?: string }
): string {
  const contextStr = context.file
    ? `📁 File: ${context.file}`
    : context.command
      ? `💻 Command: ${context.command.substring(0, 100)}${context.command.length > 100 ? "..." : ""}`
      : ""

  const exampleStr = violation.example ? `\n\n✅ Example:\n   ${violation.example}` : ""

  return (
    `🚨 Nx Guardrail Violation\n\n` +
    `${violation.reason}\n\n` +
    `${contextStr}${exampleStr}\n\n` +
    `📋 Remediation Steps:\n` +
    violation.remediation.map((step, i) => `   ${i + 1}. ${step}`).join("\n") +
    `\n\n📚 Learn More:\n` +
    `   • Nx Best Practices: https://nx.dev/concepts/decisions\n` +
    `   • Module Boundaries: https://nx.dev/features/enforce-module-boundaries`
  )
}

/**
 * Format validation errors into a user-friendly message
 */
function formatValidationErrors(
  result: ValidationResult,
  context: { file?: string; project?: string }
): string {
  const contextStr = context.file ? `📁 File: ${context.file}\n` : ""

  const errorsStr = result.errors.map((e) => `   ❌ ${e}`).join("\n")
  const warningsStr =
    result.warnings.length > 0 ? `\n\n⚠️ Warnings:\n${result.warnings.map((w) => `   ⚠️ ${w}`).join("\n")}` : ""

  return (
    `🚨 Nx Configuration Validation Failed\n\n` +
    `${contextStr}\n` +
    `❌ Errors:\n${errorsStr}${warningsStr}\n\n` +
    `📚 Learn More:\n` +
    `   • Nx Project Configuration: https://nx.dev/reference/project-configuration\n` +
    `   • Module Boundaries: https://nx.dev/features/enforce-module-boundaries`
  )
}

// ============================================================================
// NX WORKSPACE DETECTION
// ============================================================================

/**
 * Dynamically detect if directory is an Nx monorepo workspace
 *
 * Detection logic:
 * 1. Check for nx.json (official Nx workspace marker)
 * 2. Verify package.json has @nx/* or nx dependencies
 * 3. Extract workspace layout configuration
 */
function detectNxMonorepo(directory: string): NxWorkspaceInfo | null {
  // Check 1: nx.json must exist
  const nxJsonPath = join(directory, "nx.json")
  const nxJson = safeReadJson(nxJsonPath) as Record<string, unknown> | null
  if (!nxJson) return null // Not an Nx workspace

  // Check 2: package.json must have Nx dependencies
  const pkgPath = join(directory, "package.json")
  const pkg = safeReadJson(pkgPath) as Record<string, unknown> | null
  if (!pkg) return null

  const deps = (pkg.dependencies ?? {}) as Record<string, string>
  const devDeps = (pkg.devDependencies ?? {}) as Record<string, string>

  const nxVersion = devDeps.nx ?? deps.nx
  const hasNxDeps =
    Object.keys(deps).some((dep) => dep.startsWith("@nx/")) ||
    Object.keys(devDeps).some((dep) => dep.startsWith("@nx/"))

  if (!nxVersion && !hasNxDeps) return null

  // Check 3: Extract workspace layout (default: apps/ and libs/)
  const layout = (nxJson.workspaceLayout as { appsDir?: string; libsDir?: string }) ?? {}

  return {
    isNxWorkspace: true,
    rootPath: directory,
    nxVersion: nxVersion ?? "unknown",
    workspaceLayout: {
      appsDir: layout.appsDir ?? "apps",
      libsDir: layout.libsDir ?? "libs",
    },
  }
}

// ============================================================================
// VALIDATION: PROJECT.JSON
// ============================================================================

/**
 * Validate project.json against Nx schema requirements
 *
 * @see https://github.com/nrwl/nx/blob/main/packages/nx/schemas/project-schema.json
 */
function validateProjectJson(filePath: string): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  const config = safeReadJson(filePath) as Record<string, unknown> | null

  if (!config) {
    return { valid: false, errors: [`Unable to read or parse ${filePath}`], warnings: [] }
  }

  // Required fields
  if (!config.root) {
    errors.push('Missing required field: "root" (project root path)')
  }

  if (!config.sourceRoot) {
    errors.push('Missing required field: "sourceRoot" (source code path)')
  }

  if (!config.projectType) {
    errors.push('Missing required field: "projectType" (library|application)')
  } else if (!["library", "application"].includes(config.projectType as string)) {
    errors.push(`Invalid projectType: "${config.projectType}" (must be "library" or "application")`)
  }

  // Tags validation (CRITICAL for module boundaries)
  const tags = config.tags as string[] | undefined
  if (!tags || tags.length === 0) {
    errors.push(
      'Missing required field: "tags" array\n' +
        "     Tags are REQUIRED for @nx/enforce-module-boundaries.\n" +
        '     Add at minimum: ["type:<type>", "scope:<scope>"]'
    )
  } else {
    // Validate tag structure
    const hasTypeTag = tags.some((tag) => tag.startsWith("type:"))
    const hasScopeTag = tags.some((tag) => tag.startsWith("scope:"))

    if (!hasTypeTag) {
      errors.push(
        'Missing required tag dimension: "type:*"\n' +
          `     Valid types: ${VALID_LIBRARY_TYPES.map((t) => `type:${t}`).join(", ")}`
      )
    } else {
      // Validate type tag value
      const typeTag = tags.find((tag) => tag.startsWith("type:"))
      if (typeTag) {
        const typeValue = typeTag.replace("type:", "")
        if (!VALID_LIBRARY_TYPES.includes(typeValue as (typeof VALID_LIBRARY_TYPES)[number])) {
          warnings.push(
            `Non-standard type tag: "${typeTag}"\n` +
              `     Standard types: ${VALID_LIBRARY_TYPES.map((t) => `type:${t}`).join(", ")}`
          )
        }
      }
    }

    if (!hasScopeTag) {
      errors.push(
        'Missing required tag dimension: "scope:*"\n' + '     Examples: scope:shared, scope:booking, scope:admin'
      )
    }
  }

  // Targets validation
  const targets = config.targets as Record<string, unknown> | undefined
  if (!targets) {
    warnings.push(
      'Missing "targets" field. Recommended targets: build, test, lint\n' +
        "     Targets enable Nx caching and task orchestration"
    )
  } else {
    // Check for recommended targets
    const recommendedTargets = ["build", "test", "lint"]
    for (const target of recommendedTargets) {
      if (!(target in targets)) {
        warnings.push(`Missing recommended target: "${target}"`)
      }
    }

    // Validate executor usage
    for (const [targetName, targetConfig] of Object.entries(targets)) {
      const target = targetConfig as Record<string, unknown>
      const executor = target.executor as string | undefined

      if (executor && !APPROVED_EXECUTORS.has(executor)) {
        warnings.push(
          `Non-standard executor in target "${targetName}": ${executor}\n` +
            `     Approved executors: ${Array.from(APPROVED_EXECUTORS).slice(0, 5).join(", ")}...`
        )
      }
    }
  }

  // Schema field (recommended for IDE autocomplete)
  if (!config.$schema) {
    warnings.push(
      'Missing "$schema" field (recommended for IDE autocomplete)\n' +
        '     Add: "$schema": "../../node_modules/nx/schemas/project-schema.json"'
    )
  }

  return { valid: errors.length === 0, errors, warnings }
}

// ============================================================================
// VALIDATION: ESM COMPLIANCE
// ============================================================================

/**
 * Validate package.json for ESM compliance
 */
function validateESMPackageJson(filePath: string): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  const pkg = safeReadJson(filePath) as Record<string, unknown> | null

  if (!pkg) {
    return { valid: false, errors: [`Unable to read or parse ${filePath}`], warnings: [] }
  }

  // Skip if this is the root workspace package.json
  if (pkg.workspaces || pkg.private === true) {
    return { valid: true, errors: [], warnings: [] }
  }

  // Required: "type": "module"
  if (pkg.type !== "module") {
    errors.push(
      'ESM Violation: package.json must have "type": "module"\n' +
        "     This enables native ESM in Node.js\n" +
        '     Add: "type": "module"'
    )
  }

  // Recommended: "exports" field
  if (!pkg.exports) {
    warnings.push(
      'ESM Recommendation: Add "exports" field for modern resolution\n' +
        "     Example:\n" +
        '     "exports": {\n' +
        '       ".": {\n' +
        '         "types": "./dist/index.d.ts",\n' +
        '         "import": "./dist/index.js"\n' +
        "       }\n" +
        "     }"
    )
  }

  // Deprecated: "main" and "module" fields
  if (pkg.main && pkg.exports) {
    warnings.push(
      'ESM Deprecation: "main" field is legacy when "exports" is present\n' +
        '     Modern bundlers and Node.js use "exports" for resolution'
    )
  }

  if (pkg.module) {
    warnings.push(
      'ESM Deprecation: "module" field is non-standard\n' + '     Use "exports" with "import" condition instead'
    )
  }

  return { valid: errors.length === 0, errors, warnings }
}

/**
 * Validate tsconfig.json for ESM compliance
 */
function validateESMTsConfig(filePath: string): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  const tsconfig = safeReadJson(filePath) as Record<string, unknown> | null

  if (!tsconfig) {
    return { valid: false, errors: [`Unable to read or parse ${filePath}`], warnings: [] }
  }

  const compilerOptions = tsconfig.compilerOptions as Record<string, unknown> | undefined

  if (!compilerOptions) {
    warnings.push('Missing "compilerOptions" in tsconfig.json')
    return { valid: true, errors, warnings }
  }

  // Validate module setting
  const moduleValue = compilerOptions.module as string | undefined
  if (moduleValue && !VALID_ESM_MODULES.has(moduleValue)) {
    errors.push(
      `ESM Violation: "module" must be ESNext or NodeNext\n` +
        `     Current: "${moduleValue}"\n` +
        `     Valid options: ${Array.from(VALID_ESM_MODULES).join(", ")}`
    )
  }

  // Validate moduleResolution setting
  const moduleResolution = compilerOptions.moduleResolution as string | undefined
  if (moduleResolution && !VALID_ESM_MODULE_RESOLUTIONS.has(moduleResolution)) {
    errors.push(
      `ESM Violation: "moduleResolution" must be bundler or NodeNext\n` +
        `     Current: "${moduleResolution}"\n` +
        `     Valid options: ${Array.from(VALID_ESM_MODULE_RESOLUTIONS).join(", ")}`
    )
  }

  // Recommended: isolatedModules
  if (compilerOptions.isolatedModules !== true) {
    warnings.push(
      'ESM Recommendation: Enable "isolatedModules": true\n' +
        "     This ensures each file can be transpiled independently\n" +
        "     Required for esbuild, swc, and other fast compilers"
    )
  }

  // Recommended: esModuleInterop
  if (compilerOptions.esModuleInterop !== true) {
    warnings.push(
      'ESM Recommendation: Enable "esModuleInterop": true\n' + "     This improves interoperability with CommonJS modules"
    )
  }

  return { valid: errors.length === 0, errors, warnings }
}

// ============================================================================
// PLUGIN EXPORT
// ============================================================================

/**
 * Nx Guardrails Plugin
 *
 * Event hooks:
 * - tool.execute.before: Intercept Nx CLI commands for naming/bypass validation
 * - file.edited: Validate project.json, package.json, tsconfig.json edits
 */
export const NxGuardrails: Plugin = async ({ project, directory, worktree }) => {
  const nxInfo = detectNxMonorepo(directory)
  const projectName = (project as Record<string, unknown>)?.name ?? "unknown-project"

  if (nxInfo) {
    console.log(`[nx-guardrails] Detected Nx workspace: ${nxInfo.rootPath} (v${nxInfo.nxVersion})`)
  }

  return {
    "tool.execute.before": async (
      input: { tool: string; sessionID: string; callID: string },
      output: { args: Record<string, unknown> }
    ) => {
      if (!nxInfo) return

      const toolName = (input?.tool ?? "").toLowerCase().trim()
      if (toolName !== "bash") return

      const command = (output?.args?.command ?? "") as string
      const commandStr = typeof command === "string" ? command : JSON.stringify(command)
      if (!commandStr.trim()) return

      for (const violation of NAMING_VIOLATIONS) {
        if (violation.pattern.test(commandStr)) {
          throw makeError(formatViolationError(violation, { command: commandStr }), {
            project: projectName,
            directory,
            worktree,
            command: commandStr,
            remediation: violation.remediation,
          })
        }
      }

      for (const bypass of BLOCKED_NX_BYPASSES) {
        if (bypass.pattern.test(commandStr)) {
          throw makeError(formatViolationError(bypass, { command: commandStr }), {
            project: projectName,
            directory,
            worktree,
            command: commandStr,
            remediation: bypass.remediation,
          })
        }
      }
    },

    event: async ({ event }: { event: { type?: string; path?: string; filePath?: string } }) => {
      if (!nxInfo) return

      const eventType = event?.type
      if (eventType !== "file.edited") return

      const filePath = event?.path ?? event?.filePath ?? ""
      if (!filePath) return

      if (filePath.endsWith("/project.json") || filePath.endsWith("\\project.json")) {
        const result = validateProjectJson(filePath)
        if (!result.valid) {
          throw makeError(formatValidationErrors(result, { file: filePath }), {
            project: projectName,
            directory,
            worktree,
            file: filePath,
            errors: result.errors,
            warnings: result.warnings,
          })
        }

        if (result.warnings.length > 0) {
          console.warn(`[nx-guardrails] Warnings for ${filePath}:`)
          for (const warning of result.warnings) {
            console.warn(`  ⚠️ ${warning}`)
          }
        }
      }

      if (filePath.endsWith("/package.json") || filePath.endsWith("\\package.json")) {
        const isLibraryPackage =
          filePath.includes(`/${nxInfo.workspaceLayout.libsDir}/`) ||
          filePath.includes(`\\${nxInfo.workspaceLayout.libsDir}\\`)

        if (isLibraryPackage) {
          const result = validateESMPackageJson(filePath)
          if (!result.valid) {
            throw makeError(formatValidationErrors(result, { file: filePath }), {
              project: projectName,
              directory,
              worktree,
              file: filePath,
              errors: result.errors,
              warnings: result.warnings,
            })
          }

          if (result.warnings.length > 0) {
            console.warn(`[nx-guardrails] Warnings for ${filePath}:`)
            for (const warning of result.warnings) {
              console.warn(`  ⚠️ ${warning}`)
            }
          }
        }
      }

      if (
        filePath.endsWith("/tsconfig.json") ||
        filePath.endsWith("\\tsconfig.json") ||
        filePath.endsWith("/tsconfig.lib.json") ||
        filePath.endsWith("\\tsconfig.lib.json")
      ) {
        const isLibraryTsConfig =
          filePath.includes(`/${nxInfo.workspaceLayout.libsDir}/`) ||
          filePath.includes(`\\${nxInfo.workspaceLayout.libsDir}\\`)

        if (isLibraryTsConfig) {
          const result = validateESMTsConfig(filePath)
          if (!result.valid) {
            throw makeError(formatValidationErrors(result, { file: filePath }), {
              project: projectName,
              directory,
              worktree,
              file: filePath,
              errors: result.errors,
              warnings: result.warnings,
            })
          }

          if (result.warnings.length > 0) {
            console.warn(`[nx-guardrails] Warnings for ${filePath}:`)
            for (const warning of result.warnings) {
              console.warn(`  ⚠️ ${warning}`)
            }
          }
        }
      }
    },
  }
}

export default NxGuardrails
