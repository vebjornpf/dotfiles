local M = {}
local warning_display_config

local function without_warnings(severity)
  local levels = {}
  for level = vim.diagnostic.severity.ERROR, vim.diagnostic.severity.HINT do
    local matches = severity == nil or severity == level
    if type(severity) == 'table' then
      if severity.min or severity.max then
        matches = level <= (severity.min or vim.diagnostic.severity.HINT) and level >= (severity.max or vim.diagnostic.severity.ERROR)
      else
        matches = vim.tbl_contains(severity, level)
      end
    end
    if matches and level ~= vim.diagnostic.severity.WARN then levels[#levels + 1] = level end
  end
  return levels
end

function M.list_clients()
  local clients = vim.lsp.get_clients { bufnr = 0 }
  local lines = {}
  for _, client in ipairs(clients) do
    lines[#lines + 1] = string.format('%s (id: %d)', client.name, client.id)
  end
  table.sort(lines)
  local message = #lines > 0 and table.concat(lines, '\n') or 'No LSP clients attached to the current buffer'
  vim.notify(message, vim.log.levels.INFO, { title = 'LSP clients' })
end

function M.toggle_diagnostics()
  if warning_display_config then
    vim.diagnostic.config(warning_display_config)
    warning_display_config = nil
    vim.notify('Warnings shown', vim.log.levels.INFO)
    return
  end

  warning_display_config = {}
  local config = vim.diagnostic.config()
  local filtered = {}
  for _, name in ipairs { 'signs', 'underline', 'virtual_text', 'virtual_lines', 'float' } do
    warning_display_config[name] = vim.deepcopy(config[name])
    if config[name] ~= false then
      local options = type(config[name]) == 'table' and vim.deepcopy(config[name]) or {}
      options.severity = without_warnings(options.severity)
      filtered[name] = options
    end
  end
  vim.diagnostic.config(filtered)
  vim.notify('Warnings hidden', vim.log.levels.INFO)
end

function M.setup()
  vim.api.nvim_create_user_command('LspClients', M.list_clients, { desc = 'List LSP clients attached to the current buffer' })
  vim.api.nvim_create_user_command('DiagnosticsToggle', M.toggle_diagnostics, { desc = 'Toggle warning display in all buffers for this session' })
end

function M.on_attach(event)
  local map = function(keys, func, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
  end

  map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
  map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
  map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if client and client:supports_method('textDocument/documentHighlight', event.buf) then
    local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      buffer = event.buf,
      group = highlight_augroup,
      callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = event.buf,
      group = highlight_augroup,
      callback = vim.lsp.buf.clear_references,
    })

    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
      callback = function(event2)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
      end,
    })
  end

  if client and client:supports_method('textDocument/inlayHint', event.buf) then
    map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
  end
end

function M.setup_telescope()
  local builtin = require 'telescope.builtin'

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })
end

return M
