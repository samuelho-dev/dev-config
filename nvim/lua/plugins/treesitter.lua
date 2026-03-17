-- Treesitter: syntax highlighting and code understanding

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    lazy = false,
    opts = {
      ensure_installed = {
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
      },
      auto_install = true,
      highlight = { enable = true },
      indent = {
        enable = true,
        disable = { 'ruby' },
      },
    },
  },
}
