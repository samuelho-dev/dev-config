# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **centralized development configuration repository** using **Nix + Home Manager** for declarative, reproducible dotfile and package management.

**Managed configurations:**
- **Neovim** - Text editor with LSP, completion, git integration
- **Tmux** - Terminal multiplexer with plugin ecosystem
- **Ghostty** - GPU-accelerated terminal emulator
- **Yazi** - Blazing-fast terminal file manager with rich previews
- **Zsh** - Shell with Oh My Zsh framework + Powerlevel10k theme
- **Git** - Version control with 1Password SSH signing
- **Docker** - Container platform (NixOS module only)

## DevOps Development Shell

The `devShells.default` output provides a **comprehensive DevOps environment** with 40+ tools organized by category. This is the **single source of truth** for development tooling, imported by consumer projects like `ai-dev-env`.

### Tool Categories

**Core Development Tools:**
- git, zsh, tmux, docker, neovim
- fzf, ripgrep, fd, bat, lazygit, gitmux

**Runtimes:**
- nodejs_20, bun, python3

**Kubernetes Ecosystem:**
- kubectl, helm, helm-docs, k9s, kind, argocd

**Cloud Providers:**
- awscli2 (AWS), doctl (DigitalOcean)

**Infrastructure as Code:**
- terraform, terraform-docs

**Security & Compliance:**
- gitleaks, kubeseal, sops

**Data Processing:**
- jq (JSON), yq-go (YAML)

**CI/CD & Git:**
- gh (GitHub CLI), act (local Actions), pre-commit

**AI Development:**
- 1Password CLI (credential management)
- OpenCode (installed separately, not in nixpkgs)

**Utilities:**
- direnv, nix-direnv, gnumake, pkg-config, imagemagick

### Usage

**Standalone (in dev-config repo):**
```bash
# Enter development shell
nix develop

# Or use direnv for automatic activation
direnv allow
cd ~/Projects/dev-config  # Auto-loads environment
```

**Imported by consumer projects:**
```nix
# In consumer flake.nix
inputs.dev-config.url = "github:samuelho-dev/dev-config";

devShells.default = dev-config.devShells.${system}.default.overrideAttrs (old: {
  shellHook = old.shellHook + ''
    # Project-specific extensions here
  '';
});
```

### First Load vs Subsequent Loads

- **First load**: Downloads ~40 packages (~500MB) from Nix cache (5-10 minutes)
- **Subsequent loads**: Instant (<1 second) - everything cached locally
- **nix-direnv**: Caches flake evaluation for 100x faster reloads

## Architecture: Nix + Home Manager (Current)

**As of January 2025, this repository uses Home Manager for declarative configuration management.**

### Why Home Manager?

**Previous approach (shell scripts):**
- Imperative installation with shell scripts
- Manual package management per platform
- No version locking
- Difficult to reproduce environments

**Current approach (Home Manager):**
- Declarative configuration in `modules/home-manager/`
- All packages and dotfiles managed by Nix
- Version locking via `flake.lock`
- Identical environments across machines
- Single command activation: `home-manager switch --flake .`

### Key Files

```
dev-config/
├── flake.nix                          # Nix flake configuration
├── flake.lock                         # Version lock file (committed)
├── home.nix                           # Home Manager entry point
├── modules/
│   ├── home-manager/                  # Home Manager modules (main configuration)
│   │   ├── default.nix                # Main module exporter
│   │   ├── programs/
│   │   │   ├── neovim.nix             # Neovim configuration + symlink
│   │   │   ├── tmux.nix               # Tmux configuration + symlink
│   │   │   ├── yazi.nix               # Yazi file manager (declarative)
│   │   │   ├── zsh.nix                # Zsh configuration + symlink
│   │   │   ├── git.nix                # Git configuration
│   │   │   ├── ssh.nix                # SSH + 1Password agent
│   │   │   └── ghostty.nix            # Ghostty configuration + symlink
│   │   └── services/
│   │       └── direnv.nix             # Direnv auto-activation
│   └── nixos/                         # NixOS modules (for servers)
│       ├── default.nix                # Main module exporter
│       ├── base-packages.nix          # Core system packages
│       ├── docker.nix                 # Docker daemon configuration
│       ├── shell.nix                  # Zsh system configuration
│       └── users.nix                  # User account management
├── scripts/
│   └── install.sh                     # Bootstrap script (installs Nix + Home Manager)
├── nvim/, tmux/, yazi/, zsh/, ghostty/  # Actual dotfiles (managed by Home Manager)
└── docs/nix/                          # Nix documentation (9 guides)
```

### Installation Workflow (Current)

```bash
# One command installs everything:
bash scripts/install.sh

# What this does:
# 1. Installs Nix (Determinate Systems installer)
# 2. Enables flakes
# 3. Installs Home Manager
# 4. Activates configuration: nix run home-manager/master -- switch --flake .
```

**Home Manager activation:**
1. Installs all packages (Neovim, tmux, zsh, Git, etc.)
2. Creates symlinks for dotfiles:
   - `~/.config/nvim/` → `~/Projects/dev-config/nvim/`
   - `~/.tmux.conf` → `~/Projects/dev-config/tmux/tmux.conf`
   - `~/.zshrc` → `~/Projects/dev-config/zsh/.zshrc`
   - `~/.p10k.zsh` → `~/Projects/dev-config/zsh/.p10k.zsh`
   - Ghostty config (platform-specific path)
3. Installs Oh My Zsh, Powerlevel10k, plugins
4. Installs Tmux Plugin Manager (TPM)
5. Configures Git with SSH signing (1Password integration)
6. Sets up direnv auto-activation

### Machine-Specific Configuration (user.nix)

Home Manager requires machine-specific values (username, home directory) that vary per machine and should never be committed to Git.

**Initial Setup:**

1. **Create user configuration from template:**
   ```bash
   cp user.nix.example user.nix
   ```

2. **Edit with your machine-specific details:**
   ```nix
   # user.nix (gitignored, machine-specific)
   {
     username = "your-username";              # e.g., "samuelho"
     homeDirectory = "/Users/your-username";  # macOS: /Users/username, Linux: /home/username
   }
   ```

3. **Stage the file for Nix visibility (required for flakes):**
   ```bash
   git add -f user.nix
   ```

   **Why stage a gitignored file?** Nix flakes can only access Git-tracked files during evaluation.
   Staging with `-f` makes user.nix visible to Nix while `.gitignore` prevents accidental commits.

   **Safety:** The file stays in "Changes to be committed" but won't be committed because:
   - `.gitignore` blocks commits
   - Use `git commit` (not `git commit -a`) to avoid overriding gitignore
   - Pre-commit hooks (if configured) will reject commits containing gitignored files

4. **Apply Home Manager configuration:**
   ```bash
   home-manager switch --flake .#aarch64-darwin  # macOS ARM64
   # or
   home-manager switch --flake .#x86_64-linux    # Linux x86_64
   ```

### Updating Configuration

**After modifying any configuration files:**

```bash
# Apply changes:
home-manager switch --flake ~/Projects/dev-config

# Or use the helper script:
bash scripts/apply-home-manager.sh

# Update packages to latest versions:
nix flake update
home-manager switch --flake ~/Projects/dev-config
```

### Home Manager Module System

**Module structure (modules/home-manager/):**

Each program has a dedicated module with this pattern:

```nix
# modules/home-manager/programs/neovim.nix
{ config, lib, pkgs, inputs ? {}, ... }:

let
  cfg = config.dev-config.neovim;
in {
  options.dev-config.neovim = {
    enable = lib.mkEnableOption "Neovim configuration";

    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = if inputs ? dev-config then "${inputs.dev-config}/nvim" else null;
      description = "Path to Neovim configuration directory";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install Neovim package
    home.packages = [ pkgs.neovim ];

    # Create symlink to dotfiles (from flake input or null)
    xdg.configFile."nvim".source = cfg.configSource;
  };
}
```

**Key concepts:**
- **Explicit `lib.` prefixes**: Always use `lib.mkEnableOption`, `lib.mkIf`, `lib.types.*` (never `with lib;`)
- **`mkEnableOption`**: Creates `dev-config.<program>.enable` option (defaults to false)
- **`mkIf cfg.enable`**: Only applies configuration if enabled
- **`home.packages`**: Installs packages via Nix
- **`xdg.configFile`**: Creates symlinks in XDG config directory
- **`inputs ? dev-config`**: Checks if dev-config is available as flake input (allows both standalone and flake composition usage)

**All modules are enabled by default in `home.nix`:**
```nix
dev-config = {
  enable = true;  # Enables all sub-modules
};
```

### Component-Specific Documentation

**Each directory has detailed CLAUDE.md and README.md files:**

#### Configuration Components
- **[nvim/CLAUDE.md](nvim/CLAUDE.md)** - Neovim architecture, plugin system, LSP configuration
- **[nvim/lua/CLAUDE.md](nvim/lua/CLAUDE.md)** - Lua module organization and require paths
- **[nvim/lua/config/CLAUDE.md](nvim/lua/config/CLAUDE.md)** - Core configuration (options, autocmds, keymaps)
- **[nvim/lua/plugins/CLAUDE.md](nvim/lua/plugins/CLAUDE.md)** - Plugin specifications and lazy loading
- **[nvim/lua/plugins/custom/CLAUDE.md](nvim/lua/plugins/custom/CLAUDE.md)** - Custom utility modules
- **[tmux/CLAUDE.md](tmux/CLAUDE.md)** - Tmux configuration and TPM plugins
- **[yazi/CLAUDE.md](yazi/CLAUDE.md)** - Yazi file manager configuration
- **[zsh/CLAUDE.md](zsh/CLAUDE.md)** - Zsh configuration, Oh My Zsh, Powerlevel10k
- **[ghostty/CLAUDE.md](ghostty/CLAUDE.md)** - Ghostty terminal configuration

#### Scripts & Utilities
- **[scripts/CLAUDE.md](scripts/CLAUDE.md)** - Installation script architecture (legacy reference)

#### Documentation
- **[docs/CLAUDE.md](docs/CLAUDE.md)** - Documentation maintenance and standards

**When working on a specific component, read the component's CLAUDE.md first for detailed guidance.**

## Common Development Tasks

### Adding a New Package

**Note:** Packages are now managed centrally in `pkgs/default.nix` for DRY principle.

**To add a new package, edit `pkgs/default.nix`:**

```nix
# pkgs/default.nix
{pkgs}: {
  # ... existing categories ...

  # Add to appropriate category
  kubernetes = [
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.k9s
    pkgs.your-new-tool  # Add here
  ];

  # ... rest of file ...
}
```

Then apply:
```bash
home-manager switch --flake .
```

### Adding a New Program Module

1. **Create module file:** `modules/home-manager/programs/yourprogram.nix`

```nix
{ config, lib, pkgs, inputs ? {}, ... }:

let
  cfg = config.dev-config.yourprogram;
in {
  options.dev-config.yourprogram = {
    enable = lib.mkEnableOption "Your Program configuration";

    configSource = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = if inputs ? dev-config then "${inputs.dev-config}/yourprogram" else null;
      description = "Path to Your Program configuration directory";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.yourprogram ];

    # Create symlink to dotfiles (from flake input or null)
    xdg.configFile."yourprogram".source = cfg.configSource;
  };
}
```

**Important patterns:**
- Never use `with lib;` or `with pkgs;` - always use explicit prefixes
- Use `lib.mkEnableOption` (defaults to false) for optional modules
- Use `lib.mkOption { type = lib.types.bool; default = true; }` for enabled-by-default modules
- Use alphabetical parameter order: `{ config, lib, pkgs, inputs, ... }`

2. **Export module in `modules/home-manager/default.nix`:**

```nix
imports = [
  ./programs/yourprogram.nix
  # ... other imports
];
```

3. **Enable in `home.nix`:**

```nix
dev-config = {
  enable = true;
  # Optional: explicitly enable
  yourprogram.enable = true;
};
```

### Modifying Existing Dotfiles

Dotfiles in `nvim/`, `tmux/`, `zsh/`, `ghostty/` are **still edited directly** and version controlled in Git. Home Manager only creates symlinks to these files.

**Workflow:**
1. Edit dotfiles: `nvim ~/Projects/dev-config/nvim/init.lua`
2. Commit changes: `git add . && git commit -m "Update Neovim config"`
3. No Home Manager rebuild needed (symlinks automatically reflect changes)
4. Reload application:
   - Neovim: Restart
   - Tmux: `Prefix + r`
   - Zsh: `source ~/.zshrc`

### Testing Configuration Changes

**3-tier testing strategy:**

```bash
# Tier 1: Syntax validation (instant)
nix flake show --json

# Tier 2: Build without activation
home-manager build --flake .

# Tier 3: Preview changes (dry-run)
home-manager switch --flake . --dry-run

# Or use automated script:
bash scripts/test-config.sh
```

## SSH Authentication with 1Password

**All SSH authentication and Git commit signing uses 1Password SSH Agent.**

### Security Model

- **SSH private keys**: Stored in 1Password vault (never on disk)
- **SSH public keys**: Stored in `~/.config/home-manager/secrets.nix` (gitignored)
- **Git user info**: Also in `secrets.nix` (gitignored)
- **Configuration modules**: Committed to Git (no secrets)

### Machine-Specific Configuration

Each machine has its own `~/.config/home-manager/secrets.nix`:

```nix
{
  gitUserName = "Your Name";
  gitUserEmail = "your-email@example.com";
  sshSigningKey = "ssh-ed25519 AAAAC3... your-email@example.com";
}
```

**How it's used:**

```nix
# modules/home-manager/programs/git.nix
let
  secrets = import ~/.config/home-manager/secrets.nix;
in {
  programs.git = {
    userName = secrets.gitUserName;
    userEmail = secrets.gitUserEmail;
    signing.key = secrets.sshSigningKey;
  };
}
```

### Setup Workflow

1. Enable 1Password SSH Agent (Settings → Developer)
2. Create SSH key in 1Password (New Item → SSH Key)
3. Add public key to GitHub (Authentication + Signing)
4. Create `~/.config/home-manager/secrets.nix` with your info
5. Run `home-manager switch --flake .`

**Testing:**
```bash
ssh -T git@github.com                    # Test authentication
git log --show-signature                  # Verify commit signing
```

**Documentation:** See [docs/nix/09-1password-ssh.md](docs/nix/09-1password-ssh.md)

## AI Integration (OpenCode + 1Password)

**OpenCode** (AI coding assistant) and **Neovim (avante.nvim)** both integrate with:
1. **Direct API access** - Use API keys from 1Password
2. **LiteLLM proxy** - Team mode with cost tracking (requires `LITELLM_MASTER_KEY`)

### Credential Loading

**Automatic via direnv:**
```bash
cd ~/Projects/dev-config  # Activates direnv
# AI credentials auto-loaded from 1Password
```

**Manual:**
```bash
source scripts/load-ai-credentials.sh
```

**What gets loaded:**
```bash
export ANTHROPIC_API_KEY="..."       # Claude API
export OPENAI_API_KEY="..."          # OpenAI API
export GOOGLE_AI_API_KEY="..."       # Google AI API
export LITELLM_MASTER_KEY="..."      # LiteLLM proxy (optional)
```

**Documentation:**
- [docs/nix/04-opencode-integration.md](docs/nix/04-opencode-integration.md) - OpenCode setup
- [docs/nix/05-1password-setup.md](docs/nix/05-1password-setup.md) - 1Password configuration
- [docs/nix/07-litellm-proxy-setup.md](docs/nix/07-litellm-proxy-setup.md) - LiteLLM team mode

## Claude Code Multi-Profile Authentication

This repository includes **declarative multi-profile authentication** for Claude Code CLI, allowing you to manage multiple Claude accounts with different aliases.

### Configured Profiles

Three profiles are configured by default:

- **`claude`** (default) - Primary account using `~/.claude`
- **`claude-2`** - Secondary account using `~/.claude-2`
- **`claude-work`** - Work account using `~/.claude-work`

### Usage

**Shell aliases with 1Password OAuth injection:**
```bash
# Each alias automatically injects OAuth token from 1Password
claude /status         # Default profile
claude-2 /status       # Profile 2
claude-work /status    # Work profile
```

**Profile management functions:**
```bash
switch-claude work           # Switch to work profile (session-wide)
list-claude-profiles         # Show all available profiles
current-claude-profile       # Show active profile
claude-profile-status        # Check authentication status for all profiles
```

### Setup Requirements

1. **Generate long-lived OAuth tokens** for each profile:
   ```bash
   CLAUDE_CONFIG_DIR=~/.claude claude setup-token
   CLAUDE_CONFIG_DIR=~/.claude-2 claude setup-token
   CLAUDE_CONFIG_DIR=~/.claude-work claude setup-token
   ```

2. **Store tokens in 1Password "ai" item (Dev vault):**
   - Field: "claude-code-oauth-token" → value: `sk-ant-oat01-...` (may already exist)
   - Field: "claude-code-oauth-token-2" → value: `sk-ant-oat01-...`
   - Field: "claude-code-oauth-token-work" → value: `sk-ant-oat01-...`

3. **Authenticate to 1Password CLI:**
   ```bash
   op signin
   ```

### Configuration

**Module location:** `modules/home-manager/programs/claude-code.nix`

**Declarative profile definition:**
```nix
dev-config.claude-code = {
  enable = true;
  profiles = {
    default = {
      configDir = "~/.claude";
      opReference = "op://Dev/ai/claude-code-oauth-token";
    };
    claude-2 = {
      configDir = "~/.claude-2";
      opReference = "op://Dev/ai/claude-code-oauth-token-2";
    };
    work = {
      configDir = "~/.claude-work";
      opReference = "op://Dev/ai/claude-code-oauth-token-work";
    };
  };
};
```

### How It Works

Each profile alias:
1. Sets `CLAUDE_CONFIG_DIR` to isolate configuration
2. Injects `CLAUDE_CODE_OAUTH_TOKEN` via `op read` from 1Password
3. Launches `claude` CLI with isolated authentication

**Security benefits:**
- OAuth tokens never stored on disk
- Tokens retrieved on-demand from 1Password
- Each profile has independent authentication state
- Safe for version control (no secrets in config files)

### Adding More Profiles

Edit `modules/home-manager/programs/claude-code.nix` and add to profiles:

```nix
profiles = {
  # ... existing profiles ...

  client-xyz = {
    configDir = "~/.claude-client-xyz";
    opReference = "op://Personal/Claude Client XYZ/oauth-token";
  };
};
```

Then apply changes:
```bash
home-manager switch --flake ~/Projects/dev-config
```

## DevPod Integration (Remote Development)

This repository supports remote development via **DevPod** and **VS Code Remote Containers**.

**Quick start:**
```bash
devpod up . --ide vscode
```

**What happens:**
1. Container starts with base Ubuntu image
2. Nix installed via devcontainer feature
3. Home Manager configuration applied
4. All dotfiles and plugins ready

**Configuration:**
- `.devcontainer/devcontainer.json` - Container definition
- `.devcontainer/load-ai-credentials.sh` - 1Password loader (service accounts)

**Documentation:** [docs/README_DEVPOD.md](docs/README_DEVPOD.md)

## Key Architectural Decisions

### 1. Home Manager Module System
- **Decision:** Use Home Manager instead of custom shell scripts
- **Rationale:** Declarative, reproducible, version-locked, cross-platform
- **Implementation:** All configuration in `modules/home-manager/`

### 2. Flake Input Pattern for Config Sources
- **Decision:** Use `inputs ? dev-config` pattern with configSource options
- **Rationale:** Supports both standalone installation AND flake composition, graceful degradation, no hardcoded paths
- **Implementation:** All modules define `configSource` options that check `if inputs ? dev-config then "${inputs.dev-config}/path" else null`
- **Benefits:** Can be used as standalone Home Manager config OR imported as flake input in other projects

### 3. 1Password SSH Agent
- **Decision:** Store SSH keys in 1Password vault, not on disk
- **Rationale:** Zero secrets on disk, biometric unlock, cloud sync, safe for public repos
- **Implementation:** `modules/home-manager/programs/ssh.nix` + `secrets.nix` pattern

### 4. Module Enable Options
- **Decision:** All modules have `enable` option, all enabled by default
- **Rationale:** Easy to disable components per-machine, explicit configuration
- **Implementation:** `mkEnableOption` + `mkIf cfg.enable` pattern

### 5. Dual Module Export (NixOS + Home Manager)
- **Decision:** Export both `nixosModules` and `homeManagerModules` from flake
- **Rationale:** Reusable across projects (ai-dev-env integration), single source of truth
- **Implementation:** `flake.nix` outputs both module types

### 6. Anti-Pattern Elimination (January 2025 Audit)
- **Decision:** Eliminate all Nix anti-patterns and enforce 2025 best practices
- **Rationale:** Improve maintainability, static analysis, cross-compilation support
- **Implementation:**
  - Never use `with lib;` or `with pkgs;` - always explicit prefixes
  - Use `lib.mkOption { default = true; }` instead of `mkEnableOption // { default = true; }`
  - Alphabetical function parameters: `{ config, lib, pkgs, inputs, ... }`
  - Modern system enumeration: `nixpkgs.lib.systems.flakeExposed`
- **Audit Results:** 27 files modified, 23+ anti-patterns eliminated, 4 security vulnerabilities fixed
- **Documentation:** See `AUDIT_SUMMARY.md` for complete audit report

### 7. DRY Package Management
- **Decision:** Centralized package definitions in `pkgs/default.nix`
- **Rationale:** Single source of truth, eliminate duplication, easier maintenance
- **Implementation:** All packages organized by category (core, runtimes, kubernetes, cloud, etc.)
- **Benefits:** Consistent across devShells and Home Manager, easy to add/remove packages
- **Eliminated:** ~60 lines of duplicate package definitions

### 8. Security-First Secrets Management
- **Decision:** No secrets during Nix evaluation, runtime decryption only
- **Rationale:** Prevent secret exposure to `/nix/store`, ensure zero secrets on disk
- **Implementation:**
  - sops-nix for encrypted secrets with age encryption
  - 1Password CLI for just-in-time credential injection (.envrc)
  - `dotenv_if_exists` instead of `source_env` (direnv security model)
  - Never use `builtins.pathExists` or `builtins.readFile` for secrets during evaluation
- **Security Fixes:** npm token exposure, .envrc bypass, builtins.getEnv non-functionality

## NixOS Modules (For Servers)

**Located in `modules/nixos/` - used for NixOS systems only.**

These modules configure **system-level** settings (not user-level like Home Manager):

- **base-packages.nix** - System-wide packages (git, zsh, tmux, docker, etc.)
- **docker.nix** - Docker daemon configuration + user groups
- **shell.nix** - Zsh as default shell system-wide
- **users.nix** - User account creation with zsh

**Usage in NixOS configuration:**

```nix
# /etc/nixos/configuration.nix
{
  imports = [
    # Import from dev-config flake
    inputs.dev-config.nixosModules.default
  ];

  dev-config = {
    enable = true;
    docker.enable = true;
  };
}
```

**For desktops/laptops:** Use Home Manager modules only (not NixOS modules).

## Using dev-config as Flake Input

All dev-config modules support being imported as flake inputs via the `inputs ? dev-config` pattern. This enables **flake composition** - you can use dev-config modules in other projects without duplicating code.

### Pattern Explanation

**The `inputs ? dev-config` pattern:**

```nix
# Every module uses this pattern:
configSource = lib.mkOption {
  default = if inputs ? dev-config    # ← Check if dev-config available
    then "${inputs.dev-config}/nvim"  # ← Use from flake input
    else null;                         # ← Graceful degradation
};
```

**Benefits:**
- ✅ **Standalone mode**: Works when used directly (install.sh)
- ✅ **Composition mode**: Works when imported as flake input
- ✅ **No hardcoded paths**: Adapts automatically
- ✅ **Type-safe**: Nix validates paths at evaluation time

### Example: Import in Another Flake

**Add dev-config as input:**

```nix
# flake.nix in another project (e.g., ai-dev-env)
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dev-config.url = "github:samuelho-dev/dev-config";
    # OR for local development:
    # dev-config.url = "path:/Users/you/Projects/dev-config";
  };

  outputs = { self, nixpkgs, home-manager, dev-config, ... }: {
    homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        # Import dev-config Home Manager module
        dev-config.homeManagerModules.default

        # Configure which programs to enable
        {
          home = {
            username = "myuser";
            homeDirectory = "/home/myuser";
            stateVersion = "24.05";
          };

          dev-config = {
            enable = true;

            # Enable specific programs
            neovim.enable = true;
            tmux.enable = true;
            zsh.enable = true;
            git = {
              enable = true;
              userName = "Your Name";
              userEmail = "your@email.com";
              signing = {
                enable = true;
                key = "ssh-ed25519 AAA...";
              };
            };

            # Disable others
            ssh.enable = false;
            ghostty.enable = false;
          };
        }
      ];
    };
  };
}
```

### Example: NixOS System with dev-config

```nix
# /etc/nixos/configuration.nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.dev-config.nixosModules.default
  ];

  # System configuration
  dev-config = {
    enable = true;
    docker.enable = true;  # System-wide Docker daemon
  };

  # User configuration with Home Manager
  home-manager.users.myuser = {
    imports = [ inputs.dev-config.homeManagerModules.default ];

    dev-config = {
      enable = true;
      neovim.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
  };
}
```

### How It Works Internally

**When used standalone (install.sh):**
1. `flake.nix` passes itself as `inputs.dev-config`
2. Modules receive `inputs = { dev-config = /nix/store/...; }`
3. `inputs ? dev-config` evaluates to `true`
4. configSource = `"/nix/store/.../dev-config/nvim"`

**When imported as flake input:**
1. Parent flake passes dev-config as input
2. Modules receive `inputs = { dev-config = <flake>; }`
3. `inputs ? dev-config` evaluates to `true`
4. configSource = `"<dev-config-flake>/nvim"`

**When inputs not provided (rare):**
1. Modules receive empty `inputs = {}`
2. `inputs ? dev-config` evaluates to `false`
3. configSource = `null` (no config applied)

### Updating Flake Input

**In the consuming project:**

```bash
# Update to latest main branch
nix flake lock --update-input dev-config

# Pin to specific commit
nix flake update dev-config --override-input dev-config github:samuelho-dev/dev-config/abc1234

# Use local dev version
nix flake update dev-config --override-input dev-config path:/Users/you/Projects/dev-config
```

### Testing Flake Composition

```bash
# In dev-config repository
cd ~/Projects/dev-config

# Test that it can be imported
nix flake show

# Expected output:
# github:samuelho-dev/dev-config
# ├───homeManagerModules
# │   └───default: Home Manager module
# └───nixosModules
#     └───default: NixOS module
```

### Troubleshooting

**Issue: "attribute 'dev-config' missing"**
- Cause: Parent flake not passing `inputs` to module
- Fix: Add `specialArgs = { inherit inputs; };` to homeManagerConfiguration

**Issue: "configSource is null"**
- Cause: `inputs.dev-config` not available to modules
- Check: `nix eval .#homeManagerModules.default` in dev-config
- Fix: Ensure parent flake passes inputs correctly

### secrets.nix with Flake Composition

When using dev-config as a flake input, you still need to create `~/.config/home-manager/secrets.nix` on each machine:

```bash
# On target machine
cp /path/to/dev-config/secrets.nix.example ~/.config/home-manager/secrets.nix
nvim ~/.config/home-manager/secrets.nix  # Edit with your values
```

The git module will automatically import this file if present, regardless of whether dev-config is used standalone or as a flake input.

## Important Commands

### Home Manager
```bash
# Apply configuration
home-manager switch --flake ~/Projects/dev-config

# Build without activating (test)
home-manager build --flake ~/Projects/dev-config

# Preview changes (dry-run)
home-manager switch --flake ~/Projects/dev-config --dry-run

# Update packages to latest
cd ~/Projects/dev-config
nix flake update
home-manager switch --flake .
```

### Nix Flakes
```bash
# Validate syntax
nix flake show --json

# Update all inputs (nixpkgs, home-manager)
nix flake update

# Lock specific input
nix flake lock --update-input nixpkgs

# Show package information
nix search nixpkgs neovim
```

### Neovim
```bash
:checkhealth                    # Diagnose setup issues
:LspInfo                        # Show LSP client status
:Mason                          # Install/manage LSP servers
:Lazy                           # Manage plugins
:Lazy restore                   # Restore to lazy-lock.json versions
```

### Tmux
```bash
Prefix + r                      # Reload config
Prefix + I                      # Install plugins (TPM)
Prefix + U                      # Update plugins (TPM)
Prefix + ?                      # Show all keybindings
```

### Shell
```bash
source ~/.zshrc                 # Reload shell config
p10k configure                  # Reconfigure Powerlevel10k
```

### Git (in this repo)
```bash
git status                      # Check changes
git add .                       # Stage all
git commit -m "message"         # Commit (auto-signed with 1Password SSH key)
git push origin main            # Push to remote
```

## Troubleshooting

### Home Manager Issues

**"Cannot find secrets.nix":**
```bash
# Create secrets.nix from template:
mkdir -p ~/.config/home-manager
cp secrets.nix.example ~/.config/home-manager/secrets.nix
nvim ~/.config/home-manager/secrets.nix  # Edit with your info
```

**"Symlink already exists":**
```bash
# Remove existing symlinks/files first:
rm ~/.config/nvim ~/.tmux.conf ~/.zshrc ~/.zprofile ~/.p10k.zsh
# Then re-run:
home-manager switch --flake .
```

**"Build failed" / Nix errors:**
```bash
# Test configuration first:
bash scripts/test-config.sh

# Check syntax:
nix flake show --json

# Validate build without activating:
home-manager build --flake .
```

### Symlinks Not Working

Verify symlinks point to repository:
```bash
ls -la ~/.config/nvim           # Should show → ~/Projects/dev-config/nvim
ls -la ~/.tmux.conf             # Should show → ~/Projects/dev-config/tmux/tmux.conf
ls -la ~/.zshrc                 # Should show → ~/Projects/dev-config/zsh/.zshrc
```

If symlinks are missing or broken, re-run Home Manager:
```bash
home-manager switch --flake ~/Projects/dev-config
```

### 1Password SSH Issues

**"Could not open a connection to your authentication agent":**
```bash
# Check 1Password SSH agent is enabled:
# 1Password → Settings → Developer → SSH Agent (should be ON)
```

**"Permission denied (publickey)":**
```bash
# Verify SSH key added to GitHub as Authentication key
# GitHub → Settings → SSH and GPG keys → Add SSH key (Authentication)
```

**"Bad signature":**
```bash
# Verify SSH key added to GitHub as Signing key
# GitHub → Settings → SSH and GPG keys → Add SSH key (Signing)
```

**Documentation:** [docs/nix/09-1password-ssh.md](docs/nix/09-1password-ssh.md)

## For Future Claude Code Instances

**When modifying this repository:**

1. **Read component-specific CLAUDE.md first:**
   - `nvim/CLAUDE.md` for Neovim changes
   - `tmux/CLAUDE.md` for tmux changes
   - `zsh/CLAUDE.md` for shell changes
   - `modules/home-manager/programs/*.nix` for Home Manager modules

2. **Home Manager module patterns:**
   - Use `mkEnableOption` for all programs
   - Use `mkIf cfg.enable` to conditionally apply config
   - Define `configSource` options using `inputs ? dev-config` pattern for flake composition support
   - Use `xdg.configFile` or `home.file` for symlinks (source from configSource option)
   - Export modules in `modules/home-manager/default.nix`

3. **Testing changes:**
   - **Always test before committing** with `bash scripts/test-config.sh`
   - Tier 1: `nix flake show --json` (instant syntax check)
   - Tier 2: `home-manager build --flake .` (build without activation)
   - Tier 3: `home-manager switch --dry-run` (preview changes)

4. **Never commit secrets:**
   - `~/.config/home-manager/secrets.nix` is gitignored
   - SSH private keys stay in 1Password vault
   - Only public SSH keys and user info go in `secrets.nix`

5. **Version consistency:**
   - Commit `flake.lock` after updates
   - Commit `nvim/lazy-lock.json` after plugin updates
   - Document breaking changes in commit messages

6. **Cross-platform compatibility:**
   - Test on macOS (Intel + Apple Silicon)
   - Test on Linux (Debian/Ubuntu, Fedora, Arch)
   - Verify in DevPod container
   - Use platform detection: `pkgs.stdenv.isDarwin`, `pkgs.stdenv.isLinux`

7. **Documentation:**
   - Update component-specific CLAUDE.md for architecture changes
   - Update README.md for user-facing feature changes
   - Update `docs/nix/` guides for Nix-related changes
   - Keep this CLAUDE.md synchronized with current architecture

## Common Tasks Reference

### Adding Neovim Plugin
See `nvim/CLAUDE.md` lines 260-300 for detailed instructions.

### Adding Tmux Plugin
See `tmux/CLAUDE.md` lines 172-193 for detailed instructions.

### Adding LSP Server
See `nvim/CLAUDE.md` lines 210-235 for detailed instructions.

### Adding Zsh Plugin
See `zsh/CLAUDE.md` lines 205-224 for detailed instructions.

### Modifying Home Manager Module
1. Edit `modules/home-manager/programs/<program>.nix`
2. Test: `bash scripts/test-config.sh`
3. Apply: `home-manager switch --flake .`
4. Commit changes

### Cross-Platform Testing
Run in multiple environments:
- macOS: Direct installation
- Linux: Direct installation
- DevPod: Container environment
- NixOS: Server environment (uses `nixosModules`)
