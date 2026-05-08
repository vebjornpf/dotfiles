return {
  {
    'nvim-tree/nvim-tree.lua',
    cmd = { 'NvimTreeToggle', 'NvimTreeFocus', 'NvimTreeFindFile', 'NvimTreeCollapse' },
    dependencies = {
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    opts = {
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
