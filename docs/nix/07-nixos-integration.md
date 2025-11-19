# NixOS Integration Guide

## Overview

This guide explains how to use dev-config with **NixOS bare metal servers** and **VMs**. For container deployments (DevPod), see [AI_DEV_ENV_INTEGRATION.md](../AI_DEV_ENV_INTEGRATION.md).

## Architecture

dev-config provides **modular NixOS configurations** that can be imported into your system configuration:

```
dev-config/
├── modules/
│   ├── nixos/              # System-level modules
│   │   ├── base-packages.nix
│   │   ├── users.nix
│   │   ├── docker.nix
│   │   └── shell.nix
│   └── home-manager/       # User-level modules
│       ├── programs/
│       │   ├── neovim.nix
│       │   ├── tmux.nix
│       │   ├── zsh.nix
│       │   └── git.nix
│       └── services/
│           └── direnv.nix
```

**Key Features:**
- All options use `lib.mkDefault` for easy overriding
- Modular design - enable/disable components independently
- Declarative config file management
- Automatic Docker group membership
- User creation and management

## Deployment Strategies

### Strategy 1: Pure NixOS (Fully Declarative)

**Best for:**
- Production servers
- Multi-user systems
- Infrastructure as code
- Immutable deployments

**Pros:**
- Everything version controlled
- Atomic rollbacks
- Reproducible across machines
- No runtime installation needed

**Cons:**
- Requires NixOS (not compatible with Ubuntu/Debian)
- Steeper learning curve

### Strategy 2: Hybrid (NixOS + Chezmoi)

**Best for:**
- Development workstations
- Single-user systems
- Teams familiar with dotfile managers

**Pros:**
- Flexible config management
- Easy to experiment with configs
- Works on any Linux distro (with Nix package manager)

**Cons:**
- Two systems to manage (Nix + Chezmoi)
- Less declarative

### Strategy 3: Container-Only (DevPod)

**Best for:**
- Kubernetes-based development environments
- Cloud-native workflows
- Fast iteration

**Pros:**
- Pre-built images (30-second startup)
- Consistent across all developers
- Easy to deploy/destroy

**Cons:**
- Container overhead
- Limited to containerized workflows

**See:** [AI_DEV_ENV_INTEGRATION.md](../AI_DEV_ENV_INTEGRATION.md) for container strategy

## Pure NixOS Deployment

### Step 1: Add dev-config to Your Flake

```nix
# /etc/nixos/flake.nix (or your system flake)
{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Import dev-config
    dev-config = {
      url = "github:samuelho-dev/dev-config";
      # During development, use local path:
      # url = "path:/home/user/Projects/dev-config";
    };
  };

  outputs = { self, nixpkgs, dev-config, ... }: {
    nixosConfigurations = {
      my-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import dev-config NixOS module
          dev-config.nixosModules.default

          # Your system configuration
          ./configuration.nix
        ];
      };
    };
  };
}
```

### Step 2: Configure Users

```nix
# /etc/nixos/configuration.nix
{ config, pkgs, lib, ... }:

{
  # Configure dev-config users
  dev-config.users = {
    # Developer account
    developer = {
      enable = true;
      extraGroups = [ "docker" "wheel" ];  # Docker access + sudo
    };

    # CI/CD service account
    ci-runner = {
      enable = true;
      isSystemUser = true;  # System account (no home)
      extraGroups = [ "docker" ];  # Docker access only
    };
  };

  # Standard NixOS user options still work
  users.users.developer = {
    # Additional user configuration
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA..."
    ];
  };
}
```

### Step 3: Customize Packages (Optional)

```nix
# Disable default packages, use custom list
dev-config.packages = {
  enable = false;  # Disable all defaults
};

environment.systemPackages = with pkgs; [
  # Your custom package list
  git neovim tmux
  custom-tool
];

# OR: Keep defaults, add extras
dev-config.packages.extraPackages = with pkgs; [
  kubectl
  k9s
  argocd
];
```

### Step 4: Build and Deploy

```bash
# Build the configuration
sudo nixos-rebuild build --flake /etc/nixos#my-server

# Test the configuration (temporary, doesn't persist reboot)
sudo nixos-rebuild test --flake /etc/nixos#my-server

# Apply the configuration (persistent)
sudo nixos-rebuild switch --flake /etc/nixos#my-server

# Verify dev-config tools installed
nvim --version
tmux -V
docker --version
op --version
```

## Home Manager Integration

Home Manager provides **user-level** configuration management (vs system-level NixOS).

### Option 1: NixOS + Home Manager (Recommended)

```nix
# /etc/nixos/flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    dev-config.url = "github:samuelho-dev/dev-config";

    # Add Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dev-config, home-manager, ... }: {
    nixosConfigurations.my-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # System-level config
        dev-config.nixosModules.default

        # Home Manager NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager.users.developer = { pkgs, ... }: {
            # Import dev-config Home Manager module
            imports = [ dev-config.homeManagerModules.default ];

            # Home Manager version
            home.stateVersion = "24.05";

            # Git user configuration (required for commits)
            dev-config.git = {
              userName = "John Doe";
              userEmail = "john@example.com";
            };
          };
        }

        ./configuration.nix
      ];
    };
  };
}
```

**What this does:**
- System-level: Installs packages, enables Docker, creates users
- User-level: Configures Neovim, tmux, zsh, git, direnv
- Config files: Automatically symlinked from dev-config repo

### Option 2: Standalone Home Manager

For **non-NixOS systems** (Ubuntu, macOS with Nix installed):

```nix
# ~/.config/home-manager/flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    dev-config.url = "github:samuelho-dev/dev-config";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dev-config, home-manager, ... }: {
    homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        dev-config.homeManagerModules.default
        {
          home = {
            username = "user";
            homeDirectory = "/home/user";
            stateVersion = "24.05";
          };

          # Git configuration
          dev-config.git = {
            userName = "John Doe";
            userEmail = "john@example.com";
          };
        }
      ];
    };
  };
}
```

**Deploy:**
```bash
home-manager switch --flake ~/.config/home-manager#user@hostname
```

## Configuration Management

### Declarative Config Files (Default)

By default, dev-config symlinks config files from the repo:

```nix
# This is automatic when you import dev-config.homeManagerModules.default
dev-config.neovim.configSource = "${inputs.dev-config}/nvim";
dev-config.tmux.configSource = "${inputs.dev-config}/tmux/tmux.conf";
dev-config.zsh.zshrcSource = "${inputs.dev-config}/zsh/.zshrc";
```

**Result:**
- `~/.config/nvim` → symlink to `dev-config/nvim`
- `~/.tmux.conf` → symlink to `dev-config/tmux/tmux.conf`
- `~/.zshrc` → symlink to `dev-config/zsh/.zshrc`

### Custom Config Files

Override with your own configurations:

```nix
dev-config.neovim.configSource = ./my-custom-nvim;
dev-config.tmux.configSource = ./my-tmux.conf;
```

### Hybrid: Nix Packages + Chezmoi Configs

Disable declarative config management, use Chezmoi:

```nix
# Install packages only, manage configs separately
dev-config = {
  neovim = {
    enable = true;
    configSource = null;  # Don't symlink config
  };
  tmux = {
    enable = true;
    configSource = null;
  };
  zsh = {
    enable = true;
    zshrcSource = null;
  };
};
```

Then apply configs with Chezmoi:
```bash
chezmoi init --apply https://github.com/samuelho-dev/dev-config
```

## Module Options Reference

### NixOS Module Options

```nix
dev-config = {
  # Global enable/disable
  enable = true;  # Default

  # Package management
  packages = {
    enable = true;  # Default
    extraPackages = [ pkgs.custom-tool ];
  };

  # User management
  users = {
    username = {
      enable = true;
      shell = pkgs.zsh;  # Default
      extraGroups = [ "docker" "wheel" ];  # Default
      isSystemUser = false;  # Default (normal user)
      home = "/home/username";  # Default
    };
  };

  # Docker configuration
  docker = {
    enable = true;  # Default
    autoAddUsers = true;  # Default (auto-add users to docker group)
    enableOnBoot = true;  # Default
  };

  # Shell configuration
  shell = {
    enable = true;  # Default
    defaultShell = pkgs.zsh;  # Default
    enableCompletion = true;  # Default
    enableSyntaxHighlighting = true;  # Default
    enableAutosuggestions = true;  # Default
  };
};
```

### Home Manager Module Options

```nix
dev-config = {
  # Global enable/disable
  enable = true;  # Default

  # Package management
  packages = {
    enable = true;  # Default
    extraPackages = [ pkgs.custom-tool ];
  };

  # Neovim
  neovim = {
    enable = true;  # Default
    configSource = "${inputs.dev-config}/nvim";  # Default
    defaultEditor = true;  # Default
    vimAlias = true;  # Default
    viAlias = true;  # Default
  };

  # Tmux
  tmux = {
    enable = true;  # Default
    configSource = "${inputs.dev-config}/tmux/tmux.conf";  # Default
    gitmuxConfigSource = "${inputs.dev-config}/tmux/.gitmux.conf";  # Default
    prefix = "C-a";  # Default
    baseIndex = 1;  # Default
    mouse = true;  # Default
    historyLimit = 10000;  # Default
  };

  # Zsh
  zsh = {
    enable = true;  # Default
    zshrcSource = "${inputs.dev-config}/zsh/.zshrc";  # Default
    zprofileSource = "${inputs.dev-config}/zsh/.zprofile";  # Default
    p10kSource = "${inputs.dev-config}/zsh/.p10k.zsh";  # Default
    enableCompletion = true;  # Default
    enableAutosuggestions = true;  # Default
    enableSyntaxHighlighting = true;  # Default
  };

  # Git
  git = {
    enable = true;  # Default
    userName = "John Doe";  # REQUIRED
    userEmail = "john@example.com";  # REQUIRED
    defaultBranch = "main";  # Default
    editor = "nvim";  # Default
    extraConfig = {};  # Additional git config
  };

  # Direnv
  direnv = {
    enable = true;  # Default
    enableNixDirenv = true;  # Default
  };
};
```

## Advanced Examples

### Multi-User Development Server

```nix
# /etc/nixos/configuration.nix
{ config, pkgs, lib, ... }:

{
  # Import dev-config
  imports = [ inputs.dev-config.nixosModules.default ];

  # Create multiple developer accounts
  dev-config.users = {
    alice = {
      enable = true;
      extraGroups = [ "docker" "wheel" ];
    };
    bob = {
      enable = true;
      extraGroups = [ "docker" "wheel" ];
    };
    charlie = {
      enable = true;
      extraGroups = [ "docker" ];  # No sudo
    };
  };

  # Per-user Home Manager configs
  home-manager.users.alice = { pkgs, ... }: {
    imports = [ inputs.dev-config.homeManagerModules.default ];
    dev-config.git = {
      userName = "Alice";
      userEmail = "alice@company.com";
    };
  };

  home-manager.users.bob = { pkgs, ... }: {
    imports = [ inputs.dev-config.homeManagerModules.default ];
    dev-config.git = {
      userName = "Bob";
      userEmail = "bob@company.com";
    };
    # Bob uses custom Neovim config
    dev-config.neovim.configSource = ./bob-nvim-config;
  };

  home-manager.users.charlie = { pkgs, ... }: {
    imports = [ inputs.dev-config.homeManagerModules.default ];
    dev-config.git = {
      userName = "Charlie";
      userEmail = "charlie@company.com";
    };
    # Charlie disables some tools
    dev-config.tmux.enable = false;
  };
}
```

### AI Development Infrastructure Server

```nix
# /etc/nixos/configuration.nix for ai-dev-env infrastructure
{ config, pkgs, lib, ... }:

{
  imports = [ inputs.dev-config.nixosModules.default ];

  # Keep base dev tools
  dev-config.packages.extraPackages = with pkgs; [
    # Add infrastructure-specific tools
    kubectl
    kubernetes-helm
    argocd
    k9s
    terraform
    doctl  # DigitalOcean CLI
  ];

  # Infrastructure admin users
  dev-config.users = {
    admin = {
      enable = true;
      extraGroups = [ "docker" "wheel" ];
    };
    ci-deployer = {
      enable = true;
      isSystemUser = true;
      extraGroups = [ "docker" ];
    };
  };

  # Admin Home Manager config
  home-manager.users.admin = { pkgs, ... }: {
    imports = [ inputs.dev-config.homeManagerModules.default ];

    dev-config = {
      git = {
        userName = "Infrastructure Admin";
        userEmail = "admin@company.com";
        extraConfig = {
          # GPG signing for commits
          commit.gpgsign = true;
          user.signingkey = "ABCD1234";
        };
      };

      # Add infrastructure-specific packages
      packages.extraPackages = with pkgs; [
        kubectl
        k9s
        argocd
      ];
    };
  };
}
```

### Minimal Server (Disabled Unnecessary Components)

```nix
# Minimal server with only essential tools
{ config, pkgs, lib, ... }:

{
  imports = [ inputs.dev-config.nixosModules.default ];

  # Disable Docker (not needed)
  dev-config.docker.enable = false;

  # Minimal package set
  dev-config.packages.enable = false;
  environment.systemPackages = with pkgs; [
    git
    neovim
    tmux
  ];

  # Single admin user
  dev-config.users.admin.enable = true;

  # Minimal Home Manager config
  home-manager.users.admin = { pkgs, ... }: {
    imports = [ inputs.dev-config.homeManagerModules.default ];

    # Disable unnecessary programs
    dev-config = {
      packages.enable = false;
      direnv.enable = false;

      # Keep essentials
      neovim.enable = true;
      tmux.enable = true;
      git = {
        userName = "Admin";
        userEmail = "admin@server.com";
      };
    };
  };
}
```

## Testing and Validation

### Check Configuration Syntax

```bash
# Validate flake syntax
nix flake check

# Build without applying
sudo nixos-rebuild build --flake /etc/nixos#my-server

# Inspect what would change
sudo nixos-rebuild dry-build --flake /etc/nixos#my-server
```

### Test in VM

```bash
# Build VM image
sudo nixos-rebuild build-vm --flake /etc/nixos#my-server

# Run VM
./result/bin/run-nixos-vm
```

### Rollback if Issues

```bash
# Boot into previous generation
sudo nixos-rebuild switch --rollback

# List all generations
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch to specific generation
sudo nixos-rebuild switch --rollback --generation 42
```

## Troubleshooting

### Config Files Not Symlinked

**Symptom:** `~/.config/nvim` is empty

**Cause:** Home Manager not configured or configSource set to null

**Fix:**
```nix
home-manager.users.user = { pkgs, ... }: {
  imports = [ inputs.dev-config.homeManagerModules.default ];
  # Ensure configSource is set (should be automatic)
  dev-config.neovim.configSource = "${inputs.dev-config}/nvim";
};
```

### User Not in Docker Group

**Symptom:** `docker: permission denied`

**Cause:** User created before dev-config module applied

**Fix:**
```bash
# Re-run nixos-rebuild to update user groups
sudo nixos-rebuild switch

# Or manually add user
sudo usermod -aG docker $USER

# Log out and back in
```

### Nix Flake Not Updating

**Symptom:** Changes to dev-config repo not reflected

**Cause:** Flake lock not updated

**Fix:**
```bash
# Update all inputs
nix flake update

# Update only dev-config
nix flake lock --update-input dev-config

# Rebuild with updated lock
sudo nixos-rebuild switch --flake /etc/nixos#my-server
```

## Next Steps

- **Home Manager Deep Dive:** See [08-home-manager.md](08-home-manager.md)
- **Container Deployment:** See [AI_DEV_ENV_INTEGRATION.md](../AI_DEV_ENV_INTEGRATION.md)
- **Examples:** Check `examples/nixos-bare-metal/` for complete working configs

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Module System](https://nixos.wiki/wiki/NixOS_modules)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
