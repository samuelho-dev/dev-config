{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.dev-config.python;
in {
  options.dev-config.python = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Python 3 with pip and common development packages";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python3;
      description = "Python package to use";
    };

    enablePip = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include pip in Python environment";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional Python packages to install globally";
      example = lib.literalExpression "[pkgs.python3Packages.numpy pkgs.python3Packages.pandas]";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install Python with pip
    home.packages = [
      (cfg.package.withPackages (
        ps:
          [
            # Core development packages
            ps.pip
            ps.setuptools
            ps.wheel
            ps.virtualenv
            ps.pipenv

            # Common utilities
            ps.pytest
            ps.black
            ps.ruff
            ps.mypy
            ps.isort
          ]
          ++ cfg.packages
      ))
    ];

    # Create a shell hook for Python virtual environments
    programs.zsh.initContent = lib.mkIf (config.programs.zsh.enable) ''
      # Python utilities

      # Create virtual environment quickly
      pyvenv() {
        local venv_dir="''${1:-.venv}"
        ${cfg.package}/bin/python -m venv "$venv_dir"
        echo "✓ Virtual environment created at: $venv_dir"
        echo "  Activate with: source $venv_dir/bin/activate"
      }

      # Quick pip install in current environment
      pipinstall() {
        ${cfg.package}/bin/python -m pip install "$@"
      }

      # List installed packages
      piplist() {
        ${cfg.package}/bin/python -m pip list
      }
    '';
  };
}
