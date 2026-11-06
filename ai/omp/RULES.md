# Shared workspace lifecycle

Default-profile OMP guidance across projects, not automatic cleanup. Follow
repository VCS policy.

- In a jj-managed repository, author with jj. Use Git and the forge as a
  read-only boundary unless explicitly authorized to publish; never silently
  fall back to Git authoring or convert a repository.
- Before allocation, record task, path, owner, change and cleanup owner in existing
  records. Reuse safely; concurrent writers (including subprocesses) need separate
  workspaces. Read-only agents reuse source.
- Before rewriting a change graph or taking snapshots, account for active
  dependent workspaces and tracked bookmarks. Coordinate with their owners
  rather than invalidating their work.
- Verify the exact intended commit and tree before publishing or claiming
  delivery; a passing task or closed session is not a release.
- The allocator owns cleanup. Workers report exact commits, verification and
  required artifacts, then stop. After accepted handoff, remove released temporary
  workspaces without waiting for PR review/merge.
- At startup/restart, task completion and verified merge, reconcile records,
  jj workspaces, Git worktrees, checkout directories in known roots, processes,
  local branches/bookmarks, live remote heads and open PRs. Investigate loose
  checkouts and stale registrations.
- Before removal, stop writers, check dependencies and preserve work plus required
  ignored/untracked files. Remove only released, owned resources; verify registration
  and directory removal (`jj workspace forget` leaves files behind).
- Remote deletion requires authorization, merged/released work, preserved tips,
  no open PR/active dependency, and exact-tip guards. Protect shared/deployment refs;
  merge alone is not authorization.
- Preserve human/unowned work. Report removed/retained/blocked; leftovers need an
  owner, reason and release condition. Age, dead PIDs and closed tabs never
  authorize deletion.
