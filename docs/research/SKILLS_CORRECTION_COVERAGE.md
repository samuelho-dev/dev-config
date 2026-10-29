# Skills correction implementation and coverage

**Completed 2026-10-29 within the frozen inventory and the limits below.**

## Scope and outcome

This is a documentation/skill-contract correction pass against the frozen 2026-10-29 inventory, not a behavioral evaluation or a certificate that every operational recipe is safe in every environment. No additional skill was deleted, merged, renamed or restored. No runtime, dependency, vendor package, owning application or infrastructure configuration was changed.

- **233 audited variants / 226 distinct names**; all exact variant paths have a disposition.
- **280 unique bounded public claims** have explicit dispositions, applied across **492 claim/variant pairs**. These are different units, not 492 independent public claims.
- **203 variants updated; 18 checked-no-change; 8 vendor-owned and 4 ownership-blocked variants left untouched.** A variant includes its supporting references, not just its top-level body.
- **250 existing skill/reference/mirror files changed:** 20 repository sources/support files, 190 learned bodies, and 40 verified writable former-export mirror files. The 210 non-mirror edits comprise **202 `SKILL.md` bodies and 8 references**; `codebase-design` was updated through references without rewriting its body. This summary and its index entry are additional documentation outputs.
- **340 original and pass-start file records preserved**; all eight earlier drafts independently reviewed and refined by native Pi workers.
- All **82** preserved curated mirror files match their **41** repository source/support files; only 40 required rewriting. Home Manager bootstraps CLIs and does **not** deploy these skill edits.

| Lane | Variants | Updated variants | Unchanged variants | Vendor-owned | Ownership-blocked | Changed files |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| infra | 47 | 46 | 1 | 0 | 0 | 46 |
| runtime | 43 | 40 | 3 | 0 | 0 | 40 |
| ctk-data | 28 | 28 | 0 | 0 | 0 | 28 |
| ctk-ui | 23 | 23 | 0 | 0 | 0 | 23 |
| agent-workflows | 40 | 39 | 1 | 0 | 0 | 39 |
| stripe-audiospace | 14 | 14 | 0 | 0 | 0 | 14 |
| curated-hosts | 38 | 13 | 13 | 8 | 4 | 60 |

## Repository-owned coverage

The Git publication contains the curated corrections and this coverage summary only. Detailed learned-skill bodies, private project evidence, local backups/diffs and pre-existing research drafts are not newly exported into the repository.

| Curated skill | Variant disposition (body and/or references) |
| --- | --- |
| [`ask-matt`](../../ai/skills/ask-matt/SKILL.md) | updated |
| [`code-review`](../../ai/skills/code-review/SKILL.md) | updated |
| [`codebase-design`](../../ai/skills/codebase-design/SKILL.md) | updated |
| [`diagnosing-bugs`](../../ai/skills/diagnosing-bugs/SKILL.md) | updated |
| [`domain-modeling`](../../ai/skills/domain-modeling/SKILL.md) | updated |
| [`grill-me`](../../ai/skills/grill-me/SKILL.md) | checked-no-change |
| [`grill-with-docs`](../../ai/skills/grill-with-docs/SKILL.md) | updated |
| [`grilling`](../../ai/skills/grilling/SKILL.md) | checked-no-change |
| [`handoff`](../../ai/skills/handoff/SKILL.md) | checked-no-change |
| [`implement`](../../ai/skills/implement/SKILL.md) | updated |
| [`improve-codebase-architecture`](../../ai/skills/improve-codebase-architecture/SKILL.md) | updated |
| [`prototype`](../../ai/skills/prototype/SKILL.md) | updated |
| [`research`](../../ai/skills/research/SKILL.md) | updated |
| [`resolving-merge-conflicts`](../../ai/skills/resolving-merge-conflicts/SKILL.md) | updated |
| [`wayfinder`](../../ai/skills/wayfinder/SKILL.md) | updated |
| [`writing-great-skills`](../../ai/skills/writing-great-skills/SKILL.md) | updated |

## Corrections retained in scope

- Recovery/auth/infra runbooks now separate evidence from causality, exact-target authorization from diagnostic access, and structural checks from completeness. SQLite/WAL preservation and loss accounting, credential/DNS scope, controller/finalizer ownership, cookie/token boundaries and bounded failure handling remain task-specific.
- CTK guidance follows the current contract/ledger, development versus production target/delivered-state distinctions, pinned PostgreSQL rollback behavior, isolated adapter tests, queue-specific concurrency and serial money paths. Reset/reseed remains separately approved disposable work or exceptional owner-routed disaster-recovery planning—not routine failed-migration recovery.
- Application/render/storage/payment guidance follows current owning source, retaining historical incidents explicitly as history. Audiospace Preview remains production-bound; Stripe enum/provider and webhook authority distinctions are version-qualified. No provider operation was used to test the prose.
- Curated review covers staged, unstaged and relevant untracked inputs; merge-conflict handling protects unrelated staging and permits authorized abort; prototypes require whole-path development isolation. Host invocation metadata is qualified, native Pi delegation is not replaced with agent CLIs, and existing canonical glossary conventions take precedence over local `CONTEXT.md` defaults without migration/rename.

## Independent review and validation

Seven disjoint native Pi implementation lanes were followed by four fresh read-only native reviewers and bounded retained follow-ups. Review caught five retained defects: CTK preview/RPC acceptance, historical renderer applicability, a nonexistent error helper, infrastructure teardown ordering and Nx candidate selection. Native workers corrected these across 13 already-in-scope bodies; CTK and infrastructure acceptance follow-ups closed the findings and their complete-original comparison holds.

One read-only reviewer reached its 30-minute deadline: the initial review workflow was not a clean four-success run. Its partial report was retained, and one native continuation completed the 58 missing original comparisons. No alternate agent CLI was used. Requested-but-truncated reads were not counted until recovered through EOF. Across all four review scopes, all **233 current variant bodies** were read, and all **210 nonduplicate changed source/support originals** were compared with the corrections. The 40 changed mirror copies are covered by exact source equality rather than counted as additional independent source reviews. All material findings and stated body-preservation holds are closed; targeted supporting-source and runtime limits remain.

The parent independently ran **10 inspected static/hermetic suites**, all passing. These cover complete path/claim dispositions, all 340 original/pass-start hashes, 233 identities/descriptions, support links/fences, all 82 mirror equalities, unchanged vendor bytes, and **65 recorded owning-source hashes**. Fixtures exercise bounded exact-GET absence/retry/error/timeout outcomes, fail-closed teardown ordering, installed-Nx 23.1.2 selection with synthetic Git output and inherited `NX_HEAD`, seven detached shell receipts across 21 fake reset/seed cases, and corrected CTK text/source contracts. No fixture called an actual cluster, database or provider.

| Claim/variant application disposition | Count |
| --- | ---: |
| Qualified | 288 |
| Corrected | 106 |
| Already correct | 83 |
| Unresolved | 11 |
| Vendor-owned | 4 |

These checks are bounded evidence, not a behavioral evaluation. No real Nx graph/task, GL render, browser/payment workflow or production recovery was exercised. Full repository builds and the full pre-commit/Markdownlint toolchain were not run; this pass changes no Nix/application code, no active local hooks were present, and installing a missing runner was outside scope.

## Explicitly deferred or unverified

- **Eight vendor-owned variants:** Orca orchestration, Rex, the Codex terminal-browser variant, Pi Ponytail audit/debt/help/review, and Context7. Installed-version-specific wording/contract limitations are recorded; package/app-owned bodies were not overwritten or silently upgraded.
- **Four loose Claude Ponytail variants:** debt, gain, help and review match marketplace-derived copies, but adoption as editable user overrides is unproven. Known old exclusions/cost/syntax/diagnostic/validation defects remain disclosed, not called fixed. Existing newer Pi-package fixes do not authorize replacing these copies.
- **Eleven unresolved claim/variant applications:** six concern those ownership-blocked copies; four concern unproved historical Kyverno/Tailscale/ARC causal chains; one concerns unavailable PostHog metric emission/query definitions. Updated owned prose now states the required evidence instead of asserting the unresolved conclusion. Four further applications are explicitly vendor-owned.
- The Otto owning checkout was unavailable. Three updated Otto bodies retain explicitly historical project knowledge and require current source/CLI/gate verification; they are not asserted to describe a verified current implementation.
- Exact deployed identities, permissions, bucket controls, firmware, historical incident causes and provider/session/environment behavior were not proven. Security/dependency/channel upgrades remain separate work. In particular, the reviewed Kyverno security update was not installed.
- Owning-source follow-ups were not silently treated as skill fixes: the infrastructure deletion-confirmation workflow, misleading policy comments, CTK renderer/test-tier qualification, and Audiospace deployment-context/release-enforcement limits remain with their application/infra owners. All 26 deferred records and their exact evidence are retained privately.
- One learned body first observed outside the frozen inventory was left untouched and is not part of the 233-variant claim. No claim is made about skills installed or learned after the audit snapshot.

## Preservation and machine-local evidence

Original/pass-start bodies, final hashes, original-to-final private diffs, all 233 entry dispositions, all 492 claim/variant dispositions, draft reviews, source evidence, native implementation/review receipts and validation results are retained in the private local bundle recorded by the acceptance manifest. This bundle—not Git—is the detailed machine-local rollback/coverage record.

Private bundle: `~/.local/state/dev-config/skill-updates/20261029T061105Z-f042c0b3/`. The directory is owner-only and stored artifacts are private. A Git checkout alone neither installs the learned corrections nor updates existing mirrors.

Skipped: operational recipes, production probes, database/provider/authentication/payment actions, firmware tests, package installation/update and Home Manager activation. Static checks and fake-command fixtures do not establish runtime outcomes.
