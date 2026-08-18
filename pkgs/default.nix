# Package definitions for dev-config
# Single source of truth for all development packages
# Used by both devShells and Home Manager modules
{pkgs}: let
  vercelVersion = "57.0.0";
  vercelPlatform =
    {
      "aarch64-darwin" = {
        npmArch = "darwin-arm64";
        hash = "sha512-1yXaFv7H5/b/VhphpiXrfGezkDAsA/NKUR1iujx2k43WP+Il+HiLvcFI1ONkogjtkYfZt6JWlhjIXgcXduSqaA==";
      };
      "x86_64-darwin" = {
        npmArch = "darwin-x64";
        hash = "sha512-jhvTu/LcEjECbBpsk62+g8H99YnB8iLNw8MTwBizDPUZdSIqbH1PmjF8JztfbB7Ke+pBTC1zSwmpsLq76zQ/9g==";
      };
      "aarch64-linux" = {
        npmArch = "linux-arm64";
        hash = "sha512-qw5m+B6ev9sZpmRGdZDLSnvo27XdS2oWHKEDfbof5oxTWEK6/uHYd26eDX94d1GFTrMsFtuzKuNjFPBy5QOUcQ==";
      };
      "x86_64-linux" = {
        npmArch = "linux-x64";
        hash = "sha512-72JG1hqCs/jub3oofI6bIaqGox7P6qurj8XCvRyLCeXdiyNxwzGoo80e2jZ4FWjl9sbvG8EhGJ1oW1BObMpFtA==";
      };
    }.${
      pkgs.stdenv.hostPlatform.system
    };
  vercel-cli = pkgs.stdenvNoCC.mkDerivation {
    pname = "vercel-cli";
    version = vercelVersion;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@vercel/vc-native-${vercelPlatform.npmArch}/-/vc-native-${vercelPlatform.npmArch}-${vercelVersion}.tgz";
      inherit (vercelPlatform) hash;
    };
    sourceRoot = "package";
    installPhase = ''
      runHook preInstall
      install -Dm755 bin/vercel "$out/bin/vercel"
      ln -s vercel "$out/bin/vc"
      runHook postInstall
    '';
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

  # Development utilities
  utilities = [
    pkgs.direnv
    pkgs.nix-direnv
    pkgs.jq
    pkgs.yq-go
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.tree-sitter # CLI to compile parsers (required by nvim-treesitter main branch)
  ];

  # Linting and formatting tools (repo-wide: devShell, pre-commit, biome.json)
  # Note: editor LSPs (nixd, pyright, ...) live in modules/home-manager/programs/neovim.nix
  linting = [
    pkgs.biome # Fast formatter and linter for JS/TS/JSON/CSS
  ];

  # JavaScript/TypeScript runtimes + package managers
  # On PATH for every dev surface (devShell + Home Manager + DevPod image).
  runtimes = [
    pkgs.nodejs_26 # Node.js 26 (latest stable) - also provides npm + corepack
    pkgs.pnpm # repo pins packageManager: pnpm@10.x
    pkgs.bun
  ];

  # Cloud / infrastructure-as-code CLIs
  cloud = [
    pkgs.docker-client
    pkgs.terraform # IaC (unfree BSL; allowUnfree set in flake.nix)
    pkgs._1password-cli
    pkgs.stripe-cli
    vercel-cli
    pkgs.awscli2 # AWS CLI v2
    pkgs.cloudflared # Cloudflare Tunnel daemon
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.k9s
    pkgs.argocd
    pkgs.talosctl
    pkgs.doctl
    pkgs.hcloud
    pkgs.kubeseal
    pkgs.kubeconform
    pkgs.kustomize
    pkgs.sops
    pkgs.age
    pkgs.cilium-cli
  ];

  # Combine all packages into a single list
  all = self:
    self.core
    ++ self.utilities
    ++ self.linting
    ++ self.runtimes
    ++ self.cloud;
}
