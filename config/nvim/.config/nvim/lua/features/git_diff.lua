local M = {}
local sessions = {}

local function wipe_hidden(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) and not vim.bo[bufnr].modified
    and #vim.fn.win_findbuf(bufnr) == 0 then
    vim.api.nvim_buf_delete(bufnr, { force = false })
  end
end

local function close(session)
  for _, bufnr in ipairs(session.buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
      vim.notify('Comparison has unsaved edits. Write or discard them before closing.', vim.log.levels.WARN)
      return
    end
  end
  if vim.api.nvim_win_is_valid(session.source) then
    vim.api.nvim_set_current_win(session.source)
  end
  for _, win in ipairs(session.windows) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, false)
    end
  end
  for _, bufnr in ipairs(session.buffers) do
    wipe_hidden(bufnr)
  end
  if vim.api.nvim_win_is_valid(session.source) then
    vim.api.nvim_win_call(session.source, function() vim.cmd.diffoff() end)
  end
  sessions[session.source] = nil
end

function M.toggle()
  local source = vim.api.nvim_get_current_win()
  for win, session in pairs(sessions) do
    local visible = session.pending
    for _, diff_win in ipairs(session.windows) do
      visible = visible or vim.api.nvim_win_is_valid(diff_win)
    end
    if not visible then
      sessions[win] = nil
    elseif source == win or vim.tbl_contains(session.windows, source) then
      if session.pending then
        vim.notify('Git comparison is still opening', vim.log.levels.INFO)
      else
        close(session)
      end
      return
    end
  end
  if vim.wo.diff then
    vim.notify('This window already belongs to another diff view', vim.log.levels.WARN)
    return
  end

  local existing = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    existing[win] = true
  end
  local tab = vim.api.nvim_get_current_tabpage()
  local session = { source = source, windows = {}, buffers = {}, pending = true }
  sessions[source] = session
  require('gitsigns').diffthis(nil, { vertical = true }, vim.schedule_wrap(function(err)
    session.pending = false
    if err then
      sessions[source] = nil
      vim.notify('Could not open Git comparison: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end
    if not vim.api.nvim_tabpage_is_valid(tab) then
      sessions[source] = nil
      return
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local bufnr = vim.api.nvim_win_get_buf(win)
      if not existing[win] and vim.api.nvim_buf_get_name(bufnr):match('^gitsigns://') then
        session.windows[#session.windows + 1] = win
        session.buffers[#session.buffers + 1] = bufnr
        vim.keymap.set('n', '<leader>hd', M.toggle, { buffer = bufnr, desc = 'Close Git comparison' })
        -- Closing the split manually should also remove its scratch buffer,
        -- but never silently discard edits to an editable index buffer.
        vim.api.nvim_create_autocmd('BufHidden', {
          buffer = bufnr,
          once = true,
          callback = function()
            vim.schedule(function() wipe_hidden(bufnr) end)
          end,
        })
      end
    end
    if #session.windows == 0 then
      sessions[source] = nil
    end
  end))
end

return M
