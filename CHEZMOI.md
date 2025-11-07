# Chezmoi Dotfiles Management

This repository uses Chezmoi for reproducible dotfile management across:
- Local development machines
- Remote servers (SSH)
- Kubernetes DevPod workspaces
- Team member environments

## How It Works

Chezmoi uses a **three-state model**:
1. **Source**: Git repository (`~/Projects/dev-config/`)
2. **Target**: Desired state (`~/.local/share/chezmoi/`)
3. **Actual**: Your home directory (`~/`)

When you run `chezmoi init --apply`, it:
1. Clones your dotfiles repository to `~/.local/share/chezmoi/`
2. **Executes automation scripts** (`.chezmoiscripts/run_once_before_install.sh` calls `install.sh`)
3. **Clones external dependencies** (Oh My Zsh, Powerlevel10k, TPM via `.chezmoiexternal.toml`)
4. Processes any templates (`.tmpl` files)
5. Copies files to your home directory (`~/`)

**Zero-Touch Automation**: The setup is fully automated. The wrapper script in `.chezmoiscripts/` calls the existing `install.sh` script, which installs Homebrew, packages, frameworks, and configures everything. This means a single command (`chezmoi init --apply`) sets up your entire development environment.

## Zero-Touch Automation Architecture

This repository implements a **thin wrapper pattern** for zero-touch setup while maintaining low maintenance overhead.

### Architecture Components

**1. Wrapper Script** (`.chezmoiscripts/run_once_before_install.sh` - 15 lines)
- Executes once before dotfiles are applied
- Calls the existing `install.sh` script (420 lines, proven, tested)
- Provides idempotent automation (safe to run multiple times)

**2. External Dependencies** (`.chezmoiexternal.toml` - 30 lines)
- Declaratively manages git repositories
- Automatically clones Oh My Zsh, Powerlevel10k, plugins, and TPM
- Refreshes weekly (168h = 7 days)
- Uses shallow clones (`--depth 1`) for speed

**3. Existing Installation Logic** (`scripts/install.sh` - 420 lines)
- **Reused, not replaced** - maintains single source of truth
- Handles Homebrew installation
- Installs packages and frameworks
- Configures Neovim, plugins, and other tools
- Provides verification and error handling

### Why This Design?

**Problem**: Initial approach created 11 separate scripts (~800 lines of new code) which was high maintenance overhead.

**Solution**: Thin wrapper pattern reuses existing `install.sh`:
- **Only 2 new files** (wrapper + external config)
- **Only 45 lines of new code** (vs. 800 lines)
- **Maintains single source of truth** (install.sh)
- **Low maintenance overhead** (the reason install.sh exists as one file)

### Execution Flow

```bash
chezmoi init --apply https://github.com/samuelho-dev/dev-config

# What happens:
1. Chezmoi clones repository to ~/.local/share/chezmoi/
2. Runs .chezmoiscripts/run_once_before_install.sh
   └─> Calls scripts/install.sh (installs Homebrew, packages, frameworks)
3. Clones external repos via .chezmoiexternal.toml
   - ~/.oh-my-zsh/
   - ~/.oh-my-zsh/custom/themes/powerlevel10k/
   - ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/
   - ~/.tmux/plugins/tpm/
4. Applies dotfiles (.zshrc, .tmux.conf, .config/nvim/, .claude/)
5. Done! Full development environment ready.
```

### Benefits

✅ **Zero-Touch**: Single command installs everything automatically
✅ **Maintainable**: 45 lines of new code, reuses existing install.sh
✅ **Reproducible**: Same setup on local dev machines and DevPod containers
✅ **Idempotent**: Safe to run multiple times (Chezmoi tracks what's been done)
✅ **Proven**: Leverages existing 420-line install.sh that's already tested

## Machine Detection

`.chezmoi.toml.tmpl` automatically detects environment:
- **DevPod**: `isDevPod = true` (Kubernetes environment)
- **Local**: `isDevPod = false` (development machine)

### How Detection Works

The template checks for the `KUBERNETES_SERVICE_HOST` environment variable, which is automatically set by Kubernetes in all pods:

```toml
{{- $isDevPod := env "KUBERNETES_SERVICE_HOST" | not | not -}}

[data]
  isDevPod = {{ $isDevPod }}
  hostname = {{ .chezmoi.hostname | quote }}
  username = {{ .chezmoi.username | quote }}
```

### Use in Templates

You can create environment-specific configuration files by adding `.tmpl` extension and using conditionals:

**Example: `.zshrc.tmpl`**
```bash
# Common configuration for all environments
export EDITOR=nvim

{{- if .isDevPod }}
# DevPod-specific configuration
export PATH="/workspace/bin:$PATH"
export CLAUDE_CONFIG_PATH="/workspace/.claude"
{{- else }}
# Local machine configuration
export PATH="$HOME/.local/bin:$PATH"
export CLAUDE_CONFIG_PATH="$HOME/.claude"
{{- end }}
```

## Configuration Files Managed

- `.zshrc` - Shell configuration
- `.config/nvim/` - Neovim editor
- `.config/tmux/` - Terminal multiplexer
- `.config/ghostty/` - Terminal emulator
- `.claude/` - Claude Code AI assistant
  - `agents/` - Custom AI agents
  - `commands/` - Slash commands
  - `settings.json` - IDE preferences

## Installation

### Local Development

**Option 1: Using the helper script**
```bash
cd ~/Projects/dev-config
./scripts/install-chezmoi.sh
```

**Option 2: Install from GitHub**
```bash
chezmoi init --apply https://github.com/samuelho-dev/dev-config
```

**Option 3: Install from local directory**
```bash
chezmoi init --apply ~/Projects/dev-config
```

### Remote Server

Perfect for setting up a new remote server via SSH:

```bash
chezmoi init --apply https://github.com/samuelho-dev/dev-config
```

### Kubernetes DevPod

**Automatic** via init container (no manual steps).

The DevPod Helm chart includes a Chezmoi init container that:
1. Installs Chezmoi in an ephemeral Alpine container
2. Clones your dotfiles repository
3. Applies all dotfiles to `/home/vscode`
4. Completes before the main DevPod container starts

**Configuration** (in `ai-dev-env/values.yaml`):
```yaml
devpod:
  dotfiles:
    enabled: true
    repo: "https://github.com/samuelho-dev/dev-config"
    branch: "main"
```

## Updating Dotfiles

### Making Changes

1. **Edit files in your home directory**:
```bash
vim ~/.zshrc
```

2. **Add changes to Chezmoi**:
```bash
chezmoi add ~/.zshrc
```

3. **Review differences**:
```bash
chezmoi diff
```

4. **Commit and push**:
```bash
cd ~/Projects/dev-config
git add .
git commit -m "feat(zsh): update shell aliases"
git push
```

### Applying Updates on Other Machines

**Pull latest changes:**
```bash
cd ~/Projects/dev-config
git pull
chezmoi apply
```

**Or use Chezmoi's built-in update:**
```bash
chezmoi update
```

This automatically:
1. Pulls latest changes from Git
2. Applies updates to your home directory

## Common Commands

### Initialization
```bash
# Initialize from GitHub
chezmoi init --apply https://github.com/username/dev-config

# Initialize from local directory
chezmoi init --apply ~/Projects/dev-config
```

### Daily Usage
```bash
# Add a file to Chezmoi
chezmoi add ~/.zshrc

# Edit a file (opens in $EDITOR)
chezmoi edit ~/.zshrc

# See what would change
chezmoi diff

# Apply changes
chezmoi apply

# Apply changes verbosely
chezmoi apply -v

# Show status
chezmoi status
```

### Updates
```bash
# Pull and apply in one command
chezmoi update

# Or manually
cd ~/.local/share/chezmoi
git pull
chezmoi apply
```

### Verification
```bash
# Check what Chezmoi manages
chezmoi managed

# See source state
chezmoi source path

# Open source directory
cd $(chezmoi source-path)
```

## Troubleshooting

### Chezmoi not found

Install Chezmoi:
```bash
curl -sfL https://get.chezmoi.io | sh -s -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

Add to your `~/.zshrc` or `~/.bash_profile`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Files not applying

Check Chezmoi status:
```bash
chezmoi status
```

See what would change:
```bash
chezmoi diff
```

Force re-apply:
```bash
chezmoi apply --force
```

### Template errors

Validate template syntax:
```bash
chezmoi execute-template < .chezmoi.toml.tmpl
```

View processed template:
```bash
chezmoi cat ~/.zshrc
```

### Machine detection not working

Verify data variables:
```bash
chezmoi data
```

Check `isDevPod` value:
```bash
chezmoi data | grep isDevPod
```

In Kubernetes, verify environment variable:
```bash
echo $KUBERNETES_SERVICE_HOST
# Should output the Kubernetes API server address (e.g., 10.96.0.1)
```

### Conflicts with existing files

Chezmoi won't overwrite files by default. Options:

**Option 1: Backup and apply**
```bash
mkdir ~/dotfile-backups
mv ~/.zshrc ~/dotfile-backups/
chezmoi apply
```

**Option 2: Force overwrite**
```bash
chezmoi apply --force
```

**Option 3: Merge manually**
```bash
chezmoi diff
# Review differences, then decide
```

## Advanced Features

### Encrypted Secrets

Chezmoi supports encrypted files for sensitive data (API keys, tokens):

```bash
# Add encrypted file
chezmoi add --encrypt ~/.ssh/config

# Edit encrypted file
chezmoi edit ~/.ssh/config
```

**Note:** For Kubernetes DevPod, use Sealed Secrets instead for runtime credentials.

### Templates with Data

Access machine-specific data in templates:

```
{{ .chezmoi.hostname }}  - Machine hostname
{{ .chezmoi.username }}  - Current user
{{ .chezmoi.os }}        - Operating system (darwin, linux)
{{ .chezmoi.arch }}      - Architecture (amd64, arm64)
```

### Scripts

Chezmoi can run scripts at various stages of the dotfile application process. This repository uses:

**Implemented Script**: `.chezmoiscripts/run_once_before_install.sh`
- Runs **once** before dotfiles are applied (tracked by Chezmoi state)
- Calls `scripts/install.sh` to install Homebrew, packages, and frameworks
- **Idempotent**: Won't re-run unless explicitly reset with `chezmoi state delete-bucket --bucket=scriptState`

**Script Naming Conventions**:
```bash
# Run once before applying dotfiles
.chezmoiscripts/run_once_before_install.sh

# Run on every apply
.chezmoiscripts/run_setup-vim.sh

# Run once after applying dotfiles
.chezmoiscripts/run_once_after_configure.sh

# Run when script content changes
.chezmoiscripts/run_onchange_install-packages.sh
```

**Example: Run on every apply**:
```bash
# .chezmoiscripts/run_setup-vim.sh
#!/bin/bash
nvim --headless "+Lazy! sync" +qa
```

### Ignoring Files

Create `.chezmoiignore` to exclude files from being managed:

```
README.md
LICENSE
.git
```

## Best Practices

### Do's
- ✅ Use templates for environment-specific configuration
- ✅ Keep repository structure simple (no `dot_` prefix if not needed)
- ✅ Test changes locally before committing
- ✅ Document machine-specific requirements
- ✅ Use semantic commit messages

### Don'ts
- ❌ Don't commit sensitive secrets (use encryption or Sealed Secrets for Kubernetes)
- ❌ Don't mix configuration with runtime credentials
- ❌ Don't use Chezmoi for large binary files
- ❌ Don't forget to test in both local and DevPod environments

## Comparison with Traditional Symlinks

| Feature | Chezmoi | Symlinks |
|---------|---------|----------|
| **Setup** | Automated (`chezmoi init --apply`) | Manual (`install.sh`) |
| **Updates** | `chezmoi update` | `git pull` + reload |
| **Templates** | ✅ Yes (environment-specific) | ❌ No |
| **Machine Detection** | ✅ Built-in | ❌ Manual |
| **Kubernetes Integration** | ✅ Native (init container) | ⚠️ Requires custom scripts |
| **File Encryption** | ✅ Built-in | ❌ No |
| **Multi-machine** | ✅ Designed for it | ⚠️ Requires careful planning |
| **Learning Curve** | Moderate | Low |
| **Flexibility** | High (templates, scripts) | Low (static files) |

## References

- [Chezmoi Official Documentation](https://www.chezmoi.io/)
- [Chezmoi Quick Start](https://www.chezmoi.io/quick-start/)
- [Chezmoi Template Guide](https://www.chezmoi.io/user-guide/templating/)
- [Kubernetes DevPod Architecture](../ai-dev-env/deploy/helm/charts/applications/ai-dev-env/charts/devpod/CLAUDE.md)
- [Chezmoi GitHub Repository](https://github.com/twpayne/chezmoi)

---

**Last Updated**: 2025-11-07
**Chezmoi Version**: 2.x
**DevPod Integration**: ai-dev-env v1.0.0
