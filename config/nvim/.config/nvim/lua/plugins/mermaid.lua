return {
  {
    'kevalin/mermaid.nvim',
    ft = { 'mermaid' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    keys = {
      { '<leader>mp', '<cmd>MermaidPreview<CR>', ft = 'mermaid', desc = 'Mermaid preview' },
      { '<leader>mx', '<cmd>MermaidPreviewStop<CR>', ft = 'mermaid', desc = 'Stop Mermaid preview' },
      { '<leader>mf', '<cmd>MermaidFormat<CR>', ft = 'mermaid', desc = 'Format Mermaid diagram' },
      { '<leader>mr', '<cmd>MermaidRender<CR>', ft = 'mermaid', desc = 'Render Mermaid diagram' },
      { '<leader>mc', '<cmd>MermaidCopyURL<CR>', ft = 'mermaid', desc = 'Copy Mermaid preview URL' },
    },
    config = function()
      require('mermaid').setup()
    end,
  },
}
