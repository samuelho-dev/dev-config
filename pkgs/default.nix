# Package definitions for dev-config
# Single source of truth for all development packages
# Used by both devShells and Home Manager modules
{pkgs}: {
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
    (pkgs.callPackage ./monorepo-library-generator {})
    (pkgs.callPackage ./init-workspace {})
    (pkgs.callPackage ./grit.nix {})
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
