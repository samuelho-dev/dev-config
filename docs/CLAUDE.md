---
scope: docs/
updated: 2025-12-21
relates_to:
  - ../CLAUDE.md
  - ./INDEX.md
  - ./README.md
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with documentation in this directory.

## Purpose

The `docs/` directory contains **user-facing documentation** for the entire dev-config repository. This is the primary reference for users installing, configuring, and troubleshooting the development environment.

## Documentation Architecture

### Documentation Types

**User Guides (Markdown files in this directory):**
- Installation instructions
- Configuration guides
- Keybinding references
- Troubleshooting guides

**Component README.md files (in each directory):**
- Quick start for that specific component
- Common tasks and workflows
- Component-specific features

**Component CLAUDE.md files (in each directory):**
- Architectural guidance for AI assistants
- When/where to make specific changes
- Design patterns and conventions

### File Organization

```
docs/
+-- README.md                  # This directory overview (you are here)
+-- CLAUDE.md                  # AI guidance for documentation maintenance
+-- INSTALLATION.md            # Step-by-step installation guide
+-- CONFIGURATION.md           # Customization and configuration guide
+-- TROUBLESHOOTING.md         # Common issues and solutions
+-- KEYBINDINGS_NEOVIM.md      # Complete Neovim keybinding reference
+-- KEYBINDINGS_TMUX.md        # Complete tmux keybinding reference
+-- nix/                       # Nix-specific documentation (11 guides)
    +-- 00-quickstart.md                  # 5-minute setup
    +-- 01-concepts.md                    # Understanding dev-config architecture
    +-- 02-daily-usage.md                 # Common workflows
    +-- 03-troubleshooting.md             # Common issues and resolutions
    +-- 05-1password-setup.md             # 1Password CLI and secrets
    +-- 06-advanced.md                    # Advanced customization
    +-- 07-litellm-proxy-setup.md         # LiteLLM team proxy
    +-- 08-home-manager.md                # Home Manager guide
    +-- 09-1password-ssh.md               # SSH + 1Password integration
    +-- 10-biome-integration.md           # Biome linting guide
    +-- 11-strict-linting-guide.md        # Comprehensive linting policies
```

## When to Update Documentation

### INSTALLATION.md

**Update when:**
- Adding new dependencies or prerequisites
- Changing installation scripts (`scripts/install.sh`)
- Adding platform-specific installation steps
- Changing minimum version requirements
- Adding new verification steps

**Examples:**
- New LSP server added → Update "What Gets Installed" section
- New API provider added → Update "API Key Setup" section
- New platform support → Add platform-specific instructions

### CONFIGURATION.md

**Update when:**
- Adding configurable features
- Adding new environment variables
- Adding new machine-specific settings
- Changing default configurations
- Adding customization options

**Examples:**
- New AI provider → Document API key configuration
- New plugin with config options → Add customization section
- New keybinding added → Document how to customize

### TROUBLESHOOTING.md

**Update when:**
- Fixing common bugs
- Adding new health check warnings
- Identifying recurring user issues
- Adding workarounds for known limitations
- Changing diagnostic commands

**Examples:**
- New "expected warning" added → Document in health check section
- Plugin loading issue fixed → Add to plugin troubleshooting
- LSP server issue → Add to LSP section with diagnostic steps

### KEYBINDINGS_NEOVIM.md

**Update when:**
- Adding new keybindings to `nvim/lua/config/keymaps.lua`
- Adding plugin keybindings
- Changing existing keybindings
- Adding custom commands

**Format:**
```markdown
| Keybinding | Mode | Description |
|------------|------|-------------|
| `<leader>ce` | Normal | Copy LSP errors to clipboard |
```

### KEYBINDINGS_TMUX.md

**Update when:**
- Adding keybindings to `tmux/tmux.conf`
- Adding plugin keybindings
- Changing tmux prefix key
- Adding custom bindings

## Documentation Standards

### Writing Style

**User-focused documentation:**
- Clear, concise language
- Step-by-step instructions
- Real examples, not placeholders
- "You" voice (direct address)
- Assume basic terminal knowledge, explain advanced concepts

**AI-focused documentation (CLAUDE.md files):**
- Technical and precise
- Architectural reasoning
- Pattern explanations
- Integration points
- Troubleshooting patterns

### Code Examples

**Always include:**
- Language hints for syntax highlighting
- Working examples (not pseudo-code)
- Expected output when relevant
- Context (where to run the command)

**Good example:**
```markdown
Check LSP status:
```vim
:LspInfo
```

Expected output shows attached LSP servers and their status.
```

**Bad example:**
```markdown
Check LSP status with the LSP info command.
```

### Cross-Referencing

**Link to related documentation:**
- Use relative paths: `[nvim/README.md](../nvim/README.md)`
- Link to specific sections: `[API Keys](CONFIGURATION.md#api-key-setup)`
- Provide context for why the link is relevant

**Examples:**
- Configuration guide links to troubleshooting
- Keybinding reference links to feature documentation
- Installation guide links to verification in troubleshooting

## Maintenance Workflow

### When Code Changes

**For new features:**
1. Add to relevant user guide (INSTALLATION, CONFIGURATION, or component README)
2. Add keybindings to KEYBINDINGS_NEOVIM.md or KEYBINDINGS_TMUX.md
3. Add troubleshooting section if complex
4. Update component CLAUDE.md with architectural notes

**For bug fixes:**
1. Add to TROUBLESHOOTING.md if user-facing
2. Update component CLAUDE.md if architectural
3. Remove outdated workarounds

**For configuration changes:**
1. Update CONFIGURATION.md with new options
2. Update default values in examples
3. Update troubleshooting if behavior changed

### Keeping Documentation Fresh

**Regular reviews:**
- After major feature additions
- After refactoring
- When users report confusion
- During health check updates

**What to check:**
- Are all keybindings documented?
- Are all configuration options explained?
- Are troubleshooting steps still accurate?
- Are examples up-to-date with current code?
- Are cross-references valid?

## Common Documentation Tasks

### Adding a New Keybinding

1. **Document in keybinding reference:**
   ```markdown
   | `<leader>new` | Normal | Description of new feature |
   ```

2. **Add to feature documentation:**
   ```markdown
   ## New Feature

   Press `<leader>new` to activate the feature.
   ```

3. **Add to CONFIGURATION.md if customizable:**
   ```markdown
   ### Customizing New Feature

   Edit `path/to/config.lua`:
   ```lua
   vim.keymap.set('n', '<leader>new', ...)
   ```
   ```

### Adding a New Plugin

1. **Document in component README:**
   - What the plugin does
   - Key keybindings
   - Configuration options

2. **Add keybindings to reference:**
   - Include all plugin keybindings in table format

3. **Add to INSTALLATION.md:**
   - If new dependencies required
   - If new LSP server or formatter

4. **Add troubleshooting section if needed:**
   - Common issues
   - Health check warnings
   - Diagnostic steps

### Adding a New Configuration Option

1. **Document in CONFIGURATION.md:**
   ```markdown
   ### Feature Name

   Configure by editing `~/.zshrc.local`:
   ```bash
   export NEW_OPTION="value"
   ```

   **Options:**
   - `value1` - Description
   - `value2` - Description
   ```

2. **Update INSTALLATION.md if part of setup:**
   - Add to "Configuration" section
   - Include in post-install steps

### Documenting Troubleshooting

**Format:**
```markdown
### Symptom: What the user sees

**Cause:** Why this happens

**Solution:**
1. Step one
2. Step two
3. Verification step

**Example:**
```bash
command to fix issue
```
```

## Documentation Patterns

### Health Check Warnings

**Pattern for expected warnings:**
```markdown
### Warning Name ✅ EXPECTED

```
⚠️ WARNING message text
```

**Why this exists:**
- Reason for warning
- Intentional trade-off

**Action:** Ignore (or how to fix if desired)
```

### Feature Documentation

**Pattern:**
```markdown
## Feature Name

**Purpose:** One-sentence description

**Keybindings:**
- `<key>` - Action

**Usage:**
1. Step one
2. Step two

**Example:**
[Code example]
```

### Configuration Documentation

**Pattern:**
```markdown
### Option Name

**Default:** `default_value`

**Description:** What this option controls

**Configuration:**
```language
code example
```

**Example use cases:**
- Use case 1
- Use case 2
```

## Integration with Component Documentation

### Hierarchy

**docs/ (this directory):**
- Repository-wide guides
- Cross-component workflows
- Installation and troubleshooting

**Component README.md:**
- Component-specific quick start
- Feature overview
- Common tasks

**Component CLAUDE.md:**
- Architectural details
- Code organization
- Modification patterns

### Content Duplication Policy

**Avoid duplicating:**
- Detailed feature descriptions (link to component README)
- Architectural details (keep in CLAUDE.md)
- Code examples (reference actual files)

**OK to duplicate:**
- Essential keybindings (in both keybinding reference and component docs)
- Installation steps (summary in INSTALLATION.md, details in component README)
- Common troubleshooting (overview in TROUBLESHOOTING.md, details in component CLAUDE.md)

## For Future Claude Code Instances

**When updating documentation:**

1. **Identify documentation type:**
   - User guide → Update relevant .md file in docs/
   - Component-specific → Update component README.md
   - Architectural → Update component CLAUDE.md

2. **Check cross-references:**
   - Update all documents that reference the changed feature
   - Verify links still work
   - Update version numbers or dates if relevant

3. **Follow standards:**
   - Use markdown formatting consistently
   - Include code blocks with language hints
   - Add examples for new features
   - Update tables and lists

4. **Test examples:**
   - Verify commands work
   - Check file paths are correct
   - Ensure keybindings are accurate

5. **Common locations for specific updates:**
   - New dependency → INSTALLATION.md
   - New keybinding → KEYBINDINGS_NEOVIM.md or KEYBINDINGS_TMUX.md
   - New config option → CONFIGURATION.md
   - New issue/warning → TROUBLESHOOTING.md
   - New plugin → Component README.md + keybinding reference
   - Architecture change → Component CLAUDE.md
   - New linting rule → biome/CLAUDE.md + docs/nix/11-strict-linting-guide.md
   - New IaC tool → iac-linting/ config + main CLAUDE.md
   - New GritQL pattern → biome/gritql-patterns/ + biome/CLAUDE.md
