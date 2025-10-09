# Documentation Directory

This directory contains comprehensive user guides and reference documentation for the dev-config repository.

## Overview

All documentation is written in Markdown format and organized by topic. Each guide is standalone but cross-references related documentation.

## Available Documentation

### Installation & Setup

**[INSTALLATION.md](INSTALLATION.md)** - Complete installation guide
- Prerequisites and system requirements
- Step-by-step installation instructions
- Platform-specific notes (macOS vs Linux)
- Verification steps
- Common installation issues

**[CONFIGURATION.md](CONFIGURATION.md)** - Customization guide
- Machine-specific configuration (`~/.zshrc.local`)
- Environment variable setup
- API key configuration for AI plugins
- Customizing keybindings
- Plugin management

### Troubleshooting

**[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- Installation problems
- Plugin issues
- LSP and formatter problems
- Git integration issues
- Performance optimization
- Health check warnings explained

### Keybindings Reference

**[KEYBINDINGS_NEOVIM.md](KEYBINDINGS_NEOVIM.md)** - Complete Neovim keybinding reference
- Core navigation and editing
- LSP operations (go to definition, references, rename)
- Git integration (lazygit, diffview, conflicts)
- File explorer and fuzzy finding
- Markdown and Obsidian features
- Custom utilities (diagnostic copy, TypeScript stripper)
- Debug commands

**[KEYBINDINGS_TMUX.md](KEYBINDINGS_TMUX.md)** - Complete tmux keybinding reference
- Session management
- Window and pane operations
- Copy mode
- Plugin-specific bindings (vim-tmux-navigator, fzf, resurrect)
- Popup features

## Documentation Philosophy

### User-Facing (README.md files)
- **What** - What this tool/feature does
- **How** - How to use it (examples, commands, keybindings)
- **Quick reference** - Common tasks and workflows

### AI-Facing (CLAUDE.md files)
- **Why** - Architectural decisions and design philosophy
- **Where** - Where to make changes for specific tasks
- **Patterns** - Common patterns and conventions to follow

## Quick Links

### Getting Started
1. Read [INSTALLATION.md](INSTALLATION.md) for setup
2. Check [CONFIGURATION.md](CONFIGURATION.md) for customization
3. Refer to [KEYBINDINGS_NEOVIM.md](KEYBINDINGS_NEOVIM.md) for shortcuts

### Common Tasks
- **Install on new machine:** [INSTALLATION.md](INSTALLATION.md)
- **Add API keys:** [CONFIGURATION.md](CONFIGURATION.md#api-key-setup)
- **Fix plugin issues:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md#plugin-issues)
- **Customize keybindings:** [CONFIGURATION.md](CONFIGURATION.md#keybinding-customization)

### Configuration Files
- **Neovim:** `../nvim/` - See [nvim/README.md](../nvim/README.md)
- **Tmux:** `../tmux/` - See [tmux/README.md](../tmux/README.md)
- **Zsh:** `../zsh/` - See [zsh/README.md](../zsh/README.md)
- **Ghostty:** `../ghostty/` - See [ghostty/README.md](../ghostty/README.md)

## Contributing to Documentation

When adding new features or changing behavior:

1. **Update relevant user guides** (README.md files)
   - Add to appropriate section
   - Include examples and keybindings
   - Cross-reference related features

2. **Update AI guidance** (CLAUDE.md files)
   - Document architectural decisions
   - Explain integration points
   - Update troubleshooting patterns

3. **Update keybinding references** if adding keybindings
   - Add to KEYBINDINGS_NEOVIM.md or KEYBINDINGS_TMUX.md
   - Group by category
   - Include description and use case

4. **Update TROUBLESHOOTING.md** for known issues
   - Add to appropriate section
   - Include symptoms, causes, and fixes
   - Reference related health check warnings

## Documentation Standards

### Formatting
- Use clear section headings (`##`, `###`)
- Include code blocks with language hints (```bash, ```vim, ```lua)
- Use tables for keybinding references
- Bold **important concepts** and commands
- Use `inline code` for file paths, commands, and variables

### Content
- Start with "What" and "Why" before "How"
- Include real examples, not placeholders
- Cross-reference related documentation
- Keep sections focused and scannable
- Update table of contents for long documents

### Maintenance
- Review documentation when making code changes
- Remove outdated information promptly
- Keep examples synchronized with actual code
- Test commands and examples before documenting
