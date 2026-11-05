{
  config,
  lib,
  pkgs,
  ...
}: let
  rexBinDir = "${config.home.homeDirectory}/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS";
  rexLoader = ''require("dev-config")'';
  legacyRexLoader = "dofile(${builtins.toJSON "${config.xdg.configHome}/rex/dev-config.lua"})";
in {
  options.dev-config.rex-worktrees.enable = lib.mkEnableOption "managed native Rex Worktrees plugin";
  options.dev-config.rex-hermes.enable = lib.mkEnableOption "Mac palette launcher for homelab Hermes";

  config = lib.mkIf (config.dev-config.enable && (config.dev-config.rex-worktrees.enable || config.dev-config.rex-hermes.enable)) {
    home.sessionPath = lib.optionals pkgs.stdenv.isDarwin [rexBinDir];

    xdg.configFile."rex/dev-config.lua".text = ''
      ${lib.optionalString config.dev-config.rex-worktrees.enable ''rex.bind("ctrl+alt+w", "worktrees_open")''}
      ${lib.optionalString config.dev-config.rex-hermes.enable ''
        rex.action{
          name = "hermes_open",
          title = "Open Hermes",
          category = "Homelab",
          run = function(ctx)
            if not ctx.client_id then error("Open Hermes requires a native client", 0) end
            -- A CLI script resolves the Mac host registry even when action requests omit servers.
            local result, run_err = rex.exec({
              "${rexBinDir}/rex", "--autostart=false", "--server", "Homelab", "--client", "Macbook", "do", "-e", [=[
            local sessions, err = rex.call("session.list")
            if err then error(err, 0) end
            local session_id
            for _, session in ipairs(sessions.sessions or {}) do
              if session.label == "AI DEV ENV" then
                if session_id then error("Multiple AI DEV ENV sessions on homelab", 0) end
                session_id = session.session_id
              end
            end
            if not session_id then error("AI DEV ENV session not found on homelab", 0) end
            local _, attach_err = rex.call("session.attach", { session_id = session_id })
            if attach_err then error(attach_err, 0) end
            local view, view_err = rex.call("session.view", { session_id = session_id })
            if view_err then error(view_err, 0) end
            local window_id
            for _, window in ipairs(view.windows or {}) do
              if window.label == "HERMES" then
                if window_id then error("Multiple HERMES windows in AI DEV ENV", 0) end
                window_id = window.window_id
              end
            end
            if not window_id then
              local window, create_err = rex.call("session.new_window", {
                session_id = session_id,
                window_label = "HERMES",
                layout = rex.layout.block{
                  flavor = "com.superlogical.terminal.shell",
                  options = {
                    shell = "none",
                    command = {
                      "/home/admin/.nix-profile/bin/kubectl", "--context", "rex-owner@homelab",
                      "-n", "hermes", "exec", "-it", "deployment/hermes", "-c", "hermes",
                      "--", "/command/s6-setuidgid", "hermes", "env",
                      "HOME=/opt/data/home", "HERMES_HOME=/opt/data",
                      "/opt/hermes/bin/hermes", "-p", "default", "--cli",
                    },
                    exit = { on_completion = false },
                  },
                },
              })
              if create_err then error(create_err, 0) end
              window_id = window.window_id
            end
            local target = { session_id = session_id, window_id = window_id }
            -- Select through homelab: these IDs do not belong to the Mac's home server.
            rex.client.queue("session.select", target)
            return target
              ]=],
            }, { timeout = 20 })
            if run_err then error(run_err, 0) end
            if not result.ok then error(result.stderr or "Homelab Hermes launch failed", 0) end
            local target, decode_err = rex.json.decode(result.stdout)
            if decode_err then error(decode_err, 0) end
            return target
          end,
        }
      ''}
    '';

    # The upstream setup owns only its own marked registration and Lua module.
    home.activation.loadRexDevConfig = lib.hm.dag.entryAfter ["linkGeneration" "bootstrapNativeTools"] ''
      init="''${REX_CONFIG:-${config.xdg.configHome}/rex/init.lua}"
      loader=${lib.escapeShellArg rexLoader}
      if [ -L "$init" ] || { [ -e "$init" ] && [ ! -f "$init" ]; }; then
        echo "Refusing to edit non-regular Rex init: $init" >&2
        exit 1
      fi
      if [ -n "''${DRY_RUN_CMD:-}" ]; then
        echo "Would register enabled Rex integrations and add dev-config loader to $init"
      else
        ${lib.optionalString config.dev-config.rex-worktrees.enable ''
        PATH="$HOME/.local/bin:${config.home.path}/bin:${lib.makeBinPath [pkgs.coreutils pkgs.bash]}:$PATH${lib.optionalString pkgs.stdenv.isDarwin ":${rexBinDir}:/opt/homebrew/bin"}:/usr/local/bin:/usr/bin:/bin" \
          REX_CONFIG="$init" "$HOME/.local/bin/rex-worktrees" setup --config "$init" --bin "$HOME/.local/bin/rex-worktrees"
      ''}
        if [ -f "$init" ]; then
          ${pkgs.gnused}/bin/sed -E -i ${lib.escapeShellArg "s|^${lib.escapeRegex legacyRexLoader}$|${rexLoader}|"} "$init"
        fi
        if ! [ -f "$init" ] || ! ${pkgs.gnugrep}/bin/grep -Fxq "$loader" "$init"; then
          mkdir -p "$(dirname "$init")"
          printf '\n%s\n' "$loader" >> "$init"
        fi
      fi
    '';
  };
}
