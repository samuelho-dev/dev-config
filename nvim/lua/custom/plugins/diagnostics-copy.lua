-- Copy LSP diagnostics to clipboard for Claude Code workflows
local M = {}

function M.copy_errors_only()
  local diagnostics = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })

  if #diagnostics == 0 then
    vim.notify("No errors in current buffer", vim.log.levels.INFO)
    return
  end

  local lines = {"=== ERRORS ===", ""}
  for _, diag in ipairs(diagnostics) do
    table.insert(lines, string.format("Line %d: %s", diag.lnum + 1, diag.message))
  end

  local text = table.concat(lines, "\n")
  vim.fn.setreg('+', text)
  vim.fn.setreg('*', text)

  vim.notify(
    string.format("Copied %d errors to clipboard", #diagnostics),
    vim.log.levels.INFO
  )
end

function M.copy_all_diagnostics()
  local diagnostics = vim.diagnostic.get(0)

  if #diagnostics == 0 then
    vim.notify("No diagnostics in current buffer", vim.log.levels.INFO)
    return
  end

  -- Format for Claude Code readability
  local lines = {
    "=== Diagnostics for " .. vim.fn.expand('%:p') .. " ===",
    ""
  }

  -- Group by severity
  local errors = {}
  local warnings = {}
  local info = {}

  for _, diag in ipairs(diagnostics) do
    local msg = string.format("Line %d: %s", diag.lnum + 1, diag.message)
    if diag.severity == vim.diagnostic.severity.ERROR then
      table.insert(errors, msg)
    elseif diag.severity == vim.diagnostic.severity.WARN then
      table.insert(warnings, msg)
    else
      table.insert(info, msg)
    end
  end

  if #errors > 0 then
    table.insert(lines, "ERRORS:")
    vim.list_extend(lines, errors)
    table.insert(lines, "")
  end

  if #warnings > 0 then
    table.insert(lines, "WARNINGS:")
    vim.list_extend(lines, warnings)
    table.insert(lines, "")
  end

  if #info > 0 then
    table.insert(lines, "INFO:")
    vim.list_extend(lines, info)
  end

  local text = table.concat(lines, "\n")
  vim.fn.setreg('+', text)
  vim.fn.setreg('*', text)

  vim.notify(
    string.format("Copied %d diagnostics (%d errors, %d warnings)",
      #diagnostics, #errors, #warnings),
    vim.log.levels.INFO
  )
end

return M
