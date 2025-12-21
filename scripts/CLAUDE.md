---
scope: scripts/
updated: 2025-12-21
relates_to:
  - ../CLAUDE.md
  - ../flake.nix
  - ../modules/home-manager/CLAUDE.md
validation:
  max_days_stale: 30
---

# Shell Scripts

Architectural guidance for installation and utility scripts.

## Purpose

This directory contains shell scripts for bootstrapping the dev-config environment, loading credentials, and applying configuration changes. These scripts bridge the gap between manual setup and the declarative Nix/Home Manager system.

## Architecture Overview

Scripts follow a consistent pattern with colored output, error handling, and idempotent operations. The primary entry point is `install.sh` which bootstraps Nix and Home Manager, after which all configuration is managed declaratively.

Key design decisions:
- **Idempotent operations**: Scripts can be run multiple times safely
- **Colored output**: Consistent logging with info/success/warning/error prefixes
- **Container awareness**: Detect and handle Docker/DevPod environments
- **Minimal dependencies**: Only require bash and curl initially

## File Structure

```
scripts/
+-- install.sh              # Bootstrap Nix + Home Manager (main entry point)
+-- apply-home-manager.sh   # Convenience wrapper for home-manager switch
+-- load-ai-credentials.sh  # Load AI keys from 1Password CLI (legacy)
```

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Colored logging | install.sh:6-8 | `log_info`, `log_success`, `log_error` functions |
| Container detection | install.sh:11-13 | Check for /.dockerenv or cgroup containers |
| Idempotent checks | install.sh:21,45 | `command -v nix` before installing |
| Nix environment sourcing | install.sh:26-28 | Source nix-daemon.sh after install |
| Error handling | all files:3 | `set -e` for fail-fast behavior |

## Script Reference

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **install.sh** | Full bootstrap from scratch | First-time setup on new machine |
| **apply-home-manager.sh** | Apply config changes | After editing Nix files |
| **load-ai-credentials.sh** | Load 1Password secrets | Legacy (use sops-env instead) |

### install.sh

**Primary bootstrap script** that:
1. Installs Nix via Determinate Systems installer
2. Enables flakes in `~/.config/nix/nix.conf`
3. Runs `home-manager switch --flake .`
4. Fixes ownership for container environments

**Usage:**
```bash
cd ~/Projects/dev-config
bash scripts/install.sh
```

**Duration:** 10-15 minutes (first run), 1-2 minutes (subsequent)

### apply-home-manager.sh

Convenience wrapper around `home-manager switch`:
```bash
bash scripts/apply-home-manager.sh
```

Equivalent to:
```bash
home-manager switch --flake ~/Projects/dev-config
```

### load-ai-credentials.sh

**Legacy script** for loading AI API keys from 1Password CLI.

**Status:** Superseded by `sops-env` service module which loads secrets at activation time with zero shell startup latency.

**Usage (if needed):**
```bash
source scripts/load-ai-credentials.sh
```

## Adding/Modifying

### Creating a New Script

1. Create script with proper shebang and error handling:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   # Colors for output
   log_info() { echo -e "\033[0;36mℹ️  $1\033[0m"; }
   log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
   log_error() { echo -e "\033[0;31m❌ $1\033[0m"; exit 1; }

   # Script logic here
   ```

2. Make executable: `chmod +x scripts/new-script.sh`

3. Document in this CLAUDE.md

### Modifying Existing Script

1. Maintain idempotent behavior
2. Use existing logging functions
3. Test in both regular and container environments
4. Update this documentation if behavior changes

## Common Issues

### Nix installation fails

**Symptom:** curl command fails or installer errors

**Fixes:**
1. Check internet connection
2. Ensure curl is installed: `which curl`
3. Try manual install: https://determinate.systems/nix-installer

### Home Manager switch fails

**Symptom:** `home-manager switch` errors

**Fixes:**
1. Check flake syntax: `nix flake check`
2. View detailed errors: `home-manager switch --flake . --show-trace`
3. Clear cache: `nix-collect-garbage`

### Container ownership issues

**Symptom:** Permission denied errors in DevPod/Docker

**Fix:** The script auto-fixes ownership when running as root in containers. If issues persist:
```bash
sudo chown -R $(whoami) ~/.config ~/.local
```

## For Future Claude Code Instances

- [ ] Use `set -euo pipefail` for strict error handling
- [ ] Include colored logging functions for consistent output
- [ ] Check for container environments when handling permissions
- [ ] Make operations idempotent (safe to run multiple times)
- [ ] Source Nix environment after installation
- [ ] Prefer Nix/Home Manager over shell scripts for configuration
- [ ] Document any new scripts in this CLAUDE.md
