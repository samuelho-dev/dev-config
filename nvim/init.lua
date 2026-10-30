--[[

The configuration is organized into these modules:
  - lua/config/         : Core Neovim configuration (options, keymaps, autocmds)
  - lua/plugins/        : Plugin specifications organized by category
  - lua/plugins/custom/ : Custom plugin utilities

For more information, see:
  - nvim/README.md     : User documentation
  - :help lua-guide    : Neovim Lua guide

--]]

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out =
    vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- The scheduled updater needs specs, not interactive options or callbacks.
local updating = vim.g.dev_config_plugin_update == true
if not updating then
  require 'config'
end

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- Plugins are organized into separate files in lua/plugins/
-- Each file returns a table of plugin specifications
-- The Nix-store config is read-only; keep Lazy's lockfile in writable local state.
local state = vim.fn.stdpath 'state'
vim.fn.mkdir(state, 'p')
local lockfile = state .. '/lazy-lock.json'

local specs = {
  -- Import all plugin modules
  { import = 'plugins.editor' }, -- File explorer, fuzzy finder, search/replace
  { import = 'plugins.lsp' }, -- LSP configuration and formatting
  { import = 'plugins.completion' }, -- Autocompletion (blink.cmp, LuaSnip)
  { import = 'plugins.ai' }, -- AI assistance (minuet, codecompanion, yarepl)
  { import = 'plugins.git' }, -- Git integration
  { import = 'plugins.markdown' }, -- Markdown and Obsidian
  { import = 'plugins.ui' }, -- UI enhancements
  { import = 'plugins.treesitter' }, -- Syntax highlighting
  { import = 'plugins.tools' }, -- Utility tools (CSV viewer)
  { import = 'plugins.training' }, -- Vim training games
}

if updating then
  -- Retain update/build/version constraints without loading plugin runtime setup.
  local function prepare(plugin)
    if type(plugin) == 'table' then
      plugin.cond = true
      plugin.lazy = true
      plugin.init = nil
      plugin.config = nil
      plugin.opts = nil
      plugin.event = nil
      plugin.ft = nil
      plugin.cmd = nil
      plugin.keys = nil
      for _, dependency in ipairs(plugin.dependencies or {}) do
        prepare(dependency)
      end
      for _, child in ipairs(plugin.specs or {}) do
        prepare(child)
      end
    end
    return plugin
  end

  local resolved = {}
  for _, category in ipairs(specs) do
    for _, plugin in ipairs(require(category.import)) do
      resolved[#resolved + 1] = prepare(plugin)
    end
  end
  specs = resolved
end

require('lazy').setup(specs, {
  performance = updating and { rtp = { reset = false } } or nil,
  local_spec = not updating,
  lockfile = lockfile,
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
