# NPM Publishing Configuration

> **✅ INTEGRATED WITH SOPS-NIX**
>
> As of January 2025, the npm module is fully integrated with sops-nix for secure token management. Tokens are encrypted in `secrets/default.yaml` and never exposed to the Nix store.
>
> **Security benefits:**
> - Tokens encrypted at rest using age encryption
> - Tokens decrypted only during Home Manager activation
> - Tokens injected into `~/.npmrc` with 600 permissions
> - No secrets in Nix store or evaluation output

This guide covers configuring npm authentication for publishing packages to both the public npm registry and GitHub Packages from your local development environment.

## Overview

The dev-config npm module provides:
- **Dual-registry authentication**: Publish to both registry.npmjs.org and npm.pkg.github.com
- **1Password integration**: Tokens stored securely in 1Password vault
- **Automatic .npmrc generation**: Home Manager creates config with token injection
- **Multi-package-manager support**: Works with npm, pnpm, and bun

## Architecture

```
1Password Vault (Dev)
├── npm.js item → ACCESS_TOKEN field
└── Github item → GITHUB_PACKAGES_TOKEN field
         ↓
   sync-secrets.sh (fetches tokens)
         ↓
   ~/.config/dev-config/secrets/
   ├── NPM_TOKEN
   └── GITHUB_PACKAGES_TOKEN
         ↓
   ~/.config/home-manager/secrets.nix (imports tokens)
         ↓
   modules/home-manager/programs/npm.nix (generates .npmrc)
         ↓
   ~/.npmrc (final configuration)
```

## Prerequisites

### 1. NPM Account & Token

**Create npm account:**
1. Sign up at https://www.npmjs.com
2. Verify email address

**Generate authentication token:**
1. Log in to https://www.npmjs.com
2. Go to: Account → Access Tokens → Generate New Token
3. Token type: **Automation** (for CI/CD) or **Publish** (for manual publishing)
4. Copy the token (starts with `npm_...`)

**Store in 1Password:**
```bash
# The token is already stored at:
# op://Dev/npm.js/ACCESS_TOKEN

# Verify:
op read "op://Dev/npm.js/ACCESS_TOKEN"
```

### 2. GitHub Personal Access Token (for GitHub Packages)

**Generate PAT:**
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Required scopes:
   - `repo` (Full control of private repositories)
   - `write:packages` (Upload packages to GitHub Package Registry)
   - `read:packages` (Download packages from GitHub Package Registry)
4. Copy the token (starts with `ghp_...` or `gho_...`)

**Already stored in 1Password:**
```bash
# Your GitHub PAT is stored at:
# op://Dev/Github/GITHUB_PACKAGES_TOKEN

# Verify:
op read "op://Dev/Github/GITHUB_PACKAGES_TOKEN"
```

## Setup

### 1. Configure secrets.nix

Create or update `~/.config/home-manager/secrets.nix`:

```nix
{
  # Git configuration (existing)
  gitUserName = "Your Name";
  gitUserEmail = "your-email@example.com";
  sshSigningKey = "ssh-ed25519 AAAAC3...";

  # NPM Publishing tokens (add these)
  npmToken = "npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  githubPackagesToken = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
}
```

**Option 1: Use actual token values** (tokens stored in Nix store, readable in .npmrc)

```nix
{
  npmToken = "npm_actual_token_here";
  githubPackagesToken = "ghp_actual_token_here";
}
```

**Option 2: Reference 1Password** (requires sync-secrets.sh)

```nix
{
  npmToken = builtins.readFile /Users/samuelho/.config/dev-config/secrets/NPM_TOKEN;
  githubPackagesToken = builtins.readFile /Users/samuelho/.config/dev-config/secrets/GITHUB_PACKAGES_TOKEN;
}
```

### 2. Sync tokens from 1Password

Run the sync script to fetch tokens:

```bash
bash ~/Projects/dev-config/scripts/sync-secrets.sh
```

**What this does:**
- Fetches NPM_TOKEN from `op://Dev/npm.js/ACCESS_TOKEN`
- Fetches GITHUB_PACKAGES_TOKEN from `op://Dev/Github/GITHUB_PACKAGES_TOKEN`
- Caches to `~/.config/dev-config/secrets/`
- Sets permissions to 600 (user read/write only)

**Output:**
```
ℹ️  Syncing secrets from 1Password (service account, zero biometrics)...
✅ Authenticated with service account (no biometrics!)
ℹ️  Fetching NPM publishing tokens from 1Password...
✅ ✓ NPM_TOKEN
✅ ✓ GITHUB_PACKAGES_TOKEN
✅ Secrets synced successfully!
```

### 3. Apply Home Manager configuration

```bash
cd ~/Projects/dev-config
home-manager switch --flake .
```

**What this does:**
- Imports tokens from `secrets.nix`
- Generates `~/.npmrc` with authentication
- Installs pnpm package manager
- Sets file permissions to 600 on .npmrc

### 4. Verify .npmrc generation

```bash
cat ~/.npmrc
```

**Expected output:**
```ini
//registry.npmjs.org/:_authToken=npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
@samuelho-dev:registry=https://npm.pkg.github.com/
//npm.pkg.github.com/:_authToken=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Security note:** The .npmrc file contains plaintext tokens. It's protected with 600 permissions (user read/write only).

## Publishing Packages

### Publish to npm Registry

```bash
# From your package directory
npm publish --access public

# Or with pnpm
pnpm publish --access public --no-git-checks

# Or with bun
bun publish --access public
```

### Publish to GitHub Packages

**Important:** GitHub Packages requires scoped package names.

**Option 1: Scoped package name in package.json**

```json
{
  "name": "@samuelho-dev/your-package",
  "version": "1.0.0",
  "publishConfig": {
    "registry": "https://npm.pkg.github.com/"
  }
}
```

Then publish:
```bash
npm publish

# Or with pnpm
pnpm publish --no-git-checks

# Or with bun
bun publish
```

**Option 2: Publish with explicit registry**

```bash
npm publish --registry https://npm.pkg.github.com/

# Or with pnpm
pnpm publish --registry https://npm.pkg.github.com/ --no-git-checks
```

### Publish to Both Registries

**Publish to npm first:**
```bash
npm publish --access public
```

**Then publish to GitHub Packages:**
```bash
# Update package.json with scoped name
node -e "
  const pkg = require('./package.json');
  const originalName = pkg.name;
  pkg.name = '@samuelho-dev/' + originalName;
  require('fs').writeFileSync('./package.json', JSON.stringify(pkg, null, 2));
"

# Publish to GitHub
npm publish --registry https://npm.pkg.github.com/

# Restore original name
git checkout package.json
```

## Configuration Options

### Module Options (modules/home-manager/programs/npm.nix)

```nix
# In your Home Manager configuration
dev-config.npm = {
  enable = true;  # Default: true

  # Override tokens (optional)
  npmToken = "npm_...";
  githubPackagesToken = "ghp_...";

  # Change GitHub username/org for scoped packages
  githubScope = "samuelho-dev";  # Default: "samuelho-dev"

  # Add custom .npmrc configuration
  extraConfig = ''
    registry=https://registry.npmjs.org/
    save-exact=true
    engine-strict=true
  '';
};
```

### Disable npm Module

```nix
# If you manage .npmrc manually
dev-config.npm.enable = false;
```

## Troubleshooting

### "Unauthorized" when publishing

**Cause:** Token expired or invalid

**Solution:**
1. Regenerate token on npm.com or GitHub
2. Update in 1Password
3. Re-run `bash scripts/sync-secrets.sh --force`
4. Re-run `home-manager switch --flake ~/Projects/dev-config`

### "Package name must be scoped" (GitHub Packages)

**Cause:** GitHub Packages requires `@username/package-name` format

**Solution:**
Update package.json:
```json
{
  "name": "@samuelho-dev/your-package"
}
```

### .npmrc not generated

**Check secrets.nix exists:**
```bash
ls -la ~/.config/home-manager/secrets.nix
```

**Check npm module is enabled:**
```bash
home-manager generations | head -1
# Then check the generated config
```

### Token not found in 1Password

**Verify item exists:**
```bash
op item get 2rab3yvvug2zlr6klynxpztsua --fields label=ACCESS_TOKEN
op item get vtcsjphterploxdgzvsu3rm7le --fields label=GITHUB_PACKAGES_TOKEN
```

**Check vault access:**
```bash
op vault list
op vault get cv7j7tu2q76z43dhchuq6rljca
```

## Security Best Practices

1. **Use Automation tokens** for npm (not Publish tokens)
2. **Rotate tokens regularly** (every 90 days)
3. **Limit GitHub PAT scopes** (only repo, write:packages, read:packages)
4. **Never commit .npmrc** to Git (already in .gitignore)
5. **Use 1Password service account** for zero-biometric token fetching

## Integration with Other Projects

When using dev-config as a flake input in other projects:

```nix
# In your project's flake.nix
{
  inputs.dev-config.url = "github:samuelho-dev/dev-config";

  outputs = { self, nixpkgs, home-manager, dev-config, ... }: {
    homeConfigurations.youruser = home-manager.lib.homeManagerConfiguration {
      modules = [
        dev-config.homeManagerModules.default
        {
          dev-config.npm = {
            enable = true;
            # Tokens imported from ~/.config/home-manager/secrets.nix
          };
        }
      ];
    };
  };
}
```

## Related Documentation

- [1Password Setup](05-1password-setup.md) - 1Password CLI authentication
- [SSH Authentication](09-1password-ssh.md) - SSH key management with 1Password
- [LiteLLM Proxy Setup](07-litellm-proxy-setup.md) - AI API token management

## Reference

**1Password Item UUIDs:**
- npm.js: `2rab3yvvug2zlr6klynxpztsua` (Dev vault)
- Github: `vtcsjphterploxdgzvsu3rm7le` (Dev vault)

**Token Fields:**
- NPM: `ACCESS_TOKEN` field in npm.js item
- GitHub: `GITHUB_PACKAGES_TOKEN` field in Github item

**Cache Location:**
- `~/.config/dev-config/secrets/NPM_TOKEN`
- `~/.config/dev-config/secrets/GITHUB_PACKAGES_TOKEN`

**Generated Config:**
- `~/.npmrc` (600 permissions)
