-- Git integration plugins: gitsigns, lazygit, octo, diffview, git-conflict

return {
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- Lazygit integration - best git UI
  {
    'kdheepak/lazygit.nvim',
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    keys = {
      { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
      { '<leader>gf', '<cmd>LazyGitCurrentFile<cr>', desc = 'LazyGit Current File' },
    },
  },

  -- GitHub integration - PRs, issues, reviews
  {
    'pwntester/octo.nvim',
    cmd = 'Octo',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<leader>gp', '<cmd>Octo pr list<cr>', desc = 'GitHub PR List' },
      { '<leader>gi', '<cmd>Octo issue list<cr>', desc = 'GitHub Issue List' },
    },
    opts = {
      enable_builtin = true,
      default_merge_method = 'squash',
    },
  },

  -- Better diff viewing
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = 'Diffview Open' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'File History' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = 'Branch History' },
    },
    opts = {},
  },

  -- Visual merge conflict resolution
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    config = true,
    keys = {
      { '<leader>gco', '<cmd>GitConflictChooseOurs<cr>', desc = 'Choose Ours' },
      { '<leader>gct', '<cmd>GitConflictChooseTheirs<cr>', desc = 'Choose Theirs' },
      { '<leader>gcb', '<cmd>GitConflictChooseBoth<cr>', desc = 'Choose Both' },
      { '<leader>gc0', '<cmd>GitConflictChooseNone<cr>', desc = 'Choose None' },
      { '<leader>gcn', '<cmd>GitConflictNextConflict<cr>', desc = 'Next Conflict' },
      { '<leader>gcp', '<cmd>GitConflictPrevConflict<cr>', desc = 'Prev Conflict' },
      { '<leader>gcl', '<cmd>GitConflictListQf<cr>', desc = 'List Conflicts' },
    },
  },
}
