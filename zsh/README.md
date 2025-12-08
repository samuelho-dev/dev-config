# Zsh Configuration

Shell configuration with Oh My Zsh framework and Powerlevel10k theme.

## Overview

This Zsh configuration provides:
- **Oh My Zsh framework:** Plugin ecosystem and configuration management
- **Powerlevel10k theme:** Fast, customizable prompt
- **Auto-suggestions:** Fish-like command suggestions from history
- **Git integration:** Aliases and prompt indicators
- **Platform-agnostic:** Works on macOS and Linux
- **Machine-specific config:** `.zshrc.local` for local customization

## Files

| File | Purpose | Symlink |
|------|---------|---------|
| `.zshrc` | Main shell config | `~/.zshrc` |
| `.zprofile` | Login shell PATH setup | `~/.zprofile` |
| `.p10k.zsh` | Powerlevel10k theme | `~/.p10k.zsh` |

**Machine-specific:** `~/.zshrc.local` (not in repo, gitignored)

## Quick Start

### Installation

Shell framework and plugins are automatically installed during `scripts/install.sh`.

### Reload Configuration

```bash
# After editing .zshrc
source ~/.zshrc

# Or restart shell
exec zsh
```

## Features

### Oh My Zsh Framework

**Installed to:** `~/.oh-my-zsh/`

**Provides:**
- Plugin system
- Theme system
- Auto-update mechanism
- Helper functions

### Powerlevel10k Theme

**Fast, customizable prompt** with git status, time, directory, and more.

**Reconfigure:**
```bash
p10k configure
```

Interactive wizard guides you through:
- Prompt style (lean, classic, rainbow, pure)
- Character set (Unicode, ASCII)
- Show/hide elements
- Colors
- Transient prompt

Changes save to `.p10k.zsh`.

### Plugins

**git** (built-in)
- `g` = `git`
- `ga` = `git add`
- `gc` = `git commit`
- `gst` = `git status`
- `gp` = `git push`
- `gl` = `git pull`
- [100+ more aliases](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)

**zsh-autosuggestions** (custom)
- Suggests commands from history (gray text)
- Press `→` to accept
- Press `Ctrl+→` to accept one word

## Customization

### Machine-Specific Config

**Edit `~/.zshrc.local`** for machine-specific settings:

```bash
nvim ~/.zshrc.local
```

**Example:**
```zsh
# Custom PATH
export PATH="$HOME/custom-bin:$PATH"

# Aliases
alias work-server="ssh user@work.example.com"
alias vpn="sudo openvpn /path/to/config.ovpn"

# Environment variables
export DATABASE_URL="postgresql://localhost:5432/dev"
export API_KEY="your-secret-key"
```

**Benefits:**
- ✅ Keeps secrets out of Git
- ✅ Different config on different machines
- ✅ Survives updates to main `.zshrc`

### Adding Aliases

**Add to `.zshrc` (shared) or `.zshrc.local` (machine-specific):**

```zsh
# Navigation
alias ..='cd ..'
alias ...='cd ../..'

# ls shortcuts
alias ll='ls -lah'
alias la='ls -A'

# Project shortcuts
alias proj='cd ~/Projects'
alias dotfiles='cd ~/Projects/dev-config'

# Git shortcuts
alias glog='git log --oneline --graph --all'
```

Reload: `source ~/.zshrc`

### Adding Functions

**Add to `.zshrc` or `.zshrc.local`:**

```zsh
# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Git commit with timestamp
gctt() {
  git commit -m "$1 - $(date +%Y-%m-%d\ %H:%M:%S)"
}
```

**Usage:**
```bash
mkcd new-project
gctt "Initial commit"
```

### Adding to PATH

**Add to `.zshrc.local`:**

```zsh
# Always check if directory exists first
[ -d "$HOME/custom-bin" ] && export PATH="$HOME/custom-bin:$PATH"
```

Or for more complex setups:
```zsh
if [ -d "$HOME/go" ]; then
  export GOPATH="$HOME/go"
  export PATH="$GOPATH/bin:$PATH"
fi
```

### Adding Plugins

**Built-in plugins:**
1. View available: `ls ~/.oh-my-zsh/plugins/`
2. Edit `.zshrc` line 80:
   ```zsh
   plugins=(git zsh-autosuggestions docker npm)
   ```
3. Reload: `source ~/.zshrc`

**Custom plugins:**
1. Clone to custom directory:
   ```bash
   git clone https://github.com/author/plugin \
     ~/.oh-my-zsh/custom/plugins/plugin
   ```
2. Add to `.zshrc`:
   ```zsh
   plugins=(git zsh-autosuggestions plugin)
   ```
3. Reload: `source ~/.zshrc`

## PATH Configuration

### Execution Order

1. **`.zprofile`** (login shell)
   - Python paths (if installed)
   - Homebrew setup
2. **`.zshrc`** (interactive shell)
   - Oh My Zsh framework
   - Bun, pnpm (if installed)
   - `.local/bin` (if exists)
3. **`.zshrc.local`** (machine-specific)
   - Custom PATH additions
   - Environment variables

Later additions take precedence (prepended to PATH).

### Debugging PATH

```bash
# View entire PATH
echo $PATH

# View as list
echo $PATH | tr ':' '\n'

# Find where command is
which command-name

# Find all instances
whence -a command-name
```

## Troubleshooting

### Prompt not showing correctly

```bash
# Reconfigure Powerlevel10k
p10k configure

# Or check theme installed
ls ~/.oh-my-zsh/custom/themes/powerlevel10k
```

### Suggestions not appearing

```bash
# Check plugin installed
ls ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Check enabled in .zshrc
grep "plugins=" ~/.zshrc
# Should show: plugins=(git zsh-autosuggestions)
```

### PATH not updated after editing .zprofile

```bash
# .zprofile only loads on login shell
# Restart terminal completely (not just source)
exit
# Open new terminal
```

### Oh My Zsh not loading

```bash
# Check installed
ls ~/.oh-my-zsh

# Reinstall if missing
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### .zshrc.local not loading

```bash
# Check file exists
ls ~/.zshrc.local

# Check sourcing line in .zshrc
grep "zshrc.local" ~/.zshrc
# Should show: [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Check syntax errors
zsh -n ~/.zshrc.local
```

## Best Practices

1. **Use `.zshrc.local`** for machine-specific config
2. **Always check existence** before adding to PATH
3. **Test changes** with `source ~/.zshrc`
4. **Document aliases** with comments
5. **Commit `.zshrc` changes** to Git (but never `.zshrc.local`)
6. **Restart terminal** after editing `.zprofile`

## Common Use Cases

### Different Configs on Work vs Personal Machine

**On work machine (`~/.zshrc.local`):**
```zsh
export PATH="/work/tools/bin:$PATH"
alias vpn="sudo openvpn /work/vpn.ovpn"
alias ssh-prod="ssh user@prod.company.com"
```

**On personal machine (`~/.zshrc.local`):**
```zsh
export PATH="$HOME/personal-projects/bin:$PATH"
alias blog="cd ~/blog && nvim"
```

Both machines share the same `.zshrc` from Git!

### Language-Specific Setup

**Node.js developer (`~/.zshrc.local`):**
```zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

alias ni="npm add"
alias ns="npm start"
alias nt="npm test"
```

**Python developer (`~/.zshrc.local`):**
```zsh
# Conda initialization
[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ] && \
  source "$HOME/miniconda3/etc/profile.d/conda.sh"

alias py="python"
alias pir="pip install -r requirements.txt"
alias activate="source venv/bin/activate"
```

**Go developer (`~/.zshrc.local`):**
```zsh
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

alias gor="go run ."
alias got="go test ./..."
alias gob="go build"
```

## Resources

- Oh My Zsh: https://github.com/ohmyzsh/ohmyzsh
- Powerlevel10k: https://github.com/romkatv/powerlevel10k
- zsh-autosuggestions: https://github.com/zsh-users/zsh-autosuggestions
- Oh My Zsh plugins directory: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
- Zsh manual: `man zsh`
