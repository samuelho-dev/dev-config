# Yazi File Manager

Terminal file manager with image previews and Neovim integration.

## Quick Start

```bash
# Open yazi with cd-on-exit
yy

# Open yazi without cd-on-exit
yazi
```

## Features

| Feature | Description |
|---------|-------------|
| **Image previews** | Inline images in terminal (Ghostty + tmux) |
| **Fast navigation** | Vim-like keybindings (h/j/k/l) |
| **File search** | `<C-s>` for fd, `<C-g>` for ripgrep |
| **Neovim integration** | `<leader>fy` opens yazi floating window |
| **Multi-select** | Visual mode for bulk operations |

## Keybindings

### Shell

| Key | Action |
|-----|--------|
| `yy` | Open yazi (cd-on-exit) |
| `yazi` | Open yazi (no cd) |

### Inside Yazi

| Key | Action |
|-----|--------|
| `j/k` | Move down/up |
| `h/l` | Parent/Enter directory |
| `<Space>` | Toggle selection |
| `v` | Visual mode |
| `y` | Yank (copy) |
| `x` | Cut |
| `p` | Paste |
| `d` | Delete |
| `r` | Rename |
| `c` | Create file/directory |
| `<C-s>` | Search files (fd) |
| `<C-g>` | Search content (ripgrep) |
| `q` | Quit (cd to current dir) |
| `Q` | Quit (stay in original dir) |

### Neovim Integration

| Key | Action |
|-----|--------|
| `<leader>fy` | Open yazi |
| `<leader>fw` | Open yazi in cwd |
| `<leader>fY` | Resume last session |
| `<c-v>` | Open in vertical split |
| `<c-x>` | Open in horizontal split |
| `<c-t>` | Open in new tab |

## Configuration

Yazi is configured **declaratively via Home Manager**:

```nix
# modules/home-manager/programs/yazi.nix
programs.yazi = {
  enable = true;
  enableZshIntegration = true;
  shellWrapperName = "yy";

  settings = {
    mgr = {
      ratio = [ 1 4 3 ];
      sort_by = "natural";
      sort_dir_first = true;
    };
  };

  keymap = {
    mgr.prepend_keymap = [
      { on = [ "<C-s>" ]; run = "search fd"; desc = "Search with fd"; }
    ];
  };
};
```

## Image Previews

Enabled automatically with Ghostty terminal + tmux.

**Requirements:**
- Ghostty terminal (Kitty protocol support)
- tmux with `allow-passthrough on`
- ffmpegthumbnailer (video thumbnails)
- imagemagick (image processing)
- poppler (PDF previews)

## Troubleshooting

### Images not showing

Check tmux has passthrough enabled:
```bash
tmux show -g allow-passthrough
# Should return: on
```

### yy not changing directory

Use `yy` wrapper, not `yazi` directly:
```bash
yy  # Correct - changes directory on exit
yazi  # Wrong - stays in original directory
```

### Search not working

Ensure fd and ripgrep are installed:
```bash
which fd rg
```

## Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Architecture and detailed configuration
- [Neovim Integration](../nvim/lua/plugins/CLAUDE.md) - yazi.nvim setup
- [Home Manager](../modules/home-manager/programs/CLAUDE.md) - Module configuration
