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

## Authentication with 1Password

OpenCode requires API credentials for LLM providers (Anthropic, OpenAI, Google, etc.). Instead of storing credentials in config files, we use 1Password CLI for secure secret management.

### Setup Process

1. **Create 1Password "ai" item** (see [1Password Setup Guide](05-1password-setup.md))

2. **Sign in to 1Password:**
   ```bash
   op signin
   ```

3. **Verify credentials are accessible:**
   ```bash
   op read "op://Dev/ai/ANTHROPIC_API_KEY"
   # Should output: sk-ant-...
   ```

### Auto-Loading Credentials

**Method 1: direnv (Recommended)**

When you `cd` into the dev-config directory, credentials automatically load:

```bash
cd ~/Projects/dev-config
# 🔐 Loading AI credentials from 1Password...
#   ✓ Loaded: ANTHROPIC_API_KEY
#   ✓ Loaded: OPENAI_API_KEY
#   ✓ Loaded: GOOGLE_AI_API_KEY
# ✅ AI credentials loaded from 1Password

opencode ask "What is this codebase?"
# ← Credentials are already in environment
```

**Method 2: Manual source**

```bash
source ~/Projects/dev-config/scripts/load-ai-credentials.sh
```

**Method 3: op run wrapper** (Most secure - credentials never touch disk)

```bash
op run -- opencode ask "Explain this file"
```

Add to your `~/.zshrc.local` for permanent alias:
```bash
alias opencode='op run -- opencode'
```

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
