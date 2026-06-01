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
