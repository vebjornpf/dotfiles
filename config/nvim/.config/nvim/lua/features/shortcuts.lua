local M = {}

local function directory()
  return vim.fn.expand '~/.config/shortcuts'
end

local function open_note(name)
  vim.cmd.edit(vim.fn.fnameescape(directory() .. '/' .. name .. '.md'))
end

function M.setup()
  vim.keymap.set('n', '<leader>oc', function() open_note 'neovim' end, { desc = '[O]pen [C]ommand shortcuts' })
end

function M.setup_telescope()
  vim.keymap.set('n', '<leader>os', function()
    require('telescope.builtin').live_grep {
      cwd = directory(),
      prompt_title = 'Search personal shortcuts',
      glob_pattern = '*.md',
    }
  end, { desc = '[O]pen [S]hortcuts search' })
end

return M
