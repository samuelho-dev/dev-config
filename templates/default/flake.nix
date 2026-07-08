{
  description = "Project with dev-config integration";

  # Single source of truth: dev-config carries nixpkgs + the shell recipe.
  # No project-level nixpkgs input — everything follows the hub, so there is
  # exactly one nixpkgs to update (bump dev-config).
  inputs.dev-config.url = "github:samuelho-dev/dev-config";

  outputs = {dev-config, ...}: {
    devShells = dev-config.lib.forEachSystem ({pkgs, ...}: {
      default = dev-config.lib.mkDevShell {
        inherit pkgs;
        # Project-specific tools only (e.g. [pkgs.ffmpeg pkgs.postgresql]):
        packages = [];
        # Project-specific shell setup:
        extraHook = ''echo "🚀 Development environment ready"'';
      };
    });

    formatter = dev-config.lib.forEachSystem ({pkgs, ...}: pkgs.alejandra);
  };
}
