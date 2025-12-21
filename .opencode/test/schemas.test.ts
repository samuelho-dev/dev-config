import { describe, test, expect } from "bun:test"
import { Schema, pipe } from "effect"

// Import shared schemas
import {
  PolicyModeSchema,
  SeveritySchema,
  ErrorCodeSchema,
  ViolationSchema,
  policyViolation,
  makeRunId,
  makeContextVersion,
} from "../lib/shared-schemas"

describe("Shared Schemas", () => {
  describe("PolicyModeSchema", () => {
    test("accepts valid policy modes", () => {
      expect(Schema.decodeUnknownSync(PolicyModeSchema)("strict")).toBe("strict")
      expect(Schema.decodeUnknownSync(PolicyModeSchema)("standard")).toBe("standard")
      expect(Schema.decodeUnknownSync(PolicyModeSchema)("off")).toBe("off")
    })

    test("rejects invalid policy modes", () => {
      expect(() => Schema.decodeUnknownSync(PolicyModeSchema)("invalid")).toThrow()
      expect(() => Schema.decodeUnknownSync(PolicyModeSchema)(123)).toThrow()
    })
  })

  describe("SeveritySchema", () => {
    test("accepts valid severities", () => {
      expect(Schema.decodeUnknownSync(SeveritySchema)("info")).toBe("info")
      expect(Schema.decodeUnknownSync(SeveritySchema)("warn")).toBe("warn")
      expect(Schema.decodeUnknownSync(SeveritySchema)("error")).toBe("error")
    })
  })

  describe("ErrorCodeSchema", () => {
    test("accepts valid error codes", () => {
      expect(Schema.decodeUnknownSync(ErrorCodeSchema)("POLICY_VIOLATION")).toBe("POLICY_VIOLATION")
      expect(Schema.decodeUnknownSync(ErrorCodeSchema)("CONTEXT_STALE")).toBe("CONTEXT_STALE")
    })
  })

  describe("ViolationSchema", () => {
    test("accepts valid violation", () => {
      const violation = {
        code: "test/violation",
        severity: "error",
        message: "Test violation message",
        remediation: ["Fix step 1", "Fix step 2"],
      }
      const decoded = Schema.decodeUnknownSync(ViolationSchema)(violation)
      expect(decoded.code).toBe("test/violation")
      expect(decoded.severity).toBe("error")
      expect(decoded.remediation).toEqual(["Fix step 1", "Fix step 2"])
    })

    test("accepts violation without remediation", () => {
      const violation = {
        code: "test/violation",
        severity: "warn",
        message: "Test warning",
      }
      const decoded = Schema.decodeUnknownSync(ViolationSchema)(violation)
      expect(decoded.remediation).toBeUndefined()
    })
  })
})

describe("Helper Functions", () => {
  describe("policyViolation", () => {
    test("creates violation with remediation", () => {
      const violation = policyViolation("test/code", "Test message", ["Step 1", "Step 2"])
      expect(violation.code).toBe("test/code")
      expect(violation.severity).toBe("error")
      expect(violation.message).toBe("Test message")
      expect(violation.remediation).toEqual(["Step 1", "Step 2"])
    })

    test("creates violation without remediation", () => {
      const violation = policyViolation("test/code", "Test message")
      expect(violation.remediation).toBeUndefined()
    })
  })

  describe("makeRunId", () => {
    test("creates unique run IDs", () => {
      const id1 = makeRunId("test")
      const id2 = makeRunId("test")
      expect(id1).toMatch(/^test_/)
      expect(id2).toMatch(/^test_/)
      expect(id1).not.toBe(id2)
    })

    test("includes prefix", () => {
      const id = makeRunId("gritql_check")
      expect(id.startsWith("gritql_check_")).toBe(true)
    })
  })

  describe("makeContextVersion", () => {
    test("creates context version with hash", () => {
      const ctx = makeContextVersion("test pattern content")
      expect(ctx.version).toMatch(/^v1_/)
      expect(ctx.timestamp).toBeDefined()
      expect(ctx.hash).toHaveLength(16)
    })

    test("same content produces same hash", () => {
      const ctx1 = makeContextVersion("same content")
      const ctx2 = makeContextVersion("same content")
      expect(ctx1.hash).toBe(ctx2.hash)
    })

    test("different content produces different hash", () => {
      const ctx1 = makeContextVersion("content A")
      const ctx2 = makeContextVersion("content B")
      expect(ctx1.hash).not.toBe(ctx2.hash)
    })
  })
})
