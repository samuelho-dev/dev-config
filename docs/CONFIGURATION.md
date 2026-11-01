# Configuration Guide

How to customize and extend your dev-config setup. Dotfiles in `nvim/`, `tmux/`,
`zsh/`, `ghostty/`, `yazi/` are version-controlled and symlinked by Home Manager —
edit them directly and reload the app (no rebuild needed). Shared system commands
come from `pkgs/default.nix` and are enumerated for checks in
`pkgs/tool-checks.json`; profile-selected writable native coding CLIs come from
`ai/bootstrap.sh`, not Nix packages. `pkgs/Brewfile` holds opt-in Mac host extras
only. Existing `helm@3` may remain installed but is not the fresh-host Helm pin;
held third-party taps/casks require an explicit source-trust decision.

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
`GOOGLE_AI_API_KEY`, `LITELLM_MASTER_KEY` (admin only), `LITELLM_API_KEY`
(application client), `OPENROUTER_API_KEY`). See the root
`CLAUDE.md` "Secrets Management" section and `docs/nix/07-litellm-proxy-setup.md`.

### Native tools, versions and skills

Enabled Home Manager profile options for OMP, Pi, Claude, OpenCode, Codex and
Vercel generate `~/.config/dev-config/native-tools`. Run from the repo:

```bash
bash ai/bootstrap.sh install  # missing enabled CLIs only
bash ai/bootstrap.sh check    # executable availability; not authentication
bash ai/bootstrap.sh update   # deliberate native CLI upgrades
```

Pass tool names to target only those tools (for example,
`bash ai/bootstrap.sh check vercel`). On a fresh home without a manifest all
six are selected; with a manifest its enabled subset is authoritative. Native
CLIs are writable under `~/.local`, OMP must be a standalone binary, and the
bootstrap supports stock macOS Bash. Home Manager activation installs missing
enabled CLIs and reconciles curated skill links, but does not upgrade existing
CLIs or plugin packages on startup. `ai/sync-skills.sh` fills missing individual
links in physical user skill directories; it never replaces those directories,
edited skills or unmanaged links. It advances only owned links still pointing
to their recorded previous source.

`flake.lock` locks Nix input revisions, not direct native CLI versions or
MCP stdio packages. Explicitly update native CLIs via `ai/bootstrap.sh update`,
plugin sources via their own updater, and system packages via a reviewed
flake/input update; no universal automatic-latest guarantee. Availability from
`check` is not provider sign-in or project authorization.

### Shared jj and OMP workspace guidance

The shared Nix `core` package set includes `jj` on Darwin and Linux; the
current pinned nixpkgs resolves `jj 0.42.0`. This provisions a command, not
a repository conversion, author/signing configuration, or Home Manager
activation. Respect each project's VCS policy.

When `dev-config.omp.enable` is selected, Home Manager links the tracked
`ai/omp/RULES.md` to `~/.omp/agent/RULES.md` for OMP's default user profile.
Standalone and composed imports use the same source. Disabled OMP does not
project this file; custom OMP profile directories must opt in separately.
The rules direct agents to record ownership in existing task/session records,
isolate writers, preserve work before releasing workspaces, and distinguish
completion from release and cleanup. They are instructions, not automatic
workspace cleanup, a new registry, or native jj access control. No Rex or
other agent runtime configuration is changed.

### Rex homelab access (separate identity)

The headless Home Manager output is `homeConfigurations.rex` (`rex-home.nix`);
the runtime selects `#rex` at startup. It retains the existing native tools
and HTTPS Git credential helper without provisioning service credentials.

The shared Nix toolchain includes `supabase`, `psql`, `kubectl`, and `argocd`
on Darwin and Linux. Rex must use its own projected Kubernetes ServiceAccount
token and CA, with an explicit kubeconfig context in namespace `argocd`;
`KUBECONFIG` points at that config. Do not copy an admin kubeconfig or broker
credential into Rex. On the Mac, `argocd-core.sh --tailnet
https://<kubernetes-proxy> app list -o json` creates private throwaway
Kubernetes/Argo configs with a **nonsecret** bearer placeholder solely to
prevent the tailnet proxy's Basic prompt; it does not grant Kubernetes access.
Inside Rex, `argocd-core.sh --in-cluster app list -o json` uses the projected
`tokenFile` and creates only the private Argo core config. Neither mode edits
`~/.argocd/config` or other kube contexts, and neither logs into Argo API mode.

Source validation: the Mac tailnet core helper listed 64 Argo applications,
all Synced. The shared Nix cloud package set evaluated with `supabase-cli` and
`postgresql` on aarch64-darwin and x86_64-linux, without building them.

Canonical MCP definitions in `ai/mcp/servers.json` fan out only to enabled
Claude Code, OMP and Codex CLI profiles. The renderer accepts
`DEV_CONFIG_MCP_AUTH_SOURCE=op|env`: macOS Home Manager defaults to `op`,
Linux Home Manager defaults to `env`, and containers explicitly select `env`.
`env` never queries 1Password, even if `op` is installed. Override the
Home Manager `dev-config.mcp.authSource` option or set the environment variable
for a deliberate alternate source; do not rely on PATH-dependent fallback.
Home Manager prepends declared Python, user-local, profile and selected
1Password executables, then retains native host CLI discovery (including
`/opt/homebrew/bin` on macOS) even when activation resets inherited PATH.
Missing required launchers still fail before any managed config replacement.
The MCP stdio launchers are unversioned; existing working CLIs and auth are
not upgraded at activation. Credential sources are:

| Server | 1Password reference | Rex environment | Required authorization |
|--------|---------------------|-----------------|------------------------|
| Linear | `op://Dev/Linear/MCP_API_KEY` | `LINEAR_API_KEY` | Approved Linear MCP account |
| Vercel community | `op://Dev/Vercel/TOKEN` | `VERCEL_MCP_TOKEN`, rendered as child `VERCEL_TOKEN` | Existing Creativetoolkits MCP account; stdio package, no second official-MCP OAuth grant required |
| Sentry | `op://Dev/creativetoolkits/SENTRY_MCP_TOKEN` | `SENTRY_MCP_KEY` | `Sentry-Bearer` access to the intended project |
| PostHog | `op://Dev/creativetoolkits/POSTHOG_MCP_TOKEN` | `POSTHOG_MCP_KEY` | Bearer access to the intended project; tools mode, **not** globally read-only |

Vercel has **two deliberate identities**: the existing
`Dev/Vercel/TOKEN`/rendered MCP child is the Creativetoolkits integration
(`samuelho-dev`, team `samuelho-dev`); Rex's native Vercel CLI is the owner's
`samuelho` account scoped to team `samuelho`. Enroll that CLI with native
Vercel OAuth in Rex's own persisted private home; it does not consume the
Creativetoolkits MCP token separately as `VERCEL_MCP_TOKEN`; the renderer
injects `VERCEL_TOKEN` only into the MCP child environment, never globally
and never from native Vercel OAuth. No new token or official Vercel MCP OAuth
grant is required, and neither Mac identity is overwritten.
The doctor reads the actual rendered `~/.omp/agent/mcp.json` stdio command,
arguments and child environment rather than assuming its launcher/token.

The renderer fails visibly if a required credential, launcher or enabled CLI
target is missing. It validates all targets before replacing configuration;
failed validation leaves existing working configuration intact. An intentionally
empty server list (`mcpServers: {}`) is valid, and a disabled CLI target is not
written. Managed credential-bearing files are mode 0600; unrelated user
configuration is preserved and resolved secrets are not subprocess arguments.
These references are credential *sources*, not credentials to commit. Supabase
CLI needs a **valid Management API PAT** via its native
`SUPABASE_ACCESS_TOKEN` environment source (or the user's authorized CLI
keychain enrollment on macOS). The existing legacy Mac
`Supabase CLI/access-token` value was rejected by the API; do not reuse it.
Rex currently projects `PGUSER=postgres` against database `supabase` with
the existing owner-operated PostgreSQL profile. A read-only capability probe
confirmed `current_user=session_user=postgres`, with superuser, role/database
creation, replication and BYPASSRLS authority, plus CONNECT and public
schema USAGE/CREATE. This is **elevated owner authority**, not a scoped role
and not a credential to share. `check-rex-access.py` checks current
user/database identity but does not repeat those capability checks.
Keep this distinct from Supabase Management API access; do not infer a
least-privilege guarantee, invent roles/grants, or change credentials here.
Never put the password in a command argument or tracked config.

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
`REX_EXPECTED_POSTHOG_PROJECT_ID`, `REX_EXPECTED_VERCEL_USER`,
`REX_EXPECTED_VERCEL_TEAM` (native owner scope),
`REX_EXPECTED_VERCEL_MCP_TEAM` (configured community MCP integration), and the
PostHog MCP's accepted `REX_POSTHOG_MODEL` identifier (the observed
`project-get` proof used `openai-codex/gpt-6-sol`). It checks actual CLI
identities, an anonymous Kubernetes secret denial via an owner-submitted
SubjectAccessReview for `system:anonymous` in `system:unauthenticated`, MCP
read-only project/team calls, and invalid MCP credentials. The access review
fails closed on API errors or an allowed decision; it does not require the
anonymous identity to create an access review or the owner to impersonate it.
Missing required credentials/targets fail the check. Do not report enrollment
complete from package presence or an MCP
tools list alone; optional profile integrations may remain unconfigured.

Local OMP uses its built-in LiteLLM provider with `LITELLM_API_KEY` from
1Password `Dev/ai/LITELLM_CLIENT_KEY` and static
`LITELLM_BASE_URL=https://litellm.samuelho.space/v1`; this does not change
OMP's `openai-codex/gpt-6.1-sol:high` global default or enroll new OAuth.
After Home Manager activation, open a fresh login shell and restart OMP and
Neovim so their processes inherit the new environment. The installed native
`~/.local/bin/omp` binary reports `omp/18.14.0`; the separate Bun global
`@oh-my-pi/pi-coding-agent@17.1.3` is not the standalone executable.

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

## Tuicr Review Notes

On macOS, `pkgs/Brewfile` is the opt-in, manually applied Homebrew owner of
native `tuicr` installation and updates; `scripts/install.sh` and Home Manager
do not install or configure it. Run `tuicr -w` for working-tree review. Press
`c`, type a note, then Enter to save; use `v` to select a range before `c`.
Press `y` or enter `:clip` to copy the review with file and line/range
references (old-side lines use `~N`), not source excerpts. `:q` exits;
reopening resumes saved reviews. Native defaults include a transparent
background; there is no managed theme, extension or exporter.

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

Restart Neovim; lazy.nvim auto-installs missing plugins. Home Manager runs daily
plugin updates on macOS and Linux; `update-neovim-plugins` runs them manually.
The writable local lock is `$XDG_STATE_HOME/nvim/lazy-lock.json` (normally
`~/.local/state/nvim/lazy-lock.json`), not in Git. Updates are logged to
`$XDG_STATE_HOME/nvim/update-plugins.log`; configured version and branch bounds
still apply. The updater does not activate Home Manager or update Nix tools.
Linux scheduling requires a running user systemd manager; run manually in
headless containers without one.

### Adding an LSP Server

LSP servers and formatters are Nix-managed (declared once in
`modules/home-manager/programs/neovim.nix`) and supplied through Neovim's
wrapper independently of the launching shell's PATH. The same packages remain
available in the shell. To add one: add the package in `neovim.nix`, then
register the server in the `servers` table in `nvim/lua/plugins/lsp.lua`,
and activate the relevant shared flake profile. Standalone users must provide
their own executables.

## Tools: LSP, Formatters, Colorscheme

Tmux plugins and Neovim LSPs/formatters are **not** installed by Mason or TPM at
runtime — Nix provisions the binaries; Lazy.nvim manages Neovim plugins.

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

## Mac Rex configuration

The personal Mac profile manages `~/.config/rex/dev-config.lua`, binding
`ctrl+alt+w` to the `worktrees_open` action supplied by the separately installed
`rex-worktrees` plugin. Home Manager adds a loader to Rex's user-owned
`~/.config/rex/init.lua` only when absent; it does not replace that file or manage
the plugin.

Before activation, inspect the built generation's
`home-files/.config/rex/dev-config.lua` and run
`REX_CONFIG=<generation>/home-files/.config/rex/dev-config.lua rex config check`.
This checks the generated binding; the plugin actions remain owned by the
existing Rex init and need separate live verification after activation.
