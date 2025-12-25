---
scope: ghostty/
updated: 2025-12-24
relates_to:
  - ../CLAUDE.md
  - ../modules/home-manager/programs/ghostty.nix
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with Ghostty configuration in this directory.

## Overview

Ghostty is a GPU-accelerated terminal emulator written in Zig. This directory contains a minimal configuration that leverages Ghostty's sensible defaults.

## File Structure

```
ghostty/
+-- config          # Main Ghostty configuration file
```

## Configuration File Location

**Target symlink locations (platform-specific):**
- **macOS:** `~/Library/Application Support/com.mitchellh.ghostty/config`
- **Linux:** `~/.config/ghostty/config` (XDG standard)

The installation scripts (`scripts/install.sh`) automatically detect the platform and create the correct symlink.

## Current Configuration

The config is intentionally minimal:

```
theme = Cursor Dark
keybind = cmd+shift+r=prompt_surface_title
```

### Theme
- Uses "Cursor Dark" theme
- Ghostty ships with many built-in themes
- View available themes: `ghostty +list-themes`

### Keybindings
- `cmd+shift+r` - Prompt for surface title (custom window title)
- Ghostty has extensive keybinding support

## Making Changes

### Edit Configuration
```bash
nvim ~/Projects/dev-config/ghostty/config
```

### Apply Changes
Changes take effect **immediately** - no restart required!

### View All Options
```bash
ghostty +show-config --default --docs
```

This shows all available configuration options with documentation.

## Common Customizations

### Font Configuration
```
font-family = "JetBrains Mono"
font-size = 14
```

### Window Configuration
```
window-padding-x = 10
window-padding-y = 10
window-decoration = false  # Borderless window
```

### Shell Configuration
```
shell-integration = zsh
shell-integration-features = cursor,sudo,title
```

### Background Opacity
```
background-opacity = 0.95
```

## Philosophy

This configuration follows the principle of **minimal override**:
- Ghostty's defaults are excellent
- Only customize what you truly need different
- Avoid cargo-culting extensive configs

## Resources

- Official docs: https://ghostty.org/docs
- All config options: https://ghostty.org/docs/config
- Themes: `ghostty +list-themes`
- Keybind syntax: https://ghostty.org/docs/config/keybind
