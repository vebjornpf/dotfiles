-- Core editor options.
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.o.winbar = '%=%t %m'
vim.o.tabline = "%!v:lua.require('config.tabline').render()"

vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true
vim.opt.clipboard = 'unnamedplus'

if vim.fn.has('wsl') == 1 and vim.fn.executable('win32yank.exe') == 1 then
  vim.g.clipboard = {
    name = 'win32yank',
    copy = {
      ['+'] = { 'win32yank.exe', '-i', '--crlf' },
      ['*'] = { 'win32yank.exe', '-i', '--crlf' },
    },
    paste = {
      ['+'] = { 'win32yank.exe', '-o', '--lf' },
      ['*'] = { 'win32yank.exe', '-o', '--lf' },
    },
    cache_enabled = 0,
  }
elseif vim.fn.has('mac') == 1 then
  vim.g.clipboard = {
    name = 'macOS clipboard',
    copy = {
      ['+'] = { 'pbcopy' },
      ['*'] = { 'pbcopy' },
    },
    paste = {
      ['+'] = { 'pbpaste' },
      ['*'] = { 'pbpaste' },
    },
    cache_enabled = 0,
  }
end
