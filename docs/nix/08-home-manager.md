# Home Manager Integration Guide

## Overview

Home Manager provides **user-level configuration management** for Nix. Unlike NixOS modules (system-wide), Home Manager configs apply per-user.

**Key Benefits:**
- Works on **any Linux distro** with Nix installed
- Works on **macOS** with Nix
- User-level package installation (no sudo required)
- Declarative dotfile management
- Per-user customization on shared systems

## Installation Methods

### Method 1: Standalone (Non-NixOS Systems)

**Best for:** macOS, Ubuntu, Debian, Fedora, Arch with Nix package manager

#### Step 1: Install Nix

```bash
# Official Nix installer (with flakes enabled)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Verify installation
nix --version
```

#### Step 2: Create Home Manager Flake

```bash
# Create config directory
mkdir -p ~/.config/home-manager

# Create flake.nix
cat > ~/.config/home-manager/flake.nix <<'EOF'
{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    dev-config = {
      url = "github:samuelho-dev/dev-config";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dev-config, home-manager, ... }:
    let
      system = "x86_64-linux";  # or "aarch64-darwin" for M1/M2 Macs
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          dev-config.homeManagerModules.default

          {
            home = {
              username = "user";  # Your username
              homeDirectory = "/home/user";  # Your home directory
              stateVersion = "24.05";  # Home Manager version
            };

            # Required: Git user configuration
            dev-config.git = {
              userName = "Your Name";
              userEmail = "you@example.com";
            };
          }
        ];
      };
    };
}
EOF
```

**Replace:**
- `user@hostname` with `youruser@yourhostname` (run `whoami` and `hostname`)
- `system` with your architecture:
  - `x86_64-linux` - Intel/AMD Linux
  - `aarch64-linux` - ARM64 Linux
  - `x86_64-darwin` - Intel Mac
  - `aarch64-darwin` - M1/M2/M3 Mac
- `username` and `homeDirectory` with your actual values
- Git `userName` and `userEmail`

#### Step 3: Apply Configuration

```bash
# Generate flake.lock
cd ~/.config/home-manager
nix flake lock

# Build and apply configuration
home-manager switch --flake ~/.config/home-manager#user@hostname

# Verify installation
nvim --version
tmux -V
which op
```

### Method 2: NixOS Module (NixOS Systems)

**Best for:** NixOS installations (bare metal, VMs).

dev-config exposes two module sets:

- `dev-config.nixosModules.default` — **system-level** (packages, Docker, users, shell)
- `dev-config.homeManagerModules.default` — **user-level** (Neovim, tmux, zsh, git, direnv)

All options use `lib.mkDefault`, so individual components can be enabled, disabled, or
overridden independently.

#### Step 1: Add dev-config to Your System Flake

```nix
# /etc/nixos/flake.nix
{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    dev-config.url = "github:samuelho-dev/dev-config";
    # During development, use a local path:
    # dev-config.url = "path:/home/user/Projects/dev-config";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dev-config, home-manager, ... }: {
    nixosConfigurations.my-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # System-level config (packages, Docker, users)
        dev-config.nixosModules.default

        # Home Manager as a NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager.users.developer = { pkgs, ... }: {
            imports = [ dev-config.homeManagerModules.default ];
            home.stateVersion = "24.05";

            # Required: Git identity for commits
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
- System-level: installs packages, enables Docker, creates users
- User-level: configures Neovim, tmux, zsh, git, direnv
- Config files: automatically symlinked from the dev-config repo

#### Step 2: Configure Users (System-Level)

```nix
# /etc/nixos/configuration.nix
{ config, pkgs, lib, ... }:

{
  dev-config.users = {
    # Developer account: Docker access + sudo
    developer = {
      enable = true;
      extraGroups = [ "docker" "wheel" ];
    };

    # CI/CD service account: Docker only, no home
    ci-runner = {
      enable = true;
      isSystemUser = true;
      extraGroups = [ "docker" ];
    };
  };

  # Standard NixOS user options still work
  users.users.developer.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA..."
  ];
}
```

#### Step 3: Customize Packages (System-Level, Optional)

```nix
# Keep defaults, add extras
dev-config.packages.extraPackages = [
  pkgs.kubectl
  pkgs.k9s
  pkgs.argocd
];

# OR: disable defaults entirely and supply your own list
dev-config.packages.enable = false;
environment.systemPackages = [ pkgs.git pkgs.neovim pkgs.tmux ];
```

#### Step 4: Build and Deploy

```bash
# Build without applying
sudo nixos-rebuild build --flake /etc/nixos#my-server

# Test (temporary, doesn't persist across reboot)
sudo nixos-rebuild test --flake /etc/nixos#my-server

# Apply (persistent)
sudo nixos-rebuild switch --flake /etc/nixos#my-server

# Verify
nvim --version && tmux -V && docker --version && op --version
```

## Configuration Patterns

### Default Configuration

By default, dev-config symlinks all config files:

```nix
# This happens automatically when you import dev-config.homeManagerModules.default
{
  imports = [ dev-config.homeManagerModules.default ];

  # Automatic config file symlinking:
  # ~/.config/nvim -> dev-config/nvim
  # ~/.tmux.conf -> dev-config/tmux/tmux.conf
  # ~/.zshrc -> dev-config/zsh/.zshrc
  # ~/.zprofile -> dev-config/zsh/.zprofile
  # ~/.p10k.zsh -> dev-config/zsh/.p10k.zsh
}
```

### Custom Neovim Configuration

```nix
{
  imports = [ dev-config.homeManagerModules.default ];

  # Use your own Neovim config
  dev-config.neovim = {
    enable = true;
    configSource = ./my-nvim-config;  # Your custom config directory
  };
}
```

### Custom Tmux Configuration

```nix
{
  imports = [ dev-config.homeManagerModules.default ];

  dev-config.tmux = {
    enable = true;
    configSource = ./my-tmux.conf;
    prefix = "C-b";  # Change prefix (default: C-a)
    mouse = false;  # Disable mouse (default: true)
  };
}
```

### Custom Zsh Configuration

```nix
{
  imports = [ dev-config.homeManagerModules.default ];

  dev-config.zsh = {
    enable = true;
    zshrcSource = ./my-zshrc;
    # Or disable declarative management, use Chezmoi/manual
    zshrcSource = null;
  };
}
```

### Disable Specific Programs

```nix
{
  imports = [ dev-config.homeManagerModules.default ];

  # Disable programs you don't use
  dev-config = {
    tmux.enable = false;
    direnv.enable = false;
  };
}
```

### Add Extra Packages

```nix
{
  imports = [ dev-config.homeManagerModules.default ];

  # Add packages beyond defaults
  dev-config.packages.extraPackages = [
    # Infrastructure tools
    pkgs.kubectl
    pkgs.k9s
    pkgs.terraform

    # Language tools
    nodejs_20
    python312
    go

    # Utilities
    htop
    ncdu
  ];
}
```

### Git Configuration

```nix
{
  imports = [ dev-config.homeManagerModules.default ];

  dev-config.git = {
    userName = "Your Name";
    userEmail = "you@example.com";

    # Additional git config
    extraConfig = {
      pull.rebase = false;
      push.autoSetupRemote = true;

      # GPG signing
      commit.gpgsign = true;
      user.signingkey = "YOUR_GPG_KEY";

      # Diff tools
      diff.tool = "nvimdiff";
      merge.tool = "nvimdiff";
    };
  };
}
```

## Multi-Machine Configurations

### Option 1: Separate Configs per Machine

```
~/.config/home-manager/
├── flake.nix
├── home-laptop.nix
├── home-desktop.nix
└── home-server.nix
```

**flake.nix:**
```nix
{
  outputs = { self, nixpkgs, dev-config, home-manager, ... }: {
    homeConfigurations = {
      # Laptop configuration
      "user@laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          dev-config.homeManagerModules.default
          ./home-laptop.nix
        ];
      };

      # Desktop configuration
      "user@desktop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          dev-config.homeManagerModules.default
          ./home-desktop.nix
        ];
      };

      # Server configuration
      "user@server" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          dev-config.homeManagerModules.default
          ./home-server.nix
        ];
      };
    };
  };
}
```

**home-laptop.nix:**
```nix
{ config, pkgs, ... }:

{
  home = {
    username = "user";
    homeDirectory = "/home/user";
    stateVersion = "24.05";
  };

  dev-config = {
    git = {
      userName = "John Doe";
      userEmail = "john@personal.com";  # Personal email
    };

    # Laptop-specific packages
    packages.extraPackages = [
      pkgs.spotify
      pkgs.slack
      pkgs.zoom-us
    ];
  };
}
```

**home-server.nix:**
```nix
{ config, pkgs, ... }:

{
  home = {
    username = "admin";
    homeDirectory = "/home/admin";
    stateVersion = "24.05";
  };

  dev-config = {
    git = {
      userName = "John Doe";
      userEmail = "john@company.com";  # Work email
    };

    # Server doesn't need GUI tools
    packages.enable = false;

    # Minimal server packages
    home.packages = [
      pkgs.git neovim tmux
      pkgs.htop
    ];
  };
}
```

**Switching between machines:**
```bash
# On laptop
home-manager switch --flake ~/.config/home-manager#user@laptop

# On server
home-manager switch --flake ~/.config/home-manager#user@server
```

### Option 2: Shared Config with Overrides

```
~/.config/home-manager/
├── flake.nix
├── common.nix          # Shared configuration
└── machines/
    ├── laptop.nix
    ├── desktop.nix
    └── server.nix
```

**common.nix:**
```nix
{ config, pkgs, ... }:

{
  # Shared configuration for all machines
  dev-config = {
    neovim.enable = true;
    tmux.enable = true;
    zsh.enable = true;
    git.enable = true;
    direnv.enable = true;
  };
}
```

**machines/laptop.nix:**
```nix
{ config, pkgs, ... }:

{
  imports = [ ../common.nix ];

  home = {
    username = "user";
    homeDirectory = "/home/user";
    stateVersion = "24.05";
  };

  dev-config = {
    git = {
      userName = "John Doe";
      userEmail = "john@personal.com";
    };

    # Laptop-specific overrides
    packages.extraPackages = [
      pkgs.spotify
      pkgs.slack
    ];
  };
}
```

## Advanced Patterns

### Conditional Configuration Based on Hostname

```nix
{ config, pkgs, lib, ... }:

let
  hostname = builtins.readFile /etc/hostname;
  isLaptop = hostname == "laptop\n";
  isServer = hostname == "server\n";
in
{
  imports = [ dev-config.homeManagerModules.default ];

  dev-config = {
    # GUI tools only on laptop
    packages.extraPackages = lib.optionals isLaptop (with pkgs; [
      pkgs.spotify
      pkgs.slack
      pkgs.zoom-us
    ]);

    # Disable tmux on laptop (use terminal tabs)
    tmux.enable = !isLaptop;
  };
}
```

### Per-Project Development Shells

```nix
{ config, pkgs, ... }:

{
  imports = [ dev-config.homeManagerModules.default ];

  # Project-specific shells
  home.file.".config/direnv/direnvrc".text = ''
    # Load dev-config's direnv setup
    source ${config.xdg.configHome}/direnv/direnvrc

    # Custom project layouts
    layout_python() {
      VIRTUAL_ENV=.venv
      if [[ ! -d $VIRTUAL_ENV ]]; then
        python -m venv $VIRTUAL_ENV
      fi
      PATH_add "$VIRTUAL_ENV/bin"
    }

    layout_node() {
      PATH_add node_modules/.bin
    }
  '';
}
```

### Managing Shell Aliases

```nix
{ config, pkgs, ... }:

{
  imports = [ dev-config.homeManagerModules.default ];

  programs.zsh = {
    shellAliases = {
      # Git shortcuts
      g = "git";
      gs = "git status";
      gc = "git commit";
      gp = "git push";

      # Docker shortcuts
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";

      # Kubernetes shortcuts
      k = "kubectl";
      kgp = "kubectl get pods";
      kgs = "kubectl get svc";
    };
  };
}
```

### NixOS: Multi-User Development Server

```nix
# /etc/nixos/configuration.nix
{ config, pkgs, lib, ... }:

{
  imports = [ inputs.dev-config.nixosModules.default ];

  # Create multiple developer accounts (system-level)
  dev-config.users = {
    alice = { enable = true; extraGroups = [ "docker" "wheel" ]; };
    bob = { enable = true; extraGroups = [ "docker" "wheel" ]; };
    charlie = { enable = true; extraGroups = [ "docker" ]; };  # No sudo
  };

  # Per-user Home Manager configs
  home-manager.users.alice = { pkgs, ... }: {
    imports = [ inputs.dev-config.homeManagerModules.default ];
    dev-config.git = { userName = "Alice"; userEmail = "alice@company.com"; };
  };

  home-manager.users.bob = { pkgs, ... }: {
    imports = [ inputs.dev-config.homeManagerModules.default ];
    dev-config.git = { userName = "Bob"; userEmail = "bob@company.com"; };
    dev-config.neovim.configSource = ./bob-nvim-config;  # Custom Neovim
  };

  home-manager.users.charlie = { pkgs, ... }: {
    imports = [ inputs.dev-config.homeManagerModules.default ];
    dev-config.git = { userName = "Charlie"; userEmail = "charlie@company.com"; };
    dev-config.tmux.enable = false;  # Disable tmux for this user
  };
}
```

### NixOS: Minimal Server

```nix
{ config, pkgs, lib, ... }:

{
  imports = [ inputs.dev-config.nixosModules.default ];

  dev-config.docker.enable = false;  # Not needed

  # Minimal system package set
  dev-config.packages.enable = false;
  environment.systemPackages = [ pkgs.git pkgs.neovim pkgs.tmux ];

  dev-config.users.admin.enable = true;

  home-manager.users.admin = { pkgs, ... }: {
    imports = [ inputs.dev-config.homeManagerModules.default ];
    dev-config = {
      packages.enable = false;
      direnv.enable = false;
      neovim.enable = true;
      tmux.enable = true;
      git = { userName = "Admin"; userEmail = "admin@server.com"; };
    };
  };
}
```

### Hybrid: Nix Packages + External Dotfile Manager

Install packages declaratively but manage dotfiles with another tool (e.g. Chezmoi)
by setting each `configSource` to `null`:

```nix
dev-config = {
  neovim = { enable = true; configSource = null; };
  tmux = { enable = true; configSource = null; };
  zsh = { enable = true; zshrcSource = null; };
};
```

## Module Options Reference

dev-config exposes a system-level option tree (via `nixosModules.default`) and a
user-level option tree (via `homeManagerModules.default`). Both live under the
`dev-config` namespace. All options default via `lib.mkDefault` and can be overridden.

### NixOS Module Options (System-Level)

```nix
dev-config = {
  enable = true;  # Default

  packages = {
    enable = true;                       # Default
    extraPackages = [ pkgs.custom-tool ];
  };

  users = {
    <username> = {
      enable = true;
      shell = pkgs.zsh;                  # Default
      extraGroups = [ "docker" "wheel" ];
      isSystemUser = false;              # Default (normal user)
      home = "/home/<username>";         # Default
    };
  };

  docker = {
    enable = true;        # Default
    autoAddUsers = true;  # Default (auto-add users to docker group)
    enableOnBoot = true;  # Default
  };

  shell = {
    enable = true;                     # Default
    defaultShell = pkgs.zsh;           # Default
    enableCompletion = true;           # Default
    enableSyntaxHighlighting = true;   # Default
    enableAutosuggestions = true;      # Default
  };
};
```

### Home Manager Module Options (User-Level)

```nix
dev-config = {
  enable = true;  # Default

  packages = {
    enable = true;                       # Default
    extraPackages = [ pkgs.custom-tool ];
  };

  neovim = {
    enable = true;                                   # Default
    configSource = "${inputs.dev-config}/nvim";      # Default (null = unmanaged)
    defaultEditor = true;                            # Default
    vimAlias = true;                                 # Default
    viAlias = true;                                  # Default
  };

  tmux = {
    enable = true;                                              # Default
    configSource = "${inputs.dev-config}/tmux/tmux.conf";       # Default
    gitmuxConfigSource = "${inputs.dev-config}/tmux/.gitmux.conf";  # Default
    prefix = "C-a";                                            # Default
    baseIndex = 1;                                             # Default
    mouse = true;                                              # Default
    historyLimit = 10000;                                      # Default
  };

  zsh = {
    enable = true;                                       # Default
    zshrcSource = "${inputs.dev-config}/zsh/.zshrc";      # Default
    zprofileSource = "${inputs.dev-config}/zsh/.zprofile";  # Default
    p10kSource = "${inputs.dev-config}/zsh/.p10k.zsh";    # Default
    enableCompletion = true;                             # Default
    enableAutosuggestions = true;                        # Default
    enableSyntaxHighlighting = true;                     # Default
  };

  git = {
    enable = true;                  # Default
    userName = "John Doe";          # REQUIRED
    userEmail = "john@example.com"; # REQUIRED
    defaultBranch = "main";         # Default
    editor = "nvim";                # Default
    extraConfig = {};               # Additional git config
  };

  direnv = {
    enable = true;            # Default
    enableNixDirenv = true;   # Default
  };
};
```

## Updating and Maintenance

### Update dev-config

```bash
# Update dev-config to latest version
cd ~/.config/home-manager
nix flake lock --update-input dev-config

# Apply updated configuration
home-manager switch --flake .#user@hostname
```

### Update All Inputs

```bash
# Update all inputs (nixpkgs, home-manager, dev-config)
nix flake update

# Review changes
nix flake lock --update-input dev-config
git diff flake.lock

# Apply if satisfied
home-manager switch --flake .#user@hostname
```

### Rollback to Previous Generation

```bash
# List generations
home-manager generations

# Rollback to previous
home-manager switch --flake .#user@hostname --rollback

# Switch to specific generation
/nix/var/nix/profiles/per-user/$USER/home-manager-42-link/activate
```

## Troubleshooting

### Config Files Not Appearing

**Symptom:** `~/.config/nvim` doesn't exist after `home-manager switch`

**Cause 1:** configSource set to null
```nix
# Fix: Ensure configSource is set
dev-config.neovim.configSource = "${inputs.dev-config}/nvim";
```

**Cause 2:** inputs not passed to module
```nix
# Fix: Pass inputs to module
homeConfigurations."user@host" = home-manager.lib.homeManagerConfiguration {
  modules = [
    dev-config.homeManagerModules.default
    { _module.args = { inherit inputs; }; }  # Add this
    ./home.nix
  ];
};
```

### Permission Denied Errors

**Symptom:** `home-manager switch` fails with permission errors

**Cause:** Trying to manage files outside home directory

**Fix:** Only manage files in `~/.config`, `~/.local`, `~/`

### Conflicting Files

**Symptom:** `error: Existing file '/home/user/.zshrc' is in the way`

**Cause:** Existing file conflicts with Home Manager symlink

**Fix:**
```bash
# Backup existing file
mv ~/.zshrc ~/.zshrc.backup

# Try again
home-manager switch --flake .#user@hostname

# If needed, merge changes from backup
```

### Nix Command Not Found (After Install)

**Symptom:** `bash: nix: command not found`

**Cause:** Nix not in PATH

**Fix:**
```bash
# Add to shell profile
echo 'source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' >> ~/.bashrc

# Or restart shell
exec bash -l
```

### User Not in Docker Group (NixOS)

**Symptom:** `docker: permission denied`

**Cause:** User created before the dev-config module was applied

**Fix:**
```bash
sudo nixos-rebuild switch   # Re-apply to update group membership
# Then log out and back in
```

### NixOS: Changes to dev-config Not Reflected

**Symptom:** Edits to the dev-config repo aren't picked up

**Cause:** Flake lock not updated

**Fix:**
```bash
nix flake lock --update-input dev-config
sudo nixos-rebuild switch --flake /etc/nixos#my-server
```

### NixOS Rollback

```bash
# Boot into the previous generation
sudo nixos-rebuild switch --rollback

# List generations
nix-env --list-generations --profile /nix/var/nix/profiles/system
```

## macOS-Specific Notes

### Homebrew Integration

Home Manager can manage Homebrew packages on macOS:

```nix
{ config, pkgs, ... }:

{
  imports = [ dev-config.homeManagerModules.default ];

  # Homebrew packages (macOS only)
  homebrew = {
    enable = true;
    brews = [
      "docker"  # Docker Desktop
    ];
    casks = [
      "ghostty"
      "visual-studio-code"
    ];
  };
}
```

### macOS Path Configuration

```nix
{ config, pkgs, lib, ... }:

{
  imports = [ dev-config.homeManagerModules.default ];

  # macOS-specific PATH
  home.sessionPath = lib.mkIf pkgs.stdenv.isDarwin [
    "/opt/homebrew/bin"  # Apple Silicon Homebrew
    "/usr/local/bin"     # Intel Homebrew
  ];
}
```

## Next Steps

- **Advanced Customization:** See [06-advanced.md](06-advanced.md)
- **Troubleshooting:** See [03-troubleshooting.md](03-troubleshooting.md)
- **1Password SSH & CLI:** See [09-1password-ssh.md](09-1password-ssh.md)

## References

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Module System](https://nixos.wiki/wiki/NixOS_modules)
- [Nix Package Search](https://search.nixos.org/packages)
