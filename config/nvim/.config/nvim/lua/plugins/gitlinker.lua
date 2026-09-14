return {
  {
    'linrongbin16/gitlinker.nvim',
    cmd = 'GitLink',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>gy', '<cmd>GitLink current_branch<CR>', mode = { 'n', 'v' }, desc = '[G]it branch link cop[Y]' },
      { '<leader>gO', '<cmd>GitLink! current_branch<CR>', mode = { 'n', 'v' }, desc = '[G]it branch link [O]pen' },
    },
    opts = {},
  },
}
