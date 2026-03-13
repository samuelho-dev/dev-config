# Scripts

Installation and utility scripts for dev-config.

## Quick Start

### First-Time Setup

```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

This installs Nix, Home Manager, and applies all configurations.

### Apply Configuration Changes

After editing Nix files:

```bash
home-manager switch --flake .
```

## Available Scripts

| Script | Purpose | Duration |
|--------|---------|----------|
| `install.sh` | Full bootstrap from scratch | 10-15 min |
| `validate-linting-config.sh` | Pre-commit linting guard | Automatic |

## Script Details

### install.sh

**Primary bootstrap script** for new machines or fresh installs.

**What it does:**
1. Installs Nix via Determinate Systems installer
2. Enables flakes in `~/.config/nix/nix.conf`
3. Runs `home-manager switch --flake .`
4. Handles container environments (DevPod, Docker)

**Usage:**
```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

**Requirements:**
- `bash` and `curl` (pre-installed on most systems)
- Internet connection
- ~2GB disk space

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
home-manager switch --flake .

# 3. (Optional) Restart affected applications
# - Neovim: :qa and reopen
# - Tmux: prefix + I to reload plugins
```

### Test Configuration Changes

```bash
# Validate flake syntax
nix flake check

# Build without applying (dry run)
home-manager build --flake .

# Apply if build succeeds
home-manager switch --flake .
```

## File Structure

```
scripts/
+-- install.sh                  # Bootstrap Nix + Home Manager
+-- validate-linting-config.sh  # Pre-commit linting guard
+-- CLAUDE.md                   # Architecture documentation
+-- README.md                   # This file
```
