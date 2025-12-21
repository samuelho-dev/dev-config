import { Schema, Data } from "effect"

// ============================================================================
// SHARED EFFECT SCHEMAS
// Reusable schemas for OpenCode tools (gritql.ts, mlg.ts)
// ============================================================================

// ============================================================================
// POLICY & SEVERITY
// ============================================================================

export const PolicyModeSchema = Schema.Literal("strict", "standard", "off")
export type PolicyMode = Schema.Schema.Type<typeof PolicyModeSchema>

export const SeveritySchema = Schema.Literal("info", "warn", "error")
export type Severity = Schema.Schema.Type<typeof SeveritySchema>

// ============================================================================
// ERROR CODES & RETRY STRATEGIES
// ============================================================================

export const ErrorCodeSchema = Schema.Literal(
  "POLICY_VIOLATION",
  "MISSING_PREREQUISITE",
  "EXECUTION_ERROR",
  "RESOURCE_NOT_FOUND",
  "CONTEXT_STALE",
  "VALIDATION_ERROR"
)
export type ErrorCode = Schema.Schema.Type<typeof ErrorCodeSchema>

export const RetryStrategySchema = Schema.Literal(
  "fix_args", // Fix arguments and retry
  "run_prerequisite", // Run another command first
  "escalate", // Needs human intervention
  "backoff" // Wait and retry
)
export type RetryStrategy = Schema.Schema.Type<typeof RetryStrategySchema>

// ============================================================================
// VIOLATIONS & RECOMMENDATIONS
// ============================================================================

export const ViolationSchema = Schema.Struct({
  code: Schema.String,
  severity: SeveritySchema,
  message: Schema.String,
  remediation: Schema.optional(Schema.Array(Schema.String)),
})
export type Violation = Schema.Schema.Type<typeof ViolationSchema>

export const RecommendationSchema = Schema.Struct({
  action: Schema.String,
  priority: Schema.Literal("required", "suggested", "optional"),
  confidence: Schema.optional(Schema.Number),
})
export type Recommendation = Schema.Schema.Type<typeof RecommendationSchema>

// ============================================================================
// CONTEXT VERSION TRACKING
// ============================================================================

export const ContextVersionSchema = Schema.Struct({
  version: Schema.String,
  timestamp: Schema.String,
  hash: Schema.optional(Schema.String),
})
export type ContextVersion = Schema.Schema.Type<typeof ContextVersionSchema>

// ============================================================================
// LIBRARY TYPES (MLG)
// ============================================================================

export const LibraryTypeSchema = Schema.Literal(
  "contract",
  "data-access",
  "feature",
  "infra",
  "provider"
)
export type LibraryType = Schema.Schema.Type<typeof LibraryTypeSchema>

export const EffectLayerSchema = Schema.Literal(
  "Domain",
  "Service",
  "Orchestration",
  "Infrastructure",
  "Integration"
)
export type EffectLayer = Schema.Schema.Type<typeof EffectLayerSchema>

export const PlatformSchema = Schema.Literal("node", "universal", "edge")
export type Platform = Schema.Schema.Type<typeof PlatformSchema>

// ============================================================================
// LIBRARY TYPE → EFFECT LAYER MAPPING
// ============================================================================

export const LIBRARY_TYPE_TO_LAYER: Record<LibraryType, EffectLayer> = {
  contract: "Domain",
  "data-access": "Service",
  feature: "Orchestration",
  infra: "Infrastructure",
  provider: "Integration",
}

// ============================================================================
// EXTRACTION SCHEMAS (for safe unknown parsing)
// ============================================================================

export const ErrorMessageSchema = Schema.Struct({ message: Schema.String })
export const ErrorStderrSchema = Schema.Struct({ stderr: Schema.String })

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

export const nowIso = () => new Date().toISOString()

export const makeRunId = (prefix: string) =>
  `${prefix}_${nowIso()}_${Math.random().toString(16).slice(2)}`

export const makeContextVersion = (source: string) => ({
  version: `v1_${nowIso()}`,
  timestamp: nowIso(),
  hash: Buffer.from(source).toString("base64").slice(0, 16),
})

export const policyViolation = (
  code: string,
  message: string,
  remediation?: readonly string[]
): Violation => ({
  code,
  severity: "error",
  message,
  remediation: remediation ? [...remediation] : undefined,
})

// ============================================================================
// BASE TAGGED ERRORS
// ============================================================================

export class ToolNotFoundError extends Data.TaggedError("ToolNotFoundError")<{
  readonly tool: string
  readonly message: string
  readonly recommendations: readonly string[]
}> {}

export class ResourceNotFoundError extends Data.TaggedError("ResourceNotFoundError")<{
  readonly resource: string
  readonly message: string
  readonly recommendations: readonly string[]
}> {}

export class ExecutionError extends Data.TaggedError("ExecutionError")<{
  readonly stage: string
  readonly message: string
  readonly output: string | undefined
}> {}

export class ContextStaleError extends Data.TaggedError("ContextStaleError")<{
  readonly resource: string
  readonly expectedVersion: string
  readonly actualVersion: string
  readonly message: string
}> {}
