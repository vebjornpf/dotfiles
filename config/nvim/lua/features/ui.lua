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
