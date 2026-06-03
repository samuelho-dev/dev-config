# Installation Guide

dev-config is bootstrapped with **Nix + Home Manager**. There is no symlink/backup
installer and no per-tool dependency install — Home Manager declaratively provisions
every package and dotfile from `flake.nix`.

## Prerequisites

- **Nix** — installed automatically by `scripts/install.sh` via the
  [Determinate Systems installer](https://determinate.systems/nix-installer).
  Nothing else is required up front (no Homebrew, Neovim, tmux, Node, etc. — Home
  Manager installs them).

## Install

```bash
# 1. Clone
git clone https://github.com/samuelho-dev/dev-config ~/Projects/dev-config
cd ~/Projects/dev-config

# 2. Create machine-specific config (gitignored, but must be staged for flake eval)
cp user.nix.example user.nix
$EDITOR user.nix          # set username + homeDirectory
git add -f user.nix

# 3. Bootstrap (installs Nix if missing, enables flakes, runs home-manager switch)
bash scripts/install.sh
```

`scripts/install.sh` is idempotent and runs `home-manager switch --flake .` for you.
On subsequent changes you can re-apply directly:

```bash
home-manager switch --flake .
```

First run takes ~10-15 minutes (Home Manager builds/downloads everything); later runs
are 1-2 minutes.

## Verify

```bash
exec zsh                  # pick up the new shell config
nvim --version            # provided by Home Manager
tmux -V
home-manager generations  # shows the active generation
```

Open Neovim and tmux — plugins, LSP servers, and formatters are already present (all
Nix-managed; no Mason bootstrap, no TPM).

## Additional Machines

Repeat the same three steps. Because everything is declared in the flake, every
machine converges to an identical environment. Create a fresh `user.nix` per machine
(username/homeDirectory differ).

## 1Password SSH & Commit Signing

SSH authentication and Git commit signing use the 1Password SSH agent (keys live in
your 1Password vault, never on disk; commits signed via `op-ssh-sign`). Git identity
and signing key are set declaratively in `home.nix` — there is no `secrets.nix`.

See **[docs/nix/09-1password-ssh.md](nix/09-1password-ssh.md)** for the full setup
(enable agent, add key to GitHub, verify auth/signing, `op` CLI).

## Platform Notes

| Platform | Notes |
|----------|-------|
| **macOS** | Ghostty config: `~/Library/Application Support/com.mitchellh.ghostty/config` |
| **Linux** | Ghostty config: `~/.config/ghostty/config` |
| **WSL** | Treat as Linux; not officially tested |

## Containers / DevPod

`scripts/install.sh` detects container environments (`/.dockerenv` or cgroup) and
fixes ownership when running as root. No separate Docker setup is required for the
config itself. Tmux DevPod helpers live in `tmux/scripts/` — see `tmux/CLAUDE.md`.

## Troubleshooting

See **[docs/nix/03-troubleshooting.md](nix/03-troubleshooting.md)**. Quick checks:

```bash
nix flake check                          # validate the flake
home-manager switch --flake . --show-trace   # detailed activation errors
```
