# Configuration Guide

How to customize and extend your dev-config setup. Dotfiles in `nvim/`, `tmux/`,
`zsh/`, `ghostty/`, `yazi/` are version-controlled and symlinked by Home Manager —
edit them directly and reload the app (no rebuild needed). Package/LSP/formatter
provisioning is declarative and lives in `pkgs/default.nix` and the program modules
under `modules/home-manager/programs/`.

## Machine-Specific Configuration

### `~/.zshrc.local` — Personal, Untracked Config

`~/.zshrc.local` (gitignored) holds machine-specific shell settings that should not be
committed.

```bash
# PATH additions
export PATH="$HOME/custom-bin:$PATH"

# Machine-specific aliases
alias staging="ssh user@staging.example.com"

# Non-secret env vars
export DATABASE_URL="postgresql://localhost:5432/mydb"

# Conda/pyenv init blocks, etc.
```

**Why:** not tracked in Git, machine-local, survives updates to the shared `.zshrc`.

### Secrets / API Keys (1Password)

Do **not** put real secrets in `.zshrc.local`. AI service keys are 1Password-first:
Home Manager retrieves them from the `Dev` vault during activation and writes
mode-0600 `~/.config/sops-nix/load-env.sh` on disk. Shells source that file
without querying 1Password (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`,
`GOOGLE_AI_API_KEY`, `LITELLM_MASTER_KEY`, `OPENROUTER_API_KEY`). See the root
`CLAUDE.md` "Secrets Management" section and `docs/nix/07-litellm-proxy-setup.md`.

### Rex homelab access (separate identity)

The shared Nix toolchain includes `supabase`, `psql`, `kubectl`, and `argocd`
on Darwin and Linux. Rex must use its own projected Kubernetes ServiceAccount
token and CA, with an explicit kubeconfig context in namespace `argocd`;
`KUBECONFIG` points at that config. The operator grant belongs only to this Rex
profile, not every DevPod. Do not copy an Orca/Mac home, admin kubeconfig, or
broker credential into Rex. On the Mac, `argocd-core.sh --tailnet
https://<kubernetes-proxy> app list -o json` creates private throwaway
Kubernetes/Argo configs with a **nonsecret** bearer placeholder solely to
prevent the tailnet proxy's Basic prompt; it does not grant Kubernetes access.
Inside Rex, `argocd-core.sh --in-cluster app list -o json` uses the projected
`tokenFile` and creates only the private Argo core config. Neither mode edits
`~/.argocd/config` or other kube contexts, and neither logs into Argo API mode.

Source validation: the Mac tailnet core helper listed 64 Argo applications,
all Synced. The shared Nix cloud package set evaluated with `supabase-cli` and
`postgresql` on aarch64-darwin and x86_64-linux, without building them. This
does not prove the as-yet-undeployed Rex projected-token path or provider auth.

Canonical MCP definitions in `ai/mcp/servers.json` fan out to Claude Code,
OMP and Codex. Resolve these **dedicated** credential sources during activation
(`op` on Mac, environment projection in Rex):

| Server | 1Password reference | Rex environment | Required authorization |
|--------|---------------------|-----------------|------------------------|
| Linear | `op://Dev/Linear/MCP_API_KEY` | `LINEAR_API_KEY` | Approved Linear MCP account |
| Vercel community | `op://Dev/Vercel/TOKEN` | `VERCEL_TOKEN` | Approved Vercel team; pinned stdio package, no second official-MCP OAuth grant required |
| Sentry | `op://Dev/creativetoolkits-sentry-mcp/TOKEN` | `SENTRY_MCP_KEY` | `Sentry-Bearer` access to the intended project |
| PostHog | `op://Dev/creativetoolkits-posthog-mcp/TOKEN` | `POSTHOG_MCP_KEY` | Bearer access to the intended project; tools mode, **not** globally read-only |

The renderer omits an unresolved authenticated MCP server instead of publishing
an unauthenticated/stale entry and writes all managed credential-bearing configs
mode 0600 without passing resolved secrets as subprocess arguments; an omitted
**required** server is an enrollment failure, not a healthy integration.
These references are credential *sources*, not credentials to commit. Supabase
CLI needs a **valid Management API PAT**
through its native `SUPABASE_ACCESS_TOKEN` environment source (or the user's
authorized CLI keychain enrollment on macOS). The existing legacy Mac
`Supabase CLI/access-token` value was rejected by the API; do not reuse it.
Rex PostgreSQL access needs an approved DB principal via `PGHOST`, `PGDATABASE`,
`PGUSER`, `PGPASSWORD` (prefer a scoped role rather than an application owner).
Never put either password in a command argument or tracked config.

For AWS select a named project profile explicitly, e.g.
`aws --profile ctk-operator sts get-caller-identity` in Rex (the existing Mac
project profile is `creativetoolkits`). The smoke removes inherited AWS access-key,
session, region and endpoint overrides before using that profile, then checks
both account and exact expected ARN. Backblaze B2's `us-east-005` region
and S3 endpoint belong only to B2 commands/backend; do not overwrite the
default profile, which other backup/Terraform callers use.

`check-rex-access.py` is a read-only, fail-closed smoke entrypoint once
credentials are enrolled. Supply expected nonsecret
`REX_EXPECTED_KUBE_IDENTITY`, `REX_EXPECTED_AWS_ACCOUNT`,
`REX_EXPECTED_AWS_ARN`, `REX_EXPECTED_POSTGRES_IDENTITY` (`user|database`),
`REX_EXPECTED_SUPABASE_PROJECT_ID`, `REX_EXPECTED_SENTRY_PROJECT`,
`REX_EXPECTED_POSTHOG_PROJECT_ID`, `REX_EXPECTED_VERCEL_TEAM`, and the
PostHog MCP's accepted `REX_POSTHOG_MODEL` identifier. It checks actual CLI
identities, an anonymous Kubernetes secret denial, MCP read-only project/team
calls, and invalid MCP credentials. Missing required credentials/targets fail
the check. Do not report enrollment complete from package presence or an MCP
tools list alone; optional profile integrations may remain unconfigured.

## Editing Configs

| Config | Path | Reload |
|--------|------|--------|
| Neovim | `nvim/lua/config/*.lua`, `nvim/lua/plugins/*.lua` | Restart Neovim |
| Tmux | `modules/home-manager/programs/tmux.nix` (`extraConfig`) | `home-manager switch`, then `Prefix + r` |
| Zsh | `zsh/.zshrc`, `zsh/.zprofile` | `source ~/.zshrc` or `exec zsh` |
| Ghostty | `ghostty/config` | Immediate |
| Yazi | `yazi/` | Restart Yazi |

After editing tracked files, commit and push, then `home-manager switch --flake .` on
other machines.

## Neovim Customization

Neovim is fully modular — there is no monolithic `init.lua`. Entry point is
`nvim/init.lua` (loads `nvim/lua/config/`), and plugins are grouped by concern.

- **Options / keymaps / autocmds:** `nvim/lua/config/options.lua`,
  `keymaps.lua`, `autocmds.lua`
- **Plugins:** `nvim/lua/plugins/*.lua` (`lsp.lua`, `completion.lua`, `editor.lua`,
  `git.lua`, `ui.lua`, `ai.lua`, `markdown.lua`, `treesitter.lua`, `tools.lua`)
- **Your own plugins:** add a file under `nvim/lua/plugins/custom/`

### Adding a Plugin

Create or edit a file in `nvim/lua/plugins/`:

```lua
return {
  'author/plugin-name',
  config = function()
    require('plugin-name').setup({})
  end,
}
```

Restart Neovim; lazy.nvim auto-installs. Versions are locked in `nvim/lazy-lock.json`
(commit changes to keep machines consistent; `:Lazy update` / `:Lazy restore`).

### Adding an LSP Server

LSP servers and formatters are Nix-managed (declared in
`modules/home-manager/programs/neovim.nix`) and wired in `nvim/lua/plugins/lsp.lua`.
To add one: add the package in `neovim.nix`, then register it in the `servers` table
in `lsp.lua`, and run `home-manager switch --flake .`.

## Tools: LSP, Formatters, Colorscheme

Tmux plugins and Neovim LSPs/formatters are **not** installed by Mason or TPM at
runtime — they are provisioned by Nix.

Neovim uses the Rex Cathode Amber palette through existing Kanagawa Dragon
highlighting; no extra plugin is needed. After `home-manager switch --flake .`,
the matching takes effect on the next Neovim launch because installed files are
Nix-store symlinks.

| Tool | Language | Role | Source |
|------|----------|------|--------|
| nixd | Nix | LSP (formats via alejandra) | `neovim.nix` / `lsp.lua` |
| pyright | Python | LSP | `neovim.nix` / `lsp.lua` |
| biome | JS/TS/JSON/JSONC | LSP + formatter | `neovim.nix` / `lsp.lua` |
| lua_ls | Lua | LSP | `lsp.lua` |
| stylua | Lua | formatter | `neovim.nix` |
| ruff | Python | formatter + linter (`ruff_format`) | `neovim.nix` |
| prettier | YAML/Markdown | formatter | `neovim.nix` |
| alejandra | Nix | formatter (matches `nix fmt`) | `neovim.nix` |

Formatter routing lives in the `conform.nvim` config in `nvim/lua/plugins/lsp.lua`.

## Tmux Customization

Tmux plugins are Nix-managed in `modules/home-manager/programs/tmux.nix` — there is no
TPM and no `Prefix + I` install step. Add plugins and keybindings inside the
`extraConfig` block of that module:

```nix
# modules/home-manager/programs/tmux.nix (extraConfig)
bind-key C-f display-popup -E "nvim ~/notes.md"
```

Apply with `home-manager switch --flake .`, then reload the running server with
`Prefix + r`. See `docs/KEYBINDINGS_TMUX.md`.

## Zsh Customization

Add aliases/functions/PATH to `~/.zshrc.local` (machine-specific) or `zsh/.zshrc`
(shared across machines):

```bash
alias gs="git status"
alias dotfiles="cd ~/Projects/dev-config"

mkcd() { mkdir -p "$1" && cd "$1"; }

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
```

## Powerlevel10k Theme

```bash
p10k configure
```

Interactive wizard; output saved to `~/.p10k.zsh` (managed by Home Manager via the
zsh module).

## Git Integration (GitHub CLI)

`gh` is provided by Home Manager (`pkgs/default.nix` core). Authenticate once:

```bash
gh auth login
```

Then use the git plugin keybindings in Neovim (see `docs/KEYBINDINGS_NEOVIM.md`).

## Platform Detection

`zsh/.zprofile` detects the OS for Homebrew shellenv (Apple Silicon, Intel, Linuxbrew)
with no hardcoded paths, so the same config works across machines.

## Mac Orca remote access

The personal Mac profile installs `orca-serve-sync` as a launchd user agent. Desktop
Orca chooses a WebSocket port on each launch and records it in
`~/Library/Application Support/Orca/mobile-ws-fallback-port.json`; the agent checks
that the same port belongs to the live desktop runtime, then keeps Tailscale Serve's
tailnet-only TCP `:6768` forward aimed at it. It does not start another Orca runtime,
change the separate `:443` Funnel, or bypass Orca pairing.

Check `launchctl print user/$(id -u)/org.nix-community.home.orca-serve-sync`,
`tailscale serve status --json`, and `orca status --json`. A Home Manager switch
installs the agent; restarting only this agent with
`launchctl kickstart -k user/$(id -u)/org.nix-community.home.orca-serve-sync`
does not restart desktop Orca or Tailscale. To roll back a bad update, boot out
only this agent and restore the prior TCP route with
`tailscale serve --bg --tcp=6768 --yes tcp://127.0.0.1:6768`; revert the
Home Manager change before the next login.
