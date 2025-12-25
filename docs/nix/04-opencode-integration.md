# OpenCode Integration Guide

## What is OpenCode?

OpenCode is an AI coding agent built for the terminal. It enables developers to interact with LLM-based assistance directly in their workflow, supporting tasks like:

- Ask questions about codebases
- Generate new features with planning mode
- Make direct code modifications
- Undo/redo changes
- Share conversations with team members
- Analyze project structure

**Official Documentation:** https://opencode.ai/docs/

## Installation (Already Done!)

OpenCode is automatically installed via Nix when you run `bash scripts/install.sh`.

**Verify installation:**
```bash
opencode --version
```

## Authentication with sops-nix

OpenCode requires API credentials for LLM providers (Anthropic, OpenAI, Google, etc.). These credentials are securely managed using sops-nix with age encryption.

### How it Works

1. **API keys stored encrypted** in `secrets/ai.yaml` (age encryption)
2. **Decrypted at Home Manager activation** to tmpfs (RAM-only)
3. **Environment variables automatically loaded** via shell initialization
4. **Zero network latency** - no external queries on shell startup

### Auto-Loading Credentials

**Automatic in all shells:**

The `sops-env.nix` module automatically loads AI credentials in all shells:

```bash
# Open a new terminal or source your shell config
echo $ANTHROPIC_API_KEY  # Already available
echo $OPENAI_API_KEY     # Already available

# Use OpenCode directly - credentials are already loaded
opencode ask "What is this codebase?"
```

**What gets loaded:**
- `ANTHROPIC_API_KEY` - Claude API
- `OPENAI_API_KEY` - OpenAI API
- `GOOGLE_AI_API_KEY` - Google AI API
- `LITELLM_MASTER_KEY` - LiteLLM proxy master key
- `OPENROUTER_API_KEY` - OpenRouter multi-model API

### Security Benefits

- ✅ **Encrypted at rest** - Age encryption protects secrets
- ✅ **Decrypted to tmpfs** - Never written to disk unencrypted
- ✅ **Instant loading** - No network calls (~0.24s shell startup)
- ✅ **Automatic** - No manual loading required

### Setup Process

See [sops-nix Setup Guide](../../SETUP_SOPS.md) for complete configuration instructions.

## Common OpenCode Commands

### Ask Questions

```bash
opencode ask "How does authentication work in this project?"
opencode ask "What dependencies does this project use?"
```

### Generate Features

```bash
opencode feature "Add a health check endpoint to the API"
opencode feature "Implement user password reset functionality"
```

### Code Modifications

```bash
opencode modify "Refactor this function to use async/await"
opencode modify "Add error handling to all database queries"
```

### Project Analysis

```bash
opencode analyze  # Analyzes project structure
opencode explain <file>  # Explains specific file
```

## LiteLLM Proxy Integration

For team environments with centralized LLM management, OpenCode can route all API requests through a LiteLLM proxy server running in your Kubernetes cluster.

### Why Use LiteLLM Proxy?

- **Cost Tracking:** Monitor token usage across team
- **Unified API:** Single endpoint for all LLM providers
- **Fallback Support:** Automatic failover between providers
- **Rate Limiting:** Prevent API quota exhaustion
- **Team Management:** Centralized credential management

### Setup

**Complete setup guide:** [LiteLLM Proxy Setup](07-litellm-proxy-setup.md)

**Quick start:**

1. **Ensure OpenCode is configured for LiteLLM:**
   ```bash
   cat ~/.config/opencode/opencode.json
   ```

   Should contain:
   ```json
   {
     "provider": {
       "anthropic": {
         "options": {
           "baseURL": "http://localhost:4000",
           "apiKey": "{env:LITELLM_MASTER_KEY}"
         }
       }
     }
   }
   ```

2. **Start kubectl port-forward:**
   ```bash
   kubectl port-forward -n litellm svc/litellm 4000:4000 &
   ```

3. **Verify credentials are loaded:**
   ```bash
   echo $LITELLM_MASTER_KEY  # Should show your master key
   ```

4. **Use OpenCode normally:**
   ```bash
   opencode ask "What is this codebase?"
   # Requests go through LiteLLM proxy → Anthropic API
   ```

### Direct API vs LiteLLM Proxy

**Direct API (default for local development):**
- Uses `ANTHROPIC_API_KEY` directly
- No proxy/cluster dependency
- Good for: Personal projects, offline work

**LiteLLM Proxy (recommended for team environments):**
- Uses `LITELLM_MASTER_KEY` + cluster proxy
- Requires kubectl port-forward
- Good for: Team collaboration, cost tracking

## Configuration

OpenCode configuration is managed via environment variables:

### Provider Selection

```bash
# Use Claude (Anthropic)
export OPENCODE_PROVIDER=anthropic

# Use GPT-4 (OpenAI)
export OPENCODE_PROVIDER=openai

# Use Gemini (Google)
export OPENCODE_PROVIDER=google
```

### Custom Configuration

Create `~/.config/opencode/config.json`:

```json
{
  "defaultProvider": "anthropic",
  "providers": {
    "anthropic": {
      "enabled": true,
      "model": "claude-3-5-sonnet-20241022"
    },
    "openai": {
      "enabled": true,
      "model": "gpt-4-turbo-preview"
    },
    "google": {
      "enabled": true,
      "model": "gemini-pro"
    }
  },
  "theme": "dark",
  "verbose": false
}
```

**Important:** Do NOT store API keys in config files. Use environment variables or 1Password.

## Advanced Usage

### Conversation History

OpenCode stores conversation history:
```bash
opencode history        # List recent conversations
opencode resume <id>    # Resume a conversation
```

### Custom Agents

Define custom agents in `AGENTS.md` at project root:

```markdown
# AGENTS.md

## Custom Agent: Code Reviewer

You are a code reviewer focused on security and performance.
When reviewing code, check for:
- SQL injection vulnerabilities
- XSS risks
- Performance bottlenecks
- Missing error handling
```

Then use:
```bash
opencode --agent "Code Reviewer" review <file>
```

### Team Collaboration

Share conversations with team:
```bash
opencode share <conversation-id>  # Generates shareable link
```

## Troubleshooting

### "API Key not found"

**Solution:** Verify 1Password authentication and credential loading:
```bash
# Check 1Password authentication
op account get

# Re-sign in if needed
op signin

# Manually load credentials
source ~/Projects/dev-config/scripts/load-ai-credentials.sh

# Verify environment variables
echo $ANTHROPIC_API_KEY  # Should output: sk-ant-...
```

### "Rate limit exceeded"

**Solution:** Switch providers:
```bash
export OPENCODE_PROVIDER=openai  # Switch from Anthropic to OpenAI
opencode ask "Same question"
```

### "Command not found: opencode"

**Solution:** Enter Nix development shell:
```bash
cd ~/Projects/dev-config
nix develop  # Activates environment with OpenCode
opencode --version
```

Or install globally:
```bash
nix profile install nixpkgs#nodePackages.opencode-ai
```

### Credentials not auto-loading

**Solution 1:** Check direnv installation:
```bash
direnv version  # Should output version number
```

**Solution 2:** Allow direnv in directory:
```bash
cd ~/Projects/dev-config
direnv allow
```

**Solution 3:** Check .envrc syntax:
```bash
cat .envrc
# Should contain: use flake
```

## Security Best Practices

1. **Never commit API keys:**
   - `.env` and `.env.*` are gitignored
   - Use 1Password for all secrets

2. **Rotate keys regularly:**
   - Update 1Password "ai" item
   - Credentials refresh automatically on next load

3. **Use op run for sensitive operations:**
   ```bash
   op run -- opencode ask "Explain production database schema"
   # Credentials injected only for duration of command
   ```

4. **Audit credential access:**
   ```bash
   op item get "ai" --vault "Dev" --format json | jq '.overview'
   # Shows last access time
   ```

## Integration with Other Tools

### Claude Code (this tool!)

OpenCode complements Claude Code:
- **Claude Code:** Interactive development, file editing, code review
- **OpenCode:** Terminal-based coding agent, project analysis

Use both:
```bash
# Use Claude Code for interactive development
claude

# Use OpenCode for quick terminal queries
opencode ask "What does this function do?"
```

## Slash Commands and Agents

OpenCode shares slash commands and agents with Claude Code through a centralized `ai/` directory to avoid duplication.

### Architecture

```
ai/                          ← Single source of truth
├── commands/                ← Shared commands (all AI tools)
├── agents/                  ← Shared agents (all AI tools)
└── tools/                   ← Shared utilities

.claude/                     ← Claude Code
├── commands -> ../ai/commands/
└── agents -> ../ai/agents/

.opencode/                   ← OpenCode
└── command -> ../ai/commands/
```

### Why Centralized?

- **No Duplication**: Commands defined once in `ai/`, used by both tools
- **Consistency**: Same commands work identically in both tools
- **Easy Maintenance**: Update commands in one place
- **Scalable**: Easy to add new AI tools in the future

### OpenCode-Specific Features

OpenCode has additional capabilities not in Claude Code:

- **Custom Tools**: `@gritql`, `@mlg` for structural code changes
- **Guardrail Plugins**: TypeScript plugins that enforce policies
- **Effect-TS Integration**: Type-safe schemas and validation
- **Multi-Agent System**: oh-my-opencode with specialized agents

### Using Commands in OpenCode

```bash
# Commands work the same as in Claude Code
opencode
> /create-command   # Creates new slash command in ai/commands/
> /debug            # Debug issues
> @typescript-pro   # Use TypeScript agent from ai/agents/
```

### Creating OpenCode-Specific Tools

```bash
# Use the create-tool command
opencode
> /create-tool
# Creates tool in .opencode/tool/ (OpenCode-specific)
```

### Adding New Shared Commands

```bash
# Add to centralized location
echo "Your command prompt" > ai/commands/my-command.md

# Automatically available in both tools
# Claude Code: /my-command
# OpenCode: /my-command
```

### Git Integration

OpenCode can help with Git workflows:
```bash
# Generate commit messages
git diff | opencode ask "Write a commit message for these changes"

# Explain Git history
opencode ask "Summarize the last 10 commits"
```

### CI/CD Integration

Use OpenCode in automated workflows:
```bash
# In GitHub Actions
- name: Code Review
  run: |
    op run -- opencode review src/ > review-report.md
```

## Next Steps

- **1Password Setup:** [1Password Configuration](05-1password-setup.md)
- **Advanced Nix:** [Advanced Guide](06-advanced.md)
- **Daily Workflows:** [Daily Usage](02-daily-usage.md)
