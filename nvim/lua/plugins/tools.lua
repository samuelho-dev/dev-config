-- Utility tools: CSV viewer

return {
  -- Modern CSV viewer with virtual text columns
  {
    'hat0uma/csvview.nvim',
    ft = { 'csv' },
    opts = {
      view = {
        display_mode = 'border', -- 'highlight' or 'border'
      },
    },
  },
}
