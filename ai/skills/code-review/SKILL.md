---
name: code-review
description: Review the changes since a fixed point (commit, branch, tag, or merge-base) along two axes — Standards (does the code follow this repo's documented coding standards?) and Spec (does the code match what the originating issue/PRD asked for?). Reports both axes side by side, using authorized host-native parallel subagents when available. Use when the user wants to review a branch, a PR, work-in-progress changes, or asks to "review since X".
---

Two-axis review against a fixed point, covering either committed branch changes or the requested work-in-progress scope:

- **Standards** — does the code conform to this repo's documented coding standards?
- **Spec** — does the code faithfully implement the originating issue / PRD / spec?

When delegation is authorized, both axes run as **parallel read-only subagents** with separate contexts, then this skill aggregates their findings. On Pi, use native Pi subagents and the installed `pi-subagents` contract; on Claude Code, use its `Agent` tool. Do not substitute OMP, Orca, another agent CLI, or a different model if the requested native runner is unavailable: report the limitation. If delegation is not authorized, review the two axes directly and label the lack of independent contexts.

Use the project's documented issue tracker. If it is unclear, ask the user before fetching issues.

## Process

### 1. Pin the fixed point and review scope

Resolve the user's commit, branch or tag to a commit (`git rev-parse --verify '<fixed-point>^{commit}'`) and record its SHA, the current `HEAD` SHA, and the comparison base. Ask for the fixed point if absent; `/implement` may explicitly pass `HEAD` for its uncommitted work. Preserve the user's requested semantics: three-dot uses `git merge-base <fixed-point> HEAD`; a comparison to an exact commit uses that commit itself. Do not silently substitute one for the other.

Choose and state the mode before gathering input:

- **Committed branch/PR**: `git diff <base> HEAD` and `git log <base>..HEAD --oneline`. This mode excludes dirty work; say so, even if the checkout is dirty.
- **Work in progress / pre-commit**: include the committed delta above when relevant, **plus** `git diff --cached` (index versus HEAD), `git diff` (unstaged versus index), and relevant untracked files enumerated with `git ls-files --others --exclude-standard`. Read the in-scope untracked files in full; ordinary diffs do not include them. Use `git diff <base>` to inspect the combined tracked final state as well. Inspect both staged and working-tree versions when they differ; a later unstaged reversal must not hide code still staged for commit.

Record `git status --short`, distinguish task-owned files from unrelated pre-existing work, and pass the same file inventory and captured diff/content to both reviewers. Include new task support/tests even if still untracked; do not ingest unrelated secrets, ignored data, or another owner's files merely to broaden coverage. Report exclusions explicitly. Do not stage, stash, reset or clean anything to obtain a diff.

Validate the ref and the **whole selected input**, not only the committed diff. A dirty-only or untracked-only implementation is not empty. If all selected inputs are empty, report no changes. If files change while collecting/reviewing, recapture the affected input and re-review it before claiming coverage.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. Issue references in the commit messages (`#123`, `Closes #45`, GitLab `!67`, etc.) — fetch via the project's issue tracker workflow (`docs/agents/issue-tracker.md` if present).
2. A path the user passed as an argument.
3. A PRD/spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name or feature.
4. If nothing is found, ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. Identify the standards sources

Anything in the repo that documents how code should be written, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md`.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below — a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation — and, like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Spawn both sub-agents in parallel

Use two native Pi read-only review runs on Pi, or two `general-purpose` `Agent` calls on Claude Code, subject to the authorization and availability rules above. Give each reviewer the captured input rather than assuming a child checkout includes uncommitted or untracked work. Wait for completed reports; a launch receipt is not a review.

**Standards sub-agent prompt** — include:

- The pinned base/HEAD, review mode, captured committed/staged/unstaged diffs, relevant untracked contents, file inventory, exclusions, and commit list.
- The list of standards-source files you found in step 3, **plus the smell baseline from step 3** pasted in full — the sub-agent has no other access to it.
- The brief: "Report — per file/hunk where relevant — (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls — documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** — include:

- The same pinned review input and inventory supplied to the Standards reviewer.
- The path or fetched contents of the spec.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings — the two axes are deliberately separate (see _Why two axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes — that's the reranking the separation exists to prevent.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
