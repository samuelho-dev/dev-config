_: {
  imports = [./modules/home-manager ./modules/home-manager/profiles/base.nix];

  # Headless Rex workload UID is deployment-owned.
  home = {
    username = "admin";
    homeDirectory = "/home/admin";
    stateVersion = "24.05";
  };

  dev-config = {
    enable = true;

    neovim.enable = true;
    git = {
      enable = true;
      userName = "samuelho-dev";
      userEmail = "samuelho343@gmail.com";
      signing.enable = false; # No 1Password SSH agent in Rex
      preferSSH = false; # Headless GitHub access uses the projected token.
      extraConfig.credential."https://github.com".helper = "!gh auth git-credential";
      extraConfig.url."https://github.com/".insteadOf = ["git@github.com:" "ssh://git@github.com/"];
    };
    zsh = {
      enable = true;
      # base.nix nulls the p10k source; opt back in to the repo-managed
      # Nerd Font theme (Rex terminals render built-in Nerd Font glyphs).
      p10kSource = ./zsh/.p10k.zsh;
    };
    mcp = {
      enable = true;
      targets.claude = true;
    };
    biome.enable = true;
    npm.enable = true;
    yazi.enable = true;
    omp.enable = true;
    omp.hindsight.enable = true;
    pi.enable = true;
    claude-code.enable = true;
    opencode.enable = true;
    codex.enable = true;
    vercel.enable = true;
    rex-worktrees.enable = true;

    ghostty.enable = false;
    ssh.enable = false; # No 1Password agent in Rex
    tmux.enable = true;
    sops-env.enable = false; # No local sops/1Password in Rex
  };

  programs.home-manager.enable = true;
}
