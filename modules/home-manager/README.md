# Home Manager Modules

Declarative configuration for development tools via Nix Home Manager.

## Quick Start

```bash
# Enable all dev-config modules (default)
dev-config.enable = true;

# Or selectively enable programs
dev-config.neovim.enable = true;
dev-config.tmux.enable = false;  # Disable tmux
```

## Features

| Module | Description |
|--------|-------------|
| **neovim** | Neovim with LazyVim, LSP servers, formatters |
| **tmux** | Terminal multiplexer with Nix-managed plugins (no TPM) |
| **zsh** | Shell with Oh My Zsh + Powerlevel10k |
| **git** | Git with 1Password SSH commit signing |
| **ssh** | SSH with 1Password agent integration |
| **ghostty** | Ghostty terminal configuration |
| **yazi** | Terminal file manager |
| **claude-code** | Floating writable native CLI bootstrap only |
| **mcp** | Shared MCP configuration with per-agent targets |
| **biome** | Linting/formatting configuration |
| **direnv** | Per-project environments with nix-direnv |
| **sops-env** | AI secrets from sops-nix |

## Configuration

`dev-config.claude-code.enable` retains any existing CLI and otherwise runs the
official native installer for the floating latest release. The shared personal/work
profile and DevPod configuration enable it. Native installs remain writable and
self-updating; settings, OAuth, plugins and skills are untouched. See the
[bootstrap README](../../ai/claude/README.md).

Enable Claude MCP configuration independently with `dev-config.mcp.enable = true`
and `dev-config.mcp.targets.claude = true`. Home Manager no longer exports or
deletes global skills, commands or agents, adds no skip-permissions alias, and
does not set Claude proxy routing; existing installed copies are left intact.

### Disable a Program

```nix
# In home.nix
dev-config.neovim.enable = false;
```

### Use External Config Management

For tools managed by Chezmoi or other dotfile managers:

```nix
dev-config.neovim.configSource = null;  # Don't symlink config
```

### Custom Packages

Add extra packages to the Home Manager profile:

```nix
dev-config.packages.extraPackages = [ pkgs.kubectl pkgs.k9s ];
```

## Usage

### Apply Configuration

```bash
home-manager switch --flake ~/Projects/dev-config
```

### Test Without Applying

```bash
home-manager build --flake ~/Projects/dev-config
```

### View What Would Change

```bash
home-manager switch --flake ~/Projects/dev-config --dry-run
```

## Directory Structure

```
modules/home-manager/
+-- default.nix    # Module aggregator
+-- programs/      # 12 program modules
|   +-- neovim.nix
|   +-- tmux.nix
|   +-- zsh.nix
|   +-- git.nix
|   +-- ssh.nix
|   +-- ghostty.nix
|   +-- yazi.nix
|   +-- claude-code.nix
|   +-- mcp.nix
|   +-- biome.nix
|   +-- npm.nix
|   +-- typescript-strict.nix
+-- services/      # 2 service modules
    +-- direnv.nix
    +-- sops-env.nix
```

## Troubleshooting

### Config symlink conflicts

```bash
# Remove conflicting file
rm ~/.config/<tool>

# Re-apply
home-manager switch --flake .
```

### Missing dependencies

Check module is enabled:
```nix
dev-config.<module>.enable = true;
```

### View installed packages

```bash
home-manager packages
```

## Related Documentation

- [Parent CLAUDE.md](../../CLAUDE.md) - Repository overview
