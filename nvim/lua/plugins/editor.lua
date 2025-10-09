-- Editor plugins: file explorer, fuzzy finder, search/replace

return {
  -- Detect tabstop and shiftwidth automatically
  'NMAC427/guess-indent.nvim',

  -- File explorer (VS Code-style sidebar)
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- File icons
      'MunifTanjim/nui.nvim',
    },
    config = function()
      require('neo-tree').setup {
        close_if_last_window = true, -- Close Neo-tree if it's the last window
        log_level = 'info', -- Fix: use string instead of number for log level
        window = {
          position = 'left',
          width = 30,
        },
        filesystem = {
          follow_current_file = {
            enabled = true, -- Focus on current file
          },
          use_libuv_file_watcher = true, -- Auto-refresh on external file changes (git, terminal, etc.)
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
      }
      -- Keybinding: Toggle Neo-tree with backslash
      vim.keymap.set('n', '\\', ':Neotree toggle<CR>', { desc = 'Toggle file tree', silent = true })
      vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Toggle file tree', silent = true })
    end,
  },

  -- Keep LSP aware of file moves/renames for import updates, etc.
  {
    'antosha417/nvim-lsp-file-operations',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neo-tree/neo-tree.nvim',
    },
    config = function()
      require('lsp-file-operations').setup()
    end,
  },

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  -- Search and replace across project
  {
    'nvim-pack/nvim-spectre',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    cmd = 'Spectre', -- Lazy load on command
    keys = {
      {
        '<leader>rr',
        function()
          require('spectre').open()
        end,
        desc = '[R]eplace in Files (Spectre)',
      },
      {
        '<leader>rw',
        function()
          require('spectre').open_visual { select_word = true }
        end,
        desc = '[R]eplace [W]ord (Spectre)',
      },
      {
        '<leader>rf',
        function()
          require('spectre').open_file_search()
        end,
        desc = '[R]eplace in [F]ile (Spectre)',
      },
      {
        '<leader>rw',
        function()
          require('spectre').open_visual()
        end,
        mode = 'v',
        desc = '[R]eplace Selection (Spectre)',
      },
    },
    opts = {
      color_devicons = true,
      open_cmd = 'vnew',
      live_update = false, -- Don't auto execute search when typing
      line_sep_start = '┌─────────────────────────────────────────',
      result_padding = '│  ',
      line_sep = '└─────────────────────────────────────────',
      highlight = {
        ui = 'String',
        search = 'DiffChange',
        replace = 'DiffDelete',
      },
      mapping = {
        ['toggle_line'] = {
          map = 'dd',
          cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
          desc = 'toggle item',
        },
        ['enter_file'] = {
          map = '<cr>',
          cmd = "<cmd>lua require('spectre').open_file_search()<CR>",
          desc = 'open file',
        },
        ['send_to_qf'] = {
          map = '<leader>q',
          cmd = "<cmd>lua require('spectre').change_options('send_to_qf')<CR>",
          desc = 'send all items to quickfix',
        },
        ['replace_cmd'] = {
          map = '<leader>c',
          cmd = "<cmd>lua require('spectre').replace_cmd()<CR>",
          desc = 'input replace command',
        },
        ['show_option_menu'] = {
          map = '<leader>o',
          cmd = "<cmd>lua require('spectre').show_options()<CR>",
          desc = 'show options',
        },
        ['run_current_replace'] = {
          map = '<leader>rc',
          cmd = "<cmd>lua require('spectre').replace_current_line()<CR>",
          desc = 'replace current line',
        },
        ['run_replace'] = {
          map = '<leader>R',
          cmd = "<cmd>lua require('spectre').replace_all()<CR>",
          desc = 'replace all',
        },
        ['change_view_mode'] = {
          map = '<leader>v',
          cmd = "<cmd>lua require('spectre').change_view()<CR>",
          desc = 'change view mode',
        },
        ['change_replace_sed'] = {
          map = 'trs',
          cmd = "<cmd>lua require('spectre').change_options('replace_engine', 'sed')<CR>",
          desc = 'use sed',
        },
        ['change_replace_oxi'] = {
          map = 'tro',
          cmd = "<cmd>lua require('spectre').change_options('replace_engine', 'oxi')<CR>",
          desc = 'use oxi',
        },
        ['toggle_ignore_case'] = {
          map = 'ti',
          cmd = "<cmd>lua require('spectre').change_options('ignore_case')<CR>",
          desc = 'toggle ignore case',
        },
        ['toggle_ignore_hidden'] = {
          map = 'th',
          cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
          desc = 'toggle search hidden',
        },
        ['resume_last_search'] = {
          map = '<leader>l',
          cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
          desc = 'resume last search',
        },
      },
      find_engine = {
        ['rg'] = {
          cmd = 'rg',
          args = {
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
          },
          options = {
            ['ignore-case'] = {
              value = '--ignore-case',
              icon = '[I]',
              desc = 'ignore case',
            },
            ['hidden'] = {
              value = '--hidden',
              desc = 'hidden file',
              icon = '[H]',
            },
          },
        },
      },
      replace_engine = {
        ['sed'] = {
          cmd = 'sed',
          args = nil,
          options = {
            ['ignore-case'] = {
              value = '--ignore-case',
              icon = '[I]',
              desc = 'ignore case',
            },
          },
        },
      },
      default = {
        find = {
          cmd = 'rg',
          options = { 'ignore-case' },
        },
        replace = {
          cmd = 'sed',
        },
      },
      replace_vim_cmd = 'cdo',
      is_open_target_win = true,
      is_insert_mode = false,
    },
  },
}
