-- External handling policy for files that are better viewed outside Neovim.
-- Text and source files stay in Neovim; the opener is still available on
-- demand for any file when a system association is useful.
local M = {}

M.policy = {
  text = 'edit in Neovim',
  markdown = 'edit in Neovim; use MarkdownPreview for a browser preview',
  svg = 'edit in Neovim; open externally for a browser preview',
  image = 'open with the system image viewer',
  pdf = 'open with the system PDF viewer',
  office = 'open with the system office application',
  other = 'open with the system association',
}

local function is_wsl()
  return vim.loop.os_uname().release:lower():find('microsoft', 1, true) ~= nil
end

local function windows_path(path)
  if vim.fn.executable('wslpath') ~= 1 then return end
  local converted = vim.fn.trim(vim.fn.system({ 'wslpath', '-w', path }))
  if vim.v.shell_error == 0 and converted ~= '' then return converted end
end

local function opener(path)
  -- Use the Windows browser in WSL instead of Explorer's file association UI.
  if is_wsl() then
    local firefox = '/mnt/c/Program Files/Mozilla Firefox/firefox.exe'
    local converted = windows_path(path)
    if vim.fn.filereadable(firefox) == 1 and converted then return { firefox, converted } end
  end

  -- On native systems, use the browser directly for this shortcut.
  if vim.fn.has('mac') == 1 and vim.fn.executable('open') == 1 then return { 'open', path } end
  if vim.fn.executable('firefox') == 1 then return { 'firefox', path } end

  -- Keep platform openers as fallbacks when Firefox is unavailable.
  if vim.fn.executable('xdg-open') == 1 then return { 'xdg-open', path } end

  if is_wsl() and vim.fn.executable('explorer.exe') == 1 then
    local converted = windows_path(path)
    if converted then return { 'explorer.exe', converted } end
  end

  if vim.fn.executable('open') == 1 then return { 'open', path } end
end

function M.open(path)
  if path == '' then
    vim.notify('Selected item has no file path', vim.log.levels.WARN)
    return
  end
  if vim.fn.isdirectory(path) == 1 then
    vim.notify('Cannot open a directory externally', vim.log.levels.WARN)
    return
  end
  if vim.fn.filereadable(path) == 0 then
    vim.notify('File does not exist or is not readable: ' .. path, vim.log.levels.ERROR)
    return
  end

  local command = opener(path)
  if not command then
    vim.notify('No supported external file opener found', vim.log.levels.ERROR)
    return
  end

  local job = vim.fn.jobstart(command, { detach = true })
  if job <= 0 then vim.notify('Failed to start external opener', vim.log.levels.ERROR) end
end

function M.current_file()
  M.open(vim.api.nvim_buf_get_name(0))
end

return M
