# 1Password Setup Guide

## Overview

This guide shows you how to configure 1Password for SSH authentication and Claude Code OAuth tokens.

**Note:** AI API keys (Anthropic, OpenAI, Google AI, etc.) are now managed via sops-nix. See [sops-nix Setup Guide](../../SETUP_SOPS.md) for AI credential management.

## Current 1Password Usage

1Password is still used for:
- ✅ **SSH Keys** - GitHub authentication and commit signing
- ✅ **Claude Code OAuth tokens** - Multi-profile authentication
- ✅ **Service account tokens** (optional) - DevPod/container environments

**Benefits:**
- ✅ SSH private keys never touch disk
- ✅ Biometric unlock for SSH operations
- ✅ Cross-device key sync via 1Password cloud
- ✅ Audit trail of SSH key usage

## Prerequisites

- 1Password account (personal or team)
- 1Password desktop app installed
- 1Password CLI (`op`) installed via Nix (already done!)

## Step 1: SSH Key Setup

See [1Password SSH Setup Guide](09-1password-ssh.md) for complete SSH authentication configuration.

## Step 2: Claude Code OAuth Tokens (Optional)

If using Claude Code CLI with multiple profiles:

1. **Create "Dev" vault** in 1Password desktop app
2. **Create "ai" item** with OAuth tokens:
   - Field: `claude-code-oauth-token` → Primary account token
   - Field: `claude-code-oauth-token-2` → Secondary account token
   - Field: `claude-code-oauth-token-work` → Work account token

3. **Generate tokens:**
   ```bash
   CLAUDE_CONFIG_DIR=~/.claude claude setup-token
   CLAUDE_CONFIG_DIR=~/.claude-2 claude setup-token
   CLAUDE_CONFIG_DIR=~/.claude-work claude setup-token
   ```

4. **Store tokens in 1Password** using the field names above

## AI API Keys (Migrated to sops-nix)

**Important:** AI API keys are now managed via sops-nix for better performance and reliability.

- ❌ **No longer stored in 1Password:** ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.
- ✅ **Now managed by sops-nix:** Encrypted in `secrets/ai.yaml`
- ✅ **Automatic loading:** Via `sops-env.nix` module

**To manage AI credentials:**
See [sops-nix Setup Guide](../../SETUP_SOPS.md)

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

### Test Credential Retrieval (Optional)

If you've stored Claude Code OAuth tokens:

```bash
op item get "ai" --vault "Dev"
```

Should display the "ai" item (credentials concealed).

### Test Field Access (Optional)

```bash
op read "op://Dev/ai/claude-code-oauth-token"
```

Should output your OAuth token (starts with `sk-ant-oat01-`).

## Step 4: Usage with Claude Code

Claude Code CLI integrates with 1Password for multi-profile authentication:

```bash
# Each alias automatically injects OAuth token from 1Password
claude /status         # Default profile
claude-2 /status       # Profile 2
claude-work /status    # Work profile
```

**How it works:**
1. Shell alias sets `CLAUDE_CONFIG_DIR` for profile isolation
2. Injects `CLAUDE_CODE_OAUTH_TOKEN` via `op read`
3. Launches `claude` CLI with isolated authentication

## Step 5: SSH Authentication

For GitHub operations, 1Password SSH Agent handles authentication:

```bash
# Clone repositories (auto-converts to SSH)
git clone https://github.com/username/repo.git

# Commits are automatically signed
git commit -m "Your message"

# Push with biometric authentication
git push origin main
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

**For SSH keys:**
1. Generate new SSH key in 1Password
2. Update GitHub with new public key
3. Update `~/.config/home-manager/secrets.nix`
4. Run `home-manager switch --flake ~/Projects/dev-config`

**For AI API keys:**
See [sops-nix Setup Guide](../../SETUP_SOPS.md) for rotating encrypted API keys

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
