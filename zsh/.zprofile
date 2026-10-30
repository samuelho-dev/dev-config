# Homebrew's shellenv prepends Brew paths. Reorder after it so the native
# user-owned CLIs and Home Manager tools win in both login and interactive shells.
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  for python_bin in /Library/Frameworks/Python.framework/Versions/{3.13,3.11}/bin; do
    [[ -d "$python_bin" ]] && path+=("$python_bin")
  done
fi
path=("$HOME/.local/bin" "$HOME/.nix-profile/bin" "/etc/profiles/per-user/$USER/bin" $path)
typeset -U path
export PATH NPM_CONFIG_PREFIX="$HOME/.local"
