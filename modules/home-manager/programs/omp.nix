{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dev-config.omp;
in {
  options.dev-config.omp = {
    enable = lib.mkEnableOption "Oh My Pi (omp) coding-agent CLI";

    package = lib.mkOption {
      type = lib.types.str;
      default = "@oh-my-pi/pi-coding-agent";
      description = "npm package for the omp CLI (bin: omp).";
    };

    mattSkills = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Vendor mattpocock/skills into ~/.agents/skills + ~/.claude/skills (cloned, git-pulled, symlinked on activation).";
    };

    obsidian = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install pi-obsidian and publish a headless Obsidian vault config for OMP.";
      };

      package = lib.mkOption {
        type = lib.types.str;
        default = "pi-obsidian";
        description = "npm package that provides the OMP-compatible Obsidian extension.";
      };

      vaultPath = lib.mkOption {
        type = lib.types.str;
        default = "$HOME/Obsidian/Main";
        description = "Filesystem path exposed to pi-obsidian as the default vault.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # omp is not in nixpkgs and pulls native postinstalls (onnxruntime-node,
    # protobufjs), so it can't be a declarative nix package like claude-code.
    # Install it globally via bun when bun is available outside Nix (real-nix
    # machines run HM activation). In the devpod/orca images — where HM
    # activation does NOT run — the container entrypoint performs the same
    # `bun add -g` on boot. Both paths need bun >= 1.3.14 (see pkgs/default.nix).
    home.activation.installOmpCli = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      if command -v bun &>/dev/null; then
        if ! command -v omp &>/dev/null || ! omp --version &>/dev/null 2>&1; then
          $DRY_RUN_CMD bun add -g ${cfg.package} 2>/dev/null || true
        fi
      fi
    '';

    home.activation.configureOmp = lib.hm.dag.entryAfter ["writeBoundary" "installOmpCli"] ''
      if command -v omp &>/dev/null; then
        $DRY_RUN_CMD omp config set memory.backend hindsight >/dev/null 2>&1 || true
        $DRY_RUN_CMD omp config set autolearn.enabled true >/dev/null 2>&1 || true
        if [ -n "''${HINDSIGHT_API_URL:-}" ]; then
          $DRY_RUN_CMD omp config set hindsight.apiUrl "''${HINDSIGHT_API_URL}" >/dev/null 2>&1 || true
        fi
      fi
    '';

    home.activation.installPiObsidian = lib.mkIf cfg.obsidian.enable (
      lib.hm.dag.entryAfter ["writeBoundary" "installOmpCli"] ''
        if command -v bun &>/dev/null; then
          $DRY_RUN_CMD bun add -g ${cfg.obsidian.package} 2>/dev/null || true
        fi

        VAULT_PATH="${cfg.obsidian.vaultPath}"
        $DRY_RUN_CMD mkdir -p "$HOME/.config/obsidian" "$VAULT_PATH"
        if [ -z "''${DRY_RUN_CMD:-}" ]; then
          printf '{"vaults":{"main":{"path":"%s","ts":0,"open":true}}}\n' "$VAULT_PATH" > "$HOME/.config/obsidian/obsidian.json"
        fi
      ''
    );

    # mattpocock/skills lives in the skill roots omp discovers (~/.agents/skills
    # native, ~/.claude/skills), alongside the dev-config Effect/Nx skills.
    # Skill names are unique across sources and never collide.
    home.activation.vendorMattSkills = lib.mkIf cfg.mattSkills (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        REPO="$HOME/.local/share/mattpocock-skills"
        if [ ! -d "$REPO/.git" ]; then
          $DRY_RUN_CMD ${pkgs.git}/bin/git clone --depth 1 https://github.com/mattpocock/skills "$REPO" 2>/dev/null || true
        else
          $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$REPO" pull --ff-only 2>/dev/null || true
        fi
        if [ -d "$REPO/skills" ]; then
          for DEST in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
            $DRY_RUN_CMD mkdir -p "$DEST"
            for SRC in "$REPO"/skills/*/*/; do
              [ -f "''${SRC}SKILL.md" ] || continue
              case "$SRC" in *"/deprecated/"*|*"/node_modules/"*) continue ;; esac
              NAME="$(basename "''${SRC%/}")"
              $DRY_RUN_CMD ln -sfn "''${SRC%/}" "$DEST/$NAME"
            done
          done
        fi
      ''
    );
  };
}
