-- Run from the repo root: nvim --headless -u NONE -l scripts/test-neovim-obsidian.lua
local spec = dofile('nvim/lua/plugins/markdown.lua')[1]
local workspace = spec.opts.workspaces[1]
local root = vim.fn.tempname()
local cwd = vim.fn.getcwd()
vim.fn.mkdir(root .. '/vault/.obsidian', 'p')
vim.fn.mkdir(root .. '/vault/notes', 'p')
vim.fn.mkdir(root .. '/plain', 'p')
assert(vim.uv.fs_symlink(root .. '/vault/notes', root .. '/linked'))

local ok, err = pcall(function()
  vim.api.nvim_set_current_dir(root .. '/plain')
  local function check(name, expected)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    if name then vim.api.nvim_buf_set_name(buf, name) end
    local actual = workspace.path()
    assert(actual == expected, tostring(name) .. ': expected ' .. expected .. ', got ' .. tostring(actual))
    assert(vim.fn.isdirectory(actual) == 1, 'Workspace must exist')
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  check(root .. '/vault/notes/new.md', root .. '/vault')
  check(root .. '/linked/new.md', root .. '/vault')
  check(root .. '/plain/new.md', root .. '/plain')
  check('diffview://' .. root .. '/repo/.git/:0:/README.md', root .. '/plain')
  check(root .. '/missing/nested/new.md', root .. '/plain')
  check(nil, root .. '/plain')
  vim.api.nvim_set_current_dir(root .. '/vault/notes')
  check('diffview://' .. root .. '/repo/.git/:0:/README.md', root .. '/vault')
end)
vim.api.nvim_set_current_dir(cwd)
vim.fn.delete(root, 'rf')
assert(ok, err)
print('Obsidian workspace checks passed: vault, symlink, plain Markdown, Diffview, missing parent, unnamed buffer, vault cwd')
