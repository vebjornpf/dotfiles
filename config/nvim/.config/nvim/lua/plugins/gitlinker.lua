return {
  {
    'linrongbin16/gitlinker.nvim',
    cmd = 'GitLink',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>gy', '<cmd>GitLink<CR>', mode = { 'n', 'v' }, desc = '[G]it link cop[Y]' },
      { '<leader>gO', '<cmd>GitLink!<CR>', mode = { 'n', 'v' }, desc = '[G]it link [O]pen' },
    },
    opts = {},
  },
}
