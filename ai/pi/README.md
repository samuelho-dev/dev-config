# Shared Pi toolbox

Home Manager enables `dev-config.pi.enable` in the shared personal/work profile
and the DevPod configuration. Activation:

1. Keeps any `pi` already on `PATH` (including an existing `~/.local/bin/pi`).
   Only when absent, uses the managed Node/npm runtime to install the floating
   `@earendil-works/pi-coding-agent` package under the writable `~/.local` prefix.
   `~/.local/bin` is on the session PATH; Pi is not installed in the Nix store.
   Because Home Manager normally strips activation PATH, this activation alone
   prepends the managed home package bin directory, then searches activation and
   configured session paths, `/opt/homebrew/bin` on Darwin, and `/usr/local/bin`,
   `/usr/bin`, `/bin`. Global activation PATH policy is unchanged.
2. Runs `apply-plugins.sh` to register only exact sources from `packages.txt`
   missing from global Pi settings. Existing string entries and object entries
   with a matching `source` are retained, including their resource filters.
   No existing registrations are removed, reinstalled, or upgraded.
3. Merges only the keys declared in `subagents.json` into writable
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
profile merge. Project-local settings are not managed. The same bootstrap can
be run manually with Node/npm already on PATH:

```sh
bash ai/pi/bootstrap.sh
# If Pi is already installed, registration/profile merge alone:
bash ai/pi/apply-plugins.sh
```

All sources remain floating. Activation deliberately does not check versions;
manual Pi CLI, package, and model updates remain available:

```sh
pi update --all
pi update --models
```

Restart Pi after changing `toolActivation`; reloading extensions is not enough.
Credentials remain in the machine's environment or private Pi configuration; no
credentials are managed here. Context7 may require `CONTEXT7_API_KEY` when its
free quota is exhausted.

Hermetic regression check (mocked Pi/npm; no network, installs, or live agents):

```sh
bash scripts/test-pi-bootstrap.sh
```
