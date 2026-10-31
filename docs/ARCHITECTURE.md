# Dev-Config Architecture (Portable AI & Editor Resources)

## Overview

dev-config owns shared developer resources: curated AI skills, MCP configuration,
editor configs and linting. Home Manager selects enabled native tools, provisions
system packages and configures MCP targets; `ai/bootstrap.sh` installs missing
writable native CLIs in `~/.local`, and `ai/sync-skills.sh` adds curated skills
without owning whole user skill directories. The flake's `devShellHook` links
per-project editor settings.

1. **Source** (`dev-config/`): canonical resources, Git-tracked.
2. **Global deployment**: Home Manager provisions packages and selects native CLI
   and MCP targets; native CLIs are not compiled into Nix packages.
3. **Project linkage** (`project-repo/`): `lib.devShellHook` runs on `nix develop`
   and wires per-project editor config.

## Source Layout

### `ai/` — Centralized AI Resources (single source of truth)
- `skills/` — curated skills derived from `mattpocock/skills`.
  OMP autolearn skills stay machine-local in `~/.omp/agent/managed-skills`.
- `hooks/` — Biome / type-safety hooks (referenced in-repo by `.claude/settings.json`)
- `mcp/` — canonical MCP server list and profile-based Claude/OMP/Codex fan-out
- `omp/`, `pi/`, `claude/` — native bootstrap helpers and plugin sources
- `omp/RULES.md` — shared instructions linked by the enabled OMP Home Manager
  module into the default user profile (`~/.omp/agent/RULES.md`); alternate
  profile directories opt in separately
- `bootstrap.sh` — single owner for native `install|update|check` across OMP,
  Pi, Claude, OpenCode, Codex and Vercel
- `sync-skills.sh` — curated skill link reconciliation

With `dev-config.enable`, `native-tools.nix` writes the selected tools to
`~/.config/dev-config/native-tools` and invokes `ai/bootstrap.sh install` after
package installation; startup never upgrades an already working CLI. Explicit
`bash ai/bootstrap.sh update` upgrades selected tools, and `check` verifies
executables, not auth. The standalone OMP binary must be writable in
`~/.local/bin` (not a Bun shim). The official Claude installer and native npm
packages likewise remain writable in `~/.local`; Nix owns neither their binaries
nor their native settings/OAuth. This works with stock macOS Bash.

Skill reconciliation fills missing links inside each existing physical user
directory and leaves existing directories, edited skills and unmanaged symlinks
alone. It advances a tracked link only if it still points to its recorded
previous target; it never replaces a whole skills directory. OMP and Pi plugin
sources are separate from CLI binary versions: update plugin sources deliberately
and apply them explicitly; do not expect activation or shell startup to upgrade
existing plugins. MCP uses explicit `op` or `env` credential selection and
profile-enabled Claude/OMP/Codex targets; it preserves working config if a
required credential or launcher is unavailable.

The shared Nix core package set provisions `jj` alongside Git (currently
`0.42.0` from the pinned nixpkgs); it neither converts repositories nor
changes signing or authoring configuration. OMP's user-profile rules guide
workspace ownership and retention using existing task/session records. This
source link applies only when OMP is enabled; it does not install a janitor,
enforce agent ACLs, or alter other runtimes. Agents must reconcile ownership,
writers, and files before any explicitly authorized release/removal.

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
   ├── ai/  (native bootstrap, skills, hooks, MCP servers, plugin sources)
   ├── zed/
   └── biome/

      │ Home Manager switch (packages, selected native install, MCP, Biome)
      ▼

~/.config/biome/                   ← linting config
~/.config/dev-config/native-tools ← enabled native CLI manifest
~/.local/bin/                     ← writable native CLI launchers
~/.agents/skills/ etc.            ← individual curated links, user entries intact

      │ nix develop → lib.devShellHook
      ▼

my-project/                       [Project Link]
   ├── .zed     -> ${dev-config}/zed
   └── biome.json                 (extends ~/.config/biome/)
```

## Maintenance

**Update native CLIs:** `bash ai/bootstrap.sh update` uses the enabled
manifest (or pass explicit names). Run `bash ai/bootstrap.sh check` to verify
availability; authenticate each service separately. Updating `flake.lock`
updates locked Nix source revisions, not native CLIs; updating a plugin source
is a separate explicit action. MCP stdio launchers are not Nix-version-pinned.

**Update MCP resources:** edit `ai/mcp/`, then apply Home Manager for the
selected profile. Required auth/launcher failures preserve working config.
Skill changes under `ai/skills/` are linked by `ai/sync-skills.sh`, which
does not overwrite physical user skills or unmanaged links.

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
