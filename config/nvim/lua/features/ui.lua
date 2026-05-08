local M = {}

function M.which_key_spec()
  return {
    { '<leader>g', group = '[G]it' },
    { '<leader>mp', group = '[M]arkdown [P]review' },
    { '<leader>o', group = '[O]pen' },
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  }
end

function M.setup()
  vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle file tree' })
  vim.keymap.set('n', '<leader>E', '<cmd>NvimTreeFocus<CR>', { desc = 'Focus file tree' })
end

return M
