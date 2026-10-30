# Shared Pi toolbox

Home Manager selects Pi alongside the five other shared native CLIs in both
personal and headless profiles. `ai/bootstrap.sh install` installs missing
CLIs in writable `~/.local/bin` without upgrading working versions;
`ai/bootstrap.sh update pi` explicitly requests the latest Pi CLI from npm
using the writable `~/.local` prefix. `ai/bootstrap.sh check` executes enabled
CLIs. The selected set is published at `~/.config/dev-config/native-tools`.
Pi itself is never installed in the Nix store. Its per-agent bootstrap:

1. Runs `apply-plugins.sh` to register only exact sources from `packages.txt`
   missing from global Pi settings. Existing string entries and object entries
   with a matching `source` are retained, including their resource filters.
   No existing registrations are removed, reinstalled, or upgraded.
2. Merges only the keys declared in `subagents.json` into writable
   `~/.pi/agent/extensions/subagent/config.json`, preserving other profile fields.
   `toolActivation: eager` makes native delegation available immediately, with
   compact descriptions, three concurrent workers, one delegation level, and
   bounded run/session spawn limits. No provider/model is pinned.

Both settings and the existing subagent profile must be JSON objects. Invalid
JSON or a non-array `packages` value stops registration/profile changes without
printing configuration contents. The profile is replaced atomically with mode
0600 only when its owned keys change; it is not a read-only settings symlink.
Package-manager failures fail activation rather than being ignored. Successful
registrations before a later installation failure remain in place for retry.
Home Manager dry runs skip all bootstrap, registration, and profile writes.

`PI_CODING_AGENT_DIR` overrides the global agent directory for both Pi and the
profile merge. Project-local settings are not managed. Manual operations:

```sh
bash ai/bootstrap.sh install pi
bash ai/bootstrap.sh update pi
bash ai/bootstrap.sh check pi
```

All package sources remain floating. Only explicit CLI updates change an
existing working Pi version; Pi model/package updates remain user operations.

Restart Pi after changing `toolActivation`; reloading extensions is not enough.
Credentials remain in the machine's environment or private Pi configuration; no
credentials are managed here. Context7 may require `CONTEXT7_API_KEY` when its
free quota is exhausted.

Hermetic regression check (mocked Pi/npm; no network, installs, or live agents):

```sh
bash scripts/test-pi-bootstrap.sh
```
