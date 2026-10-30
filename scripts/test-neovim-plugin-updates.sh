#!/usr/bin/env bash
# Real Lazy.nvim + local Git remotes; never writes to the user's Neovim data.
set -euo pipefail
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
lazy_source=${1:-${LAZY_NVIM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim}}
[[ -f "$lazy_source/lua/lazy/init.lua" ]] || { echo "Pass the installed Lazy.nvim directory as LAZY_NVIM_DIR or argument" >&2; exit 1; }
command -v nvim >/dev/null
command -v git >/dev/null
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" XDG_STATE_HOME="$tmp/state" XDG_CACHE_HOME="$tmp/cache"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$tmp/gitconfig" GIT_ALLOW_PROTOCOL=file
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME/nvim/lazy/lazy.nvim" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
cp -R "$lazy_source/." "$XDG_DATA_HOME/nvim/lazy/lazy.nvim/"
lazy_copy="$XDG_DATA_HOME/nvim/lazy/lazy.nvim"
rm -rf -- "$lazy_copy/.git"
git init -q -b stable "$lazy_copy"
git -C "$lazy_copy" config user.name 'Neovim update fixture'
git -C "$lazy_copy" config user.email 'fixture@example.invalid'
git -C "$lazy_copy" add .
git -C "$lazy_copy" commit -qm 'Local Lazy.nvim fixture'
git clone -q --bare "$lazy_copy" "$tmp/lazy-remote.git"
git -C "$lazy_copy" remote add origin 'https://github.com/folke/lazy.nvim.git'
git config --global "url.file://$tmp/lazy-remote.git.insteadOf" 'https://github.com/folke/lazy.nvim.git'
export ROOT_REMOTE="file://$tmp/root" DEP_REMOTE="file://$tmp/dependency"
git init -q -b allowed "$tmp/root"
git init -q -b stable "$tmp/dependency"
for repo in root dependency; do
  git -C "$tmp/$repo" config user.name 'Neovim update fixture'
  git -C "$tmp/$repo" config user.email 'fixture@example.invalid'
  mkdir -p "$tmp/$repo/lua"
done
commit_plugin() {
  local repo=$1 revision=$2
  printf 'return { revision = "%s" }\n' "$revision" > "$tmp/$repo/lua/$repo.lua"
  git -C "$tmp/$repo" add .
  git -C "$tmp/$repo" commit -qm "$revision"
}
commit_plugin root A
commit_plugin dependency v1.0
git -C "$tmp/dependency" tag v1.0
export RUNTIME_MARKER="$tmp/runtime-callbacks"
cat > "$tmp/fixtures.lua" <<'LUA'
local function runtime_callback()
  vim.fn.writefile({ 'ran' }, vim.env.RUNTIME_MARKER, 'a')
  error('fixture runtime callback ran')
end
local dep = {
  url = vim.env.DEP_REMOTE,
  name = 'dependency',
  version = 'v1.*',
  cond = function() return false end,
  init = runtime_callback,
  config = runtime_callback,
  opts = runtime_callback,
}
package.preload['plugins.editor'] = function()
  return {
    { 'folke/lazy.nvim', branch = 'stable' },
    {
      url = vim.env.ROOT_REMOTE,
      name = 'root',
      branch = 'allowed',
      cond = function() return false end,
      dependencies = { dep },
      init = runtime_callback,
      config = runtime_callback,
      opts = runtime_callback,
      build = [[sh -c 'if [ "$FAIL_BUILD" = 1 ]; then exit 1; fi']],
    },
  }
end
for _, category in ipairs({ 'lsp', 'completion', 'ai', 'git', 'markdown', 'ui', 'treesitter', 'tools', 'training' }) do
  package.preload['plugins.' .. category] = function() return {} end
end
LUA
update() {
  nvim --headless -i NONE \
    --cmd "set rtp^=$root/nvim" \
    --cmd "luafile $tmp/fixtures.lua" \
    --cmd 'let g:dev_config_plugin_update=v:true' \
    -u "$root/nvim/init.lua" \
    -c "luafile $root/nvim/update-plugins.lua"
}
update
[[ ! -e "$RUNTIME_MARKER" ]] || { echo 'Runtime callback executed during update' >&2; exit 1; }
[[ $(git -C "$XDG_DATA_HOME/nvim/lazy/root" rev-parse HEAD) == $(git -C "$tmp/root" rev-parse HEAD) ]]
[[ $(git -C "$XDG_DATA_HOME/nvim/lazy/dependency" rev-parse HEAD) == $(git -C "$tmp/dependency" rev-parse HEAD) ]]
commit_plugin root B
commit_plugin dependency v1.1
git -C "$tmp/dependency" tag v1.1
git -C "$tmp/root" switch -q -c not-allowed
commit_plugin root wrong-branch
git -C "$tmp/root" switch -q allowed
commit_plugin dependency v2.0
git -C "$tmp/dependency" tag v2.0
allowed=$(git -C "$tmp/root" rev-parse HEAD)
bounded=$(git -C "$tmp/dependency" rev-parse v1.1)
update
[[ ! -e "$RUNTIME_MARKER" ]] || { echo 'Runtime callback executed during update' >&2; exit 1; }
[[ $(git -C "$XDG_DATA_HOME/nvim/lazy/root" rev-parse HEAD) == "$allowed" ]] || { echo 'Branch constraint or conditional update failed' >&2; exit 1; }
[[ $(git -C "$XDG_DATA_HOME/nvim/lazy/dependency" rev-parse HEAD) == "$bounded" ]] || { echo 'Dependency update or version constraint failed' >&2; exit 1; }
commit_plugin root C
if FAIL_BUILD=1 update > "$tmp/failure.log" 2>&1; then
  echo 'Lazy build failure incorrectly reported success' >&2
  exit 1
fi
[[ $(< "$tmp/failure.log") == *'Failed process (build):'* ]] || { echo 'Update failed without reporting its build task' >&2; exit 1; }
[[ ! -e "$RUNTIME_MARKER" ]] || { echo 'Runtime callback executed during update' >&2; exit 1; }
printf 'Neovim plugin updater: isolated Git update and error propagation passed\n'
