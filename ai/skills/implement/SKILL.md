---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets. First inventory the dirty checkout and identify task-owned paths; preserve unrelated staged, unstaged and untracked work.

Use the project's documented checks and resource limits: focused typechecks and test files during implementation, then the required final suite when authorized and feasible. Report blocked or omitted checks instead of claiming they passed.

Once done, use /code-review in **work-in-progress mode**, passing the agreed comparison base (or explicitly `HEAD` for an uncommitted-only task), the spec and the task-owned paths. The review must include staged, unstaged and relevant untracked implementation/tests/support files, not just commits. Follow the host's invocation and native-delegation policy; if independent review is unavailable, report that limit. Fix accepted findings and recheck the changed scope.

Commit to the current branch only when the user/project authorizes it. Stage only reviewed task-owned paths/hunks, inspect the staged diff, and leave unrelated work untouched. Never commit merely because a review launch returned a receipt.
