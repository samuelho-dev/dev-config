# Native Claude Code bootstrap

Home Manager enables `dev-config.claude-code.enable` in the shared personal/work
profile and the DevPod configuration. This module only bootstraps the CLI:

- Keeps any existing executable `claude` without invoking, replacing or upgrading
  it. Discovery covers the managed home package bin directory, activation PATH,
  configured session paths, `/opt/homebrew/bin` on Darwin, `/usr/local/bin`,
  `/usr/bin`, `/bin`, and `~/.local/bin`.
- Only when absent, downloads the [official native installer](https://code.claude.com/docs/en/setup)
  from `https://claude.ai/install.sh` into a private temporary file. The script
  runs only after a successful fetch; fetch/installer failures fail activation,
  and the temporary file is cleaned up on exit.
- Uses the default floating latest release, not npm or a Nix-store CLI package.
  The official installer owns `~/.local/bin/claude` and versioned data under
  `~/.local/share/claude`. The bootstrap never creates or replaces the launcher.
  Native installations handle their own auto-updates and `claude update`.
- Adds `~/.local/bin` to the session PATH. Managed curl/coreutils and bounded CLI
  discovery are scoped to this activation; global `home.emptyActivationPath`
  policy is unchanged. Home Manager dry runs skip all downloads and writes.

No settings, OAuth credentials, skills, agents, commands, plugins or vendor
resources are exported, deleted or rewritten. There is no proxy routing or
skip-permissions alias. MCP configuration remains independently managed by
`dev-config.mcp` and its explicit `targets.claude` opt-in, not this bootstrap.
Existing installs retain their existing update mechanism and configuration.

Manual bootstrap with curl/coreutils on PATH:

```sh
bash ai/claude/bootstrap.sh
```

Hermetic regression check (mocked curl/installer/Claude; no network, vendor code,
installs or Claude sessions):

```sh
bash scripts/test-claude-bootstrap.sh
```
