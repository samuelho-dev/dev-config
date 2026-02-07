-- Treesitter: syntax highlighting and code understanding
-- Uses the new nvim-treesitter main branch API (post-v0.10.0)

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    lazy = false,
    config = function()
      local parsers = {
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

      -- Install parsers (idempotent - skips already installed)
      require('nvim-treesitter').install(parsers)

      -- Enable treesitter highlighting and indentation via autocmd
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('TreesitterSetup', { clear = true }),
        callback = function(args)
          -- Check if a parser exists for this filetype
          if pcall(vim.treesitter.start, args.buf) then
            -- Enable treesitter-based indentation (except ruby)
            if vim.bo[args.buf].filetype ~= 'ruby' then
              vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end
        end,
      })

      -- Ruby: additional vim regex highlighting
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('TreesitterRuby', { clear = true }),
        pattern = 'ruby',
        callback = function()
          vim.opt_local.syntax = 'on'
        end,
      })
    end,
  },
}
