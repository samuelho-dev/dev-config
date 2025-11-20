{
  description = "Example NixOS configuration with dev-config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Import dev-config
    dev-config = {
      url = "github:samuelho-dev/dev-config";
      # For local testing:
      # url = "path:../../";
    };

    # Home Manager for user-level configs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    dev-config,
    home-manager,
    ...
  }: {
    nixosConfigurations = {
      # Example server configuration
      dev-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import dev-config NixOS module
          dev-config.nixosModules.default

          # Home Manager NixOS module
          home-manager.nixosModules.home-manager

          # Main configuration
          ./configuration.nix
        ];
      };
    };
  };
}
