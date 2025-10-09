-- UI plugins: which-key, colorscheme, todo-comments, mini.nvim, vim-visual-multi, indent-blankline

return {
  -- Which-key: shows pending keybinds
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      -- Document existing key chains
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>r', group = '[R]eplace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },

  -- Colorscheme: tokyonight
  {
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false }, -- Disable italics in comments
        },
      }

      -- Load the colorscheme
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },

  -- Collection of various small independent plugins/modules
  {
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      require('mini.surround').setup()

      -- Simple and easy statusline
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- Cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  -- Multiple cursors (VS Code-style)
  {
    'mg979/vim-visual-multi',
    branch = 'master',
    event = 'VeryLazy', -- Lazy load to avoid startup impact
    init = function()
      -- Change <C-n> to <leader>m to avoid blink.cmp conflict
      vim.g.VM_maps = {
        ['Find Under'] = '<leader>m', -- Start multi-cursor, select word under cursor
        ['Find Subword Under'] = '<leader>m', -- Same for subwords
      }

      -- Customize theme to match tokyonight
      vim.g.VM_theme = 'iceblue'

      -- Show messages in statusline instead of command line
      vim.g.VM_silent_exit = 1
    end,
  },

  -- Indent guides with scope highlighting
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' }, -- Lazy load on file open
    opts = {
      indent = {
        char = '│',
        tab_char = '│',
      },
      scope = {
        enabled = true,
        show_start = true,
        show_end = false,
        injected_languages = true,
        highlight = { 'Function', 'Label' },
        priority = 1024,
      },
      exclude = {
        filetypes = {
          'help',
          'alpha',
          'dashboard',
          'neo-tree',
          'Trouble',
          'trouble',
          'lazy',
          'mason',
          'notify',
          'toggleterm',
          'lazyterm',
        },
        buftypes = {
          'terminal',
          'nofile',
          'quickfix',
          'prompt',
        },
      },
    },
  },

  -- Tabline with numbered buffer navigation
  {
    'romgrk/barbar.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-tree/nvim-web-devicons', -- File icons
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    opts = {
      -- Tabline appearance
      animation = true,
      auto_hide = false,
      tabpages = true,
      clickable = true,

      -- Sidebar integration (Neo-tree)
      sidebar_filetypes = {
        ['neo-tree'] = { event = 'BufWipeout', text = 'neo-tree' },
      },

      -- Icons
      icons = {
        buffer_index = false,
        buffer_number = false,
        button = '',
        diagnostics = {
          [vim.diagnostic.severity.ERROR] = { enabled = true },
          [vim.diagnostic.severity.WARN] = { enabled = false },
          [vim.diagnostic.severity.INFO] = { enabled = false },
          [vim.diagnostic.severity.HINT] = { enabled = false },
        },
        gitsigns = {
          added = { enabled = true, icon = '+' },
          changed = { enabled = true, icon = '~' },
          deleted = { enabled = true, icon = '-' },
        },
        filetype = {
          custom_colors = false,
          enabled = true,
        },
        separator = { left = '▎', right = '' },
        modified = { button = '●' },
        pinned = { button = '', filename = true },
        preset = 'default',
        alternate = { filetype = { enabled = false } },
        current = { buffer_index = false },
        inactive = { button = '×' },
        visible = { modified = { buffer_number = false } },
      },

      -- Highlight groups (match tokyonight theme)
      highlight_visible = true,

      -- Insert at end of bufferline instead of start
      insert_at_end = false,
      insert_at_start = false,

      -- Maximum padding width
      maximum_padding = 1,

      -- Minimum padding width
      minimum_padding = 1,

      -- Maximum buffer name length
      maximum_length = 30,

      -- Semantic letters for quick navigation
      semantic_letters = true,

      -- Don't show numbers for buffers
      numbers = false,

      -- No offset for first buffer
      no_name_title = nil,
    },
    keys = {
      -- Navigate to specific buffer (Alt+1-9)
      { '<M-1>', '<Cmd>BufferGoto 1<CR>', desc = 'Barbar: Go to buffer 1' },
      { '<M-2>', '<Cmd>BufferGoto 2<CR>', desc = 'Barbar: Go to buffer 2' },
      { '<M-3>', '<Cmd>BufferGoto 3<CR>', desc = 'Barbar: Go to buffer 3' },
      { '<M-4>', '<Cmd>BufferGoto 4<CR>', desc = 'Barbar: Go to buffer 4' },
      { '<M-5>', '<Cmd>BufferGoto 5<CR>', desc = 'Barbar: Go to buffer 5' },
      { '<M-6>', '<Cmd>BufferGoto 6<CR>', desc = 'Barbar: Go to buffer 6' },
      { '<M-7>', '<Cmd>BufferGoto 7<CR>', desc = 'Barbar: Go to buffer 7' },
      { '<M-8>', '<Cmd>BufferGoto 8<CR>', desc = 'Barbar: Go to buffer 8' },
      { '<M-9>', '<Cmd>BufferGoto 9<CR>', desc = 'Barbar: Go to buffer 9' },
      { '<M-0>', '<Cmd>BufferLast<CR>', desc = 'Barbar: Go to last buffer' },

      -- Navigate between buffers
      { '<M-,>', '<Cmd>BufferPrevious<CR>', desc = 'Barbar: Previous buffer' },
      { '<M-.>', '<Cmd>BufferNext<CR>', desc = 'Barbar: Next buffer' },

      -- Re-order buffers
      { '<M-<>', '<Cmd>BufferMovePrevious<CR>', desc = 'Barbar: Move buffer left' },
      { '<M->>', '<Cmd>BufferMoveNext<CR>', desc = 'Barbar: Move buffer right' },

      -- Pin/unpin buffer
      { '<M-p>', '<Cmd>BufferPin<CR>', desc = 'Barbar: Pin/unpin buffer' },

      -- Close buffer
      { '<M-c>', '<Cmd>BufferClose<CR>', desc = 'Barbar: Close buffer' },

      -- Magic buffer-picking mode
      { '<leader>bp', '<Cmd>BufferPick<CR>', desc = 'Barbar: Pick buffer' },

      -- Sort buffers
      { '<leader>bb', '<Cmd>BufferOrderByBufferNumber<CR>', desc = 'Barbar: Sort by buffer number' },
      { '<leader>bd', '<Cmd>BufferOrderByDirectory<CR>', desc = 'Barbar: Sort by directory' },
      { '<leader>bl', '<Cmd>BufferOrderByLanguage<CR>', desc = 'Barbar: Sort by language' },
      { '<leader>bw', '<Cmd>BufferOrderByWindowNumber<CR>', desc = 'Barbar: Sort by window number' },
    },
  },
}
