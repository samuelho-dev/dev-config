# Phase 1 Complete: Home Manager Dotfile Symlinking

**Completion Date:** 2025-11-18
**Branch:** `feat/nix-native-dotfiles-corrected`
**Status:** ✅ COMPLETE (Awaiting Deployment Testing)

---

## Summary

Phase 1 successfully migrated all dotfile management and external dependencies to Nix Home Manager. All imperative installations (git clones) have been replaced with declarative Nix package management.

---

## Completed Tasks

### ✅ Phase 1.1: Ghostty Home Manager Module
**Commit:** `6c7e95e`

**Created:**
- `modules/home-manager/programs/ghostty.nix` (40 lines)

**Implementation:**
- Symlinks `~/.config/ghostty/config` → `repo/ghostty/config`
- Cross-platform compatible (xdg.configFile)
- Optional package support (Ghostty may not be in nixpkgs yet)
- Follows existing module pattern

**Options Added:**
- `dev-config.ghostty.enable` (default: true)
- `dev-config.ghostty.package` (optional)
- `dev-config.ghostty.configSource` (default: repo/ghostty/config)

---

### ✅ Phase 1.2: Oh My Zsh Nix Integration
**Commit:** `ee4c564`

**Modified:**
- `modules/home-manager/programs/zsh.nix` (+22 lines)

**Implementation:**
- Added `programs.zsh.oh-my-zsh.enable = true`
- Theme: `powerlevel10k/powerlevel10k`
- Plugins: `git` (autosuggestions via `programs.zsh.autosuggestion`)
- Installed `pkgs.zsh-powerlevel10k` via Nix
- Symlinked theme to `~/.oh-my-zsh/custom/themes/powerlevel10k`

**Replaces:**
- Chezmoi `.chezmoiexternal.toml` git clones for:
  - Oh My Zsh
  - Powerlevel10k
  - zsh-autosuggestions

**Benefits:**
- Declarative Oh My Zsh installation
- Version-locked via `flake.lock`
- No imperative git clones
- Uses Home Manager's built-in Oh My Zsh support

---

### ✅ Phase 1.3: Tmux Plugins Nix Migration
**Commit:** `ca14a1c`

**Modified:**
- `modules/home-manager/programs/tmux.nix` (+13 lines)

**Implementation:**
- Added `programs.tmux.plugins` with 9 plugins:
  1. **sensible** - Sensible tmux defaults
  2. **resurrect** - Save/restore sessions
  3. **continuum** - Auto-save sessions
  4. **battery** - Battery status
  5. **cpu** - CPU/RAM status
  6. **catppuccin** - Theme
  7. **vim-tmux-navigator** - Vim/tmux navigation
  8. **yank** - Clipboard integration
  9. **tmux-fzf** - Fuzzy finder

**Replaces:**
- TPM (Tmux Plugin Manager) imperative installation
- Chezmoi `.chezmoiexternal.toml` git clone for TPM

**Benefits:**
- Declarative plugin management
- Version-locked via `flake.lock`
- No TPM installation needed
- Plugins loaded automatically by Nix

**Breaking Change:**
- TPM plugin declarations in `tmux.conf` are now ignored
- Nix manages plugin loading

---

### ✅ Phase 1.4: Remove Imperative Installations
**Commit:** `79a4ac8`

**Modified:**
- `flake.nix` (-34 lines, +5 lines)

**Removed:**
- Oh My Zsh git clone (6 lines)
- Powerlevel10k git clone (6 lines)
- zsh-autosuggestions git clone (6 lines)
- TPM git clone (6 lines)
- TPM install script (6 lines)

**Kept:**
- `.zshrc.local` template creation (machine-specific config)
- Neovim plugin installation (lazy.nvim handles this)

**Added:**
- Documentation comments explaining Home Manager takeover
- References to specific Home Manager modules

**Impact:**
- Reduced activate script from ~100 lines to ~60 lines
- All external dependencies now declarative
- No more imperative git clones

---

## Files Modified Summary

### Created (1 file):
- `modules/home-manager/programs/ghostty.nix` (40 lines)

### Modified (3 files):
- `modules/home-manager/default.nix` (+3 lines - added ghostty import + docs)
- `modules/home-manager/programs/zsh.nix` (+22 lines - Oh My Zsh integration)
- `modules/home-manager/programs/tmux.nix` (+13 lines - plugin management)
- `flake.nix` (-29 lines net - removed imperative installations)

### Total Changes:
- **Lines Added:** 78
- **Lines Removed:** 34
- **Net Change:** +44 lines
- **Commits:** 4

---

## What's Now Managed by Nix

### ✅ Dotfiles (Symlinked via Home Manager)
- Neovim config (`~/.config/nvim/`)
- Tmux config (`~/.tmux.conf`, `~/.gitmux.conf`)
- Zsh config (`~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh`)
- Ghostty config (`~/.config/ghostty/config`)

### ✅ External Dependencies (Installed via Nix)
- Oh My Zsh (via `programs.zsh.oh-my-zsh`)
- Powerlevel10k (via `pkgs.zsh-powerlevel10k`)
- zsh-autosuggestions (via `programs.zsh.autosuggestion`)
- Tmux plugins (9 plugins via `programs.tmux.plugins`)

### ✅ Packages (Installed via Nix)
- git, zsh, tmux, docker, neovim
- fzf, ripgrep, fd, bat, lazygit, gitmux
- gnumake, pkg-config, nodejs, imagemagick
- opencode-ai, 1password, jq, gh
- direnv, nix-direnv, pre-commit

---

## What's Still Imperative (By Design)

### Neovim Plugins
**Managed by:** lazy.nvim (not Nix)
**Rationale:** Neovim ecosystem designed for lazy.nvim, Phase 2 will add lazy-nix-helper for hybrid approach
**Status:** Working as designed

### `.zshrc.local`
**Managed by:** Manual file creation
**Rationale:** Machine-specific, gitignored, user-controlled
**Status:** Working as designed

---

## Testing Checklist (Phase 1.5)

### Pre-Deployment Validation
- [x] Nix module syntax correct (no compilation errors)
- [x] File structure matches plan
- [x] Ghostty module created and imported
- [x] Zsh module updated with Oh My Zsh integration
- [x] Tmux module updated with plugin management
- [x] flake.nix imperative installations removed

### Post-Deployment Validation (To Be Tested)

#### Home Manager Deployment
- [ ] Run: `home-manager switch --flake ~/Projects/dev-config`
- [ ] No errors during deployment
- [ ] All symlinks created correctly

#### Symlink Verification
```bash
# All symlinks should point to repo
ls -la ~/.config/nvim        # → /Users/samuelho/Projects/dev-config/nvim
ls -la ~/.tmux.conf          # → /Users/samuelho/Projects/dev-config/tmux/tmux.conf
ls -la ~/.zshrc              # → /Users/samuelho/Projects/dev-config/zsh/.zshrc
ls -la ~/.config/ghostty/config  # → /Users/samuelho/Projects/dev-config/ghostty/config
```

#### Oh My Zsh Validation
- [ ] Oh My Zsh installed: `ls -la ~/.oh-my-zsh`
- [ ] Powerlevel10k theme exists: `ls -la ~/.oh-my-zsh/custom/themes/powerlevel10k`
- [ ] Zsh loads theme: `zsh -c 'echo $ZSH_THEME'` → `powerlevel10k/powerlevel10k`
- [ ] Autosuggestions work (type partial command, see suggestion)

#### Tmux Validation
- [ ] Tmux launches without errors: `tmux`
- [ ] Plugins loaded (check statusline shows battery, cpu)
- [ ] vim-tmux-navigator works: `Ctrl+h/j/k/l` navigates panes
- [ ] Session resurrect works: `Prefix + Ctrl+s` / `Prefix + Ctrl+r`

#### Neovim Validation
- [ ] Neovim launches: `nvim`
- [ ] Plugins load via lazy.nvim
- [ ] LSP works (TypeScript, Python, Lua)
- [ ] Formatters work (prettier, stylua, ruff)

#### Ghostty Validation
- [ ] Ghostty config loads
- [ ] Theme applied correctly
- [ ] Keybindings work

---

## Known Limitations

### Ghostty Package
**Issue:** Ghostty may not be available in nixpkgs yet
**Workaround:** Set `dev-config.ghostty.package = null`, install manually (e.g., Homebrew on macOS)
**Status:** Config symlink still works, package optional

### TPM Plugin Declarations
**Issue:** TPM plugin declarations in `tmux.conf` are now ignored
**Resolution:** Nix manages plugins, TPM declarations can be removed in future
**Status:** Harmless (declarations just ignored)

---

## Rollback Plan

If Phase 1 deployment fails:

```bash
# Option 1: Restore from git backup
git checkout main
git reset --hard origin/backup/pre-nix-migration
home-manager switch --flake .

# Option 2: Restore from tarball
cd ~/Projects
rm -rf dev-config
tar -xzf ~/dev-config-backup-20251118-201007.tar.gz
```

---

## Next Phase: Phase 2

**Goal:** Hybrid Neovim Plugin Management (lazy-nix-helper)

**Tasks:**
1. Install lazy-nix-helper.nvim via Nix
2. Add LSP servers to Home Manager packages
3. Configure lazy-nix-helper in Neovim
4. Conditional Mason configuration

**Benefits:**
- Nix-managed LSP servers (Nix systems)
- Mason fallback (non-Nix systems)
- Best of both worlds

---

*Phase 1 Complete: 2025-11-18*
*Ready for Phase 2 implementation*
