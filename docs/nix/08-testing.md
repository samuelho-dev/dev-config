# Testing Nix Configuration Changes

**Purpose:** Test Home Manager configuration changes safely before applying them to your system.

**Target Audience:** Users who want to validate configuration changes without risking their development environment.

---

## Why Testing Matters

**The Problem:**
- Running `home-manager switch` immediately applies changes
- Syntax errors can break your environment
- No preview of what will change
- Difficult to validate complex configurations

**The Solution:**
- Three-tier testing approach
- Catch errors before they affect your system
- Preview changes before applying
- Confidence in configuration changes

---

## Three-Tier Testing Strategy

### Overview

```
Tier 1: Syntax Check → Tier 2: Build Test → Tier 3: Dry-Run Preview
    (fastest)              (moderate)            (slowest)
    (no builds)         (uses cache)         (shows changes)
```

### Tier 1: Syntax & Evaluation Check

**Purpose:** Validate Nix syntax and configuration options

**Command:**
```bash
nix-instantiate --eval --strict '.#homeConfigurations'
```

**What it does:**
- Parses all Nix files
- Checks for syntax errors
- Validates option references
- Ensures configuration is well-formed

**What it doesn't do:**
- Build packages
- Download anything
- Access network
- Modify system

**Speed:** Instant (< 1 second)

**Use cases:**
- Quick validation during development
- Pre-commit hook
- CI/CD pipeline checks
- Syntax verification before builds

**Example output (success):**
```
$ nix-instantiate --eval --strict '.#homeConfigurations'
{ ... }  # Configuration evaluated successfully
```

**Example output (failure):**
```
error: undefined variable 'progams'
       at /path/to/file.nix:10:3:
            9|   config = {
           10|     progams.git.enable = true;
              |     ^
           11|   };
```

### Tier 2: Build Test

**Purpose:** Verify configuration builds successfully without activating it

**Command:**
```bash
home-manager build --flake .
```

**What it does:**
- Evaluates configuration (same as Tier 1)
- Downloads packages from binary cache
- Builds configuration derivation
- Creates `./result` symlink

**What it doesn't do:**
- Activate configuration
- Create symlinks in `$HOME`
- Run activation scripts
- Modify system state

**Speed:** Moderate (1-5 minutes first time, < 30 seconds cached)

**Use cases:**
- Verify configuration builds before switching
- Test after major changes
- Validate new package additions
- Check for build failures

**Example:**
```bash
$ home-manager build --flake .
building the system configuration...
these 3 derivations will be built:
  /nix/store/abc123-home-manager-path
  /nix/store/def456-home-manager-generation
  /nix/store/ghi789-home-manager-activation
building '/nix/store/abc123-home-manager-path'...
...
$ ls -l result
lrwxr-xr-x result -> /nix/store/ghi789-home-manager-generation
```

### Tier 3: Dry-Run Preview

**Purpose:** Show what would change if configuration is applied

**Command:**
```bash
home-manager switch --flake . --dry-run --verbose
```

**Alternative (using nh wrapper):**
```bash
nh home switch --dry --verbose
```

**What it does:**
- Everything from Tier 2
- Downloads packages from cache
- Shows diff of changes
- Lists activation scripts that would run
- Displays what symlinks would change

**What it doesn't do:**
- Actually activate configuration
- Create permanent symlinks
- Fully run activation scripts*

***Important limitation:** Some activation scripts may execute during dry-run. This is a known limitation of Home Manager's `--dry-run` flag.

**Speed:** Moderate to slow (2-10 minutes first time, < 1 minute cached)

**Use cases:**
- Preview changes before applying
- Understand impact of configuration changes
- Verify expected changes are correct
- Check for unexpected modifications

**Example output:**
```bash
$ home-manager switch --flake . --dry-run --verbose
Dry-run: the following symlinks will be created:
  /home/user/.config/nvim -> /nix/store/...-nvim
  /home/user/.config/git/config -> /nix/store/...-git-config

The following packages will be installed:
  neovim-0.9.5
  git-2.43.0

Dry-run complete. No changes were applied.
```

---

## Automated Testing Script

### Usage

**Quick test:**
```bash
bash scripts/test-config.sh
```

**What it does:**
1. Runs Tier 1: Syntax check
2. Runs Tier 2: Build test
3. Runs Tier 3: Dry-run preview
4. Reports results

### Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Nix Configuration Testing (3-Tier)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Tier 1: Syntax & Evaluation Check
   Purpose: Validate Nix syntax and options
   Speed:   Fastest (no builds, no downloads)
   Command: nix-instantiate --eval --strict

✅ Syntax check passed - configuration is valid

🏗️  Tier 2: Build Test
   Purpose: Verify configuration builds successfully
   Speed:   Moderate (downloads from cache, no activation)
   Command: home-manager build --flake .

✅ Build test passed - configuration builds successfully
   Result: /nix/store/abc123-home-manager-generation

👀 Tier 3: Dry-Run Preview
   Purpose: Show what would change if applied
   Speed:   Slower (downloads packages, shows diff)
   Command: home-manager switch --dry-run --verbose

⚠️  Note: --dry-run still downloads packages from cache
⚠️       Some activation scripts may run (see dry-run limitations)

[Dry-run output]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ All tests passed!

Configuration is ready to apply.

To apply changes:

  home-manager switch --flake .

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Pre-Commit Integration

### Automatic Syntax Checking

The repository includes a pre-commit hook that automatically runs Tier 1 syntax checking on all Nix files.

**Configuration:** `.pre-commit-config.yaml`

```yaml
- id: nix-syntax-check
  name: Home Manager Syntax Check
  entry: nix-instantiate --eval --strict '.#homeConfigurations'
  language: system
  files: \.nix$
  pass_filenames: false
  description: Validate Home Manager configuration syntax
```

**Installation:**
```bash
# Pre-commit hooks are automatically installed via Nix devShell
# Manual installation if needed:
pre-commit install
```

**Usage:**
```bash
# Runs automatically on git commit
git commit -m "feat: add new package"

# Run manually on all files
pre-commit run --all-files

# Run specific hook
pre-commit run nix-syntax-check
```

---

## Recommended Workflow

### Making Configuration Changes

**Step 1: Edit configuration**
```bash
nvim modules/home-manager/programs/neovim.nix
```

**Step 2: Test changes**
```bash
bash scripts/test-config.sh
```

**Step 3: Review results**
- ✅ All tiers pass → Safe to apply
- ❌ Tier 1 fails → Fix syntax errors
- ❌ Tier 2 fails → Fix build errors
- ❌ Tier 3 shows unexpected changes → Review configuration

**Step 4: Apply changes**
```bash
home-manager switch --flake .
```

**Step 5: Verify**
```bash
# Check Neovim installation
nvim --version

# Check configuration applied
ls -la ~/.config/nvim
```

### Iterative Development

**Fast iteration:**
```bash
# Edit → Tier 1 → Repeat
while editing:
  nix-instantiate --eval --strict '.#homeConfigurations'
```

**Build verification:**
```bash
# After major changes
home-manager build --flake .
```

**Final check before switching:**
```bash
# Full testing
bash scripts/test-config.sh
```

---

## Troubleshooting

### Tier 1: Syntax Errors

**Error:** `error: undefined variable 'progams'`

**Cause:** Typo in option name

**Fix:**
```nix
# Before (incorrect)
progams.git.enable = true;

# After (correct)
programs.git.enable = true;
```

**Error:** `error: infinite recursion encountered`

**Cause:** Circular dependency in configuration

**Fix:** Review module imports and option definitions, look for self-referential options

### Tier 2: Build Failures

**Error:** `builder for '/nix/store/...' failed`

**Cause:** Package build failure or missing dependency

**Fix:**
```bash
# Check package is available
nix search nixpkgs package-name

# Try building package directly
nix build nixpkgs#package-name

# Check build logs
nix build --log-format bar-with-logs
```

**Error:** `attribute 'package-name' missing`

**Cause:** Package doesn't exist in nixpkgs

**Fix:**
```bash
# Search for correct package name
nix search nixpkgs keyword

# Check package in correct scope
nix search nixpkgs nodePackages.package-name
```

### Tier 3: Dry-Run Issues

**Issue:** Dry-run downloads many packages

**Cause:** Expected behavior - `--dry-run` downloads from cache

**Solution:** This is normal. First run takes longer, subsequent runs are fast.

**Issue:** Activation scripts run during dry-run

**Cause:** Known Home Manager limitation

**Workaround:** Use `home-manager build` (Tier 2) for safer testing

---

## Advanced Testing

### Testing Specific Modules

**Test only Neovim configuration:**
```bash
nix-instantiate --eval --strict -A homeConfigurations.<user>.config.programs.neovim
```

**Build only specific package:**
```bash
nix build '.#homeConfigurations.<user>.config.programs.neovim.finalPackage'
```

### Cross-Platform Testing

**Test macOS configuration from Linux:**
```bash
nix-instantiate --eval --strict '.#homeConfigurations.user-macos'
```

**Build for different platform:**
```bash
nix build --system x86_64-darwin '.#homeConfigurations.user-macos'
```

### CI/CD Integration

**GitHub Actions example:**
```yaml
name: Test Nix Configuration

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v25
      - name: Tier 1 - Syntax Check
        run: nix-instantiate --eval --strict '.#homeConfigurations'
      - name: Tier 2 - Build Test
        run: nix build '.#homeConfigurations.ci-test'
```

---

## Comparison with Other Tools

### vs. `nix flake check`

**`nix flake check`:**
- Validates flake structure
- Checks flake outputs
- Runs flake-level tests
- Does NOT validate Home Manager-specific configuration

**`nix-instantiate` (Tier 1):**
- Validates Home Manager configuration
- Checks all module options
- Catches Home Manager-specific errors
- More thorough for Home Manager testing

**Recommendation:** Use both! `nix flake check` for flake validation, `nix-instantiate` for Home Manager validation.

### vs. `nixos-rebuild build-vm`

**`nixos-rebuild build-vm`:**
- Creates VM to test NixOS configuration
- Full system testing
- Slower (builds entire VM)
- Only for NixOS (not Home Manager)

**`home-manager build` (Tier 2):**
- Tests Home Manager configuration
- User-level testing
- Faster (no VM overhead)
- Works on any system with Nix

**Recommendation:** Use `home-manager build` for user environment testing. Use VMs for full system integration testing.

---

## Summary

**Quick Reference:**

| Tier | Command | Speed | Purpose |
|------|---------|-------|---------|
| 1 | `nix-instantiate --eval --strict` | Instant | Syntax validation |
| 2 | `home-manager build` | Moderate | Build verification |
| 3 | `home-manager switch --dry-run` | Slow | Change preview |

**Best Practices:**
- ✅ Run Tier 1 frequently during development
- ✅ Run Tier 2 before major changes
- ✅ Run Tier 3 before switching
- ✅ Use pre-commit hooks for automatic checking
- ✅ Test incrementally, not all at once
- ✅ Keep test script (`scripts/test-config.sh`) up to date

**Remember:**
- Testing doesn't guarantee success, but catches most issues
- Dry-run has limitations (downloads, some scripts execute)
- Always have rollback plan: `home-manager generations`
- Test early, test often, test incrementally

---

*For more information, see [Home Manager Manual](https://nix-community.github.io/home-manager/) and [Nix Reference Manual](https://nixos.org/manual/nix/stable/).*
