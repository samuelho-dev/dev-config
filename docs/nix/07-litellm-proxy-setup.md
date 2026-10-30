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

Local OMP and Neovim Avante use the hosted LiteLLM HTTPS endpoint
`https://litellm.samuelho.space/v1`; no port-forward is needed. OMP consumes
`LITELLM_BASE_URL` and `LITELLM_API_KEY` using its built-in LiteLLM provider.
Avante inherits its native OpenAI Responses implementation and defaults to
the `coding-default` alias. An explicit proxy model can be selected for the
current Neovim session using Avante's provider object (below); its selector
does not dynamically discover inherited-provider models. LiteLLM centrally
routes `coding-default` to `openai-codex/gpt-6.1-sol`.
This does not replace the shared Rex OMP auth gateway/OAuth broker and does
not change OMP's global `openai-codex/gpt-6.1-sol:high` default. Claude Code
keeps its native authentication; an explicit per-command override is separate.

## Credentials (1Password-First)

The application client key lives in **1Password**, not in the Nix store or a
`secrets/ai.yaml` file. Home Manager fetches it at activation and writes a
mode-0600 `~/.config/sops-nix/load-env.sh`; shells only source that generated
file. The existing master key remains an administrative credential, not client
authentication. The base URL is a nonsecret Home Manager session variable.

| 1Password field (item `ai` in vault `Dev`) | Exported shell var |
|---|---|
| `LITELLM_KEY` | `LITELLM_MASTER_KEY` (admin only) |
| `LITELLM_CLIENT_KEY` | `LITELLM_API_KEY` (OMP and Avante) |
| `ANTHROPIC_API_KEY` | `ANTHROPIC_API_KEY` |
| `OPENAI_API_KEY` | `OPENAI_API_KEY` |
| `GOOGLE_AI_STUDIO_KEY` | `GOOGLE_AI_API_KEY` |
| `OPENROUTER_API_KEY` | `OPENROUTER_API_KEY` |

> The only declared sops-nix secret is `op/service_account_token`
> (`secrets/default.yaml`, age-encrypted). The encrypted file may retain a legacy
> `git.github_token` field until the next sync. `op` uses the bootstrap token
> during Home Manager activation to populate the generated key exports.

## Setup Instructions

### Step 1: Provision a scoped client key

Provision `LITELLM_CLIENT_KEY` on item `ai` in 1Password vault `Dev`, with
the correct proxy model permissions. Do not put the LiteLLM administrative
`LITELLM_KEY` into the application field or a tracked file. Provisioning,
authorization and key rotation are owner-operated; no credentials are
committed by this repository.

### Step 2: Apply Home Manager Configuration

```bash
cd ~/Projects/dev-config
home-manager switch --flake .
```

Activation regenerates `~/.config/sops-nix/load-env.sh`. Open a fresh login
shell and restart OMP/Neovim so their processes inherit both variables.
Check without printing the secret:

```bash
test -n "$LITELLM_API_KEY" && printf 'client key loaded\n'
printf '%s\n' "$LITELLM_BASE_URL"
```

### Step 3: Use native OMP and Avante

OMP's native `litellm` provider sees the proxy through the standard variables;
no `models.yml` registration or default-role rewrite is needed. In Neovim,
Avante uses `coding-default` through `/v1/responses`. Its inherited-provider
selector does not dynamically list proxy models; set an explicit ID for the
current session with `:lua require('avante.providers').litellm.model = 'MODEL_ID'`.
The master key is never used for these application requests. Native Claude
Code authentication stays independent; Home Manager does not set its proxy.

### Step 4: Read-only connectivity smoke

```bash
/usr/bin/curl -fsS -o /dev/null -w '%{http_code}\n' \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  "$LITELLM_BASE_URL/models"
```

Run only with the application key, and never log the Authorization header.
Successful authorized responses return HTTP 200. Local Python urllib may
receive Cloudflare 403; use the native curl check, not a DNS/TLS bypass.

## Neovim Integration (avante.nvim)

**avante.nvim** uses `LITELLM_API_KEY` (the client key), `LITELLM_BASE_URL`,
and the native OpenAI Responses API body/stream/tool implementation. The
`coding-default` alias omits unsupported sampling parameters inherited from
Avante's OpenAI defaults. Launch Neovim from a fresh login shell after
activation. To switch to an explicit proxy model for the current session use
`:lua require('avante.providers').litellm.model = 'MODEL_ID'` (not a static
editor catalog); the selector does not fetch the gateway's model list.

**Available Commands:**

| Command | Description |
|---------|-------------|
| `:AvanteAsk` | Open chat interface to ask AI about code |
| `:AvanteEdit` | Request AI code edits (applies changes directly) |
| `:AvanteToggle` | Toggle Avante chat window |

**Keybindings (Avante defaults):** `<leader>aa` asks, `<leader>ae` edits,
`<leader>at` toggles the sidebar. `<leader>a?` selects only models already
configured/selected in Avante. Proxy requests are tracked at the gateway;
native Claude Code is independent.

## Checking Cost / Usage

LiteLLM provides a dashboard for tracking usage. Open the gateway's dashboard URL
(or, when self-hosting, forward the dashboard port:
`kubectl port-forward -n litellm svc/litellm 8080:8080` and open
`http://localhost:8080`). View total tokens, cost per user/project, model usage
distribution, and error rates.

## Troubleshooting

### "LITELLM_API_KEY not set"

Confirm the 1Password `Dev/ai` item has an authorized
`LITELLM_CLIENT_KEY`, then activate Home Manager and start a fresh login shell:

```bash
test -n "$LITELLM_API_KEY" && printf 'client key loaded\n'
printf '%s\n' "$LITELLM_BASE_URL"
```

The generated loader is refreshed at activation, not each shell start. Do
not print or copy the client key into a repo file.

### "Invalid API key" / "Authentication failed"

An invalid application key or ungranted model requires an owner to inspect
LiteLLM's client-key authorization and the `Dev/ai/LITELLM_CLIENT_KEY`
1Password field. Re-activate Home Manager after authorized key rotation,
open a fresh login shell, then restart the clients. Do not use
`LITELLM_MASTER_KEY` as a fallback.

### Network or model errors

Use the authenticated native `/usr/bin/curl` `/v1/models` smoke above. HTTP
403 from Python urllib alone is not proof of a proxy outage. A missing model
must be enabled and granted to the application key in LiteLLM; model routing
is centrally administered. No local OMP `models.yml` registration is needed.

## Model Management

All model routing, fallbacks, and provider enablement are handled in the LiteLLM
dashboard UI:
- Add/remove Anthropic, OpenAI, MiniMax, etc. deployments
- Create virtual keys scoped to specific model groups
- Set per-user budgets, rate limits, or fallback chains

dev-config supplies OMP and Avante client credentials and base URL. Claude Code
does not always talk to the gateway.

## Security Best Practices

1. **Never commit API keys.** AI keys live in 1Password; the repo stores an
   age-encrypted bootstrap token. Home Manager writes their exports to
   mode-0600 `~/.config/sops-nix/load-env.sh` on disk, not the Nix store.
2. **Rotate keys regularly.** After updating the 1Password field, run
   `home-manager switch --flake .`, then open a new shell or source the loader.
3. **Use least privilege.** Client keys should be scoped to required models;
   retain the master key for administrative operations only.
4. **Monitor usage.** Review the LiteLLM dashboard and set budget alerts.

## Next Steps

- **Claude Code Guidance:** [Repository CLAUDE.md](../../CLAUDE.md)
- **1Password Setup:** [1Password SSH & CLI](09-1password-ssh.md)
- **Advanced Nix:** [Advanced Customization](06-advanced.md)
