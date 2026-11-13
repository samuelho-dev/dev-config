-- Debug Adapter Protocol (DAP): Go debugging via Delve

return {
  -- Generic DAP client; nvim-dap-go wires the Delve adapter for Go.
  {
    'mfussenegger/nvim-dap',
    dependencies = { 'nvim-neotest/nvim-nio' },
    keys = {
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = '[D]ebug [B]reakpoint',
      },
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = '[D]ebug [C]ontinue',
      },
      {
        '<leader>do',
        function()
          require('dap').step_over()
        end,
        desc = '[D]ebug Step [O]ver',
      },
      {
        '<leader>di',
        function()
          require('dap').step_into()
        end,
        desc = '[D]ebug Step [I]nto',
      },
      {
        '<leader>du',
        function()
          require('dap').step_out()
        end,
        desc = '[D]ebug Step O[u]t',
      },
      {
        '<leader>dr',
        function()
          require('dap').repl.toggle()
        end,
        desc = '[D]ebug [R]EPL',
      },
    },
  },
  -- Delve adapter + Go launch configs (dlv supplied by Home Manager).
  {
    'leoluz/nvim-dap-go',
    ft = 'go',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
    config = function()
      require('dap-go').setup()
    end,
    keys = {
      {
        '<leader>dt',
        function()
          require('dap-go').debug_test()
        end,
        desc = '[D]ebug [T]est (nearest)',
      },
      {
        '<leader>dT',
        function()
          require('dap-go').debug_last_test()
        end,
        desc = '[D]ebug Last [T]est',
      },
    },
  },
}
