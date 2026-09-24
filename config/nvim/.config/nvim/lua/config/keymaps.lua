-- Basic keymaps and diagnostics.
--
-- vim.keymap.set(mode, key_sequence, action, opts)
--   mode: which editor mode(s) the mapping applies to, for example:
--     'n' = normal, 'i' = insert, 'v' = visual, 't' = terminal.
--   key_sequence: the keys you press.
--   action: what Neovim should do when key_sequence is pressed. This can be a command
--     string, a key sequence, or a Lua function.
--   opts: optional table for metadata/behavior such as desc, silent, expr,
--     remap, buffer, etc. In this file we mainly use desc so helpers like
--     which-key can show a readable label for the mapping.
--
-- Key notation examples:
--   <leader>q means "press your leader key, then q".
--   <C-h> means "hold Control and press h".
--   <C-w><C-h> is a two-step sequence: first Ctrl+w, then Ctrl+h.
--   <cmd>...<CR> runs an Ex command and presses Enter for you.

-- Clear highlighted search matches after you are done jumping through results.
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

for _, mode in ipairs { 'n', 'i', 'v' } do
  -- Disable arrow keys to reinforce using hjkl for movement.
  vim.keymap.set(mode, '<Up>', '<Nop>')
  vim.keymap.set(mode, '<Down>', '<Nop>')
  vim.keymap.set(mode, '<Left>', '<Nop>')
  vim.keymap.set(mode, '<Right>', '<Nop>')
end

-- Diagnostics are Neovim's built-in way to show errors, warnings, hints, and
-- info from the LSP and other tooling. Keeping the display config here makes
-- the behavior easy to discover next to the related keymaps.
--
-- This setup means:
--   - don't refresh diagnostics while typing in insert mode
--   - sort messages by severity
--   - use rounded floating windows when opening diagnostic details
--   - only underline warnings/errors to reduce visual noise
--   - show virtual text inline, but keep virtual lines disabled
--   - when jumping between diagnostics, open the float automatically
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = false,
  jump = { float = true },
}

-- Open buffer diagnostics in the location list so problems are easy to scan and jump through.
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Open the current file in VS Code. This is a practical preview path for
-- generated PNGs when terminal-native image rendering is not available.
vim.keymap.set('n', '<leader>op', function()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then
    vim.notify('Current buffer has no file path', vim.log.levels.WARN)
    return
  end

  if vim.fn.executable 'code' == 1 then
    vim.fn.jobstart({ 'code', '--reuse-window', file }, { detach = true })
    return
  end

  vim.notify('VS Code CLI is not available on PATH', vim.log.levels.ERROR)
end, { desc = '[O]pen file [P]review' })

-- Open the current PDF in the first available desktop PDF viewer.
local function open_pdf()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then
    vim.notify('Current buffer has no file path', vim.log.levels.WARN)
    return
  end

  local viewers = { 'zathura', 'sioyek', 'evince', 'okular', 'xdg-open' }
  for _, viewer in ipairs(viewers) do
    if vim.fn.executable(viewer) == 1 then
      local command = viewer == 'zathura' and { viewer, '--mode', 'fullscreen', file } or { viewer, file }
      vim.fn.jobstart(command, { detach = true })
      return
    end
  end

  vim.notify('No PDF viewer found on PATH', vim.log.levels.ERROR)
end

vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*.pdf',
  callback = function(event)
    vim.keymap.set('n', '<leader>pv', open_pdf, {
      buffer = event.buf,
      desc = '[P]review [V]iew PDF',
    })
  end,
})

-- Leave terminal-insert mode and return to normal terminal navigation.
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Move focus to the window on the left without typing the full window command.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
-- Move focus to the window on the right without typing the full window command.
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
-- Move focus to the window below without typing the full window command.
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
-- Move focus to the window above without typing the full window command.
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader>wt', function()
  local tabs = vim.api.nvim_list_tabpages()
  if #tabs < 2 then
    vim.notify('Only one tab is open', vim.log.levels.WARN)
    return
  end

  local target = vim.fn.input(string.format('Move window to tab (1-%d): ', #tabs))
  local tab_number = tonumber(target)
  if not tab_number or tab_number < 1 or tab_number > #tabs or tab_number % 1 ~= 0 then
    vim.notify('Invalid tab number', vim.log.levels.WARN)
    return
  end

  local window = vim.api.nvim_get_current_win()
  local target_tab = tabs[tab_number]
  if target_tab == vim.api.nvim_get_current_tabpage() then
    vim.notify('Window is already in that tab', vim.log.levels.INFO)
    return
  end

  vim.api.nvim_win_move(window, vim.api.nvim_tabpage_get_win(target_tab))
end, { desc = 'Move current window to another tab' })
