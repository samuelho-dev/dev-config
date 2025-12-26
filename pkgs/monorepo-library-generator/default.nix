{
  lib,
  symlinkJoin,
  writeShellScriptBin,
  bun,
}: let
  # Simple bunx wrappers - package is public on npm registry
  # bunx runs the default bin (mlg), use --bun flag for bun runtime
  #
  # Note: --force flag always fetches the latest version from npm registry
  # This bypasses bunx cache (~/.bun/install/cache/) and ensures up-to-date builds
  mlg = writeShellScriptBin "mlg" ''
    exec ${bun}/bin/bunx --force --bun @samuelho-dev/monorepo-library-generator@latest "$@"
  '';

  # For mlg-mcp, we need to specify the bin name explicitly
  mlg-mcp = writeShellScriptBin "mlg-mcp" ''
    exec ${bun}/bin/bunx --force --bun @samuelho-dev/monorepo-library-generator@latest/mlg-mcp "$@"
  '';
in
  symlinkJoin {
    name = "monorepo-library-generator";
    paths = [mlg mlg-mcp];

    meta = with lib; {
      description = "Effect-based monorepo library generator with Nx integration (bunx wrapper)";
      homepage = "https://github.com/samuelho-dev/monorepo-library-generator";
      license = licenses.mit;
      platforms = platforms.all;
      mainProgram = "mlg";
    };
  }
