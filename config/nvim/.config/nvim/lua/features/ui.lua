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
    { 'I', group = 'Block: insert at start', mode = { 'x' } },
    { 'A', group = 'Block: append at end', mode = { 'x' } },
    { 'c', group = 'Block: change selected text', mode = { 'x' } },
    { 'd', group = 'Block: delete selected text', mode = { 'x' } },
    { 'y', group = 'Block: yank selected text', mode = { 'x' } },
    { '<', group = 'Block: shift left', mode = { 'x' } },
    { '>', group = 'Block: shift right', mode = { 'x' } },
    { 'J', group = 'Block: move down', mode = { 'x' } },
    { 'K', group = 'Block: move up', mode = { 'x' } },
  }
end

function M.setup()
  vim.keymap.set('x', '<leader>?', function()
    require('which-key').show('', { mode = 'x' })
  end, { desc = 'Show visual-block help' })

  local function smart_tree()
    local api = require 'nvim-tree.api'

    if vim.bo.filetype == 'NvimTree' then
      api.tree.close()
      return
    end

    if api.tree.is_visible() then
      api.tree.focus()
      return
    end

    api.tree.find_file { open = true, focus = true }
  end

  vim.keymap.set('n', '<leader>e', smart_tree, { desc = 'Open or focus file tree' })
  vim.keymap.set('n', '<leader>fe', '<cmd>NvimTreeFindFile<CR>', { desc = '[F]ind current file in [E]xplorer' })
end

return M
