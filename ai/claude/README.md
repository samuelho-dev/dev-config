# Native Claude Code bootstrap

Home Manager selects `dev-config.claude-code.enable` alongside the other five
native CLIs in personal and headless profiles. The shared `ai/bootstrap.sh`
preserves working versions on `install`, executes them on `check`, and invokes
the native CLI's updater only on explicit `update claude`. The standalone
installer is used only if Claude is missing or an explicit update migrates an
existing non-native installation into writable `~/.local`.

- Only when absent, downloads the [official native installer](https://code.claude.com/docs/en/setup)
  from `https://claude.ai/install.sh` into a private temporary file. The script
  runs only after a successful fetch; fetch/installer failures fail activation,
  and the temporary file is cleaned up on exit.
- Uses the default floating latest release, not npm or a Nix-store CLI package.
  The official installer owns `~/.local/bin/claude` and versioned data under
  `~/.local/share/claude`. The bootstrap never creates or replaces the launcher.
  `DISABLE_AUTOUPDATER=1` in managed profiles disables implicit CLI upgrades;
  `bash ai/bootstrap.sh update claude` explicitly allows a native upgrade.
  Home Manager dry runs skip all downloads and writes.

No settings, OAuth credentials, skills, agents, commands, plugins or vendor
resources are exported, deleted or rewritten. There is no proxy routing or
skip-permissions alias. MCP configuration remains independently managed by
`dev-config.mcp` and its explicit `targets.claude` opt-in, not this bootstrap.
Existing installs retain their credentials and configuration. Manual operations:

```sh
bash ai/bootstrap.sh install claude
bash ai/bootstrap.sh update claude
bash ai/bootstrap.sh check claude
```

Hermetic regression check (mocked curl/installer/Claude; no network, vendor code,
installs or Claude sessions):

```sh
bash scripts/test-claude-bootstrap.sh
```
