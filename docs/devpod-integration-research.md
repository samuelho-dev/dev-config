# DevPod Integration Research: Dotfiles, Nix, and Secrets Management

**Research Date:** November 19, 2025
**Focus:** Remote development environments with dev-config
**Status:** Comprehensive findings for implementation planning

---

## Executive Summary

This research synthesizes best practices for integrating **DevPod** with your existing **Nix flake + dotfiles + 1Password** stack. Key findings:

1. **DevPod dotfiles integration is explicit and flexible** - supports custom install scripts with context-wide configuration
2. **devcontainer.json is the central configuration** - works with DevPod, VS Code Remote Containers, and GitHub Codespaces
3. **Nix flakes can be integrated via devcontainer features** - but direct flake.nix integration in containers is still evolving
4. **Execution order matters** - postCreateCommand → dotfiles → postStartCommand (dotfiles runs *after* postCreateCommand)
5. **1Password integration is mature** - uses `op run` with environment variables and service accounts for security
6. **User permissions require attention** - dotfiles should run as remoteUser, not root (known issue with SSH configs)

---

## 1. DevPod Dotfiles Integration

### How DevPod Handles Dotfiles

**Primary mechanism:** The `--dotfiles` flag during workspace creation triggers automatic cloning and installation:

```bash
devpod up <workspace-repo> --dotfiles <dotfiles-repo> [--dotfiles-script <custom-script>]
```

**Default installation script search order (8 locations):**
1. `install.sh`
2. `install`
3. `bootstrap.sh`
4. `bootstrap`
5. `script/bootstrap`
6. `setup.sh`
7. `setup`
8. `script/setup`

If **none found**, DevPod symlinks all hidden files (files starting with `.`) directly to `$HOME`.

### Custom Installation Script

Override default locations with explicit path:

```bash
devpod up https://github.com/example/repo \
  --dotfiles https://github.com/my-user/my-dotfiles-repo \
  --dotfiles-script custom/location/install.sh
```

**Current dev-config recommendation:**
```bash
devpod up <workspace-repo> \
  --dotfiles https://github.com/samuelho-dev/dev-config \
  --dotfiles-script scripts/install.sh
```

### Context-Wide Configuration

Avoid specifying dotfiles/script for every workspace:

```bash
devpod context set-options \
  -o DOTFILES_URL=https://github.com/samuelho-dev/dev-config \
  -o DOTFILES_SCRIPT=scripts/install.sh
```

**All new workspaces will inherit these settings automatically.**

### Execution Context & Permissions

**Critical issue identified:** When using `--ssh-config`, dotfiles may execute as root instead of remoteUser.

**Expected behavior:** Dotfiles script runs as configured `remoteUser` (e.g., `vscode`, `ubuntu`)

**Risk:** Root-owned files in `$HOME` break user permissions and can make container unusable.

**Mitigation strategies:**
- Avoid `--ssh-config` if possible (use local Docker driver)
- Ensure install script explicitly sets correct ownership: `chown -R $USER:$USER $HOME`
- Use `sudo` sparingly in dotfiles script
- Test dotfiles installation in isolated container first

---

## 2. devcontainer.json Specification

### Required vs. Optional Fields

**Most fields are optional** - requirements depend on setup scenario:

| Scenario | Required Field(s) |
|----------|------------------|
| Using pre-built image | `"image": "ghcr.io/org/repo:tag"` |
| Using Dockerfile | `"build": { "dockerfile": "Dockerfile" }` |
| Using Docker Compose | `"dockerComposeFile": "...", "service": "..."` |

**Recommended but not required:** `"name"` (for clarity)

### Key Configuration Categories

**General properties:**
```json
{
  "name": "dev-config-remote",
  "image": "ghcr.io/samuelho-dev/dev-config:latest",
  "remoteUser": "vscode",
  "containerEnv": {
    "SHELL": "/bin/zsh",
    "TERM": "xterm-256color"
  },
  "remoteEnv": {
    "PATH": "${containerEnv:PATH}:/usr/local/nix-profile/bin",
    "NIX_PATH": "nixpkgs=channel:nixpkgs-unstable"
  }
}
```

**Difference between `containerEnv` and `remoteEnv`:**

- **`containerEnv`** - Set during container image build (Docker `RUN` equivalent), evaluated before container starts
- **`remoteEnv`** - Set after container is running, evaluated in VS Code/IDE context only, can reference existing container variables

**Example using both:**
```json
{
  "containerEnv": {
    "LANG": "en_US.UTF-8"
  },
  "remoteEnv": {
    "PATH": "${containerEnv:PATH}:/custom/path",
    "NIXPKGS": "/workspaces/nixpkgs"
  }
}
```

### Custom Docker Images (Nix-Built)

Reference via standard `build` property:

```json
{
  "build": {
    "dockerfile": "Dockerfile.devpod",
    "context": ".",
    "args": {
      "BASE_IMAGE": "nixos/nix:latest"
    }
  }
}
```

**For pre-built Nix images, use `image` directly:**
```json
{
  "image": "ghcr.io/samuelho-dev/dev-config:nix-latest"
}
```

### Features: Reusable Components

DevPod features are "reusable Dockerfile parts" - modular pre-built configurations:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/nix:1": {
      "extraNixConfig": "experimental-features = nix-command flakes\nsandbox = true",
      "installHomeManager": false
    },
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  }
}
```

**Official feature registry:** https://containers.dev/features

### Extensions & VS Code Settings

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "jnoortheen.nix-ide",
        "ms-vscode.remote-containers",
        "tamasfe.even-better-toml",
        "folke.nix"
      ],
      "settings": {
        "nix.enableLanguageServer": true,
        "[nix]": {
          "editor.defaultFormatter": "jnoortheen.nix-ide",
          "editor.formatOnSave": true
        }
      }
    }
  }
}
```

---

## 3. Lifecycle Hooks: Execution Order & Timing

### Complete Lifecycle Sequence

DevPod executes commands in this strict order on initial container creation:

1. **`initializeCommand`** - Runs on host machine only (preparation phase)
2. **`onCreateCommand`** - First container setup (root context, no user assets yet)
3. **`updateContentCommand`** - Second container setup
4. **`postCreateCommand`** - Final container setup (runs in background, has user context)
5. **Dotfiles installation** ← **RUNS AFTER postCreateCommand** (critical timing!)
6. **`postStartCommand`** - Runs each time container starts (has all personalization)
7. **`postAttachCommand`** - Runs when IDE attaches to container

### Critical Behavior: Dotfiles Runs AFTER postCreateCommand

**Implication:** Don't configure shell dotfiles in `postCreateCommand` - they'll be overwritten by dotfiles installation.

**Correct pattern:**
```json
{
  "postCreateCommand": "# Install system tools (package managers, build tools)",
  "postStartCommand": "# Configure shell, load plugins, etc (runs AFTER dotfiles)"
}
```

**Script failure behavior:** If any command fails, all subsequent commands are skipped (fail-fast).

### Command Format Options

All lifecycle commands support 3 formats:

```json
{
  "postCreateCommand": "echo hello",                    // String (shell execution)
  "postCreateCommand": ["bash", "-c", "echo hello"],    // Array (direct execution)
  "postCreateCommand": {                                 // Object (parallel execution)
    "build": "npm run build",
    "test": "npm test"
  }
}
```

---

## 4. Nix Flakes + DevPod Integration

### Current Status: Feature Support Available

**Key discovery:** NixOS/nixpkgs project successfully uses devcontainer.json with Nix flakes.

**Their configuration:**
```json
{
  "image": "mcr.microsoft.com/devcontainers/universal:2-linux",
  "features": {
    "ghcr.io/devcontainers/features/nix:1": {
      "extraNixConfig": "experimental-features = nix-command flakes\nsandbox = true"
    }
  },
  "remoteEnv": {
    "NIXPKGS": "/workspaces/nixpkgs"
  },
  "customizations": {
    "vscode": {
      "extensions": ["jnoortheen.nix-ide"],
      "settings": {
        "nixd.nixpkgs.expr": "import <nixpkgs> {}"
      }
    }
  }
}
```

### Recommended Pattern for dev-config

**Two approaches:**

#### Approach A: Nix Feature + flake.nix (Recommended)

Use devcontainer Nix feature to enable flakes, rely on existing `flake.nix`:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:debian",
  "features": {
    "ghcr.io/devcontainers/features/nix:1": {
      "extraNixConfig": "experimental-features = nix-command flakes"
    }
  },
  "onCreateCommand": "nix flake update --flake /workspaces/dev-config",
  "postCreateCommand": "cd /workspaces/dev-config && nix run .#activate"
}
```

**Benefits:**
- Reuses existing Nix infrastructure
- Activates entire flake.nix environment
- Works across macOS/Linux

**Limitations:**
- First run slow (Nix evaluation, package building)
- Subsequent runs cached but still slower than pre-built images

#### Approach B: Pre-Built Nix Docker Image (Faster)

Build Docker image with Nix pre-configured, commit to registry:

```dockerfile
# Dockerfile.devpod.nix
FROM nixos/nix:latest

RUN nix-channel --add https://nixos.org/channels/nixos-unstable unstable
RUN nix-channel --update

# Copy flake files to enable build cache
COPY flake.nix flake.lock /workspaces/dev-config/
RUN cd /workspaces/dev-config && \
    nix build .#devShell --no-link  # Pre-warm cache

USER vscode
```

Use in devcontainer.json:
```json
{
  "image": "ghcr.io/samuelho-dev/dev-config:nix-prebuilt",
  "postCreateCommand": "cd /workspaces/dev-config && nix run .#activate"
}
```

**Benefits:**
- Docker cache layer speeds up repeated builds
- First startup 10-30 seconds instead of hours
- Suitable for CI/CD integration

**Limitations:**
- Requires Docker image build and registry push
- Image size larger (~2-3GB for full Nix)

### Direnv Integration in DevPod Containers

**Current limitation:** Direnv + `use flake` is NOT automatically activated inside containers.

**To enable direnv in DevPod container:**

```json
{
  "features": {
    "ghcr.io/devcontainers/features/nix:1": {},
    "ghcr.io/nix-community/nix-direnv:1": {}  // Custom feature
  },
  "postCreateCommand": [
    "bash",
    "-c",
    "cd /workspaces/dev-config && direnv allow && direnv reload"
  ]
}
```

**Note:** Direnv shell hooks must be already installed in base image or loaded in shell initialization.

---

## 5. Secrets Management: 1Password Integration

### 1Password CLI with Environment Variables

**Recommended approach:** Use `op run` with secret references in environment files.

**Step 1: Create `.env.op` file** (can be committed to Git - it's safe):
```bash
export ANTHROPIC_API_KEY=op://Dev/ai/ANTHROPIC_API_KEY
export OPENAI_API_KEY=op://Dev/ai/OPENAI_API_KEY
export GOOGLE_AI_API_KEY=op://Dev/google/API_KEY
```

**Step 2: Load in container:**
```bash
eval "$(op signin)"
source .env.op
```

Or use `op run` directly:
```bash
op run --env-file .env.op -- bash
```

**Security best practice:** Use 1Password Service Accounts for CI/CD and remote containers.

### Service Account Integration (Recommended for Remote)

Service accounts are restricted tokens that access only specific vaults - not your entire vault:

```bash
# Create service account (1Password admin)
export OP_SERVICE_ACCOUNT_TOKEN="ops_..."

# Load secrets
op run --env-file .env.op -- bash
```

**Benefits:**
- No personal 1Password authentication required in container
- Secrets never stored on disk
- Audit trail of access
- Can revoke without affecting personal account

### DevPod/DevContainers Integration Pattern

Add to `devcontainer.json`:

```json
{
  "remoteEnv": {
    "OP_SERVICE_ACCOUNT_TOKEN": "${localEnv:OP_SERVICE_ACCOUNT_TOKEN}"
  },
  "postCreateCommand": "bash -c 'eval $(op signin) && direnv reload'"
}
```

**Flow:**
1. Host machine: `export OP_SERVICE_ACCOUNT_TOKEN=ops_...`
2. Container startup: Token passed via `remoteEnv`
3. `postCreateCommand`: Authenticate with 1Password
4. Secrets available: `op read "op://vault/item/field"`

### Environment Variable Injection (Without remoteEnv)

Alternative if `remoteEnv` not working:

```json
{
  "containerEnv": {
    "OP_SERVICE_ACCOUNT_TOKEN": "${localEnv:OP_SERVICE_ACCOUNT_TOKEN}"
  }
}
```

**Important note:** `containerEnv` is evaluated before container starts, `remoteEnv` is evaluated within IDE context.

### Comparison: Methods

| Method | Security | Container Access | CI/CD Friendly |
|--------|----------|------------------|----------------|
| 1Password CLI + Service Account | ⭐⭐⭐⭐⭐ | op read | Yes |
| userEnvProbe (dynamic injection) | ⭐⭐⭐⭐ | $VARIABLE | Moderate |
| .env.op files | ⭐⭐⭐ | $VARIABLE | Yes |
| Container env vars (hardcoded) | ⭐ | $VARIABLE | No |

---

## 6. Performance Optimization

### Startup Time Breakdown

**Typical DevPod startup times:**

| Scenario | Time | Optimization |
|----------|------|---------------|
| Fresh Nix flake build | 30-60 min | Use pre-built images (Approach B) |
| Cached Nix evaluation | 2-5 min | Volume mount /nix/store |
| Pre-built Docker image | 10-30 sec | Commit image to registry |
| npm/pip install | 1-3 min | Layer caching in Dockerfile |
| Dotfiles installation | 5-30 sec | Keep scripts fast |

### Caching Strategies

**Volume mounts for persistent cache:**

```json
{
  "mounts": [
    "source=/nix/store,target=/nix/store,type=bind,consistency=delegated",
    "source=.cache/pip,target=/root/.cache/pip,type=bind"
  ]
}
```

**Or use named volumes (Docker-managed):**

```json
{
  "mounts": [
    "source=dev-config-nix-store,target=/nix/store,type=volume"
  ]
}
```

### Feature Performance

Install only needed features - each adds overhead:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/nix:1": {},
    // SKIP docker-in-docker if not needed
    // SKIP gh-cli if not needed
  }
}
```

### Parallel Execution

Use object format for `postCreateCommand` to run tasks in parallel:

```json
{
  "postCreateCommand": {
    "nix_flake": "nix flake update",
    "npm_deps": "npm ci",
    "pip_deps": "pip install -r requirements.txt"
  }
}
```

**Runs all three simultaneously instead of sequentially.**

---

## 7. Known Pitfalls & Solutions

### Pitfall 1: Dotfiles Overwrite postCreateCommand Changes

**Problem:** You configure shell in `postCreateCommand`, then dotfiles overwrites it.

**Solution:** Move shell/plugin config to `postStartCommand` or dotfiles script itself.

```json
{
  "postCreateCommand": "apt-get update && apt-get install -y zsh",  // System pkg OK
  "postStartCommand": "source ~/.zshrc && p10k configure"           // Shell config here
}
```

### Pitfall 2: Nix Flake Evaluation in Container Takes Hours

**Problem:** First container startup hangs for hours evaluating Nix flake.

**Solution:** Pre-build Docker image with flake evaluation cached, or use pre-built base images:

```json
{
  "image": "ghcr.io/samuelho-dev/dev-config:nix-prebuilt"
}
```

### Pitfall 3: Root-Owned Files Break User Permissions

**Problem:** Dotfiles runs as root → files owned by root → user can't write.

**Workaround:** Ensure dotfiles script explicitly fixes ownership:

```bash
#!/bin/bash
# In your install.sh
chown -R ${USER}:${USER} $HOME/.config
chown -R ${USER}:${USER} $HOME/.local
```

Or ensure script runs as remoteUser (not root).

### Pitfall 4: remoteEnv Variables Not Passing to Subshells

**Problem:** `remoteEnv` set in devcontainer.json but not available in shell subprocess.

**Solution:** Explicitly export in shell initialization:

```bash
# In ~/.bashrc or ~/.zshrc
export $(op read "op://Dev/ai/ANTHROPIC_API_KEY")
```

Or set in `containerEnv` instead of `remoteEnv` if containers don't support it.

### Pitfall 5: 1Password CLI Timeout in Container

**Problem:** `op read` times out waiting for authentication in headless container.

**Solution:** Use Service Account token instead of user auth:

```bash
export OP_SERVICE_ACCOUNT_TOKEN=ops_...
op run --env-file .env.op -- bash
```

### Pitfall 6: direnv Not Auto-Activating in Containers

**Problem:** `.envrc` with `use flake` not loaded when entering container directory.

**Solution:** Explicitly allow in `postCreateCommand`:

```json
{
  "postCreateCommand": "cd /workspaces/dev-config && direnv allow && direnv reload"
}
```

---

## 8. Implementation Recommendations for dev-config

### Recommended Architecture

```
.devcontainer/
├── devcontainer.json          # Main config
├── Dockerfile.devpod          # Optional: pre-built image
└── load-secrets.sh            # 1Password integration

devcontainer.json structure:
{
  "name": "dev-config-remote",

  // Base image with Nix support
  "image": "ghcr.io/samuelho-dev/dev-config:nix-latest",

  // System packages
  "features": {
    "ghcr.io/devcontainers/features/nix:1": {
      "extraNixConfig": "experimental-features = nix-command flakes"
    },
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  },

  // Initial setup (system tools, Nix evaluation)
  "onCreateCommand": "cd /workspaces/dev-config && nix flake update",

  // Installation (repo-specific)
  "postCreateCommand": "cd /workspaces/dev-config && nix run .#activate",

  // Personalization (runs AFTER dotfiles)
  "postStartCommand": "source ~/.zshrc && direnv reload",

  // Secrets
  "remoteEnv": {
    "OP_SERVICE_ACCOUNT_TOKEN": "${localEnv:OP_SERVICE_ACCOUNT_TOKEN}"
  },

  // VS Code
  "customizations": {
    "vscode": {
      "extensions": [
        "jnoortheen.nix-ide",
        "ms-vscode.remote-containers"
      ]
    }
  }
}
```

### DevPod Creation Command

```bash
# One-time context setup
devpod context set-options \
  -o DOTFILES_URL=https://github.com/samuelho-dev/dev-config \
  -o DOTFILES_SCRIPT=scripts/install.sh

# Create workspace (dotfiles applied automatically)
devpod up https://github.com/<workspace-repo>
```

### Dotfiles Script Adjustments for DevPod

Current `scripts/install.sh` works, but optimize for containers:

```bash
#!/bin/bash
# scripts/install.sh (DevPod-optimized)

set -euo pipefail

source scripts/lib/common.sh
source scripts/lib/paths.sh

# In container, detect environment
if [ -f /.dockerenv ]; then
  log_info "Running in container (DevPod)"
  # Skip certain package managers (Docker has them)
  SKIP_BREW=1
else
  log_info "Running on bare metal"
fi

# Continue with standard installation...
```

### Secrets Loading in Container

Add to `scripts/install.sh`:

```bash
# Load 1Password secrets
if command -v op &> /dev/null; then
  log_info "1Password CLI found, loading secrets..."
  eval "$(op signin)" || log_warn "1Password auth failed - proceeding without secrets"
  source scripts/load-ai-credentials.sh || log_warn "AI credentials not available"
else
  log_warn "1Password CLI not installed - AI credentials not available"
fi
```

### GitHub Actions Integration (CI/CD)

```yaml
# .github/workflows/devpod-build.yml
name: DevPod Build

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build DevPod Image
        run: |
          docker build \
            -f .devcontainer/Dockerfile.devpod \
            -t ghcr.io/samuelho-dev/dev-config:nix-latest \
            .

      - name: Push to Registry
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push ghcr.io/samuelho-dev/dev-config:nix-latest
```

---

## 9. VS Code Remote Containers Compatibility

DevPod uses the **open Dev Container specification**, which is 100% compatible with:
- VS Code Remote - Containers extension
- GitHub Codespaces
- Other devcontainer-compatible tools

**No special handling required** - same `devcontainer.json` works everywhere.

**Additional VS Code features available:**
- `devContainerUrl` - Deep link to open in remote container
- `remoteEnv` - VS Code-specific environment variables
- Custom bash/zsh in integrated terminal
- Extensions auto-installed with `-extensionsToInstall`

---

## 10. Testing & Validation

### Local Testing Before DevPod

```bash
# Build devcontainer locally
devcontainer build --image-name dev-config-test:latest

# Test the image
devcontainer up --image-name dev-config-test:latest

# Verify inside container
devcontainer exec bash -c "nix --version && zsh --version"
```

### Debugging Failed Startup

```bash
# View container logs
devpod logs <workspace-id>

# SSH into running container
devpod ssh <workspace-id>

# Inspect devcontainer.json
devpod inspect <workspace-id>
```

### Performance Profiling

```bash
# Time container startup
time devpod up <workspace-repo>

# Check layer caching
docker history ghcr.io/samuelho-dev/dev-config:latest
```

---

## 11. Migration Path (Phased Approach)

### Phase 1: Current Setup (Proven)
- Manual installation: `bash scripts/install.sh`
- Works on macOS and Linux
- Local development only

### Phase 2: DevContainer Support (Next)
- Add `.devcontainer/devcontainer.json`
- Reuse existing `scripts/install.sh`
- Support VS Code Remote Containers
- No breaking changes to local workflow

### Phase 3: Nix-Based DevPod (Advanced)
- Pre-built Docker image with Nix cached
- 10-30 second startup instead of hours
- Full CI/CD integration
- Optional: Chezmoi-based dotfiles

### Phase 4: Enterprise Integration (Future)
- 1Password Service Accounts
- Kubernetes support (DevPod on K8s)
- Team-wide Cachix caching
- Terraform for infrastructure as code

---

## Summary: Quick Reference

| Aspect | Recommendation | Rationale |
|--------|---|---|
| **Base Image** | `mcr.microsoft.com/devcontainers/base:debian` | Lightweight, Nix-compatible |
| **Nix Setup** | Feature `ghcr.io/devcontainers/features/nix:1` | Official, well-maintained |
| **postCreateCommand** | `nix run .#activate` | Reuses existing flake.nix |
| **Dotfiles** | DevPod `--dotfiles` flag | Native support, no config needed |
| **Secrets** | 1Password Service Accounts | Most secure for remote |
| **Performance** | Pre-built image or volume caching | Startup time critical |
| **Testing** | VS Code Remote Containers first | Same spec as DevPod |

---

## Resources

- **DevPod Docs:** https://devpod.sh/docs
- **Dev Container Spec:** https://containers.dev
- **VS Code Remote Containers:** https://code.visualstudio.com/docs/devcontainers/containers
- **1Password CLI:** https://developer.1password.com/docs/cli
- **Nix Flakes:** https://wiki.nixos.org/wiki/Flakes
- **direnv + Nix:** https://nix.dev/guides/recipes/direnv.html
