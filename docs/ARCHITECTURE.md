# Dev-Config Architecture (Portable AI & Editor Resources)

## Overview

dev-config is the single source of truth for shared developer resources (Claude Code
commands/agents, editor configs, linting). Resources flow from this repo to your
machine via Home Manager, and into individual projects via the flake's `devShellHook`.

1. **Source** (`dev-config/`): canonical resources, Git-tracked.
2. **Global deployment** (`~/.claude/`, `~/.config/biome/`): Home Manager copies AI
   configs and linting config to the home directory so every tool/project finds them
   automatically.
3. **Project linkage** (`project-repo/`): `lib.devShellHook` runs on `nix develop` and
   wires per-project editor config.

## Source Layout

### `ai/` — Centralized AI Resources (single source of truth)
- `commands/` — slash commands
- `agents/` — agent definitions
- `hooks/`, `skills/`, `tools/` — supporting resources

`claude-code.nix` (Home Manager) copies `ai/agents` and `ai/commands` to
`~/.claude/{agents,commands}` (via `cp -Lr`). AI configs are **global** — no
project-level sync of commands/agents is needed.

### `.claude/` — Project-level Claude Code config (this repo)
- `settings.json` — project hooks (reference `ai/hooks/`)
- `templates/` — CLAUDE.md / README.md templates
- `tools -> ../ai/tools` — symlink

## Project Linkage: `devShellHook`

On `nix develop`, `lib.devShellHook` (in `flake.nix`) performs exactly:

- creates `.envrc` (`use flake`) and auto-`direnv allow`
- symlinks `.zed -> ${dev-config}/zed` (full-directory symlink; no internal relative
  paths)
- generates `biome.json` extending `~/.config/biome/biome.json` if missing

The root `CLAUDE.md` "Flake Composition & devShellHook" section documents the full
table of what gets linked/generated (`.claude/`, `.factory/`, `.zed/`, `biome.json`)
and the symlink strategy. Treat that table as authoritative.

```
dev-config/                         [Source, Git]
   ├── ai/  (commands, agents, hooks, skills, tools)
   ├── zed/
   └── biome/

      │ Home Manager switch (claude-code.nix, biome module)
      ▼

~/.claude/        ← cp -Lr ai/agents, ai/commands     [Global, per-machine]
~/.config/biome/  ← linting config

      │ nix develop  →  lib.devShellHook
      ▼

my-project/                          [Project Link]
   ├── .zed     -> ${dev-config}/zed   (full-dir symlink)
   └── biome.json                       (generated; extends ~/.config/biome/)
```

## Maintenance

**Update AI resources:** edit files in `dev-config/ai/`, then
`home-manager switch --flake .` in this repo.

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
