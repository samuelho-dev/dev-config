# sops-nix Setup Instructions

## Phase 1 Emergency Security Fixes - Complete ✅

This document provides step-by-step instructions for setting up sops-nix secrets management after the comprehensive Nix configuration refactoring.

## Prerequisites

- Nix with flakes enabled
- Home Manager
- 1Password (for SSH keys and existing secrets)

## Step 1: Generate Age Key

```bash
# Create sops configuration directory
mkdir -p ~/.config/sops/age

# Generate age encryption key
age-keygen -o ~/.config/sops/age/keys.txt

# Extract public key (you'll need this for .sops.yaml)
age-keygen -y ~/.config/sops/age/keys.txt
# Output: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Step 2: Configure .sops.yaml

Edit `.sops.yaml` and replace `YOUR_AGE_PUBLIC_KEY_HERE` with the public key from Step 1:

```bash
# Edit .sops.yaml
nvim .sops.yaml

# Replace this line:
# - &personal YOUR_AGE_PUBLIC_KEY_HERE
# With:
# - &personal age1xxxxxxxxx... (your actual public key)
```

## Step 3: Create Encrypted Secrets File

```bash
# Create and edit encrypted secrets file
# This will open in your $EDITOR (nvim by default)
sops secrets/default.yaml
```

Add your secrets in this format (sops will encrypt on save):

```yaml
# Git configuration
git:
  userName: "Your Name"
  userEmail: "your@example.com"
  signingKey: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your@example.com"

# Claude Code OAuth tokens
claude:
  oauth-token: "sk-ant-oat01-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# AI service API keys
ai:
  anthropic-key: "sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  openai-key: "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  google-ai-key: "AIzaSyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  litellm-master-key: "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Getting your existing values:**

```bash
# Git signing key (SSH public key)
cat ~/.ssh/id_ed25519.pub

# Fetch from 1Password if you have them stored there
op item get "ai" --vault "Dev" --fields label=ANTHROPIC_API_KEY
```

## Step 4: Stage Files for Nix Flakes

Nix flakes can only access Git-tracked files during evaluation:

```bash
# Stage sops configuration and encrypted secrets
git add -f .sops.yaml secrets/default.yaml

# Verify they're staged but gitignored
git status

# You should see:
# Changes to be committed:
#   new file:   .sops.yaml
#   new file:   secrets/default.yaml
```

**Important:** These files remain in "Changes to be committed" but won't actually commit because they're gitignored. This is intentional!

## Step 5: Apply Home Manager Configuration

```bash
# Update flake inputs to download sops-nix
nix flake update

# Apply configuration (this will fail the first time if secrets aren't set up)
home-manager switch --flake .#samuelho-macbook  # or .#samuelho-linux

# Or use direnv (automatically activates environment)
direnv allow
cd .  # Re-enter directory to trigger direnv
```

## Step 6: Verify Secrets Are Loaded

```bash
# Check that secrets are decrypted and accessible
ls -la /run/user/1000/secrets/

# Should show:
# git-signingKey
# git-userName
# git-userEmail
# claude-oauth-token
# ai-anthropic-key
# etc.

# Test git configuration
git config user.name
git config user.email
git config user.signingkey
```

## Troubleshooting

### Error: "secrets not found"

Make sure secrets/default.yaml is staged:
```bash
git add -f secrets/default.yaml
```

### Error: "age key not found"

Check that age key exists:
```bash
ls -la ~/.config/sops/age/keys.txt
```

### Error: "failed to decrypt"

Verify your age public key in .sops.yaml matches the key:
```bash
age-keygen -y ~/.config/sops/age/keys.txt
```

### Secrets not loading in shell

Check sops systemd service status:
```bash
systemctl --user status sops-nix
```

## Security Notes

### What's Encrypted
- ✅ secrets/default.yaml (encrypted with age)
- ✅ Age private key is on local machine only (~/.config/sops/age/keys.txt)

### What's In Git
- ✅ .sops.yaml (contains public key - safe to commit)
- ✅ secrets/default.yaml (encrypted - safe to commit)
- ✅ secrets/default.yaml.example (unencrypted template - safe)

### What's NOT In Git
- ❌ ~/.config/sops/age/keys.txt (age private key)
- ❌ /run/user/1000/secrets/* (decrypted secrets)

## Migrating from Old Patterns

### From secrets.nix

Old pattern:
```nix
# ~/.config/home-manager/secrets.nix (DEPRECATED)
{
  gitUserName = "Your Name";
  sshSigningKey = "ssh-ed25519 AAAAC3...";
}
```

New pattern:
```bash
# Add to secrets/default.yaml instead
sops secrets/default.yaml
```

### From 1Password `op read`

Old pattern:
```nix
# Shell alias with op read (INSECURE - exposed in process list)
"CLAUDE_CODE_OAUTH_TOKEN=$(op read 'op://Dev/ai/token')"
```

New pattern:
```yaml
# secrets/default.yaml
claude:
  oauth-token: "sk-ant-oat01-xxx..."
```

Token is loaded via sops into environment automatically.

## Next Steps

After setting up sops-nix:

1. **Remove old secrets.nix** (if it exists):
   ```bash
   rm -f ~/.config/home-manager/secrets.nix
   ```

2. **Remove user.nix** (now uses environment variables):
   ```bash
   # No longer needed - home.nix uses builtins.getEnv "USER" and "HOME"
   ```

3. **Test the configuration**:
   ```bash
   # Verify git is configured
   git config --list | grep user

   # Test a commit with signing
   git commit --allow-empty -m "Test commit signing"
   ```

4. **Backup your age key** (important for disaster recovery):
   ```bash
   # Copy age key to secure location (1Password, encrypted USB, etc.)
   cp ~/.config/sops/age/keys.txt /secure/backup/location/
   ```

## References

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [SOPS GitHub](https://github.com/getsops/sops)
- [Age Encryption](https://age-encryption.org/)
