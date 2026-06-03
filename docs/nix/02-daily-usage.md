# Daily Usage and Common Workflows

Day-to-day operations with the Nix + Home Manager dev-config environment.

## Environment Activation

`direnv` auto-activates the dev shell when you `cd` into the repo. At shell startup, AI credentials are fetched from 1Password via `~/.config/sops-nix/load-env.sh` (fields: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_AI_STUDIO_KEY`, `LITELLM_KEY`, `OPENROUTER_API_KEY`).

```bash
cd ~/Projects/dev-config   # direnv loads the dev shell
direnv allow               # first time only, to approve .envrc

# manual fallback if direnv is not set up:
nix develop
```

Verify:

```bash
which nvim                 # /nix/store/.../bin/nvim
echo $ANTHROPIC_API_KEY    # populated from 1Password
```

If credentials are missing, sign in: `op signin`.

## Core Commands

```bash
# Apply / test configuration
home-manager switch --flake .              # apply
home-manager build --flake .               # build without applying
home-manager switch --flake . --dry-run    # preview changes

# Update dependencies
nix flake update                           # update flake.lock
git diff flake.lock                        # review
nix flake check                            # validate

# Rollback
home-manager generations                   # list past generations
git checkout <commit> flake.lock           # revert package versions
```

## Adding or Removing a Package

Packages live in `pkgs/default.nix` only (single source of truth), grouped by category (`core`, `runtimes`, `utilities`, `linting`).

```nix
# pkgs/default.nix — add to the relevant category
utilities = [
  pkgs.jq
  pkgs.yq-go
  pkgs.postgresql   # new
];
```

```bash
nix flake check                # validate syntax
home-manager switch --flake .  # apply
which psql                     # verify
git add pkgs/default.nix && git commit -m "feat: add postgresql"
```

To remove, delete the line and re-run `home-manager switch --flake .`.

## Editing Config Files

Dotfiles (`nvim/`, `tmux/tmux.conf`, etc.) are symlinked — no rebuild needed. Edit, then reload the app:

```bash
nvim nvim/lua/config/keymaps.lua   # edit
# restart nvim to pick up changes

tmux source-file ~/.config/tmux/tmux.conf   # reload tmux
source ~/.zshrc                              # reload zsh
```

Only `.nix` changes require `home-manager switch --flake .`.

## Syncing to Another Machine

```bash
git pull origin main
home-manager switch --flake .   # rebuilds only if .nix / flake.lock changed
```

## AI / Claude Code via LiteLLM

Credentials and `ANTHROPIC_BASE_URL=https://litellm.infra.samuelho.space` load automatically via direnv + 1Password.

```bash
claude                                          # default model
claude --model claude-3-5-haiku-20241022        # alternate routed model
```

The LiteLLM dashboard controls which providers/models are available. See [07-litellm-proxy-setup.md](07-litellm-proxy-setup.md).

## direnv

```bash
direnv allow     # approve .envrc (first time / after edits)
direnv reload    # re-evaluate
direnv status    # check state
```

The zsh hook (`eval "$(direnv hook zsh)"`) is installed by Home Manager. Each shell activates independently — variables loaded in one terminal are not global.

## Maintenance

```bash
# Search for a package name
nix search nixpkgs postgresql        # or https://search.nixos.org/packages

# Temporary, throwaway tool (don't add to pkgs/default.nix)
nix shell nixpkgs#htop

# Garbage-collect old generations (frees /nix/store; removes rollback points)
nix-collect-garbage --delete-older-than 30d
nix-store --optimise                 # deduplicate

# Neovim health check
nvim +checkhealth +qall
```

## Next Steps

- **Troubleshooting:** [Common Issues](03-troubleshooting.md)
- **Testing changes:** [Testing](04-testing.md)
- **Advanced Customization:** [Advanced Guide](06-advanced.md)
- **Concepts:** [Understanding dev-config](01-concepts.md)
