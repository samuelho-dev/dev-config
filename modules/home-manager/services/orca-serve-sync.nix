{config, lib, pkgs, ...}: let
  sync = pkgs.writeShellScript "orca-serve-sync" ''
    set -euo pipefail
    state="$HOME/Library/Application Support/Orca"
    port=$(${pkgs.jq}/bin/jq -er '.port | select(type == "number" and . == floor and . >= 1 and . <= 65535)' "$state/mobile-ws-fallback-port.json" 2>/dev/null) || exit 0
    pid=$(${pkgs.jq}/bin/jq -er '.pid | select(type == "number" and . == floor and . > 0)' "$state/orca-runtime.json" 2>/dev/null) || exit 0
    ${pkgs.jq}/bin/jq -e --arg endpoint "ws://0.0.0.0:$port" \
      'any(.transports[]; .kind == "websocket" and .endpoint == $endpoint)' \
      "$state/orca-runtime.json" >/dev/null 2>&1 || exit 0
    /usr/sbin/lsof -nP -a -p "$pid" -iTCP:"$port" -sTCP:LISTEN >/dev/null || exit 0

    current=$(${pkgs.tailscale}/bin/tailscale serve status --json | ${pkgs.jq}/bin/jq -r '.TCP["6768"].TCPForward // ""')
    if [ "$current" != "127.0.0.1:$port" ]; then
      ${pkgs.tailscale}/bin/tailscale serve --bg --tcp=6768 --yes "tcp://127.0.0.1:$port"
    fi
  '';
in lib.mkIf pkgs.stdenv.isDarwin {
  # The desktop Orca runtime retains its sessions but chooses a new WS port on restart.
  # Keep the existing tailnet-only Serve route pointed at that live listener.
  launchd.agents.orca-serve-sync = {
    enable = true;
    domain = "user";
    config = {
      ProgramArguments = ["${sync}"];
      EnvironmentVariables.HOME = config.home.homeDirectory;
      RunAtLoad = true;
      StartInterval = 30;
    };
  };
}
