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

`scripts/install.sh` installs Nix if missing, enables flakes, then invokes
the Home Manager app from this flake's locked input
(`nix run .#home-manager -- switch --flake .`). The selected profile provisions
shared system commands and dotfiles and writes
`~/.config/dev-config/native-tools` for enabled OMP, Pi, Claude, OpenCode,
Codex and Vercel. `ai/bootstrap.sh install` fills missing writable CLIs in
`~/.local` without upgrading existing installations on shell startup or
Home Manager activation. Curated skills are reconciled per link, preserving
physical user directories and unmanaged/edited skills.

`flake.lock` pins Nix source revisions, not native CLI versions, MCP stdio
packages or plugin updates. Mac extras in `pkgs/Brewfile` are opt-in, held
third-party sources need explicit trust, and `pkgs/tool-checks.json` records
shared Darwin/Linux system command checks.

## Common Tasks

### Apply Configuration Changes

```bash
cd ~/Projects/dev-config
nix run .#home-manager -- switch --flake .
```

### Test Before Applying

```bash
nix eval --raw .#homeConfigurations.$(whoami).activationPackage.drvPath
nix build --no-link .#homeConfigurations.$(whoami).activationPackage
```

### Update Packages and Native CLIs Deliberately

Update `flake.lock` only after reviewing Nix input changes; then activate
the selected Home Manager profile. Update native CLIs separately:

```bash
bash ai/bootstrap.sh check   # enabled executables, not OAuth or MCP auth
bash ai/bootstrap.sh update  # enabled native CLIs
```

Provider login, intended team/project authorization and the separate MCP
credential source still need explicit enrollment. Native Vercel owner OAuth
is not the community MCP child's token (`VERCEL_MCP_TOKEN` becomes only the
child's `VERCEL_TOKEN`). See [Configuration](../CONFIGURATION.md).

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

## Native Coding CLIs + Optional LiteLLM Integration

Selected personal and work profiles enable native coding CLIs. The
single `ai/bootstrap.sh` owner installs missing enabled OMP, Pi, Claude,
OpenCode, Codex and Vercel CLIs; it does not update working CLIs or configure
their settings/OAuth. Explicit `bash ai/bootstrap.sh update` is the upgrade
path. MCP targeting is separate and selected per Claude/OMP/Codex profile.
Use explicit `op` or `env` credential resolution, never implicit fallback.

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
│   ├── install.sh                  # Nix + flake-selected Home Manager app
│   └── validate-linting-config.sh  # Pre-commit linting guardrail
│
├── modules/home-manager/   # Program + service modules
├── pkgs/default.nix        # Centralized package definitions
├── ai/                     # One native CLI owner, MCP, curated skills and hooks
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

After reviewing activation effects, run
`nix run .#home-manager -- switch --flake .`; `nix build --no-link
.#homeConfigurations.$(whoami).activationPackage` only builds, then restart
your terminal.

## Next Steps

- **Full Documentation:** [Nix Concepts](01-concepts.md)
- **Daily Workflows:** [Daily Usage](02-daily-usage.md)
- **LiteLLM Setup:** [LiteLLM Proxy](07-litellm-proxy-setup.md)
- **1Password Setup:** [1Password SSH & CLI](09-1password-ssh.md)
- **Advanced Customization:** [Advanced Guide](06-advanced.md)

## Help & Support

- **GitHub Issues:** https://github.com/samuelho-dev/dev-config/issues
- **CLAUDE.md:** See root `CLAUDE.md` for AI assistance details
