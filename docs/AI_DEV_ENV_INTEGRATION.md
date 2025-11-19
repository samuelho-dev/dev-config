# ai-dev-env Integration Guide

## ✅ Automation Complete

**The integration is now fully automated!** No manual steps required.

**What's Automated:**
1. ✅ **dev-config/flake.nix** - Exports modular NixOS + Home Manager modules
2. ✅ **dev-config/.github/workflows/build-devpod-image.yml** - Auto-builds DevPod images on every commit
3. ✅ **ai-dev-env/flake.nix** - Imports dev-config modules automatically
4. ✅ **ai-dev-env DevPod Helm chart** - Uses pre-built dev-config images

**Result:**
- DevPod images built automatically (GitHub Actions)
- Pushed to ghcr.io/samuelho-dev/dev-config-devpod:latest
- ai-dev-env Helm chart pulls latest image automatically
- Zero manual intervention required

## Overview

This guide explains the automated integration between dev-config and ai-dev-env.

**Architecture:**
- **dev-config**: Single source of truth for developer tooling (Neovim, tmux, zsh, OpenCode, 1Password)
- **ai-dev-env**: Infrastructure and Kubernetes configurations (ArgoCD, networking, monitoring)

## Phase 1: Update ai-dev-env flake.nix

### Step 1.1: Add dev-config as Input

Create or update `ai-dev-env/flake.nix`:

```nix
{
  description = "AI Development Environment Infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Import dev-config (single source of truth for dev tools)
    dev-config = {
      url = "github:samuelho-dev/dev-config";
      # During development, use local path:
      # url = "path:/Users/samuelho/Projects/dev-config";
    };
  };

  outputs = { self, nixpkgs, dev-config, ... }: {
    # NixOS configurations (for bare metal servers)
    nixosConfigurations = {
      production-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import dev-config module for developer tools
          dev-config.nixosModules.dev-config

          # Your infrastructure-specific configuration
          ./infrastructure/nix/configuration.nix
        ];
      };
    };

    # DevPod container images
    packages.x86_64-linux = {
      # Option 1: Use dev-config image directly
      devpod-image = dev-config.packages.x86_64-linux.devpod-image;

      # Option 2: Extend with ai-dev-env specific tools
      devpod-custom =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          baseImage = dev-config.packages.x86_64-linux.devpod-image;
        in
        pkgs.dockerTools.buildLayeredImage {
          name = "ghcr.io/samuelho-dev/ai-dev-env-devpod";
          tag = "latest";
          fromImage = baseImage;

          # Add ai-dev-env specific tools on top of dev-config base
          contents = with pkgs; [
            kubectl
            kubernetes-helm
            argocd
            k9s
          ];

          # Inherit config from base image
          config = {
            Cmd = [ "/bin/zsh" ];
            Env = [
              "PATH=/bin:/usr/bin"
              "HOME=/home/vscode"
              "SHELL=/bin/zsh"
            ];
            User = "vscode";
            WorkingDir = "/workspace";
          };
        };
    };
  };
}
```

### Step 1.2: Update flake.lock

```bash
cd ~/Projects/ai-dev-env

# Add dev-config input (if using local path during development)
nix flake lock --override-input dev-config path:/Users/samuelho/Projects/dev-config

# Or update to use GitHub (for production)
nix flake lock --override-input dev-config github:samuelho-dev/dev-config

# Commit the lock file
git add flake.nix flake.lock
git commit -m "feat: integrate dev-config for developer tooling"
```

## Phase 2: Remove Duplicated Nix Modules

### Step 2.1: Identify Modules to Remove

**Remove these (now provided by dev-config):**

```bash
cd ~/Projects/ai-dev-env

# List modules that will be removed
find infrastructure/nix/modules/programs/ -name "*.nix" -o -name "*.toml"
find infrastructure/nix/modules/packages/ -name "*.nix"

# Expected output:
# infrastructure/nix/modules/programs/neovim.nix
# infrastructure/nix/modules/programs/tmux.nix
# infrastructure/nix/modules/programs/zsh/
# infrastructure/nix/modules/packages/base.nix
# infrastructure/nix/modules/packages/cli-tools.nix
```

### Step 2.2: Remove Duplicate Modules

```bash
cd ~/Projects/ai-dev-env

# Remove duplicated program configurations
git rm -r infrastructure/nix/modules/programs/neovim.nix || true
git rm -r infrastructure/nix/modules/programs/tmux.nix || true
git rm -r infrastructure/nix/modules/programs/zsh/ || true

# Remove duplicated package lists
git rm -r infrastructure/nix/modules/packages/base.nix || true
git rm -r infrastructure/nix/modules/packages/cli-tools.nix || true

# Commit removal
git commit -m "refactor: remove duplicated modules (now in dev-config)

Removed modules:
- programs/neovim.nix
- programs/tmux.nix
- programs/zsh/
- packages/base.nix
- packages/cli-tools.nix

These are now provided by dev-config flake import."
```

### Step 2.3: Keep Infrastructure-Specific Modules

**Keep these (infrastructure-specific to ai-dev-env):**

```
infrastructure/nix/modules/
├── kubernetes/           # ✅ KEEP
├── argocd/              # ✅ KEEP
├── networking/          # ✅ KEEP
├── monitoring/          # ✅ KEEP
└── tailscale/           # ✅ KEEP
```

## Phase 3: Update DevPod Helm Chart

### Step 3.1: Update values.yaml

```yaml
# deploy/helm/charts/applications/ai-dev-env/values.yaml

devpod:
  enabled: true

  # Use pre-built image from dev-config
  image:
    repository: ghcr.io/samuelho-dev/dev-config-devpod
    tag: latest  # Or specific SHA: abc123...
    pullPolicy: Always

  # Image pull secret for GHCR
  imagePullSecrets:
    - name: ghcr-pull-secret

  # Init container: Apply dotfiles via Chezmoi
  initContainers:
    - name: dotfiles
      image: ghcr.io/twpayne/chezmoi:latest
      command:
        - /bin/sh
        - -c
        - |
          echo "📦 Applying dotfiles from dev-config..."
          chezmoi init --apply https://github.com/samuelho-dev/dev-config

          echo "✅ Dotfiles applied!"
          ls -la /home/vscode/Projects/dev-config
      volumeMounts:
        - name: home
          mountPath: /home/vscode
      env:
        - name: HOME
          value: /home/vscode

  # Main container (all tools pre-installed in image!)
  containers:
    - name: devpod
      command: ["/bin/zsh"]
      tty: true
      stdin: true

      # Environment variables
      env:
        # direnv auto-activation
        - name: DIRENV_LOG_FORMAT
          value: ""

        # Workspace directory
        - name: WORKSPACE
          value: /workspace

      # Volume mounts
      volumeMounts:
        - name: home
          mountPath: /home/vscode
        - name: workspace
          mountPath: /workspace

      # Resource limits
      resources:
        requests:
          memory: "2Gi"
          cpu: "1000m"
        limits:
          memory: "8Gi"
          cpu: "4000m"

  # Persistent volumes
  persistence:
    home:
      enabled: true
      size: 10Gi
      storageClass: do-block-storage
      mountPath: /home/vscode

    workspace:
      enabled: true
      size: 50Gi
      storageClass: do-block-storage
      mountPath: /workspace
```

### Step 3.2: Create Image Pull Secret

```bash
# Create GHCR pull secret
kubectl create secret docker-registry ghcr-pull-secret \
  --docker-server=ghcr.io \
  --docker-username=samuelho-dev \
  --docker-password="$GITHUB_TOKEN" \
  --docker-email=samuelho.dev@gmail.com \
  --namespace=ai-dev-env-dev

# Or use sealed-secrets
cat <<EOF | kubeseal --format=yaml > deploy/secrets/dev/ghcr-pull-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ghcr-pull-secret
  namespace: ai-dev-env-dev
type: kubernetes.io/dockerconfigjson
stringData:
  .dockerconfigjson: |
    {
      "auths": {
        "ghcr.io": {
          "username": "samuelho-dev",
          "password": "$GITHUB_TOKEN",
          "email": "samuelho.dev@gmail.com"
        }
      }
    }
EOF
```

## Phase 4: Build and Push DevPod Image

### Step 4.1: Build Image Locally (Optional Testing)

```bash
cd ~/Projects/dev-config

# Build the image
nix build .#devpod-image

# Load into Docker
docker load < result

# Test locally
docker run -it --rm ghcr.io/samuelho-dev/dev-config-devpod:latest

# Inside container, verify tools:
nvim --version
tmux -V
opencode --version
op --version
```

### Step 4.2: Push Image via GitHub Actions

```bash
cd ~/Projects/dev-config

# Push changes to trigger build
git add flake.nix .github/workflows/build-devpod-image.yml
git commit -m "feat: add pre-built DevPod image with buildLayeredImage"
git push origin main

# GitHub Actions will:
# 1. Build image with Nix
# 2. Push to ghcr.io/samuelho-dev/dev-config-devpod:latest
# 3. Tag with commit SHA for rollback
```

### Step 4.3: Verify Image on GHCR

```bash
# Pull the image
docker pull ghcr.io/samuelho-dev/dev-config-devpod:latest

# Inspect layers (should see ~50-100 layers for optimal caching)
docker history ghcr.io/samuelho-dev/dev-config-devpod:latest | wc -l

# Run and test
docker run -it --rm ghcr.io/samuelho-dev/dev-config-devpod:latest zsh -c "
  echo 'Testing installed tools...'
  nvim --version && echo '✅ Neovim'
  tmux -V && echo '✅ tmux'
  git --version && echo '✅ git'
  opencode --version && echo '✅ OpenCode'
  op --version && echo '✅ 1Password CLI'
"
```

## Phase 5: Deploy and Test

### Step 5.1: Deploy to Dev Environment

```bash
cd ~/Projects/ai-dev-env

# Update Helm values to use new image
# (Already done in Phase 3)

# Deploy via ArgoCD
argocd app sync ai-dev-env-dev --prune

# Or deploy directly
helm upgrade --install ai-dev-env-dev \
  deploy/helm/charts/applications/ai-dev-env \
  -f deploy/helm/charts/applications/ai-dev-env/values-dev.yaml \
  --namespace ai-dev-env-dev
```

### Step 5.2: Verify DevPod Functionality

```bash
# Check pod status
kubectl get pods -n ai-dev-env-dev -l app=devpod

# Exec into pod
kubectl exec -it -n ai-dev-env-dev \
  $(kubectl get pod -n ai-dev-env-dev -l app=devpod -o name) \
  -- zsh

# Inside pod, verify:
# 1. All tools installed
nvim --version
tmux -V
opencode --version
op --version

# 2. Dotfiles symlinked
ls -la ~/.config/nvim  # Should be symlink to ~/Projects/dev-config/nvim

# 3. direnv working
cd ~/Projects/dev-config
# Should see: "🔐 Loading AI credentials from 1Password..."

# 4. 1Password integration (if authenticated)
op account get
```

### Step 5.3: Performance Benchmarks

**Measure pod startup time:**

```bash
# Delete pod to force restart
kubectl delete pod -n ai-dev-env-dev -l app=devpod

# Time until ready
time kubectl wait --for=condition=Ready pod \
  -n ai-dev-env-dev \
  -l app=devpod \
  --timeout=5m
```

**Expected results:**
- **Before (runtime installation)**: 5-10 minutes
- **After (pre-built image)**: 30-60 seconds

## Phase 6: Rollback Plan

### If Issues Occur

**Option 1: Use specific image tag**

```yaml
# values.yaml
devpod:
  image:
    tag: abc123...  # Use previous working SHA
```

**Option 2: Revert to legacy modules**

```bash
cd ~/Projects/ai-dev-env

# Revert the commit that removed modules
git revert <commit-hash>

# Restore duplicated modules
git push origin main
```

**Option 3: Use local dev-config**

```bash
# In ai-dev-env flake.nix
nix flake lock --override-input dev-config path:/Users/samuelho/Projects/dev-config

# Test locally before pushing
```

## Success Criteria

- ✅ DevPod starts in < 1 minute
- ✅ All dev-config tools available (nvim, tmux, opencode, op)
- ✅ Dotfiles applied correctly (symlinks working)
- ✅ direnv auto-activates in ~/Projects/dev-config
- ✅ 1Password credentials load (if authenticated)
- ✅ No duplicated Nix modules in ai-dev-env
- ✅ Image builds in CI/CD (<10 minutes)
- ✅ Image layers properly cached (50-100 layers)

## Troubleshooting

### Image Pull Failures

```bash
# Check image pull secret
kubectl get secret ghcr-pull-secret -n ai-dev-env-dev -o yaml

# Test credentials
docker login ghcr.io -u samuelho-dev --password-stdin <<< "$GITHUB_TOKEN"
docker pull ghcr.io/samuelho-dev/dev-config-devpod:latest
```

### Dotfiles Not Applied

```bash
# Check init container logs
kubectl logs -n ai-dev-env-dev \
  $(kubectl get pod -n ai-dev-env-dev -l app=devpod -o name) \
  -c dotfiles

# Manually test chezmoi
kubectl exec -it -n ai-dev-env-dev \
  $(kubectl get pod -n ai-dev-env-dev -l app=devpod -o name) \
  -- chezmoi init --apply https://github.com/samuelho-dev/dev-config
```

### Tools Not Found

```bash
# Verify image contents
docker run --rm ghcr.io/samuelho-dev/dev-config-devpod:latest ls -la /bin

# Check PATH
kubectl exec -it -n ai-dev-env-dev \
  $(kubectl get pod -n ai-dev-env-dev -l app=devpod -o name) \
  -- env | grep PATH
```

## Next Steps

After successful integration:

1. **Update Documentation**: Update ai-dev-env README with new architecture
2. **Team Rollout**: Deploy to staging, then production
3. **Monitor**: Set up alerts for DevPod startup failures
4. **Optimize**: Reduce image size if needed (currently ~2GB)
5. **Expand**: Add more ai-dev-env specific tools to custom image

## References

- [dev-config flake.nix](../flake.nix)
- [Nix Docker Tools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools)
- [buildLayeredImage Documentation](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix)
- [Chezmoi Documentation](https://www.chezmoi.io/)
