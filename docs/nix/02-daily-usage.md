# Daily Usage and Common Workflows

## Overview

This guide covers day-to-day operations with your Nix-powered dev-config environment. After initial setup, these are the tasks you'll perform regularly.

## Environment Activation

### Automatic Activation (Recommended)

When you `cd` into dev-config, direnv automatically activates the Nix environment:

```bash
cd ~/Projects/dev-config
# 🔐 Loading AI credentials from 1Password...
#   ✓ Loaded: ANTHROPIC_API_KEY
#   ✓ Loaded: OPENAI_API_KEY
#   ✓ Loaded: GOOGLE_AI_API_KEY
# ✅ AI credentials loaded from 1Password
```

**What happened:**
1. direnv detected `.envrc`
2. Loaded `nix develop` (all packages available)
3. Sourced `scripts/load-ai-credentials.sh`
4. Exported AI credentials from 1Password

**Verify environment:**
```bash
which nvim     # Should show /nix/store/.../bin/nvim
which opencode # Should show /nix/store/.../bin/opencode
echo $ANTHROPIC_API_KEY  # Should show your API key
```

### Manual Activation

If direnv is not set up:

```bash
cd ~/Projects/dev-config
nix develop
```

To load credentials manually:
```bash
source scripts/load-ai-credentials.sh
```

## Common Daily Tasks

### 1. Updating Packages

**Update all packages to latest versions:**

```bash
cd ~/Projects/dev-config
nix flake update
```

This updates `flake.lock` with latest package versions from nixpkgs.

**View what changed:**
```bash
git diff flake.lock
```

**Test updated environment:**
```bash
nix develop
nvim --version  # Check Neovim version
tmux -V         # Check tmux version
```

**Commit updated lock file:**
```bash
git add flake.lock
git commit -m "chore: update Nix flake inputs"
git push origin main
```

### 2. Adding a New Package

**Edit flake.nix:**
```bash
nvim flake.nix
```

**Note:** Packages are centrally managed in `pkgs/default.nix` (single source of truth).

Add package to appropriate category in `pkgs/default.nix`:
```nix
# pkgs/default.nix
{pkgs}: {
  # ... existing categories ...

  # Add to relevant category
  data = [
    pkgs.jq
    pkgs.yq-go
    pkgs.postgresql  # NEW: Add PostgreSQL client
  ];

  # ... rest of file ...
}
```

**Rebuild environment:**
```bash
nix flake check  # Validate syntax
nix develop      # Enter new environment
```

**Verify package installed:**
```bash
which psql  # Should show /nix/store/.../bin/psql
```

**Commit changes:**
```bash
git add pkgs/default.nix
git commit -m "feat: add PostgreSQL client to data tools"
git push origin main
```

### 3. Removing a Package

**Edit `pkgs/default.nix`:**
```nix
# pkgs/default.nix
{pkgs}: {
  # ... existing categories ...

  core = [
    pkgs.git
    pkgs.zsh
    # Removed: pkgs.docker (if you no longer need it)
    pkgs.neovim
    pkgs.tmux
  ];

  # ... rest of file ...
}
```

**Rebuild and test:**
```bash
nix develop
which docker  # Should return "not found"
```

### 4. Updating Configuration Files

**Example: Modify Neovim config**

```bash
nvim ~/Projects/dev-config/nvim/init.lua
# Make changes...
```

**Apply changes:**
```bash
# No rebuild needed! Configs are symlinked.
# Just restart Neovim to see changes.
nvim
```

**Commit changes:**
```bash
git add nvim/init.lua
git commit -m "feat(nvim): add new keybinding"
git push origin main
```

### 5. Rerunning Activation Script

**When to rerun:**
- Added new dotfiles to flake.nix
- Changed symlink structure
- Need to reinstall Oh My Zsh or TPM

**Rerun activation:**
```bash
nix run .#activate
```

This recreates symlinks and reinstalls plugins without breaking existing setup.

### 6. Rolling Back Changes

**If update broke something:**

```bash
# View generation history
nix profile history

# Output:
# Version 42 (current) - 2025-01-18
# Version 41 - 2025-01-15
# Version 40 - 2025-01-10

# Rollback to previous generation
nix profile rollback

# Or rollback to specific generation
nix profile switch-generation 40
```

**Rollback flake.lock:**
```bash
git log --oneline flake.lock  # Find commit hash before update
git checkout <commit-hash> flake.lock
nix develop  # Uses older package versions
```

## Workflow Patterns

### Pattern 1: Morning Routine

Start your development day:

```bash
cd ~/Projects/dev-config   # Auto-activates Nix + credentials
tmux new -s dev            # Start tmux session
nvim                       # Open editor (LSP auto-starts)
opencode ask "What should I work on today?"  # Get AI suggestions
```

### Pattern 2: Making Config Changes

Safe workflow for experimentation:

```bash
cd ~/Projects/dev-config

# Create feature branch
git checkout -b feat/new-config

# Edit config
nvim nvim/init.lua

# Test changes (no rebuild needed for config files!)
nvim test-file.txt

# If satisfied, commit
git add nvim/init.lua
git commit -m "feat(nvim): add new feature"
git push origin feat/new-config

# Create PR for team review
gh pr create --title "New Neovim feature"
```

### Pattern 3: Syncing to Another Machine

**On your updated workstation:**
```bash
cd ~/Projects/dev-config
git push origin main
```

**On target machine:**
```bash
cd ~/Projects/dev-config
git pull origin main

# If flake.lock changed, rebuild environment
nix develop

# If config files changed, restart affected tools
tmux source-file ~/.tmux.conf  # Reload tmux
source ~/.zshrc                # Reload zsh
# Restart Neovim (no command, just exit and reopen)
```

### Pattern 4: Weekly Maintenance

**Sunday evening checklist:**

```bash
cd ~/Projects/dev-config

# Update packages
nix flake update
git add flake.lock
git commit -m "chore: weekly flake update"

# Rebuild and test
nix develop
nvim --version
tmux -V
opencode --version

# Run health checks
nvim +checkhealth +qall  # Neovim health check
bash scripts/validate.sh  # Repo validation

# Push updates
git push origin main
```

### Pattern 5: AI-Assisted Development

**Using OpenCode with 1Password credentials:**

```bash
cd ~/Projects/dev-config  # Credentials auto-load

# Ask for code review
opencode ask "Review nvim/init.lua for improvements"

# Generate new config
opencode ask "Create a tmux keybinding for splitting panes"

# Debug issues
opencode ask "Why is my LSP not attaching? Here's my :LspInfo output: ..."
```

**Credentials are automatically injected** via direnv + 1Password integration.

## direnv Integration

### How It Works

```
1. You: cd ~/Projects/dev-config
2. direnv: Detects .envrc file
3. direnv: Runs `use flake`
4. Nix: Loads all packages from flake.nix
5. direnv: Sources scripts/load-ai-credentials.sh
6. 1Password CLI: Fetches API keys from "Dev" vault
7. You: All tools + credentials available!
```

### Allow/Block Directories

**First time in directory:**
```bash
cd ~/Projects/dev-config
# direnv: error .envrc is blocked. Run `direnv allow` to approve its content.

direnv allow  # Approve .envrc
# 🔐 Loading AI credentials...
```

**Block a directory:**
```bash
direnv block
```

**Re-allow:**
```bash
direnv allow
```

### Troubleshooting direnv

**Environment not loading:**
```bash
direnv status  # Check direnv state

# Should show:
# Found RC allowed true
# Found RC path /Users/you/Projects/dev-config/.envrc
```

**Manual reload:**
```bash
direnv reload
```

**Check hook installation:**
```bash
cat ~/.zshrc | grep direnv
# Should show: eval "$(direnv hook zsh)"
```

## OpenCode Workflows

### Common OpenCode Commands

**Ask a question:**
```bash
opencode ask "How do I configure Neovim LSP for Python?"
```

**Review code:**
```bash
opencode ask "Review nvim/init.lua and suggest improvements"
```

**Generate code:**
```bash
opencode ask "Create a shell function to quickly switch tmux sessions"
```

**Debug:**
```bash
opencode ask "Debug: Neovim LSP not working. :LspInfo shows: ..."
```

### OpenCode + 1Password Integration

**Automatic credential injection:**
```bash
cd ~/Projects/dev-config  # Credentials auto-load
opencode ask "..."        # Uses ANTHROPIC_API_KEY from environment
```

**Explicit op run (most secure):**
```bash
op run -- opencode ask "Explain this codebase"
# Credentials injected only for duration of command
```

**Verify credentials loaded:**
```bash
echo $ANTHROPIC_API_KEY  # Should show sk-ant-...
```

### Provider Selection

**Default provider (Anthropic Claude):**
```bash
opencode ask "..."  # Uses Claude by default
```

**Use different provider:**
```bash
opencode ask --provider openai "..."    # Use GPT
opencode ask --provider google-ai "..." # Use Gemini
```

**Configure default in ~/.opencode/config.yaml:**
```yaml
default_provider: anthropic
providers:
  anthropic:
    model: claude-3-5-sonnet-20241022
  openai:
    model: gpt-4o
```

## Team Collaboration

### Sharing Config Changes

**Push changes:**
```bash
cd ~/Projects/dev-config
git add .
git commit -m "feat: add new tmux plugin"
git push origin main
```

**Team members pull:**
```bash
cd ~/Projects/dev-config
git pull origin main
nix develop  # Automatically rebuilds if flake.lock changed
```

**No manual "install updated packages" step!** Nix handles it automatically.

### Sharing 1Password Credentials

**For team vaults:**
1. Create shared "Dev" vault in 1Password
2. Add team members to vault
3. Create "ai" item with team credentials
4. Each team member runs `op signin`
5. Credentials auto-load for all team members

**Result:** Everyone uses same API keys, no manual distribution.

### Binary Caching for Teams

**First build (no cache):**
- Time: 5-10 minutes (building packages from source)

**Subsequent builds (with Cachix):**
- Time: 10-30 seconds (downloading pre-built binaries)
- 20x faster!

**How it works:**
1. First team member builds environment
2. Cachix uploads build artifacts
3. Other team members download instead of rebuilding

**No setup needed** - configured in `flake.nix`.

## Tips and Tricks

### 1. Quick Environment Check

**Verify everything is working:**
```bash
cd ~/Projects/dev-config
nix develop --command bash -c "
  nvim --version &&
  tmux -V &&
  op account get &&
  opencode --version &&
  echo '✅ All tools operational'
"
```

### 2. Temporary Package Installation

**Need a tool just once?**
```bash
nix shell nixpkgs#htop  # Temporarily add htop
htop                    # Use it
exit                    # Tool removed when shell exits
```

**Don't pollute flake.nix with temporary tools.**

### 3. Search for Packages

**Find package name:**
```bash
nix search nixpkgs postgresql
# Returns: legacyPackages.x86_64-darwin.postgresql
# Use: pkgs.postgresql in flake.nix
```

**Web search:**
https://search.nixos.org/packages

### 4. Garbage Collection

**Nix store grows over time.** Clean up old generations:

```bash
# Remove old generations (keep last 10)
nix-collect-garbage --delete-older-than 30d

# Aggressive cleanup (keep only current generation)
nix-collect-garbage -d
```

**Caution:** This removes ability to rollback to old generations.

### 5. Offline Development

**Nix works offline** if packages are cached:

```bash
# Build all dependencies while online
nix build .#devShells.x86_64-darwin.default

# Later, offline:
cd ~/Projects/dev-config
nix develop  # Uses cached packages
```

### 6. Multiple Projects with Different Dependencies

**Use project-specific flake.nix:**

```bash
# Project A: Uses Python 3.9
cd ~/Projects/project-a
nix develop  # Loads Python 3.9

# Project B: Uses Python 3.11
cd ~/Projects/project-b
nix develop  # Loads Python 3.11

# No conflicts! Isolated environments.
```

### 7. Shell Integration

**Add to ~/.zshrc.local:**
```bash
# Auto-activate Nix in dev-config
cd() {
  builtin cd "$@"
  if [[ $(pwd) == "$HOME/Projects/dev-config"* ]]; then
    echo "🔧 Nix environment active"
  fi
}

# Quick rebuild alias
alias nix-rebuild="cd ~/Projects/dev-config && nix develop && cd -"
```

## Performance Optimization

### Cachix Binary Cache

**Verify Cachix is working:**
```bash
nix build .#devShells.x86_64-darwin.default --print-build-logs
# Look for: "copying path ... from 'https://dev-config.cachix.org'"
```

**If builds are slow:**
1. Check internet connection
2. Verify Cachix cache name in flake.nix
3. Check GitHub Actions pushed to cache

### Local Binary Cache

**Create personal cache for fast rebuilds:**
```bash
# Build once
nix build .#devShells.x86_64-darwin.default

# Subsequent builds use local cache
nix develop  # Nearly instant!
```

### Evaluation Cache

**Speed up flake evaluation:**
```bash
nix develop --eval-cache  # Experimental feature
```

## Common Questions

### Q: How do I update just one package?

**A:** Update specific input:
```bash
nix flake lock --update-input nixpkgs
```

Or pin to specific version in flake.nix:
```nix
inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable?rev=abc123";
```

### Q: Can I use Homebrew alongside Nix?

**A:** Yes! They coexist peacefully:
- Nix packages: `/nix/store/`
- Homebrew: `/opt/homebrew/` (Apple Silicon) or `/usr/local/` (Intel)

Use Nix for development tools, Homebrew for GUI apps.

### Q: What happens if I `nix develop` in a non-dev-config directory?

**A:** Nothing, unless that directory has a flake.nix. Nix only activates when:
1. You run `nix develop` in directory with flake.nix
2. direnv detects .envrc with `use flake`

### Q: How do I share my environment with CI/CD?

**A:** GitHub Actions example:
```yaml
- uses: DeterminateSystems/nix-installer-action@main
- uses: DeterminateSystems/magic-nix-cache-action@main
- uses: cachix/cachix-action@v14
  with:
    name: dev-config
    authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
- run: nix develop --command make test
```

CI builds use same flake.lock → identical environment.

### Q: Can I override package versions?

**A:** Yes, using overlays in flake.nix:
```nix
nixpkgs.overlays = [
  (final: prev: {
    neovim = prev.neovim.overrideAttrs (old: {
      version = "0.10.0";  # Pin specific version
    });
  })
];
```

## Next Steps

- **Troubleshooting:** [Common Issues](03-troubleshooting.md)
- **Advanced Customization:** [Advanced Guide](06-advanced.md)
- **Nix Concepts:** [Understanding Nix](01-concepts.md)
- **Quick Reference:** [Quick Start](00-quickstart.md)

## Quick Reference Card

```bash
# Daily Commands
cd ~/Projects/dev-config      # Auto-activate environment
nix flake update              # Update all packages
nix develop                   # Enter dev environment
nix run .#activate            # Rerun activation script
nix profile rollback          # Undo last change

# Package Management
nix search nixpkgs <name>     # Find package
nix shell nixpkgs#<pkg>       # Temporary package
nix-collect-garbage -d        # Clean up old builds

# Environment
direnv allow                  # Approve .envrc
direnv reload                 # Reload environment
op signin                     # Authenticate 1Password

# OpenCode
opencode ask "..."            # Ask AI assistant
opencode --provider openai    # Use different provider

# Validation
nix flake check               # Validate flake.nix
bash scripts/validate.sh      # Validate setup
nvim +checkhealth +qall       # Neovim health check

# Git
git add flake.lock            # Commit package updates
git push origin main          # Share with team
```
