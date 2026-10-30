local Task, original_spawn

local ok, err = pcall(function()
  Task = require('lazy.manage.task')
  original_spawn = Task.spawn
  -- Headless Lazy does not record failed process exits as task errors.
  Task.spawn = function(self, cmd, opts)
    local success = original_spawn(self, cmd, opts)
    if success == false then
      self:error('Failed process (' .. self.name .. '): ' .. cmd)
    end
    return success
  end
  require('lazy').update({ wait = true, show = false })
  -- Lazy retains task failures instead of throwing them from update().
  if require('lazy.manage.checker').has_errors() then
    error('Lazy plugin update failed; see task errors above')
  end
end)

if original_spawn then
  Task.spawn = original_spawn
end

if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd('cquit 1')
else
  vim.cmd('qa')
end
