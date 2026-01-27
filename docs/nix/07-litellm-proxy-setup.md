# LiteLLM Proxy Integration Guide

## What is LiteLLM Proxy?

LiteLLM Proxy is a unified API gateway for multiple LLM providers (Anthropic, OpenAI, Google, Cohere, etc.). It provides a single OpenAI-compatible endpoint that routes requests to different providers.

**Official Documentation:** https://docs.litellm.ai/docs/proxy/quick_start

### Why Use LiteLLM Proxy?

**Cost Tracking & Monitoring:**
- Track token usage across team members
- Monitor costs per project/user
- Set budget limits and alerts

**Unified API:**
- Single endpoint for all LLM providers
- OpenAI-compatible format for all models
- Easy provider switching

**Reliability:**
- Automatic fallback between providers
- Rate limiting to prevent quota exhaustion
- Caching for repeated queries

**Team Management:**
- Centralized credential management
- User-based access control
- Audit logs for compliance

## Architecture

```
┌──────────────┐         ┌─────────────────┐         ┌────────────────┐
│ Claude Code  │────────>│ LiteLLM Proxy   │────────>│ Anthropic API  │
│ (localhost)  │ :4000   │ (k8s cluster)   │         │ (claude models)│
└──────────────┘         └─────────────────┘         └────────────────┘
                                 │
┌──────────────┐                 ├──────────────────>┌────────────────┐
│   Neovim     │────────>        │                   │  OpenAI API    │
│ (avante.nvim)│ :4000           │                   │  (gpt models)  │
└──────────────┘                 │                   └────────────────┘
                                 │
                                 └──────────────────>┌────────────────┐
                                                     │  Google AI API │
                                                     │ (gemini models)│
                                                     └────────────────┘
```

**Request Flow:**
1. Claude Code or Neovim sends API request to `http://localhost:4000/v1/chat/completions`
2. kubectl port-forward tunnels request to LiteLLM pod in Kubernetes cluster
3. LiteLLM authenticates request using `LITELLM_MASTER_KEY`
4. LiteLLM routes request to appropriate provider (Anthropic, OpenAI, etc.)
5. Response flows back through proxy to client (Claude Code or Neovim)

## Prerequisites

### 1. Kubernetes Cluster Access

Ensure you have kubectl configured for your cluster:

```bash
# Check cluster access
kubectl cluster-info

# Verify LiteLLM namespace exists
kubectl get namespace litellm
```

If LiteLLM is not deployed yet, see your ai-dev-env repository for deployment instructions.

### 2. LiteLLM Master Key

You need the master key from your LiteLLM deployment:

```bash
# Get master key from cluster
kubectl get secret litellm-secrets -n litellm -o jsonpath='{.data.LITELLM_MASTER_KEY}' | base64 -d
```

Save this key in your sops-nix secrets (next section).

## Setup Instructions

### Step 1: Configure LiteLLM Master Key

The LITELLM_MASTER_KEY is managed via sops-nix along with other AI credentials:

1. **Edit encrypted secrets:**
   ```bash
   sops secrets/ai.yaml
   ```

2. **Add or update the LITELLM_MASTER_KEY:**
   ```yaml
   ai:
     LITELLM_MASTER_KEY: "sk-..."  # Your master key from cluster
   ```

3. **Apply configuration:**
   ```bash
   home-manager switch --flake ~/Projects/dev-config
   ```

4. **Verify credential is loaded:**
   ```bash
   echo $LITELLM_MASTER_KEY
   # Should output: sk-...
   ```

### Step 2: Configure kubectl Port Forwarding

LiteLLM runs in your Kubernetes cluster, so you need to forward the service port to localhost.

**Option A: Manual Port Forward (for testing)**

```bash
# Forward LiteLLM service to localhost:4000
kubectl port-forward -n litellm svc/litellm 4000:4000

# Keep this terminal window open
# Press Ctrl+C to stop
```

**Option B: Background Port Forward (recommended)**

```bash
# Start in background
kubectl port-forward -n litellm svc/litellm 4000:4000 &

# Save PID for later cleanup
echo $! > ~/.litellm-port-forward.pid

# To stop later:
kill $(cat ~/.litellm-port-forward.pid)
rm ~/.litellm-port-forward.pid
```

**Option C: Persistent Port Forward (with auto-restart)**

Create `~/bin/litellm-port-forward.sh`:

```bash
#!/bin/bash
# Auto-restart port-forward if connection drops

while true; do
  echo "Starting LiteLLM port-forward..."
  kubectl port-forward -n litellm svc/litellm 4000:4000
  echo "Connection lost. Restarting in 5 seconds..."
  sleep 5
done
```

Make executable and run:

```bash
chmod +x ~/bin/litellm-port-forward.sh
~/bin/litellm-port-forward.sh &
```

**Option D: Tailscale Integration (best for production)**

If your cluster has Tailscale ingress configured, you can access LiteLLM directly without port-forwarding:

```bash
# No port-forward needed!
# Claude Code env uses: https://litellm.your-tailnet.ts.net
```

See ai-dev-env Tailscale documentation for setup.

### Step 3: Verify Claude Code Environment

Claude Code picks up LiteLLM settings from environment variables exported by Home Manager. Confirm they exist:

```bash
env | grep ANTHROPIC_
```

Expected output:

```
ANTHROPIC_BASE_URL=https://litellm.infra.samuelho.space
ANTHROPIC_AUTH_TOKEN=sk-virtual-key...
ANTHROPIC_CUSTOM_HEADERS=x-litellm-api-key: Bearer sk-virtual-key...
```

If these variables are missing, re-run `home-manager switch --flake .` and ensure `dev-config.claude-code.litellm` options are enabled.

### Step 4: Load Credentials

The LiteLLM master key is automatically loaded when you enter the dev-config directory:

```bash
cd ~/Projects/dev-config

# Environment variables are automatically available via sops-env module
echo $LITELLM_MASTER_KEY
# Should output: sk-...
```

**All AI credentials loaded automatically:**
- ANTHROPIC_API_KEY
- OPENAI_API_KEY
- GOOGLE_AI_API_KEY
- LITELLM_MASTER_KEY
- OPENROUTER_API_KEY

### Step 5: Test the Integration

**Test 1: Health Check**

```bash
# Test LiteLLM proxy is accessible
curl http://localhost:4000/health

# Expected response:
# {"status": "healthy"}
```

**Test 2: Claude Code Query**

```bash
claude ask "What is 2+2?"

# Should receive response from Claude via LiteLLM proxy
```

**Test 3: Verify Proxy Usage**

Check LiteLLM logs in cluster to confirm requests are routing through proxy:

```bash
kubectl logs -n litellm deployment/litellm --tail=20 -f

# Watch for log entries like:
# POST /v1/chat/completions - 200 OK
```

## Usage

### Daily Workflow

**Before coding:**

```bash
# 1. Start port-forward (if not using Tailscale)
kubectl port-forward -n litellm svc/litellm 4000:4000 &

# 2. Enter dev-config directory (loads credentials)
cd ~/Projects/dev-config

# 3. Use Claude Code as normal
claude ask "Explain this codebase"
```

**After coding:**

```bash
# Stop port-forward (if running in background)
pkill -f "port-forward.*litellm"
```

### Checking Cost/Usage

LiteLLM provides a dashboard for tracking usage:

```bash
# Forward dashboard port
kubectl port-forward -n litellm svc/litellm 8080:8080

# Open browser
open http://localhost:8080
```

View:
- Total tokens used
- Cost per user/project
- Model usage distribution
- Error rates

### Neovim Integration (avante.nvim)

**avante.nvim** provides a Cursor-like AI coding assistant directly in Neovim, powered by your LiteLLM proxy.

**Setup:**

1. **Ensure LiteLLM proxy is accessible:**
   ```bash
   # Start port-forward (if not using Tailscale)
   kubectl port-forward -n litellm svc/litellm 4000:4000 &

   # Verify connection
   curl -s http://localhost:4000/health
   ```

2. **Load LITELLM_MASTER_KEY:**
   ```bash
   cd ~/Projects/dev-config  # direnv auto-loads credentials

   # Verify key is loaded
   echo $LITELLM_MASTER_KEY
   ```

3. **Launch Neovim:**
   ```bash
   nvim
   ```

**Available Commands:**

| Command | Description |
|---------|-------------|
| `:AvanteAsk` | Open chat interface to ask AI about code |
| `:AvanteEdit` | Request AI code edits (applies changes directly) |
| `:AvanteToggle` | Toggle Avante chat window |

**Example Workflow:**

```vim
" 1. Open file you want to modify
:e src/components/UserProfile.tsx

" 2. Ask AI about the code
:AvanteAsk What does this component do?

" 3. Request specific edits
:AvanteEdit Add error handling for API failures

" 4. Review and accept/reject changes
" Changes appear as diff in buffer, accept with :AvanteAccept
```

**Keybindings (if configured in nvim/lua/config/keymaps.lua):**

- `<leader>aa` - Quick ask (`:AvanteAsk`)
- `<leader>ae` - Quick edit (`:AvanteEdit`)
- `<leader>ar` - Toggle chat window (`:AvanteToggle`)

**Architecture:**

```
Neovim (avante.nvim) → http://localhost:4000/v1 (kubectl port-forward)
                      → LiteLLM Proxy (k8s cluster)
                      → Anthropic/OpenAI/Google APIs
```

**Cost Tracking:**

All avante.nvim requests go through LiteLLM proxy, so they're automatically tracked in the dashboard alongside Claude CLI usage.

**Performance Tips:**

- Keep port-forward running in background for faster response times
- Use Tailscale integration for zero-latency access (no port-forward needed)
- Configure timeout in `nvim/lua/plugins/ai.lua` if experiencing slow responses

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| "Plugin not loading" | Check `LITELLM_MASTER_KEY` is set: `echo $LITELLM_MASTER_KEY` |
| "Connection timeout" | Verify port-forward: `curl http://localhost:4000/health` |
| "Invalid API key" | Ensure sops-nix secrets have correct master key |
| "Model not found" | Check LiteLLM config has `claude-sonnet-4` model configured |

## Troubleshooting

### "Connection refused" or "Cannot connect to localhost:4000"

**Cause:** Port-forward is not running

**Solution:**

```bash
# Check if port-forward is running
ps aux | grep "port-forward.*litellm"

# Start port-forward
kubectl port-forward -n litellm svc/litellm 4000:4000 &
```

### "LITELLM_MASTER_KEY not set"

**Cause:** Credentials not loaded from sops-nix

**Solution:**

```bash
# Check if environment variable is loaded
echo $LITELLM_MASTER_KEY

# If not, verify sops-nix secrets are decrypted
ls ~/.local/share/sops-nix/secrets.d/*/ai/

# Reload shell configuration
source ~/.zshrc

# Verify again
echo $LITELLM_MASTER_KEY
```

### "Invalid API key" or "Authentication failed"

**Cause:** Wrong master key in sops-nix secrets

**Solution:**

```bash
# Get correct key from cluster
kubectl get secret litellm-secrets -n litellm -o jsonpath='{.data.LITELLM_MASTER_KEY}' | base64 -d

# Update sops-nix secrets
sops secrets/ai.yaml
# Update LITELLM_MASTER_KEY value

# Apply changes
home-manager switch --flake ~/Projects/dev-config

# Reload shell and verify
exec zsh
echo $LITELLM_MASTER_KEY
```

### "Context deadline exceeded" or "Timeout"

**Cause:** Port-forward connection dropped

**Solution:**

```bash
# Kill existing port-forward
pkill -f "port-forward.*litellm"

# Restart with auto-retry
while true; do
  kubectl port-forward -n litellm svc/litellm 4000:4000
  sleep 2
done &
```

### "Model not found" errors

**Cause:** LiteLLM proxy doesn't have that model configured

**Solution:**

```bash
# Check available models exposed by the gateway
curl http://localhost:4000/v1/models

# Use any enabled model directly
claude --model claude-3-5-haiku-20241022 ask "..."
```

If the model is missing from the list, enable it via the LiteLLM dashboard UI (Model Registry → Enable Model).

### Port-forward keeps disconnecting

**Cause:** Network instability or cluster issues

**Solutions:**

1. **Use persistent port-forward script** (see Setup Step 2, Option C)

2. **Switch to Tailscale ingress** (recommended for production):
   - Set `ANTHROPIC_BASE_URL=https://litellm.your-tailnet.ts.net`
   - No port-forward needed
   - More stable connection

3. **Check cluster networking:**
   ```bash
   kubectl get pods -n litellm
   kubectl describe pod -n litellm <litellm-pod-name>
   ```

## Model Management

All model routing, fallbacks, and provider enablement are handled directly inside the LiteLLM dashboard UI. Use the UI to:
- Add/remove Anthropic, MiniMax, OpenAI, etc. deployments
- Create virtual keys scoped to specific model groups
- Set per-user budgets, rate limits, or fallback chains

No local config edits are required—dev-config only supplies the base URL and authentication headers so Claude Code always talks to the homelab gateway.

## Security Best Practices

1. **Never commit API keys:**
   - All secrets encrypted with sops-nix (age encryption)
   - Environment variables loaded from tmpfs (RAM-only)
   - Config files use `{env:VAR}` syntax

2. **Rotate keys regularly:**
   - Update cluster secret
   - Update sops-nix secrets: `sops secrets/ai.yaml`
   - Apply changes: `home-manager switch --flake ~/Projects/dev-config`

3. **Use minimal permissions:**
   - LiteLLM master key should have read-only access to models
   - No admin permissions needed

4. **Monitor usage:**
   - Review LiteLLM dashboard weekly
   - Set budget alerts in cluster
   - Check for unauthorized access

5. **Audit logs:**
   ```bash
   # Check recent API usage
   kubectl logs -n litellm deployment/litellm --since=1h | grep "POST /v1"
   ```

## Next Steps

- **Claude Code Guidance:** [Repository CLAUDE.md](../../CLAUDE.md)
- **sops-nix Setup:** [sops-nix Configuration](../../SETUP_SOPS.md)
- **Advanced Nix:** [Advanced Customization](06-advanced.md)
