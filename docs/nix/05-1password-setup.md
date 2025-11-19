# 1Password Setup Guide

## Overview

This guide shows you how to configure 1Password CLI for automatic AI credential management in your development environment.

**Benefits:**
- ✅ Secrets never touch disk
- ✅ Credentials auto-load when entering dev-config directory
- ✅ Team-wide secret sharing via 1Password vaults
- ✅ Audit trail of secret access
- ✅ Easy credential rotation

## Prerequisites

- 1Password account (personal or team)
- 1Password desktop app installed
- 1Password CLI (`op`) installed via Nix (already done!)

## Step 1: Create "Dev" Vault

1. Open 1Password desktop app
2. Click "New Vault" (or use existing vault)
3. Name: `Dev`
4. Type: Personal or Shared (for team access)
5. Click "Create"

## Step 2: Create "ai" Item

1. In "Dev" vault, click "New Item"
2. Select "Login" or "Password" as template
3. Title: `ai`
4. Add custom fields for each AI provider:

### Required Fields

**Anthropic (Claude):**
- Field Label: `ANTHROPIC_API_KEY`
- Field Type: Password (concealed)
- Value: Your Anthropic API key (starts with `sk-ant-`)

**OpenAI (GPT models):**
- Field Label: `OPENAI_API_KEY`
- Field Type: Password (concealed)
- Value: Your OpenAI API key (starts with `sk-proj-` or `sk-`)

**Google AI (Gemini):**
- Field Label: `GOOGLE_AI_API_KEY`
- Field Type: Password (concealed)
- Value: Your Google AI API key

### Optional Fields (Add as needed)

**Cohere:**
- Field Label: `COHERE_API_KEY`
- Field Type: Password
- Value: Your Cohere API key

**Hugging Face:**
- Field Label: `HUGGINGFACE_TOKEN`
- Field Type: Password
- Value: Your HF token

**LangSmith (for tracing):**
- Field Label: `LANGCHAIN_API_KEY`
- Field Type: Password
- Value: Your LangSmith API key

## Step 2b: Create "litellm" Item (For Team/Cluster Integration)

If you're using LiteLLM proxy for team-based AI usage tracking and centralized credential management, create a separate item:

1. In "Dev" vault, click "New Item"
2. Select "API Credential" as template
3. Title: `litellm`
4. Add custom field:

**LiteLLM Master Key:**
- Field Label: `MASTER_KEY`
- Field Type: Password (concealed)
- Value: Your LiteLLM proxy master key (get from cluster: `kubectl get secret litellm-secrets -n litellm -o jsonpath='{.data.LITELLM_MASTER_KEY}' | base64 -d`)

**Why separate item?**
- Different use case: Proxy authentication vs direct API access
- Different rotation schedule: Cluster key vs provider keys
- Clearer organization: `ai` for direct API, `litellm` for proxy

**For complete LiteLLM setup:** See [LiteLLM Proxy Setup Guide](07-litellm-proxy-setup.md)

## Step 3: Authenticate 1Password CLI

### Initial Sign-In

```bash
op signin
```

Follow prompts:
1. Enter your 1Password account URL (e.g., `my.1password.com`)
2. Enter email address
3. Enter secret key (from Emergency Kit)
4. Enter master password
5. Optionally save credentials in system keychain

### Verify Authentication

```bash
op account get
```

Should output your account details.

### List Vaults

```bash
op vault list
```

Should show "Dev" vault.

### Test Credential Retrieval

```bash
op item get "ai" --vault "Dev"
```

Should display the "ai" item (credentials concealed).

### Test Field Access

```bash
op read "op://Dev/ai/ANTHROPIC_API_KEY"
```

Should output your actual API key (starts with `sk-ant-`).

## Step 4: Configure Auto-Loading

Credentials auto-load when you enter the dev-config directory via direnv:

```bash
cd ~/Projects/dev-config
# 🔐 Loading AI credentials from 1Password...
#   ✓ Loaded: ANTHROPIC_API_KEY
#   ✓ Loaded: OPENAI_API_KEY
#   ✓ Loaded: GOOGLE_AI_API_KEY
#   ✓ Loaded: LITELLM_MASTER_KEY
# ✅ AI credentials loaded from 1Password
```

**How it works:**
1. `.envrc` detects directory entry
2. Checks if `op` is authenticated
3. Sources `scripts/load-ai-credentials.sh`
4. Exports API keys as environment variables
5. OpenCode and other tools use credentials from environment

## Step 5: Usage Patterns

### Pattern 1: Auto-Injected Environment Variables

```bash
cd ~/Projects/dev-config  # Credentials load automatically
opencode ask "What is this project?"  # Uses $ANTHROPIC_API_KEY
```

### Pattern 2: Explicit op run (Most Secure)

```bash
op run -- opencode ask "Explain this codebase"
# Credentials injected only for duration of command
```

### Pattern 3: Manual Loading

```bash
source ~/Projects/dev-config/scripts/load-ai-credentials.sh
# Credentials now in environment for current shell session
```

## Security Best Practices

### 1. Never Commit Credentials

**Verify .gitignore protection:**
```bash
grep -E "\.env|\.op" ~/Projects/dev-config/.gitignore
# Should show:
# .env
# .env.*
# .op/
```

### 2. Rotate Keys Regularly

**Update API key in 1Password:**
1. Open 1Password desktop app
2. Find "Dev" vault → "ai" item
3. Edit field (e.g., `ANTHROPIC_API_KEY`)
4. Paste new key
5. Save

**Next credential load will use new key** (no code changes needed!)

### 3. Use Service Accounts for CI/CD

For GitHub Actions or other CI/CD:

1. Create 1Password service account:
   - https://1password.com/features/service-accounts

2. Store service account token as GitHub Secret:
   - Settings → Secrets → `OP_SERVICE_ACCOUNT_TOKEN`

3. Use in GitHub Actions:
   ```yaml
   - name: Load secrets
     env:
       OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
     run: |
       op read "op://Dev/ai/ANTHROPIC_API_KEY"
   ```

### 4. Audit Secret Access

```bash
# View access history
op item get "ai" --vault "Dev" --format json | jq '.overview'

# Shows:
# - Last accessed time
# - Last modified time
# - Created time
```

### 5. Principle of Least Privilege

For team vaults:
1. Create separate vaults for different environments
   - `Dev` vault for development keys (lower spend limits)
   - `Prod` vault for production keys (restricted access)

2. Use vault permissions to control access
   - Developers: Read-only access to Dev vault
   - DevOps: Read/write access to Prod vault

## Troubleshooting

### "op: command not found"

**Solution:** Verify Nix environment:
```bash
nix develop
which op  # Should output: /nix/store/.../bin/op
```

Or install globally:
```bash
nix profile install nixpkgs#_1password
```

### "Session expired"

**Solution:** Re-authenticate:
```bash
op signin
```

Enable biometric unlock for faster re-auth:
```bash
op signin --account your-account.1password.com
# Follow prompts to enable Touch ID / Windows Hello
```

### "Item not found: ai"

**Solution:** Verify item name and vault:
```bash
# List all items in Dev vault
op item list --vault "Dev"

# Check exact item name (case-sensitive!)
op item get "ai" --vault "Dev"
```

### "Field not found: ANTHROPIC_API_KEY"

**Solution:** Verify field label matches exactly:
```bash
# View all fields
op item get "ai" --vault "Dev" --format json | jq '.fields[].label'

# Field labels are case-sensitive and must match exactly:
# Correct: ANTHROPIC_API_KEY
# Wrong: anthropic_api_key, Anthropic API Key
```

### Credentials not loading automatically

**Solution:** Check direnv status:
```bash
cd ~/Projects/dev-config
direnv status  # Should show "Found RC allowed true"
```

If not allowed:
```bash
direnv allow
```

## Team Collaboration

### Sharing Credentials with Team

1. Create shared vault in 1Password for Teams
2. Add team members to vault
3. Create "ai" item with team credentials
4. Each team member runs `op signin`
5. Credentials auto-load for all team members

### Best Practices for Teams

1. **Separate dev/prod credentials:**
   - `Dev` vault: Development API keys (lower rate limits)
   - `Prod` vault: Production keys (restricted access)

2. **Document field structure:**
   - Create `docs/1password-schema.md` with required fields
   - Ensures consistency across team

3. **Audit credential usage:**
   - Review 1Password activity log monthly
   - Rotate shared credentials quarterly

4. **Onboarding checklist:**
   - New team member signs into 1Password
   - Granted access to Dev vault
   - Runs `op signin` on workstation
   - Verifies credential loading: `source scripts/load-ai-credentials.sh`

## Advanced Configuration

### Custom Vault Names

If you use a different vault name (e.g., "Secrets"):

Edit `scripts/load-ai-credentials.sh`:
```bash
# Change from:
ANTHROPIC_API_KEY=$(op read "op://Dev/ai/ANTHROPIC_API_KEY" 2>/dev/null)

# To:
ANTHROPIC_API_KEY=$(op read "op://Secrets/ai/ANTHROPIC_API_KEY" 2>/dev/null)
```

### Multiple Items

For organization-specific credentials:

```bash
# Work credentials
op read "op://Work/ai/ANTHROPIC_API_KEY"

# Personal credentials
op read "op://Personal/ai/ANTHROPIC_API_KEY"
```

### Environment-Specific Loading

In `~/.zshrc.local`:
```bash
# Load work credentials during work hours
if [ "$(date +%H)" -ge 9 ] && [ "$(date +%H)" -le 17 ]; then
  export ANTHROPIC_API_KEY=$(op read "op://Work/ai/ANTHROPIC_API_KEY" 2>/dev/null)
else
  export ANTHROPIC_API_KEY=$(op read "op://Personal/ai/ANTHROPIC_API_KEY" 2>/dev/null)
fi
```

## Frequently Asked Questions

**Q: Can I use a different secrets manager (e.g., AWS Secrets Manager, Vault)?**

A: Yes! Edit `scripts/load-ai-credentials.sh` to fetch from your preferred source:
```bash
# AWS Secrets Manager
ANTHROPIC_API_KEY=$(aws secretsmanager get-secret-value --secret-id dev/ai/anthropic --query SecretString --output text)

# HashiCorp Vault
ANTHROPIC_API_KEY=$(vault kv get -field=api_key secret/dev/ai/anthropic)
```

**Q: How do I use different providers for different projects?**

A: Create project-specific .envrc files:
```bash
# ~/Projects/work-project/.envrc
export OPENCODE_PROVIDER=openai
export ANTHROPIC_API_KEY=$(op read "op://Work/ai/OPENAI_API_KEY")

# ~/Projects/personal-project/.envrc
export OPENCODE_PROVIDER=anthropic
export ANTHROPIC_API_KEY=$(op read "op://Personal/ai/ANTHROPIC_API_KEY")
```

**Q: Can I share credentials with CI/CD?**

A: Yes! Use 1Password service accounts or GitHub Secrets integration:
- https://developer.1password.com/docs/ci-cd/github-actions/

## Next Steps

- **OpenCode Integration:** [OpenCode Usage](04-opencode-integration.md)
- **Quick Start:** [Installation Guide](00-quickstart.md)
- **Advanced Nix:** [Advanced Guide](06-advanced.md)
