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
| **native-tools** | Enabled OMP, Pi, Claude, OpenCode, Codex, Vercel and optional Rex Worktrees manifest plus missing-only writable native install |
| **mcp** | Shared MCP configuration with profile-selected Claude/OMP/Codex targets |
| **biome** | Linting/formatting configuration |
| **direnv** | Per-project environments with nix-direnv |
| **sops-env** | AI secrets from sops-nix |

## Configuration

Each `dev-config.omp`, `pi`, `claude-code`, `opencode`, `codex`, `vercel`
and `rex-worktrees` enable option selects that native tool in
`~/.config/dev-config/native-tools`. `native-tools.nix` invokes the one
`ai/bootstrap.sh install` owner after Nix package installation and
`ai/sync-skills.sh` for curated per-tool skill links. The CLIs live in writable
`~/.local`, not Nix packages: activation only fills missing tools, never
upgrades existing ones or enrolls OAuth. Explicit `bash ai/bootstrap.sh
update` upgrades the selected native set; `bash ai/bootstrap.sh check`
verifies executable availability, not account authorization. Rex Worktrees
registers its Lua module offline before the binding loader is appended to
the user-owned Rex init; it neither starts Rex nor reloads a running server.
Skill sync preserves physical directories, edited skills and unmanaged links,
advancing only links still pointing to their recorded previous source.

MCP is independent: `dev-config.mcp.enable` and the enabled
`dev-config.mcp.targets.{claude,omp,codex}` determine render targets. Select
`dev-config.mcp.authSource = "op"` or `"env"` explicitly (macOS defaults
to `op`, Linux to `env`); there is no fallback. Required missing credentials,
launchers or targets fail before replacing working configuration. Native
Vercel OAuth does not supply the community MCP: the `env` input is
`VERCEL_MCP_TOKEN`, rendered as child-only `VERCEL_TOKEN`. No global skills
directory is replaced, no skip-permissions alias or proxy is set.

Review notes use the native `tuicr` app, installed and updated by manually
applying the opt-in `pkgs/Brewfile` on macOS (not by Home Manager or
`scripts/install.sh`). Run `tuicr -w` to review working-tree changes. Press
`c`, type a note and press Enter to save; for a range, select it with `v`
before pressing `c`. `y` or `:clip` copies the saved review with file/line
references rather than source excerpts. `:q` exits; reopen to resume saved
reviews. No tuicr Home Manager module or theme is configured.

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

When Neovim is enabled with non-null `configSource`, Home Manager provides
`update-neovim-plugins` and schedules it daily (launchd on macOS, user systemd
timer on Linux). Logs and Lazy's writable lock are under
`$XDG_STATE_HOME/nvim/`. The updater honors configured plugin branch/version
bounds but does not activate Home Manager or upgrade Nix-managed tools. A
headless Linux container without user systemd needs a manual run or its own
scheduler.

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
