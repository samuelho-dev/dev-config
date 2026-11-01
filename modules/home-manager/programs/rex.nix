{
  config,
  lib,
  pkgs,
  ...
}: let
  rexBinDir = "${config.home.homeDirectory}/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS";
in {
  options.dev-config.rex-worktrees.enable = lib.mkEnableOption "managed native Rex Worktrees plugin";

  config = lib.mkIf (config.dev-config.enable && config.dev-config.rex-worktrees.enable) {
    home.sessionPath = lib.optionals pkgs.stdenv.isDarwin [rexBinDir];

    xdg.configFile."rex/dev-config.lua".text = ''
      rex.bind("ctrl+alt+w", "worktrees_open")
    '';

    # The upstream setup owns only its own marked registration and Lua module.
    home.activation.loadRexDevConfig = lib.hm.dag.entryAfter ["linkGeneration" "bootstrapNativeTools"] ''
      init="''${REX_CONFIG:-${config.xdg.configHome}/rex/init.lua}"
      loader=${lib.escapeShellArg "dofile(${builtins.toJSON "${config.xdg.configHome}/rex/dev-config.lua"})"}
      if [ -L "$init" ] || { [ -e "$init" ] && [ ! -f "$init" ]; }; then
        echo "Refusing to edit non-regular Rex init: $init" >&2
        exit 1
      fi
      if [ -n "''${DRY_RUN_CMD:-}" ]; then
        echo "Would register Rex Worktrees and add dev-config loader to $init"
      else
        PATH="$HOME/.local/bin:${config.home.path}/bin:${lib.makeBinPath [pkgs.coreutils pkgs.bash]}:$PATH${lib.optionalString pkgs.stdenv.isDarwin ":${rexBinDir}:/opt/homebrew/bin"}:/usr/local/bin:/usr/bin:/bin" \
          REX_CONFIG="$init" "$HOME/.local/bin/rex-worktrees" setup --config "$init" --bin "$HOME/.local/bin/rex-worktrees"
        if ! [ -f "$init" ] || ! ${pkgs.gnugrep}/bin/grep -Fxq "$loader" "$init"; then
          mkdir -p "$(dirname "$init")"
          printf '\n%s\n' "$loader" >> "$init"
        fi
      fi
    '';
  };
}
