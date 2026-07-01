return {
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    keys = require('features.git').diffview_keys(),
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = {
          layout = 'diff2_vertical',
        },
        file_history = {
          layout = 'diff2_vertical',
        },
      },
      file_panel = {
        listing_style = 'list',
        win_config = {
          width = 32,
        },
      },
    },
  },
}
