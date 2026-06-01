return {
  {
    'selimacerbas/markdown-preview.nvim',
    dependencies = { 'selimacerbas/live-server.nvim' },
    cmd = { 'MarkdownPreview', 'MarkdownPreviewRefresh', 'MarkdownPreviewStop' },
    ft = { 'markdown', 'mermaid' },
    init = function()
      vim.filetype.add {
        extension = {
          mmd = 'mermaid',
          mermaid = 'mermaid',
        },
      }
    end,
    keys = {
      { '<leader>mps', '<cmd>MarkdownPreview<CR>', desc = '[M]arkdown [P]review [S]tart' },
      { '<leader>mpr', '<cmd>MarkdownPreviewRefresh<CR>', desc = '[M]arkdown [P]review [R]efresh' },
      { '<leader>mpS', '<cmd>MarkdownPreviewStop<CR>', desc = '[M]arkdown [P]review [S]top' },
    },
    opts = {
      instance_mode = 'multi',
      port = 0,
      open_browser = true,
      debounce_ms = 300,
    },
  },
}
