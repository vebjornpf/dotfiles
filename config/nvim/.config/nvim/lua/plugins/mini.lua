return {
  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup {
        mappings = {
          around_next = 'aa',
          inside_next = 'ii',
        },
        n_lines = 500,
      }

      require('mini.surround').setup()
      require('mini.pairs').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_filename = function()
        local unsaved = #vim.fn.getbufinfo { buflisted = 1, bufmodified = 1 }
        return '%t%m%r  ' .. require('features.git').base_label() .. (unsaved > 0 and string.format('  Unsaved: %d', unsaved) or '')
      end
    end,
  },
}
