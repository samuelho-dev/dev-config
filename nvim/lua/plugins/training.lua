-- Vim training and practice plugins

return {
  -- vim-be-good: Practice Vim motions with mini-games
  {
    'ThePrimeagen/vim-be-good',
    cmd = { 'VimBeGood' },
    keys = {
      { '<leader>tv', '<cmd>VimBeGood<cr>', desc = '[T]raining: [V]im Be Good' },
    },
  },
}
