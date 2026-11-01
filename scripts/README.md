# Scripts

Installation and utility scripts for dev-config.

## Quick Start

### First-Time Setup

```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

This uses the flake-selected Home Manager app to provision Nix packages and
dotfiles and install missing enabled native CLIs. It does not upgrade existing
native CLIs, authenticate providers or install Mac-only `pkgs/Brewfile` extras.

### Apply Configuration Changes

After editing Nix files:

```bash
nix run .#home-manager -- switch --flake .
```

## Available Scripts

| Script | Purpose | Duration |
|--------|---------|----------|
| `install.sh` | Bootstrap Nix and activate selected Home Manager profile | First run varies |
| `ai/bootstrap.sh` | Install missing, explicitly update, or check native CLIs | Varies |
| `validate-linting-config.sh` | Pre-commit linting guard | Automatic |

## Script Details

### install.sh

**Primary bootstrap script** for new machines or fresh installs.

**What it does:**
1. Installs Nix via the Determinate Systems installer if missing
2. Enables flakes in `~/.config/nix/nix.conf`
3. Invokes the Home Manager app locked by this flake (`nix run .#home-manager -- switch --flake .`)
4. Activation selects missing writable native tools via `ai/bootstrap.sh install`;
   no separate per-agent startup installer upgrades working tools

**Usage:**
```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

**Requirements:**
- `bash` and `curl` (pre-installed on most systems)
- Internet connection
- ~2GB disk space

### ai/bootstrap.sh

The single native tool owner supports `install|update|check` and optional tool
names from `omp pi claude opencode codex vercel rex-worktrees`. Without names
it reads `~/.config/dev-config/native-tools`, written by the selected Home
Manager profile; without that manifest it selects the original six. Stock
macOS Bash is supported. `install` preserves working versions; `update` is
deliberate; `check` proves executables only, not account authorization.
Rex Worktrees downloads the latest published macOS arm64 or Linux x64 archive
and shared `SHA256SUMS`, verifies the selected archive, and keeps its bundle
and license notices under `~/.local/share/dev-config/rex-worktrees`. Only its
owned `~/.local/bin/rex-worktrees` symlink is managed; an unrelated or broken
launcher is not overwritten on install.

```bash
bash ai/bootstrap.sh install
bash ai/bootstrap.sh check
bash ai/bootstrap.sh update
```

System/Nix command checks are enumerated in `pkgs/tool-checks.json`. Nix
sources follow `flake.lock`, while native CLI and MCP stdio package versions
are not locked by it. `pkgs/Brewfile` is an opt-in Mac host extras list, not
an automatically applied toolchain.

### validate-linting-config.sh

Pre-commit hook that prevents weakening of linting rules (e.g. changing `error` to `warn`).
Runs automatically via `.pre-commit-config.yaml` on biome/tsconfig/pre-commit config changes.

## Common Workflows

### New Machine Setup

```bash
# 1. Clone repository
git clone https://github.com/samuelho-dev/dev-config ~/Projects/dev-config
cd ~/Projects/dev-config

# 2. Create user configuration
cp user.nix.example user.nix
# Edit user.nix with your username and home directory

# 3. Run installation
bash scripts/install.sh

# 4. Restart terminal
exec zsh
```

### Update Configuration

```bash
cd ~/Projects/dev-config

# 1. Pull latest changes
git pull

# 2. Apply configuration
nix run .#home-manager -- switch --flake .

# 3. (Optional) Restart affected applications
# - Neovim: :qa and reopen
# - Tmux: prefix + I to reload plugins
```

### Test Configuration Changes

```bash
# Evaluate and build the selected derivation without activation
nix eval --raw .#homeConfigurations.$(whoami).activationPackage.drvPath
nix build --no-link .#homeConfigurations.$(whoami).activationPackage

# Switch only when activation is intended
nix run .#home-manager -- switch --flake .
```

## File Structure

```
scripts/
+-- install.sh                  # Bootstrap Nix + Home Manager
+-- validate-linting-config.sh  # Pre-commit linting guard
+-- CLAUDE.md                   # Architecture documentation
+-- README.md                   # This file
```
