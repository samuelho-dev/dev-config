# Troubleshooting Guide

Common issues and solutions for dev-config.

## Installation Issues

### "Permission denied" when running install.sh
**Problem:** Script doesn't have execute permissions.

**Solution:**
```bash
chmod +x scripts/install.sh
bash scripts/install.sh
```

### "Running as root/sudo" warning
**Problem:** Script detects you're running with sudo.

**Solution:** Run as normal user:
```bash
# Don't do this:
sudo bash scripts/install.sh

# Do this instead:
bash scripts/install.sh
```

The script will request sudo only when needed (e.g., package installation).

### Homebrew installation fails (macOS)
**Problem:** Network issues or Xcode Command Line Tools missing.

**Solution:**
```bash
# Install Xcode Command Line Tools first
xcode-select --install

# Then retry install.sh
bash scripts/install.sh
```

### Package installation fails (Linux)
**Problem:** Package manager can't find packages.

**Solution:**
```bash
# Update package lists
sudo apt update  # Debian/Ubuntu
sudo dnf check-update  # Fedora
sudo pacman -Sy  # Arch

# Retry installation
bash scripts/install.sh
```

---

## Symlink Issues

### Symlink not pointing to correct location
**Problem:** `ls -la ~/.zshrc` shows wrong path.

**Solution:**
```bash
# Remove incorrect symlink
rm ~/.zshrc

# Recreate symlinks
cd ~/Projects/dev-config
bash scripts/install.sh
```

### "File exists and is not a symlink"
**Problem:** Original config files weren't backed up.

**Solution:**
```bash
# Manually backup and remove
mv ~/.zshrc ~/.zshrc.manual_backup
mv ~/.config/nvim ~/.config/nvim.manual_backup

# Reinstall
bash scripts/install.sh
```

### Symlinks break after moving repository
**Problem:** Moved `~/Projects/dev-config` to different location.

**Solution:**
```bash
# Uninstall old symlinks
bash scripts/uninstall.sh

# Move repository
mv ~/Projects/dev-config ~/new-location/dev-config
cd ~/new-location/dev-config

# Reinstall (auto-detects new location)
bash scripts/install.sh
```

---

## Neovim Issues

### Plugins not loading
**Problem:** Fresh install, plugins missing.

**Solution:**
```bash
# Reinstall plugins
nvim --headless "+Lazy! sync" +qa

# Or manually in Neovim
nvim
:Lazy sync
```

### "Neovim version too old" warning
**Problem:** Neovim < 0.9.0.

**Solution (macOS):**
```bash
brew upgrade neovim
```

**Solution (Linux):**
```bash
# Add Neovim PPA (Ubuntu)
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim

# Or download AppImage
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod +x nvim.appimage
sudo mv nvim.appimage /usr/local/bin/nvim
```

### LSP server not working
**Problem:** Language server not installed.

**Solution:**
```vim
" In Neovim
:Mason

" Find your server (e.g., ts_ls, pyright)
" Press 'i' to install
```

### Diagnostic copy not working
**Problem:** No diagnostics or keybinding doesn't work.

**Solution:**
1. Ensure you're in a file with LSP errors: `:LspInfo`
2. Check for Lua errors: `:messages`
3. Verify file exists: `ls ~/Projects/dev-config/nvim/lua/custom/plugins/diagnostics-copy.lua`
4. Restart Neovim

---

## Tmux Issues

### Plugins not installing
**Problem:** TPM not installed or script failed.

**Solution:**
```bash
# Ensure TPM is installed
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# In tmux, press:
# Prefix + I (capital i)

# Or run manually:
bash ~/.tmux/plugins/tpm/scripts/install_plugins.sh
```

### Vim-tmux-navigator not working
**Problem:** Can't navigate between Neovim splits and tmux panes.

**Solution:**
1. Ensure plugin installed: `ls ~/.tmux/plugins/vim-tmux-navigator`
2. Reload tmux config: `Prefix + r`
3. Restart tmux: `tmux kill-server && tmux`
4. In Neovim, ensure you have the matching plugin (already in config)

### "tmux command not found"
**Problem:** tmux not installed.

**Solution:**
```bash
# macOS
brew install tmux

# Linux
sudo apt install tmux  # Debian/Ubuntu
sudo dnf install tmux  # Fedora
```

### Catppuccin theme not applying
**Problem:** Theme plugin not installed.

**Solution:**
```bash
# In tmux
Prefix + I  # Install plugins
Prefix + r  # Reload config

# Or manually
bash ~/.tmux/plugins/tpm/scripts/install_plugins.sh
tmux source-file ~/.tmux.conf
```

---

## Zsh Issues

### "command not found: zsh"
**Problem:** Zsh not installed.

**Solution:**
```bash
# macOS (already pre-installed)
# Just set as default shell:
chsh -s $(which zsh)

# Linux
sudo apt install zsh  # Debian/Ubuntu
chsh -s $(which zsh)
```

### Oh My Zsh not found
**Problem:** Installation failed or `.oh-my-zsh` directory missing.

**Solution:**
```bash
# Reinstall Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Then reinstall dev-config
cd ~/Projects/dev-config
bash scripts/install.sh
```

### Powerlevel10k instant prompt warning
**Problem:** Configuration before instant prompt block.

**Solution:** Edit `~/.zshrc` - ensure the instant prompt block (lines 1-6) stays at the top.

### zsh-autosuggestions not working
**Problem:** Plugin not installed or not enabled.

**Solution:**
```bash
# Check if installed
ls ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# If missing, reinstall
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Ensure it's in .zshrc plugins list (line 80)
plugins=(git zsh-autosuggestions)

# Reload
source ~/.zshrc
```

### PATH not updated after editing .zprofile
**Problem:** Login shell config not reloaded.

**Solution:**
```bash
# Reload .zprofile
source ~/.zprofile

# Or restart terminal completely
exit
# Open new terminal
```

---

## Git Issues

### lazygit not found
**Problem:** lazygit not installed.

**Solution:**
```bash
# macOS
brew install lazygit

# Linux - see https://github.com/jesseduffield/lazygit#installation
```

### GitHub CLI (gh) not authenticated
**Problem:** Octo.nvim can't access PRs/issues.

**Solution:**
```bash
# Install gh
brew install gh  # macOS
sudo apt install gh  # Linux

# Authenticate
gh auth login
# Follow prompts (browser or token)

# Verify
gh auth status
```

### Octo.nvim not working
**Problem:** Can't open PRs in Neovim.

**Solution:**
1. Ensure gh is installed: `which gh`
2. Ensure authenticated: `gh auth status`
3. In Neovim: `<leader>gp` then select repo
4. Check for errors: `:messages`

---

## General Issues

### "Repository structure verification failed"
**Problem:** Missing files in repository.

**Solution:**
```bash
# Check repository integrity
cd ~/Projects/dev-config
git status

# Re-clone if corrupted
cd ~
rm -rf ~/Projects/dev-config
git clone https://github.com/yourusername/dev-config ~/Projects/dev-config
cd ~/Projects/dev-config
bash scripts/install.sh
```

### Changes not syncing across machines
**Problem:** Forgot to commit or push changes.

**Solution:**
```bash
# On machine with changes
cd ~/Projects/dev-config
git status  # See what changed
git add .
git commit -m "Update configs"
git push origin main

# On other machines
cd ~/Projects/dev-config
bash scripts/update.sh
```

### Command not found after installation
**Problem:** PATH not updated or shell not reloaded.

**Solution:**
```bash
# Reload shell
exec zsh

# Or restart terminal completely
```

---

## Validation

Run the validation script to diagnose issues:

```bash
cd ~/Projects/dev-config
bash scripts/validate.sh
```

This checks:
- ✅ Repository structure
- ✅ Symlinks
- ✅ Dependencies
- ✅ Tool versions
- ✅ Oh My Zsh, TPM installation

---

## Still Having Issues?

1. **Check logs:**
   - Neovim: `:messages` or `~/.local/share/nvim/log`
   - tmux: `tmux show-messages`

2. **Fresh install:**
   ```bash
   bash scripts/uninstall.sh
   bash scripts/install.sh
   ```

3. **Open an issue:**
   - Repository: https://github.com/yourusername/dev-config/issues
   - Include: OS, tool versions, error messages

4. **Reset to defaults:**
   ```bash
   cd ~/Projects/dev-config
   git reset --hard origin/main
   bash scripts/install.sh
   ```
