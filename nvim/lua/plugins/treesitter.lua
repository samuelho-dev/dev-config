-- Treesitter: syntax highlighting and code understanding
--
-- NOTE: Uses the `main` branch (rewrite for Neovim 0.11+). The legacy `master`
-- branch is incompatible with Neovim 0.12 (`node:range()` errors during markdown
-- injection parsing). The `main` branch drops the old `setup{ ensure_installed,
-- highlight, indent }` API in favor of:
--   - `require('nvim-treesitter').install(langs)` to install parsers
--   - `vim.treesitter.start()` per-buffer for highlighting (FileType autocmd)
--   - `vim.bo.indentexpr` for indentation

local ensure_installed = {
  'bash',
  'c',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  -- JavaScript/TypeScript
  'javascript',
  'typescript',
  'tsx',
  'jsdoc',
  -- Python
  'python',
  -- Common formats
  'json',
  'yaml',
  'toml',
  'css',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install(ensure_installed)

      -- Enable treesitter highlighting + indentation per buffer.
      -- The `main` branch no longer wires this automatically.
      vim.api.nvim_create_autocmd('FileType', {
        desc = 'Enable treesitter highlighting and indentation',
        callback = function(args)
          local filetype = args.match
          -- Map filetype -> parser language (handles aliases like tsx/typescriptreact)
          local lang = vim.treesitter.language.get_lang(filetype) or filetype
          if not vim.tbl_contains(ensure_installed, lang) then
            return
          end
          -- Highlighting (no-op if parser missing)
          pcall(vim.treesitter.start)
          -- Indentation (skip languages where treesitter indent misbehaves)
          if filetype ~= 'ruby' then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
