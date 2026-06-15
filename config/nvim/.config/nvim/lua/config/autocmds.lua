vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
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
