# Changelog

## Unreleased — Rex homelab access

- Added Supabase CLI and PostgreSQL client to the shared Darwin/Linux toolchain.
- Registered Sentry and PostHog MCP with dedicated credential resolution and full approved tools mode; missing credentials now omit managed authenticated servers, including stale entries. Pinned community Vercel MCP starts from a neutral working directory; Effect MCP is fixed to verified `0.1.16` and initial pi-ponytail installs to `0.1.2`.
- Added an isolated Argo core selector, an authenticated identity/denial check, and a shared standalone OMP binary installer for Home Manager and Rex.
- Source Mac tailnet Argo core helper smoke returned 64 applications, all Synced. Shared cloud dependency evaluation included `supabase-cli` and `postgresql` for aarch64-darwin and x86_64-linux (no package builds). The unmodified HTTP MCP smoke passed Sentry `find_projects` (`api`), PostHog `project-get` (`112088`), and invalid-token denial checks using approved existing Orca development credentials only in memory. Initial renderer regression passed before subsequent credential-safety changes; rerun is pending. Live Rex authorization and valid Supabase PAT enrollment remain unverified; no Rex deployment/access claim is made.
