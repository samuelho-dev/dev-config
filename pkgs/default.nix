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
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Get actual hash
      };
      "x86_64-linux" = {
        url = "https://github.com/biomejs/gritql/releases/download/v${version}/grit-x86_64-unknown-linux-gnu.tar.gz";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Get actual hash
      };
      "aarch64-linux" = {
        url = "https://github.com/biomejs/gritql/releases/download/v${version}/grit-aarch64-unknown-linux-gnu.tar.gz";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Get actual hash
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
    pkgs.zsh
    pkgs.tmux
    pkgs.docker
    pkgs.fzf
    pkgs.ripgrep
    pkgs.fd
    pkgs.bat
    pkgs.lazygit
    pkgs.gitmux
  ];

  # Programming language runtimes
  runtimes = [
    pkgs.nodejs_20
    pkgs.bun
    pkgs.python3
  ];

  # Kubernetes ecosystem tools
  kubernetes = [
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.helm-docs
    pkgs.k9s
    pkgs.kind
    pkgs.argocd
    pkgs.cilium-cli # Cilium CNI CLI for cluster networking status/diagnostics
  ];

  # Cloud provider CLIs
  cloud = [
    pkgs.awscli2
    pkgs.doctl
    pkgs.hcloud
  ];

  # Infrastructure as Code tools
  iac = [
    pkgs.terraform
    pkgs.terraform-docs
  ];

  # Security and compliance tools
  security = [
    pkgs.gitleaks
    pkgs.kubeseal
    pkgs.sops
  ];

  # Data processing tools
  data = [
    pkgs.jq
    pkgs.yq-go
  ];

  # CI/CD and Git tools
  cicd = [
    pkgs.gh
    pkgs.act
    pkgs.pre-commit
    pkgs.cachix
  ];

  # Development utilities
  utilities = [
    pkgs.direnv
    pkgs.nix-direnv
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.imagemagick
    pkgs._1password-cli
    (pkgs.callPackage ./init-workspace {})
    (pkgs.callPackage ./monorepo-library-generator {})
    grit
  ];

  # Linting and formatting tools
  linting = [
    pkgs.biome # Fast formatter and linter for JS/TS/JSON/CSS
    pkgs.hadolint # Dockerfile linting
    pkgs.kube-linter # Kubernetes manifest linting
    pkgs.tflint # Terraform linting
    pkgs.actionlint # GitHub Actions linting
    pkgs.yamllint # YAML linting
    pkgs.shellcheck # Shell script linting
  ];

  # Combine all packages into a single list
  all = self:
    self.core
    ++ self.runtimes
    ++ self.kubernetes
    ++ self.cloud
    ++ self.iac
    ++ self.security
    ++ self.data
    ++ self.cicd
    ++ self.utilities
    ++ self.linting;
}
