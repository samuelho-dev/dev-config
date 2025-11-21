# Nix Concepts and Mental Model

## What is Nix?

Nix is a **declarative package manager** and **build system** that provides reproducible, reliable package management and system configuration.

**Key Principle:** Instead of imperatively running commands to install packages, you declare what you want in a configuration file, and Nix makes it happen.

### Traditional Package Management (Imperative)

```bash
# Homebrew (macOS)
brew install neovim tmux zsh
# What version? Depends on when you run it!
# Clean uninstall? Hope you remember everything!
```

### Nix Package Management (Declarative)

```nix
# flake.nix
packages = [ neovim tmux zsh ];
# Exact versions locked in flake.lock
# Atomic rollback to any previous state
```

## Core Concepts

### 1. The Nix Store

**Location:** `/nix/store/`

Every package is stored in an immutable directory with a unique hash:

```
/nix/store/
├── a1b2c3d4-neovim-0.9.5/
│   ├── bin/nvim
│   └── share/...
├── e5f6g7h8-tmux-3.3a/
│   ├── bin/tmux
│   └── share/...
└── i9j0k1l2-zsh-5.9/
    ├── bin/zsh
    └── share/...
```

**Benefits:**
- Multiple versions coexist peacefully
- No dependency conflicts
- Atomic upgrades and rollbacks
- Shared dependencies (deduplication)

### 2. Derivations (Build Recipes)

A **derivation** is a recipe for building a package. It specifies:
- Source code location
- Build dependencies
- Build steps
- Output paths

**Example conceptual derivation:**
```nix
neovim = {
  name = "neovim-0.9.5";
  src = fetchFromGitHub { ... };
  buildInputs = [ lua luajit ];
  buildPhase = "cmake && make";
  installPhase = "make install";
};
```

### 3. Flakes (Modern Nix)

**Flakes** are the modern way to manage Nix projects. They provide:
- **Reproducibility:** `flake.lock` pins exact versions
- **Composability:** Import flakes from other projects
- **Discoverability:** Standard output schema
- **Hermetic builds:** No implicit dependencies

**Our flake.nix structure:**
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: {
    devShells.default = /* development environment */;
    apps.activate = /* activation script */;
  };
}
```

### 4. Profiles (User Environments)

A **profile** is a collection of packages available to a user. Think of it as a symlink forest pointing into the Nix store.

```
~/.nix-profile/
├── bin/
│   ├── nvim -> /nix/store/a1b2c3d4-neovim-0.9.5/bin/nvim
│   ├── tmux -> /nix/store/e5f6g7h8-tmux-3.3a/bin/tmux
│   └── zsh -> /nix/store/i9j0k1l2-zsh-5.9/bin/zsh
└── ...
```

### 5. Generations (Rollback Points)

Every time you change your environment, Nix creates a new **generation**. You can instantly roll back to any previous generation.

```bash
# List generations
nix profile history

# Output:
# Version 42 (current) - 2025-01-18
# Version 41 - 2025-01-15
# Version 40 - 2025-01-10

# Rollback to version 41
nix profile rollback

# Or specific generation
nix profile switch-generation 40
```

## Nix Command Hierarchy

### Development Commands

```bash
# Enter development shell (temporary)
nix develop

# Run a one-off command in dev environment
nix develop --command nvim

# Build a package
nix build .#packageName

# Run an app
nix run .#appName
```

### Package Management

```bash
# Install package to profile
nix profile install nixpkgs#neovim

# Remove package
nix profile remove neovim

# List installed packages
nix profile list

# Update all packages
nix profile upgrade '.*'
```

### Flake Management

```bash
# Validate flake syntax
nix flake check

# Show flake outputs
nix flake show

# Update flake inputs (updates flake.lock)
nix flake update

# Lock specific input to current version
nix flake lock --update-input nixpkgs
```

## How dev-config Uses Nix

### 1. Package Definitions (flake.nix)

All tools are declared in one place:

```nix
packages = [
  pkgs.git zsh tmux docker neovim
  pkgs.fzf ripgrep lazygit
  pkgs.nodePackages.opencode-ai
  _1password
];
```

### 2. Version Locking (flake.lock)

Exact package versions are pinned:

```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "narHash": "sha256-abc123...",
        "rev": "def456...",
        "lastModified": 1705564800
      }
    }
  }
}
```

**Result:** Same `flake.lock` = identical environment on any machine.

### 3. Development Shell (devShells.default)

When you `cd` into dev-config:
1. direnv detects `.envrc`
2. Loads `nix develop`
3. All packages available in `$PATH`
4. AI credentials loaded from 1Password

### 4. Activation Apps (apps.activate)

Custom scripts for one-time setup:
- Create symlinks (reuses `scripts/lib/common.sh`)
- Install Oh My Zsh, Powerlevel10k, TPM
- Auto-install Neovim and tmux plugins

## Nix vs Traditional Package Managers

| Feature | Nix | Homebrew | APT/DNF |
|---------|-----|----------|---------|
| **Reproducibility** | ✅ Perfect (flake.lock) | ⚠️ Lockfiles exist but not default | ❌ No |
| **Rollback** | ✅ Instant, atomic | ❌ No | ❌ No |
| **Multiple Versions** | ✅ Yes | ⚠️ Limited (via `@version`) | ❌ No |
| **Isolation** | ✅ Per-project environments | ❌ Global | ❌ Global |
| **Cross-Platform** | ✅ Linux, macOS, Windows (WSL) | ⚠️ macOS, Linux | ❌ Linux only |
| **Binary Cache** | ✅ Built-in | ✅ Built-in | ✅ Built-in |
| **Package Count** | 80,000+ | 6,000+ | Varies |

## Common Nix Patterns in dev-config

### Pattern 1: Development Shell with Dependencies

```nix
devShells.default = pkgs.mkShell {
  packages = [ pkgs.nodejs pkgs.python3 ];
  shellHook = ''
    echo "Welcome to dev environment!"
    export CUSTOM_VAR="value"
  '';
};
```

**Usage:**
```bash
cd ~/Projects/dev-config
nix develop  # or auto-activated via direnv
```

### Pattern 2: Wrapper Scripts

```nix
apps.myScript = {
  type = "app";
  program = toString (pkgs.writeShellScript "my-script" ''
    echo "Running custom script..."
    ${pkgs.neovim}/bin/nvim --version
  '');
};
```

**Usage:**
```bash
nix run .#myScript
```

### Pattern 3: Reusable Modules

```nix
# Import shared library
source ${./scripts/lib/common.sh}

# Call existing function
create_backup "$file" "$timestamp"
```

**Benefit:** Reuse battle-tested Bash code from Nix.

## Nix Language Basics

Nix has its own functional programming language. Here are the essentials:

### Variables

```nix
let
  version = "1.0.0";
  name = "my-package";
in
"${name}-${version}"  # Result: "my-package-1.0.0"
```

### Functions

```nix
# Anonymous function
x: x + 1

# Named function
let
  addOne = x: x + 1;
in
addOne 5  # Result: 6
```

### Attribute Sets (Objects)

```nix
{
  name = "neovim";
  version = "0.9.5";
  dependencies = [ "lua" "luajit" ];
}
```

### Lists

```nix
[ "neovim" "tmux" "zsh" ]
```

### String Interpolation

```nix
let
  name = "Nix";
in
"Hello, ${name}!"  # Result: "Hello, Nix!"
```

### Conditionals

```nix
if condition then
  "yes"
else
  "no"
```

### let...in Expressions

```nix
let
  x = 10;
  y = 20;
in
x + y  # Result: 30
```

## Common Questions

### Q: Do I need to learn the Nix language?

**A:** Not for daily usage! The flake.nix is already configured. You only need:
- `nix develop` - Enter dev shell
- `nix flake update` - Update packages
- `nix run .#activate` - Run activation

### Q: What's the difference between `nix develop` and `nix shell`?

**A:**
- `nix develop` - Uses `devShells.default` from flake.nix (for development)
- `nix shell` - Temporarily adds packages without a flake

### Q: Why is the first build slow?

**A:** Nix downloads and builds packages. Subsequent builds use:
1. **Binary cache** (pre-built packages from cache.nixos.org or Cachix)
2. **Local store** (already built packages in `/nix/store`)

### Q: Can I use Nix with Homebrew?

**A:** Yes! They coexist peacefully:
- Nix: `/nix/store/`
- Homebrew: `/opt/homebrew/` (Apple Silicon) or `/usr/local/` (Intel)

### Q: What's the difference between Nix and NixOS?

**A:**
- **Nix:** Package manager (works on macOS, Linux, Windows WSL)
- **NixOS:** Linux distribution using Nix for entire system configuration

We're using **Nix** (package manager only), not NixOS.

## Troubleshooting Concepts

### "Evaluation error"

**Meaning:** Syntax error in .nix file

**Solution:**
```bash
nix flake check  # Shows detailed error
```

### "Build failed"

**Meaning:** Package compilation error

**Solution:**
```bash
nix build .#package --show-trace  # Detailed build log
```

### "Infinite recursion"

**Meaning:** Circular dependency in Nix code

**Solution:** Check for self-referencing attributes

## Next Steps

Now that you understand Nix concepts:
- **Daily Usage:** [Common Workflows](02-daily-usage.md)
- **Troubleshooting:** [Common Issues](03-troubleshooting.md)
- **Advanced:** [Customization Guide](06-advanced.md)

## Resources

- **Official Manual:** https://nixos.org/manual/nix/stable/
- **Nix Pills:** https://nixos.org/guides/nix-pills/ (deep dive)
- **Nixpkgs Search:** https://search.nixos.org/packages
- **Nix Flakes RFC:** https://github.com/NixOS/rfcs/pull/49
