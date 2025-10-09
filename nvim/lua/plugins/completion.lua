-- Autocompletion plugins: blink.cmp and LuaSnip

return {
  -- Autocompletion
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        preset = 'super-tab',
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      -- Command-line completion (when you type : commands)
      cmdline = {
        enabled = true,
        keymap = { preset = 'super-tab' }, -- Use Tab for completion
        completion = {
          menu = {
            auto_show = true, -- Show menu automatically when typing commands
          },
        },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      snippets = { preset = 'luasnip' },

      -- Use Lua fuzzy matcher (no native build required)
      -- This avoids pkg-config dependency and ensures cross-platform compatibility
      -- Trade-off: Slightly slower than Rust, but acceptable for most workflows
      -- NOTE: The health check warning "blink_cmp_fuzzy lib is not downloaded/built" is EXPECTED
      fuzzy = {
        implementation = 'lua', -- Use Lua implementation (no binary download)
        prebuilt_binaries = { download = false }, -- Disable native builds explicitly
      },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },
}
