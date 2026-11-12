# NPM Publishing Configuration

This guide covers npm authentication for publishing packages to the public npm
registry, as implemented by `modules/home-manager/programs/npm.nix`.

> **Scope note:** The npm module manages **only** `~/.npmrc` registry
> `extraConfig` (generated at activation, `600` permissions). Registry
> authentication is **not** managed here: publish with npm OIDC tokens
> (`npm publish --provenance`) or a per-project `.npmrc`. GitHub Packages
> dual-registry auth and a 1Password `sync-secrets.sh` script are **not**
> implemented in this repo. Where this guide mentions GitHub Packages, it is a
> manual `package.json` workflow, not something the module wires up.

## What the Module Actually Does

`modules/home-manager/programs/npm.nix`:

1. Generates `~/.npmrc` at activation time from `dev-config.npm.extraConfig`
   (never written to the Nix store).
2. Sets `~/.npmrc` to `600` permissions.
3. Sets `NPM_CONFIG_PREFIX` to `~/.local` so global npm packages never write
   into the Nix store.

There is no token handling: use npm's OIDC-based publishing (GitHub Actions or
local `npm login` auth) or a per-project `.npmrc` for registry auth.

## Module Options (`dev-config.npm`)

```nix
dev-config.npm = {
  enable = true;   # mkEnableOption — off by default; turn on to manage ~/.npmrc

  # Extra lines appended to the generated ~/.npmrc
  extraConfig = ''
    registry=https://registry.npmjs.org/
    save-exact=true
    engine-strict=true
  '';
};
```

There are **no** `npmToken`, `githubPackagesToken`, or `githubScope` options —
registry auth is owned by npm OIDC or a per-project `.npmrc`.

## Setup

### 1. Configure extraConfig

In your `home.nix`:

```nix
dev-config.npm.enable = true;
```

Optionally set `dev-config.npm.extraConfig` (see above).

### 2. Apply

```bash
cd ~/Projects/dev-config
home-manager switch --flake .
```

### 3. Verify `.npmrc` generation

```bash
cat ~/.npmrc
```

Expected output: your `extraConfig` lines (plus any local auth added outside
the module).

**Security note:** `~/.npmrc` is generated with `600` permissions (user
read/write only) and regenerated on every `home-manager switch`.

## Publishing Packages

### Publish to the npm Registry

Registry auth is not managed by this module. Use npm's OIDC-based publishing
(GitHub Actions with `id-token: write` and `npm publish --provenance`, or a
locally authenticated npm session), or a per-project `.npmrc`:

```bash
# From your package directory
npm publish --access public --provenance

# Or with pnpm
pnpm publish --access public --no-git-checks

# Or with bun
bun publish --access public
```

### Publishing to GitHub Packages (Manual)

> The npm module does **not** configure GitHub Packages. The steps below are a
> standard manual workflow you can use independently; they require you to add a
> GitHub Packages auth line to `~/.npmrc` yourself (e.g. via `extraConfig`, or a
> per-project `.npmrc`).

GitHub Packages requires scoped package names. In `package.json`:

```json
{
  "name": "@your-scope/your-package",
  "version": "1.0.0",
  "publishConfig": {
    "registry": "https://npm.pkg.github.com/"
  }
}
```

Add auth for the GitHub registry (replace `<GH_PAT>` with a PAT that has
`write:packages`):

```ini
@your-scope:registry=https://npm.pkg.github.com/
//npm.pkg.github.com/:_authToken=<GH_PAT>
```

Then publish:

```bash
npm publish
```

## Troubleshooting

### "Unauthorized" when publishing

**Cause:** Auth missing or expired in the active npm context (OIDC token, local
`npm login`, or per-project `.npmrc`).

**Solution:** Re-authenticate npm in the publishing context; this module adds no
token handling.

### `.npmrc` not generated

The activation step runs only when `dev-config.npm.enable = true` and
`extraConfig` is non-empty, so a locally authenticated `~/.npmrc` (e.g. `npm
login`) is never overwritten.

```bash
# Confirm the module is enabled and re-apply
home-manager switch --flake .
```

### "Package name must be scoped" (GitHub Packages)

GitHub Packages requires `@scope/package-name`. Update `package.json`
accordingly.

## Security Best Practices

1. Prefer OIDC-based publishing (no long-lived tokens) for npm.
2. Keep long-lived registry tokens in the publishing context (npm login or
   per-project `.npmrc`), never in this repo.
3. **Never commit `~/.npmrc`** to Git.

## Related Documentation

- [1Password SSH & CLI](09-1password-ssh.md) — secrets bootstrap and `op` CLI
- [LiteLLM Proxy Setup](07-litellm-proxy-setup.md) — AI API key management
