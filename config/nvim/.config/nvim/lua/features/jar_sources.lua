local M = {}

local function remember_client(event)
  local clients = vim.lsp.get_clients { bufnr = event.buf, name = 'kotlin_lsp' }
  vim.w.jar_source_client_id = clients[1] and clients[1].id or nil
end

local function attach_client(event)
  if vim.bo[event.buf].filetype ~= 'kotlin' then return end
  if #vim.lsp.get_clients { bufnr = event.buf, name = 'kotlin_lsp' } > 0 then return end

  -- Keep navigation in the originating project's server, including JAR-to-JAR jumps.
  local client = vim.w.jar_source_client_id and vim.lsp.get_client_by_id(vim.w.jar_source_client_id)
  if not client or client:is_stopped() then
    local clients = vim.lsp.get_clients { name = 'kotlin_lsp' }
    -- A directly opened JAR has no originating buffer. Only use an unambiguous server.
    client = #clients == 1 and clients[1] or nil
  end
  if client then vim.lsp.buf_attach_client(event.buf, client.id) end
end

local function read_source(event)
  local uri = vim.api.nvim_buf_get_name(event.buf)
  local archive, entry = uri:match '^jar://(/.-)!/(.+)$'
  if not archive then error('JAR source: invalid URI: ' .. uri) end
  if vim.fn.executable 'unzip' ~= 1 then error 'JAR source: unzip is required to read dependency sources' end

  archive, entry = vim.uri_decode(archive), vim.uri_decode(entry)
  -- unzip treats entry names as glob patterns, even when passed without a shell.
  local pattern = entry:gsub('([*?%[])', '[%1]')
  -- Load synchronously: LSP navigation sets the cursor as soon as this returns.
  local result = vim.system({ 'unzip', '-p', archive, pattern }, { text = true }):wait(10000)
  if result.code ~= 0 then error('JAR source: could not read ' .. entry .. ': ' .. vim.trim(result.stderr or 'unzip failed')) end

  local contents = result.stdout or ''
  local lines = vim.split(contents, '\n', { plain = true })
  if contents:sub(-1) == '\n' then table.remove(lines) end

  local opts = vim.bo[event.buf]
  opts.swapfile = false
  opts.buftype = 'nofile'
  opts.modifiable = true
  vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, lines)
  opts.endofline = contents:sub(-1) == '\n'
  opts.modified = false
  opts.readonly = true
  opts.modifiable = false
  opts.filetype = vim.filetype.match { filename = entry, buf = event.buf } or ''
end

function M.setup()
  local group = vim.api.nvim_create_augroup('jar-sources', { clear = true })
  vim.api.nvim_create_autocmd('BufReadCmd', {
    group = group,
    pattern = 'jar://*',
    callback = read_source,
    desc = 'Read dependency source files from JAR URIs',
  })
  vim.api.nvim_create_autocmd('BufLeave', {
    group = group,
    callback = remember_client,
    desc = 'Remember the originating Kotlin LSP client for dependency navigation',
  })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(event)
      if vim.api.nvim_buf_get_name(event.buf):match '^jar://' then
        attach_client(event)
      else
        remember_client(event)
      end
    end,
    desc = 'Reuse the project Kotlin LSP client in dependency sources',
  })
end

return M
