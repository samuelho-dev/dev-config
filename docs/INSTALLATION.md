# Installation Guide

Complete installation guide for dev-config across different platforms.

## Prerequisites

### Required
- **Git** - Version control
- **Zsh** - Shell (or willingness to switch from bash)

### Auto-Installed by `install.sh`
The following will be installed automatically if missing:
- **Homebrew** (macOS only)
- **Docker** (20.10+) - Container platform
- **Neovim** (0.9.0+)
- **tmux** (1.9+)
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep
- **lazygit** - Git TUI
- **make** - Build tools (telescope-fzf-native)
- **node** - Node.js runtime
- **npm** - Node package manager
- **imagemagick** - Image processing
- **Docker Compose** - Container orchestration (optional)
- **Oh My Zsh** - Zsh framework
- **Powerlevel10k** - Zsh theme
- **zsh-autosuggestions** - Zsh plugin
- **TPM** - Tmux Plugin Manager

### Mason-Installed Tools (via Neovim)
These are automatically installed when you first open Neovim:

**LSP Servers:**
- **ts_ls** - TypeScript/JavaScript language server
- **pyright** - Python language server  
- **lua_ls** - Lua language server (for Neovim config)

**Formatters:**
- **stylua** - Lua code formatter
- **prettier** - JavaScript/TypeScript/JSON/YAML/Markdown formatter
- **ruff** - Python formatter and linter

### Optional (Install Manually)
- **GitHub CLI (`gh`)** - For PR/issue management in Neovim
  ```bash
  # macOS
  brew install gh

  # Linux (Debian/Ubuntu)
  sudo apt install gh

  # Authenticate after installing
  gh auth login
  ```

- **pkg-config** - For blink.cmp Rust optimization (optional)
  ```bash
  # macOS
  brew install pkg-config

  # Linux (Debian/Ubuntu)
  sudo apt install pkg-config
  ```

---

## Fresh Installation

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/dev-config ~/Projects/dev-config
cd ~/Projects/dev-config
```

### 2. Run Installer
```bash
bash scripts/install.sh
```

**What the installer does:**
1. ✅ Checks for sudo (script should run as normal user)
2. ✅ Verifies repository structure
3. ✅ Installs Homebrew (macOS) if missing
4. ✅ Installs core dependencies (git, zsh, neovim, tmux, fzf, ripgrep, lazygit)
5. ✅ Checks tool versions (Neovim ≥ 0.9.0, tmux ≥ 1.9)
6. ✅ Installs Oh My Zsh + Powerlevel10k + zsh-autosuggestions
7. ✅ Installs TPM (Tmux Plugin Manager)
8. ✅ Creates backups of existing configs (timestamped)
9. ✅ Creates symlinks from home directory → repository
10. ✅ Creates `~/.zshrc.local` for machine-specific config
11. ✅ Auto-installs Neovim plugins (via Lazy.nvim)
12. ✅ Auto-installs tmux plugins (via TPM)
13. ✅ Verifies installation

**Zero manual intervention required!**

### 3. Restart Terminal
```bash
exec zsh
```

### 4. Done!
Open Neovim and tmux - everything should work automatically.

---

## 1Password SSH Setup (Recommended)

Secure SSH authentication and Git commit signing using 1Password SSH Agent. This approach stores private keys in your encrypted 1Password vault instead of on disk.

### Why 1Password SSH Agent?

**Security:**
- Private keys never touch disk (encrypted in 1Password vault)
- Biometric unlock (Touch ID/Face ID/Windows Hello)
- No secrets committed to Git (safe for public repos)

**Convenience:**
- Keys sync across all your devices via 1Password
- No manual SSH key management
- Auto-fill for SSH passphrases
- Commit signing with single setup

### Prerequisites

1. **1Password Account** - [Sign up](https://1password.com) (free for personal use)
2. **1Password Desktop App** - Install from website or:
   ```bash
   # macOS
   brew install --cask 1password
   ```
3. **1Password CLI** (auto-installed by `install.sh`)

### Step 1: Enable 1Password SSH Agent

**macOS/Windows:**
1. Open 1Password desktop app
2. Settings → Developer
3. Enable **"Use the SSH agent"**
4. Enable **"Display key names when authorizing connections"** (optional but helpful)

**Linux:**
See [1Password SSH Agent Setup Guide](https://developer.1password.com/docs/ssh/get-started#step-3-turn-on-the-1password-ssh-agent)

### Step 2: Create or Import SSH Key

**Option A: Generate new SSH key in 1Password (Recommended)**

1. 1Password desktop app → **New Item** → **SSH Key**
2. **Name:** "GitHub SSH Key"
3. Click **"Generate a new key"**
4. **Key Type:** Ed25519 (recommended) or RSA 4096
5. **Save**

**Option B: Import existing SSH key**

1. 1Password desktop app → **New Item** → **SSH Key**
2. **Name:** "GitHub SSH Key"
3. **Private Key:** Paste contents of `~/.ssh/id_ed25519`
4. **Public Key:** Paste contents of `~/.ssh/id_ed25519.pub`
5. **Save**

### Step 3: Get Your SSH Public Key

**From 1Password Desktop:**
1. Open your SSH key item
2. Click **"Copy Public Key"**

**From CLI:**
```bash
# After authenticating 1Password CLI
op read "op://Dev/GitHub SSH Key/public key"
```

**Manual extraction (if needed):**
```bash
# View all SSH keys in 1Password
ssh-add -L
```

### Step 4: Add SSH Key to GitHub

Add your SSH public key to GitHub for **both authentication and signing**.

**For Authentication (Required):**
1. GitHub → **Settings** → **SSH and GPG keys**
2. **New SSH key** → **Authentication key**
3. **Title:** "1Password - [Your Computer Name]"
4. **Key:** Paste public key (starts with `ssh-ed25519` or `ssh-rsa`)
5. **Add SSH key**

**For Signing (Recommended):**
1. GitHub → **Settings** → **SSH and GPG keys**
2. **New SSH key** → **Signing key**
3. **Title:** "1Password - Signing Key"
4. **Key:** Paste the **same** public key
5. **Add SSH key**

**Test authentication:**
```bash
ssh -T git@github.com
# Expected: "Hi <username>! You've successfully authenticated..."
```

### Step 5: Create secrets.nix

Create machine-specific configuration file (gitignored, not committed):

```bash
# Copy template
cp secrets.nix.example ~/.config/home-manager/secrets.nix

# Edit with your details
nvim ~/.config/home-manager/secrets.nix
```

**Example secrets.nix:**
```nix
{
  # Your Git identity (used for commits)
  gitUserName = "Your Name";
  gitUserEmail = "your-email@example.com";

  # Your SSH public key from 1Password (for commit signing)
  # Get from 1Password or: op read "op://Dev/GitHub SSH Key/public key"
  sshSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-email@example.com";
}
```

**Important:**
- Replace with your actual values
- Use the **same public key** you added to GitHub
- Never commit this file (already gitignored)

### Step 6: Apply Configuration

```bash
# Activate Nix environment (if using Nix)
cd ~/Projects/dev-config
nix run .#activate

# Or reload shell config
source ~/.zshrc
```

### Step 7: Verify Setup

**Test SSH authentication:**
```bash
ssh -T git@github.com
# Expected: "Hi <username>! You've successfully authenticated..."
```

**Test Git commit signing:**
```bash
cd ~/Projects/dev-config
git commit --allow-empty -m "Test commit signing"
git log --show-signature -1
# Should show "Good signature" with your SSH key
```

**Test 1Password CLI:**
```bash
# Should prompt for 1Password authentication
op whoami
```

### Troubleshooting 1Password SSH

**"Could not open a connection to your authentication agent"**
- Ensure 1Password SSH agent is enabled in settings
- Restart 1Password desktop app
- Check socket path:
  ```bash
  # macOS
  ls -la ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

  # Linux
  ls -la ~/.1password/agent.sock
  ```

**"Permission denied (publickey)"**
- Verify SSH key added to GitHub (Authentication key)
- Test with verbose output: `ssh -Tvvv git@github.com`
- Check 1Password SSH agent logs in 1Password desktop app

**"Bad signature" when verifying commits**
- Ensure SSH key added to GitHub as **Signing key** (not just Authentication)
- Verify `sshSigningKey` in `secrets.nix` matches GitHub public key
- Check Git config: `git config --get gpg.ssh.program`

**"op: not found" errors**
- Ensure 1Password CLI installed: `which op`
- If missing, install manually:
  ```bash
  brew install 1password-cli
  ```

For more troubleshooting, see [docs/nix/08-1password-ssh.md](nix/08-1password-ssh.md)

---

## Installing on Additional Machines

On any other machine:

```bash
git clone https://github.com/yourusername/dev-config ~/Projects/dev-config
cd ~/Projects/dev-config
bash scripts/install.sh
```

All configs and plugins will be set up identically.

---

## Platform-Specific Notes

### macOS
- Homebrew will be installed automatically
- Ghostty config path: `~/Library/Application Support/com.mitchellh.ghostty/config`
- Python paths in `.zprofile` are macOS Framework Python installations

### Linux
- Uses system package manager (apt/dnf/pacman/zypper)
- Ghostty config path: `~/.config/ghostty/config`
- Homebrew detection includes Linuxbrew paths

### Windows/WSL
- Not officially supported yet
- WSL users: treat as Linux installation

---

## Validation

After installation, verify everything is working:

```bash
bash scripts/validate.sh
```

This will check:
- ✅ Repository structure
- ✅ Symlinks pointing to correct locations
- ✅ All dependencies installed
- ✅ Tool versions meet requirements
- ✅ Oh My Zsh, Powerlevel10k, TPM installed

---

## Updating

Pull latest changes from repository:

```bash
bash scripts/update.sh
```

This will:
1. Stash uncommitted changes (with prompt)
2. Pull latest from Git
3. Reload tmux config (if running)
4. Remind you to restart Neovim and shell

---

## Uninstalling

Remove all symlinks and restore backups:

```bash
bash scripts/uninstall.sh
```

**Note:** This removes symlinks but keeps the repository intact at `~/Projects/dev-config`.

---

## Docker Setup

### Platform-Specific Installation

**macOS:**
- Docker Desktop installed via Homebrew cask
- Auto-starts after installation
- May require manual start: `open -a Docker`

**Linux:**
- Installed via package manager (apt, dnf, pacman, zypper)
- User added to docker group automatically
- Service started and enabled
- **Important:** Log out and back in for group changes to take effect

### Testing Docker Installation

After installation, verify Docker is working:

```bash
# Test Docker daemon
docker --version

# Test Docker functionality
docker run hello-world

# Check Docker Compose (if installed)
docker-compose --version
# or
docker compose version
```

### Docker Aliases

Docker aliases are available in `~/.zshrc.local` (commented out by default):

```bash
# Edit ~/.zshrc.local and uncomment aliases you want:
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dcb='docker-compose build'
alias dps='docker ps'
alias di='docker images'
# ... and more
```

### Common Issues

**Docker daemon not running:**
```bash
# macOS
open -a Docker

# Linux
sudo systemctl start docker
```

**Permission denied on Linux:**
```bash
# Add user to docker group (if not done automatically)
sudo usermod -aG docker $USER

# Log out and back in
```

**Docker Desktop not starting on macOS:**
- Check if Docker Desktop is installed: `brew list --cask docker`
- Reinstall if needed: `brew reinstall --cask docker`

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

---

## What Gets Symlinked?

| Source (Repository) | Target (Home Directory) |
|---------------------|-------------------------|
| `nvim/` | `~/.config/nvim` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS) or `~/.config/ghostty/config` (Linux) |
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/.zprofile` | `~/.zprofile` |
| `zsh/.p10k.zsh` | `~/.p10k.zsh` |

**Backups:** Original files are backed up with timestamp: `~/.config/nvim.backup_20251006_120000`
