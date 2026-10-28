local M = {}

function M.setup()
  local builtin = require 'telescope.builtin'

  vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = '[G]it [S]tatus' })
  vim.keymap.set('n', '<leader>gf', function()
    vim.fn.system({ 'git', 'rev-parse', '--verify', 'main^{commit}' })
    if vim.v.shell_error ~= 0 then
      vim.notify('Git main branch not found in the current repository', vim.log.levels.ERROR)
      return
    end

    local cwd = vim.fn.systemlist({ 'git', 'rev-parse', '--show-toplevel' })[1]
    local preview_utils = require 'telescope.previewers.utils'

    builtin.git_files {
      cwd = cwd,
      prompt_title = 'Files changed against main (including uncommitted)',
      git_command = { 'git', '-c', 'core.quotepath=false', 'diff', '--name-only', '--diff-filter=ACMRT', 'main', '--' },
      previewer = require('telescope.previewers').new_buffer_previewer {
        title = 'Diff against main',
        get_buffer_by_name = function(_, entry) return entry.value end,
        define_preview = function(self, entry)
          preview_utils.job_maker({ 'git', '--no-pager', 'diff', '--no-ext-diff', '--no-color', 'main', '--', entry.value }, self.state.bufnr, {
            cwd = cwd,
            bufname = self.state.bufname,
            callback = function(bufnr)
              if vim.api.nvim_buf_is_valid(bufnr) then preview_utils.highlighter(bufnr, 'diff') end
            end,
          })
        end,
      },
    }
  end, { desc = '[G]it changed [F]iles from main' })
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', function()
    builtin.find_files {
      hidden = true,
      file_ignore_patterns = { '%.git/' },
    }
  end, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>sF', function()
    builtin.find_files {
      hidden = true,
      no_ignore = true,
    }
  end, { desc = '[S]earch all [F]iles' })
  vim.keymap.set('n', '<leader>st', function()
    builtin.find_files {
      cwd = vim.fn.getcwd() .. '/tmp',
      hidden = true,
      no_ignore = true,
    }
  end, { desc = '[S]earch [T]mp files' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', function()
    builtin.live_grep {
      file_ignore_patterns = { '%.git/' },
      additional_args = function()
        return { '--hidden' }
      end,
    }
  end, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sG', function()
    builtin.live_grep {
      additional_args = function()
        return { '--hidden' }
      end,
    }
  end, { desc = '[S]earch hidden by [G]rep' })
  vim.keymap.set('n', '<leader>sT', function()
    builtin.live_grep {
      cwd = vim.fn.getcwd() .. '/tmp',
      additional_args = function()
        return { '--hidden', '--no-ignore' }
      end,
    }
  end, { desc = '[S]earch grep in [T]mp' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sm', function()
    local buffers = {}
    for _, info in ipairs(vim.fn.getbufinfo { buflisted = 1, bufmodified = 1 }) do
      table.insert(buffers, { bufnr = info.bufnr, info = info, flag = ' ' })
    end
    if #buffers == 0 then
      vim.notify('No unsaved buffers', vim.log.levels.INFO)
      return
    end

    local previewers = require 'telescope.previewers'
    local conf = require('telescope.config').values
    require('telescope.pickers').new({}, {
      prompt_title = 'Unsaved Buffers',
      finder = require('telescope.finders').new_table {
        results = buffers,
        entry_maker = require('telescope.make_entry').gen_from_buffer {},
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        title = 'Unsaved contents',
        define_preview = function(self, entry)
          if not vim.api.nvim_buf_is_valid(entry.bufnr) then return end
          local lines = vim.api.nvim_buf_get_lines(entry.bufnr, 0, -1, false)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          require('telescope.previewers.utils').highlighter(self.state.bufnr, vim.bo[entry.bufnr].filetype)
        end,
      },
    }):find()
  end, { desc = '[S]earch [M]odified buffers' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', function()
    builtin.buffers {
      sort_mru = true,
      sort_lastused = true,
    }
  end, { desc = '[ ] Find existing buffers' })

  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find {
      layout_strategy = 'horizontal',
      layout_config = {
        width = 0.98,
        height = 0.95,
      },
      previewer = true,
    }
  end, { desc = '[/] Fuzzily search in current buffer' })

  vim.keymap.set('n', '<leader>s/', function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end, { desc = '[S]earch [/] in Open Files' })

  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
end

return M
