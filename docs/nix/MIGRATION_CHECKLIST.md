# Nix Migration Checklist

**Migration:** Shell Scripts → Pure Nix Home Manager
**Start Date:** 2025-11-18
**Target Completion:** 4 weeks
**Branch:** `feat/nix-native-dotfiles-corrected`

---

## Phase 0: Backup & Preparation ✅ COMPLETE

### 0.1 Create Comprehensive Backup ✅
- [x] Create git backup branch (`backup/pre-nix-migration`)
- [x] Push backup branch to remote
- [x] Create tarball backup (`~/dev-config-backup-20251118-201007.tar.gz`)
- [x] Document current state (`docs/nix/PHASE0_CURRENT_STATE.md`)

### 0.2 Audit Existing Modules ✅
- [x] Audit `modules/home-manager/programs/neovim.nix`
- [x] Audit `modules/home-manager/programs/tmux.nix`
- [x] Audit `modules/home-manager/programs/zsh.nix`
- [x] Audit `modules/home-manager/programs/git.nix`
- [x] Audit `modules/home-manager/services/direnv.nix`
- [x] Document findings (`docs/nix/MODULE_AUDIT_FINDINGS.md`)

### 0.3 Evaluate Chezmoi ✅
- [x] Analyze `.chezmoi.toml.tmpl` usage
- [x] Analyze `.chezmoiexternal.toml` external resources
- [x] Decision: REMOVE Chezmoi (Phase 3)
- [x] Document decision (`docs/nix/CHEZMOI_DECISION.md`)

### 0.4 Create Migration Checklist ✅
- [x] Create this checklist
- [x] Define phases and deliverables
- [x] Set validation criteria

---

## Phase 1: Complete Home Manager Dotfile Symlinking (Week 1)

**Goal:** All dotfiles symlinked via Home Manager, external tools installed via Nix

### 1.1 Add Ghostty Home Manager Module
- [ ] Create `modules/home-manager/programs/ghostty.nix`
- [ ] Define options: `enable`, `configSource`
- [ ] Implement `xdg.configFile."ghostty/config"` symlink
- [ ] Add to `modules/home-manager/default.nix` imports
- [ ] Test: `home-manager switch --flake .`
- [ ] Verify: `ls -la ~/.config/ghostty/config` points to repo

**Validation:**
```bash
# Ghostty config should symlink correctly
ls -la ~/.config/ghostty/config
# Output: ~/.config/ghostty/config -> /Users/samuelho/Projects/dev-config/ghostty/config
```

### 1.2 Migrate Oh My Zsh to Nix
- [ ] Update `modules/home-manager/programs/zsh.nix`
- [ ] Add `programs.zsh.oh-my-zsh` configuration
- [ ] Install Powerlevel10k: `home.packages = [ pkgs.zsh-powerlevel10k ]`
- [ ] Symlink Powerlevel10k theme to Oh My Zsh location
- [ ] Install zsh-autosuggestions via Nix package
- [ ] Symlink zsh-autosuggestions to Oh My Zsh location
- [ ] Test: `home-manager switch --flake .`
- [ ] Verify: `zsh --version`, `echo $ZSH_THEME`, test autosuggestions

**Validation:**
```bash
# Oh My Zsh should be installed
ls -la ~/.oh-my-zsh

# Powerlevel10k theme should exist
ls -la ~/.oh-my-zsh/custom/themes/powerlevel10k

# zsh-autosuggestions should exist
ls -la ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# zsh should load theme
zsh -c 'echo $ZSH_THEME'
# Output: powerlevel10k/powerlevel10k
```

### 1.3 Tmux Plugin Strategy (DECISION REQUIRED)
- [ ] **Decision:** Nix plugins (Option A) or Keep TPM (Option B)?
- [ ] **If Option A:**
  - [ ] Update `modules/home-manager/programs/tmux.nix`
  - [ ] Add `programs.tmux.plugins` with all plugins
  - [ ] Update `tmux/tmux.conf` to remove TPM plugin declarations
  - [ ] Test tmux plugin loading
- [ ] **If Option B:**
  - [ ] Keep TPM installation via Nix or flake.nix
  - [ ] Document rationale in MIGRATION_NOTES.md
- [ ] Test: `tmux` launches with all plugins
- [ ] Verify: `tmux list-keys | grep navigator` shows vim-tmux-navigator

**Validation (Option A - Nix plugins):**
```bash
# Tmux plugins should load
tmux new-session -d 'echo test'
tmux list-keys | grep navigator
# Output: bind-key -T root C-h if-shell...

# Session resurrection should work
# (test after tmux session created)
```

**Validation (Option B - Keep TPM):**
```bash
# TPM should be installed
ls -la ~/.tmux/plugins/tpm

# Plugins should load via TPM
tmux new-session -d 'echo test'
tmux show-environment | grep TMUX_PLUGIN
```

### 1.4 Update flake.nix
- [ ] Remove Oh My Zsh git clone (lines 252-256)
- [ ] Remove Powerlevel10k git clone (lines 258-263)
- [ ] Remove zsh-autosuggestions git clone (lines 265-270)
- [ ] Remove TPM git clone (lines 272-277) **IF** using Nix plugins
- [ ] Remove TPM install script (lines 286-291) **IF** using Nix plugins
- [ ] Keep Neovim plugin installation (lazy.nvim handles)
- [ ] Keep `.zshrc.local` template creation (lines 233-249)
- [ ] Test: `nix flake check`
- [ ] Test: Fresh activation works

**Validation:**
```bash
# flake should validate
nix flake check

# activate app should run without errors
nix run .#activate
```

### 1.5 Test Phase 1 Completion
- [ ] Fresh install test: `home-manager switch --flake .`
- [ ] Verify all symlinks: nvim, tmux, zsh, ghostty
- [ ] Test Neovim: `nvim` launches, plugins load
- [ ] Test tmux: `tmux` launches, plugins work
- [ ] Test zsh: Oh My Zsh + Powerlevel10k + autosuggestions
- [ ] Test Ghostty: Config loads correctly
- [ ] Rollback test: Can restore from backup

**Validation:**
```bash
# All symlinks should exist
ls -la ~/.config/nvim        # -> repo
ls -la ~/.tmux.conf          # -> repo
ls -la ~/.zshrc              # -> repo
ls -la ~/.config/ghostty/config  # -> repo

# Functionality tests
nvim --version  # Should show Neovim version
tmux -V         # Should show tmux version
zsh --version   # Should show zsh version
```

---

## Phase 2: Hybrid Neovim Plugin Management (Week 2)

**Goal:** Use lazy-nix-helper.nvim for Nix + lazy.nvim integration

### 2.1 Install lazy-nix-helper.nvim
- [ ] Update `modules/home-manager/programs/neovim.nix`
- [ ] Add `plugins = [ pkgs.vimPlugins.lazy-nix-helper-nvim ]`
- [ ] Add LSP servers to `home.packages`: ts_ls, pyright, lua_ls
- [ ] Add formatters to `home.packages`: stylua, prettier, ruff
- [ ] Add build tools: gnumake, gcc, pkg-config, nodejs, imagemagick
- [ ] Test: `home-manager switch --flake .`
- [ ] Verify: `nvim` loads lazy-nix-helper

**Validation:**
```bash
# lazy-nix-helper should be installed
nvim --headless "+lua print(vim.inspect(require('lazy-nix-helper')))" +q 2>&1 | grep -v "^$"

# LSP servers should be in PATH
which typescript-language-server
which pyright
which lua-language-server
```

### 2.2 Configure lazy-nix-helper in Neovim
- [ ] Create or update `nvim/lua/config/options.lua` or `nvim/lua/plugins/lsp.lua`
- [ ] Add lazy-nix-helper setup:
  ```lua
  local ok, lazy_nix = pcall(require, 'lazy-nix-helper')
  if ok then
    lazy_nix.setup({ mason_nvim = { enable = false } })
  end
  ```
- [ ] Test: `nvim`, check for errors
- [ ] Verify: lazy-nix-helper loads without errors

**Validation:**
```bash
# lazy-nix-helper should load
nvim --headless "+lua print(require('lazy-nix-helper').mason_enabled())" +q 2>&1
# Output: false (if Nix detected)
```

### 2.3 Conditional Mason Configuration
- [ ] Update `nvim/lua/plugins/lsp.lua`
- [ ] Wrap Mason setup with conditional:
  ```lua
  local use_mason = true
  if pcall(require, 'lazy-nix-helper') then
    use_mason = require('lazy-nix-helper').mason_enabled()
  end
  if use_mason then
    -- Existing Mason setup
  else
    vim.notify('Using Nix for LSP servers', vim.log.levels.INFO)
  end
  ```
- [ ] Test: `nvim` on NixOS/Home Manager (should use Nix)
- [ ] Test: `nvim` on non-Nix system (should use Mason)

**Validation:**
```bash
# On Nix system: Mason should be disabled
nvim --headless "+checkhealth mason" +q 2>&1 | grep -i "mason"
# Should show Mason disabled or not used

# LSP should work with Nix servers
nvim test.ts
# :LspInfo should show ts_ls attached
```

### 2.4 Test Phase 2 Completion
- [ ] NixOS test: LSP works with Nix servers
- [ ] Non-NixOS test: LSP works with Mason servers
- [ ] TypeScript test: ts_ls, prettier work
- [ ] Python test: pyright, ruff work
- [ ] Lua test: lua_ls, stylua work
- [ ] Verify no Mason errors on Nix system

**Validation:**
```bash
# Full Neovim health check
nvim --headless "+checkhealth" +q 2>&1 > /tmp/nvim-health.txt
cat /tmp/nvim-health.txt | grep -A5 "ERROR"
# Should show no LSP-related errors
```

---

## Phase 3: Cleanup and Simplification (Week 3)

**Goal:** Remove Chezmoi, archive legacy scripts, simplify install.sh

### 3.1 Remove Chezmoi Files
- [ ] Verify Phase 1 complete (Oh My Zsh via Nix works)
- [ ] Verify Phase 1 complete (TPM via Nix or kept via Nix)
- [ ] Delete `.chezmoi.toml.tmpl`
- [ ] Delete `.chezmoiexternal.toml`
- [ ] Delete `.chezmoiscripts/` if exists
- [ ] Commit: "feat(nix): remove Chezmoi (replaced by Nix)"

**Validation:**
```bash
# Chezmoi files should be removed
test ! -f .chezmoi.toml.tmpl && echo "✓ Removed"
test ! -f .chezmoiexternal.toml && echo "✓ Removed"
```

### 3.2 Archive Legacy Scripts
- [ ] Create `scripts/legacy/` directory
- [ ] Move `scripts/lib/common.sh` to `scripts/legacy/` **IF** not used by flake.nix
- [ ] Move `scripts/lib/paths.sh` to `scripts/legacy/` **IF** not used by flake.nix
- [ ] Move `scripts/update.sh` to `scripts/legacy/`
- [ ] Move `scripts/uninstall.sh` to `scripts/legacy/`
- [ ] Move `scripts/validate.sh` to `scripts/legacy/`
- [ ] Keep `scripts/install.sh` (will rewrite)
- [ ] Keep `scripts/load-ai-credentials.sh` (still needed)
- [ ] Commit: "refactor(scripts): archive legacy shell scripts"

**Validation:**
```bash
# Legacy scripts should be archived
ls scripts/legacy/
# Output: common.sh paths.sh update.sh uninstall.sh validate.sh
```

### 3.3 Simplify install.sh
- [ ] Backup current `scripts/install.sh` to `scripts/legacy/install-old.sh`
- [ ] Rewrite `scripts/install.sh` (~30 lines):
  - Install Nix if not present
  - Enable flakes
  - Install Home Manager
  - Apply dev-config
- [ ] Test on fresh system (VM or container)
- [ ] Verify one-command installation works

**Validation:**
```bash
# New install.sh should be minimal
wc -l scripts/install.sh
# Output: ~30 lines

# Should work on fresh system
bash scripts/install.sh
# Should complete without errors
```

### 3.4 Update flake.nix
- [ ] Remove `activate` app (replaced by Home Manager)
- [ ] Keep `devShells.default`
- [ ] Keep `nixosModules`
- [ ] Keep `homeManagerModules`
- [ ] Keep `set-shell` app
- [ ] Keep `setup-opencode` app
- [ ] Test: `nix flake check`

**Validation:**
```bash
# flake should validate
nix flake check

# Apps should be available
nix run .#set-shell -- --help
nix run .#setup-opencode -- --help
```

---

## Phase 4: Documentation and Validation (Week 4)

**Goal:** Update docs, test all platforms, prepare for ai-dev-env integration

### 4.1 Update Primary Documentation
- [ ] Update `README.md`:
  - Replace shell script installation with Nix
  - Remove Chezmoi references
  - Add Nix flake.lock explanation
- [ ] Update `CLAUDE.md`:
  - Document hybrid architecture (lazy-nix-helper)
  - Remove shell script references
  - Add Nix module descriptions
- [ ] Update `docs/INSTALLATION.md`:
  - Pure Nix installation guide
  - Home Manager usage
  - Platform-specific notes
- [ ] Update `docs/CONFIGURATION.md`:
  - Home Manager customization
  - Nix module options
  - flake.lock management

**Validation:**
```bash
# Documentation should be accurate
grep -r "Chezmoi" README.md CLAUDE.md docs/
# Output: (none - all references removed)
```

### 4.2 Create Migration Guide
- [ ] Create `docs/nix/09-migration-guide.md`
- [ ] Document: Why the migration
- [ ] Document: Before/after architecture
- [ ] Document: Hybrid approach (lazy-nix-helper)
- [ ] Document: Rollback instructions
- [ ] Document: Troubleshooting guide
- [ ] Document: FAQs

**Validation:**
```bash
# Migration guide should exist and be comprehensive
test -f docs/nix/09-migration-guide.md && wc -l docs/nix/09-migration-guide.md
# Output: 200+ lines
```

### 4.3 Platform Testing Matrix

#### macOS Intel
- [ ] Fresh install: `bash scripts/install.sh`
- [ ] Verify: All dotfiles symlinked
- [ ] Test: Neovim + LSP (Nix servers)
- [ ] Test: Tmux + plugins
- [ ] Test: Zsh + Oh My Zsh + Powerlevel10k

#### macOS Apple Silicon
- [ ] Fresh install: `bash scripts/install.sh`
- [ ] Verify: All dotfiles symlinked
- [ ] Test: Neovim + LSP (Nix servers)
- [ ] Test: Tmux + plugins
- [ ] Test: Zsh + Oh My Zsh + Powerlevel10k

#### Linux (NixOS)
- [ ] Fresh NixOS install
- [ ] Import dev-config modules in `configuration.nix`
- [ ] Rebuild: `nixos-rebuild switch`
- [ ] Verify: System + user packages
- [ ] Test: All dotfiles
- [ ] Test: Neovim LSP (Nix servers)

#### Linux (Non-NixOS - Ubuntu)
- [ ] Install Nix: `bash scripts/install.sh`
- [ ] Standalone Home Manager
- [ ] Test: Neovim LSP (Mason fallback works)
- [ ] Verify: lazy-nix-helper detects non-Nix

#### Linux (Non-NixOS - Fedora)
- [ ] Install Nix: `bash scripts/install.sh`
- [ ] Standalone Home Manager
- [ ] Test: Neovim LSP (Mason fallback works)

#### DevPod
- [ ] Rebuild container image with Nix
- [ ] Test in Kubernetes deployment
- [ ] Verify: All tools available
- [ ] Test: Neovim + LSP

**Validation:**
```bash
# All platforms should pass smoke tests
# Documented in platform testing notes
```

### 4.4 Regression Testing

#### Claude Code Integration
- [ ] Test: Diagnostic copy (`<leader>ce`, `<leader>cd`)
- [ ] Test: Auto-reload on external changes
- [ ] Test: Multiple Claude instances in tmux panes (worktree workflow)

#### Git Workflows
- [ ] Test: lazygit (`<leader>gg`)
- [ ] Test: Octo.nvim (`<leader>gp`, `<leader>gi`)
- [ ] Test: git-conflict (`<leader>gco`, `<leader>gct`)
- [ ] Test: diffview (`<leader>gd`, `<leader>gh`)

#### Markdown Editing
- [ ] Test: Obsidian.nvim (wikilinks, daily notes)
- [ ] Test: render-markdown (in-buffer rendering)
- [ ] Test: Mermaid diagrams (if mmdc available)

#### LSP Functionality
- [ ] Test: TypeScript (ts_ls)
- [ ] Test: Python (pyright)
- [ ] Test: Lua (lua_ls)
- [ ] Test: Formatting on save

#### Tmux Session Management
- [ ] Test: Session resurrect (`Prefix + Ctrl+s`, `Prefix + Ctrl+r`)
- [ ] Test: Continuum (auto-save)
- [ ] Test: vim-tmux-navigator (`Ctrl+h/j/k/l`)

#### Zsh Features
- [ ] Test: Completion system
- [ ] Test: Autosuggestions
- [ ] Test: Powerlevel10k theme rendering

**Validation:**
```bash
# All core workflows should work
# Documented in regression testing notes
```

---

## Phase 5: ai-dev-env Integration (Future)

**Prerequisites:**
- [ ] dev-config migration complete and stable
- [ ] All Phase 4 tests passing
- [ ] Documentation finalized

### 5.1 Export Stable Module API
- [ ] Verify flake.nix exports are clean
- [ ] Document module options in README
- [ ] Version module interface

### 5.2 ai-dev-env Integration
- [ ] Add dev-config as flake input in ai-dev-env
- [ ] Import modules in ai-dev-env configuration
- [ ] Remove duplicated Nix code from ai-dev-env

### 5.3 Testing
- [ ] Test NixOS builds in ai-dev-env
- [ ] Test DevPod containers
- [ ] Test Kubernetes deployments

---

## Final Sign-Off

### Migration Complete Criteria

- [ ] **Phase 0:** ✅ Backup created, modules audited, Chezmoi decision made
- [ ] **Phase 1:** All dotfiles symlinked via Home Manager
- [ ] **Phase 2:** Hybrid Neovim (lazy-nix-helper) working
- [ ] **Phase 3:** Chezmoi removed, legacy scripts archived, install.sh simplified
- [ ] **Phase 4:** Documentation updated, all platforms tested
- [ ] **flake.lock:** Committed with all version changes
- [ ] **Rollback:** Tested and documented
- [ ] **No regressions:** All core workflows still work

### Sign-Off Date

**Date:** _____________
**Migration Duration:** _____ weeks
**Issues Encountered:** _____
**Final flake.lock commit:** _____

---

## Rollback Plan

If critical issues arise at any phase:

```bash
# Option 1: Restore from git backup
git checkout main
git reset --hard origin/backup/pre-nix-migration
home-manager switch --flake .

# Option 2: Restore from tarball
cd ~/Projects
rm -rf dev-config
tar -xzf ~/dev-config-backup-20251118-201007.tar.gz
cd dev-config
home-manager switch --flake .
```

---

*Created: 2025-11-18*
*Last Updated: 2025-11-18*
