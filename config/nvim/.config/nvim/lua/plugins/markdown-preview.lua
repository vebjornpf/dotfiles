return {
  {
    'selimacerbas/markdown-preview.nvim',
    dependencies = { 'selimacerbas/live-server.nvim' },
    cmd = { 'MarkdownPreview', 'MarkdownPreviewRefresh', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    keys = {
      { '<leader>mps', '<cmd>MarkdownPreview<CR>', ft = 'markdown', desc = 'Start Markdown preview' },
      { '<leader>mpr', '<cmd>MarkdownPreviewRefresh<CR>', ft = 'markdown', desc = 'Refresh Markdown preview' },
      { '<leader>mpS', '<cmd>MarkdownPreviewStop<CR>', ft = 'markdown', desc = 'Stop Markdown preview' },
    },
    opts = {
      instance_mode = 'multi',
      port = 0,
      open_browser = true,
      browser = 'markdown-preview-browser',
      debounce_ms = 300,
    },
  },
}
