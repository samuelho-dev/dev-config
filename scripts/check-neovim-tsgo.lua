-- Run from the repository root: nvim --headless -u NONE -l scripts/check-neovim-tsgo.lua
local root = vim.fn.tempname()
local bin = root .. '/node_modules/.bin'
local original_start = vim.lsp.rpc.start
local original_enable = vim.lsp.enable
local original_blink = package.loaded['blink.cmp']
local selected
local function executable(path, body)
  vim.fn.writefile({ '#!/bin/sh', body or 'exit 0' }, path)
  vim.fn.setfperm(path, 'rwx------')
end
local ok, err = xpcall(function()
  vim.fn.mkdir(bin, 'p')
  root = assert(vim.uv.fs_realpath(root))
  bin = root .. '/node_modules/.bin'
  vim.lsp.enable = function() end
  package.loaded['blink.cmp'] = { get_lsp_capabilities = function() return {} end }
  -- Load the real plugin configuration without downloading or starting plugins/servers.
  local plugins = dofile('nvim/lua/plugins/lsp.lua')
  plugins[2].config()
  vim.lsp.enable = original_enable
  vim.lsp.rpc.start = function(cmd)
    selected = cmd
    return {}
  end
  local function expect(path)
    vim.lsp.config.tsc.cmd({}, { root_dir = root })
    assert(vim.deep_equal(selected, { path, '--lsp', '--stdio' }), vim.inspect(selected))
  end
  expect('tsc')
  executable(bin .. '/tsgo')
  expect(bin .. '/tsgo')
  local native = root .. '/effect-native'
  executable(native)
  executable(bin .. '/effect-tsgo', 'printf "%s\\n" "' .. native .. '"')
  expect(native)
  executable(bin .. '/effect-tsgo', 'exit 1')
  expect(bin .. '/tsgo')
  vim.fn.delete(bin .. '/tsgo')
  expect('tsc')
  vim.fn.writefile({ '{}' }, root .. '/package.json')
  vim.fn.writefile({}, root .. '/index.ts')
  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(bufnr, root .. '/index.ts')
  local selected_root
  vim.lsp.config.tsc.root_dir(bufnr, function(dir) selected_root = dir end)
  assert(selected_root == root, 'package.json-only projects must attach')
  vim.fn.delete(root .. '/package.json')
  vim.lsp.config.tsc.root_dir(bufnr, function(dir) selected_root = dir end)
  assert(selected_root == vim.fn.getcwd(), 'standalone files must attach')
  vim.api.nvim_buf_delete(bufnr, { force = true })
end, debug.traceback)
vim.lsp.rpc.start = original_start
vim.lsp.enable = original_enable
package.loaded['blink.cmp'] = original_blink
vim.fn.delete(root, 'rf')
assert(ok, err)
print('Neovim native TypeScript selection passed')
