# Package definitions for dev-config
# Single source of truth for all development packages
# Used by both devShells and Home Manager modules
{pkgs}: {
  # Core development tools
  core = [
    pkgs.git
    pkgs.gh
    pkgs.openssh # Shared SSH client, including non-login headless profiles.
    pkgs.zsh
    pkgs.tmux
    pkgs.fzf
    pkgs.ripgrep
    pkgs.fd
    pkgs.bat
    pkgs.lazygit
    pkgs.gitmux # tmux pane Git status
  ];

  # Development utilities
  utilities = [
    pkgs.direnv
    pkgs.nix-direnv
    pkgs.zoxide # Yazi directory-jump keybinding
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
    pkgs.nodejs # Node.js also supplies npm and npx (not Corepack).
    pkgs.pnpm # Flake-locked shared CLI; projects declare their own packageManager.
    pkgs.bun
  ];

  # Cloud / infrastructure-as-code CLIs
  cloud = [
    pkgs.docker-client
    pkgs.terraform # IaC (unfree BSL; allowUnfree set in flake.nix)
    pkgs._1password-cli
    pkgs.stripe-cli
    pkgs.awscli2 # AWS CLI v2
    pkgs.cloudflared # Cloudflare Tunnel daemon
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.k9s
    pkgs.argocd
    pkgs.supabase-cli
    pkgs.postgresql
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
