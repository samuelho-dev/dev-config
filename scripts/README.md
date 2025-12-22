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
bash scripts/apply-home-manager.sh
# Or directly:
home-manager switch --flake .
```

## Available Scripts

| Script | Purpose | Duration |
|--------|---------|----------|
| `install.sh` | Full bootstrap from scratch | 10-15 min |
| `apply-home-manager.sh` | Apply config changes | 1-2 min |
| `load-ai-credentials.sh` | Load 1Password secrets (legacy) | Instant |

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

**Container support:**
The script detects Docker/DevPod environments and adjusts permissions automatically.

### apply-home-manager.sh

**Convenience wrapper** for applying configuration changes.

**When to use:**
- After editing any `.nix` file
- After pulling updates from Git
- After modifying dotfiles (nvim, tmux, zsh)

**Usage:**
```bash
bash scripts/apply-home-manager.sh
```

**Equivalent to:**
```bash
home-manager switch --flake ~/Projects/dev-config
```

### load-ai-credentials.sh

**Legacy script** for loading AI API keys from 1Password CLI.

**Status:** Superseded by `sops-env` service module.

**Modern alternative:**
```bash
# Credentials loaded automatically via sops-nix
# No script needed - happens at Home Manager activation
```

**If you still need it:**
```bash
source scripts/load-ai-credentials.sh
```

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
bash scripts/apply-home-manager.sh

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

## Troubleshooting

### Nix installation fails

**Symptoms:** curl errors or installer failures

**Fixes:**
1. Check internet connection
2. Try manual install: https://determinate.systems/nix-installer
3. Clear previous Nix installation:
   ```bash
   sudo rm -rf /nix
   ```

### Home Manager switch fails

**Symptoms:** Error during `home-manager switch`

**Fixes:**
1. Check flake syntax:
   ```bash
   nix flake check
   ```

2. View detailed errors:
   ```bash
   home-manager switch --flake . --show-trace
   ```

3. Clear Nix cache:
   ```bash
   nix-collect-garbage
   ```

### Permission errors in containers

**Symptoms:** Permission denied in DevPod/Docker

**Fixes:**
The script auto-fixes this, but if issues persist:
```bash
sudo chown -R $(whoami) ~/.config ~/.local
```

### Script not found

**Symptoms:** `bash: scripts/install.sh: No such file or directory`

**Fix:** Ensure you're in the repository root:
```bash
cd ~/Projects/dev-config
ls scripts/  # Should show install.sh
```

## File Structure

```
scripts/
+-- install.sh              # Bootstrap Nix + Home Manager
+-- apply-home-manager.sh   # Apply configuration changes
+-- load-ai-credentials.sh  # Load 1Password secrets (legacy)
+-- CLAUDE.md               # Architecture documentation
+-- README.md               # This file
```

## Best Practices

1. **Always use `nix flake check`** before applying changes
2. **Pull updates regularly** to stay current
3. **Commit changes** before running `home-manager switch`
4. **Use `--show-trace`** when debugging failures
5. **Prefer Nix/Home Manager** over shell scripts for configuration

## Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Architecture details
- [Installation Guide](../docs/INSTALLATION.md) - Comprehensive setup
- [Troubleshooting](../docs/nix/03-troubleshooting.md) - Common issues
- [Home Manager Guide](../docs/nix/08-home-manager.md) - Deep dive
