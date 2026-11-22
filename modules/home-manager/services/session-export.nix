{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.session-export;
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJVpPEazbmhLaIBygg5JpkT1eBwsskkS7FKZ80Gmxmh";
  marker = "dev-config-session-export";
  empty = pkgs.runCommand "empty-session-export" {} "mkdir -p $out";
  server = pkgs.writeShellScript "session-export" ''
    set -eu
    [ "''${SSH_ORIGINAL_COMMAND-}" = 'rsync --server --daemon .' ] || exit 1
    tmp="$(${pkgs.coreutils}/bin/mktemp -d)"
    trap '${pkgs.coreutils}/bin/rm -rf "$tmp"' EXIT
    home="$(${pkgs.coreutils}/bin/realpath ${lib.escapeShellArg config.home.homeDirectory})"
    config="$tmp/rsyncd.conf"
    printf 'use chroot = no\nread only = yes\nlist = no\nmunge symlinks = yes\nrefuse options = links copy-links copy-unsafe-links copy-dirlinks\n' > "$config"
    module() {
      name="$1" root="$home/$2"
      if [ -d "$root" ]; then
        [ "$(${pkgs.coreutils}/bin/realpath "$root")" = "$root" ] || exit 1
      else
        root=${empty}
      fi
      printf '[%s]\npath = %s\nfilter = + */ + *.jsonl - *\n' "$name" "$root" >> "$config"
    }
    module claude-projects .claude/projects
    module claude-sessions .claude/sessions
    module codex-sessions .codex/sessions
    module codex-archived .codex/archived_sessions
    module omp .omp/agent/sessions
    module pi .pi/agent/sessions
    ${pkgs.rsync}/bin/rsync --server --daemon --config="$config" .
  '';
in {
  options.dev-config.session-export.enable = lib.mkEnableOption "read-only native session export to the homelab";

  config = {
    home.activation.sessionExport = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.python3}/bin/python3 - ${lib.escapeShellArg config.home.homeDirectory} ${lib.escapeShellArg marker} ${lib.escapeShellArg key} ${lib.escapeShellArg "restrict,command=\"${server}\" ${key} ${marker}"} ${if cfg.enable then "1" else "0"} <<'PY'
import os, stat, sys, tempfile
home, marker, key, entry, enabled = sys.argv[1:]
ssh = os.path.join(home, '.ssh')
path = os.path.join(ssh, 'authorized_keys')
if enabled != '1' and (not os.path.isfile(path) or os.path.islink(path)):
    sys.exit(0)
if not os.path.exists(ssh):
    if enabled != '1':
        sys.exit(0)
    os.mkdir(ssh, 0o700)
if os.path.islink(path):
    raise SystemExit('refusing symlinked authorized_keys')
try:
    with open(path, 'rb') as f:
        original = f.read()
    mode = stat.S_IMODE(os.stat(path).st_mode)
except FileNotFoundError:
    original, mode = b"", 0o600
lines = original.splitlines(keepends=True)
owned = marker.encode()
kept = [line for line in lines if not line.rstrip(b'\r\n').endswith(b' ' + owned)]
if enabled == '1':
    parts = key.encode().split()
    if any(parts[0] in line.split() and parts[1] in line.split() for line in kept):
        raise SystemExit('session export key already exists outside managed entry')
    if kept and not kept[-1].endswith(b'\n'):
        kept[-1] += b'\n'
    kept.append(entry.encode() + b'\n')
updated = b"".join(kept)
if updated != original:
    fd, tmp = tempfile.mkstemp(prefix='.authorized_keys.', dir=ssh)
    try:
        os.fchmod(fd, mode)
        with os.fdopen(fd, 'wb') as f:
            f.write(updated)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)
PY
    '';
  };
}
