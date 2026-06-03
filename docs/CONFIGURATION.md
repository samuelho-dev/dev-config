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
they live in the `Dev` vault and are loaded at shell startup via
`~/.config/sops-nix/load-env.sh` (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`,
`GOOGLE_AI_STUDIO_KEY`, `LITELLM_KEY`, `OPENROUTER_API_KEY`). See the root `CLAUDE.md`
"Secrets Management" section and `docs/nix/07-litellm-proxy-setup.md`.

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
runtime — they are provisioned by Nix. Colorscheme is **kanagawa**.

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
`Prefix + r`. See `tmux/CLAUDE.md` and `docs/KEYBINDINGS_TMUX.md`.

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
