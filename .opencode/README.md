# OpenCode Migration - Setup Guide

## Overview

This project has been migrated from Claude to OpenCode with a portable configuration system. The setup includes specialized agents, custom commands, and development environment integration.

## Quick Start

### 1. Environment Setup

Copy the environment template and configure your API keys:

```bash
cp .env.example .env
# Edit .env with your actual API keys
```

Required environment variables:
```bash
OPENCODE_MODEL=anthropic/claude-sonnet-4-20250514
OPENCODE_SMALL_MODEL=anthropic/claude-haiku-4-20250514
ANTHROPIC_API_KEY=your_anthropic_api_key_here
OPENAI_API_KEY=your_openai_api_key_here
```

### 2. Start OpenCode

```bash
# Navigate to project directory
cd /path/to/dev-config

# Start OpenCode (automatically detects .opencode/ config)
opencode
```

### 3. Verify Configuration

Run these commands to verify everything is working:

```bash
# Test Nix configuration
/nix-check

# Test Biome formatting
/biome-check

# Test all commands
/test-all
```

## Configuration Structure

### Portable Configuration (.opencode/)

```
.opencode/
├── opencode.json              # Main configuration (portable)
├── agent/                     # Specialized agents
│   ├── nix-architect.md
│   ├── typescript-pro.md
│   ├── devops-engineer.md
│   ├── code-reviewer.md
│   ├── python-backend-architect.md
│   ├── neovim-expert.md
│   ├── security-auditor.md
│   ├── nx-monorepo-architect.md
│   └── effect-architecture-specialist.md
├── command/                   # Custom commands
├── tool/                      # Custom tools
│   └── nix-validator.ts
└── prompts/                   # Agent prompt files
    ├── nix-architect.md
    ├── typescript-pro.md
    ├── devops-engineer.md
    ├── code-reviewer.md
    ├── python-backend-architect.md
    ├── neovim-expert.md
    ├── security-auditor.md
    ├── nx-monorepo-architect.md
    └── effect-architecture-specialist.md
```

### Key Features

- **Portable**: All configurations use relative paths and environment variables
- **No Hardcoded Paths**: Works across different development environments
- **Environment Variables**: Sensitive data (API keys) stored in `.env`
- **Cross-Platform**: Compatible with macOS, Linux, and Windows

## Available Agents

### Primary Agents (Tab to switch)
- **`build`**: Full development access with all tools enabled
- **`plan`**: Read-only analysis and planning (file edits: ask, bash: ask)

### Specialized Agents (@mention to invoke)
- **`@nix-architect`**: Nix configuration and Home Manager modules
- **`@typescript-pro`**: TypeScript with strict typing and Effect-TS patterns
- **`@devops-engineer`**: Infrastructure, containers, and deployment automation
- **`@code-reviewer`**: Code quality, security, and maintainability reviews
- **`@python-backend-architect`**: Python backend services and APIs
- **`@neovim-expert`**: Neovim configuration and Lua plugin development
- **`@security-auditor`**: Security vulnerability assessment and remediation
- **`@nx-monorepo-architect`**: Nx workspace configuration and build optimization
- **`@effect-architecture-specialist`**: Effect-TS functional programming and error handling

## Slash Commands

OpenCode uses shared slash commands from the centralized `ai/` directory. Commands are:
- **Source of Truth**: `../ai/commands/` (centralized location)
- **Accessed via**: `./command/` (symlink to `../ai/commands/`)
- **Shared with**: Claude Code (via `.claude/commands/` symlink)
- **OpenCode-specific tools**: See `./tool/` directory

### Available Commands
- `/create-command` - Create new slash commands
- `/create-plugin` - Create OpenCode plugins
- `/create-tool` - Create OpenCode tools
- `/debug` - Debug issues
- `/create-documentation` - Create documentation
- `/create-execution` - Create execution plans
- `/generate-tests` - Generate test files
- `/refactor` - Refactor code
- `/refine-commands` - Refine command definitions
- `/refineagents` - Refine agent definitions
- `/security-hardening` - Security hardening analysis
- `/start-context` - Start new context
- `/update-documentation` - Update documentation
- `/validate-library` - Validate library structure
- `/validate-plan` - Validate execution plans

### Custom Commands (Development)
- **`/nix-fmt`**: Format all Nix files using `nix fmt`
- **`/nix-check`**: Validate Nix configuration syntax and build test
- **`/biome-check`**: Format and lint code with Biome
- **`/test-all`**: Run all project tests and checks
- **`/home-switch`**: Apply Home Manager configuration (with confirmation)

### Usage Examples
```bash
# Format Nix files
/nix-fmt

# Validate configuration
/nix-check

# Run full test suite
/test-all

# Apply configuration changes
/home-switch
```

## Agent Usage Patterns

### Architecture Workflow
1. **Design**: `@nix-architect help design this module`
2. **Implementation**: Switch to `build` agent and implement
3. **Review**: `@code-reviewer review the changes`
4. **Security**: `@security-auditor check for vulnerabilities`

### Development Workflow
1. **TypeScript Issues**: `@typescript-pro fix these type errors`
2. **Effect-TS Patterns**: `@effect-architecture-specialist optimize this effect`
3. **Infrastructure**: `@devops-engineer set up CI/CD for this`
4. **Nx Optimization**: `@nx-monorepo-architect optimize the build`

### Code Review Workflow
1. **Quality Check**: `@code-reviewer review this PR`
2. **Security Review**: `@security-auditor assess security`
3. **Performance**: `@devops-engineer check performance impact`

## Development Environment Integration

### Nix Integration
- Automatic Nix formatting and validation
- Home Manager module support
- Flake-based configuration management
- Security best practices (sops-nix integration)

### Biome Integration
- Strict TypeScript and JavaScript linting
- Automatic formatting on save
- 100 character line width enforcement
- Single quotes and 2-space indentation

### Editor Integration
- Neovim configuration support via `@neovim-expert`
- LSP integration for TypeScript and Nix
- Custom keybindings and workflows
- Cross-platform compatibility

## Portability Features

### Environment Variables
All sensitive configuration uses environment variables:
- API keys for LLM providers
- Model selection preferences
- Theme and UI preferences
- Custom tool configurations

### Relative Paths
All file references use relative paths:
- Agent prompts: `{file:./prompts/agent-name.md}`
- Tool commands: `./scripts/tool-script.sh`
- Configuration files: `docs/guidelines.md`
- Project files: `@src/components/Button.tsx`

### Cross-Platform Compatibility
- Shell commands work across platforms
- File separators handled automatically
- Environment detection and adaptation
- Consistent behavior across systems

## Troubleshooting

### Common Issues

**Configuration not loading**
```bash
# Check .opencode directory exists
ls -la .opencode/

# Verify environment variables
cat .env

# Test OpenCode detection
opencode --help
```

**Agents not available**
```bash
# Check agent files exist
ls -la .opencode/agent/

# Verify configuration syntax
cat .opencode/opencode.json | jq .
```

**Commands not working**
```bash
# Test command syntax
/command-name

# Check shell integration
!echo "test"
```

### Getting Help

- Use `/help` for built-in OpenCode commands
- Check `AGENTS.md` for project-specific guidelines
- Review agent documentation with `@agent-name help`
- Use `/models` to see available models

## Migration Notes

### Differences from Claude
- **Agent Invocation**: Use `@agent-name` instead of direct selection
- **Command System**: Use `/command-name` with argument support
- **Context Management**: File references with `@filename`
- **Tool Integration**: Shell commands with `!command` syntax

### Preserved Features
- All specialized agents migrated and enhanced
- Development environment integration maintained
- Security and quality standards preserved
- Portable configuration system added

### Enhanced Capabilities
- Better tool permission control
- Cross-platform compatibility
- Environment variable management
- Custom tool integration

## Team Deployment

### For Team Members

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd dev-config
   ```

2. **Setup Environment**
   ```bash
   cp .env.example .env
   # Add your API keys to .env
   ```

3. **Start OpenCode**
   ```bash
   opencode
   ```

4. **Verify Setup**
   ```bash
   /test-all
   ```

### For CI/CD Systems

Set these environment variables in your CI/CD system:
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `OPENCODE_MODEL`
- `OPENCODE_SMALL_MODEL`

The configuration will automatically work without modifications in CI/CD environments.

## Support and Feedback

For issues or feedback:
1. Check this documentation first
2. Review `AGENTS.md` for project-specific guidelines
3. Use `@code-reviewer` for code quality issues
4. Test with `/test-all` command
5. Report configuration issues if they persist

This portable OpenCode configuration provides a robust, maintainable, and cross-platform development environment that preserves all the capabilities of the original Claude setup while adding enhanced portability and team collaboration features.
