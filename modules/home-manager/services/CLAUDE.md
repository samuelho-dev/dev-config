---
scope: modules/home-manager/services/
updated: 2025-12-21
relates_to:
  - ../CLAUDE.md
  - ../default.nix
  - ../programs/CLAUDE.md
validation:
  max_days_stale: 30
---

# Home Manager Service Modules

Architectural guidance for the 2 service modules that configure background services and environment setup.

## Purpose

This directory contains Nix modules for services that run in the background or provide environment-level configuration. Unlike program modules that configure applications, service modules handle cross-cutting concerns like environment variable loading and shell hook integration.

## Architecture Overview

Service modules follow the same Nix module pattern as programs but focus on:
- **Environment variables**: Setting up shell environment via `home.sessionVariables`
- **Shell hooks**: Adding code to `.zshenv`, `.zshrc`, or `.bashrc`
- **Activation scripts**: Running scripts during `home-manager switch`
- **Cross-program integration**: Enabling features across multiple programs

## File Structure

```
services/
+-- direnv.nix    # direnv + nix-direnv for per-project environments
+-- sops-env.nix  # sops-nix secret loading to environment variables
```

## Key Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| Session variables | direnv.nix:47-49 | `home.sessionVariables = { ... };` |
| Shell integration | direnv.nix:39 | `enableZshIntegration = true;` |
| Activation hooks | sops-env.nix:83 | `home.activation.generateLoadEnv = ...;` |
| DAG ordering | sops-env.nix:83 | `lib.hm.dag.entryAfter ["sops-nix"]` |
| Env extra | sops-env.nix:87-92 | `programs.zsh.envExtra = ''...''` |

## Module Reference

| Module | Purpose | Key Options | Integration Points |
|--------|---------|-------------|-------------------|
| **direnv.nix** | Per-project environments | `enable`, `enableNixDirenv` | zsh, nix-direnv |
| **sops-env.nix** | Secret environment vars | `enable` | sops-nix, zsh, bash |

### direnv.nix

Configures [direnv](https://direnv.net/) with [nix-direnv](https://github.com/nix-community/nix-direnv) integration for fast Nix shell loading.

**Features:**
- Auto-activates when entering directories with `.envrc`
- `nix-direnv` caches Nix shells for near-instant loading
- Suppresses verbose logging via `DIRENV_LOG_FORMAT`

**Usage:**
```bash
# In project directory
echo "use flake" > .envrc
direnv allow
# Nix environment auto-activates on cd
```

### sops-env.nix

Loads encrypted secrets from sops-nix into shell environment variables at activation time.

**Security model:**
1. Secrets encrypted in `secrets/default.yaml` with age key
2. sops-nix decrypts to tmpfs at `~/.local/share/sops-nix/secrets.d/`
3. Activation script generates `~/.config/sops-nix/load-env.sh`
4. Shell sources `load-env.sh` on startup

**Environment variables loaded:**
- `ANTHROPIC_API_KEY` - Claude API
- `OPENAI_API_KEY` - OpenAI API
- `GOOGLE_AI_API_KEY` - Google AI API
- `LITELLM_MASTER_KEY` - LiteLLM proxy
- `OPENROUTER_API_KEY` - OpenRouter API

**Benefits over 1Password CLI:**
- Zero latency (no CLI calls on shell startup)
- Works offline after initial decryption
- Same encryption mechanism as all secrets

## Adding/Modifying

### Creating a New Service Module

1. **Create the module file** `services/<name>.nix`:
   ```nix
   { config, lib, pkgs, ... }: let
     cfg = config.dev-config.<name>;
   in {
     options.dev-config.<name> = {
       enable = lib.mkOption {
         type = lib.types.bool;
         default = true;
         description = "Enable dev-config <name> service";
       };
     };

     config = lib.mkIf cfg.enable {
       # Session variables
       home.sessionVariables = { ... };

       # Or shell hooks
       programs.zsh.envExtra = ''...'';

       # Or activation scripts
       home.activation.<name> = lib.hm.dag.entryAfter ["writeBoundary"] ''...'';
     };
   }
   ```

2. **Add import to `default.nix`**:
   ```nix
   imports = [
     # ... existing imports
     ./services/<name>.nix
   ];
   ```

3. **Document in parent CLAUDE.md** (`../CLAUDE.md`)

### Activation Script DAG Ordering

Use `lib.hm.dag.entryAfter` to control execution order:
- `["writeBoundary"]` - After config files are written
- `["sops-nix"]` - After secrets are decrypted
- `["linkGeneration"]` - After symlinks are created

### Adding Environment Variables

For simple cases, use `home.sessionVariables`:
```nix
home.sessionVariables = {
  MY_VAR = "value";
};
```

For dynamic values, use shell hooks:
```nix
programs.zsh.envExtra = ''
  export MY_VAR="$(some-command)"
'';
```

## Common Issues

### Environment variables not loading

**Symptom:** `echo $VAR` shows empty

**Fixes:**
1. Check `enableZshIntegration = true` is set
2. Restart terminal (don't just source `.zshrc`)
3. For session variables: log out and back in
4. Check activation script ran: `ls ~/.config/sops-nix/`

### sops-env secrets not decrypting

**Symptom:** `load-env.sh` has empty values

**Fixes:**
1. Verify sops-nix is configured in `home.nix`
2. Check age key exists at `~/.config/sops/age/keys.txt`
3. Run `home-manager switch` (not just build)
4. Check secret paths in `sops.secrets.*`

### direnv not activating

**Symptom:** No auto-activation when cd into project

**Fixes:**
1. Run `direnv allow` in the project directory
2. Check `.envrc` exists and has valid content
3. Verify `DIRENV_LOG_FORMAT` isn't hiding errors

## For Future Claude Code Instances

- [ ] Use `lib.hm.dag.entryAfter` for activation script ordering
- [ ] Prefer `home.sessionVariables` over shell hooks when possible
- [ ] For secrets, use sops-env pattern (activation script + shell source)
- [ ] Always support both zsh and bash for shell hooks
- [ ] Document security implications when handling secrets
- [ ] Test with `home-manager switch --flake .` (not just build)
