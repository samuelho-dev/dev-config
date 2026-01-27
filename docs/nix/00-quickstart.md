# Dev-Config Quickstart (Nix-Powered)

## New Machine Setup (5 minutes)

```bash
git clone https://github.com/samuelho-dev/dev-config
cd dev-config
bash scripts/install.sh
```

That's it! Restart your terminal and you're done.

## What Just Happened?

The install script automatically:

1. ✅ **Installed Nix** (if not present) - Declarative package manager
2. ✅ **Installed all packages** (Neovim, tmux, zsh, Docker, Claude CLI, 1Password CLI, etc.)
3. ✅ **Created symlinks** (nvim config → `~/Projects/dev-config/nvim`)
4. ✅ **Installed plugins** (Neovim: lazy.nvim, tmux: TPM, zsh: Oh My Zsh + Powerlevel10k)
5. ✅ **Set zsh as default shell**

All package versions are pinned in `flake.lock` for reproducibility.

## Common Tasks

### Update All Packages

```bash
cd ~/Projects/dev-config
nix flake update  # Updates flake.lock with latest versions
git commit flake.lock -m "chore: update dependencies"
```

### Rebuild Environment

```bash
nix run .#activate  # Re-creates symlinks, reinstalls plugins
```

### Rollback to Previous Version

```bash
nix profile rollback  # Instant rollback to previous generation
```

### Test Changes Before Committing

```bash
nix develop  # Enter temporary shell with all packages
# Test your changes...
exit         # Leave temporary shell
```

## Claude Code + LiteLLM Integration

### One-Time Setup

1. **Sign in to 1Password:**
   ```bash
   op signin
   ```

2. **Create "ai" item in "Dev" vault** (see [1Password Setup Guide](05-1password-setup.md)):
   - Field: `ANTHROPIC_API_KEY`
   - Field: `LITELLM_MASTER_KEY` (or virtual key) for the gateway
   - Any other provider keys you use (OpenAI, Google, etc.)

### Daily Usage

```bash
# AI credentials auto-load when you enter dev-config directory
cd ~/Projects/dev-config
# ✅ AI credentials loaded from 1Password

# Use Claude Code with LiteLLM routing preconfigured
claude ask "What is this repository about?"
claude feature "Add a new greeting function"
```

**Alternative:** Use wrapper for explicit credential injection:
```bash
op run -- claude ask "Explain this codebase"
```

## Directory Structure

```
dev-config/
├── flake.nix           # Nix package definitions (all tools)
├── flake.lock          # Pinned versions (committed for reproducibility)
├── .envrc              # direnv auto-activation
│
├── scripts/
│   ├── install.sh              # NEW: Nix bootstrap (50 lines)
│   ├── load-ai-credentials.sh  # NEW: 1Password integration
│   └── install-legacy.sh       # OLD: Shell-based installer (backup)
│
├── nvim/               # Neovim config (symlinked to ~/.config/nvim)
├── tmux/               # Tmux config (symlinked to ~/.tmux.conf)
├── zsh/                # Zsh config (symlinked to ~/.zshrc)
└── ghostty/            # Ghostty config
```

## Troubleshooting

### "Nix command not found"

Restart your terminal or source the Nix daemon:
```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### "1Password credentials not loading"

1. Check authentication: `op account get`
2. If not signed in: `op signin`
3. Verify item exists: `op item get "ai" --vault "Dev"`

### Symlinks not created

Run activation manually:
```bash
nix run .#activate
```

## Next Steps

- **Full Documentation:** [Nix Concepts](01-concepts.md)
- **Daily Workflows:** [Daily Usage](02-daily-usage.md)
- **LiteLLM Setup:** [LiteLLM Proxy](07-litellm-proxy-setup.md)
- **1Password Setup:** [1Password Configuration](05-1password-setup.md)
- **Advanced Customization:** [Advanced Guide](06-advanced.md)

## Help & Support

- **Validation:** Run `bash scripts/validate.sh` to diagnose issues
- **GitHub Issues:** https://github.com/samuelho-dev/dev-config/issues
- **CLAUDE.md:** See root `CLAUDE.md` for AI assistance details
