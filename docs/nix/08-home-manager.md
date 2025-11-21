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

**Best for:** NixOS installations

See [07-nixos-integration.md](07-nixos-integration.md#option-1-nixos--home-manager-recommended) for complete NixOS + Home Manager integration.

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

## Examples

Complete working examples in:
- `examples/home-manager-standalone/` - Standalone Home Manager setup
- `examples/nixos-bare-metal/` - NixOS + Home Manager integration

## Next Steps

- **NixOS Integration:** See [07-nixos-integration.md](07-nixos-integration.md)
- **Advanced Customization:** See [06-advanced.md](06-advanced.md)
- **Troubleshooting:** See [03-troubleshooting.md](03-troubleshooting.md)

## References

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [Nix Package Search](https://search.nixos.org/packages)
