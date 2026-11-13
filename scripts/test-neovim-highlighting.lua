-- Run from the repo root: nvim --headless -u NONE -l scripts/test-neovim-highlighting.lua
local root = vim.fn.getcwd()
local lockfile = vim.fn.tempname()
vim.o.loadplugins = true
vim.o.termguicolors = true
vim.opt.rtp:prepend(root .. '/nvim')
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')
local plugins = dofile('nvim/lua/plugins/ui.lua')
local selected = dofile('nvim/lua/plugins/treesitter.lua')
for _, plugin in ipairs(plugins) do
  if plugin[1] == 'sainnhe/gruvbox-material' or plugin[1] == 'HiPhish/rainbow-delimiters.nvim' then
    selected[#selected + 1] = plugin
  end
end
require('lazy').setup(selected, {
  lockfile = lockfile,
  change_detection = { enabled = false },
})

local ok, err = pcall(function()
  assert(vim.g.colors_name == 'gruvbox-material', 'Gruvbox Material must load')
  assert(vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg == nil, 'Rex background must remain visible')
  local function open(filetype, lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = filetype
    vim.cmd.redraw()
    assert(vim.treesitter.highlighter.active[buf], filetype .. ': highlighting must start')
    return buf
  end
  local buf = open('typescriptreact', {
    'const view = <main><Card title="hello">{value}</Card></main>',
  })
  assert(vim.wait(5000, function()
    local groups = {}
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
      local group = mark[4].hl_group
      if type(group) == 'string' and group:match('^RainbowDelimiter') then
        groups[group] = true
      end
    end
    return vim.tbl_count(groups) >= 2
  end), 'Nested JSX must receive distinct depth highlights')
  local function color(group)
    return vim.api.nvim_get_hl(0, { name = group, link = false }).fg
  end
  assert(color('@tag.attribute') ~= color('@string'), 'Props and strings must be distinguishable')
  local before = color('RainbowDelimiterRed')
  vim.o.background = 'light'
  assert(color('RainbowDelimiterRed') ~= before, 'Nesting colors must follow theme changes')
  vim.o.background = 'dark'

  -- Nix is deliberately outside the default parser installation list.
  require('nvim-treesitter').install({ 'nix' }):wait(120000)
  open('nix', { '{ answer = 42; }' })
  local plain = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(plain)
  vim.bo.filetype = 'text'
  assert(not vim.treesitter.highlighter.active[plain], 'Plain text must not need a parser')
end)
vim.fn.delete(lockfile)
assert(ok, err)
print('Highlighting checks passed: transparent background, nested JSX, prop/string contrast, theme switching, additional parser')
