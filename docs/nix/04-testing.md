# Testing Nix Configuration Changes

Validate Home Manager configuration changes before applying them, so a syntax or build error never breaks your live environment.

## The Three Commands

`home-manager switch` applies changes immediately. Test first with one of these, in increasing order of thoroughness:

| Command | Speed | What it does | What it does NOT do |
|---------|-------|--------------|---------------------|
| `nix flake check` | Fast | Evaluates flake outputs, catches syntax/eval errors | Build user packages, validate HM activation |
| `home-manager build --flake .` | Moderate (cached: <30s) | Evaluates + builds the generation, writes `./result` | Activate, touch `$HOME`, run activation scripts |
| `home-manager switch --flake . --dry-run` | Slower | Builds + shows the diff of symlinks/packages that would change | Permanently activate (some activation scripts may still run — known HM limitation) |

```bash
nix flake check
home-manager build --flake .
home-manager switch --flake . --dry-run
```

## Recommended Workflow

```bash
# 1. Edit
nvim modules/home-manager/programs/neovim.nix

# 2. Validate -> build -> preview
nix flake check
home-manager build --flake .
home-manager switch --flake . --dry-run

# 3. Apply
home-manager switch --flake .

# 4. Verify
nvim --version
ls -la ~/.config/nvim
```

During fast iteration, run `nix flake check` after each edit; run the build/dry-run before switching.

## Pre-Commit Syntax Check

The repo's pre-commit hook runs flake evaluation on staged `.nix` files automatically. Run it manually:

```bash
pre-commit run --all-files
```

## Common Failures

**`nix flake check` — `undefined variable 'progams'`**
Typo in an option name. Fix: `programs.git.enable = true;`.

**`nix flake check` — `infinite recursion encountered`**
Circular reference in a module. Review imports and self-referential options.

**`home-manager build` — `builder for '/nix/store/...' failed`**
Package build failure. Inspect with:

```bash
home-manager build --flake . --show-trace
nix build nixpkgs#<package> --log-format bar-with-logs
```

**`home-manager build` — `attribute '...' missing`**
Package not in nixpkgs (or wrong scope). Find the real name:

```bash
nix search nixpkgs <keyword>
```

**Dry-run downloads many packages / runs some scripts**
Expected. `--dry-run` pulls from the binary cache and, due to a known Home Manager limitation, may execute some activation scripts. Use `home-manager build` for the safest no-side-effect check.

## Testing Specific Modules

```bash
# Build just one program's package
nix build '.#homeConfigurations.<user>.config.programs.neovim.finalPackage'
```

## Rollback Plan

If an applied switch misbehaves:

```bash
home-manager generations            # list past generations
git checkout HEAD~1 flake.lock       # revert package versions
home-manager switch --flake .
```

---

See the [Home Manager Manual](https://nix-community.github.io/home-manager/) and [Nix Reference Manual](https://nixos.org/manual/nix/stable/).
