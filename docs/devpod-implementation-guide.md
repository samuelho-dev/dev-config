# DevPod Implementation Guide: Step-by-Step Setup

**Status:** Ready for implementation
**Complexity:** Medium (builds on existing Nix + dotfiles infrastructure)
**Timeline:** 1-2 hours for Phase 1, weeks for full optimization

---

## Phase 1: Add devcontainer.json Support (VS Code Remote Containers Compatible)

**Goal:** Enable VS Code Remote Containers and GitHub Codespaces support without breaking existing setup.

### Step 1: Create `.devcontainer/` Directory Structure

```bash
cd /Users/samuelho/Projects/dev-config

mkdir -p .devcontainer
```

### Step 2: Create `.devcontainer/devcontainer.json`

```json
{
  "name": "dev-config",
  "description": "Development environment with Nix, Tmux, Neovim, Zsh",

  "image": "mcr.microsoft.com/devcontainers/base:debian",

  "features": {
    "ghcr.io/devcontainers/features/nix:1": {
      "extraNixConfig": "experimental-features = nix-command flakes"
    }
  },

  "remoteUser": "vscode",

  "containerEnv": {
    "SHELL": "/bin/zsh",
    "TERM": "xterm-256color"
  },

  "remoteEnv": {
    "PATH": "${containerEnv:PATH}",
    "HOME": "/home/vscode"
  },

  "onCreateCommand": "apt-get update && apt-get install -y git curl",

  "postCreateCommand": "cd /workspaces/dev-config && nix flake update --offline 2>/dev/null || true && nix run .#activate 2>&1 | head -20",

  "postStartCommand": "source ~/.zshrc && p10k configure --quiet || true",

  "customizations": {
    "vscode": {
      "extensions": [
        "jnoortheen.nix-ide",
        "ms-vscode.remote-containers",
        "tamasfe.even-better-toml",
        "folke.nix",
        "vim.vim",
        "eamodio.gitlens",
        "ms-python.python"
      ],
      "settings": {
        "nix.enableLanguageServer": true,
        "[nix]": {
          "editor.defaultFormatter": "jnoortheen.nix-ide",
          "editor.formatOnSave": true
        },
        "[json]": {
          "editor.defaultFormatter": "esbenp.prettier-vscode",
          "editor.formatOnSave": true
        },
        "vim.enable": true,
        "vim.enableNeovim": true
      }
    }
  },

  "mounts": [
    "source=/nix/store,target=/nix/store,type=bind,consistency=delegated"
  ]
}
```

### Step 3: Test with VS Code

```bash
# 1. Open dev-config folder in VS Code
code /Users/samuelho/Projects/dev-config

# 2. Install "Dev Containers" extension (ms-vscode.remote-containers)

# 3. Press Cmd+Shift+P and search "Dev Containers: Reopen in Container"

# 4. VS Code rebuilds container (first time: 5-10 minutes for Nix evaluation)

# 5. Inside container, verify setup:
nix --version
zsh --version
nvim --version
tmux -V
```

### Step 4: Verify Dotfiles Installation

```bash
# Inside container, check if dotfiles were applied
ls -la ~/.zshrc
ls -la ~/.tmux.conf
ls -la ~/.config/nvim

# All should exist and be readable
```

### Step 5: Git Commit

```bash
cd /Users/samuelho/Projects/dev-config

git add .devcontainer/devcontainer.json
git commit -m "feat(devcontainer): add VS Code Remote Containers support

- Enable Nix flakes in container
- Auto-install via scripts/install.sh
- Configure shell and extensions
- Compatible with GitHub Codespaces"
```

---

## Phase 2: Add DevPod-Specific Optimizations

**Goal:** Enable fast DevPod workspace creation with explicit dotfiles integration.

### Step 6: Create `.devcontainer/load-ai-credentials.sh`

```bash
#!/bin/bash
# .devcontainer/load-ai-credentials.sh
# Load 1Password secrets in DevPod containers

set -euo pipefail

# Only run if 1Password CLI is available
if ! command -v op &> /dev/null; then
  echo "[warn] 1Password CLI not installed, skipping secret loading"
  exit 0
fi

# Check if already authenticated
if ! op account get &> /dev/null; then
  # If SERVICE_ACCOUNT_TOKEN set, use it
  if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    export OP_SERVICE_ACCOUNT_TOKEN
    echo "[info] Using 1Password Service Account"
  else
    echo "[warn] 1Password not authenticated and no SERVICE_ACCOUNT_TOKEN set"
    echo "[info] To authenticate manually, run: eval \$(op signin)"
    exit 0
  fi
fi

# Load secrets
if op item get "ai" &> /dev/null; then
  export ANTHROPIC_API_KEY=$(op read "op://Dev/ai/ANTHROPIC_API_KEY" 2>/dev/null || echo "")
  export OPENAI_API_KEY=$(op read "op://Dev/ai/OPENAI_API_KEY" 2>/dev/null || echo "")
  export GOOGLE_AI_API_KEY=$(op read "op://Dev/google/API_KEY" 2>/dev/null || echo "")

  [ -n "$ANTHROPIC_API_KEY" ] && echo "[info] Loaded ANTHROPIC_API_KEY"
  [ -n "$OPENAI_API_KEY" ] && echo "[info] Loaded OPENAI_API_KEY"
  [ -n "$GOOGLE_AI_API_KEY" ] && echo "[info] Loaded GOOGLE_AI_API_KEY"
else
  echo "[warn] 1Password 'ai' item not found in vault"
fi
```

Make executable:
```bash
chmod +x .devcontainer/load-ai-credentials.sh
```

### Step 7: Update devcontainer.json with Secrets Support

```json
{
  // ... existing config ...

  "remoteEnv": {
    "OP_SERVICE_ACCOUNT_TOKEN": "${localEnv:OP_SERVICE_ACCOUNT_TOKEN}"
  },

  "postCreateCommand": "bash -c 'cd /workspaces/dev-config && bash .devcontainer/load-ai-credentials.sh && nix run .#activate 2>&1 | tail -5'",

  // ... rest of config ...
}
```

### Step 8: Update `scripts/install.sh` for Container Detection

Edit `scripts/install.sh` to skip package manager setup in containers:

```bash
#!/bin/bash
# scripts/install.sh (around line 10, add container detection)

# Detect if running in container
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
  IS_CONTAINER=1
  log_info "Running in container - skipping package manager setup"
else
  IS_CONTAINER=0
  log_info "Running on bare metal"
fi

# Later in script, skip Nix installation if in container with Nix feature
if [ "$IS_CONTAINER" = "0" ] && ! command -v nix &> /dev/null; then
  log_info "Installing Nix..."
  # ... existing Nix install logic ...
fi
```

### Step 9: Test with DevPod

```bash
# Install DevPod (if not already installed)
brew install devpod  # macOS

# Set context-wide dotfiles (one time)
devpod context set-options \
  -o DOTFILES_URL=https://github.com/samuelho-dev/dev-config \
  -o DOTFILES_SCRIPT=scripts/install.sh

# Create a test workspace
devpod up https://github.com/samuelho-dev/dev-config

# Inside DevPod container:
nix --version
zsh --version
echo $HOME
```

### Step 10: Git Commit

```bash
git add .devcontainer/load-ai-credentials.sh scripts/install.sh
git commit -m "feat(devpod): optimize for DevPod workspace creation

- Add 1Password Service Account integration
- Container detection in install script
- Support --dotfiles flag with scripts/install.sh
- Load AI credentials from 1Password vault"
```

---

## Phase 3: Pre-Built Docker Image (Performance Optimization)

**Goal:** Reduce container startup time from hours to 30 seconds.

### Step 11: Create `.devcontainer/Dockerfile.devpod`

```dockerfile
# .devcontainer/Dockerfile.devpod
# Pre-built DevPod image with Nix and dev-config cached

FROM mcr.microsoft.com/devcontainers/base:debian

# Install Nix
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install \
    --deterministic \
    --no-start-daemon

# Enable flakes in Nix
RUN mkdir -p /etc/nix && \
    echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf

# Create workspace directory
RUN mkdir -p /workspaces/dev-config

# Copy only flake files (to leverage Docker layer caching)
COPY flake.nix flake.lock /workspaces/dev-config/

# Pre-warm Nix store (build flake schema)
WORKDIR /workspaces/dev-config
RUN nix flake show --offline || nix flake show 2>&1 | tail -5 || true

# Switch to vscode user for remaining setup
USER vscode
RUN /nix/var/nix/profiles/default/bin/nix flake update --offline || true

# Expected startup time:
# - FROM mcr.microsoft.com/devcontainers/base:debian: cached
# - Nix install: ~2 min (first time only, cached after)
# - Flake setup: ~1 min (cached)
# - Total: ~3 min
```

### Step 12: Update devcontainer.json to Use Pre-Built Image

```json
{
  "name": "dev-config",

  // Use pre-built image instead of building from base
  "image": "ghcr.io/samuelho-dev/dev-config:nix-prebuilt",
  // OR: "build": { "dockerfile": ".devcontainer/Dockerfile.devpod" }

  // Rest of config remains the same...
}
```

### Step 13: Add GitHub Actions CI for Image Building

Create `.github/workflows/devpod-build.yml`:

```yaml
name: Build and Push DevPod Image

on:
  push:
    branches: [main]
    paths:
      - 'flake.nix'
      - 'flake.lock'
      - '.devcontainer/Dockerfile.devpod'
      - '.github/workflows/devpod-build.yml'

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push DevPod image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: .devcontainer/Dockerfile.devpod
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:nix-prebuilt
            ghcr.io/${{ github.repository }}:nix-prebuilt-latest
          cache-from: type=registry,ref=ghcr.io/${{ github.repository }}:buildcache
          cache-to: type=registry,ref=ghcr.io/${{ github.repository }}:buildcache,mode=max
```

### Step 14: Git Commit

```bash
git add .devcontainer/Dockerfile.devpod .github/workflows/devpod-build.yml
git commit -m "feat(devpod): add pre-built Docker image for faster startup

- Pre-build image with Nix flake cached
- Reduces startup time from 1+ hour to ~30 seconds
- GitHub Actions CI/CD to build and push image
- Registry: ghcr.io/samuelho-dev/dev-config:nix-prebuilt"
```

---

## Phase 4: Advanced: Chezmoi + DevPod (Optional)

**Goal:** Use Chezmoi for more sophisticated dotfiles management.

**Note:** Only pursue this if symlink-based approach becomes limiting.

### Decision Point: When to Use Chezmoi

**Stick with current `scripts/install.sh` if:**
- Simple symlinks work fine
- No complex templating needed
- Current setup is stable

**Consider Chezmoi if:**
- Need OS-specific config variations
- Want "apply-on-update" behavior
- Supporting multiple teams/machines
- Need encrypted secrets in dotfiles

### Implementation Outline (Not Detailed Here)

```bash
# Add Chezmoi feature to devcontainer.json
"features": {
  "ghcr.io/rio/features/chezmoi:1": {}
}

# Update scripts/install.sh to use Chezmoi
chezmoi init https://github.com/samuelho-dev/dev-config
chezmoi apply
```

Reference: `/Users/samuelho/Projects/dev-config/CHEZMOI.md` (existing documentation)

---

## Testing Checklist

### Test 1: VS Code Remote Containers

- [ ] Open dev-config in VS Code
- [ ] Click "Reopen in Container"
- [ ] Wait for container to build (~10 min first time)
- [ ] Verify `zsh --version` and `nix --version` in integrated terminal
- [ ] Verify Neovim works: `nvim ~/.zshrc`
- [ ] Run tests: `:checkhealth` in Neovim
- [ ] Verify Tmux: `tmux new-session -d -s test`

### Test 2: DevPod Workspace

```bash
# Create workspace with context-wide dotfiles
devpod up https://github.com/samuelho-dev/dev-config

# Verify inside DevPod
devpod ssh <workspace-id>
zsh --version
nix --version
ls -la ~/.zshrc

# Verify 1Password secrets (if SERVICE_ACCOUNT_TOKEN set)
op read "op://Dev/ai/ANTHROPIC_API_KEY"

# Cleanup
devpod delete <workspace-id>
```

### Test 3: GitHub Codespaces

```bash
# Push changes to GitHub
git push origin main

# Go to GitHub repo → Code → Codespaces → Create
# Wait for container to start (uses devcontainer.json)
# Verify nix and zsh in terminal
```

### Test 4: Performance Comparison

```bash
# Time different startup paths
time devpod up https://github.com/samuelho-dev/dev-config  # Should be <2 min with cache

# Monitor container logs
devpod logs <workspace-id> | grep -E "postCreate|dotfiles"
```

---

## Troubleshooting

### Issue: Container Build Fails with "nix: command not found"

**Solution:** Ensure Nix feature is enabled:
```json
{
  "features": {
    "ghcr.io/devcontainers/features/nix:1": {}
  }
}
```

### Issue: Dotfiles Not Applied in DevPod

**Solution:** Check execution order and permissions:
```bash
devpod logs <workspace-id> | grep -i dotfiles

# Manually run dotfiles script
devpod ssh <workspace-id>
bash /workspaces/dev-config/scripts/install.sh
```

### Issue: 1Password Credentials Not Loaded

**Solution:** Set Service Account token on host:
```bash
export OP_SERVICE_ACCOUNT_TOKEN=ops_...
devpod up <repo>
```

### Issue: Nix Evaluation Takes Too Long

**Solution:** Use pre-built image or cache:
```json
{
  "image": "ghcr.io/samuelho-dev/dev-config:nix-prebuilt"
}
```

### Issue: Zsh/Tmux Not Working After Container Start

**Solution:** Ensure `postStartCommand` runs after dotfiles:
```json
{
  "postStartCommand": "source ~/.zshrc && direnv reload || true"
}
```

---

## Next Steps After Implementation

1. **Week 1:** Get Phase 1 (devcontainer.json) working locally
2. **Week 2:** Test with VS Code Remote Containers and GitHub Codespaces
3. **Week 3:** Set up DevPod context and test workspace creation
4. **Week 4:** Build and push pre-built image, optimize startup time
5. **Ongoing:** Monitor performance, gather team feedback, iterate

---

## File Checklist

After completing all phases, your repo should contain:

```
.devcontainer/
├── devcontainer.json              ✅ (Phase 1)
├── load-ai-credentials.sh         ✅ (Phase 2)
└── Dockerfile.devpod              ✅ (Phase 3)

.github/workflows/
└── devpod-build.yml               ✅ (Phase 3)

scripts/
├── install.sh                     ✅ (Phase 2 - updated)
├── lib/common.sh                  ✅ (unchanged)
└── lib/paths.sh                   ✅ (unchanged)

docs/
├── devpod-integration-research.md ✅ (reference)
└── devpod-implementation-guide.md ✅ (this file)
```

---

## Resources

- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [DevPod Documentation](https://devpod.sh/docs)
- [Dev Container Specification](https://containers.dev)
- [1Password CLI Secrets](https://developer.1password.com/docs/cli/secrets-environment-variables)
