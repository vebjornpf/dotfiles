return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    cmd = { 'RenderMarkdown' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      -- Keep the reading view usable without a Nerd Font.
      heading = { icons = { '# ', '## ', '### ', '#### ', '##### ', '###### ' } },
      code = { language_icon = false },
      sign = { enabled = false },
      link = { enabled = false },
      checkbox = {
        unchecked = { icon = '[ ] ' },
        checked = { icon = '[x] ' },
        custom = { todo = { rendered = '[-] ' } },
      },
    },
  },
}
