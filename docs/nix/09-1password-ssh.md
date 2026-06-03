# 1Password SSH Agent Integration

**Purpose:** Secure GitHub authentication and commit signing using 1Password SSH agent WITHOUT committing private keys to the repository.

**Target Audience:** Users who want declarative SSH configuration while keeping their repository public and SSH keys secure.

---

## Overview

### The Challenge

**Traditional SSH setup problems:**
- SSH private keys stored on disk (`~/.ssh/id_ed25519`)
- Risk of accidentally committing keys to Git
- Keys don't sync across machines
- Manual key management on each machine
- No biometric authentication

**The dev-config challenge:**
- Repository needs to be **PUBLIC**
- SSH configuration should be **declarative** (in Nix)
- Private keys must **NEVER** be committed
- Setup should be **automatable** on new machines

### The Solution

**1Password SSH Agent Integration:**
- SSH keys stored in 1Password (encrypted cloud vault)
- 1Password agent provides keys via local socket
- Private keys NEVER touch disk
- Biometric unlock (Touch ID / Windows Hello / Face ID)
- Keys sync automatically across machines
- Declarative Nix configuration

**What gets committed to PUBLIC repo:**
- ✅ SSH configuration (programs.ssh module)
- ✅ Git signing configuration (programs.git module)
- ✅ 1Password agent socket path
- ✅ GitHub-specific settings
- ✅ Template file (secrets.nix.example)

**What stays LOCAL (not committed):**
- ❌ SSH private keys (in 1Password only)
- ❌ Your Git user info (name/email)
- ❌ SSH public keys (in ~/.config/home-manager/secrets.nix)

---

## Architecture

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│  1Password App                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Encrypted Vault                                  │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  GitHub SSH Key (Ed25519)                   │  │  │
│  │  │  - Private key: [encrypted, never exported] │  │  │
│  │  │  - Public key: ssh-ed25519 AAAAC3...        │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
│           │                                             │
│           │ Provides keys via SSH agent socket         │
│           ▼                                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │  1Password SSH Agent                              │  │
│  │  Socket: ~/.1password/agent.sock (Linux)          │  │
│  │         ~/Library/.../agent.sock (macOS)          │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                       │
                       │ SSH client connects to socket
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Home Manager SSH Configuration                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  programs.ssh.extraConfig                         │  │
│  │  Host *                                           │  │
│  │    IdentityAgent "~/.1password/agent.sock"       │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                       │
                       │ SSH uses agent for authentication
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Git Operations                                         │
│  - git clone git@github.com:user/repo.git              │
│  - git push origin main                                 │
│  - git commit -S (signing)                              │
└─────────────────────────────────────────────────────────┘
```

### Security Benefits

**Private keys never touch disk:**
- Keys generated/imported in 1Password
- Stored encrypted in 1Password vault
- Only accessible via 1Password agent socket
- Agent requires biometric unlock

**Biometric authentication:**
- Touch ID (macOS)
- Windows Hello (Windows)
- Face ID (macOS with Face ID)
- System authentication (Linux)

**Encrypted at rest:**
- 1Password uses AES-256 encryption
- Master password + Secret Key
- End-to-end encryption

---

## Setup Instructions

### Prerequisites

**Required:**
- 1Password 8+ installed
- 1Password account with vault access
- Home Manager configured
- Git 2.34.0+ (for SSH signing)

**Optional but recommended:**
- GitHub account
- Existing dev-config repository

### Step 1: Enable 1Password SSH Agent

**1. Open 1Password settings:**
- macOS: 1Password → Settings → Developer
- Linux: 1Password → Settings → Developer
- Windows: 1Password → Settings → Developer

**2. Enable SSH agent:**
- ✅ Check "Use the SSH agent"
- ✅ Check "Display key names when authorizing connections"

**3. Verify agent is running:**
```bash
# macOS
ls -la ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Linux
ls -la ~/.1password/agent.sock
```

### Step 2: Generate or Import SSH Key

**Option A: Generate new key in 1Password (Recommended)**

1. Open 1Password
2. Click "New Item" → "SSH Key"
3. Name: "GitHub SSH Key"
4. Click "Generate a new key"
5. Key type: Ed25519 (recommended) or RSA 4096
6. Done!

**Option B: Import existing SSH key**

1. Open 1Password
2. Click "New Item" → "SSH Key"
3. Name: "GitHub SSH Key"
4. Click "Import" → Select your `~/.ssh/id_ed25519` file
5. Done!

### Step 3: Configure Git Commit Signing

**Automatic (Recommended):**

1. Open 1Password
2. Find your "GitHub SSH Key" item
3. Click "Configure Commit Signing"
4. Choose "Automatically" or "Manually"
5. 1Password configures Git for you!

**Manual (if automatic fails):**

```bash
# Set signing format to SSH
git config --global gpg.format ssh

# Set your SSH public key (from 1Password)
git config --global user.signingkey "ssh-ed25519 AAAAC3... your-email@example.com"

# Set op-ssh-sign program
# macOS:
git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"

# Linux:
git config --global gpg.ssh.program "op-ssh-sign"

# Sign commits by default
git config --global commit.gpgsign true
```

### Step 4: Add SSH Public Key to GitHub

**1. Get your public key:**

From 1Password:
- Open "GitHub SSH Key" item
- Click "Public Key"
- Copy to clipboard

Or using 1Password CLI:
```bash
op read "op://Dev/GitHub SSH Key/public key"
```

**2. Add to GitHub (do this TWICE):**

**Authentication Key:**
- Go to GitHub → Settings → SSH and GPG keys
- Click "New SSH key"
- Title: "dev-config (Authentication)"
- Key type: **Authentication Key**
- Paste public key
- Click "Add SSH key"

**Signing Key:**
- Click "New SSH key" again
- Title: "dev-config (Signing)"
- Key type: **Signing Key**
- Paste SAME public key
- Click "Add SSH key"

**Why twice?** GitHub requires separate entries for authentication (SSH push/pull) and signing (verified commits).

### Step 5: Create Machine-Specific Secrets

**1. Copy template:**
```bash
cp secrets.nix.example ~/.config/home-manager/secrets.nix
```

**2. Edit with your values:**
```bash
nvim ~/.config/home-manager/secrets.nix
```

**3. Fill in:**
```nix
{
  # Your Git identity
  gitUserName = "Your Name";
  gitUserEmail = "your-email@example.com";

  # Your SSH public key from 1Password (for commit signing)
  # Get from 1Password or: op read "op://Dev/GitHub SSH Key/public key"
  sshSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKey... your-email@example.com";
}
```

**4. Verify it's gitignored:**
```bash
git check-ignore ~/.config/home-manager/secrets.nix
# Should output: /Users/you/.config/home-manager/secrets.nix
```

### Step 6: Apply Home Manager Configuration

**1. Switch to new configuration:**
```bash
cd ~/Projects/dev-config
home-manager switch --flake .
```

**2. Verify SSH config:**
```bash
cat ~/.ssh/config | grep -A 2 "Host \*"
# Should show:
#   Host *
#     IdentityAgent "~/.1password/agent.sock"
```

**3. Verify Git config:**
```bash
git config --global --get gpg.format
# Should show: ssh

git config --global --get gpg.ssh.program
# Should show path to op-ssh-sign
```

### Step 7: Test SSH Authentication

**Test GitHub SSH:**
```bash
ssh -T git@github.com
```

**Expected behavior:**
1. 1Password popup appears
2. Requests biometric unlock (Touch ID / Windows Hello)
3. Shows "GitHub SSH Key" being used
4. Click "Allow" or unlock with biometric
5. Terminal shows: "Hi username! You've successfully authenticated..."

**If it fails:**
- Ensure 1Password agent is enabled (Settings → Developer)
- Verify agent socket exists (`ls -la ~/.1password/agent.sock`)
- Check SSH config (`cat ~/.ssh/config`)
- Run with debug: `ssh -vvv -T git@github.com`

### Step 8: Test Commit Signing

**Create test commit:**
```bash
cd ~/Projects/dev-config
git commit --allow-empty -m "test: verify SSH signing with 1Password"
```

**Expected behavior:**
1. 1Password popup appears
2. Requests biometric unlock
3. Shows "GitHub SSH Key" being used for signing
4. Commit completes

**Verify signature:**
```bash
git show --show-signature
```

**Expected output:**
```
Good "git" signature for your-email@example.com with ED25519 key SHA256:...
```

**Check on GitHub:**
- Push commit: `git push origin main`
- View commit on GitHub
- Should show green "Verified" badge

---

## Usage

### Daily Workflow

**SSH authentication:**
```bash
# Clone repository
git clone git@github.com:user/repo.git
# → 1Password popup, unlock with biometric

# Push changes
git push origin main
# → Uses cached authentication (no popup if recently unlocked)
```

**Commit signing:**
```bash
# Create commit (automatically signed)
git commit -m "feat: add new feature"
# → 1Password popup first time, then cached

# Verify signature
git show --show-signature
```

**1Password caching:**
- First SSH operation: Popup + biometric unlock
- Subsequent operations: Cached for ~5 minutes
- After cache expires: Popup again

### HTTPS → SSH Automatic Rewriting

**Configured by default:**
```nix
# modules/home-manager/programs/git.nix
url."ssh://git@github.com/".insteadOf = "https://github.com/";
```

**Benefit:**
```bash
# Clone with HTTPS URL
git clone https://github.com/user/repo.git

# Git automatically converts to SSH
# Actual: git clone git@github.com:user/repo.git
# → Uses 1Password SSH agent, no password prompts!
```

### Setting Up New Machine

**Steps:**
1. Install 1Password + sign in (keys sync automatically!)
2. Enable SSH agent (Settings → Developer)
3. Clone dev-config: `git clone https://github.com/user/dev-config.git`
4. Copy secrets template: `cp secrets.nix.example ~/.config/home-manager/secrets.nix`
5. Fill in secrets.nix (Git user info + SSH public key)
6. Apply: `home-manager switch --flake .`
7. Test: `ssh -T git@github.com`
8. Done! SSH works immediately

**No need to:**
- ❌ Generate new SSH keys
- ❌ Copy private keys
- ❌ Add keys to ssh-agent
- ❌ Configure Git signing manually
- ❌ Add public key to GitHub (already done once)

---

## 1Password CLI Authentication

The 1Password SSH agent handles SSH auth and commit signing without the CLI. The `op`
CLI is only needed for reading secrets (e.g. AI service keys stored in the `Dev` vault,
or the sops-nix bootstrap token). See [01-concepts.md](01-concepts.md) for the full
secrets model.

### Interactive Sign-In

```bash
op signin
```

Follow the prompts (account URL, email, secret key, master password). Verify:

```bash
op account get      # Shows your account details
op vault list       # Should list the "Dev" vault
```

Enable biometric unlock for faster re-auth from the 1Password desktop app
(Settings -> Developer / Security).

### Service Accounts for CI/CD

For non-interactive environments (GitHub Actions, containers, DevPod), use a
1Password service account instead of interactive sign-in:

1. Create a service account: https://1password.com/features/service-accounts
2. Store its token as a CI secret named `OP_SERVICE_ACCOUNT_TOKEN`.
3. Reference it in your workflow:

   ```yaml
   - name: Read secret
     env:
       OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
     run: op read "op://Dev/<item>/<field>"
   ```

This repo's sops-nix bootstrap stores an `op/service_account_token` for the same
purpose (declarative, non-interactive `op` access). See
[01-concepts.md](01-concepts.md).

---

## Troubleshooting

### SSH Authentication Fails

**Symptom:**
```
git@github.com: Permission denied (publickey).
```

**Diagnosis:**
```bash
# Test SSH with debug output
ssh -vvv -T git@github.com

# Check for:
# 1. "debug1: identity added:" → Key loaded from 1Password
# 2. "debug1: Offering public key:" → Key offered to GitHub
# 3. "debug1: Server accepts key:" → GitHub accepts key
```

**Fixes:**

**1. 1Password agent not running:**
```bash
# Check agent socket exists
ls -la ~/.1password/agent.sock  # Linux
ls -la ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock  # macOS

# If missing: Open 1Password → Settings → Developer → Enable SSH agent
```

**2. SSH not using 1Password agent:**
```bash
# Check SSH config
cat ~/.ssh/config | grep IdentityAgent

# Should show:
#   IdentityAgent "~/.1password/agent.sock"

# If missing: Run home-manager switch --flake .
```

**3. Public key not on GitHub:**
- Go to GitHub → Settings → SSH and GPG keys
- Verify your key is listed (both Authentication AND Signing)
- If missing: Add public key from 1Password

**4. Wrong key being used:**
```bash
# List keys in 1Password agent
ssh-add -L

# Should show your GitHub SSH key
# If shows multiple keys, 1Password will prompt which to use
```

### Commit Signing Fails

**Symptom:**
```
error: gpg failed to sign the data
fatal: failed to write commit object
```

**Diagnosis:**
```bash
# Check Git signing config
git config --global --get gpg.format
# Should be: ssh

git config --global --get gpg.ssh.program
# Should be path to op-ssh-sign

git config --global --get user.signingkey
# Should be your SSH public key
```

**Fixes:**

**1. op-ssh-sign not found:**
```bash
# macOS: Check path
ls -la /Applications/1Password.app/Contents/MacOS/op-ssh-sign

# Linux: Check if 1Password GUI installed
which op-ssh-sign
```

**2. Signing key not set:**
```bash
# Set manually
git config --global user.signingkey "ssh-ed25519 AAAAC3... your-email@example.com"

# Or: Let 1Password configure it
# 1Password → GitHub SSH Key → Configure Commit Signing
```

**3. Allowed signers file missing (optional):**
```bash
# Only needed for local verification
# Create allowed signers file
echo "your-email@example.com $(cat ~/.1password/agent.sock)" > ~/.ssh/allowed_signers

# Configure Git
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

### 1Password Popup Doesn't Appear

**Symptom:**
SSH/Git operations hang, no 1Password popup

**Fixes:**

**1. 1Password not running:**
```bash
# macOS: Check if running
pgrep -f 1Password

# Start 1Password app
open -a 1Password
```

**2. Display key names disabled:**
- 1Password → Settings → Developer
- ✅ Enable "Display key names when authorizing connections"
- Retry operation

**3. System authentication required:**
- Some systems require system unlock first
- Unlock your computer
- Retry operation

### Secrets.nix Not Found Error

**Symptom:**
```
error: path '/Users/you/.config/home-manager/secrets.nix' does not exist
```

**Fix:**
```bash
# Create secrets.nix from template
cp ~/Projects/dev-config/secrets.nix.example ~/.config/home-manager/secrets.nix

# Edit with your values
nvim ~/.config/home-manager/secrets.nix

# Re-run Home Manager
home-manager switch --flake ~/Projects/dev-config
```

### Commit Shows "Unverified" on GitHub

**Symptom:**
Commit signature shows "Unverified" badge instead of "Verified"

**Causes:**

**1. Signing key not added to GitHub:**
- GitHub → Settings → SSH and GPG keys
- Must add SAME key as both "Authentication" AND "Signing"

**2. Email mismatch:**
```bash
# Check commit email
git config --global --get user.email

# Check signing key email
git config --global --get user.signingkey
# Should match your GitHub email

# Fix: Update Git config
git config --global user.email "your-github-email@example.com"
```

**3. Wrong key type on GitHub:**
- Verify key type is "Signing Key" (not just "Authentication")
- Delete old key, re-add as "Signing Key"

---

## Advanced Usage

### Multiple GitHub Accounts

**Setup:**
```nix
# modules/home-manager/programs/ssh.nix
programs.ssh.matchBlocks = {
  "github.com-work" = {
    hostname = "github.com";
    user = "git";
    identityFile = "~/.ssh/id_work";  # Different 1Password SSH key
  };

  "github.com-personal" = {
    hostname = "github.com";
    user = "git";
    identityFile = "~/.ssh/id_personal";  # Your personal key
  };
};
```

**Usage:**
```bash
# Clone work repo
git clone git@github.com-work:company/repo.git

# Clone personal repo
git clone git@github.com-personal:user/repo.git
```

### Custom Allowed Signers (Local Verification)

**Purpose:** Verify signatures locally without GitHub

**Setup:**
```bash
# Create allowed signers file
cat > ~/.ssh/allowed_signers <<EOF
your-email@example.com ssh-ed25519 AAAAC3... your-email@example.com
teammate@example.com ssh-ed25519 AAAAC3... teammate@example.com
EOF

# Configure Git
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

**Usage:**
```bash
# Verify signature locally
git verify-commit HEAD

# Verify tag
git verify-tag v1.0.0
```

### SSH Agent Forwarding (Remote Development)

**Warning:** Only forward to trusted remote hosts!

**Setup:**
```nix
# modules/home-manager/programs/ssh.nix
programs.ssh.matchBlocks = {
  "devserver" = {
    hostname = "dev.example.com";
    user = "developer";
    forwardAgent = true;  # Enable agent forwarding
  };
};
```

**Usage:**
```bash
# SSH to remote server
ssh devserver

# On remote server, use your 1Password keys
git clone git@github.com:user/repo.git
# → Uses your local 1Password agent!
```

### Conditional SSH Configuration

**Use system ssh-agent on non-Nix machines:**

```nix
# In your secrets.nix or Home Manager config
{
  dev-config.ssh.onePasswordAgent.enable = lib.mkDefault (
    # Only use 1Password if installed
    builtins.pathExists "/Applications/1Password.app"  # macOS
    || builtins.pathExists "/usr/bin/1password"         # Linux
  );
}
```

---

## Security Best Practices

### Do's ✅

- ✅ Enable 1Password SSH agent
- ✅ Use Ed25519 keys (modern, secure, fast)
- ✅ Enable biometric unlock
- ✅ Keep 1Password app updated
- ✅ Use strong 1Password master password
- ✅ Enable 2FA on GitHub account
- ✅ Add SSH keys to GitHub as both Authentication AND Signing
- ✅ Review 1Password audit log regularly
- ✅ Keep secrets.nix gitignored

### Don'ts ❌

- ❌ Never commit secrets.nix to Git
- ❌ Never commit SSH private keys
- ❌ Never share 1Password Secret Key
- ❌ Never enable SSH agent forwarding to untrusted hosts
- ❌ Never reuse SSH keys across security boundaries
- ❌ Never disable SSH host key checking
- ❌ Never store private keys on disk when using 1Password

### Recommended Settings

**1Password:**
- Master password: 20+ characters, unique
- Secret Key: Store safely (physical backup)
- Auto-lock: 5-10 minutes
- Require biometric for SSH: Enabled

**GitHub:**
- 2FA: Enabled (TOTP or hardware key)
- SSH keys: Separate for each machine (audit trail)
- Signed commits: Required for protected branches
- Vigilant mode: Enabled (flags unsigned commits)

---

## Comparison with Alternatives

### vs. Traditional SSH (~/.ssh/id_ed25519)

| Feature | 1Password | Traditional SSH |
|---------|-----------|-----------------|
| Private key storage | Encrypted vault | Disk (plaintext or passphrase) |
| Key sync | Automatic | Manual copy |
| Biometric unlock | Yes | No (passphrase only) |
| Audit trail | Yes | No |
| Accidental commit risk | Zero | High |
| Setup complexity | Medium | Low |
| Security | Excellent | Good (if passphrase used) |

### vs. GPG Commit Signing

| Feature | SSH Signing | GPG Signing |
|---------|-------------|-------------|
| Setup complexity | Low | High |
| Key management | 1Password | GPG keyring |
| GitHub support | Native | Native |
| Verification | GitHub + local | GitHub + local |
| Key format | SSH (familiar) | GPG (complex) |
| Biometric unlock | Yes (1Password) | No (GPG passphrase) |

### vs. GitHub Deploy Keys

| Feature | 1Password SSH | Deploy Keys |
|---------|---------------|-------------|
| Scope | All repos | Single repo |
| Signing support | Yes | No |
| User identity | Personal | Machine/service |
| Audit trail | User-level | Repo-level |
| Biometric | Yes | No |
| Best for | Developer workflow | CI/CD, automation |

---

## Summary

**What you get:**
- ✅ Secure SSH authentication with 1Password
- ✅ Automatic Git commit signing
- ✅ Biometric unlock (Touch ID / Windows Hello)
- ✅ Public repository (no secrets committed)
- ✅ Declarative configuration (Home Manager)
- ✅ Easy setup on new machines
- ✅ GitHub "Verified" badges on all commits

**What stays secure:**
- 🔒 SSH private keys (in 1Password only)
- 🔒 Git user info (in secrets.nix, gitignored)
- 🔒 No credentials on disk
- 🔒 Biometric authentication required

**Next steps:**
1. Complete setup (8 steps above)
2. Test SSH: `ssh -T git@github.com`
3. Test signing: `git commit --allow-empty -m "test"`
4. Push to GitHub, verify "Verified" badge
5. Set up on other machines (reuse same 1Password keys!)

---

*For more information, see [1Password SSH Documentation](https://developer.1password.com/docs/ssh/) and [GitHub SSH Authentication](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).*
