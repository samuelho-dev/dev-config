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
2. Processes any templates (`.tmpl` files)
3. Copies files to your home directory (`~/`)

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

Run scripts before/after applying dotfiles:

```bash
# Run once (create as .chezmoiscripts/run_once_install-packages.sh)
#!/bin/bash
brew install fzf ripgrep

# Run on every apply (create as .chezmoiscripts/run_setup-vim.sh)
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
