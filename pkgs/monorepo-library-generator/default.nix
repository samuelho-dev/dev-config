{
  lib,
  symlinkJoin,
  writeShellScriptBin,
  bun,
}: let
  # Package is public on npm registry
  pkg = "@samuelho-dev/monorepo-library-generator@latest";

  # Use bun x with -p flag when binary name differs from package name
  # --bun forces bun runtime instead of node
  mlg = writeShellScriptBin "mlg" ''
    exec ${bun}/bin/bun x --bun -p ${pkg} mlg "$@"
  '';

  mlg-mcp = writeShellScriptBin "mlg-mcp" ''
    exec ${bun}/bin/bun x --bun -p ${pkg} mlg-mcp "$@"
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
