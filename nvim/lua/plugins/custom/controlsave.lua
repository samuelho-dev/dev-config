-- Quick save functionality for Neovim
-- Provides Ctrl+S save keybinding matching industry standards (VS Code, IntelliJ, etc.)

local M = {}

-- Configuration (can be extended later)
M.config = {
  notify_on_save = false, -- Set to true for save notifications
  save_on_focus_lost = false, -- Future: auto-save on focus lost
}

--- Save the current buffer
--- Works in normal, insert, and visual mode
--- Integrates with TypeScript return type stripper if enabled
--- @return nil
function M.save()
  local modified = vim.bo.modified
  local readonly = vim.bo.readonly
  local buftype = vim.bo.buftype

  -- Don't save if buffer is not modifiable
  if readonly then
    vim.notify('Buffer is read-only, cannot save', vim.log.levels.WARN)
    return
  end

  -- Don't save special buffers (help, terminal, etc.)
  if buftype ~= '' then
    vim.notify('Cannot save special buffer type: ' .. buftype, vim.log.levels.WARN)
    return
  end

  -- Check if file has a name
  local filename = vim.fn.expand '%'
  if filename == '' then
    vim.notify('No file name, use :saveas <filename>', vim.log.levels.WARN)
    return
  end

  -- Strip TypeScript return types before saving (if enabled)
  local stripper_ok, stripper = pcall(require, 'plugins.custom.typescript-return-stripper')
  if stripper_ok then
    stripper.on_save(0)
  end

  -- Save the file
  vim.cmd 'write'

  -- Optional notification
  if M.config.notify_on_save and modified then
    vim.notify('Saved: ' .. filename, vim.log.levels.INFO)
  end
end

--- Save all modified buffers
--- Useful for project-wide save
--- @return nil
function M.save_all()
  local modified_count = 0

  -- Count modified buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      modified_count = modified_count + 1
    end
  end

  if modified_count == 0 then
    vim.notify('No modified buffers to save', vim.log.levels.INFO)
    return
  end

  -- Save all modified buffers
  vim.cmd 'wall'

  if M.config.notify_on_save then
    vim.notify(string.format('Saved %d buffer(s)', modified_count), vim.log.levels.INFO)
  end
end

--- Format and save current buffer
--- Explicitly formats before saving (conform.nvim format_on_save already handles this)
--- Provided for explicit format+save workflows
--- @return nil
function M.format_and_save()
  -- Check if conform is available
  local conform_ok, conform = pcall(require, 'conform')

  if conform_ok then
    -- Format synchronously
    conform.format { timeout_ms = 500, lsp_format = 'fallback' }
  else
    -- Fallback to LSP formatting
    vim.lsp.buf.format { timeout_ms = 500 }
  end

  -- Save after formatting
  M.save()
end

--- Setup function (optional, for future configuration)
--- @param opts table|nil Configuration options
--- @return nil
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)
end

return M
