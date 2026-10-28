vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Copy ordinary yanks to the system clipboard',
  group = vim.api.nvim_create_augroup('clipboard-yank', { clear = true }),
  callback = function()
    local event = vim.v.event
    if event.operator == 'y' and event.regname == '' then
      vim.fn.setreg('+', event.regcontents, event.regtype)
    end
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable spell checking in Markdown',
  group = vim.api.nvim_create_augroup('markdown-spell', { clear = true }),
  pattern = 'markdown',
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = 'en'
  end,
})

vim.api.nvim_create_autocmd('BufNewFile', {
  pattern = { '*.kt', '*.kts' },
  callback = function(event)
    if vim.bo[event.buf].modified or vim.api.nvim_buf_line_count(event.buf) > 1 or vim.api.nvim_buf_get_lines(event.buf, 0, 1, false)[1] ~= '' then return end

    local path = event.file
    local roots = {
      'src/main/kotlin/',
      'src/test/kotlin/',
    }

    for _, root in ipairs(roots) do
      local package_path = vim.fn.fnamemodify(path, ':h'):match(root .. '(.+)$')
      if package_path then
        local package_name = package_path:gsub('/', '.')
        vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, {
          'package ' .. package_name,
          '',
        })
        return
      end
    end
  end,
})
