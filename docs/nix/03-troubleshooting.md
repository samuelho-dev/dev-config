# Troubleshooting Guide

Common issues with the Nix + Home Manager dev-config environment. Topics covered canonically elsewhere are linked, not duplicated:

- **1Password / op CLI / credentials** → [09-1password-ssh.md](09-1password-ssh.md)
- **direnv activation** → [02-daily-usage.md](02-daily-usage.md#direnv)
- **Nix evaluation / build errors** → [01-concepts.md](01-concepts.md#common-build-errors)

## Installation

### `nix: command not found` after install

Shell hasn't sourced the Nix profile. Restart the terminal, or:

```bash
source ~/.nix-profile/etc/profile.d/nix.sh   # bash/zsh
source ~/.nix-profile/etc/profile.d/nix.fish # fish
```

The Determinate Nix installer wires `~/.zprofile` automatically; if missing, add the `source` line there.

### `experimental Nix feature 'nix-command' is disabled`

Flakes not enabled:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Permission denied on `/nix` (macOS)

```bash
echo 'nix' | sudo tee -a /etc/synthetic.conf
sudo reboot
```

## Nix Store

### Out of disk space

```bash
error: cannot create directory '/nix/store/...': No space left on device
```

```bash
nix-collect-garbage --delete-older-than 30d   # safe
nix-collect-garbage -d                        # aggressive (drops rollback points)
nix-store --optimise                          # deduplicate
```

### `error: path '...' is not valid`

```bash
nix-store --verify --check-contents --repair
```

### `collision between files`

Two packages provide the same binary (e.g. two Python versions). Keep only one in `pkgs/default.nix`.

### `package X depends on broken package Y`

The dependency is marked broken on your platform. Either remove the package, or pin an older nixpkgs:

```bash
nix flake lock --override-input nixpkgs github:nixos/nixpkgs/<commit>
```

## Environment

### Variable set but missing in child processes

```bash
echo $ANTHROPIC_API_KEY        # set
bash -c 'echo $ANTHROPIC_API_KEY'  # empty
```

The variable isn't exported. Credential loading is handled by `~/.config/sops-nix/load-env.sh`, which uses `export`. If you wrote a custom loader, ensure it exports.

### `command not found` after `nix flake update`

A package was renamed or dropped from nixpkgs. Find the new name and update `pkgs/default.nix`:

```bash
nix search nixpkgs <name>
```

### `Git tree is dirty` warning

Not an error — you have uncommitted changes. Commit or ignore.

## Claude Code / LiteLLM

### `claude: command not found`

Not in the Nix environment:

```bash
cd ~/Projects/dev-config
nix develop
which claude
```

### `[401] Authentication Error`

Missing/invalid LiteLLM key.

```bash
env | grep LITELLM
curl -s https://litellm.infra.samuelho.space/health \
  -H "x-litellm-api-key: Bearer $LITELLM_KEY"
```

If empty, re-run `home-manager switch --flake .` and `op signin`. Full setup in [07-litellm-proxy-setup.md](07-litellm-proxy-setup.md).

### `[404] Model not found`

Model is disabled in the LiteLLM dashboard. Enable it there, or use a known model:

```bash
claude --model claude-3-5-sonnet-20241022
```

### `Rate limit exceeded`

Virtual-key budget exceeded. Raise the budget / reset period in the LiteLLM UI.

## Performance

### Slow first build

Normal — Nix downloads and builds packages on first run, then caches them. Subsequent `nix develop` / `home-manager build` runs are fast. Increase parallelism:

```bash
echo "max-jobs = auto" >> ~/.config/nix/nix.conf
```

## Debugging Tools

```bash
nix --version            # Nix version
nix show-config          # effective config
nix-store --verify       # store health
home-manager build --flake . --show-trace   # full build trace
direnv status            # direnv state
op account get           # 1Password auth (see 09-1password-ssh.md)
```

## Emergency Rollback

```bash
home-manager generations            # find a working generation
git checkout HEAD~1 flake.lock       # revert package versions
home-manager switch --flake .
```

## Getting Help

- Nix manual: https://nixos.org/manual/nix/stable/ · Discourse: https://discourse.nixos.org/
- LiteLLM: https://docs.litellm.ai/ · Claude Code: https://docs.anthropic.com/en/docs/claude-code
- 1Password CLI: https://developer.1password.com/docs/cli/
- Repo issues: https://github.com/samuelho-dev/dev-config/issues

## Quick Diagnostic Checklist

- [ ] In the dev-config directory? (`pwd`)
- [ ] direnv allowed? (`direnv status`)
- [ ] Nix shell active? (`echo $IN_NIX_SHELL`)
- [ ] 1Password authenticated? (`op account get`)
- [ ] Credentials loaded? (`echo $ANTHROPIC_API_KEY`)
- [ ] Flake valid? (`nix flake check`)
- [ ] Store healthy? (`nix-store --verify`)
- [ ] Tried restarting the terminal?
