# Installation Guide

dev-config bootstraps **Nix + Home Manager** for system tools and dotfiles.
The selected profile also installs only missing enabled writable native OMP,
Pi, Claude, OpenCode, Codex and Vercel CLIs through `ai/bootstrap.sh`; these
native binaries are not compiled into the Nix store. `pkgs/tool-checks.json`
lists shared Darwin/Linux command checks. Mac-only extras in `pkgs/Brewfile`
are opt-in; held third-party sources are not installed without a trust decision.

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

# 3. Bootstrap Nix and activate the selected Home Manager profile
bash scripts/install.sh
```

`scripts/install.sh` uses the Home Manager app from this flake's locked input
(`nix run .#home-manager -- switch --flake .`) rather than a separately installed
Home Manager. An activation selects native tools in
`~/.config/dev-config/native-tools` and installs missing ones, but does not
upgrade working CLIs or enroll provider OAuth. After a reviewed configuration
change, re-apply deliberately:

```bash
nix run .#home-manager -- switch --flake .
```

First run takes ~10-15 minutes (Home Manager builds/downloads everything); later runs
are 1-2 minutes.

## Verify without activation

From a clean Git-backed checkout, evaluate and build the selected Home Manager
derivation without switching or running activation hooks:

```bash
nix eval --raw .#homeConfigurations.$(whoami).activationPackage.drvPath
nix build --no-link .#homeConfigurations.$(whoami).activationPackage
```

For an untracked source checkout use `path:.` only after reviewing what that
filesystem path contains; a plain Git-backed `.` excludes untracked files.
On an activated machine, `bash ai/bootstrap.sh check` checks enabled native
executables, not OAuth, MCP credentials or project authorization. Enroll
services separately and check their intended identities/targets before
claiming access. `flake.lock` pins Nix source revisions, not native CLI/MCP
package versions; explicit `bash ai/bootstrap.sh update` upgrades native CLIs.

Open Neovim and tmux — Nix supplies editor tools through Neovim's wrapper and
tmux plugins through Home Manager; Lazy.nvim installs Neovim plugins on first
launch. No Mason bootstrap or TPM is needed.

## Additional Machines

The Nix package set follows the locked flake inputs. Native tools are
installed only when missing and may have different locally installed versions;
create a fresh `user.nix` for each machine (username/homeDirectory differ).
An existing `helm@3` is preserved, not a desired-state version pin for new
machines.

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
config itself. Tmux DevPod helpers live in `tmux/scripts/`; see `tmux/README.md`.

## Troubleshooting

See **[docs/nix/03-troubleshooting.md](nix/03-troubleshooting.md)**. Quick checks:

```bash
nix eval --raw .#homeConfigurations.$(whoami).activationPackage.drvPath  # no activation
nix run .#home-manager -- switch --flake . --show-trace  # intentional activation only
```
