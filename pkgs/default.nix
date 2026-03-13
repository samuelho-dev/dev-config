# Package definitions for dev-config
# Single source of truth for all development packages
# Used by both devShells and Home Manager modules
{pkgs}: let
  # GritQL CLI - Structural code search and rewriting
  # Pre-built binary from biomejs/gritql releases
  # Wrapped with XDG directory support to avoid Nix store permission issues
  grit = let
    version = "0.1.0-alpha.1743007075";
    sources = {
      "aarch64-darwin" = {
        url = "https://github.com/biomejs/gritql/releases/download/v${version}/grit-aarch64-apple-darwin.tar.gz";
        sha256 = "sha256-erjH7qkHma41yG8qm35I5WuRpi5qRZuRDd4aPaoGa/M=";
      };
      "x86_64-darwin" = {
        url = "https://github.com/biomejs/gritql/releases/download/v${version}/grit-x86_64-apple-darwin.tar.gz";
        sha256 = "03h1aav549n53x17k9xzqw0sqnhsad9sybr8jghmhaz7rwqz00mm";
      };
      "x86_64-linux" = {
        url = "https://github.com/biomejs/gritql/releases/download/v${version}/grit-x86_64-unknown-linux-gnu.tar.gz";
        sha256 = "0j9i2r63s7bqdiax15n9cgbcczq7jjng19ram62hxjiqlm0ldcwl";
      };
      "aarch64-linux" = {
        url = "https://github.com/biomejs/gritql/releases/download/v${version}/grit-aarch64-unknown-linux-gnu.tar.gz";
        sha256 = "0w28jg8ffz1fccvjqnf7lxhh5y3qk8klv3q1dlw1cmsr8mf42dwf";
      };
    };
    platformKey = pkgs.stdenvNoCC.hostPlatform.system;
    src = sources.${platformKey} or (throw "Unsupported platform: ${platformKey}");
  in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "grit";
      inherit version;
      src = pkgs.fetchurl {
        inherit (src) url sha256;
      };
      sourceRoot = ".";
      nativeBuildInputs =
        [pkgs.makeWrapper]
        ++ pkgs.lib.optionals pkgs.stdenvNoCC.isLinux [pkgs.autoPatchelfHook];
      buildInputs = pkgs.lib.optionals pkgs.stdenvNoCC.isLinux [
        pkgs.stdenv.cc.cc.lib # libstdc++.so.6
        pkgs.zlib # libz.so.1
      ];
      installPhase = ''
        runHook preInstall

        # Install unwrapped binary
        mkdir -p $out/bin
        find . -name 'grit' -type f -exec cp {} $out/bin/.grit-unwrapped \;
        chmod +x $out/bin/.grit-unwrapped

        # Wrap with XDG directory support to prevent Nix store writes
        # Only sets cache/data directories - user config handled by Home Manager
        # Environment variables:
        #   GRIT_GLOBAL_DIR - Global modules and stdlib cache (~/.local/share/grit)
        # Note: GRIT_USER_CONFIG intentionally NOT set - grit uses default ~/.grit
        #       which Home Manager populates with patterns
        makeWrapper $out/bin/.grit-unwrapped $out/bin/grit \
          --run 'export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"' \
          --run 'export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"' \
          --run 'export GRIT_GLOBAL_DIR="''${GRIT_GLOBAL_DIR:-$XDG_DATA_HOME/grit}"' \
          --run 'mkdir -p "$GRIT_GLOBAL_DIR" "$XDG_CACHE_HOME/grit"'

        runHook postInstall
      '';
      meta = {
        description = "GritQL - Structural code search, linting, and rewriting";
        homepage = "https://docs.grit.io";
        license = pkgs.lib.licenses.mit;
        platforms = pkgs.lib.platforms.darwin ++ pkgs.lib.platforms.linux;
        mainProgram = "grit";
      };
    };
in {
  # Core development tools
  core = [
    pkgs.git
    pkgs.gh
    pkgs.zsh
    pkgs.tmux
    pkgs.fzf
    pkgs.ripgrep
    pkgs.fd
    pkgs.bat
    pkgs.lazygit
  ];

  # Programming language runtimes
  runtimes = [
    pkgs.nodejs_20
    pkgs.bun
  ];

  # Development utilities
  utilities = [
    pkgs.direnv
    pkgs.nix-direnv
    pkgs.jq
    pkgs.yq-go
    pkgs.gnumake
    pkgs.pkg-config
    grit
  ];

  # Linting and formatting tools
  linting = [
    pkgs.biome # Fast formatter and linter for JS/TS/JSON/CSS
  ];

  # Combine all packages into a single list
  all = self:
    self.core
    ++ self.runtimes
    ++ self.utilities
    ++ self.linting;
}
