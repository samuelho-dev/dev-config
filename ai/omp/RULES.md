# Shared workspace lifecycle

These always-apply instructions govern OMP agents using this user's default
profile, across projects. They are guidance for agents, not automatic cleanup,
an ownership registry, or native jj access control. Follow each project's VCS
policy.

- In a jj-managed repository, author with jj. Use Git and the forge as a
  read-only boundary unless explicitly authorized to publish; never silently
  fall back to Git authoring or convert a repository.
- Before allocating a workspace, record the task/run, workspace path, owner,
  and owned change using existing durable task/session records. If that cannot
  be recorded, do not allocate silently; ask for a safe ownership path.
- Reuse an appropriate owned workspace when safe; do not allocate one for every
  microchange. One writer per workspace includes subprocesses; independent
  agents write in separate workspaces.
- Before rewriting a change graph or taking snapshots, account for active
  dependent workspaces and tracked bookmarks. Coordinate with their owners
  rather than invalidating their work.
- Verify the exact intended commit and tree before publishing or claiming
  delivery; a passing task or closed session is not a release.
- Distinguish task completion, release, retention, and workspace removal.
  Record an intentional retention decision explicitly; do not infer release
  or deletion from a finished task.
- Keep failed workspaces visible as cleanup-pending or quarantined in existing
  task/session records, with an owner and reason. Do not silently discard them.
- On startup or restart, reconcile known durable task/ownership records with
  actual workspaces and running processes before reuse or removal. A dead PID
  alone, lease expiry, or workspace age never authorizes deletion.
- Remove only released, harness-owned workspaces after stopping every writer
  and preserving tracked changes and relevant ignored/untracked files. With jj,
  `jj workspace forget` leaves files behind, while removal can delete ignored
  files; inspect and preserve them first.
- Closing a Rex tab is not workspace cleanup. Preserve unowned, manual, and
  human workspaces; ask the owner or explicitly adopt one before any removal.
