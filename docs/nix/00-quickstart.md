# Dev-Config Quickstart (Nix-Powered)

## New Machine Setup (5 minutes)

```bash
# 1. Clone the repo
git clone https://github.com/samuelho-dev/dev-config
cd dev-config

# 2. Create your machine-specific user file
cp user.nix.example user.nix
# Edit user.nix with your username + homeDirectory, then:
git add -f user.nix   # gitignored, but must be staged for flake evaluation

# 3. Run the installer
bash scripts/install.sh
```

Restart your terminal and you're done.

## What Just Happened?

`scripts/install.sh`:

1. ✅ **Installs Nix** (Determinate Systems installer) if not present
2. ✅ **Enables flakes** in `~/.config/nix/nix.conf`
3. ✅ **Installs Home Manager** if not present
4. ✅ **Runs `home-manager switch --flake .`**, which:
   - Installs all packages (Neovim, tmux, zsh, fzf, ripgrep, LSP servers, etc.)
   - Symlinks dotfiles (`nvim/`, `tmux/`, `zsh/`, `ghostty/`, `yazi/`)
   - Installs Oh My Zsh + Powerlevel10k and tmux plugins (Nix-managed, no TPM)

All package versions are pinned in `flake.lock` for reproducibility.

## Common Tasks

### Apply Configuration Changes

```bash
cd ~/Projects/dev-config
home-manager switch --flake .
```

### Test Before Applying

```bash
home-manager build --flake .        # Build without activating
home-manager switch --flake . --dry-run   # Preview changes
```

### Update All Packages

```bash
nix flake update                    # Updates flake.lock with latest versions
git commit flake.lock -m "chore: update dependencies"
home-manager switch --flake .
```

### Rollback to Previous Version

```bash
home-manager generations            # List previous generations
/nix/store/...-home-manager-generation/activate   # Activate an older one
```

### Test Changes in a Throwaway Shell

```bash
nix develop                         # Enter a temporary shell with all packages
# Test your changes...
exit                                # Leave temporary shell
```

## Claude Code + Optional LiteLLM Integration

The personal/work and DevPod profiles enable `dev-config.claude-code.enable`.
Activation preserves any existing executable Claude; only when absent does it
run the official native installer for floating latest. The CLI stays writable
and native installs self-update. Settings, OAuth, plugins and skills are not
managed by this bootstrap. See [native bootstrap details](../../ai/claude/README.md).
MCP targeting is configured separately through `dev-config.mcp.targets.claude`.

AI service keys live in **1Password** (not in the Nix store). The `sops-env`
Home Manager module fetches them during activation and writes mode-0600
`~/.config/sops-nix/load-env.sh` on disk; shells source it without contacting 1Password.

### One-Time Setup

1. **Bootstrap the 1Password service-account token via sops-nix.**
   The only declared sops-nix secret is `op/service_account_token` in
   `secrets/default.yaml` (age-encrypted); the encrypted file may retain a legacy
   `git.github_token` field until the next sync. The token lets `op` run
   non-interactively during activation. See
   [1Password SSH & CLI Guide](09-1password-ssh.md).

2. **Store your AI keys in the 1Password vault.**
   All keys live in vault `Dev`, item `ai`, with fields:
   - `ANTHROPIC_API_KEY`
   - `OPENAI_API_KEY`
   - `GOOGLE_AI_STUDIO_KEY`
   - `LITELLM_KEY`
   - `OPENROUTER_API_KEY`

### Daily Usage

```bash
# Open a new shell; load-env.sh sources keys fetched during Home Manager activation.
# Claude Code uses its native configuration; Home Manager does not set a proxy.
# LiteLLM routing requires an explicit opt-in (see the proxy guide below).

claude "What is this repository about?"
```

If you explicitly configured a gateway, check its URL without printing API keys:

```bash
printf '%s\n' "${ANTHROPIC_BASE_URL:-not set}"
```

See [LiteLLM Proxy Setup](07-litellm-proxy-setup.md) for full details.

## Directory Structure

```
dev-config/
├── flake.nix           # Entry point: homeManagerModules, devShells
├── flake.lock          # Pinned versions (committed for reproducibility)
├── home.nix            # Personal Home Manager config (sops-nix secrets)
├── work.nix            # Lean work-machine config
├── user.nix            # Machine-specific values (GITIGNORED, must `git add -f`)
│
├── scripts/
│   ├── install.sh                  # Nix + Home Manager bootstrap
│   └── validate-linting-config.sh  # Pre-commit linting guardrail
│
├── modules/home-manager/   # Program + service modules
├── pkgs/default.nix        # Centralized package definitions
├── ai/                     # CLI bootstraps, MCP, curated skills and hooks
│
├── nvim/               # Neovim config (symlinked to ~/.config/nvim)
├── tmux/               # Tmux config
├── zsh/                # Zsh config
└── ghostty/            # Ghostty config
```

## Troubleshooting

### "Nix command not found"

Restart your terminal or source the Nix daemon:
```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Flake evaluation fails: "user.nix not found"

`user.nix` is gitignored but must be staged for the flake to see it:
```bash
git add -f user.nix
```

### "1Password credentials not loading"

1. Confirm the service-account token is set without printing it: `test -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" && echo "Bootstrap token present"`
2. Check `op` is authenticated: `op account get`
3. Verify the AI item exists: `op item get ai --vault Dev`
4. Re-source the loader: `source ~/.config/sops-nix/load-env.sh`

### Config changes not applied

Run `home-manager switch --flake .` (not just `build`), then restart your terminal.

## Next Steps

- **Full Documentation:** [Nix Concepts](01-concepts.md)
- **Daily Workflows:** [Daily Usage](02-daily-usage.md)
- **LiteLLM Setup:** [LiteLLM Proxy](07-litellm-proxy-setup.md)
- **1Password Setup:** [1Password SSH & CLI](09-1password-ssh.md)
- **Advanced Customization:** [Advanced Guide](06-advanced.md)

## Help & Support

- **GitHub Issues:** https://github.com/samuelho-dev/dev-config/issues
- **CLAUDE.md:** See root `CLAUDE.md` for AI assistance details
