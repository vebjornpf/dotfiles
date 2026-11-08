local M = {}

local function git(cwd, args)
  return vim.system(vim.list_extend({ 'git' }, args), { cwd = cwd, text = false }):wait()
end

function M.open()
  local root = git(vim.fn.getcwd(), { 'rev-parse', '--show-toplevel' })
  if root.code ~= 0 then
    vim.notify('Could not find the current Git repository', vim.log.levels.ERROR)
    return
  end
  local cwd = vim.trim(root.stdout)
  local comparison = require 'features.git'
  local base = comparison.base_ref()
  local label = comparison.base_label()
  local diff_args = { '--no-pager', 'diff', '--no-ext-diff', '--no-color' }
  if base then
    diff_args[#diff_args + 1] = base
  end
  local list_args = vim.list_extend(vim.deepcopy(diff_args), { '--name-only', '-z', '--diff-filter=ACMRT', '--' })
  local changed = git(cwd, list_args)
  if changed.code ~= 0 then
    vim.notify('Could not list changed files: ' .. vim.trim(changed.stderr or ''), vim.log.levels.ERROR)
    return
  end

  local files, unsaved_diffs = {}, {}
  for _, path in ipairs(vim.split(changed.stdout, '\0', { trimempty = true })) do
    files[path] = true
  end

  -- Only inspect modified buffers; Git already accounts for saved files.
  local tracked_result = git(cwd, { 'ls-files', '-z' })
  if tracked_result.code ~= 0 then
    vim.notify('Could not list tracked Git files', vim.log.levels.ERROR)
    return
  end
  local tracked = {}
  for _, path in ipairs(vim.split(tracked_result.stdout, '\0', { trimempty = true })) do
    tracked[path] = true
  end
  for _, info in ipairs(vim.fn.getbufinfo { bufmodified = 1 }) do
    local path = vim.fs.relpath(cwd, info.name)
    if path and tracked[path] and vim.api.nvim_buf_is_loaded(info.bufnr)
      and vim.bo[info.bufnr].buftype == '' then
      local original = git(cwd, { 'show', (base or '') .. ':' .. path })
      -- A tracked file added since the selected base has no original blob.
      local before = original.code == 0 and original.stdout or ''
      local contents = table.concat(vim.api.nvim_buf_get_lines(info.bufnr, 0, -1, false), '\n')
      if vim.bo[info.bufnr].endofline then
        contents = contents .. '\n'
      end
      local diff = vim.diff(before, contents, { result_type = 'unified' })
      files[path] = diff ~= '' or nil
      unsaved_diffs[path] = diff
    end
  end

  local results = vim.tbl_keys(files)
  table.sort(results)
  if #results == 0 then
    vim.notify('No changed files against ' .. label, vim.log.levels.INFO)
    return
  end

  local preview_utils = require 'telescope.previewers.utils'
  require('telescope.pickers').new({ cwd = cwd }, {
    prompt_title = 'Changed files — ' .. label,
    finder = require('telescope.finders').new_table {
      results = results,
      entry_maker = require('telescope.make_entry').gen_from_file { cwd = cwd },
    },
    sorter = require('telescope.config').values.file_sorter {},
    previewer = require('telescope.previewers').new_buffer_previewer {
      title = 'Diff — ' .. label,
      get_buffer_by_name = function(_, entry) return entry.value end,
      define_preview = function(self, entry)
        local diff = unsaved_diffs[entry.value]
        if diff then
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(diff, '\n'))
          preview_utils.highlighter(self.state.bufnr, 'diff')
          return
        end
        local args = vim.list_extend(vim.deepcopy(diff_args), { '--', entry.value })
        preview_utils.job_maker(vim.list_extend({ 'git' }, args), self.state.bufnr, {
          cwd = cwd,
          bufname = self.state.bufname,
          callback = function(bufnr)
            if vim.api.nvim_buf_is_valid(bufnr) then preview_utils.highlighter(bufnr, 'diff') end
          end,
        })
      end,
    },
  }):find()
end

return M
