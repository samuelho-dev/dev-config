# Changelog

## Unreleased — Rex homelab access

- Added Supabase CLI and PostgreSQL client to the shared Darwin/Linux toolchain.
- Registered Sentry and PostHog MCP with dedicated credential resolution and full approved tools mode; missing credentials now omit managed authenticated servers, including stale entries. Pinned community Vercel MCP starts from a neutral working directory.
- Added an isolated Argo core selector, an authenticated identity/denial check, and a shared standalone OMP binary installer for Home Manager and Rex.
- Renderer auth/retained-local-config regression check passed in the source worktree. Live Rex authorization, provider project reads, Supabase PAT enrollment, Argo core transport, and cross-platform package evaluation are separate pending smokes; no live access claim is made here.
