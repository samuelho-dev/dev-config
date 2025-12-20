{pkgs}:
# Wrapper script to run GritQL using bunx
# This avoids needing to manage the binary version manually and uses the project's Bun runtime
pkgs.writeShellScriptBin "grit" ''
  exec ${pkgs.bun}/bin/bunx @getgrit/cli "$@"
''
