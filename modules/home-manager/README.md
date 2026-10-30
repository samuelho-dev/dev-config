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
| **native-tools** | Enabled OMP, Pi, Claude, OpenCode, Codex and Vercel manifest plus missing-only writable native install |
| **mcp** | Shared MCP configuration with profile-selected Claude/OMP/Codex targets |
| **biome** | Linting/formatting configuration |
| **direnv** | Per-project environments with nix-direnv |
| **sops-env** | AI secrets from sops-nix |

## Configuration

Each `dev-config.omp`, `pi`, `claude-code`, `opencode`, `codex` and `vercel`
enable option selects that native tool in
`~/.config/dev-config/native-tools`. `native-tools.nix` invokes the one
`ai/bootstrap.sh install` owner after Nix package installation and
`ai/sync-skills.sh` for curated per-tool skill links. The CLIs live in writable
`~/.local`, not Nix packages: activation only fills missing tools, never
upgrades existing ones or enrolls OAuth. Explicit `bash ai/bootstrap.sh
update` upgrades the enabled native set; `bash ai/bootstrap.sh check`
verifies executable availability, not account authorization. The native
bootstrap supports stock macOS Bash. Skill sync preserves physical user
directories, edited skills and unmanaged links, advancing only links that
still point to their recorded previous source.

MCP is independent: `dev-config.mcp.enable` and the enabled
`dev-config.mcp.targets.{claude,omp,codex}` determine render targets. Select
`dev-config.mcp.authSource = "op"` or `"env"` explicitly (macOS defaults
to `op`, Linux to `env`); there is no fallback. Required missing credentials,
launchers or targets fail before replacing working configuration. Native
Vercel OAuth does not supply the community MCP: the `env` input is
`VERCEL_MCP_TOKEN`, rendered as child-only `VERCEL_TOKEN`. No global skills
directory is replaced, no skip-permissions alias or proxy is set.

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
cd ~/Projects/dev-config
nix run .#home-manager -- switch --flake .
```

### Test Without Applying

```bash
cd ~/Projects/dev-config
nix run .#home-manager -- build --flake .
```

### Evaluate Without Applying

```bash
nix eval --raw .#homeConfigurations.$(whoami).activationPackage.drvPath
```

## Directory Structure

```
modules/home-manager/
+-- default.nix    # Module aggregator
+-- programs/      # Program modules, including native-tools.nix
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

Preserve the existing file before an intentional activation. Do not remove
it just to allow a switch; inspect the target and use Home Manager's unique
backup extension if activation is approved (`switch -b <unused-extension>`).
Building/evaluating the derivation above does not activate or replace it.

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
