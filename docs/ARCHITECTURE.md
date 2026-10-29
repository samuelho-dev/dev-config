# Dev-Config Architecture (Portable AI & Editor Resources)

## Overview

dev-config is the single source of truth for shared developer resources (curated AI
skills, MCP configuration, editor configs, linting). Home Manager deploys tool
configuration; agent skills are installed separately. The flake's `devShellHook`
links per-project editor settings.

1. **Source** (`dev-config/`): canonical resources, Git-tracked.
2. **Global deployment**: Home Manager configures enabled MCP targets and linting.
   Agent skill installation is separate from Home Manager.
3. **Project linkage** (`project-repo/`): `lib.devShellHook` runs on `nix develop` and
   wires per-project editor config.

## Source Layout

### `ai/` — Centralized AI Resources (single source of truth)
- `skills/` — curated skills derived from `mattpocock/skills`.
  OMP autolearn skills stay machine-local in `~/.omp/agent/managed-skills`.
- `hooks/` — Biome / type-safety hooks (referenced in-repo by `.claude/settings.json`)
- `mcp/` — canonical MCP server list and cross-agent fan-out script
- `omp/` — canonical OMP plugin list and idempotent installer
- `claude/` — [native Claude CLI bootstrap](../ai/claude/README.md), only when absent

`claude-code.nix` is a minimal writable CLI bootstrap, enabled in personal/work
and DevPod profiles. It preserves existing CLIs; otherwise it runs the official
native installer for floating latest. Native installs own their launcher and
updates. It does not manage settings, OAuth, plugins, skills or proxy routing.
Home Manager no longer copies or retires agent skills or cleans up global
agents/commands. Existing installed resources are left intact; changes to
`ai/skills` require a separate installation step. MCP fan-out remains in
`mcp.nix`; profiles explicitly opt into the Claude target.

`omp.nix` and the DevPod/Orca entrypoints run `ai/omp/apply-plugins.sh`, so
workstations and container runtimes install the same plugins from
`ai/omp/plugins.txt`.

`omp` itself is not a Nix package (a read-only `/nix/store` install cannot
self-update). Everywhere — `omp.nix` on workstations, the DevPod/Orca
entrypoints in containers — it is the same prebuilt standalone binary from
`https://omp.sh/install --binary`, which self-updates via `omp update`.
It is deliberately *not* installed with `bun add -g`: that yields a shim that
runs on bun, pinning omp to whatever bun the image baked.

### `.claude/` — Project-level Claude Code config (this repo)
- `settings.json` — project hooks (reference `ai/hooks/`)
- `templates/` — CLAUDE.md / README.md templates

## Project Linkage: `devShellHook`

On `nix develop`, `lib.devShellHook` (in `flake.nix`) performs exactly:

- creates `.envrc` (`use flake`) and auto-`direnv allow`
- symlinks `.zed -> ${dev-config}/zed` (full-directory symlink; no internal relative
  paths)
- generates `biome.json` extending `~/.config/biome/biome.json` if missing

The root `CLAUDE.md` "Flake Composition & devShellHook" section documents the full
table of what gets linked/generated (`.claude/`, `.zed/`, `biome.json`)
and the symlink strategy. Treat that table as authoritative.

```
dev-config/                         [Source, Git]
   ├── ai/  (skills, hooks, MCP servers, OMP plugins)
   ├── zed/
   └── biome/

      │ Home Manager switch (MCP, Biome and OMP modules)
      ▼

~/.config/biome/  ← linting config
~/.omp/plugins  ← ai/omp/plugins.txt

      │ nix develop  →  lib.devShellHook
      ▼

my-project/                          [Project Link]
   ├── .zed     -> ${dev-config}/zed   (full-dir symlink)
   └── biome.json                       (generated; extends ~/.config/biome/)
```

## Maintenance

**Update MCP resources:** edit `ai/mcp/`, then run
`home-manager switch --flake .` in this repo. Skill source changes under
`ai/skills/` are not installed by that command.

**Update global OMP plugins:** edit `ai/omp/plugins.txt`, then run
`home-manager switch --flake .`; DevPod/Orca images consume the same list on boot.

**Re-initialize a project's editor config:**
```bash
cd project-directory
rm -f .zed biome.json   # remove stale links/generated config
nix develop             # devShellHook recreates them
```

**Set up a new project:**
```nix
# In the consumer flake.nix devShell:
inputs.dev-config.url = "github:samuelho-dev/dev-config";
# ...
shellHook = ''
  ${dev-config.lib.devShellHook}
'';
```

See the root `CLAUDE.md` "Flake Composition & devShellHook" section for the full
composition pattern and the `inputs ? dev-config` standalone/composed mechanism.
