{
  lib,
  symlinkJoin,
  writeShellScriptBin,
  bun,
}: let
  # Simple bunx wrappers - package is public on npm registry
  # bunx runs the default bin (mlg), use --bun flag for bun runtime
  #
  # Note: bunx caches packages in ~/.bun/install/cache/
  # To force update: mlg-update (clears cache and fetches latest)
  mlg = writeShellScriptBin "mlg" ''
    exec ${bun}/bin/bunx --bun @samuelho-dev/monorepo-library-generator@latest "$@"
  '';

  # For mlg-mcp, we need to specify the bin name explicitly
  mlg-mcp = writeShellScriptBin "mlg-mcp" ''
    exec ${bun}/bin/bunx --bun @samuelho-dev/monorepo-library-generator@latest/mlg-mcp "$@"
  '';

  # Update command - clears bun cache for this package and fetches latest
  mlg-update = writeShellScriptBin "mlg-update" ''
    echo "Clearing bun cache for monorepo-library-generator..."
    rm -rf ~/.bun/install/cache/@samuelho-dev+monorepo-library-generator* 2>/dev/null || true
    rm -rf ~/.bun/install/cache/@samuelho-dev/monorepo-library-generator* 2>/dev/null || true
    echo "Fetching latest version..."
    ${bun}/bin/bunx --bun @samuelho-dev/monorepo-library-generator@latest --version
    echo "Updated!"
  '';
in
  symlinkJoin {
    name = "monorepo-library-generator";
    paths = [mlg mlg-mcp mlg-update];

    meta = with lib; {
      description = "Effect-based monorepo library generator with Nx integration (bunx wrapper)";
      homepage = "https://github.com/samuelho-dev/monorepo-library-generator";
      license = licenses.mit;
      platforms = platforms.all;
      mainProgram = "mlg";
    };
  }
