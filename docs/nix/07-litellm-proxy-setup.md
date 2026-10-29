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

## Architecture (Default: Team Gateway)

dev-config talks to a hosted LiteLLM gateway over HTTPS. There is **no
port-forward** in the default setup — the gateway has a stable public ingress.

```
┌──────────────┐                          ┌─────────────────────────────┐
│ Claude Code  │ ──── HTTPS ────────────> │ LiteLLM Gateway             │
│              │  litellm.infra...space   │ (homelab, Tailscale ingress)│
└──────────────┘                          └──────────────┬──────────────┘
                                                          │
┌──────────────┐                                          ├──> Anthropic API
│   Neovim     │ ──── HTTPS ───────────────────────────>  ├──> OpenAI API
│ (avante.nvim)│                                          └──> Google AI API
└──────────────┘
```

**Request Flow:**
1. Claude Code / Neovim sends an Anthropic-format request to
   `https://litellm.infra.samuelho.space/anthropic`.
2. The gateway authenticates the request using the `LITELLM_MASTER_KEY` env var.
3. LiteLLM routes to the appropriate provider (Anthropic, OpenAI, etc.).
4. The response flows back over HTTPS.

## Credentials (1Password-First)

The LiteLLM key lives in **1Password**, not in the Nix store and not in a
`secrets/ai.yaml` file. The `sops-env` Home Manager module fetches it at
activation and writes mode-0600 `~/.config/sops-nix/load-env.sh` on disk;
shells only source that generated file.

| 1Password field (item `ai` in vault `Dev`) | Exported shell var |
|---|---|
| `LITELLM_KEY` | `LITELLM_MASTER_KEY` |
| `ANTHROPIC_API_KEY` | `ANTHROPIC_API_KEY` |
| `OPENAI_API_KEY` | `OPENAI_API_KEY` |
| `GOOGLE_AI_STUDIO_KEY` | `GOOGLE_AI_API_KEY` |
| `OPENROUTER_API_KEY` | `OPENROUTER_API_KEY` |

> The only declared sops-nix secret is `op/service_account_token`
> (`secrets/default.yaml`, age-encrypted). The encrypted file may retain a legacy
> `git.github_token` field until the next sync. `op` uses the bootstrap token
> during Home Manager activation to populate the generated key exports.

## Setup Instructions

### Step 1: Store the LiteLLM Key in 1Password

Add (or update) the `LITELLM_KEY` field on item `ai` in vault `Dev`:

```bash
op item edit ai --vault Dev "LITELLM_KEY[password]=sk-..."

# Verify:
op item get ai --vault Dev --fields label=LITELLM_KEY --reveal
```

If you are self-hosting LiteLLM in a cluster, you can read the master key from
the cluster secret first:

```bash
kubectl get secret litellm-secrets -n litellm \
  -o jsonpath='{.data.LITELLM_MASTER_KEY}' | base64 -d
```

### Step 2: Apply Home Manager Configuration

```bash
cd ~/Projects/dev-config
home-manager switch --flake .
```

This regenerates `~/.config/sops-nix/load-env.sh`. Open a new shell (or
`source ~/.config/sops-nix/load-env.sh`) and verify:

```bash
echo $LITELLM_MASTER_KEY    # Should output: sk-...
```

### Step 3: Verify Claude Code Environment

Home Manager no longer configures Claude Code proxy routing. If the gateway is
configured to support your authentication method, opt in for a single command:

```bash
ANTHROPIC_BASE_URL=https://litellm.infra.samuelho.space/anthropic claude
```

To inspect an explicitly configured shell override without printing credentials:

```bash
printf '%s\n' "${ANTHROPIC_BASE_URL:-not set}"
```

For an explicit shell override, the output is the configured URL:

```
https://litellm.infra.samuelho.space/anthropic
```

A per-command override does not change the parent shell's environment.

An unset `ANTHROPIC_BASE_URL` is normal for native Claude Code access. Running
`home-manager switch --flake .` does not enable proxy routing.

### Step 4: Test the Integration

```bash
# Health check against the gateway
curl https://litellm.infra.samuelho.space/health

# Claude Code query (explicit gateway opt-in)
ANTHROPIC_BASE_URL=https://litellm.infra.samuelho.space/anthropic claude "What is 2+2?"
```

## Self-Hosting Locally (Optional)

> **Only follow this section if you run LiteLLM yourself in Kubernetes.**
> The default team setup uses the HTTPS gateway above and needs none of this.

If you run LiteLLM in a local cluster, expose it on `localhost:4000` and use
an explicit per-command URL override.

**Port-forward the service:**

```bash
kubectl port-forward -n litellm svc/litellm 4000:4000 &
echo $! > ~/.litellm-port-forward.pid   # save PID for cleanup
# Stop later: kill $(cat ~/.litellm-port-forward.pid) && rm ~/.litellm-port-forward.pid
```

**Persistent auto-restarting port-forward** (`~/bin/litellm-port-forward.sh`):

```bash
#!/bin/bash
while true; do
  echo "Starting LiteLLM port-forward..."
  kubectl port-forward -n litellm svc/litellm 4000:4000
  echo "Connection lost. Restarting in 5 seconds..."
  sleep 5
done
```

**Point Claude Code at localhost** for one invocation:

```bash
ANTHROPIC_BASE_URL=http://localhost:4000/anthropic claude
```

No Home Manager option or activation is required.

## Neovim Integration (avante.nvim)

**avante.nvim** provides a Cursor-like AI coding assistant in Neovim, powered by
the same gateway. It reads `LITELLM_MASTER_KEY` from the environment, so no
extra setup is needed once the key is loaded.

1. Confirm the key is loaded: `echo $LITELLM_MASTER_KEY`
2. Launch `nvim`.

**Available Commands:**

| Command | Description |
|---------|-------------|
| `:AvanteAsk` | Open chat interface to ask AI about code |
| `:AvanteEdit` | Request AI code edits (applies changes directly) |
| `:AvanteToggle` | Toggle Avante chat window |

**Keybindings (if configured in `nvim/lua/config/keymaps.lua`):**

- `<leader>aa` - Quick ask (`:AvanteAsk`)
- `<leader>ae` - Quick edit (`:AvanteEdit`)
- `<leader>ar` - Toggle chat window (`:AvanteToggle`)

All avante.nvim requests go through the gateway, so usage is tracked alongside
Claude CLI usage.

## Checking Cost / Usage

LiteLLM provides a dashboard for tracking usage. Open the gateway's dashboard URL
(or, when self-hosting, forward the dashboard port:
`kubectl port-forward -n litellm svc/litellm 8080:8080` and open
`http://localhost:8080`). View total tokens, cost per user/project, model usage
distribution, and error rates.

## Troubleshooting

### "LITELLM_MASTER_KEY not set"

**Cause:** Keys not loaded from 1Password.

**Solution:**

```bash
# Confirm the service-account token is present
echo $OP_SERVICE_ACCOUNT_TOKEN

# Confirm op can read the item
op item get ai --vault Dev --fields label=LITELLM_KEY --reveal

# Re-source the loader, then re-check
source ~/.config/sops-nix/load-env.sh
echo $LITELLM_MASTER_KEY
```

If `load-env.sh` is missing or stale, run `home-manager switch --flake .`.

### "Invalid API key" / "Authentication failed"

**Cause:** Wrong `LITELLM_KEY` value in 1Password.

**Solution:** Update the field, re-run Home Manager to regenerate the loader,
then open a new shell (or source the regenerated file):

```bash
op item edit ai --vault Dev "LITELLM_KEY[password]=sk-..."
home-manager switch --flake .
source ~/.config/sops-nix/load-env.sh
echo $LITELLM_MASTER_KEY
```

### "Connection refused" / timeout

**Default (team gateway):** check connectivity to the ingress —
`curl https://litellm.infra.samuelho.space/health`. If you rely on Tailscale
ingress, confirm you are connected to the tailnet.

**Self-hosting:** the port-forward likely dropped. Restart it:

```bash
ps aux | grep "port-forward.*litellm"
kubectl port-forward -n litellm svc/litellm 4000:4000 &
```

### "Model not found"

**Cause:** The gateway doesn't have that model enabled.

```bash
# List models exposed by the gateway (default)
curl https://litellm.infra.samuelho.space/v1/models
```

Enable the model via the LiteLLM dashboard (Model Registry → Enable Model).

## Model Management

All model routing, fallbacks, and provider enablement are handled in the LiteLLM
dashboard UI:
- Add/remove Anthropic, OpenAI, MiniMax, etc. deployments
- Create virtual keys scoped to specific model groups
- Set per-user budgets, rate limits, or fallback chains

No local config edits are required — dev-config only supplies the base URL and
authentication so Claude Code always talks to the gateway.

## Security Best Practices

1. **Never commit API keys.** AI keys live in 1Password; the repo stores an
   age-encrypted bootstrap token. Home Manager writes their exports to
   mode-0600 `~/.config/sops-nix/load-env.sh` on disk, not the Nix store.
2. **Rotate keys regularly.** After updating the 1Password field, run
   `home-manager switch --flake .`, then open a new shell or source the loader.
3. **Use minimal permissions.** Virtual/master keys should be scoped to the
   models you actually use.
4. **Monitor usage.** Review the LiteLLM dashboard and set budget alerts.

## Next Steps

- **Claude Code Guidance:** [Repository CLAUDE.md](../../CLAUDE.md)
- **1Password Setup:** [1Password SSH & CLI](09-1password-ssh.md)
- **Advanced Nix:** [Advanced Customization](06-advanced.md)
