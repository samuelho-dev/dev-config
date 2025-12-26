-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- Custom diagnostic copy keybindings for CLI workflows
local diag_copy = require 'plugins.custom.diagnostics-copy'
vim.keymap.set('n', '<leader>ce', diag_copy.copy_errors_only, { desc = '[C]opy [E]rrors to clipboard' })
vim.keymap.set('n', '<leader>cd', diag_copy.copy_all_diagnostics, { desc = '[C]opy [D]iagnostics to clipboard' })

-- Custom quick save plugin
local controlsave = require 'plugins.custom.controlsave'

-- Initialize TypeScript return type stripper with notifications
local stripper = require 'plugins.custom.typescript-return-stripper'
stripper.setup({
  enabled = true,
  debug = false,             -- Set to true for debugging
  notify_on_strip = true,    -- Show notification when types are removed
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
})

-- Ctrl+S: Save file (works in normal, insert, visual mode)
vim.keymap.set('n', '<C-s>', controlsave.save, { desc = 'Save file' })
vim.keymap.set('i', '<C-s>', function()
  -- Exit insert mode first, then save
  vim.cmd 'stopinsert'
  controlsave.save()
end, { desc = 'Save file' })
vim.keymap.set('v', '<C-s>', function()
  -- Exit visual mode first, then save
  vim.cmd 'normal! <Esc>'
  controlsave.save()
end, { desc = 'Save file' })

-- Path copying utilities
vim.keymap.set('n', '<leader>crp', function()
  local path = vim.fn.expand '%'
  vim.fn.setreg('+', path)
  vim.fn.setreg('*', path)
  vim.notify('Copied relative path to clipboard', vim.log.levels.INFO)
end, { desc = '[C]opy [R]elative [P]ath' })

vim.keymap.set('n', '<leader>cp', function()
  local path = vim.fn.expand '%:p'
  vim.fn.setreg('+', path)
  vim.fn.setreg('*', path)
  vim.notify('Copied absolute path to clipboard', vim.log.levels.INFO)
end, { desc = '[C]opy [P]ath (absolute)' })

-- Reload Neovim config
vim.keymap.set('n', '<leader>Rc', function()
  vim.cmd 'source $MYVIMRC'
  vim.notify('Reloaded Neovim config', vim.log.levels.INFO)
end, { desc = '[R]eload Neovim [C]onfig' })

-- TypeScript Return Type Stripper - Debug Commands
vim.api.nvim_create_user_command('TSStripPreview', function()
  local stripper = require 'plugins.custom.typescript-return-stripper'
  stripper.preview_changes(0)
end, { desc = 'Preview TypeScript return types that would be removed' })

vim.api.nvim_create_user_command('TSStripTest', function()
  local stripper = require 'plugins.custom.typescript-return-stripper'
  stripper.test_query(0)
end, { desc = 'Test tree-sitter query for TypeScript' })

vim.api.nvim_create_user_command('TSStripNow', function()
  local stripper = require 'plugins.custom.typescript-return-stripper'
  local count = stripper.strip_return_types(0)
  vim.notify(string.format('Removed %d return type annotation%s', count, count == 1 and '' or 's'), vim.log.levels.INFO)
end, { desc = 'Immediately strip return types without saving' })

vim.api.nvim_create_user_command('TSStripDebug', function()
  local stripper = require 'plugins.custom.typescript-return-stripper'
  stripper.config.debug = not stripper.config.debug
  local status = stripper.config.debug and 'ENABLED' or 'DISABLED'
  vim.notify('TypeScript Stripper Debug: ' .. status, vim.log.levels.INFO)
end, { desc = 'Toggle TypeScript stripper debug logging' })
