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

  -- Cathode Amber from Rex Beta themes.json; Kanagawa provides the syntax/plugin highlight coverage.
  {
    'rebelot/kanagawa.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      -- ANSI 0-15 from /Applications/Rex Beta.app/Contents/Resources/SuperUI_SuperDesignTokens.bundle/Contents/Resources/themes.json
      local ansi = {
        '#241a0e', '#e8763f', '#b8a83f', '#ffb642',
        '#c98d4f', '#cf8a62', '#d4a852', '#cfa972',
        '#7a6238', '#f2925f', '#d0c05e', '#ffcc70',
        '#dca86e', '#e2a67f', '#e7c077', '#ffe8c2',
      }
      ---@diagnostic disable-next-line: missing-fields
      require('kanagawa').setup {
        theme = 'dragon',
        commentStyle = { italic = false },
        colors = {
          theme = {
            dragon = {
              ui = {
                fg = '#f0c88a',
                fg_dim = ansi[8],
                fg_reverse = '#140f08',
                bg_dim = ansi[1],
                bg_gutter = '#140f08',
                bg_m3 = ansi[1],
                bg_m2 = ansi[1],
                bg_m1 = ansi[1],
                bg = '#140f08',
                bg_p1 = ansi[1],
                bg_p2 = '#4a3212',
                special = ansi[7],
                nontext = ansi[9],
                whitespace = ansi[9],
                bg_search = '#4a3212',
                bg_visual = '#4a3212',
                pmenu = {
                  fg = '#f0c88a',
                  fg_sel = '#ffe8c2',
                  bg = ansi[1],
                  bg_sel = '#4a3212',
                  bg_sbar = ansi[1],
                  bg_thumb = ansi[9],
                },
                float = {
                  fg = '#f0c88a',
                  bg = ansi[1],
                  fg_border = ansi[9],
                  bg_border = ansi[1],
                },
              },
              syn = {
                string = ansi[3],
                variable = 'none',
                number = ansi[12],
                constant = ansi[4],
                identifier = ansi[7],
                parameter = ansi[8],
                fun = ansi[13],
                statement = ansi[6],
                keyword = ansi[4],
                operator = ansi[14],
                preproc = ansi[2],
                type = ansi[11],
                regex = ansi[12],
                deprecated = ansi[9],
                comment = ansi[9],
                punct = ansi[8],
                special1 = ansi[5],
                special2 = ansi[10],
                special3 = ansi[15],
              },
              diag = {
                error = ansi[2],
                warning = ansi[4],
                info = ansi[7],
                hint = ansi[8],
                ok = ansi[3],
              },
              vcs = {
                added = ansi[3],
                removed = ansi[2],
                changed = ansi[4],
              },
              diff = {
                add = '#4a3212',
                delete = ansi[1],
                change = ansi[9],
                text = '#4a3212',
              },
              term = ansi,
            },
          },
        },
        overrides = function()
          return {
            Cursor = { fg = '#140f08', bg = '#ffb642' },
            Visual = { fg = '#ffe8c2', bg = '#4a3212' },
            -- VM has no custom palette API; without VM_theme it preserves these links.
            VM_Mono = { link = 'Cursor' },
            VM_Cursor = { link = 'Visual' },
            VM_Extend = { link = 'Search' },
            VM_Insert = { link = 'Cursor' },
          }
        end,
      }

      vim.cmd.colorscheme 'kanagawa-dragon'
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
        ['Find Under'] = '<leader>m',         -- Start multi-cursor, select word under cursor
        ['Find Subword Under'] = '<leader>m', -- Same for subwords
      }

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
}
