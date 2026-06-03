---
scope: modules/home-manager/
updated: 2026-06-03
relates_to:
  - ../../CLAUDE.md
  - ../../home.nix
  - ../../work-home.nix
  - ../../pkgs/default.nix
  - ./programs/neovim.nix
  - ./programs/tmux.nix
  - ./programs/zsh.nix
  - ./services/sops-env.nix
validation:
  max_days_stale: 30
---

# Home Manager Modules

Architectural guidance for Claude Code when working with the Home Manager module system.

## Purpose

This module system provides a declarative, composable way to configure user-level programs and services via Nix Home Manager. It enables the dev-config repository to be imported as a flake input by other projects, providing consistent development environments across machines.

## Architecture Overview

The module follows the standard Nix module pattern with `options` and `config` attributes. All program modules are imported by `default.nix` and can be individually enabled/disabled via `dev-config.<program>.enable`. Configuration sources support both bundled configs (from this repo) and external management (e.g., Chezmoi).

Key design decisions:
- **Explicit `lib.` prefixes**: Never use `with lib;` - always explicit imports
- **Flake composition support**: `inputs ? dev-config` pattern enables standalone and imported usage
- **DRY package management**: Centralized in `pkgs/default.nix`, imported once
- **Null config sources**: Set `configSource = null` to manage configs externally

## File Structure

```
modules/home-manager/
+-- default.nix              # Module aggregator, imports all programs/services
+-- programs/                # User program configurations
|   +-- biome.nix            # Biome linter/formatter
|   +-- claude-code.nix      # Claude Code AI assistant + MCP servers
|   +-- ghostty.nix          # Ghostty terminal emulator
|   +-- git.nix              # Git with 1Password SSH signing
|   +-- neovim.nix           # Neovim editor setup
|   +-- npm.nix              # NPM configuration
|   +-- opencode.nix         # Opencode CLI (Gemini OAuth)
|   +-- python.nix           # Python 3 + pip + dev tooling
|   +-- ssh.nix              # SSH with 1Password agent + DevPod Tailscale proxy
|   +-- tmux.nix             # Tmux terminal multiplexer
|   +-- yazi.nix             # Yazi file manager
|   +-- zsh.nix              # Zsh shell configuration
+-- services/                # Background services
    +-- direnv.nix           # direnv with nix-direnv
    +-- sops-env.nix         # sops-nix secret environment
```

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Module options structure | programs/*.nix:8-50 | Standard `options.dev-config.<name>` with enable, package, configSource |
| Flake input detection | programs/*.nix:23-25 | `if inputs ? dev-config then ... else null` for composition |
| Explicit lib prefixes | all files | `lib.mkOption`, `lib.mkIf` - never `with lib;` |
| Config source nullability | programs/*.nix:21-32 | `lib.types.nullOr lib.types.path` allows external config management |
| Centralized packages | default.nix:52-58 | `devPkgs = import ../../pkgs` - single source of truth |

## Module Reference

| Module | Purpose | Key Options |
|--------|---------|-------------|
| **default.nix** | Aggregates all modules, defines global options | `dev-config.enable`, `dev-config.packages.{enable,extraPackages}` |
| **programs/neovim.nix** | Neovim with LazyVim config | `enable`, `package`, `configSource`, `defaultEditor`, `vimAlias` |
| **programs/tmux.nix** | Tmux with Nix-managed plugins (no TPM) | `enable`, `package`, `gitmuxConfigSource`, `prefix`, `devpodConnect.enable` |
| **programs/zsh.nix** | Zsh with Oh My Zsh + Powerlevel10k | `enable`, `zshrcSource`, `zprofileSource`, `p10kSource` |
| **programs/git.nix** | Git with 1Password signing | `enable`, `userName`, `userEmail`, `signing.{enable,key}` |
| **programs/ssh.nix** | SSH with 1Password agent + DevPod proxy | `enable`, `devpods.{enable,user}`, `onePasswordAgent.{enable,socketPath}` |
| **programs/ghostty.nix** | Ghostty terminal config | `enable`, `package`, `configSource` |
| **programs/yazi.nix** | Yazi file manager | `enable`, `configSource` |
| **programs/claude-code.nix** | Claude Code + MCP servers + LiteLLM routing | `enable`, `litellm.enable`, `mcpServers`, `enableAllProjectMcpServers` |
| **programs/opencode.nix** | Opencode CLI with Gemini OAuth | `enable` |
| **programs/python.nix** | Python 3 + pip + dev tooling | `enable`, `package`, `enablePip`, `packages` |
| **programs/biome.nix** | Biome linting configs | `enable`, `package` |
| **programs/npm.nix** | NPM configuration | `enable` |
| **services/direnv.nix** | direnv + nix-direnv | `enable` |
| **services/sops-env.nix** | Secret environment variables | `enable`, `secretsFile` |

> Note: GritQL is installed as a binary via `pkgs/default.nix`. `biome.json` at
> the repo root references its patterns directly — no nix-side module needed.

## Service Modules

Service modules (`services/`) handle cross-cutting concerns (environment variable
loading, shell hooks, activation scripts) rather than configuring a single app.

| Pattern | Location | Purpose |
|---------|----------|---------|
| Session variables | direnv.nix:47-49 | `home.sessionVariables = { ... };` |
| Shell integration | direnv.nix:39 | `enableZshIntegration = true;` |
| Activation hooks | sops-env.nix:83 | `home.activation.generateLoadEnv = ...;` |
| DAG ordering | sops-env.nix:83 | `lib.hm.dag.entryAfter ["sops-nix"]` |

### sops-env.nix security model

Loads encrypted secrets into shell environment variables at activation time:

1. Secrets encrypted in `secrets/default.yaml` with age key
2. sops-nix decrypts to tmpfs at `~/.local/share/sops-nix/secrets.d/`
3. Activation script generates `~/.config/sops-nix/load-env.sh`
4. Shell sources `load-env.sh` on startup

**Environment variables loaded:** `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`,
`GOOGLE_AI_API_KEY`, `LITELLM_MASTER_KEY`, `OPENROUTER_API_KEY`.

**Benefits over 1Password CLI:** zero shell-startup latency, works offline after
initial decryption, same encryption mechanism as all secrets.

### Activation script DAG ordering

Use `lib.hm.dag.entryAfter` to control execution order:
- `["writeBoundary"]` — after config files are written
- `["sops-nix"]` — after secrets are decrypted
- `["linkGeneration"]` — after symlinks are created

Prefer `home.sessionVariables` for static values; use `programs.zsh.envExtra`
shell hooks only for dynamic values (e.g. `export VAR="$(some-command)"`).

## Adding/Modifying

### Adding a New Program Module

1. Create `programs/<name>.nix` with this structure:
   ```nix
   { config, lib, pkgs, inputs, ... }: {
     options.dev-config.<name> = {
       enable = lib.mkOption {
         type = lib.types.bool;
         default = true;
         description = "Enable dev-config <name> setup";
       };
       configSource = lib.mkOption {
         type = lib.types.nullOr lib.types.path;
         default = if inputs ? dev-config then "${inputs.dev-config}/<name>" else null;
       };
     };
     config = lib.mkIf config.dev-config.<name>.enable { ... };
   }
   ```

2. Add import to `default.nix`:
   ```nix
   imports = [
     # ... existing imports
     ./programs/<name>.nix
   ];
   ```

3. Document the module in this CLAUDE.md

### Modifying Module Options

1. Read existing module to understand current options
2. Add new options following the pattern (explicit `lib.` prefixes)
3. Update `config` section to use new options
4. Test with `home-manager build --flake .`

### Disabling a Program

Users can disable any program in their `home.nix`:
```nix
dev-config.neovim.enable = false;
dev-config.tmux.enable = false;
```

### Using External Config Management

Set `configSource = null` to prevent symlink creation:
```nix
dev-config.neovim.configSource = null;  # Manage with Chezmoi
```

## Common Issues

| Symptom | Fix |
|---------|-----|
| `home-manager switch` fails with "file exists" | Remove conflicting file, or set `home.file.<name>.force = true` |
| Program fails to start (missing binary) | Add required package to `home.packages` in the module |
| Tool doesn't auto-activate in shell | Ensure `enableZshIntegration = true` is set |
| Env var shows empty (`echo $VAR`) | Check `enableZshIntegration`, restart terminal (don't just source `.zshrc`), confirm activation ran: `ls ~/.config/sops-nix/` |
| `load-env.sh` has empty values | Verify sops-nix configured in `home.nix`, age key exists at `~/.config/sops/age/keys.txt`, run `home-manager switch` (not build) |
| direnv not activating on `cd` | Run `direnv allow` in project, check `.envrc` exists |

See root `CLAUDE.md` for general AI conventions and guardrails.
