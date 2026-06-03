# Nix Concepts and Mental Model

This guide covers only the mental model you need to work with **this repo**. For the Nix language and package manager itself, read the official material:

- Nix manual: https://nixos.org/manual/nix/stable/
- Nix Pills (deep dive): https://nixos.org/guides/nix-pills/
- Package search: https://search.nixos.org/packages

What you actually need to know: Nix is declarative. You describe the environment you want in `.nix` files, Nix builds it, and `flake.lock` pins exact versions so any machine reproduces the same result. Changes are atomic and rollback-able.

## How dev-config Is Wired

This repo is a **flake** managed with **Home Manager**. Three pieces matter:

### 1. Packages (`pkgs/default.nix`)

All tools are declared once, grouped by category (`core`, `runtimes`, `utilities`, `linting`). This is the single source of truth — never scatter package references across modules.

```nix
runtimes = [ pkgs.nodejs_24 pkgs.bun pkgs.uv ];
```

### 2. Modules (`modules/home-manager/programs/*.nix`)

Each program (neovim, tmux, git, zsh, ...) is a Home Manager module gated by a `dev-config.<program>.enable` option. Modules wire packages plus their config (symlinked dotfiles, generated settings). See `modules/home-manager/CLAUDE.md` for the module pattern.

### 3. Version locking (`flake.lock`)

`flake.lock` pins the exact `nixpkgs` revision. Same `flake.lock` = identical environment everywhere. Update it with `nix flake update`, review the diff, commit.

## The Activate Mental Model

Applying config = building a new Home Manager **generation** and switching the symlink forest in `$HOME` to point at it:

```bash
home-manager switch --flake .       # build + activate
home-manager build --flake .        # build only (no activation)
home-manager switch --flake . --dry-run   # preview
```

Every switch creates a new generation you can roll back to:

```bash
home-manager generations            # list
/nix/store/...-home-manager-generation/activate   # re-activate an older one
```

Dotfiles in `nvim/`, `tmux/`, etc. are **symlinked**, so editing them needs no rebuild — just reload the app. Only changes to `.nix` files require `home-manager switch`.

## Composed vs Standalone

This flake works two ways. Modules use the `inputs ? dev-config` pattern so `configSource` resolves whether the repo is used standalone (`home-manager switch --flake .` here) or imported as `inputs.dev-config` in another project. See root `CLAUDE.md` ("Flake Composition & devShellHook") for details.

## Common Build Errors

These are the canonical fixes; other guides link here.

| Error | Meaning | Fix |
|-------|---------|-----|
| `evaluation error` / `undefined variable` | Syntax/typo in a `.nix` file | `nix flake check` shows the location; fix the name |
| `attribute '...' missing` | Package name typo or not in nixpkgs | `nix search nixpkgs <name>` for the real name |
| `infinite recursion` | Self-referencing attribute | Remove the circular reference |
| `builder for '...' failed` | Compilation failed | `home-manager build --flake . --show-trace`; try `nix flake update` |

## Next Steps

- **Daily Usage:** [Common Workflows](02-daily-usage.md)
- **Troubleshooting:** [Common Issues](03-troubleshooting.md)
- **Testing changes:** [Testing](04-testing.md)
- **Advanced:** [Customization Guide](06-advanced.md)
