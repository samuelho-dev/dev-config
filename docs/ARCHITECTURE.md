# Dev-Config Architecture (Portable AI Resources)

## Overview
The dev-config architecture uses a three-tier system to manage AI resources (commands, agents, templates) across multiple projects:

1. **Source Tier (`dev-config/ai/`)**: The source of truth for all shared AI resources, managed by Git in the `dev-config` repository.
2. **Global Deployment Tier (`~/.config/`)**: Shared resources are deployed to your home directory via Home Manager. This makes the resources portable and accessible to any project on the machine.
   - `~/.config/claude-code/`: Managed by `claude-code.nix`
   - `~/.config/opencode/`: Managed by `opencode.nix`
3. **Project Linkage Tier (`project-repo/`)**: Individual projects link to dev-config via `lib.devShellHook` (automatic on `nix develop`).
   - `.claude/ -> dev-config/.claude/`
   - `.opencode/ -> dev-config/.opencode/`
   - `.zed/ -> dev-config/zed/`
   - `.grit/ -> dev-config/grit/`

## Directory Structure (Source)

### `ai/` - Centralized AI Resources (Single Source of Truth)
- **commands/**: Slash commands (shared by all AI tools)
- **agents/**: AI agents (shared by all AI tools)
- **tools/**: Shared utilities
- **Purpose**: Single source of truth for all AI-related resources, managed by Git.

### `.claude/` - Claude Code Templates & Settings
- **settings-base.json**: Base Claude Code settings (deployed to `~/.config/claude-code/`)
- **templates/**: Claude Code templates (deployed to `~/.config/claude-code/`)

### `.opencode/` - OpenCode Specific Assets
- **plugin/**: TypeScript plugins (guardrails, validation)
- **tool/**: OpenCode-specific tools (gritql, mlg)
- **lib/**: Shared TypeScript schemas
- **test/**: Tests for plugins and tools

## Architecture Principles

### 1. Centralized Source, Global Deployment
All shared AI resources (commands, agents) are stored in the `ai/` directory and deployed globally via Home Manager to `~/.config/`.

### 2. Project-Level Portability
Individual projects use `lib.devShellHook` in their flake.nix to automatically create symlinks on `nix develop`. This ensures that the AI resources are available anywhere without duplicating files.

### 3. Tool-Specific Extensions
Each tool maintains its own specific configuration while sharing the core resources:
- Claude Code: `settings.json`, `templates/`
- OpenCode: TypeScript plugins, custom tools, Effect-TS schemas

### 4. Deployment Flow
```
dev-config/ai/              [Source]
   ├── commands/
   ├── agents/
   └── tools/

      │ (Home Manager switch)
      ▼

~/.config/claude-code/       [Global Deployment]
   ├── commands/             (source: dev-config/ai/commands)
   ├── agents/               (source: dev-config/ai/agents)
   └── templates/

      │ (nix develop with lib.devShellHook)
      ▼

my-project/                   [Project Link]
   ├── .claude/ -> dev-config/.claude/
   ├── .opencode/ -> dev-config/.opencode/
   ├── .zed/ -> dev-config/zed/
   └── .grit/ -> dev-config/grit/
```

## How It Works

### Claude Code
1. `claude-code.nix` (Home Manager) deploys shared resources from `ai/` to `~/.config/claude-code/`.
2. `lib.devShellHook` (in project flake.nix) links `.claude/` to dev-config on `nix develop`.

### OpenCode
1. `opencode.nix` (Home Manager) deploys shared commands and local assets to `~/.config/opencode/`.
2. `lib.devShellHook` links `.opencode/` to dev-config on `nix develop`.

## Benefits
1. ✅ **Portability**: AI resources follow the developer across any project on the machine.
2. ✅ **Single Maintenance**: Update `ai/` resources in one place.
3. ✅ **No Duplication**: Files are linked, not copied.
4. ✅ **Consistency**: Every project has the same toolset.
5. ✅ **Clean Repositories**: Project-level `.gitignore` handles the symlinks.

## Maintenance

### Updating Resources
1. Edit files in `dev-config/ai/`.
2. Run `home-manager switch --flake .` in the `dev-config` repository.

### Re-initializing a Project
If symlinks are broken or you want to refresh configuration:
```bash
cd project-directory
rm -rf .claude .opencode .zed .grit  # Remove broken symlinks
nix develop  # Re-creates symlinks via lib.devShellHook
```

### Setting Up a New Project
```bash
# Option 1: Initialize from template
nix flake init -t github:samuelho-dev/dev-config
nix develop

# Option 2: Add to existing flake.nix
inputs.dev-config.url = "github:samuelho-dev/dev-config";
# In devShell:
shellHook = dev-config.lib.devShellHook;
```
