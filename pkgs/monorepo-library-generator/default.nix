{
  lib,
  symlinkJoin,
  writeShellScriptBin,
  nodejs_20,
}: let
  mlg = writeShellScriptBin "mlg" ''
    # Create temporary .npmrc to override scope registry
    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT
    echo "@samuelho-dev:registry=https://registry.npmjs.org/" > "$TMPDIR/.npmrc"
    export npm_config_userconfig="$TMPDIR/.npmrc"
    exec ${nodejs_20}/bin/npx --yes -p @samuelho-dev/monorepo-library-generator@1.5.0 mlg "$@"
  '';

  mlg-mcp = writeShellScriptBin "mlg-mcp" ''
    # Create temporary .npmrc to override scope registry
    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT
    echo "@samuelho-dev:registry=https://registry.npmjs.org/" > "$TMPDIR/.npmrc"
    export npm_config_userconfig="$TMPDIR/.npmrc"
    exec ${nodejs_20}/bin/npx --yes -p @samuelho-dev/monorepo-library-generator@1.5.0 mlg-mcp "$@"
  '';
in
  symlinkJoin {
    name = "monorepo-library-generator-1.5.0";
    paths = [mlg mlg-mcp];

    meta = with lib; {
      description = "Effect-based monorepo library generator with Nx integration (npx wrapper)";
      homepage = "https://github.com/samuelho-dev/monorepo-library-generator";
      license = licenses.mit;
      platforms = platforms.all;
      mainProgram = "mlg";
    };
  }
