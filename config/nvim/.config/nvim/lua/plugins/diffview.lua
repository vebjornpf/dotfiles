return {
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    keys = require('features.git').diffview_keys(),
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = {
          layout = 'diff2_horizontal',
        },
        merge_tool = {
          layout = 'diff3_horizontal',
        },
        file_history = {
          layout = 'diff2_horizontal',
        },
      },
      file_panel = {
        listing_style = 'list',
        win_config = {
          width = 32,
          win_opts = { winbar = ' Diffview' },
        },
      },
      file_history_panel = {
        win_config = {
          win_opts = { winbar = ' Diffview' },
        },
      },
    },
  },
}
