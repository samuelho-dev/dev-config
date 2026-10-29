---
name: resolving-merge-conflicts
description: "Use when you need to resolve an in-progress git merge/rebase conflict."
---

1. **Confirm scope and authority.** Inspect status, history and the in-progress operation: merge or rebase, branches/commits, and unresolved paths. Record pre-existing staged, unstaged and untracked work separately from operation-owned changes. Do not start a new merge/rebase or switch branches. Confirm the intended result and whether the user authorizes editing, staging and completion; a diagnosis-only request stops at advice.

2. **Find the primary sources** for each conflict. Understand deeply why each change was made, and what the original intent was. Read the commit messages, check the PRs, check original issues/tickets.

3. **Resolve each hunk.** Preserve both intents where possible. Where incompatible, use the approved goal; if that does not settle the choice, stop and ask rather than invent behaviour or discard work. Git supports `merge --abort` and `rebase --abort`, but do not abort automatically: explain the consequences and obtain explicit authorization, especially when pre-existing dirty work may not be recoverable. Likewise, `rebase --skip` drops a commit and needs a separate decision. Do not use reset/restore/stash as an implicit recovery shortcut.

4. Discover the project's **automated checks** and resource policy, then run the authorized focused checks — typically typecheck, tests and format. Inspect for unresolved markers and unintended semantic changes. Fix operation-caused failures within scope; report unrelated failures and blocked checks.

5. **Finish only within the granted authority.** Stage only the resolved operation-owned files/hunks (for example `git add -- <resolved-path>`), never blanket `git add .` or `git add -A`. Inspect the staged result against the recorded starting index; pre-existing staged work is not automatically part of this operation. If unrelated staged hunks cannot be separated safely, stop for the owner rather than unstaging them. Verify no unmerged entries remain. For a merge, commit the reviewed merge result only if authorized; for a rebase, use `git rebase --continue` and repeat the source/resolve/check cycle at each stop. If completion or history rewriting is not authorized, leave the operation in place and report exactly what is resolved, staged and still pending. No push or force-push is implied.
