local M = {}

function M.label(tab)
  local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, 'tab_name')
  if ok and name ~= '' then return name end

  local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_get_win(tab))
  local path = vim.api.nvim_buf_get_name(buf)
  name = path:match('^diffview://') and 'Diffview' or vim.fn.fnamemodify(path, ':t')
  return name ~= '' and name or '[No Name]'
end

function M.create()
  vim.ui.input({ prompt = 'New tab name: ' }, function(name)
    if not name or vim.trim(name) == '' then return end
    vim.cmd.tabnew()
    vim.api.nvim_tabpage_set_var(0, 'tab_name', vim.trim(name))
    vim.cmd.redrawtabline()
  end)
end

function M.rename()
  local tab = vim.api.nvim_get_current_tabpage()
  local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, 'tab_name')
  vim.ui.input({ prompt = 'Tab name (empty resets): ', default = ok and name or '' }, function(value)
    if value == nil or not vim.api.nvim_tabpage_is_valid(tab) then return end
    vim.api.nvim_tabpage_set_var(tab, 'tab_name', vim.trim(value))
    vim.cmd.redrawtabline()
  end)
end

function M.pick()
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  require('telescope.pickers').new({}, {
    prompt_title = 'Tabs',
    finder = require('telescope.finders').new_table {
      results = vim.api.nvim_list_tabpages(),
      entry_maker = function(tab)
        local label = M.label(tab)
        return {
          value = tab,
          display = string.format('%d: %s', vim.api.nvim_tabpage_get_number(tab), label),
          ordinal = label,
        }
      end,
    },
    sorter = require('telescope.config').values.generic_sorter {},
    previewer = false,
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry and vim.api.nvim_tabpage_is_valid(entry.value) then vim.api.nvim_set_current_tabpage(entry.value) end
      end)
      return true
    end,
  }):find()
end

function M.setup()
  vim.keymap.set('n', '<leader>tn', M.create, { desc = '[T]ab: [N]ew named tab' })
  vim.keymap.set('n', '<leader>tr', M.rename, { desc = '[T]ab: [R]ename' })
  vim.keymap.set('n', '<leader>tt', M.pick, { desc = '[T]ab: pick [T]ab' })
end

return M
