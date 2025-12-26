-- TypeScript Return Type Annotation Stripper
-- Removes ': Type' annotations from function return types on save
-- Uses Neovim's native tree-sitter API for precise AST-based removal

local M = {}

-- Configuration
M.config = {
  enabled = true,
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  dry_run = false, -- Set true for testing without modifying buffer
  notify_on_strip = true, -- Show notification when types are removed
  debug = false, -- Enable debug logging
}

-- Debug logging helper
local function log(msg)
  if M.config.debug then
    print('[TS-Stripper] ' .. msg)
  end
end

--- Check if tree-sitter parser is available for the given language
--- @param lang string Language name (e.g., 'typescript')
--- @return boolean available True if parser is installed
function M.has_parser(lang)
  local ok, _ = pcall(vim.treesitter.get_parser, 0, lang)
  return ok
end

--- Find all return type annotations in buffer using tree-sitter
--- @param bufnr number Buffer number (0 for current buffer)
--- @return table matches List of {row, col, end_row, end_col, text}
function M.find_return_types(bufnr)
  bufnr = bufnr or 0

  -- Get filetype and determine parser language
  local ft = vim.bo[bufnr].filetype
  local lang = 'typescript'
  if ft == 'javascript' or ft == 'javascriptreact' then
    lang = 'javascript'
  elseif ft == 'typescriptreact' then
    lang = 'tsx'
  end

  log(string.format('Filetype: %s, Parser lang: %s', ft, lang))

  -- Check if parser is available
  if not M.has_parser(lang) then
    log('Parser NOT available!')
    vim.notify('Tree-sitter parser for ' .. lang .. ' not available', vim.log.levels.WARN)
    return {}
  end

  log('Parser available')

  -- Parse buffer
  local parser = vim.treesitter.get_parser(bufnr, lang)
  local tree = parser:parse()[1]
  local root = tree:root()

  log(string.format('Root node: %s, children: %d', root:type(), root:child_count()))

  -- Tree-sitter query to find return type annotations
  -- Matches: function_declaration, arrow_function, method_definition, method_signature
  local query_string = [[
    (function_declaration
      return_type: (type_annotation) @return_type)

    (arrow_function
      return_type: (type_annotation) @return_type)

    (method_definition
      return_type: (type_annotation) @return_type)

    (method_signature
      return_type: (type_annotation) @return_type)
  ]]

  local query = vim.treesitter.query.parse(lang, query_string)
  local matches = {}

  -- Iterate over all captures
  for id, node, _ in query:iter_captures(root, bufnr) do
    local capture_name = query.captures[id]
    if capture_name == 'return_type' then
      local start_row, start_col, end_row, end_col = node:range()

      -- Get the text of the matched node
      local text = vim.treesitter.get_node_text(node, bufnr)

      log(string.format('Found match at line %d: %s', start_row + 1, text))

      table.insert(matches, {
        row = start_row,
        col = start_col,
        end_row = end_row,
        end_col = end_col,
        text = text,
        node = node,
      })
    end
  end

  log(string.format('Total matches found: %d', #matches))
  return matches
end

--- Remove return type annotations from buffer
--- @param bufnr number Buffer number (0 for current buffer)
--- @return number count Number of return types removed
function M.strip_return_types(bufnr)
  bufnr = bufnr or 0

  -- Find all return type annotations
  local matches = M.find_return_types(bufnr)

  if #matches == 0 then
    return 0
  end

  -- Sort matches in reverse order (bottom to top, right to left)
  -- This ensures that removing one match doesn't affect positions of others
  table.sort(matches, function(a, b)
    if a.row ~= b.row then
      return a.row > b.row
    end
    return a.col > b.col
  end)

  -- Dry run mode: just return count without modifying
  if M.config.dry_run then
    vim.notify(string.format('[DRY RUN] Would remove %d return type annotations', #matches), vim.log.levels.INFO)
    return #matches
  end

  -- Remove each return type annotation
  for _, match in ipairs(matches) do
    local start_row = match.row
    local start_col = match.col
    local end_row = match.end_row
    local end_col = match.end_col

    -- We need to include the colon before the type annotation
    -- The type_annotation starts AFTER the ':', so we need to look back
    -- Get the line text to find the colon
    local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]

    -- Find the colon before the type annotation
    -- Search backwards from start_col to find ':'
    local colon_col = start_col - 1
    while colon_col >= 0 do
      local char = line:sub(colon_col + 1, colon_col + 1)
      if char == ':' then
        start_col = colon_col
        break
      elseif char:match('%S') then
        -- Found non-whitespace that isn't ':', stop
        break
      end
      colon_col = colon_col - 1
    end

    -- Delete the range (including the colon and type annotation)
    vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { '' })
  end

  return #matches
end

--- Hook to run before save for TypeScript files
--- @param bufnr number Buffer number (0 for current buffer)
--- @return number|nil count Number of types removed, or nil if skipped
function M.on_save(bufnr)
  bufnr = bufnr or 0

  log('on_save() called')

  -- Check if enabled
  if not M.config.enabled then
    log('Stripper is DISABLED')
    return nil
  end

  log('Stripper is enabled')

  -- Check filetype
  local ft = vim.bo[bufnr].filetype
  log(string.format('Current filetype: %s', ft))

  local should_process = false
  for _, allowed_ft in ipairs(M.config.filetypes) do
    if ft == allowed_ft then
      should_process = true
      break
    end
  end

  if not should_process then
    log('Filetype not in allowed list, skipping')
    return nil
  end

  log('Filetype allowed, proceeding with strip')

  -- Strip return types
  local count = M.strip_return_types(bufnr)

  log(string.format('Stripped %d return type annotations', count))

  -- Optional notification
  if count > 0 and M.config.notify_on_strip then
    vim.notify(string.format('Removed %d return type annotation%s', count, count == 1 and '' or 's'), vim.log.levels.INFO)
  end

  return count
end

--- Preview what would be removed (for debugging)
--- @param bufnr number Buffer number (0 for current buffer)
function M.preview_changes(bufnr)
  bufnr = bufnr or 0
  local matches = M.find_return_types(bufnr)

  if #matches == 0 then
    print('No return type annotations found.')
    return
  end

  print(string.format('Found %d return type annotation%s:\n', #matches, #matches == 1 and '' or 's'))

  for i, match in ipairs(matches) do
    print(string.format('  %d. Line %d, Col %d: %s', i, match.row + 1, match.col + 1, match.text))
  end
end

--- Test tree-sitter query (for debugging)
--- @param bufnr number Buffer number (0 for current buffer)
function M.test_query(bufnr)
  bufnr = bufnr or 0

  local ft = vim.bo[bufnr].filetype
  print(string.format('Filetype: %s', ft))

  local lang = 'typescript'
  if ft == 'javascript' or ft == 'javascriptreact' then
    lang = 'javascript'
  elseif ft == 'typescriptreact' then
    lang = 'tsx'
  end

  print(string.format('Parser language: %s', lang))

  if not M.has_parser(lang) then
    print('❌ Tree-sitter parser NOT available')
    return
  end

  print('✅ Tree-sitter parser available')

  local parser = vim.treesitter.get_parser(bufnr, lang)
  local tree = parser:parse()[1]
  local root = tree:root()

  print(string.format('Root node type: %s', root:type()))
  print(string.format('Tree has %d children', root:child_count()))
end

--- Setup function
--- @param opts table|nil Configuration options
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  -- Validate tree-sitter availability for configured filetypes
  local missing_parsers = {}
  for _, ft in ipairs(M.config.filetypes) do
    local lang = ft
    if ft == 'typescriptreact' then
      lang = 'tsx'
    elseif ft == 'javascriptreact' then
      lang = 'jsx'
    end

    if not M.has_parser(lang) then
      table.insert(missing_parsers, lang)
    end
  end

  if #missing_parsers > 0 then
    vim.notify(
      string.format('TypeScript Return Stripper: Missing tree-sitter parsers: %s', table.concat(missing_parsers, ', ')),
      vim.log.levels.WARN
    )
  end
end

return M
