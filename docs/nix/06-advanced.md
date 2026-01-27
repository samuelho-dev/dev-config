# Advanced Customization Guide

## Overview

This guide covers advanced Nix techniques for customizing and extending your dev-config environment beyond the basics.

**Prerequisites:**
- Completed initial setup ([Quick Start](00-quickstart.md))
- Familiarity with Nix concepts ([Concepts Guide](01-concepts.md))
- Understanding of daily workflows ([Daily Usage](02-daily-usage.md))

## Package Customization

### Overriding Package Versions

**Pin specific package version:**

```nix
# flake.nix
{
  outputs = { self, nixpkgs }: {
    devShells = forAllSystems ({ pkgs, ... }: {
      default = pkgs.mkShell {
        packages = [
          # Override Neovim version
          (pkgs.neovim.override {
            viAlias = true;
            vimAlias = true;
          })

          # Pin specific version via override
          (pkgs.nodejs.overrideAttrs (old: rec {
            version = "20.11.0";
            src = pkgs.fetchurl {
              url = "https://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
              sha256 = "sha256-...";  # Get from nixpkgs
            };
          }))
        ];
      };
    });
  };
}
```

### Using Overlays

**Create custom package modifications:**

```nix
# flake.nix
{
  outputs = { self, nixpkgs }: {
    # Define overlay
    overlays = {
      default = final: prev: {
        # Customize Neovim with specific plugins
        neovim-custom = prev.neovim.override {
          configure = {
            customRC = ''
              " Custom Neovim config
              set number relativenumber
            '';
          };
        };

        # Add completely custom package
        my-dev-tool = prev.callPackage ./pkgs/my-dev-tool {};
      };
    };

    # Apply overlay to devShell
    devShells = forAllSystems ({ pkgs, system }: {
      default = let
        pkgs-custom = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in pkgs-custom.mkShell {
        packages = with pkgs-custom; [
          neovim-custom  # Uses overlay version
          my-dev-tool    # Custom package
        ];
      };
    });
  };
}
```

### Building Custom Derivations

**Create pkgs/my-dev-tool/default.nix:**

```nix
{ pkgs, lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "my-dev-tool";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "yourname";
    repo = "my-dev-tool";
    rev = "v${version}";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pkgs.bash pkgs.jq pkgs.curl ];

  installPhase = ''
    mkdir -p $out/bin
    cp my-tool.sh $out/bin/my-tool
    chmod +x $out/bin/my-tool

    wrapProgram $out/bin/my-tool \
      --prefix PATH : ${lib.makeBinPath [ pkgs.jq pkgs.curl ]}
  '';

  meta = {
    description = "My custom development tool";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
```

**Use in flake.nix:**

```nix
packages = [
  (pkgs.callPackage ./pkgs/my-dev-tool {})
];
```

## Advanced Environment Configuration

### Multiple Development Shells

**Create environment-specific shells:**

```nix
# flake.nix
{
  outputs = { self, nixpkgs }: {
    devShells = forAllSystems ({ pkgs, ... }: {
      # Default shell (general development)
      default = pkgs.mkShell {
        packages = [ pkgs.git pkgs.neovim pkgs.tmux ];
      };

      # Python development shell
      python = pkgs.mkShell {
        packages = [
          pkgs.python311
          pkgs.python311Packages.pip
          pkgs.python311Packages.virtualenv
          pkgs.python311Packages.pytest
          pkgs.poetry
        ];
        shellHook = ''
          echo "🐍 Python development environment"
          python --version
        '';
      };

      # Node.js development shell
      nodejs = pkgs.mkShell {
        packages = [
          pkgs.nodejs_20
          pkgs.nodePackages.npm
          pkgs.nodePackages.pnpm
          pkgs.nodePackages.typescript
        ];
        shellHook = ''
          echo "📦 Node.js development environment"
          node --version
          npm --version
        '';
      };

      # Kubernetes ops shell
      k8s = pkgs.mkShell {
        packages = [
          pkgs.kubectl
          pkgs.kubernetes-helm
          pkgs.k9s
          pkgs.argocd
        ];
        shellHook = ''
          echo "☸️  Kubernetes operations environment"
          kubectl version --client
        '';
      };
    });
  };
}
```

**Usage:**
```bash
# Default shell
nix develop

# Python shell
nix develop .#python

# Node.js shell
nix develop .#nodejs

# Kubernetes shell
nix develop .#k8s
```

### Environment-Specific .envrc

**Create .envrc.python:**
```bash
use flake .#python
export PYTHONPATH="$PWD/src:$PYTHONPATH"
```

**Create .envrc.nodejs:**
```bash
use flake .#nodejs
export NODE_ENV=development
```

**Switch environments:**
```bash
# Link to desired environment
ln -sf .envrc.python .envrc
direnv allow

# Later, switch to Node.js
ln -sf .envrc.nodejs .envrc
direnv reload
```

## Integration with ai-dev-env

### Exporting Modules for Reuse

**Add to flake.nix outputs:**

```nix
{
  outputs = { self, nixpkgs }: {
    # Export for use in other flakes
    nixosModules = {
      dev-config = { config, pkgs, ... }: {
        imports = [
          ./modules/neovim.nix
          ./modules/tmux.nix
          ./modules/zsh.nix
        ];
      };
    };

    homeManagerModules = {
      dev-config = { config, pkgs, ... }: {
        home.packages = [
          pkgs.neovim pkgs.tmux pkgs.zsh
          pkgs.fzf pkgs.ripgrep pkgs.fd pkgs.bat pkgs.lazygit
        ];

        programs.neovim = {
          enable = true;
          defaultEditor = true;
          configure = {
            customRC = builtins.readFile ./nvim/init.lua;
          };
        };
      };
    };
  };
}
```

### Importing in ai-dev-env

**In ai-dev-env/flake.nix:**

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    dev-config.url = "github:samuelho-dev/dev-config";
  };

  outputs = { self, nixpkgs, dev-config }: {
    nixosConfigurations.my-server = nixpkgs.lib.nixosSystem {
      modules = [
        dev-config.nixosModules.dev-config  # Import dev-config module
        ./configuration.nix
      ];
    };

    homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
      modules = [
        dev-config.homeManagerModules.dev-config  # Import for home-manager
        ./home.nix
      ];
    };
  };
}
```

### Shared Package Sets

**Create shared-packages.nix:**

```nix
{ pkgs }:

[
  # Core development tools
  pkgs.git pkgs.gh pkgs.lazygit pkgs.gitmux
  pkgs.neovim pkgs.tmux pkgs.zsh

  # CLI utilities
  pkgs.fzf pkgs.ripgrep pkgs.fd pkgs.bat pkgs.eza
  pkgs.jq pkgs.yq-go
  pkgs.htop pkgs.btop

  # Language tools
  pkgs.nodejs_20 pkgs.python311 pkgs.go

  # Container tools
  pkgs.docker pkgs.kubectl pkgs.kubernetes-helm

  # CLI tools
  pkgs._1password-cli
]
```

**Import in multiple flakes:**

```nix
# flake.nix
{
  packages = (import ./shared-packages.nix { inherit pkgs; });
}
```

## Advanced Nix Apps

### Custom Activation Scripts

**Create apps/setup-work.nix:**

```nix
{ pkgs, lib }:

pkgs.writeShellApplication {
  name = "setup-work";

  runtimeInputs = [ pkgs.git pkgs.gh pkgs.openssh ];

  text = ''
    echo "🔧 Setting up work environment..."

    # Configure work-specific git
    git config --global user.email "work@company.com"
    git config --global user.name "Your Name"

    # Clone work repositories
    mkdir -p ~/work
    cd ~/work

    if [ ! -d "company-repo" ]; then
      gh repo clone company/company-repo
    fi

    # Setup SSH keys for work
    if [ ! -f ~/.ssh/work_id_ed25519 ]; then
      ssh-keygen -t ed25519 -f ~/.ssh/work_id_ed25519 -C "work@company.com"
      echo "✅ Created work SSH key: ~/.ssh/work_id_ed25519.pub"
      echo "📋 Add this key to your GitHub account"
    fi

    echo "✅ Work environment ready!"
  '';
}
```

**Add to flake.nix:**

```nix
{
  apps = forAllSystems ({ pkgs, ... }: {
    setup-work = {
      type = "app";
      program = "${import ./apps/setup-work.nix { inherit pkgs lib; }}/bin/setup-work";
    };
  });
}
```

**Usage:**
```bash
nix run .#setup-work
```

### Multi-Step Deployment App

**Create apps/deploy.nix:**

```nix
{ pkgs, lib }:

pkgs.writeShellApplication {
  name = "deploy";

  runtimeInputs = [ pkgs.git pkgs.kubectl pkgs.argocd ];

  text = ''
    set -euo pipefail

    ENVIRONMENT="''${1:-dev}"

    echo "🚀 Deploying to $ENVIRONMENT..."

    # Step 1: Run tests
    echo "🧪 Running tests..."
    nix flake check

    # Step 2: Build application
    echo "🔨 Building application..."
    nix build .#apps.my-app

    # Step 3: Push to container registry
    echo "📦 Pushing to registry..."
    docker load < result
    docker tag my-app:latest ghcr.io/user/my-app:$ENVIRONMENT
    docker push ghcr.io/user/my-app:$ENVIRONMENT

    # Step 4: Update Kubernetes
    echo "☸️  Updating Kubernetes..."
    kubectl set image deployment/my-app \
      my-app=ghcr.io/user/my-app:$ENVIRONMENT \
      -n $ENVIRONMENT

    # Step 5: Sync ArgoCD
    echo "🔄 Syncing ArgoCD..."
    argocd app sync my-app-$ENVIRONMENT --prune

    echo "✅ Deployment to $ENVIRONMENT complete!"
  '';
}
```

**Usage:**
```bash
nix run .#deploy dev     # Deploy to dev
nix run .#deploy staging # Deploy to staging
nix run .#deploy prod    # Deploy to prod
```

## Advanced direnv Patterns

### Project-Specific Credentials

**Create .envrc.local (gitignored):**

```bash
# Machine-specific or secret configuration
export AWS_PROFILE=personal
export DATABASE_URL=postgresql://localhost/mydb
export API_KEY=$(op read "op://Personal/project-x/api-key")

# Project-specific tool versions
export NODE_VERSION=20.11.0
export PYTHON_VERSION=3.11.7
```

**Update .envrc:**

```bash
use flake

# Load project-specific secrets (if exists)
if [ -f .envrc.local ]; then
  source_env .envrc.local
fi

# Load AI credentials from 1Password
if command -v op &>/dev/null && op account get &>/dev/null 2>&1; then
  source_env scripts/load-ai-credentials.sh
fi
```

### Multi-Project Layout Detection

**Create smart .envrc:**

```bash
# Auto-detect project type
if [ -f "package.json" ]; then
  use flake .#nodejs
  layout node
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  use flake .#python
  layout python
elif [ -f "Cargo.toml" ]; then
  use flake .#rust
  layout rust
else
  use flake  # Default environment
fi

# Set project root
export PROJECT_ROOT=$PWD

# Load .env file if exists
dotenv_if_exists .env

# Load AI credentials
if op account get &>/dev/null 2>&1; then
  source_env scripts/load-ai-credentials.sh
fi
```

### Nested Directory Environments

**Root .envrc:**
```bash
use flake
export REPO_ROOT=$PWD
```

**backend/.envrc:**
```bash
source_up  # Inherit from parent
use flake .#python
export BACKEND_PORT=8000
```

**frontend/.envrc:**
```bash
source_up  # Inherit from parent
use flake .#nodejs
export FRONTEND_PORT=3000
```

**Result:**
- `~/project/` - Base environment
- `~/project/backend/` - Python + base environment
- `~/project/frontend/` - Node.js + base environment

## Custom Binary Caches

### Setting Up Private Cachix

**1. Create Cachix cache:**
```bash
cachix create my-team
```

**2. Generate auth token:**
```bash
cachix authtoken create my-team-ci
# Save token as GitHub Secret: CACHIX_AUTH_TOKEN
```

**3. Update flake.nix:**
```nix
{
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://my-team.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "my-team.cachix.org-1:YOUR_PUBLIC_KEY_HERE"
    ];
  };
}
```

**4. Push to cache (CI/CD):**
```yaml
# .github/workflows/build.yml
- uses: cachix/cachix-action@v14
  with:
    name: my-team
    authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

- run: |
    nix build .#devShells.x86_64-darwin.default
    nix build .#devShells.x86_64-linux.default
```

### Self-Hosted Binary Cache (S3)

**1. Configure Nix to use S3:**
```nix
# ~/.config/nix/nix.conf
substituters = https://cache.nixos.org s3://my-nix-cache?region=us-east-1
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= my-cache-1:YOUR_KEY_HERE
```

**2. Push to S3 cache:**
```bash
# Build and sign
nix build .#myPackage
nix store sign --key-file /path/to/cache-key.sec $(readlink -f result)

# Push to S3
nix copy --to 's3://my-nix-cache?region=us-east-1' $(readlink -f result)
```

**3. Generate cache keys:**
```bash
nix-store --generate-binary-cache-key my-cache /etc/nix/cache-key.sec /etc/nix/cache-key.pub
```

## Flake Templates

### Creating Reusable Templates

**Create templates/python/flake.nix:**

```nix
{
  description = "Python development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: {
    devShells = forAllSystems ({ pkgs, ... }: {
      default = pkgs.mkShell {
        packages = [
          pkgs.python311
          pkgs.python311Packages.pip
          pkgs.python311Packages.virtualenv
          pkgs.poetry
          pkgs.ruff
        ];

        shellHook = ''
          echo "🐍 Python ${pkgs.python311.version}"

          # Create virtualenv if doesn't exist
          if [ ! -d .venv ]; then
            python -m venv .venv
            echo "✅ Created .venv"
          fi

          source .venv/bin/activate
        '';
      };
    });
  };
}
```

**Export template in main flake.nix:**

```nix
{
  templates = {
    python = {
      path = ./templates/python;
      description = "Python development environment with virtualenv";
    };

    nodejs = {
      path = ./templates/nodejs;
      description = "Node.js development environment with pnpm";
    };

    rust = {
      path = ./templates/rust;
      description = "Rust development environment with cargo";
    };
  };
}
```

**Usage:**
```bash
# Initialize new Python project
mkdir my-python-project
cd my-python-project
nix flake init -t github:samuelho-dev/dev-config#python

# Initialize new Node.js project
nix flake init -t github:samuelho-dev/dev-config#nodejs
```

## Testing and CI/CD

### Pre-Commit Hooks with Nix

**Add to flake.nix:**

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, nixpkgs, pre-commit-hooks }: {
    checks = forAllSystems ({ pkgs, system, ... }: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          nixpkgs-fmt.enable = true;
          shellcheck.enable = true;
          gitleaks.enable = true;

          # Custom hook
          sync-docs = {
            enable = true;
            name = "Sync documentation";
            entry = toString (pkgs.writeShellScript "sync-docs" ''
              ${pkgs.nodePackages.markdown-link-check}/bin/markdown-link-check docs/**/*.md
            '');
            files = "\\.md$";
          };
        };
      };
    });

    devShells = forAllSystems ({ pkgs, system, ... }: {
      default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
      };
    });
  };
}
```

### Multi-Platform Builds

**Build for all platforms in CI:**

```yaml
# .github/workflows/build.yml
name: Build All Platforms

on: [push, pull_request]

jobs:
  build-matrix:
    strategy:
      matrix:
        os:
          - ubuntu-latest
          - macos-13      # Intel
          - macos-14      # Apple Silicon
    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - uses: DeterminateSystems/nix-installer-action@main

      - uses: DeterminateSystems/magic-nix-cache-action@main

      - name: Build devShell
        run: |
          nix build .#devShells.$(nix eval --raw .#currentSystem).default --print-build-logs

      - name: Run tests
        run: |
          nix develop --command bash scripts/validate.sh
```

## Performance Tuning

### Parallel Builds

**Configure in ~/.config/nix/nix.conf:**

```conf
# Use all CPU cores
max-jobs = auto

# Parallel build jobs per derivation
cores = 0  # 0 = use all cores

# Keep build results
keep-outputs = true
keep-derivations = true
```

### Build-Time Optimization

**Enable experimental features:**

```conf
# ~/.config/nix/nix.conf
experimental-features = nix-command flakes ca-derivations

# Use content-addressed derivations (faster rebuilds)
accept-flake-config = true
```

### Evaluation Cache

**Speed up flake evaluation:**

```bash
# Enable evaluation cache (experimental)
nix develop --eval-cache
nix build --eval-cache
```

## Security Best Practices

### Secrets Management

**Never hardcode secrets in flake.nix:**

```nix
# ❌ WRONG:
shellHook = ''
  export API_KEY="sk-abc123"  # Never do this!
'';

# ✅ CORRECT:
shellHook = ''
  if op account get &>/dev/null 2>&1; then
    export API_KEY=$(op read "op://Dev/api/key")
  fi
'';
```

### Pinning Inputs

**Always pin flake inputs for security:**

```bash
# Update and review changes
nix flake update
git diff flake.lock

# Pin to specific commit after verification
nix flake lock --override-input nixpkgs github:nixos/nixpkgs/<commit-hash>
```

### Signature Verification

**Require signatures for binary caches:**

```conf
# ~/.config/nix/nix.conf
require-sigs = true
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= my-cache-1:YOUR_KEY
```

## Resources

### Official Documentation

- **Nix Manual:** https://nixos.org/manual/nix/stable/
- **Nixpkgs Manual:** https://nixos.org/manual/nixpkgs/stable/
- **Nix Pills:** https://nixos.org/guides/nix-pills/ (deep dive)

### Community Resources

- **NixOS Discourse:** https://discourse.nixos.org/
- **NixOS Wiki:** https://nixos.wiki/
- **Awesome Nix:** https://github.com/nix-community/awesome-nix

### Related Guides

- [Quick Start](00-quickstart.md) - Get up and running
- [Concepts](01-concepts.md) - Understand Nix fundamentals
- [Daily Usage](02-daily-usage.md) - Common workflows
- [Troubleshooting](03-troubleshooting.md) - Fix issues

## Next Steps

**Now that you've mastered advanced Nix:**

1. **Contribute to dev-config:**
   - Create templates for new languages
   - Add custom packages
   - Improve documentation

2. **Integrate with infrastructure:**
   - Export modules to ai-dev-env
   - Set up team binary cache
   - Automate deployments

3. **Share knowledge:**
   - Write blog posts about your setup
   - Help team members with Nix
   - Contribute to upstream nixpkgs

4. **Explore further:**
   - NixOS (full operating system)
   - Home Manager (user environment manager)
   - Nix Darwin (macOS system manager)
   - Hydra (build farm)
