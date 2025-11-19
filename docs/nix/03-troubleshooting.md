# Troubleshooting Guide

## Overview

This guide covers common issues you might encounter with the Nix-based dev-config environment and their solutions.

## Installation Issues

### "nix: command not found" After Installation

**Symptom:**
```bash
$ nix --version
zsh: command not found: nix
```

**Cause:** Shell hasn't sourced Nix environment yet.

**Solution:**
```bash
# Restart terminal, or manually source Nix:
source ~/.nix-profile/etc/profile.d/nix.sh

# For fish shell:
source ~/.nix-profile/etc/profile.d/nix.fish

# For zsh (should be automatic):
cat ~/.zprofile | grep nix
# Should show Nix setup lines
```

**Permanent fix for zsh:**
Add to `~/.zprofile` if missing:
```bash
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
  source ~/.nix-profile/etc/profile.d/nix.sh
fi
```

### "experimental features" Error

**Symptom:**
```bash
error: experimental Nix feature 'nix-command' is disabled
```

**Cause:** Flakes not enabled in Nix configuration.

**Solution:**
```bash
# Create config directory
mkdir -p ~/.config/nix

# Enable flakes
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Verify
cat ~/.config/nix/nix.conf
# Should show: experimental-features = nix-command flakes
```

### Installation Script Fails on macOS

**Symptom:**
```bash
error: Nix is not supported on this system
```

**Cause:** macOS version too old or architecture mismatch.

**Requirements:**
- macOS 10.15 (Catalina) or later
- x86_64 (Intel) or aarch64 (Apple Silicon)

**Check your system:**
```bash
sw_vers              # macOS version
uname -m             # Architecture (x86_64 or arm64)
```

**Solution:** Upgrade macOS or use a supported machine.

### Permission Denied on /nix

**Symptom:**
```bash
error: cannot create /nix: Permission denied
```

**Cause:** Installer doesn't have permission to create `/nix` directory.

**Solution (macOS):**
```bash
# Modern macOS uses synthetic.conf
echo 'nix' | sudo tee -a /etc/synthetic.conf
sudo reboot  # Required for changes to take effect
```

**Solution (Linux):**
```bash
# Create /nix directory manually
sudo mkdir /nix
sudo chown -R $USER:$USER /nix
```

## direnv Issues

### ".envrc is blocked"

**Symptom:**
```bash
cd ~/Projects/dev-config
# direnv: error .envrc is blocked. Run `direnv allow` to approve its content.
```

**Cause:** Security feature - direnv requires explicit approval.

**Solution:**
```bash
direnv allow

# Should see:
# direnv: loading ~/Projects/dev-config/.envrc
# 🔐 Loading AI credentials from 1Password...
```

### Environment Not Auto-Loading

**Symptom:** No direnv message when entering directory.

**Cause 1:** direnv not installed or hook not configured.

**Check installation:**
```bash
which direnv
# Should show: /nix/store/.../bin/direnv

# Check hook in ~/.zshrc
cat ~/.zshrc | grep direnv
# Should show: eval "$(direnv hook zsh)"
```

**Solution:**
```bash
# Add to ~/.zshrc if missing:
eval "$(direnv hook zsh)"

# Reload shell
source ~/.zshrc
```

**Cause 2:** .envrc not allowed yet.

**Solution:**
```bash
cd ~/Projects/dev-config
direnv allow
```

### "use: command not found: flake"

**Symptom:**
```bash
.envrc:1: use: command not found: flake
```

**Cause:** nix-direnv not installed.

**Solution:**
```bash
# Install nix-direnv
nix profile install nixpkgs#nix-direnv

# Configure in ~/.config/direnv/direnvrc
mkdir -p ~/.config/direnv
echo 'source $HOME/.nix-profile/share/nix-direnv/direnvrc' >> ~/.config/direnv/direnvrc

# Reload
direnv reload
```

### Environment Variables Not Persisting

**Symptom:** Variables loaded in one terminal, but not in others.

**Cause:** direnv is per-shell. Each terminal instance needs to activate.

**Expected behavior:**
```bash
# Terminal 1
cd ~/Projects/dev-config
echo $ANTHROPIC_API_KEY  # Shows key

# Terminal 2 (different window)
echo $ANTHROPIC_API_KEY  # Empty (until you cd into dev-config)
cd ~/Projects/dev-config
echo $ANTHROPIC_API_KEY  # Now shows key
```

**Solution:** This is intentional isolation. If you need global environment variables, use `~/.zshrc.local`.

## 1Password Issues

### "op: command not found"

**Symptom:**
```bash
$ op account get
zsh: command not found: op
```

**Cause:** Not in Nix environment or 1Password CLI not installed.

**Solution:**
```bash
# Verify Nix environment is active
cd ~/Projects/dev-config
nix develop

# Check if op is available
which op
# Should show: /nix/store/.../bin/op

# If not found, check flake.nix includes _1password:
grep "_1password" flake.nix
```

### "Session expired"

**Symptom:**
```bash
$ op read "op://Dev/ai/ANTHROPIC_API_KEY"
[ERROR] 2025-01-18 10:30:00 Session expired. Please sign in.
```

**Cause:** 1Password CLI session timed out.

**Solution:**
```bash
# Re-authenticate
op signin

# Optionally enable biometric unlock for automatic re-auth:
op signin --account your-account.1password.com
# Follow prompts to enable Touch ID / Windows Hello
```

**Configure longer session timeout:**
Add to `~/.op/config`:
```json
{
  "session_timeout": 30  # Minutes (default: 10)
}
```

### "Item not found: ai"

**Symptom:**
```bash
$ op read "op://Dev/ai/ANTHROPIC_API_KEY"
[ERROR] item "ai" not found in vault "Dev"
```

**Cause:** Item doesn't exist or vault name is wrong.

**Solution:**
```bash
# List all vaults
op vault list

# List items in Dev vault
op item list --vault "Dev"

# Create ai item if missing (see setup guide)
# Or check if item has different name:
op item get "ai-credentials" --vault "Dev"  # Try variations
```

### "Field not found: ANTHROPIC_API_KEY"

**Symptom:**
```bash
$ op read "op://Dev/ai/ANTHROPIC_API_KEY"
[ERROR] field "ANTHROPIC_API_KEY" not found
```

**Cause:** Field name mismatch (case-sensitive).

**Solution:**
```bash
# View all fields in item
op item get "ai" --vault "Dev" --format json | jq '.fields[].label'

# Common mistakes:
# ❌ "anthropic_api_key" (lowercase)
# ❌ "Anthropic API Key" (spaces)
# ✅ "ANTHROPIC_API_KEY" (exact match required)
```

**Fix field label in 1Password:**
1. Open 1Password desktop app
2. Find "Dev" vault → "ai" item
3. Edit field label to exact name: `ANTHROPIC_API_KEY`
4. Save

### Credentials Not Loading Automatically

**Symptom:** No "Loading AI credentials" message when entering directory.

**Check 1:** Is 1Password CLI authenticated?
```bash
op account get
# Should show account details, not error
```

**Check 2:** Is script sourced in .envrc?
```bash
cat .envrc
# Should show:
# if command -v op &>/dev/null && op account get &>/dev/null 2>&1; then
#   source_env scripts/load-ai-credentials.sh
# fi
```

**Check 3:** Is load-ai-credentials.sh executable?
```bash
ls -la scripts/load-ai-credentials.sh
# Should show: -rwxr-xr-x (executable)

# If not:
chmod +x scripts/load-ai-credentials.sh
```

**Check 4:** Silent failure?
```bash
# Run script manually with debug output
bash -x scripts/load-ai-credentials.sh
```

## Nix Build Issues

### "error: hash mismatch"

**Symptom:**
```bash
error: hash mismatch in fixed-output derivation
  specified: sha256-abc123...
  got:       sha256-def456...
```

**Cause:** Package source changed but hash wasn't updated.

**Solution:**
```bash
# Update flake inputs
nix flake update

# Or rebuild with new hash
nix build --impure  # Ignores hash mismatch (not recommended)

# Better: Update hash in flake.lock
nix flake lock --update-input nixpkgs
```

### "error: infinite recursion"

**Symptom:**
```bash
error: infinite recursion encountered
```

**Cause:** Circular dependency in Nix expression.

**Common mistake:**
```nix
# ❌ WRONG: Circular reference
devShells.default = pkgs.mkShell {
  buildInputs = [ devShells.default ];  # Refers to itself!
};
```

**Solution:** Check for self-references in flake.nix.

### "error: attribute missing"

**Symptom:**
```bash
error: attribute 'nonexistentPackage' missing
```

**Cause:** Package name typo or package doesn't exist in nixpkgs.

**Solution:**
```bash
# Search for correct package name
nix search nixpkgs <partial-name>

# Example:
nix search nixpkgs postgres
# Returns: postgresql, postgresql_15, postgresqlTestHook

# Use correct name in flake.nix:
packages = with pkgs; [
  postgresql  # ✅ Correct
  # postgres  # ❌ Wrong
];
```

### "error: builder failed"

**Symptom:**
```bash
error: builder for '/nix/store/...-package.drv' failed with exit code 1
```

**Cause:** Package compilation failed.

**Debug steps:**
```bash
# View full build log
nix build .#devShells.x86_64-darwin.default --show-trace --print-build-logs

# Check if package is broken on your platform
nix search nixpkgs <package> --json | jq '.[] | select(.broken == true)'

# Try building with fallback
nix build --fallback  # Try different build method
```

**Common fix:** Update nixpkgs to latest:
```bash
nix flake update
```

### Out of Disk Space

**Symptom:**
```bash
error: cannot create directory '/nix/store/...': No space left on device
```

**Check Nix store size:**
```bash
du -sh /nix/store
# Example output: 15G
```

**Solution:**
```bash
# Remove old generations (safe)
nix-collect-garbage --delete-older-than 30d

# Aggressive cleanup (removes rollback ability)
nix-collect-garbage -d

# Optimize store (deduplicate)
nix-store --optimise
```

## OpenCode Issues

### "opencode: command not found"

**Symptom:**
```bash
$ opencode --version
zsh: command not found: opencode
```

**Cause:** Not in Nix environment.

**Solution:**
```bash
cd ~/Projects/dev-config
nix develop
which opencode  # Should show /nix/store/.../bin/opencode
```

### "Authentication failed"

**Symptom:**
```bash
$ opencode ask "test"
[ERROR] Authentication failed: Invalid API key
```

**Cause:** ANTHROPIC_API_KEY not loaded or invalid.

**Check 1:** Is variable set?
```bash
echo $ANTHROPIC_API_KEY
# Should show: sk-ant-...

# If empty:
source scripts/load-ai-credentials.sh
```

**Check 2:** Is key valid?
```bash
# Test key manually
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'

# Should return JSON response, not error
```

**Check 3:** Is key in 1Password correct?
```bash
op read "op://Dev/ai/ANTHROPIC_API_KEY"
# Should show valid key starting with sk-ant-
```

### "Rate limit exceeded"

**Symptom:**
```bash
[ERROR] Rate limit exceeded. Please try again later.
```

**Cause:** Too many API requests.

**Solution:**
```bash
# Wait a few minutes
sleep 60

# Or use different provider temporarily:
opencode ask --provider openai "..."
```

**Long-term fix:** Use separate API keys for dev/prod in different 1Password items.

## Package Conflicts

### "error: collision between files"

**Symptom:**
```bash
error: collision between `/nix/store/.../bin/python` and `/nix/store/.../bin/python`
```

**Cause:** Multiple packages providing the same binary.

**Common scenario:**
```nix
packages = with pkgs; [
  python3      # Provides /bin/python
  python39     # Also provides /bin/python - CONFLICT!
];
```

**Solution:** Choose one version:
```nix
packages = with pkgs; [
  python3      # Use default Python 3
  # python39   # Remove conflicting version
];
```

### "package X depends on Y, which is marked as broken"

**Symptom:**
```bash
error: package 'foo' depends on broken package 'bar'
```

**Cause:** Dependency is marked broken on your platform.

**Solution 1:** Allow broken packages (not recommended):
```nix
# In flake.nix
nixpkgs.config.allowBroken = true;
```

**Solution 2:** Use older nixpkgs version:
```bash
# Pin to specific nixpkgs commit
nix flake lock --override-input nixpkgs github:nixos/nixpkgs/<commit-hash>
```

**Solution 3:** Remove package from flake.nix.

## Environment Issues

### Variables Not Available in Child Processes

**Symptom:**
```bash
echo $ANTHROPIC_API_KEY  # Shows key
bash -c 'echo $ANTHROPIC_API_KEY'  # Empty!
```

**Cause:** Variable not exported.

**Solution:**
Check `scripts/load-ai-credentials.sh` uses `export`:
```bash
# ❌ Wrong:
ANTHROPIC_API_KEY=$(op read "...")

# ✅ Correct:
ANTHROPIC_API_KEY=$(op read "...")
export ANTHROPIC_API_KEY  # Makes available to child processes
```

### Different Package Versions in Different Terminals

**Symptom:**
```bash
# Terminal 1
nvim --version  # v0.9.5

# Terminal 2
nvim --version  # v0.10.0
```

**Cause:** Different Nix environments or profile generations.

**Check current generation:**
```bash
nix profile history
```

**Solution:** Use same generation:
```bash
nix develop  # Uses current flake.lock
```

### "command not found" After flake.lock Update

**Symptom:**
After `nix flake update`, previously available command not found.

**Cause:** Package removed from nixpkgs or renamed.

**Solution:**
```bash
# Check package still exists
nix search nixpkgs <package-name>

# If renamed, update flake.nix:
packages = with pkgs; [
  newPackageName  # Updated name
  # oldPackageName  # No longer exists
];
```

## Performance Issues

### Slow First Build

**Symptom:** `nix develop` takes 10+ minutes on first run.

**Expected behavior:** This is normal! Nix is:
1. Downloading packages from cache
2. Building packages not in cache
3. Verifying signatures

**Subsequent builds:** 10-30 seconds (uses cache).

**Speed up first build:**
```bash
# Use Cachix binary cache (already configured)
nix develop --accept-flake-config

# Increase parallel builds
echo "max-jobs = auto" >> ~/.config/nix/nix.conf
```

### Slow Flake Evaluation

**Symptom:** `nix flake check` takes minutes.

**Cause:** Complex flake expressions.

**Solution:**
```bash
# Use evaluation cache (experimental)
nix flake check --eval-cache
```

### Cachix Not Working

**Symptom:** Always building from source, never using cache.

**Check 1:** Is Cachix configured?
```bash
nix show-config | grep substituters
# Should include: https://dev-config.cachix.org
```

**Check 2:** Is public key correct?
```bash
cat flake.nix | grep publicKeys
# Verify matches your Cachix cache
```

**Check 3:** Network issues?
```bash
curl -I https://dev-config.cachix.org
# Should return 200 OK
```

## Common Error Messages

### "error: path '...' is not valid"

**Solution:**
```bash
# Repair Nix store
nix-store --verify --check-contents --repair
```

### "error: getting status of '...': No such file or directory"

**Solution:** File referenced in flake.nix doesn't exist.
```bash
# Check for typos in paths
nix flake show  # Shows all outputs
```

### "error: access to URI '...' is forbidden"

**Solution:** Enable flakes if not done:
```bash
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "warning: Git tree '...' is dirty"

**Explanation:** Uncommitted changes in repo. This is a warning, not an error.

**Ignore or commit:**
```bash
git add .
git commit -m "WIP: testing changes"
```

### "error: cannot coerce null to a string"

**Cause:** Null value where string expected in Nix expression.

**Solution:** Check for null values in flake.nix, add default:
```nix
# ❌ Wrong:
name = someValue;

# ✅ Better:
name = someValue or "default-value";
```

## Debugging Tools

### Check Nix Installation

```bash
# Nix version
nix --version

# Nix configuration
nix show-config

# Nix store health
nix-store --verify
```

### Check direnv Status

```bash
# direnv version
direnv version

# Current status
direnv status

# Show loaded RC
direnv show_dump
```

### Check 1Password CLI

```bash
# 1Password CLI version
op --version

# Account status
op account get

# List vaults
op vault list

# Test credential retrieval
op read "op://Dev/ai/ANTHROPIC_API_KEY"
```

### Check Development Environment

```bash
# Run validation script
bash scripts/validate.sh

# Check Nix environment
nix develop --command env | grep -E "(PATH|ANTHROPIC|OPENAI)"

# Check package availability
nix develop --command which nvim tmux op opencode
```

### Verbose Logging

```bash
# Nix build with full logs
nix build --print-build-logs --show-trace

# direnv debug
direnv exec . env  # Show all environment variables

# 1Password CLI debug
op read "op://Dev/ai/ANTHROPIC_API_KEY" --debug
```

## Getting Help

### Check Documentation

- [Quick Start](00-quickstart.md) - Installation basics
- [Concepts](01-concepts.md) - Understanding Nix
- [Daily Usage](02-daily-usage.md) - Common workflows
- [Advanced Guide](06-advanced.md) - Customization

### Community Resources

**Nix:**
- Official Manual: https://nixos.org/manual/nix/stable/
- Discourse: https://discourse.nixos.org/
- Wiki: https://nixos.wiki/

**OpenCode:**
- Documentation: https://opencode.ai/docs/
- GitHub: https://github.com/opencodeai/opencode

**1Password CLI:**
- Documentation: https://developer.1password.com/docs/cli/
- Support: https://support.1password.com/

### Internal Resources

```bash
# Nix help
nix --help
nix develop --help
nix flake --help

# OpenCode help
opencode --help

# 1Password CLI help
op --help
op read --help
```

### Reporting Issues

If you encounter a bug:

1. **Gather information:**
```bash
# System info
uname -a
nix --version
op --version
opencode --version

# Error logs
nix build .#devShells.x86_64-darwin.default --show-trace &> nix-error.log
```

2. **Create issue:**
- Repository: https://github.com/samuelho-dev/dev-config/issues
- Include: OS, Nix version, error message, steps to reproduce

3. **Emergency rollback:**
```bash
# Rollback to last working state
nix profile rollback

# Or restore from git
git checkout HEAD~1 flake.lock
nix develop
```

## Quick Diagnostic Checklist

When something doesn't work, run through this checklist:

- [ ] Am I in the dev-config directory? (`pwd`)
- [ ] Is direnv allowed? (`direnv status`)
- [ ] Is Nix environment active? (`echo $IN_NIX_SHELL` should show "impure")
- [ ] Is 1Password authenticated? (`op account get`)
- [ ] Are credentials loaded? (`echo $ANTHROPIC_API_KEY`)
- [ ] Is flake.lock valid? (`nix flake check`)
- [ ] Is Nix store healthy? (`nix-store --verify`)
- [ ] Did I try turning it off and on again? (Restart terminal)

If all checks pass and issue persists, see [Getting Help](#getting-help).
