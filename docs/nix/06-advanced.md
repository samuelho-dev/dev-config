# Advanced Customization Guide

Advanced Nix techniques for extending dev-config. Assumes you've read [01-concepts.md](01-concepts.md) and [02-daily-usage.md](02-daily-usage.md).

## Overriding Packages

Pin or customize a package with `.override` / `.overrideAttrs`:

```nix
# in a devShell or module
packages = [
  (pkgs.neovim.override {
    viAlias = true;
    vimAlias = true;
  })
];
```

### Overlays

An overlay layers custom or modified packages onto nixpkgs:

```nix
# flake.nix
overlays.default = final: prev: {
  my-dev-tool = prev.callPackage ./pkgs/my-dev-tool {};
};

# apply it
devShells.default = let
  pkgs' = import nixpkgs {
    inherit system;
    overlays = [ self.overlays.default ];
  };
in pkgs'.mkShell {
  packages = [ pkgs'.my-dev-tool ];
};
```

### Custom derivation

```nix
# pkgs/my-dev-tool/default.nix
{ pkgs, lib, stdenv, fetchFromGitHub }:
stdenv.mkDerivation rec {
  pname = "my-dev-tool";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "yourname"; repo = "my-dev-tool"; rev = "v${version}";
    sha256 = "sha256-...";
  };
  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp my-tool.sh $out/bin/my-tool
    chmod +x $out/bin/my-tool
    wrapProgram $out/bin/my-tool \
      --prefix PATH : ${lib.makeBinPath [ pkgs.jq pkgs.curl ]}
  '';
  meta = { license = lib.licenses.mit; platforms = lib.platforms.unix; };
}
```

Reference it with `pkgs.callPackage ./pkgs/my-dev-tool {}`.

## Multiple Development Shells

Define purpose-specific shells alongside `default`:

```nix
# flake.nix
devShells = forAllSystems ({ pkgs, ... }: {
  default = pkgs.mkShell {
    packages = [ pkgs.git pkgs.neovim pkgs.tmux ];
  };

  python = pkgs.mkShell {
    packages = [ pkgs.python311 pkgs.poetry pkgs.ruff ];
    shellHook = ''echo "Python: $(python --version)"'';
  };

  nodejs = pkgs.mkShell {
    packages = [ pkgs.nodejs_24 pkgs.bun ];
    shellHook = ''echo "Node: $(node --version)"'';
  };
});
```

```bash
nix develop          # default
nix develop .#python
nix develop .#nodejs
```

### Environment-specific .envrc

```bash
# .envrc.python
use flake .#python
export PYTHONPATH="$PWD/src:$PYTHONPATH"
```

Switch by symlinking:

```bash
ln -sf .envrc.python .envrc && direnv allow
```

## Advanced direnv Patterns

### Project-specific secrets (`.envrc.local`, gitignored)

```bash
# .envrc.local
export AWS_PROFILE=personal
export DATABASE_URL=postgresql://localhost/mydb
export PROJECT_API_KEY=$(op read "op://Dev/project-x/api-key")
```

Source it from `.envrc`:

```bash
use flake
if [ -f .envrc.local ]; then
  source_env .envrc.local
fi
```

### Auto-detect project type

```bash
# .envrc
if [ -f package.json ]; then
  use flake .#nodejs
elif [ -f pyproject.toml ]; then
  use flake .#python
else
  use flake
fi
export PROJECT_ROOT=$PWD
dotenv_if_exists .env
```

### Nested directory environments

```bash
# backend/.envrc
source_up          # inherit parent .envrc
use flake .#python
export BACKEND_PORT=8000
```

`source_up` lets a subdirectory inherit the repo-root environment and layer on top.

## Security Notes

Never hardcode secrets in `.nix` files. Fetch at runtime from 1Password:

```nix
shellHook = ''
  if op account get &>/dev/null 2>&1; then
    export API_KEY=$(op read "op://Dev/api/key")
  fi
'';
```

Pin and review inputs before committing:

```bash
nix flake update
git diff flake.lock
```

## Performance Tuning

```conf
# ~/.config/nix/nix.conf
max-jobs = auto       # parallel derivations
cores = 0             # all cores per build
keep-outputs = true
keep-derivations = true
```

## Resources

- Nixpkgs manual: https://nixos.org/manual/nixpkgs/stable/
- Awesome Nix: https://github.com/nix-community/awesome-nix
- [Concepts](01-concepts.md) · [Daily Usage](02-daily-usage.md) · [Troubleshooting](03-troubleshooting.md)
