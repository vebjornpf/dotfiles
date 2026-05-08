local M = {}

function M.gitsigns_on_attach(bufnr)
  local gs = package.loaded.gitsigns

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map('n', ']h', function()
    if vim.wo.diff then
      vim.cmd.normal { ']c', bang = true }
    else
      gs.nav_hunk 'next'
    end
  end, 'Jump to next hunk')

  map('n', '[h', function()
    if vim.wo.diff then
      vim.cmd.normal { '[c', bang = true }
    else
      gs.nav_hunk 'prev'
    end
  end, 'Jump to previous hunk')

  map('n', '<leader>hs', gs.stage_hunk, 'Stage hunk')
  map('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'Stage hunk')
  map('n', '<leader>hr', gs.reset_hunk, 'Reset hunk')
  map('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, 'Reset hunk')
  map('n', '<leader>hS', gs.stage_buffer, 'Stage buffer')
  map('n', '<leader>hu', gs.undo_stage_hunk, 'Undo stage hunk')
  map('n', '<leader>hR', gs.reset_buffer, 'Reset buffer')
  map('n', '<leader>hp', gs.preview_hunk_inline, 'Preview hunk')
  map('n', '<leader>hb', function() gs.blame_line { full = true } end, 'Blame line')
  map('n', '<leader>hd', gs.diffthis, 'Diff this')
  map('n', '<leader>hD', function() gs.diffthis '~' end, 'Diff against index')
end

function M.diffview_keys()
  return {
    { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = '[G]it [D]iff view' },
    { '<leader>gH', '<cmd>DiffviewFileHistory %<CR>', desc = '[G]it file [H]istory' },
    { '<leader>gD', '<cmd>DiffviewClose<CR>', desc = '[G]it close [D]iff view' },
  }
end

return M
