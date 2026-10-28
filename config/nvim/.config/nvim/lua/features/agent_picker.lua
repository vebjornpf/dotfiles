local M = {}

function M.select(agents, callback)
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local generation = 0
  local preview = require('telescope.previewers').new_buffer_previewer {
    title = 'Agent details / visible conversation',
    teardown = function() generation = generation + 1 end,
    define_preview = function(self, entry)
      generation = generation + 1
      local request = generation
      local buf = self.state.bufnr
      local pane = entry.value
      local function show(lines)
        if request ~= generation or not vim.api.nvim_buf_is_valid(buf) then return end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        if self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
          vim.wo[self.state.winid].wrap = true
        end
      end
      if pane.new then
        return show {
          'New OpenCode agent', '',
          'Starts at the repository root in a new pane.',
          'Uses the tab named after the current Herdr workspace, creating it if needed.',
          'Sends the queue once the agent is ready; no confirmation dialog.',
          '', 'No conversation yet.',
        }
      end
      local header = {
        'Title: ' .. (pane.terminal_title_stripped or pane.terminal_title or '(untitled)'),
        'Agent: ' .. pane.agent .. '    Status: ' .. (pane.agent_status or 'unknown'),
        'Workspace: ' .. (pane.workspace_id or '') .. '    Tab: ' .. (pane.tab_id or '') .. '    Pane: ' .. pane.pane_id,
        'Directory: ' .. (pane.foreground_cwd or pane.cwd or '(unknown)'),
        '', 'Current terminal view (not full history; does not scroll the agent)', '',
      }
      local loading = vim.list_extend(vim.deepcopy(header), { 'Loading…' })
      show(loading)
      vim.system({ 'herdr', 'agent', 'read', pane.pane_id, '--source', 'visible' }, { text = true, timeout = 5000 }, vim.schedule_wrap(function(result)
        local text = result.code == 0 and result.stdout or ('Preview unavailable: ' .. (result.stderr or ''))
        if not text or text:match '^%s*$' then text = '(No visible terminal output.)' end
        show(vim.list_extend(vim.deepcopy(header), vim.split(text, '\n', { plain = true })))
      end))
    end,
  }
  require('telescope.pickers').new({}, {
    prompt_title = 'Send comments to agent — Enter sends',
    layout_strategy = 'horizontal',
    layout_config = { width = 0.98, height = 0.95, horizontal = { preview_width = 0.65, preview_cutoff = 1 } },
    finder = require('telescope.finders').new_table {
      results = agents,
      entry_maker = function(pane)
        local label = pane.new and 'New OpenCode agent…' or string.format('%s [%s] %s — %s',
          pane.agent, pane.agent_status or 'unknown', pane.pane_id, pane.terminal_title_stripped or pane.terminal_title or '')
        return { value = pane, display = label, ordinal = label .. ' ' .. (pane.foreground_cwd or pane.cwd or '') }
      end,
    },
    sorter = require('telescope.config').values.generic_sorter {},
    previewer = preview,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then callback(entry.value) end
      end)
      -- Global file-opening mappings must not try to open agent records as files.
      local function ignore_file_action() end
      for _, mode in ipairs { 'i', 'n' } do
        for _, key in ipairs { '<C-x>', '<C-v>', '<C-t>' } do map(mode, key, ignore_file_action) end
      end
      map('n', 'gh', ignore_file_action)
      map('n', 'gv', ignore_file_action)
      return true
    end,
  }):find()
end

return M
