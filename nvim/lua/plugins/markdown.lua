-- Markdown and Obsidian plugins

return {
  -- Obsidian vault integration
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*',
    lazy = true,
    ft = 'markdown',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {
      -- Dynamic workspace detection - searches upward for .obsidian directory
      -- Works from any location, no hardcoded paths, adapts to any machine
      workspaces = {
        {
          name = 'detected-vault',
          path = function()
            -- Search upward from current buffer for .obsidian directory
            local obsidian_dirs = vim.fs.find('.obsidian', {
              upward = true,
              path = vim.api.nvim_buf_get_name(0),
              type = 'directory',
            })

            -- If found, return parent directory (vault root)
            if obsidian_dirs and #obsidian_dirs > 0 then
              return vim.fs.dirname(obsidian_dirs[1])
            end

            -- Fallback: use buffer's parent directory (for non-vault markdown)
            return vim.fs.dirname(vim.api.nvim_buf_get_name(0))
          end,
          overrides = {
            notes_subdir = vim.NIL,
            new_notes_location = 'current_dir',
            templates = { folder = vim.NIL },
          },
        },
      },
      -- Daily notes disabled to prevent automatic folder creation
      daily_notes = {
        folder = vim.NIL,
      },
      completion = {
        nvim_cmp = false, -- Using blink.cmp instead
        min_chars = 2,
      },
      -- Use new command format (`:Obsidian <subcommand>` instead of `:Obsidian<Subcommand>`)
      legacy_commands = false,
      callbacks = {
        -- Set buffer-local keymaps when entering a note
        enter_note = function(client, note)
          -- Guard against nil note (non-vault markdown files)
          if not note then
            return
          end

          -- Toggle checkboxes with <leader>ch
          vim.keymap.set('n', '<leader>ch', '<cmd>Obsidian toggle_checkbox<cr>', {
            buffer = note.bufnr,
            desc = 'Toggle checkbox',
          })
        end,
      },
      ui = {
        enable = false, -- disable obsidian.nvim UI, we'll use render-markdown.nvim instead
      },
    },
  },

  -- Render markdown beautifully in-buffer
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      file_types = { 'markdown' },
      code = {
        sign = false,
        width = 'block',
        right_pad = 1,
      },
      heading = {
        sign = false,
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
      },
    },
  },

  -- Markdown preview in browser
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = 'markdown',
    build = function()
      vim.fn['mkdp#util#install']()
    end,
    keys = {
      { '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', desc = 'Markdown Preview' },
    },
  },

  -- Better bullet and task management
  {
    'bullets-vim/bullets.vim',
    ft = 'markdown',
  },

  -- Document outline
  {
    'hedyhli/outline.nvim',
    cmd = { 'Outline', 'OutlineOpen' },
    keys = {
      { '<leader>o', '<cmd>Outline<CR>', desc = 'Toggle outline' },
    },
    opts = {},
  },
}
