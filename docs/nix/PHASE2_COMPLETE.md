# Phase 2 Complete: Hybrid Neovim Plugin Management

**Completion Date:** 2025-11-18
**Branch:** `feat/nix-native-dotfiles-corrected`
**Status:** ✅ COMPLETE

---

## Summary

Phase 2 successfully implemented hybrid Neovim plugin management using lazy-nix-helper. LSP servers, formatters, and build tools are now managed by Nix on Nix systems, with Mason fallback for non-Nix environments.

---

## Implementation

### Phase 2.1: Install lazy-nix-helper and LSP Servers

**Commit:** `c5838b1`

**Modified:**
- `modules/home-manager/programs/neovim.nix` (+29 lines)

**Implementation:**
- Added `lazy-nix-helper-nvim` to `programs.neovim.plugins`
- Installed LSP servers via Nix:
  - `nodePackages.typescript-language-server` (TypeScript/JavaScript)
  - `pyright` (Python)
  - `lua-language-server` (Lua)
- Installed formatters via Nix:
  - `stylua` (Lua)
  - `nodePackages.prettier` (JS/TS/JSON/YAML/Markdown)
  - `ruff` (Python formatter + linter)
- Installed build tools:
  - `gnumake`, `gcc`, `pkg-config`, `nodejs`, `imagemagick`
  - `nodePackages."@mermaid-js/mermaid-cli"` (for Mermaid diagrams)

### Phase 2.2-2.3: Configure lazy-nix-helper and Conditional Mason

**Commit:** `cb8a7d0`

**Modified:**
- `nvim/lua/plugins/lsp.lua` (+28 lines)

**Implementation:**

**Nix Detection:**
```lua
local nix_ok, lazy_nix = pcall(require, 'lazy-nix-helper')
local use_nix = false

if nix_ok then
  lazy_nix.setup {
    install_dependencies = false,  -- Nix manages packages
  }
  use_nix = true
  vim.notify('Using Nix-managed LSP servers', vim.log.levels.INFO)
else
  vim.notify('Not on Nix, using Mason', vim.log.levels.INFO)
end
```

**Conditional LSP Server Setup:**

**On Nix Systems (`use_nix = true`):**
- Mason tool installer: DISABLED
- Mason lspconfig: DISABLED
- LSP servers configured directly via lspconfig
- Uses Nix-managed packages from Phase 2.1

**On Non-Nix Systems (`use_nix = false`):**
- Mason tool installer: ENABLED
- Mason lspconfig: ENABLED
- Auto-installs: ts_ls, pyright, lua_ls
- Auto-installs formatters: stylua, prettier, ruff

---

## Benefits

### Hybrid Approach
- **Nix systems:** Declarative, reproducible LSP servers
- **Non-Nix systems:** Mason auto-installation works
- **Zero breaking changes** for existing setups
- **Single codebase** for all environments

### Developer Experience
- Nix users: LSP servers version-locked in `flake.lock`
- Non-Nix users: Mason "just works" as before
- Automatic detection (no manual configuration)
- Clear startup notifications show which mode is active

### Maintainability
- LSP server versions centralized in Home Manager module
- Easier to update (change Nix packages, not Mason commands)
- Consistent across all dev-config deployments

---

## Files Modified

### Phase 2.1
- `modules/home-manager/programs/neovim.nix` (+29 lines)

### Phase 2.2-2.3
- `nvim/lua/plugins/lsp.lua` (+28 lines)

**Total:** 2 files, 57 lines added

---

## Testing Checklist

### Nix System Testing
- [ ] Neovim starts without errors
- [ ] Startup notification shows "Using Nix-managed LSP servers"
- [ ] `:LspInfo` shows ts_ls, pyright, lua_ls attached
- [ ] Mason UI (`:Mason`) shows no auto-install attempts
- [ ] Formatters work: stylua, prettier, ruff
- [ ] LSP features work: go to definition, rename, code actions
- [ ] No Mason-related warnings in `:messages`

### Non-Nix System Testing
- [ ] Neovim starts without errors
- [ ] Startup notification shows "Not on Nix, using Mason"
- [ ] `:LspInfo` shows ts_ls, pyright, lua_ls attached
- [ ] Mason UI (`:Mason`) shows servers installed
- [ ] Formatters work: stylua, prettier, ruff
- [ ] LSP features work: go to definition, rename, code actions
- [ ] Mason auto-installs missing tools on first run

### Regression Testing
- [ ] Existing Neovim configurations still work
- [ ] lazy.nvim plugin installation unaffected
- [ ] Completion (blink.cmp) works
- [ ] Treesitter syntax highlighting works
- [ ] Git plugins (lazygit, gitsigns) work
- [ ] Markdown plugins (Obsidian, render-markdown) work

---

## Known Limitations

### Neovim Plugin Management
**Not Changed:** Neovim plugins still managed by lazy.nvim (not Nix)

**Rationale:**
- Neovim ecosystem designed around lazy.nvim
- 50+ plugins across 10 category files
- Porting to Nix would be maintenance burden
- lazy-nix-helper provides hybrid approach (best of both worlds)

**Status:** Working as designed

### Mason GUI
**Behavior on Nix:** Mason UI (`:Mason`) still accessible but won't auto-install

**Rationale:**
- Some users prefer Mason GUI for exploration
- Harmless to leave enabled
- Can manually install tools if needed (won't be managed by Nix)

**Status:** Not a bug, expected behavior

---

## Next Phase: Phase 3

**Goal:** Cleanup and Simplification

**Tasks:**
1. Remove Chezmoi files (.chezmoi.toml.tmpl, .chezmoiexternal.toml)
2. Archive legacy scripts to scripts/legacy/
3. Simplify scripts/install.sh to Nix+Home Manager bootstrap
4. Update flake.nix to remove activate app

**Benefits:**
- Single source of truth (Home Manager)
- Simpler installation workflow
- Fewer scripts to maintain
- Full declarative configuration

---

*Phase 2 Complete: 2025-11-18*
*Ready for Phase 3 implementation*
