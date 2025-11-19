# Phase 0.2: Home Manager Module Audit Findings

**Date:** 2025-11-18

## Executive Summary

All existing Home Manager modules use **symlink strategy** (not content management). They symlink files from the dev-config repository to home directory locations. External dependencies (Oh My Zsh, Powerlevel10k, TPM) are currently managed by Chezmoi.

---

## Module Analysis

### 1. neovim.nix (59 lines)

**Current Behavior:**
- **Symlinks:** `~/.config/nvim/` → `${inputs.dev-config}/nvim` (line 54-57)
- **Strategy:** `xdg.configFile."nvim"` with `recursive = true`
- **Package:** Installs Neovim via Home Manager `programs.neovim`
- **Aliases:** Sets `vim` and `vi` aliases (lines 49-50)
- **Default Editor:** Sets `EDITOR` environment variable (line 48)

**Options Available:**
- `configSource` - Path to nvim config dir (default: `${inputs.dev-config}/nvim`)
- `defaultEditor` - Set as default editor (default: true)
- `vimAlias` / `viAlias` - Create aliases (default: true)
- **Note:** `configSource = null` explicitly supported for Chezmoi compatibility (line 20)

**Plugins:** NOT managed by Nix - expects lazy.nvim to handle plugins

**Assessment:**
- ✅ Works as designed (symlinks only)
- ✅ Clean implementation
- ⚠️ No external dependencies installed (Oh My Zsh, TPM, etc.)
- ✅ Ready for Phase 2 enhancement (lazy-nix-helper integration)

---

### 2. tmux.nix (78 lines)

**Current Behavior:**
- **Symlinks:**
  - `~/.tmux.conf` → `${inputs.dev-config}/tmux/tmux.conf` (line 69-71)
  - `~/.gitmux.conf` → `${inputs.dev-config}/tmux/.gitmux.conf` (line 74-76)
- **Strategy:** `home.file` symlinks
- **Package:** Installs tmux via Home Manager `programs.tmux` (line 59-66)
- **Declarative Options:** Exposes `prefix`, `baseIndex`, `mouse`, `historyLimit` (lines 33-55)

**Options Available:**
- `configSource` - Path to tmux.conf (default: `${inputs.dev-config}/tmux/tmux.conf`)
- `gitmuxConfigSource` - Path to gitmux.conf (default: `${inputs.dev-config}/tmux/.gitmux.conf`)
- `prefix`, `baseIndex`, `mouse`, `historyLimit` - Declarative tmux settings
- **Note:** `configSource = null` supported for Chezmoi compatibility (line 20)

**Plugins:** NOT managed by Nix - expects TPM to handle plugins

**Assessment:**
- ✅ Works as designed (symlinks only)
- ✅ Declarative options mirror tmux.conf settings
- ⚠️ TPM not installed by Nix (currently via Chezmoi)
- ✅ Ready for Phase 1 enhancement (Nix tmux plugins or keep TPM)

---

### 3. zsh.nix (81 lines)

**Current Behavior:**
- **Symlinks:**
  - `~/.zshrc` → `${inputs.dev-config}/zsh/.zshrc` (line 69-71)
  - `~/.zprofile` → `${inputs.dev-config}/zsh/.zprofile` (line 73-75)
  - `~/.p10k.zsh` → `${inputs.dev-config}/zsh/.p10k.zsh` (line 77-79)
- **Strategy:** `home.file` symlinks
- **Package:** Installs zsh via Home Manager `programs.zsh` (line 60-66)
- **Declarative Options:** `enableCompletion`, `autosuggestion.enable`, `syntaxHighlighting.enable` (lines 63-65)

**Options Available:**
- `zshrcSource` - Path to .zshrc (default: `${inputs.dev-config}/zsh/.zshrc`)
- `zprofileSource` - Path to .zprofile (default: `${inputs.dev-config}/zsh/.zprofile`)
- `p10kSource` - Path to .p10k.zsh (default: `${inputs.dev-config}/zsh/.p10k.zsh`)
- `enableCompletion`, `enableAutosuggestions`, `enableSyntaxHighlighting`
- **Note:** All sources support `null` for Chezmoi compatibility (lines 17, 27, 34)

**Oh My Zsh:** NOT managed by Nix - expects Oh My Zsh to be installed externally

**Assessment:**
- ✅ Works as designed (symlinks only)
- ✅ Declarative zsh options enabled
- ⚠️ Oh My Zsh, Powerlevel10k, zsh-autosuggestions NOT installed by Nix (currently via Chezmoi)
- ❌ **CRITICAL:** No `programs.zsh.oh-my-zsh` configuration present
- ✅ Ready for Phase 1 enhancement (add Oh My Zsh via Nix)

---

### 4. git.nix (69 lines) - Not requiring changes

**Current Behavior:**
- **Declarative Git Config:** Generates `~/.gitconfig` via Home Manager
- **NOT a symlink:** Uses `programs.git` to manage git configuration declaratively

**Options Available:**
- `userName`, `userEmail`, `defaultBranch`, `editor`, `extraConfig`

**Assessment:**
- ✅ Fully declarative (no symlinks needed)
- ✅ No changes required for Nix migration

---

### 5. direnv.nix (45 lines) - Not requiring changes

**Current Behavior:**
- **Enables direnv:** Via `services.direnv.enable`
- **Nix Integration:** `nix-direnv` integration enabled

**Assessment:**
- ✅ Fully declarative
- ✅ No changes required for Nix migration

---

## Key Findings

### ✅ Strengths
1. **Consistent Strategy:** All modules use symlink approach (not content management)
2. **Clean Code:** Well-structured with clear options and defaults
3. **Chezmoi Compatible:** Explicit `configSource = null` support in all modules
4. **Declarative Where Possible:** git.nix and direnv.nix are fully declarative

### ⚠️ Gaps Identified

#### Missing: Ghostty Module
- **Status:** No Home Manager module exists for Ghostty
- **Current:** Managed by shell scripts only
- **Required:** Create `modules/home-manager/programs/ghostty.nix`
- **Priority:** HIGH (Phase 1.1)

#### Missing: External Dependency Installation
1. **Oh My Zsh** - Required by .zshrc, currently via Chezmoi
2. **Powerlevel10k** - Required by Oh My Zsh, currently via Chezmoi
3. **zsh-autosuggestions** - Required by Oh My Zsh, currently via Chezmoi
4. **TPM (Tmux Plugin Manager)** - Required by tmux.conf, currently via Chezmoi

**All four dependencies** are managed by `.chezmoiexternal.toml` (lines 5-31)

#### Missing: Oh My Zsh Home Manager Configuration
- **Current:** `zsh.nix` only symlinks .zshrc (does not configure `programs.zsh.oh-my-zsh`)
- **Required:** Add Oh My Zsh integration to `zsh.nix`
- **Priority:** HIGH (Phase 1.2)

---

## Chezmoi Role Analysis

### What Chezmoi Currently Manages

**From `.chezmoiexternal.toml`:**
1. `.oh-my-zsh/` - Oh My Zsh framework (git clone, weekly refresh)
2. `.oh-my-zsh/custom/themes/powerlevel10k/` - Powerlevel10k theme (git clone)
3. `.oh-my-zsh/custom/plugins/zsh-autosuggestions/` - zsh-autosuggestions plugin (git clone)
4. `.tmux/plugins/tpm/` - Tmux Plugin Manager (git clone)

**From `.chezmoi.toml.tmpl`:**
- Template variables: `isDevPod`, `hostname`, `username`
- **Minimal templating:** Only 7 lines, mostly metadata

### Chezmoi Functionality Assessment

**Current Use Case:**
- **Primary:** Git repository management (external resources)
- **Secondary:** Minimal templating (environment detection)

**Can Nix Replace This?**
- ✅ **Yes** - All four git repos can be installed as Nix packages
- ✅ **Yes** - Template variables not critical (hostname/username available via Nix)
- ✅ **Yes** - DevPod detection not needed (Nix flake handles environment)

**Conclusion:** Chezmoi can be safely removed after Nix migration

---

## Recommendations

### Phase 1 Implementation Order

1. **Add Ghostty Module** (Phase 1.1)
   - Create `modules/home-manager/programs/ghostty.nix`
   - Symlink `~/.config/ghostty/config` → `${inputs.dev-config}/ghostty/config`
   - Add to `modules/home-manager/default.nix`

2. **Migrate Oh My Zsh to Nix** (Phase 1.2)
   - Update `modules/home-manager/programs/zsh.nix`
   - Add `programs.zsh.oh-my-zsh` configuration
   - Install Powerlevel10k via `pkgs.zsh-powerlevel10k`
   - Install zsh-autosuggestions via `pkgs.zsh-autosuggestions`
   - Link theme/plugins to expected Oh My Zsh locations

3. **Tmux Plugin Strategy Decision** (Phase 1.3)
   - **Option A:** Migrate to Nix plugins (`programs.tmux.plugins`)
   - **Option B:** Keep TPM (simpler, less disruptive)
   - **Recommendation:** Option A for full Nix consistency

4. **Update flake.nix** (Phase 1.4)
   - Remove imperative git clones from activate app
   - Remove TPM installation if using Nix plugins

### Chezmoi Removal Plan (Phase 3)

**Safe to Remove After Phase 1:**
- `.chezmoi.toml.tmpl` - Template variables not needed
- `.chezmoiexternal.toml` - Git repos replaced by Nix packages

**Document in:** `docs/nix/CHEZMOI_DECISION.md`

---

## Next Steps

1. ✅ **Phase 0.2 Complete:** Module audit documented
2. **Phase 0.3:** Create Chezmoi decision document (NEXT)
3. **Phase 0.4:** Create migration checklist
4. **Phase 1:** Begin implementation

---

*Last Updated: 2025-11-18*
