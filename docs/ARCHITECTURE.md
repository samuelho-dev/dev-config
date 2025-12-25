# Dev-Config Architecture

## Directory Structure

### `ai/` - Centralized AI Resources (Single Source of Truth)
- **commands/**: Slash commands (shared by all AI tools)
- **agents/**: AI agents (shared by all AI tools)
- **tools/**: Custom tools and utilities
- **Purpose**: Single source of truth for all AI-related resources

### `.claude/` - Claude Code Configuration
- **commands/**: Symlink to `../ai/commands/`
- **agents/**: Symlink to `../ai/agents/`
- **settings.json**: Claude Code specific settings
- **settings.local.json**: Local overrides (not committed)
- **templates/**: Claude Code templates

### `.opencode/` - OpenCode Configuration
- **command/**: Symlink to `../ai/commands/`
- **opencode.json**: OpenCode configuration
- **plugin/**: TypeScript plugins (guardrails, validation)
- **tool/**: OpenCode-specific tools (gritql, mlg)
- **lib/**: Shared TypeScript schemas
- **test/**: Tests for plugins and tools

## Architecture Principles

### 1. Single Source of Truth
All shared AI resources (commands, agents) are stored in the `ai/` directory. Tool-specific directories (`.claude/`, `.opencode/`) symlink to these resources.

### 2. Tool-Specific Extensions
Each AI tool can have its own specific configuration and extensions:
- Claude Code: `settings.json`, `settings.local.json`
- OpenCode: TypeScript plugins, custom tools, Effect-TS schemas

### 3. No Duplication
Commands and agents are defined once in `ai/` and accessed via symlinks. This ensures:
- Single point of maintenance
- Consistency across tools
- No version drift

### 4. Clear Separation
```
ai/                          ← Shared resources
├── commands/                ← Slash commands (all tools)
├── agents/                  ← AI agents (all tools)
└── tools/                   ← Shared utilities

.claude/                     ← Claude Code specific
├── commands -> ../ai/commands/
├── agents -> ../ai/agents/
└── settings.json

.opencode/                   ← OpenCode specific
├── command -> ../ai/commands/
├── plugin/                  ← TypeScript plugins
└── tool/                    ← OpenCode tools
```

## How It Works

### Claude Code
1. Reads commands from `.claude/commands/` (symlink to `ai/commands/`)
2. Reads agents from `.claude/agents/` (symlink to `ai/agents/`)
3. Ignores `.opencode/` directory via `permissions.deny`
4. Uses `settings.json` for configuration

### OpenCode
1. Reads commands from `.opencode/command/` (symlink to `ai/commands/`)
2. Uses `opencode.json` for OpenCode-specific configuration
3. Has additional tools in `.opencode/tool/`
4. Has TypeScript plugins in `.opencode/plugin/`

### Adding New Commands
```bash
# Add command to centralized location
echo "Your command prompt" > ai/commands/my-command.md

# Automatically available in both tools via symlinks
# Claude Code: /my-command
# OpenCode: /my-command
```

### Adding New Agents
```bash
# Add agent to centralized location
cp agent-template.md ai/agents/my-agent.md

# Automatically available in both tools via symlinks
# Claude Code: @my-agent
# OpenCode: @my-agent
```

## Configuration Details

### Claude Code Settings (`.claude/settings.json`)

```json
{
  "hooks": {
    "enabled": true
  },
  "permissions": {
    "deny": [
      "Read(./.opencode/**)"
    ]
  }
}
```

**Purpose**: Prevents Claude Code from reading OpenCode-specific files while still allowing access to shared `ai/` resources via symlinks.

### OpenCode Configuration (`.opencode/opencode.json`)

OpenCode has its own configuration file that includes:
- Custom tools (@gritql, @mlg)
- TypeScript plugins for guardrails
- Effect-TS integration
- Multi-agent system configuration
- Test configurations

## Benefits

1. ✅ **No Duplication**: Commands and agents defined once in `ai/`
2. ✅ **No Conflicts**: Claude Code ignores `.opencode/` directory
3. ✅ **Clear Separation**: Shared vs tool-specific is obvious
4. ✅ **Easy Maintenance**: Update in one place, available everywhere
5. ✅ **Tool-Specific Extensions**: Each tool can have unique features
6. ✅ **Backward Compatible**: Existing commands continue to work
7. ✅ **Scalable**: Easy to add new AI tools in the future

## Adding New AI Tools

To add a new AI tool to this architecture:

1. Create tool-specific directory (e.g., `.newtool/`)
2. Create symlink to shared resources:
   ```bash
   ln -s ../ai/commands .newtool/commands
   ln -s ../ai/agents .newtool/agents
   ```
3. Add tool-specific configuration files
4. Update Claude Code's `permissions.deny` if needed

## Future Enhancements

1. **Command Registry**: Central registry with metadata
2. **Agent Marketplace**: Share agents between projects
3. **Tool Plugins**: Package tools as npm modules
4. **Unified Testing**: Test commands work across all tools
5. **Version Management**: Track command/agent versions
