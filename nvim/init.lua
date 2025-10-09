--[[

The configuration is organized into these modules:
  - lua/config/         : Core Neovim configuration (options, keymaps, autocmds)
  - lua/plugins/        : Plugin specifications organized by category
  - lua/plugins/custom/ : Custom plugin utilities

For more information, see:
  - nvim/CLAUDE.md     : AI assistant guidance
  - nvim/README.md     : User documentation
  - :help lua-guide    : Neovim Lua guide

--]]

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Load core configuration ]]
-- This loads options, autocommands, and keymaps
require 'config'

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
require('lazy').setup({
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
}, {
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
