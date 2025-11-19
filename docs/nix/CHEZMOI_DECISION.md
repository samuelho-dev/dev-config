# Chezmoi Decision Document

**Date:** 2025-11-18
**Decision:** **REMOVE CHEZMOI** after Phase 1 implementation
**Rationale:** Nix Home Manager fully replaces Chezmoi functionality

---

## Executive Summary

After auditing Chezmoi usage in dev-config, we've determined that **Chezmoi can be safely removed** once Nix migration is complete. Chezmoi currently manages only external git repositories (Oh My Zsh, Powerlevel10k, zsh-autosuggestions, TPM), all of which can be replaced by Nix packages.

---

## Current Chezmoi Usage

### Files Present
1. `.chezmoi.toml.tmpl` (7 lines) - Minimal template configuration
2. `.chezmoiexternal.toml` (32 lines) - External git repository management

### What Chezmoi Manages

**From `.chezmoiexternal.toml`:**

| Resource | Type | URL | Purpose | Nix Replacement |
|----------|------|-----|---------|-----------------|
| `.oh-my-zsh` | git-repo | ohmyzsh/ohmyzsh | Zsh framework | `programs.zsh.oh-my-zsh` |
| `.oh-my-zsh/custom/themes/powerlevel10k` | git-repo | romkatv/powerlevel10k | Zsh theme | `pkgs.zsh-powerlevel10k` |
| `.oh-my-zsh/custom/plugins/zsh-autosuggestions` | git-repo | zsh-users/zsh-autosuggestions | Zsh plugin | `pkgs.zsh-autosuggestions` |
| `.tmux/plugins/tpm` | git-repo | tmux-plugins/tpm | Tmux plugin manager | `programs.tmux.plugins` or keep TPM |

**From `.chezmoi.toml.tmpl`:**

```toml
[data]
  isDevPod = {{ $isDevPod }}
  hostname = {{ .chezmoi.hostname }}
  username = {{ .chezmoi.username }}
```

**Template Variables:**
- `isDevPod` - Detects Kubernetes environment (KUBERNETES_SERVICE_HOST)
- `hostname` - System hostname
- `username` - Current user

**Template Usage:** Minimal - no template files found in repository that use these variables

---

## Can Nix Replace Chezmoi?

### ✅ External Repositories → Nix Packages

All four git repositories can be installed as Nix packages:

#### 1. Oh My Zsh
**Chezmoi:**
```toml
[".oh-my-zsh"]
    type = "git-repo"
    url = "https://github.com/ohmyzsh/ohmyzsh.git"
```

**Nix (Home Manager):**
```nix
programs.zsh.oh-my-zsh = {
  enable = true;
  theme = "powerlevel10k/powerlevel10k";
  plugins = [ "git" ];
};
```

**Status:** ✅ Direct replacement available

#### 2. Powerlevel10k Theme
**Chezmoi:**
```toml
[".oh-my-zsh/custom/themes/powerlevel10k"]
    type = "git-repo"
    url = "https://github.com/romkatv/powerlevel10k.git"
```

**Nix (Home Manager):**
```nix
home.packages = [ pkgs.zsh-powerlevel10k ];
home.file.".oh-my-zsh/custom/themes/powerlevel10k".source =
  "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
```

**Status:** ✅ Available in nixpkgs

#### 3. zsh-autosuggestions Plugin
**Chezmoi:**
```toml
[".oh-my-zsh/custom/plugins/zsh-autosuggestions"]
    type = "git-repo"
    url = "https://github.com/zsh-users/zsh-autosuggestions.git"
```

**Nix (Home Manager):**
```nix
home.file.".oh-my-zsh/custom/plugins/zsh-autosuggestions".source =
  "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
```

**Status:** ✅ Available in nixpkgs

#### 4. TPM (Tmux Plugin Manager)
**Chezmoi:**
```toml
[".tmux/plugins/tpm"]
    type = "git-repo"
    url = "https://github.com/tmux-plugins/tpm.git"
```

**Nix (Option A - Recommended):**
```nix
programs.tmux.plugins = with pkgs.tmuxPlugins; [
  vim-tmux-navigator
  resurrect
  continuum
  # ... other plugins
];
```

**Nix (Option B - Keep TPM):**
```nix
# Install TPM via Nix package or git clone
# Less disruptive to existing workflow
```

**Status:** ✅ Both options available

---

### ✅ Template Variables → Nix Alternatives

#### isDevPod Detection
**Chezmoi:**
```toml
{{- $isDevPod := env "KUBERNETES_SERVICE_HOST" | not | not -}}
```

**Nix Alternative:**
```nix
# Nix flake can detect environment at build time
let
  isDevPod = builtins.getEnv "KUBERNETES_SERVICE_HOST" != "";
in
# Use in conditional logic
```

**Usage:** **NOT FOUND** - No files in repository currently use `isDevPod` variable

**Status:** ✅ Not needed (unused variable)

#### hostname & username
**Chezmoi:**
```toml
hostname = {{ .chezmoi.hostname }}
username = {{ .chezmoi.username }}
```

**Nix Alternative:**
```nix
# Available in Nix/Home Manager
config.home.username
config.networking.hostName  # NixOS
builtins.getEnv "HOSTNAME"
```

**Usage:** **NOT FOUND** - No files in repository currently use these variables

**Status:** ✅ Not needed (unused variables)

---

## Decision Matrix

| Chezmoi Feature | Status | Nix Replacement | Migration Effort |
|----------------|--------|-----------------|------------------|
| Oh My Zsh git clone | Active | `programs.zsh.oh-my-zsh` | Medium (Phase 1.2) |
| Powerlevel10k git clone | Active | `pkgs.zsh-powerlevel10k` | Medium (Phase 1.2) |
| zsh-autosuggestions git clone | Active | `pkgs.zsh-autosuggestions` | Medium (Phase 1.2) |
| TPM git clone | Active | `programs.tmux.plugins` or keep | Medium (Phase 1.3) |
| Template variables | **UNUSED** | N/A | None (delete) |
| Machine-specific configs | **NONE** | N/A | None |

---

## Decision: REMOVE CHEZMOI

### Rationale

1. **No Unique Functionality:** All Chezmoi features can be replaced by Nix
2. **Minimal Usage:** Only manages 4 git repositories
3. **No Templating:** Template variables defined but never used
4. **Simpler Architecture:** One tool (Nix) instead of two (Nix + Chezmoi)
5. **Better Reproducibility:** Nix packages are version-locked, Chezmoi git clones are not

### Benefits of Removal

✅ **Single Source of Truth:** Nix is authoritative for all dependencies
✅ **Version Locking:** `flake.lock` ensures identical versions across machines
✅ **Declarative:** All dependencies defined in Nix modules
✅ **Less Complexity:** Fewer tools to maintain
✅ **Faster Installs:** Nix binary cache vs git clones

### Risks of Removal

⚠️ **Minimal Risk:** Chezmoi usage is limited to external repos
⚠️ **Migration Effort:** Medium (requires Nix module updates)
⚠️ **Rollback Available:** Backup branch preserved

---

## Migration Plan

### Phase 1: Replace Chezmoi Functionality with Nix

**Phase 1.2: Migrate Oh My Zsh to Nix**
- Update `modules/home-manager/programs/zsh.nix`
- Add `programs.zsh.oh-my-zsh` configuration
- Install Powerlevel10k and zsh-autosuggestions via Nix
- Test zsh functionality

**Phase 1.3: Tmux Plugin Strategy**
- Decide: Nix plugins vs keep TPM
- Update `modules/home-manager/programs/tmux.nix`
- Test tmux functionality

**Phase 1.4: Update flake.nix**
- Remove imperative git clones from activate app
- Keep only `.zshrc.local` template creation

### Phase 3: Remove Chezmoi Files

**After Phase 1 complete and tested:**
```bash
git rm .chezmoi.toml.tmpl
git rm .chezmoiexternal.toml
git rm -rf .chezmoiscripts/  # If exists
```

**Update documentation:**
- Remove Chezmoi references from `README.md`
- Remove Chezmoi section from `CLAUDE.md`
- Update `docs/INSTALLATION.md`

---

## Rollback Plan

If Nix migration fails or Chezmoi removal causes issues:

```bash
# Restore from backup branch
git checkout main
git reset --hard origin/backup/pre-nix-migration

# Or restore from tarball
cd ~/Projects
rm -rf dev-config
tar -xzf ~/dev-config-backup-20251118-201007.tar.gz
```

---

## Alternative Considered: Keep Chezmoi

### Why NOT Keep Chezmoi

❌ **Redundancy:** Nix Home Manager already symlinks dotfiles
❌ **Complexity:** Two tools doing similar jobs
❌ **No Machine-Specific Config:** Chezmoi's strength (templating) is unused
❌ **Maintenance Burden:** More tools = more documentation, more debugging

### When Chezmoi WOULD Be Useful

✅ **If we had:** Machine-specific dotfile templates (work vs personal)
✅ **If we had:** Secrets management (Chezmoi can encrypt)
✅ **If we had:** Complex templating needs

**Reality:** We have none of these. Machine-specific config is handled via `.zshrc.local` (gitignored, manual file).

---

## Conclusion

**Decision:** **REMOVE CHEZMOI**

**Timeline:**
- **Phase 0 (Now):** Decision documented
- **Phase 1 (Week 1):** Migrate Chezmoi functionality to Nix
- **Phase 3 (Week 3):** Remove Chezmoi files after validation

**Sign-Off:** Phase 0.3 Complete

---

*Last Updated: 2025-11-18*
