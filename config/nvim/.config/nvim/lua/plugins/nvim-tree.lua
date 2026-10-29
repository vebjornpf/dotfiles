local shortcuts_dir = vim.fn.expand '~/.config/shortcuts'

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
         map('gh', api.node.open.horizontal, 'Open: Horizontal Split')
         map('gv', api.node.open.vertical, 'Open: Vertical Split')
          map('<leader>ac', require('features.agent_comments').add_tree, 'Agent: comment on files or directories')
         map('O', function()
           local node = api.tree.get_node_under_cursor()
           if node and node.absolute_path then require('config.file_handlers').open(node.absolute_path) end
         end, 'Open externally')
       end,
      git = {
        enable = true,
        ignore = false,
      },
      view = {
        side = 'right',
        width = { min = 50 },
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
        update_root = {
          enable = true,
          ignore_list = {
            shortcuts_dir .. '/',
            (vim.uv.fs_realpath(shortcuts_dir) or shortcuts_dir) .. '/',
          },
        },
      },
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      filters = {
        dotfiles = false,
      },
      live_filter = {
        always_show_folders = false,
      },
    },
  },
}
