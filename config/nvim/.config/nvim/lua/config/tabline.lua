local M = {}

function M.render()
  local tabs = {}

  for index, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local win = vim.api.nvim_tabpage_get_win(tab)
    local buf = vim.api.nvim_win_get_buf(win)
    local path = vim.api.nvim_buf_get_name(buf)
    local name = path:match('^diffview://') and 'Diffview' or vim.fn.fnamemodify(path, ':t')
    if name == '' then name = '[No Name]' end

    local highlight = tab == vim.api.nvim_get_current_tabpage() and 'TabLineSel' or 'TabLine'
    tabs[#tabs + 1] = string.format('%%#%s#%%%dT %s%s ', highlight, index, name:gsub('%%', '%%%%'), vim.bo[buf].modified and '+' or '')
  end

  return table.concat(tabs) .. '%#TabLineFill#%T'
end

return M
