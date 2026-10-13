local M = {}

local function relative_path(file)
  local root = vim.fn.getcwd()
  if vim.fn.executable 'git' == 1 then
    local result = vim.system({ 'git', '-C', vim.fs.dirname(file), 'rev-parse', '--show-toplevel' }, { text = true }):wait()
    if result.code == 0 then root = vim.trim(result.stdout) end
  end

  local base = vim.split(vim.fs.normalize(root), '/', { trimempty = true })
  local target = vim.split(vim.fs.normalize(file), '/', { trimempty = true })
  local common = 0
  while base[common + 1] and base[common + 1] == target[common + 1] do
    common = common + 1
  end
  local parts = {}
  for _ = common + 1, #base do
    parts[#parts + 1] = '..'
  end
  for i = common + 1, #target do
    parts[#parts + 1] = target[i]
  end
  return table.concat(parts, '/')
end

local function copy_path(kind)
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' or vim.bo.buftype ~= '' then
    vim.notify('Current buffer has no regular file path', vim.log.levels.WARN)
    return
  end

  local value = file
  if kind == 'filename' then
    value = vim.fs.basename(file)
  elseif kind == 'relative' then
    value = relative_path(file)
  end
  vim.fn.setreg('+', value)
  vim.notify('Copied: ' .. value)
end

function M.setup()
  vim.api.nvim_create_user_command('CopyFileName', function() copy_path 'filename' end, { desc = 'Copy current filename to clipboard' })
  vim.api.nvim_create_user_command('CopyRelativePath', function() copy_path 'relative' end, { desc = 'Copy current path relative to Git root or working directory' })
  vim.api.nvim_create_user_command('CopyAbsolutePath', function() copy_path 'absolute' end, { desc = 'Copy current absolute path to clipboard' })
end

return M
