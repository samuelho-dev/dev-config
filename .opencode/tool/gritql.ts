import { tool } from "@opencode-ai/plugin";
import { existsSync, readdirSync } from "fs";
import { join } from "path";

type PolicyMode = "strict" | "standard" | "off";

type Command = "listPatterns" | "checkPattern" | "applyPattern" | "checkProject" | "explainUsage";

type Severity = "info" | "warn" | "error";

type Match = {
  file: string;
  startLine?: number;
  endLine?: number;
  // Optional: if grit provides it. Keep fields optional for compatibility.
  startColumn?: number;
  endColumn?: number;
  snippet?: string;
};

type Summary = {
  target: string;
  dryRun: boolean;
  patternsRun: number;
  matches: number;
  filesWithMatches: number;
  filesScanned?: number;
};

type Diff = {
  available: boolean;
  unified?: string;
};

type Violation = {
  code: string;
  severity: Severity;
  message: string;
  remediation?: string[];
};

type Response = {
  success: boolean;

  // Request echo
  command: Command;
  policy: PolicyMode;
  target: string;

  // Pattern identity
  patternName?: string;
  patternSource?: "repo" | "inline";

  // Workflow fields
  dryRun: boolean;
  runId?: string;
  confirm?: boolean;

  // Results
  summary?: Summary;
  matches?: Match[];
  diff?: Diff;
  violations?: Violation[];

  // Human readable (still useful in UI)
  output?: string;

  // Guidance
  recommendations?: string[];

  // Error
  error?: string;
};

const DEFAULT_POLICY: PolicyMode = "strict";

// Repo convention
const REPO_PATTERNS_DIR = join(process.cwd(), "biome", "gritql-patterns");

// Default ruleset for checkProject (can be overridden via args.patternNames).
const DEFAULT_RULESET: string[] = [
  "detect-missing-yield-star",
  "ban-any-type-annotation",
  "ban-type-assertions",
  "ban-satisfies",
  "ban-relative-parent-imports",
  "prefer-object-spread",
  "ban-default-export-non-index",
  "ban-push-spread",
  "ban-return-types",
  "enforce-effect-pipe",
  "enforce-esm-package-type",
  "enforce-nx-project-tags",
  "enforce-strict-tsconfig",
];

function nowIso(): string {
  return new Date().toISOString();
}

function makeRunId(prefix: string): string {
  // Deterministic enough for session-local enforcement, no crypto required.
  return `${prefix}_${nowIso()}_${Math.random().toString(16).slice(2)}`;
}

function normalizeTarget(input: string): string {
  const t = (input ?? "").trim();
  return t.length === 0 ? "." : t;
}

function listRepoPatterns(): string[] {
  if (!existsSync(REPO_PATTERNS_DIR)) return [];
  return readdirSync(REPO_PATTERNS_DIR)
    .filter((f) => f.endsWith(".grit"))
    .map((f) => f.replace(/\.grit$/u, ""))
    .sort();
}

function readRepoPattern(
  patternName: string,
): { ok: true; text: string } | { ok: false; error: string } {
  const safeName = (patternName ?? "").trim();
  if (!safeName) return { ok: false, error: "patternName is required." };

  const pPath = join(REPO_PATTERNS_DIR, `${safeName}.grit`);
  if (!existsSync(pPath)) {
    return {
      ok: false,
      error: `Pattern '${safeName}' not found. Expected file: biome/gritql-patterns/${safeName}.grit`,
    };
  }

  // Bun.file is available in OpenCode runtime (Bun).
  return { ok: true, text: Bun.file(pPath).text() as unknown as string };
}

async function ensureGritAvailable(): Promise<
  { ok: true } | { ok: false; error: string; recommendations: string[] }
> {
  try {
    // In this repo, `grit` is provided via Nix wrapper (pkgs/grit.nix).
    await Bun.$`grit --version`.quiet();
    return { ok: true };
  } catch {
    return {
      ok: false,
      error: "Grit CLI not found in PATH.",
      recommendations: [
        "Enter the dev shell: `nix develop` (recommended), or ensure Home Manager/dev-config is applied.",
        "If you are not using Nix, install Grit CLI: https://docs.grit.io/cli/quickstart",
      ],
    };
  }
}

function policyViolation(code: string, message: string, remediation?: string[]): Violation {
  return {
    code,
    severity: "error",
    message,
    remediation,
  };
}

/**
 * STRICT policy:
 * - applyPattern requires confirm=true
 * - applyPattern requires a prior checkPattern runId (unless policy=off)
 * - inline pattern is discouraged; require justification via allowInline=true (strict)
 */
function enforcePolicy(args: {
  policy: PolicyMode;
  command: Command;
  patternName?: string;
  pattern?: string;
  allowInline?: boolean;
  confirm?: boolean;
  runId?: string;
}): Violation[] {
  const violations: Violation[] = [];
  const { policy, command, patternName, pattern, allowInline, confirm, runId } = args;

  if (policy === "off") return violations;

  const hasName = Boolean(patternName && patternName.trim().length > 0);
  const hasInline = Boolean(pattern && pattern.trim().length > 0);

  if (!hasName && !hasInline && command !== "listPatterns" && command !== "explainUsage") {
    violations.push(
      policyViolation("gritql/missing-pattern", "Either patternName or pattern must be provided.", [
        "Prefer `patternName` pointing to biome/gritql-patterns/<name>.grit.",
        "Use `listPatterns` to discover available rules.",
      ]),
    );
  }

  if (policy === "strict") {
    if (hasInline && !hasName && !allowInline) {
      violations.push(
        policyViolation(
          "gritql/inline-pattern-disallowed",
          "Inline patterns are disallowed under strict policy. Use a named repo pattern.",
          [
            "Create or reuse a pattern in `biome/gritql-patterns/` and reference it via patternName.",
            "If you must run inline temporarily, set allowInline=true (discouraged) and justify in your prompt.",
          ],
        ),
      );
    }

    if (command === "applyPattern") {
      if (!confirm) {
        violations.push(
          policyViolation(
            "gritql/apply-requires-confirm",
            "applyPattern requires confirm=true under strict policy.",
            [
              "Run checkPattern first to produce a dry-run diff, review it, then re-run applyPattern with confirm=true.",
            ],
          ),
        );
      }

      if (!runId) {
        violations.push(
          policyViolation(
            "gritql/apply-requires-runid",
            "applyPattern requires a runId from a prior checkPattern under strict policy.",
            [
              "Run checkPattern (dryRun=true) first; it returns runId.",
              "Call applyPattern with that runId to prove review intent.",
            ],
          ),
        );
      }
    }
  }

  return violations;
}

/**
 * Execute `grit apply` and return raw output.
 * We intentionally rely on the `grit` wrapper in PATH (Nix-managed).
 */
async function runGritApply(params: {
  patternText: string;
  target: string;
  dryRun: boolean;
}): Promise<string> {
  const { patternText, target, dryRun } = params;

  // NOTE: We pass the pattern text directly as an argument. If grit CLI ever changes expectations,
  // we can pivot to writing a temp pattern file, but that requires filesystem writes.
  if (dryRun) {
    return Bun.$`grit apply ${patternText} ${target} --dry-run`.text();
  }
  return Bun.$`grit apply ${patternText} ${target}`.text();
}

/**
 * Best-effort parse for matches from Grit output.
 * Grit output formats can vary, so we keep this heuristic and non-fatal.
 */
function parseMatchesBestEffort(raw: string): Match[] {
  const matches: Match[] = [];
  const lines = raw.split("\n");

  // Heuristic 1: file:line:col style
  const re1 = /^(.+?):(\d+):(\d+):\s*(.*)$/u;
  // Heuristic 2: file:line style
  const re2 = /^(.+?):(\d+):\s*(.*)$/u;

  for (const line of lines) {
    const m1 = line.match(re1);
    if (m1) {
      matches.push({
        file: m1[1],
        startLine: Number(m1[2]),
        startColumn: Number(m1[3]),
        snippet: m1[4] || undefined,
      });
      continue;
    }

    const m2 = line.match(re2);
    if (m2) {
      matches.push({
        file: m2[1],
        startLine: Number(m2[2]),
        snippet: m2[3] || undefined,
      });
    }
  }

  return matches;
}

function summarize(
  target: string,
  dryRun: boolean,
  patternsRun: number,
  matches: Match[],
): Summary {
  const filesWithMatches = new Set(matches.map((m) => m.file)).size;
  return {
    target,
    dryRun,
    patternsRun,
    matches: matches.length,
    filesWithMatches,
  };
}

function usageText(): string {
  return [
    "gritql pseudo-API (LLM-optimized)",
    "",
    "STRICT POLICY (default):",
    "- All search/lint/modify must go through this tool.",
    "- applyPattern requires confirm=true and a runId from a prior checkPattern.",
    "- Inline patterns are discouraged; prefer repo patterns in biome/gritql-patterns/.",
    "",
    "Commands:",
    "1) listPatterns",
    "2) checkPattern (dry-run structural search + diff)",
    "3) applyPattern (structural rewrite; requires confirm + runId in strict mode)",
    "4) checkProject (run a ruleset of repo patterns across a target)",
    "",
    "Examples:",
    "- Find console.log:",
    '  checkPattern: pattern="`console.log($_)`" target="src/" allowInline=true',
    "",
    "- Apply a named pattern:",
    '  checkPattern: patternName="detect-missing-yield-star" target="."',
    '  applyPattern: patternName="detect-missing-yield-star" target="." runId=<from check> confirm=true',
    "",
    "- Run repo ruleset:",
    '  checkProject: patternNames=[...] target="."',
  ].join("\n");
}

export default tool({
  description:
    "STRICT pseudo-API for structural search, linting, and refactoring via GritQL. Safe-by-default and policy-enforcing for LLM workflows.",
  args: {
    command: tool.schema
      .string()
      .describe("One of: listPatterns, checkPattern, applyPattern, checkProject, explainUsage")
      .default("checkPattern"),
    policy: tool.schema
      .string()
      .optional()
      .describe("Policy mode: strict (default), standard, off"),
    target: tool.schema.string().optional().describe("Target file or directory (default: '.')"),
    patternName: tool.schema
      .string()
      .optional()
      .describe("Name of repo pattern in biome/gritql-patterns (no extension)"),
    pattern: tool.schema
      .string()
      .optional()
      .describe("Inline GritQL pattern text (discouraged in strict mode)"),
    allowInline: tool.schema
      .boolean()
      .optional()
      .describe("Allow inline pattern under strict policy (discouraged). Default false.")
      .default(false),

    // Workflow enforcement
    runId: tool.schema
      .string()
      .optional()
      .describe("Run id returned by checkPattern; required for applyPattern in strict policy."),
    confirm: tool.schema
      .boolean()
      .optional()
      .describe("Explicit confirmation required for applyPattern in strict policy.")
      .default(false),

    // checkProject options
    patternNames: tool.schema
      .array(tool.schema.string())
      .optional()
      .describe("List of repo patterns to run for checkProject (defaults to curated ruleset)."),

    // Output controls
    includeDiff: tool.schema
      .boolean()
      .optional()
      .describe("Include unified diff output when available (default true).")
      .default(true),
  },

  async execute(args): Promise<Response> {
    const command = (args.command as Command) ?? "checkPattern";
    const policy = ((args.policy as PolicyMode) ?? DEFAULT_POLICY) as PolicyMode;
    const target = normalizeTarget((args.target as string) ?? ".");
    const patternName = (args.patternName as string | undefined) ?? undefined;
    const pattern = (args.pattern as string | undefined) ?? undefined;
    const allowInline = Boolean(args.allowInline);
    const includeDiff = Boolean(args.includeDiff);
    const confirm = Boolean(args.confirm);
    const runId = (args.runId as string | undefined) ?? undefined;

    if (command === "explainUsage") {
      return {
        success: true,
        command,
        policy,
        target,
        dryRun: true,
        output: usageText(),
        recommendations: [
          "Use checkPattern first (dry-run).",
          "Under strict policy, applyPattern requires confirm=true and runId from checkPattern.",
          "Prefer repo patterns in biome/gritql-patterns/.",
        ],
      };
    }

    if (command === "listPatterns") {
      const patterns = listRepoPatterns();
      return {
        success: true,
        command,
        policy,
        target,
        dryRun: true,
        output: patterns.length
          ? `Available repo patterns:\n- ${patterns.join("\n- ")}`
          : "No repo patterns found.",
        recommendations: patterns.length
          ? ["Use checkPattern with patternName=<one of the listed patterns>."]
          : [
              "Add patterns to biome/gritql-patterns/*.grit",
              "Then use listPatterns to confirm discovery.",
            ],
      };
    }

    const gritOk = await ensureGritAvailable();
    if (!gritOk.ok) {
      return {
        success: false,
        command,
        policy,
        target,
        dryRun: true,
        error: gritOk.error,
        recommendations: gritOk.recommendations,
      };
    }

    // Policy enforcement (pre-flight)
    const violations = enforcePolicy({
      policy,
      command,
      patternName,
      pattern,
      allowInline,
      confirm,
      runId,
    });
    if (violations.length > 0) {
      return {
        success: false,
        command,
        policy,
        target,
        patternName: patternName?.trim() ? patternName.trim() : undefined,
        patternSource: patternName ? "repo" : pattern ? "inline" : undefined,
        dryRun: command !== "applyPattern",
        confirm,
        runId,
        violations,
        error: "Policy violation: request rejected.",
        recommendations: [
          "Fix violations and retry.",
          "Use explainUsage for the required workflow.",
        ],
      };
    }

    // Resolve pattern text (repo or inline)
    let patternText = "";
    let patternSource: "repo" | "inline" | undefined;

    if (patternName && patternName.trim().length > 0) {
      const r = readRepoPattern(patternName);
      if (!r.ok) {
        return {
          success: false,
          command,
          policy,
          target,
          patternName: patternName.trim(),
          dryRun: true,
          error: r.error,
          recommendations: [
            "Run listPatterns to see valid pattern names.",
            "Ensure the pattern file exists under biome/gritql-patterns/.",
          ],
        };
      }
      // Bun.file().text() returns a Promise-like; ensure we await properly.
      // The helper returned `text` typed as string but it is a Promise in reality.
      // We normalize here safely.
      patternText = await (r.text as unknown as Promise<string>);
      patternSource = "repo";
    } else if (pattern && pattern.trim().length > 0) {
      patternText = pattern;
      patternSource = "inline";
    }

    // Execute by command
    if (command === "checkPattern") {
      const thisRunId = makeRunId("gritql_check");
      try {
        const raw = await runGritApply({ patternText, target, dryRun: true });
        const matches = parseMatchesBestEffort(raw);

        return {
          success: true,
          command,
          policy,
          target,
          patternName: patternName?.trim() ? patternName.trim() : undefined,
          patternSource,
          dryRun: true,
          runId: thisRunId,
          summary: summarize(target, true, 1, matches),
          matches,
          diff: includeDiff
            ? { available: raw.trim().length > 0, unified: raw }
            : { available: false },
          output: raw.trim().length ? raw : "No matches found or no changes required.",
          recommendations: [
            "Review matches/diff.",
            policy === "strict"
              ? "If you want to modify code, call applyPattern with confirm=true and runId from this response."
              : "If you want to modify code, call applyPattern.",
            "After applying changes, run `biome check .` (and any relevant project checks).",
          ],
        };
      } catch (e: any) {
        return {
          success: false,
          command,
          policy,
          target,
          patternName: patternName?.trim() ? patternName.trim() : undefined,
          patternSource,
          dryRun: true,
          runId: thisRunId,
          error: `Grit execution failed: ${e?.message ?? String(e)}`,
          output: e?.stderr?.toString?.() || e?.stdout?.toString?.(),
          recommendations: [
            "Ensure the GritQL pattern is valid.",
            "Try narrowing the target.",
            "If this is a repo pattern, validate the .grit file syntax.",
          ],
        };
      }
    }

    if (command === "applyPattern") {
      const thisRunId = makeRunId("gritql_apply");
      try {
        // Standard practice: always run a dry-run first for reporting.
        const dry = await runGritApply({ patternText, target, dryRun: true });

        // In strict mode, require confirm already enforced above. Proceed with apply.
        const applied = await runGritApply({ patternText, target, dryRun: false });

        const matches = parseMatchesBestEffort(dry);

        return {
          success: true,
          command,
          policy,
          target,
          patternName: patternName?.trim() ? patternName.trim() : undefined,
          patternSource,
          dryRun: false,
          runId: thisRunId,
          confirm,
          summary: summarize(target, false, 1, matches),
          matches,
          diff: includeDiff
            ? { available: dry.trim().length > 0, unified: dry }
            : { available: false },
          output: applied.trim().length ? applied : "Applied. (No additional output.)",
          recommendations: [
            "Run `biome check .` to validate formatting/linting.",
            "If this touched Nix files, run `nix flake show` / `home-manager build` as applicable.",
            "Review `git diff` and commit with a clear message.",
          ],
        };
      } catch (e: any) {
        return {
          success: false,
          command,
          policy,
          target,
          patternName: patternName?.trim() ? patternName.trim() : undefined,
          patternSource,
          dryRun: false,
          runId: thisRunId,
          confirm,
          error: `Grit execution failed: ${e?.message ?? String(e)}`,
          output: e?.stderr?.toString?.() || e?.stdout?.toString?.(),
          recommendations: [
            "Check that the pattern is valid and safe.",
            "Try re-running checkPattern first.",
            "Narrow the target to reduce blast radius.",
          ],
        };
      }
    }

    if (command === "checkProject") {
      const thisRunId = makeRunId("gritql_project");
      const names = (args.patternNames as string[] | undefined) ?? DEFAULT_RULESET;

      // Validate that all patterns exist
      const available = new Set(listRepoPatterns());
      const missing = names.filter((n) => !available.has(n));
      if (missing.length > 0) {
        return {
          success: false,
          command,
          policy,
          target,
          dryRun: true,
          runId: thisRunId,
          violations: [
            policyViolation(
              "gritql/missing-patterns",
              `Some patterns were not found in biome/gritql-patterns/: ${missing.join(", ")}`,
              [
                "Run listPatterns to see available patterns.",
                "Fix the rule list or add missing .grit files.",
              ],
            ),
          ],
          error: "Ruleset contains missing patterns.",
        };
      }

      const allMatches: Match[] = [];
      const perRule: Array<{ patternName: string; output: string; matches: Match[] }> = [];

      try {
        for (const name of names) {
          const r = readRepoPattern(name);
          if (!r.ok) {
            // Should not happen due to missing check above, but keep defensive.
            return {
              success: false,
              command,
              policy,
              target,
              dryRun: true,
              runId: thisRunId,
              error: r.error,
            };
          }
          const text = await (r.text as unknown as Promise<string>);
          const raw = await runGritApply({ patternText: text, target, dryRun: true });
          const matches = parseMatchesBestEffort(raw);
          for (const m of matches) allMatches.push(m);
          perRule.push({ patternName: name, output: raw, matches });
        }

        const summary = summarize(target, true, names.length, allMatches);

        const output =
          [
            `checkProject complete (dry-run):`,
            `- patternsRun: ${summary.patternsRun}`,
            `- matches: ${summary.matches}`,
            `- filesWithMatches: ${summary.filesWithMatches}`,
            "",
            ...perRule.map((r) => {
              const count = r.matches.length;
              return `- ${r.patternName}: ${count} match${count === 1 ? "" : "es"}`;
            }),
          ].join("\n") + "\n";

        return {
          success: true,
          command,
          policy,
          target,
          dryRun: true,
          runId: thisRunId,
          summary,
          matches: allMatches,
          output,
          recommendations: [
            "Use checkPattern with a specific patternName to inspect diffs more closely.",
            policy === "strict"
              ? "Apply fixes via applyPattern per pattern with confirm=true and runId from the relevant checkPattern."
              : "Apply fixes via applyPattern per pattern.",
          ],
        };
      } catch (e) {
        return {
          success: false,
          command,
          policy,
          target,
          dryRun: true,
          runId: thisRunId,
          error: `Grit execution failed: ${e?.message ?? String(e)}`,
          output: e?.stderr?.toString?.() || e?.stdout?.toString?.(),
          recommendations: [
            "Try running patterns individually with checkPattern for easier debugging.",
          ],
        };
      }
    }

    return {
      success: false,
      command,
      policy,
      target,
      dryRun: true,
      error: `Unknown command: ${String(args.command)}`,
      recommendations: ["Use explainUsage to see valid commands and workflows."],
    };
  },
});
