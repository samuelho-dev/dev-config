---
scope: tmux/
updated: 2026-06-03
relates_to:
  - ../CLAUDE.md
  - ../modules/home-manager/programs/tmux.nix
  - ../docs/KEYBINDINGS_TMUX.md
---

# CLAUDE.md

Guidance for Claude Code when working with tmux configuration in this directory.

## Architecture Overview

tmux is configured **declaratively by Home Manager** — NOT by TPM and NOT by
symlinking the file in this directory.

**Single source of truth:** `modules/home-manager/programs/tmux.nix`
(`programs.tmux.extraConfig` + the `programs.tmux.plugins` list).

Home Manager writes the real, generated config to `~/.config/tmux/tmux.conf`
and installs plugins from `pkgs.tmuxPlugins` into the Nix store. There is no
`~/.tmux.conf`, no `~/.tmux/plugins/`, and no `tpm`.

> ⚠️ `tmux/tmux.conf` in this directory is a **non-consumed reference stub**.
> Editing it has no effect. Do not symlink it. To change tmux behavior, edit
> `tmux.nix` and run `home-manager switch --flake .`.

## File Structure

```
tmux/
├── tmux.conf        # Reference stub only — points back to tmux.nix (not consumed)
├── gitmux.conf      # gitmux config for per-pane git status (symlinked to ~/.gitmux.conf)
└── scripts/         # DevPod integration (symlinked to ~/.local/bin/, gated on devpodConnect.enable)
    ├── devpod-connect.sh        # prefix+D: fzf picker → SSH session
    ├── devpod-bootstrap.sh      # run-shell on server start: auto-create sessions for online pods
    ├── devpod-mutagen-hook.sh   # session-created hook: start mutagen sync for devpod_* sessions
    └── devpod-status.sh         # status-right: count of active devpod_ sessions
```

**Symlinks (created by `tmux.nix`):**
- `~/.gitmux.conf` → `tmux/gitmux.conf`
- `~/.local/bin/devpod-*.sh` → `tmux/scripts/devpod-*.sh` (only when `dev-config.tmux.devpodConnect.enable = true`)

## Where Configuration Lives

All of these are in `modules/home-manager/programs/tmux.nix`:

| Setting | How it's set |
|---------|--------------|
| prefix (`C-a`), baseIndex, mouse, historyLimit | `programs.tmux.*` declarative options |
| keyMode vi, escapeTime, aggressiveResize, focusEvents, terminal | `programs.tmux.*` declarative options |
| plugins | `programs.tmux.plugins` list (Nix store, no TPM) |
| keybinds, copy-mode, status bar, popups, plugin settings | `programs.tmux.extraConfig` |
| DevPod integration | appended to `extraConfig` via `lib.optionalString devpodConnect.enable` |

### Module Options (`dev-config.tmux.*`)

- `enable` (default true)
- `package` (default `pkgs.tmux`)
- `gitmuxConfigSource` (path to gitmux.conf)
- `prefix`, `baseIndex`, `mouse`, `historyLimit`
- `devpodConnect.enable` + per-script source options

There is intentionally **no `configSource`** option — config is generated, not
sourced from a file.

## Plugins

Installed via `programs.tmux.plugins` (Nix store):
`sensible`, `catppuccin`, `resurrect`, `continuum`, `battery`, `cpu`,
`vim-tmux-navigator`, `yank`, `tmux-fzf`.

To add a plugin: add it to the `plugins` list in `tmux.nix`, then
`home-manager switch --flake .`. There is no `prefix + I` install step.

### Catppuccin v2 ordering (IMPORTANT)

The packaged `catppuccin` is **v2.x**, which reads its `@catppuccin_*` options
at *source time*. Two consequences:

1. Options use the spelling `@catppuccin_flavor` (no `u`). The old v0.3
   `@catppuccin_flavour` is silently ignored.
2. Options must be set **before** the plugin's `run-shell`. Home Manager emits
   a plugin **attrset's** `extraConfig` immediately before that plugin's
   `run-shell`, so catppuccin is configured as:

   ```nix
   {
     plugin = catppuccin;
     extraConfig = ''
       set -g @catppuccin_flavor 'mocha'
       set -g @catppuccin_window_status_style 'rounded'
       # ...
     '';
   }
   ```

   It is also placed **ahead of** other status-line-touching plugins
   (resurrect/continuum/battery/cpu) in the list.

The status bar in the main `extraConfig` references catppuccin v2 modules
(`#{E:@catppuccin_status_session}`, `..._directory`, `..._host`,
`..._date_time`) and the `@thm_*` palette. These resolve because catppuccin is
sourced earlier. The plugin sets `status-style` itself; do not set it before
the plugin sources (the `@thm_*` vars don't exist yet).

### vim-tmux-navigator

Seamless `C-h/j/k/l` navigation between Neovim splits and tmux panes (no
prefix). Neovim side is configured in the Neovim config.

### resurrect + continuum

Session persistence. `@continuum-restore on`, save every 60 min,
`@resurrect-processes 'ssh'` (preserves DevPod SSH sessions). Manual:
`prefix + C-s` save, `prefix + C-r` restore. State in `~/.tmux/resurrect/`.

## DevPod Integration

Gated on `dev-config.tmux.devpodConnect.enable`. Tailscale-based.

- **`prefix + D`** → `devpod-connect.sh`: lists online `devpod-*` peers via
  `tailscale status --json`, fzf picker, creates/switches to a `devpod_<proj>`
  session that SSHes in.
- **Server start** → `devpod-bootstrap.sh` runs synchronously (`run-shell`),
  auto-creating `devpod_<proj>` sessions for every online pod.
- **`session-created` hook** → `devpod-mutagen-hook.sh <session>`: starts
  `mutagen project start` if the session is `devpod_*` and the project has
  `mutagen.yml`. This is the **single** mutagen entry point — connect and
  bootstrap no longer inline mutagen logic.

**Shared SSH form** (connect and bootstrap are aligned):
```bash
ssh -t coder@<host>.<magicdns-suffix> 'cd ~ && exec zsh'
```
`-t` + `exec zsh` bypasses the container login shell (which fails with
`mesg: cannot change mode` due to missing `CAP_FOWNER`). Sessions start in `~`
(not the workspace) to avoid triggering direnv/nix on connect, with
`remain-on-exit on`. The MagicDNS suffix is resolved dynamically from
`tailscale status --json | .MagicDNSSuffix` (not hardcoded).

## gitmux (per-pane git status)

`pane-border-format` runs gitmux per pane to show branch/status in each pane
border — critical for git-worktree workflows where different panes sit on
different branches. gitmux is isolated from direnv to avoid Nix flake
evaluation in subshells:

```
#(env -u DIRENV_DIR -u DIRENV_WATCHES gitmux -cfg ~/.gitmux.conf '#{pane_current_path}')
```

Colors/symbols configured in `tmux/gitmux.conf` (Catppuccin Mocha palette).
Note: gitmux is used in **pane borders**, independent of catppuccin's own
status-line gitmux module.

## Claude Code + Git Worktree Workflow

Run isolated Claude Code instances in separate panes/worktrees. `zsh/.zshrc`
exports `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1` so each Claude instance
stays locked to its starting directory. The gitmux pane border shows which
branch each pane is on.

## Modifying Configuration

1. Edit `programs.tmux` / `extraConfig` / `plugins` in
   `modules/home-manager/programs/tmux.nix`.
2. `nix fmt modules/home-manager/programs/tmux.nix`
3. `home-manager build --flake .` (verify it builds)
4. `home-manager switch --flake .` (apply)
5. `prefix + r` to reload the live session (sources `~/.config/tmux/tmux.conf`).

DevPod scripts in `tmux/scripts/` are symlinked, so edits to script **content**
take effect without a rebuild; adding/removing a script requires a rebuild.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Theme not applying | Confirm `@catppuccin_flavor` (no `u`) is in the plugin **attrset** extraConfig, before its run-shell. Verify ordering in `~/.config/tmux/tmux.conf`. |
| Colors wrong | `echo $TERM` should be `tmux-256color`. |
| gitmux blank | `which gitmux`; test `gitmux -cfg ~/.gitmux.conf $(pwd)`; check `~/.gitmux.conf` symlink. |
| DevPod picker missing | `dev-config.tmux.devpodConnect.enable` true? `tailscale` reachable? Debug log at `/tmp/devpod-connect.log`. |
| Session not restoring | `ls ~/.tmux/resurrect/`; `prefix + C-r`. |
| Edits to `tmux/tmux.conf` ignored | Expected — that file is a stub. Edit `tmux.nix`. |

## Resources

- Full keybindings: `docs/KEYBINDINGS_TMUX.md`
- catppuccin/tmux (v2): https://github.com/catppuccin/tmux
- vim-tmux-navigator: https://github.com/christoomey/vim-tmux-navigator
- tmux-resurrect: https://github.com/tmux-plugins/tmux-resurrect
- gitmux: https://github.com/arl/gitmux
