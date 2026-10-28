return {
  {
    'pwntester/octo.nvim',
    cmd = 'Octo',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    keys = {
      { '<leader>gp', '<cmd>Octo pr list<CR>', desc = 'GitHub pull requests' },
    },
    opts = {
      picker = 'telescope',
      enable_builtin = true,
      use_timeline_icons = false,
      user_icon = 'user ',
      ghost_icon = 'ghost ',
      copilot_icon = 'copilot ',
      dependabot_icon = 'dependabot ',
      comment_icon = '|',
      outdated_icon = 'outdated ',
      resolved_icon = 'resolved ',
      reaction_viewer_hint_icon = '* ',
      timeline_marker = '> ',
      right_bubble_delimiter = '',
      left_bubble_delimiter = '',
      file_panel = { icons = false },
    },
  },
}
