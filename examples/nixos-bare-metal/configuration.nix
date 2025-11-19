{ config, pkgs, lib, inputs, ... }:

{
  # System settings
  system.stateVersion = "24.05";

  # Hostname
  networking.hostName = "dev-server";

  # Boot loader (example for UEFI systems)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "America/Los_Angeles";

  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # ===================================
  # dev-config Configuration
  # ===================================

  # Configure users with dev-config
  dev-config.users = {
    # Developer account
    developer = {
      enable = true;
      extraGroups = [ "docker" "wheel" ];  # Docker access + sudo
    };

    # CI/CD service account
    ci-runner = {
      enable = true;
      isSystemUser = true;  # System account
      extraGroups = [ "docker" ];  # Docker access only
    };
  };

  # Additional dev-config options (all optional, these are defaults)
  dev-config = {
    # Enable/disable components
    packages.enable = true;  # Base developer packages
    docker.enable = true;    # Docker virtualization
    shell.enable = true;     # Zsh shell configuration

    # Add extra packages beyond defaults
    packages.extraPackages = with pkgs; [
      # Infrastructure tools (example)
      kubectl
      kubernetes-helm
      k9s
    ];
  };

  # ===================================
  # Home Manager Configuration
  # ===================================

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    # Developer user configuration
    users.developer = { pkgs, ... }: {
      # Import dev-config Home Manager module
      imports = [ inputs.dev-config.homeManagerModules.default ];

      home.stateVersion = "24.05";

      # Required: Git user configuration
      dev-config.git = {
        userName = "Developer";
        userEmail = "developer@example.com";
      };

      # Optional: Customize dev-config settings
      # dev-config.neovim.configSource = ./custom-nvim;
      # dev-config.tmux.prefix = "C-b";
      # dev-config.zsh.zshrcSource = null;  # Manage with Chezmoi
    };

    # CI runner user configuration (minimal)
    users.ci-runner = { pkgs, ... }: {
      imports = [ inputs.dev-config.homeManagerModules.default ];

      home.stateVersion = "24.05";

      # Minimal config for CI
      dev-config = {
        packages.enable = false;  # No user packages
        neovim.enable = false;
        tmux.enable = false;
        zsh.enable = false;
        direnv.enable = false;

        # Only git config
        git = {
          userName = "CI Runner";
          userEmail = "ci@example.com";
        };
      };
    };
  };

  # ===================================
  # Standard NixOS Configuration
  # ===================================

  # SSH keys for developer account
  users.users.developer = {
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      # "ssh-ed25519 AAAA..."
    ];
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Enable flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };
}
