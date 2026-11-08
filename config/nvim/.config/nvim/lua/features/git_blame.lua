local M = {}
local panels = {}
local pending = {}

function M.toggle()
  local tab = vim.api.nvim_get_current_tabpage()
  local panel = panels[tab]
  if panel then
    panels[tab] = nil
    if vim.api.nvim_win_is_valid(panel.blame) then
      vim.api.nvim_win_close(panel.blame, false)
      if vim.api.nvim_win_is_valid(panel.source) then
        vim.api.nvim_set_current_win(panel.source)
      end
      return
    end
  end

  if pending[tab] then
    return
  end
  local source = vim.api.nvim_get_current_win()
  local existing = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    existing[win] = true
  end
  pending[tab] = true
  require('gitsigns').blame(nil, vim.schedule_wrap(function(err)
    pending[tab] = nil
    if err then
      vim.notify('Could not open Git blame: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end
    if not vim.api.nvim_tabpage_is_valid(tab) then
      return
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if not existing[win] and vim.bo[buf].filetype == 'gitsigns-blame' then
        panels[tab] = { source = source, blame = win }
        vim.keymap.set('n', '<leader>hB', M.toggle, { buffer = buf, desc = 'Toggle file blame' })
        return
      end
    end
  end))
end

function M.toggle_line()
  require('gitsigns').toggle_current_line_blame()
end

return M
