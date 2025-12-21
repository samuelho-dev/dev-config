# oh-my-opencode: Multi-Agent AI Orchestration

## Overview

**oh-my-opencode** is an OpenCode plugin that transforms your AI coding workflow into a collaborative multi-agent system. Instead of a single AI assistant, you now have a team of specialized agents working together, each optimized for specific tasks.

**Version**: 2.4.0
**Configuration**: Fully managed via Nix (`modules/home-manager/programs/opencode.nix`)
**Status**: Enabled by default in `home.nix`

## Architecture

### Agent Ecosystem

oh-my-opencode provides 7 specialized AI agents, each powered by frontier models selected for optimal performance and cost:

| Agent | Model | Purpose | Temperature | Cost |
|-------|-------|---------|-------------|------|
| **Sisyphus** | Claude Opus 4.5 (Max 20) | Main orchestrator with extended thinking (32k budget) | 0.7 | High |
| **oracle** | Claude Opus 4.5 (OpenRouter) | Architecture design & debugging specialist | 0.3 | High |
| **librarian** | Claude Sonnet 4.5 (Max 20) | Codebase analysis & documentation research | 0.5 | Medium |
| **explore** | Grok 3 (OpenRouter) | Fast file traversal & pattern matching | 0.2 | Free |
| **frontend-ui-ux-engineer** | Gemini 3 Pro High (OpenRouter) | UI/UX design & frontend development | 0.8 | Low |
| **document-writer** | Gemini 3 Flash (OpenRouter) | Technical writing & documentation | 0.6 | Very Low |
| **multimodal-looker** | Gemini 2.5 Flash (OpenRouter) | Image/PDF analysis & visual content | 0.5 | Very Low |

### Model Selection Rationale

- **Claude Max 20**: Used for Sisyphus (main orchestrator) and librarian (deep analysis). Max 20 subscription provides extended thinking and high quotas.
- **OpenRouter Fallback**: Oracle uses OpenRouter for load balancing. Explore uses free Grok 3. Frontend/document agents use cost-effective Gemini models.
- **Cost Optimization**: Free Grok for searches, cheap Gemini for creative/writing tasks, premium Claude for complex reasoning.

## Features

### 1. Multi-Agent Orchestration

**Sisyphus** acts as your project manager, delegating tasks to specialized agents:

```bash
# Single agent invocation
opencode
> Ask @oracle to review this architecture and suggest improvements

# Parallel background execution
> Have @oracle design the API while @librarian researches existing implementations

# Automatic delegation
> ultrawork: Implement feature X with comprehensive testing
# Sisyphus automatically coordinates multiple agents in parallel
```

### 2. Built-in MCPs (Model Context Protocol)

oh-my-opencode includes 3 production-ready MCPs:

- **context7**: Official documentation lookup (Effect-TS, React, Nix, etc.)
- **websearch_exa**: Real-time web search powered by Exa AI
- **grep_app**: Ultra-fast GitHub code search across millions of public repos

```bash
# Example usage
> Search official Effect-TS docs for Schema.decode
# Uses context7 MCP

> Find GitHub implementations of GritQL patterns
# Uses grep_app MCP
```

### 3. Automatic Markdown Table Formatting

**Plugin**: `@franlol/opencode-md-table-formatter@0.0.3`

Automatically formats markdown tables after AI text completion, ensuring perfect alignment and spacing:

**Features**:
- ✅ **Automatic formatting**: Tables formatted after AI completes text generation
- ✅ **Concealment mode compatible**: Correctly calculates column widths when markdown symbols are hidden
- ✅ **Alignment support**: Left (`:---`), center (`:---:`), right (`---:`)
- ✅ **Smart symbol handling**: Strips `**bold**`, `_italic_`, `~~strikethrough~~` for width calculation
- ✅ **Code preservation**: Preserves markdown symbols inside inline code (`` `**bold**` ``)
- ✅ **Edge cases**: Handles emojis, unicode characters, empty cells, long content
- ✅ **Silent operation**: No console spam, errors don't interrupt workflow
- ✅ **Validation**: Invalid tables get helpful error comments

**Example**:

Before (AI-generated raw):
```markdown
| Name | Age | City |
|---|---|---|
| Alice | 30 | NYC |
| Bob | 25 | LA |
```

After (auto-formatted):
```markdown
| Name  | Age | City |
|-------|-----|------|
| Alice | 30  | NYC  |
| Bob   | 25  | LA   |
```

**How It Works**: Uses OpenCode's `experimental.text.complete` hook to post-process AI-generated text. Multi-pass regex algorithm strips markdown symbols for width calculation while preserving symbols inside inline code.

**Configuration**: No configuration needed - works automatically when plugin is loaded.

### 4. Advanced LSP & AST-Grep Tools

Full language server protocol integration with refactoring support:

**LSP Tools**:
- `lsp_hover`: Type info, docs, signatures at cursor position
- `lsp_goto_definition`: Jump to symbol definition
- `lsp_find_references`: Find all usages across workspace
- `lsp_rename`: Rename symbol across entire workspace
- `lsp_code_actions`: Get available quick fixes/refactorings

**AST-Grep Tools**:
- `ast_grep_search`: AST-aware code pattern search (25 languages)
- `ast_grep_replace`: AST-aware code replacement

```bash
# Example usage
> Use LSP to rename function 'foo' to 'bar' across the entire workspace

> Use AST-grep to find all missing yield* in Effect.gen blocks
```

### 5. Claude Code Compatibility

Full compatibility with Claude Code's hook system:

**Supported Hooks**:
- **PostToolUse**: Comment checking, tool output truncation
- **PreToolUse**: Permission checks, context window monitoring
- **UserPromptSubmit**: Keyword detection (ultrawork, ultrathink)
- **Stop**: Todo continuation enforcement

**Configuration Files Loaded**:
- `~/.claude/commands/*.md` (custom slash commands)
- `~/.claude/agents/*.md` (custom agent definitions)
- `~/.claude/skills/*/SKILL.md` (reusable skills)
- `.claude/.mcp.json` (project MCPs)

### 6. Intelligent Features

**Todo Continuation Enforcer**: Forces agents to complete all TODOs before stopping. Eliminates the chronic LLM habit of quitting halfway.

**Comment Checker**: Reminds agents to avoid excessive comments. Ignores valid patterns (BDD, directives, docstrings) and demands justification for unnecessary comments.

**Keyword Detector**: Automatically activates specialized modes:
- `ultrawork` / `ulw`: Maximum performance with parallel agents
- `search` / `find`: Maximized search with parallel explore + librarian
- `analyze` / `investigate`: Deep analysis with multi-phase consultation
- `ultrathink`: Extended thinking mode for complex reasoning

**Context Window Monitor**: Implements anxiety management - reminds agents at 70%+ usage that there's headroom, preventing rushed work.

**Background Notification**: OS notifications when background agents complete (macOS/Linux/Windows).

**Session Recovery**: Automatically recovers from session errors (missing tool results, thinking block issues, empty messages).

## Configuration

### Nix Module Options

Configuration managed in `home.nix`:

```nix
dev-config.opencode = {
  enable = true;

  # Additional OpenCode plugins (managed via Nix)
  additionalPlugins = [
    "@franlol/opencode-md-table-formatter@0.0.3"  # Automatic markdown table formatting
    # Add more plugins here as needed
  ];

  ohMyOpencode = {
    enable = true;
    package = "oh-my-opencode";  # npm package (or "oh-my-opencode@2.4.0" to pin)

    # Disable specific hooks
    disabledHooks = ["startup-toast"];  # Cleaner startup (no "oMoMoMo" message)

    # Disable specific agents (none by default)
    disabledAgents = [];  # Example: ["oracle", "frontend-ui-ux-engineer"]

    # Disable specific MCPs (none by default)
    disabledMcps = [];  # Example: ["websearch_exa"]

    # Google Auth (false when using OpenRouter)
    enableGoogleAuth = false;

    # Model overrides (optional)
    modelOverrides = {};  # Example: { oracle = { model = "anthropic/claude-opus-4-5"; }; }
  };
};
```

### Generated Files

Home Manager generates 3 configuration files in `~/.config/opencode/`:

1. **package.json**: npm dependencies with oh-my-opencode plugin
2. **opencode.json**: OpenCode base config with plugin registration + OpenRouter provider
3. **oh-my-opencode.json**: Agent model assignments and feature toggles

### Manual Configuration (OpenRouter Provider)

The OpenRouter provider configuration in `~/.config/opencode/opencode.json` was created manually (OpenCode merges user config with built-in providers):

```json
{
  "providers": [
    {
      "id": "openrouter",
      "name": "OpenRouter",
      "apiKey": "${OPENROUTER_API_KEY}",
      "baseUrl": "https://openrouter.ai/api/v1"
    }
  ],
  "models": [
    {
      "id": "openrouter/x-ai/grok-3",
      "name": "Grok 3 (OpenRouter)",
      "provider": "openrouter",
      "contextWindow": 131072,
      "maxOutput": 65536,
      "inputPrice": 0.0,
      "outputPrice": 0.0
    }
    // ... other models
  ]
}
```

**Note**: `OPENROUTER_API_KEY` is automatically exported via `sops-env.nix` from encrypted secrets.

## Usage Patterns

### Pattern 1: Single Agent Invocation

```bash
opencode
> Ask @oracle about the best architecture for X

> Ask @librarian how Effect-TS error handling works

> Ask @explore for all Nix modules in this repository
```

### Pattern 2: Background Parallel Execution

```bash
> Have @oracle design the backend API while @librarian researches existing patterns

> Have @frontend-ui-ux-engineer build the UI while @document-writer creates the docs
```

Agents run in parallel, main agent is notified on completion.

### Pattern 3: Keyword Shortcuts

```bash
> ultrawork: Implement comprehensive error handling across the codebase
# Activates maximum performance mode with aggressive parallelization

> ultrathink: Analyze the implications of this architectural decision
# Activates extended thinking mode (32k budget)

> search: Find all uses of Effect.gen in the monorepo
# Maximizes search effort with parallel explore + librarian agents
```

### Pattern 4: LSP Refactoring

```bash
> Use LSP to find all references to the function 'mkEnableOption'

> Use LSP to rename 'oldName' to 'newName' across the entire workspace

> Show me available code actions for fixing this type error
```

### Pattern 5: AST-Grep Structural Search

```bash
> Use AST-grep to find all missing yield* in Effect.gen blocks

> Use AST-grep to replace all 'var' declarations with 'const'
```

## GritQL Policy Compatibility

oh-my-opencode works seamlessly with your strict GritQL policy:

**Policy**: GritQL is the ONLY interface for code search, linting, and modification.

**Compatibility**:
- oh-my-opencode's LSP tools use language servers (safe, read-only for analysis)
- AST-grep tools use structural transformations (compatible with policy)
- Agents respect the GritQL workflow: check (dry-run) → review → apply (confirm)

**Tools Available to Agents**:
- ✅ `gritql`, `read`, `list`, `task`, `webfetch`, `todowrite`, `todoread`, `mlg`
- ✅ `lsp_*` tools (hover, goto, references, rename, code actions)
- ✅ `ast_grep_*` tools (search, replace)
- ❌ `grep`, `glob`, `find`, `edit`, `write` (blocked by policy)

## Troubleshooting

### Issue: Plugin Not Loading

```bash
# Check plugin installation
ls -la ~/.config/opencode/node_modules/ | grep oh-my

# Verify config
cat ~/.config/opencode/opencode.json | jq '.plugin'

# Should show: ["oh-my-opencode"]
```

### Issue: Agents Not Responding

```bash
# Check oh-my-opencode config
cat ~/.config/opencode/oh-my-opencode.json | jq '.agents'

# Verify environment variable
echo $OPENROUTER_API_KEY
```

### Issue: OpenRouter Rate Limits

**Symptom**: Agents using OpenRouter models fail with 429 errors.

**Solution**: Fallback to Claude Max 20:
```nix
# In home.nix
dev-config.opencode.ohMyOpencode.modelOverrides = {
  oracle = { model = "anthropic/claude-opus-4-5"; };
  explore = { model = "anthropic/claude-sonnet-4-5"; };
};
```

### Issue: Claude Max 20 Quota Exhaustion

**Symptom**: Main orchestrator (Sisyphus) hits rate limits.

**Solution**: Use cheaper models for non-critical tasks:
```nix
dev-config.opencode.ohMyOpencode.modelOverrides = {
  Sisyphus = { model = "anthropic/claude-sonnet-4-5"; };  # Downgrade from Opus
};
```

### Issue: Excessive Agent Notifications

**Symptom**: Too many OS notifications from background agents.

**Solution**: Disable background notification hook:
```nix
dev-config.opencode.ohMyOpencode.disabledHooks = ["startup-toast", "background-notification"];
```

## Cost Management

### Estimated Costs (per 1M tokens)

| Model | Input | Output | Use Case |
|-------|-------|--------|----------|
| Grok 3 | Free | Free | File searches, exploration |
| Gemini 3 Flash | $0.19 | $0.75 | Documentation, simple tasks |
| Gemini 3 Pro | $7.50 | $30.00 | Frontend design, creative work |
| Claude Sonnet 4.5 | $3.00 | $15.00 | Codebase analysis |
| Claude Opus 4.5 | $15.00 | $75.00 | Complex reasoning, architecture |

### Cost Optimization Strategies

1. **Use Free Tier**: Grok 3 for all file searches and exploration
2. **Prefer Gemini Flash**: Documentation and simple tasks use very cheap Gemini Flash
3. **Reserve Opus for Complex Tasks**: Only use Sisyphus/oracle for architecture and debugging
4. **Background Agents**: Run cheap agents (explore, document-writer) in background while doing other work

### Monitoring Usage

```bash
# Check recent agent usage
grep -r "agent:" ~/.claude/transcripts/ | tail -20

# Estimated daily cost (rough calculation)
# Track token usage from OpenCode logs
```

## Advanced Topics

### Custom Agent Creation

Add custom agents via `.claude/agents/my-agent.md`:

```markdown
---
name: my-agent
model: openrouter/anthropic/claude-opus-4-5
temperature: 0.5
---

You are a specialized agent for...
```

Then enable in oh-my-opencode config (future enhancement - currently agents are hardcoded).

### Model Experimentation

Try different models for specific agents:

```nix
dev-config.opencode.ohMyOpencode.modelOverrides = {
  oracle = {
    model = "openrouter/anthropic/claude-opus-4-5";
    temperature = 0.1;  # More deterministic
  };
  frontend-ui-ux-engineer = {
    model = "openrouter/google/gemini-3-pro-high";
    temperature = 0.9;  # More creative
  };
};
```

### Disabling Features Selectively

```nix
# Disable specific agents
disabledAgents = ["multimodal-looker"];  # Don't need image analysis

# Disable specific hooks
disabledHooks = ["startup-toast", "comment-checker"];

# Disable specific MCPs
disabledMcps = ["websearch_exa"];  # Only use context7 and grep_app
```

## Next Steps

1. **Test agent invocations**: Try `Ask @oracle about X` and `Ask @librarian for Y`
2. **Experiment with keywords**: Use `ultrawork:`, `ultrathink:`, `search:`, `analyze:`
3. **Try background agents**: `Have @agent1 do X while @agent2 does Y`
4. **Explore MCPs**: Search official docs with context7, GitHub code with grep_app
5. **Use LSP tools**: Leverage `lsp_rename`, `lsp_find_references`, `lsp_code_actions`

## References

- **oh-my-opencode GitHub**: https://github.com/code-yeongyu/oh-my-opencode
- **md-table-formatter GitHub**: https://github.com/franlol/opencode-md-table-formatter
- **OpenCode Documentation**: https://opencode.ai/docs
- **OpenRouter Models**: https://openrouter.ai/models
- **Claude Max 20**: https://www.anthropic.com/claude/pricing

## Changelog

### 2024-12-21 - Additional Plugins Integration
- Added `@franlol/opencode-md-table-formatter@0.0.3` for automatic markdown table formatting
- Created `additionalPlugins` option in opencode.nix for extensible plugin management
- Implemented plugin name/version parser for Nix (handles scoped packages like `@org/package@version`)
- Updated package.json and opencode.json generation to include additional plugins
- Updated documentation with table formatting features and examples

### 2024-12-21 - Initial Integration
- Integrated oh-my-opencode v2.4.0 via Nix
- Configured 7 specialized agents (Sisyphus, oracle, librarian, explore, frontend, document-writer, multimodal)
- Set up OpenRouter provider with Grok 3 (free), Gemini 3 models (cheap), Claude fallback
- Enabled Claude Code compatibility (hooks, commands, skills, MCPs)
- Disabled startup-toast hook for cleaner experience
- Generated comprehensive documentation
