-- [[ Basic Autocommands ]]
-- See `:help lua-guide-autocommands`

-- Trigger checktime on these events to make autoread work automatically
-- Required because autoread doesn't work on its own - needs events to trigger the check
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  desc = 'Check if files changed outside Neovim',
  pattern = '*',
  command = 'checktime',
})

-- Notify when file is reloaded from disk
vim.api.nvim_create_autocmd('FileChangedShellPost', {
  desc = 'Notify when file changed on disk',
  pattern = '*',
  command = 'echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None',
})

-- CSV filetype detection for csvview.nvim
-- Neovim doesn't detect CSV files by default, so we set the filetype explicitly
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  desc = 'Set filetype for CSV/TSV files',
  pattern = { '*.csv', '*.tsv' },
  callback = function()
    vim.bo.filetype = 'csv'
    -- Ensure csvview.nvim loads for this buffer
    vim.cmd 'doautocmd FileType csv'
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})
