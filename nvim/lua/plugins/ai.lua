-- AI-powered plugins: code completion, chat assistant, REPL

return {
  -- AI-powered completion (minuet)
  {
    'milanglacier/minuet-ai.nvim',
    event = 'InsertEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    -- Only load if API key is set
    cond = function()
      return vim.env.ZHIPUAI_API_KEY ~= nil and vim.env.ZHIPUAI_API_KEY ~= ''
    end,
    opts = {
      provider = 'openai_compatible',
      provider_options = {
        openai_compatible = {
          endpoint = 'https://open.bigmodel.cn/api/paas/v4',
          api_key = 'ZHIPUAI_API_KEY',
          model = 'glm-4.5-chat',
          optional = {
            timeout = 6,
          },
        },
      },
      blink = {
        auto_trigger = true,
        score_bias = 120,
      },
    },
  },

  -- AI chat companion (codecompanion)
  {
    'olimorris/codecompanion.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    -- Only load if API key is set
    cond = function()
      return vim.env.ZHIPUAI_API_KEY ~= nil and vim.env.ZHIPUAI_API_KEY ~= ''
    end,
    opts = {
      adapters = {
        http = {
          glm45 = function()
            return require('codecompanion.adapters').extend('openai', {
              name = 'glm45',
              formatted_name = 'GLM 4.5',
              url = 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
              env = { api_key = 'ZHIPUAI_API_KEY' },
              headers = {
                ['Content-Type'] = 'application/json',
                Authorization = 'Bearer ${api_key}',
              },
              schema = {
                model = {
                  default = 'glm-4.5-chat',
                  choices = {
                    ['glm-4.5-chat'] = {
                      label = 'GLM 4.5',
                      opts = { has_vision = false },
                    },
                  },
                },
              },
              opts = {
                tools = false,
              },
            })
          end,
        },
      },
      strategies = {
        chat = {
          adapter = 'glm45',
        },
      },
    },
  },

  -- REPL integration for AI assistants (aichat, claude, aider) and languages
  {
    'milanglacier/yarepl.nvim',
    cmd = {
      'REPLStart',
      'REPLSendLine',
      'REPLSendVisual',
      'REPLExec',
      'REPLFocus',
      'REPLHide',
      'REPLHideOrFocus',
      'REPLClose',
      'REPLSwap',
      'REPLAttachBufferToREPL',
      'REPLDetachBufferToREPL',
      'REPLCleanup',
    },
    config = function()
      local yarepl = require 'yarepl'
      local fmt = require 'yarepl.formatter'
      local agent_root = vim.env.CLAUDE_AGENT_ROOT or vim.fn.expand '~/Projects/claude-code-agent'

      yarepl.setup {
        buflisted = false,
        scratch = true,
        ft = 'REPL',
        wincmd = 'botright 15split',
        scroll_to_bottom_after_sending = true,
        metas = {
          aichat = { cmd = 'aichat', formatter = fmt.bracketed_pasting, source_syntax = 'aichat' },
          radian = { cmd = 'radian', formatter = fmt.bracketed_pasting_no_final_new_line, source_syntax = 'R' },
          ipython = { cmd = 'ipython', formatter = fmt.bracketed_pasting, source_syntax = 'ipython' },
          python = { cmd = 'python', formatter = fmt.trim_empty_lines, source_syntax = 'python' },
          R = { cmd = 'R', formatter = fmt.trim_empty_lines, source_syntax = 'R' },
          bash = {
            cmd = 'bash',
            formatter = vim.fn.has 'linux' == 1 and fmt.bracketed_pasting or fmt.trim_empty_lines,
            source_syntax = 'bash',
          },
          zsh = { cmd = 'zsh', formatter = fmt.bracketed_pasting, source_syntax = 'bash' },
          claude = {
            cmd = string.format('cd %s && claude', agent_root),
            formatter = fmt.bracketed_pasting,
            source_syntax = 'bash',
          },
          aider = {
            cmd = string.format('cd %s && aider', agent_root),
            formatter = fmt.trim_empty_lines,
            source_syntax = 'bash',
          },
          observability = {
            cmd = string.format('cd %s && ./scripts/start-system.sh', agent_root),
            formatter = fmt.trim_empty_lines,
            source_syntax = 'bash',
          },
        },
      }
    end,
  },
}
