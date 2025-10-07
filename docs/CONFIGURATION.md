# Configuration Guide

How to customize and extend your dev-config setup.

## Machine-Specific Configuration

### `.zshrc.local` - Your Personal Config

The installer creates `~/.zshrc.local` (gitignored) for machine-specific settings.

**Example use cases:**
```bash
# Custom PATH additions
export PATH="$HOME/custom-bin:$PATH"

# Machine-specific aliases
alias work-vpn="sudo openvpn /path/to/work.ovpn"
alias staging="ssh user@staging.example.com"

# Environment variables
export DATABASE_URL="postgresql://localhost:5432/mydb"
export API_KEY="your-secret-key-here"

# Conda/pyenv initialization
# >>> conda initialize >>>
# your conda setup here
# <<< conda initialize <<<
```

**Why use `.zshrc.local`?**
- ✅ Not tracked in Git (keeps secrets safe)
- ✅ Machine-specific without polluting main config
- ✅ Survives updates to main `.zshrc`

---

## Editing Configs

All configs are in the repository. Edit them directly:

```bash
# Neovim main config
nvim ~/Projects/dev-config/nvim/init.lua

# Tmux config
nvim ~/Projects/dev-config/tmux/tmux.conf

# Zsh main config
nvim ~/Projects/dev-config/zsh/.zshrc

# Zsh PATH setup
nvim ~/Projects/dev-config/zsh/.zprofile

# Ghostty terminal
nvim ~/Projects/dev-config/ghostty/config

# Machine-specific (not in repo)
nvim ~/.zshrc.local
```

**Changes take effect:**
- **Neovim:** Restart Neovim
- **tmux:** `Prefix + r` or `tmux source-file ~/.tmux.conf`
- **Zsh:** `source ~/.zshrc` or `exec zsh`
- **Ghostty:** Immediate (no restart needed)

---

## Committing Changes

After editing configs:

```bash
cd ~/Projects/dev-config

# Check what changed
git status
git diff

# Commit changes
git add .
git commit -m "Add custom keybinding for..."
git push origin main
```

**On other machines:**
```bash
bash scripts/update.sh
```

---

## Neovim Customization

### Adding Plugins

Edit `~/Projects/dev-config/nvim/init.lua`:

```lua
-- Around line 202, in the plugins list:
{
  'your-github-username/your-plugin',
  config = function()
    require('your-plugin').setup()
  end,
},
```

Restart Neovim - Lazy.nvim will auto-install.

### Custom Plugins Directory

Add files to `nvim/lua/custom/plugins/`:

```bash
# Create new plugin config
nvim ~/Projects/dev-config/nvim/lua/custom/plugins/my-plugin.lua
```

```lua
-- my-plugin.lua
return {
  'author/plugin-name',
  config = function()
    -- your configuration
  end,
}
```

Lazy.nvim automatically loads all files in `lua/custom/plugins/`.

### Adding LSP Servers

Edit `init.lua` around line 705:

```lua
local servers = {
  ts_ls = {},      -- TypeScript
  pyright = {},    -- Python
  lua_ls = {},     -- Lua
  rust_analyzer = {}, -- Add Rust
  gopls = {},      -- Add Go
}
```

Restart Neovim, then run `:Mason` to install the server.

---

## Tmux Customization

### Adding Plugins

Edit `tmux/tmux.conf`:

```bash
# Around line 173, add:
set -g @plugin 'your-plugin-name'
```

Then in tmux:
1. `Prefix + r` - Reload config
2. `Prefix + I` - Install new plugins

### Custom Keybindings

Add to `tmux/tmux.conf`:

```bash
# Custom popup window
bind-key C-f display-popup -E "nvim ~/notes.md"
```

Reload with `Prefix + r`.

---

## Zsh Customization

### Aliases

Add to `~/.zshrc.local` (machine-specific) or `zsh/.zshrc` (shared across machines):

```bash
# Git shortcuts
alias gs="git status"
alias gc="git commit"
alias gp="git push"

# Navigation
alias proj="cd ~/Projects"
alias dotfiles="cd ~/Projects/dev-config"
```

### Functions

Add to `~/.zshrc.local`:

```bash
# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Git commit with timestamp
gctt() {
  git commit -m "$1 - $(date +%Y-%m-%d)"
}
```

### PATH Additions

Add to `~/.zshrc.local`:

```bash
# Custom binaries
export PATH="$HOME/custom-scripts:$PATH"

# Language-specific (e.g., Go)
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
```

---

## Powerlevel10k Theme

Reconfigure the prompt theme:

```bash
p10k configure
```

This launches an interactive wizard to customize:
- Prompt style (lean, classic, rainbow)
- Character set (Unicode, ASCII)
- Colors
- Prompt elements (git, time, directory, etc.)

Changes are saved to `~/.p10k.zsh` (symlinked to repository).

---

## Obsidian Integration

By default, Obsidian.nvim uses **dynamic workspace detection** - it finds your vault automatically based on the markdown file location.

### Configure Specific Vaults

Edit `init.lua` around line 833:

```lua
workspaces = {
  {
    name = 'personal',
    path = '~/Documents/Obsidian/PersonalVault',
  },
  {
    name = 'work',
    path = '~/Documents/Obsidian/WorkVault',
  },
},
```

---

## Git Integration

### GitHub CLI Setup

For PR/issue management in Neovim (Octo.nvim):

```bash
# Install gh
brew install gh  # macOS
sudo apt install gh  # Linux

# Authenticate
gh auth login
```

Then in Neovim:
- `<leader>gp` - List Pull Requests
- `<leader>gi` - List Issues

---

## Version Locking

### Neovim Plugins

Plugin versions are locked in `nvim/lazy-lock.json` (committed to repo).

**Update plugins:**
```vim
:Lazy update
```

**Restore locked versions:**
```vim
:Lazy restore
```

**Keep versions consistent** across machines by committing `lazy-lock.json` changes.

---

## Platform Detection

Configs automatically detect OS:

**`.zprofile` example:**
```bash
# Homebrew setup (platform-agnostic)
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"  # macOS Apple Silicon
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"      # macOS Intel
elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"  # Linux
fi
```

No hardcoded paths - works across machines!

---

## Advanced: Shared Library for Scripts

Custom scripts can use the shared library:

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/paths.sh"

# Use library functions
log_info "Starting custom script..."
if command_exists nvim; then
  log_success "Neovim is installed"
fi
```

See `scripts/lib/common.sh` for available functions.
