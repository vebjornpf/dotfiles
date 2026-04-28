-- Bootstrap and configure lazy.nvim, the plugin manager for this Neovim setup.
--
-- Purpose of this file:
--   - install lazy.nvim automatically if it is missing
--   - add lazy.nvim to Neovim's runtime path
--   - tell lazy.nvim where the plugin definitions live
--   - customize a small part of lazy.nvim's UI
--
-- What lazy.nvim is:
--   - a plugin manager that downloads, loads, and configures Neovim plugins
--   - the thing that reads your plugin spec files under lua/plugins/
--   - a tool that can lazy-load plugins so startup stays fast

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require('lazy').setup({
  spec = {
    { import = 'plugins' },
    -- { import = 'custom.plugins' },
  },
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
