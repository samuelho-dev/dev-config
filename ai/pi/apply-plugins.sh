#!/usr/bin/env bash
# Register only missing floating sources and merge the owned delegation keys.
set -euo pipefail
[[ -z "${DRY_RUN_CMD:-}" ]] || exit 0
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PACKAGES_FILE="${PI_PACKAGES_FILE:-$SCRIPT_DIR/packages.txt}"

command -v pi >/dev/null || { echo 'pi-plugins: pi is required' >&2; exit 1; }
command -v node >/dev/null || { echo 'pi-plugins: node is required' >&2; exit 1; }

node --input-type=module - "$PACKAGES_FILE" "$SCRIPT_DIR/subagents.json" <<'NODE'
import { execFileSync } from 'node:child_process';
import { readFileSync, mkdirSync, writeFileSync, renameSync, rmSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';

function readObject(file, allowMissing = false) {
  let text;
  try {
    text = readFileSync(file, 'utf8');
  } catch (error) {
    if (allowMissing && error.code === 'ENOENT') return {};
    throw new Error('Cannot read Pi configuration');
  }
  try {
    const value = JSON.parse(text);
    if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new Error();
    return value;
  } catch {
    // Never include JSON content: settings may contain credentials.
    throw new Error('Invalid Pi JSON object; no packages or profile changed');
  }
}

try {
  let agentDir = process.env.PI_CODING_AGENT_DIR || join(homedir(), '.pi', 'agent');
  if (agentDir === '~') agentDir = homedir();
  else if (agentDir.startsWith('~/')) agentDir = join(homedir(), agentDir.slice(2));
  const settings = readObject(join(agentDir, 'settings.json'), true);
  const profileFile = join(agentDir, 'extensions', 'subagent', 'config.json');
  const current = readObject(profileFile, true);
  const owned = readObject(process.argv[3]);
  const packages = settings.packages === undefined ? [] : settings.packages;
  if (!Array.isArray(packages)) throw new Error('Invalid Pi packages array; no packages or profile changed');
  const sources = readFileSync(process.argv[2], 'utf8').split(/\r?\n/)
    .map(line => line.trim()).filter(line => line && !line.startsWith('#'));

  // Validate both writable files before invoking Pi or changing the profile.
  for (const source of new Set(sources)) {
    if (packages.some(entry => (typeof entry === 'string' ? entry : entry?.source) === source)) continue;
    execFileSync('pi', ['install', source], { stdio: 'inherit' });
  }

  const merged = { ...current, ...owned };
  if (JSON.stringify(merged) !== JSON.stringify(current)) {
    mkdirSync(dirname(profileFile), { recursive: true });
    const temporary = `${profileFile}.${process.pid}.tmp`;
    try {
      writeFileSync(temporary, `${JSON.stringify(merged, null, 2)}\n`, { mode: 0o600, flag: 'wx' });
      renameSync(temporary, profileFile);
    } finally {
      rmSync(temporary, { force: true });
    }
  }
} catch {
  console.error('pi-plugins: configuration or package registration failed; check JSON objects and Pi installation (contents withheld)');
  process.exitCode = 1;
}
NODE
