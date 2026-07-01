return {
  {
    'nvim-tree/nvim-tree.lua',
    cmd = { 'NvimTreeToggle', 'NvimTreeFocus', 'NvimTreeFindFile', 'NvimTreeCollapse' },
    dependencies = {
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    opts = {
      on_attach = function(bufnr)
        local api = require 'nvim-tree.api'

        api.config.mappings.default_on_attach(bufnr)

        local function map(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = 'nvim-tree: ' .. desc })
        end

        map('i', api.node.open.vertical, 'Open: Vertical Split')
        map('s', api.node.open.horizontal, 'Open: Horizontal Split')
        map('t', api.node.open.tab, 'Open: New Tab')
      end,
      git = {
        enable = true,
        ignore = false,
      },
      view = {
        side = 'left',
        width = 32,
      },
      renderer = {
        group_empty = true,
      },
      actions = {
        open_file = {
          resize_window = true,
        },
      },
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      filters = {
        dotfiles = false,
      },
    },
  },
}
