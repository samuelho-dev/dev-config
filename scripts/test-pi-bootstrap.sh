#!/usr/bin/env bash
# Hermetic: only mocked pi/npm are reachable by the bootstrap.
set -euo pipefail
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/config with spaces/extensions/subagent"
for tool in node bash dirname; do
  ln -s "$(command -v "$tool")" "$tmp/bin/$tool"
done
export HOME="$tmp/home" PI_CODING_AGENT_DIR="$tmp/config with spaces"
export PI_TEST_LOG="$tmp/pi.log" NPM_TEST_LOG="$tmp/npm.log" PI_TEST_MOCK="$tmp/pi-mock"
: > "$PI_TEST_LOG"
: > "$NPM_TEST_LOG"
cat > "$PI_TEST_MOCK" <<'MOCK'
#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const args = process.argv.slice(2);
if (args.length !== 2 || args[0] !== 'install') process.exit(90);
fs.appendFileSync(process.env.PI_TEST_LOG, `${args[1]}\n`);
if (process.env.PI_TEST_FAIL) process.exit(42);
const { homedir } = require('node:os');
let agentDir = process.env.PI_CODING_AGENT_DIR || path.join(homedir(), '.pi', 'agent');
if (agentDir === '~') agentDir = homedir();
else if (agentDir.startsWith('~/')) agentDir = path.join(homedir(), agentDir.slice(2));
const file = path.join(agentDir, 'settings.json');
const settings = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : {};
settings.packages = [...(settings.packages || []), args[1]];
fs.mkdirSync(path.dirname(file), {recursive: true});
fs.writeFileSync(file, JSON.stringify(settings));
MOCK
chmod +x "$PI_TEST_MOCK"
cp "$PI_TEST_MOCK" "$tmp/bin/pi"
mkdir -p "$HOME/.local/bin"
printf '#!/bin/sh\nexit 92\n' > "$HOME/.local/bin/pi"
chmod +x "$HOME/.local/bin/pi"
cat > "$tmp/bin/npm" <<'MOCK'
#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const args = process.argv.slice(2);
if (JSON.stringify(args) !== JSON.stringify(['install', '--global', '--prefix', `${process.env.HOME}/.local`, '@earendil-works/pi-coding-agent'])) process.exit(91);
fs.appendFileSync(process.env.NPM_TEST_LOG, `${args.join(' ')}\n`);
if (process.env.NPM_TEST_FAIL) process.exit(43);
const bin = path.join(process.env.HOME, '.local/bin');
fs.mkdirSync(bin, {recursive: true});
fs.copyFileSync(process.env.PI_TEST_MOCK, path.join(bin, 'pi'));
fs.chmodSync(path.join(bin, 'pi'), 0o755);
MOCK
chmod +x "$tmp/bin/npm"
bootstrap() { PATH="$tmp/bin" bash "$root/ai/pi/bootstrap.sh"; }
settings="$PI_CODING_AGENT_DIR/settings.json"
profile="$PI_CODING_AGENT_DIR/extensions/subagent/config.json"
cat > "$settings" <<'JSON'
{"model":"keep","custom":{"nested":true},"packages":["npm:pi-web-access",{"source":"npm:@upstash/context7-pi","extensions":["keep"]},"npm:unrelated"]}
JSON
printf '{"toolActivation":"auto","model":"inherit","custom":{"nested":true}}\n' > "$profile"
bootstrap
[[ ! -s "$NPM_TEST_LOG" ]] # An existing PATH installation wins, even over local Pi.
node - "$settings" "$profile" "$root/ai/pi/subagents.json" "$PI_TEST_LOG" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const [settingsFile, profileFile, ownedFile, logFile] = process.argv.slice(2);
const settings = JSON.parse(fs.readFileSync(settingsFile));
assert.equal(settings.model, 'keep');
assert.deepEqual(settings.custom, {nested: true});
assert.deepEqual(settings.packages.slice(0, 3), ['npm:pi-web-access', {source: 'npm:@upstash/context7-pi', extensions: ['keep']}, 'npm:unrelated']);
assert.deepEqual(fs.readFileSync(logFile, 'utf8').trim().split('\n'), ['npm:pi-subagents', 'npm:@aliou/pi-processes', 'npm:@capdiem/pi-todo']);
const profile = JSON.parse(fs.readFileSync(profileFile));
for (const [key, value] of Object.entries(JSON.parse(fs.readFileSync(ownedFile)))) assert.deepEqual(profile[key], value);
assert.equal(profile.toolActivation, 'eager');
assert.equal(profile.model, 'inherit');
assert.deepEqual(profile.custom, {nested: true});
assert.equal(fs.statSync(profileFile).mode & 0o777, 0o600);
NODE
cp "$settings" "$tmp/settings-before"
cp "$profile" "$tmp/profile-before"
cp "$PI_TEST_LOG" "$tmp/log-before"
bootstrap
cmp "$settings" "$tmp/settings-before"
cmp "$profile" "$tmp/profile-before"
cmp "$PI_TEST_LOG" "$tmp/log-before"

# Invalid JSON/types must fail before any installs or profile writes, without leaks.
for invalid in '{"secret":"TEST_SECRET_DO_NOT_PRINT",' 'null' '[]' '{"packages":{}}' '{"packages":null}'; do
  printf '%s\n' "$invalid" > "$settings"
  cp "$settings" "$tmp/invalid-before"
  if bootstrap > "$tmp/error" 2>&1; then echo 'invalid settings accepted' >&2; exit 1; fi
  ! grep -q TEST_SECRET_DO_NOT_PRINT "$tmp/error"
  cmp "$settings" "$tmp/invalid-before"
  cmp "$profile" "$tmp/profile-before"
  cmp "$PI_TEST_LOG" "$tmp/log-before"
done
printf '{}\n' > "$settings"
printf '{"secret":"TEST_SECRET_DO_NOT_PRINT",\n' > "$profile"
cp "$profile" "$tmp/invalid-before"
if bootstrap > "$tmp/error" 2>&1; then echo 'invalid profile accepted' >&2; exit 1; fi
! grep -q TEST_SECRET_DO_NOT_PRINT "$tmp/error"
cmp "$profile" "$tmp/invalid-before"
cmp "$PI_TEST_LOG" "$tmp/log-before"

# Dry-run must not invoke either package manager or touch invalid configuration.
DRY_RUN_CMD=echo bootstrap
DRY_RUN_CMD=echo PATH="$tmp/bin" bash "$root/ai/pi/apply-plugins.sh"
cmp "$profile" "$tmp/invalid-before"
cmp "$PI_TEST_LOG" "$tmp/log-before"
rm "$settings" "$profile"

# Propagate Pi failures; never continue to write the profile.
if PI_TEST_FAIL=1 bootstrap > "$tmp/error" 2>&1; then echo 'Pi failure swallowed' >&2; exit 1; fi
[[ ! -e "$settings" && ! -e "$profile" ]]
rm "$tmp/bin/pi" "$HOME/.local/bin/pi"
: > "$PI_TEST_LOG"
# A dry-run with Pi absent must not install it.
DRY_RUN_CMD=echo bootstrap
[[ ! -s "$NPM_TEST_LOG" && ! -e "$HOME/.local/bin/pi" ]]
if NPM_TEST_FAIL=1 bootstrap > "$tmp/error" 2>&1; then echo 'npm failure swallowed' >&2; exit 1; fi
[[ ! -e "$HOME/.local/bin/pi" && ! -s "$PI_TEST_LOG" ]]
: > "$NPM_TEST_LOG"
bootstrap
[[ -x "$HOME/.local/bin/pi" && $(wc -l < "$NPM_TEST_LOG") -eq 1 && $(wc -l < "$PI_TEST_LOG") -eq 5 ]]
cp "$NPM_TEST_LOG" "$tmp/npm-before"
cp "$PI_TEST_LOG" "$tmp/log-before"
bootstrap
cmp "$NPM_TEST_LOG" "$tmp/npm-before"
cmp "$PI_TEST_LOG" "$tmp/log-before"

# Model the Pi-only PATH augmentation when HM starts with an empty/minimal PATH:
# managed Node/npm first, then activation tools, session paths, discovery paths.
rm "$HOME/.local/bin/pi" "$settings"
mkdir -p "$tmp/session/bin" "$tmp/empty-activation"
cp "$PI_TEST_MOCK" "$tmp/session/bin/pi"
printf '#!/bin/sh\nexit 93\n' > "$tmp/session/bin/node"
chmod +x "$tmp/session/bin/node"
: > "$PI_TEST_LOG"
PATH="$tmp/bin:$tmp/empty-activation:$HOME/.local/bin:$tmp/session/bin" \
  "$tmp/bin/bash" "$root/ai/pi/bootstrap.sh"
cmp "$NPM_TEST_LOG" "$tmp/npm-before"
[[ ! -e "$HOME/.local/bin/pi" && $(wc -l < "$PI_TEST_LOG") -eq 5 ]]

# Quoted tilde overrides must resolve like Pi, independent of activation cwd.
cp "$PI_TEST_MOCK" "$tmp/bin/pi"
mkdir -p "$tmp/tilde-cwd"
for override in '~/.pi/tilde-agent' '~'; do
  if [[ "$override" == '~' ]]; then agent_dir="$HOME"; else agent_dir="$HOME/.pi/tilde-agent"; fi
  mkdir -p "$agent_dir/extensions/subagent"
  printf '{"custom":true}\n' > "$agent_dir/extensions/subagent/config.json"
  : > "$PI_TEST_LOG"
  (cd "$tmp/tilde-cwd"; PI_CODING_AGENT_DIR="$override" bootstrap)
  node - "$agent_dir" "$root/ai/pi" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const [agentDir, sourceDir] = process.argv.slice(2);
const settings = JSON.parse(fs.readFileSync(path.join(agentDir, 'settings.json')));
assert.deepEqual(settings.packages, fs.readFileSync(path.join(sourceDir, 'packages.txt'), 'utf8').trim().split('\n'));
const profile = JSON.parse(fs.readFileSync(path.join(agentDir, 'extensions/subagent/config.json')));
assert.deepEqual(profile, {custom: true, ...JSON.parse(fs.readFileSync(path.join(sourceDir, 'subagents.json')))});
NODE
  [[ $(wc -l < "$PI_TEST_LOG") -eq 5 && ! -e "$tmp/tilde-cwd/~" ]]
  cp "$PI_TEST_LOG" "$tmp/tilde-log-before"
  cp "$agent_dir/settings.json" "$tmp/tilde-settings-before"
  cp "$agent_dir/extensions/subagent/config.json" "$tmp/tilde-profile-before"
  (cd "$tmp/tilde-cwd"; PI_CODING_AGENT_DIR="$override" bootstrap)
  cmp "$PI_TEST_LOG" "$tmp/tilde-log-before"
  cmp "$agent_dir/settings.json" "$tmp/tilde-settings-before"
  cmp "$agent_dir/extensions/subagent/config.json" "$tmp/tilde-profile-before"
  cmp "$NPM_TEST_LOG" "$tmp/npm-before"
done
printf 'Pi bootstrap regression checks passed\n'
