return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function() require('conform').format { async = true } end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    ---@module 'conform'
    ---@type conform.setupOpts
    opts = {
      notify_on_error = true,
      format_on_save = function(bufnr)
        local enabled_filetypes = {
          json = true,
          kotlin = true,
          -- lua = true,
          -- python = true,
        }
        if enabled_filetypes[vim.bo[bufnr].filetype] then
          -- ktlint starts a JVM, so allow extra time for Kotlin formatting.
          return { timeout_ms = vim.bo[bufnr].filetype == 'kotlin' and 10000 or 500 }
        else
          return nil
        end
      end,
      default_format_opts = {
        lsp_format = 'fallback',
      },
       formatters_by_ft = {
          bash = { 'shfmt' },
          json = { 'jq' },
          kotlin = { 'ktlint' },
         sh = { 'shfmt' },
         -- rust = { 'rustfmt' },
         -- python = { 'isort', 'black' },
         -- javascript = { 'prettierd', 'prettier', stop_after_first = true },
      },
    },
  },
}
