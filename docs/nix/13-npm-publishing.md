# NPM Publishing Configuration

This guide covers configuring npm authentication for publishing packages to the
public npm registry from your local development environment, as implemented by
`modules/home-manager/programs/npm.nix`.

> **Scope note:** The npm module today configures **only the public npm registry
> (`registry.npmjs.org`)**. GitHub Packages dual-registry auth, a 1Password
> `sync-secrets.sh` script, and a `~/.config/home-manager/secrets.nix` file are
> **not** implemented in this repo. Where this guide mentions GitHub Packages, it
> is a manual `package.json` workflow, not something the module wires up.

## What the Module Actually Does

`modules/home-manager/programs/npm.nix`:

1. Reads the npm token from the **sops secret `npm/token`** (decrypted at Home
   Manager activation, never written to the Nix store).
2. Generates `~/.npmrc` at activation time with
   `//registry.npmjs.org/:_authToken=<token>` and any `extraConfig`.
3. Sets `~/.npmrc` to `600` permissions.
4. Installs `pnpm` (npm ships with `nodejs`).

If the `npm/token` secret is absent, the activation step is skipped and no
`~/.npmrc` is generated.

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
the token comes solely from the sops secret `npm/token`.

## Setup

### 1. Add the npm token to sops secrets

Generate an **Automation** token at npm (Account → Access Tokens → Generate New
Token), then add it to the encrypted secrets file:

```bash
sops secrets/default.yaml
```

```yaml
npm:
  token: npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> Editing `secrets/default.yaml` requires the age key at
> `~/.config/sops/age/keys.txt`. See [1Password SSH & CLI](09-1password-ssh.md)
> for the secrets bootstrap.

### 2. Enable the module and apply

In your `home.nix`:

```nix
dev-config.npm.enable = true;
```

```bash
cd ~/Projects/dev-config
home-manager switch --flake .
```

### 3. Verify `.npmrc` generation

```bash
cat ~/.npmrc
```

Expected output:

```ini
//registry.npmjs.org/:_authToken=npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

(plus any `extraConfig` lines you set).

**Security note:** `~/.npmrc` contains the plaintext token and is protected with
`600` permissions (user read/write only). It is regenerated on every
`home-manager switch`.

## Publishing Packages

### Publish to the npm Registry

```bash
# From your package directory
npm publish --access public

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

**Cause:** Token expired or invalid.

**Solution:**
1. Regenerate the token on npm.
2. Update it in `secrets/default.yaml` (`sops secrets/default.yaml`).
3. Re-run `home-manager switch --flake .` to regenerate `~/.npmrc`.

### `.npmrc` not generated

The activation step only runs when the `npm/token` sops secret exists and
`dev-config.npm.enable = true`.

```bash
# Confirm the secret is configured
grep -A1 '^npm:' <(sops -d secrets/default.yaml)

# Confirm the module is enabled and re-apply
home-manager switch --flake .
```

### "Package name must be scoped" (GitHub Packages)

GitHub Packages requires `@scope/package-name`. Update `package.json`
accordingly.

## Security Best Practices

1. **Use Automation tokens** for npm (not Publish tokens).
2. **Rotate tokens regularly** (every 90 days) and re-apply Home Manager.
3. **Never commit `~/.npmrc`** to Git.
4. The npm token is stored encrypted in `secrets/default.yaml` (age) and is never
   exposed to the Nix store — it is decrypted only at activation time.

## Related Documentation

- [1Password SSH & CLI](09-1password-ssh.md) — secrets bootstrap and `op` CLI
- [LiteLLM Proxy Setup](07-litellm-proxy-setup.md) — AI API key management
