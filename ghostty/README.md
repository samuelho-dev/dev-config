# Ghostty Configuration

GPU-accelerated terminal emulator configuration.

## What is Ghostty?

Ghostty is a fast, feature-rich terminal emulator written in Zig. It's designed for performance and native platform integration.

**Key features:**
- GPU-accelerated rendering
- Native macOS and Linux support
- Extensive configuration options
- Built-in theme support
- Shell integration (zsh, bash, fish)
- Live configuration reload

## Configuration

This directory contains a minimal `config` file that sets:
- Theme: Cursor Dark
- Custom keybinding: `cmd+shift+r` for surface title prompt

Ghostty ships with sensible defaults, so we only override what's needed.

## Installation

Ghostty config is symlinked during `scripts/install.sh`:

**macOS:**
```
~/Library/Application Support/com.mitchellh.ghostty/config → ghostty/config
```

**Linux:**
```
~/.config/ghostty/config → ghostty/config
```

## Usage

### Viewing Configuration
```bash
# Show current config with documentation
ghostty +show-config --default --docs

# List all available themes
ghostty +list-themes

# Show keybindings
ghostty +show-config | grep keybind
```

### Customizing

Edit `ghostty/config`:
```bash
nvim ~/Projects/dev-config/ghostty/config
```

Changes apply **immediately** - no restart needed!

### Common Options

```
# Font
font-family = "JetBrains Mono"
font-size = 14

# Window
window-padding-x = 10
window-padding-y = 10
background-opacity = 0.95

# Shell integration
shell-integration = zsh
shell-integration-features = cursor,sudo,title

# Theme
theme = Catppuccin Mocha
```

## Themes

Ghostty includes many built-in themes. View them:
```bash
ghostty +list-themes
```

Popular choices:
- Catppuccin (Mocha, Latte, Frappe, Macchiato)
- Tokyo Night
- Nord
- Gruvbox
- Dracula

## Resources

- Homepage: https://ghostty.org
- Documentation: https://ghostty.org/docs
- Configuration reference: https://ghostty.org/docs/config
- GitHub: https://github.com/ghostty-org/ghostty
