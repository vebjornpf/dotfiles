return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('catppuccin').setup {
        flavour = 'frappe',
        transparent_background = false,
        styles = {
          comments = {},
        },
      }

      vim.cmd.colorscheme 'catppuccin-frappe'
    end,
  },
}
