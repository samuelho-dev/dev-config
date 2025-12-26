-- [[ Setting options ]]
-- See `:help vim.o`

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable unused providers (reduces startup time and health check warnings)
-- See `:help provider`
vim.g.loaded_perl_provider = 0 -- Perl provider not needed (no Perl plugins)
vim.g.loaded_ruby_provider = 0 -- Ruby provider not needed (treesitter uses Ruby for syntax only)

-- Python virtual environment detection
local function set_project_python()
  local cwd = vim.fn.expand '%:p:h'
  local venv_python = vim.fn.findfile('.venv/bin/python', cwd .. ';')
  if venv_python ~= '' then
    vim.g.python3_host_prog = vim.fn.fnamemodify(venv_python, ':p')
  end
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged' }, {
  callback = set_project_python,
})

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'` and `:help 'listchars'`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Auto-reload files when changed outside Neovim (critical for Claude Code workflows)
-- See `:help 'autoread'`
vim.o.autoread = true

-- Command-line completion
-- See `:help 'wildmode'` and `:help 'wildoptions'`
vim.o.wildmode = 'longest:full,full' -- Complete longest common string, then cycle through full matches
vim.o.wildoptions = 'pum'            -- Use popup menu for completion (Neovim default, but explicit)
