-- AI-powered plugins: code completion, chat assistant, REPL

return {
  -- AI-powered completion (minuet)
  {
    'milanglacier/minuet-ai.nvim',
    event = 'InsertEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    -- Load if any supported API key is set (priority: OpenRouter > ZhipuAI > OpenAI)
    cond = function()
      return vim.env.OPENROUTER_API_KEY ~= nil or vim.env.ZHIPUAI_API_KEY ~= nil or vim.env.OPENAI_API_KEY ~= nil
    end,
    opts = function()
      -- Auto-detect available provider (priority order)
      local provider_config = {}

      if vim.env.OPENROUTER_API_KEY then
        provider_config = {
          endpoint = 'https://openrouter.ai/api/v1',
          api_key = 'OPENROUTER_API_KEY',
          model = 'anthropic/claude-3.5-sonnet',
        }
      elseif vim.env.ZHIPUAI_API_KEY then
        provider_config = {
          endpoint = 'https://open.bigmodel.cn/api/paas/v4',
          api_key = 'ZHIPUAI_API_KEY',
          model = 'glm-4.5-chat',
        }
      elseif vim.env.OPENAI_API_KEY then
        provider_config = {
          endpoint = 'https://api.openai.com/v1',
          api_key = 'OPENAI_API_KEY',
          model = 'gpt-4-turbo',
        }
      end

      return {
        provider = 'openai_compatible',
        provider_options = {
          openai_compatible = vim.tbl_extend('force', provider_config, {
            optional = {
              timeout = 10,
            },
          }),
        },
        blink = {
          auto_trigger = true,
          score_bias = 120,
        },
      }
    end,
  },

  -- AI chat companion (codecompanion)
  {
    'olimorris/codecompanion.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    -- Load if any supported API key is set
    cond = function()
      return vim.env.OPENROUTER_API_KEY ~= nil or vim.env.ZHIPUAI_API_KEY ~= nil or vim.env.OPENAI_API_KEY ~= nil or vim.env.ANTHROPIC_API_KEY ~= nil
    end,
    opts = function()
      local adapters = {}

      -- OpenRouter adapter (supports multiple models via one API)
      if vim.env.OPENROUTER_API_KEY then
        adapters.openrouter = function()
          return require('codecompanion.adapters').extend('openai', {
            name = 'openrouter',
            url = 'https://openrouter.ai/api/v1/chat/completions',
            env = { api_key = 'OPENROUTER_API_KEY' },
            headers = {
              ['Content-Type'] = 'application/json',
              ['Authorization'] = 'Bearer ${api_key}',
              ['HTTP-Referer'] = 'https://github.com/samuelho-dev/dev-config',
              ['X-Title'] = 'Neovim CodeCompanion',
            },
            schema = {
              model = {
                default = 'anthropic/claude-3.5-sonnet',
              },
            },
          })
        end
      end

      -- ZhipuAI GLM adapter
      if vim.env.ZHIPUAI_API_KEY then
        adapters.zhipuai = function()
          return require('codecompanion.adapters').extend('openai', {
            name = 'zhipuai',
            url = 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
            env = { api_key = 'ZHIPUAI_API_KEY' },
            headers = {
              ['Content-Type'] = 'application/json',
              Authorization = 'Bearer ${api_key}',
            },
            schema = {
              model = {
                default = 'glm-4.5-chat',
              },
            },
            opts = {
              tools = false,
            },
          })
        end
      end

      -- OpenAI and Anthropic use built-in adapters (just need env vars set)

      -- Determine default adapter (priority order)
      local default_adapter = 'openai' -- fallback
      if vim.env.OPENROUTER_API_KEY then
        default_adapter = 'openrouter'
      elseif vim.env.ANTHROPIC_API_KEY then
        default_adapter = 'anthropic'
      elseif vim.env.ZHIPUAI_API_KEY then
        default_adapter = 'zhipuai'
      elseif vim.env.OPENAI_API_KEY then
        default_adapter = 'openai'
      end

      return {
        adapters = adapters,
        strategies = {
          chat = {
            adapter = default_adapter,
          },
          inline = {
            adapter = default_adapter,
          },
        },
      }
    end,
  },

  -- AI coding assistant with LiteLLM proxy support (Cursor-like AI in Neovim)
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    build = 'make',
    version = false,
    -- Load only if LiteLLM master key is available
    cond = function()
      return vim.env.LITELLM_MASTER_KEY ~= nil
    end,
    opts = {
      provider = 'litellm',
      providers = {
        litellm = {
          __inherited_from = 'openai',
          endpoint = 'http://localhost:4000/v1',
          model = 'claude-sonnet-4', -- Configure in LiteLLM config
          api_key_name = 'LITELLM_MASTER_KEY',
          timeout = 30000,
          extra_request_body = {
            temperature = 0.7,
            max_tokens = 4096,
          },
        },
      },
    },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-web-devicons',
      -- Optional: Markdown rendering in chat
      {
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { 'markdown', 'Avante' },
        },
        ft = { 'markdown', 'Avante' },
      },
      -- Optional: Image pasting support
      {
        'HakonHarnes/img-clip.nvim',
        event = 'VeryLazy',
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
            use_absolute_path = true,
          },
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
