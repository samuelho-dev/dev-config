{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.isDarwin {
  xdg.configFile."rex/dev-config.lua".text = ''
    rex.bind("ctrl+alt+w", "worktrees_open")
  '';

  # Rex's init.lua also belongs to npm-installed plugins; only add our loader.
  home.activation.loadRexDevConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    init="''${REX_CONFIG:-${config.xdg.configHome}/rex/init.lua}"
    loader=${lib.escapeShellArg "dofile(${builtins.toJSON "${config.xdg.configHome}/rex/dev-config.lua"})"}
    if [ -L "$init" ] || { [ -e "$init" ] && [ ! -f "$init" ]; }; then
      echo "Refusing to edit non-regular Rex init: $init" >&2
      exit 1
    fi
    if [ -f "$init" ] && ${pkgs.gnugrep}/bin/grep -Fxq "$loader" "$init"; then
      :
    elif [ -n "''${DRY_RUN_CMD:-}" ]; then
      echo "Would add Rex dev-config loader to $init"
    else
      mkdir -p "$(dirname "$init")"
      printf '\n%s\n' "$loader" >> "$init"
    fi
  '';
}
