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
      description = "Enable Python 3 runtime with pip";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "python313";
      description = "Python version to use (python311, python312, python313, etc.)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install Python with pip using withPackages pattern
    # This creates a proper environment where 'python' and 'pip' both work
    home.packages = [
      (pkgs.${cfg.version}.withPackages (ps: [
        ps.pip
        ps.setuptools
      ]))
    ];

    # Shell utilities for Python development
    programs.zsh.initContent = lib.mkIf (config.programs.zsh.enable) ''
      # Python development utilities

      # Create and activate virtual environment
      pyvenv() {
        local venv_dir="''${1:-.venv}"
        python -m venv "$venv_dir"
        echo "✓ Virtual environment created at: $venv_dir"
        echo "  Activate with: source $venv_dir/bin/activate"
      }

      # Quick pip install
      pipinstall() {
        python -m pip install "$@"
      }

      # List installed packages
      piplist() {
        python -m pip list
      }
    '';
  };
}
