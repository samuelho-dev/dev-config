local M = {}

local has_image, image = pcall(require, 'image')
local query = vim.treesitter.query.parse(
  'markdown',
  [[
    (fenced_code_block
      (info_string) @info
      (code_fence_content) @content) @block
  ]]
)

local cache_dir = vim.fn.stdpath('cache') .. '/mermaid-diagrams'
local state = {}

local function ensure_cache_dir()
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, 'p')
  end
end

local function safe_id(str)
  return (str:gsub('[^%w-_]', '_'))
end

local function clear_entry(entry)
  if entry and entry.image and has_image then
    pcall(function()
      entry.image:clear()
    end)
  end
end

local function ensure_state(bufnr)
  local buf_state = state[bufnr]
  if not buf_state then
    buf_state = {
      entries = {},
      pending = {},
      flush_scheduled = false,
      notified_cli_missing = false,
    }
    state[bufnr] = buf_state

    vim.api.nvim_create_autocmd('BufWipeout', {
      buffer = bufnr,
      callback = function()
        for _, entry in pairs(buf_state.entries) do
          clear_entry(entry)
        end
        state[bufnr] = nil
      end,
    })
  end
  return buf_state
end

local function notify_missing_cli(buf_state)
  if buf_state.notified_cli_missing then
    return false
  end

  buf_state.notified_cli_missing = true
  vim.schedule(function()
    vim.notify(
      'Mermaid preview requires @mermaid-js/mermaid-cli (`mmdc`). Install with `npm install -g @mermaid-js/mermaid-cli`.',
      vim.log.levels.WARN,
      { title = 'Mermaid Preview' }
    )
  end)
  return false
end

local function render_mermaid(buf_state, id, task)
  if not has_image then
    return
  end

  if vim.fn.executable('mmdc') ~= 1 then
    notify_missing_cli(buf_state)
    return
  end

  ensure_cache_dir()

  local entry = buf_state.entries[id] or {}
  if entry.hash == task.hash and entry.image then
    entry.image:render({ x = 0, y = task.start_row })
    entry.keep = true
    buf_state.entries[id] = entry
    return
  end

  local base_name = safe_id(string.format('%s-%s', id, task.hash:sub(1, 16)))
  local input_path = string.format('%s/%s.mmd', cache_dir, base_name)
  local output_path = string.format('%s/%s.png', cache_dir, base_name)

  local lines = vim.split(task.content, '\n', { plain = true })
  vim.fn.writefile(lines, input_path)

  local result = vim.system({
    'mmdc',
    '--input', input_path,
    '--output', output_path,
    '--quiet',
  }, { text = true }):wait()

  if result.code ~= 0 then
    vim.schedule(function()
      vim.notify(
        string.format('Mermaid render failed (%s)', result.stderr or result.stdout or 'unknown error'),
        vim.log.levels.ERROR,
        { title = 'Mermaid Preview' }
      )
    end)
    return
  end

  if entry.image then
    clear_entry(entry)
  end

  local image_id = string.format('mermaid:%s', base_name)
  local new_image = image.from_file(output_path, {
    id = image_id,
    buffer = task.bufnr,
    inline = true,
    with_virtual_padding = true,
  })

  if new_image then
    new_image:render({ x = 0, y = task.start_row })
    buf_state.entries[id] = {
      image = new_image,
      hash = task.hash,
      path = output_path,
      keep = true,
    }
  end
end

local function schedule_render(buf_state)
  if buf_state.flush_scheduled then
    return
  end

  buf_state.flush_scheduled = true
  vim.schedule(function()
    buf_state.flush_scheduled = false
    local pending = buf_state.pending
    buf_state.pending = {}
    for id, payload in pairs(pending) do
      render_mermaid(buf_state, id, payload)
    end
  end)
end

function M.parse(ctx)
  if not has_image then
    return {}
  end

  local bufnr = ctx.buf
  local root = ctx.root
  local buf_state = ensure_state(bufnr)
  local marks = {}

  local seen = {}
  for _, entry in pairs(buf_state.entries) do
    entry.keep = false
  end

  for _, match in query:iter_matches(root, bufnr, 0, -1) do
    local info_node = match[1]
    local content_node = match[2]
    local block_node = match[3]

    local info = vim.treesitter.get_node_text(info_node, bufnr)
    if not info or not info:match('%f[%w]mermaid%f[%W]') then
      goto continue
    end

    local content_text = vim.treesitter.get_node_text(content_node, bufnr) or ''
    local start_row, start_col, end_row, _ = block_node:range()
    local block_id = string.format('%d:%d:%d', bufnr, start_row, start_col)
    seen[block_id] = true

    marks[#marks + 1] = {
      conceal = true,
      start_row = start_row,
      start_col = 0,
      opts = {
        end_row = end_row,
        end_col = 0,
        hl_group = 'RenderMarkdownCode',
        virt_text = { { 'Mermaid diagram', 'Comment' } },
        virt_text_pos = 'overlay',
      },
    }

    buf_state.pending[block_id] = {
      bufnr = bufnr,
      hash = vim.fn.sha256(content_text),
      start_row = start_row,
      content = content_text,
    }

    buf_state.entries[block_id] = buf_state.entries[block_id] or {}
    buf_state.entries[block_id].keep = true

    ::continue::
  end

  for id, entry in pairs(buf_state.entries) do
    if not seen[id] or not entry.keep then
      clear_entry(entry)
      buf_state.entries[id] = nil
    end
  end

  if next(buf_state.pending) then
    schedule_render(buf_state)
  end

  return marks
end

return M
